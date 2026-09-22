using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Collections.Generic;

namespace spmst_lms_development.Users.Staff.Transactions
{
    public partial class Book_Return : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        // Per-session live feed (avoids leaking between users / app pool restarts)
        private List<FeedEntry> FeedItems
        {
            get
            {
                if (Session["ReturnFeed"] == null)
                    Session["ReturnFeed"] = new List<FeedEntry>();
                return (List<FeedEntry>)Session["ReturnFeed"];
            }
        }

        // Strongly-typed feed item — mirrors columns actually returned
        [Serializable]
        public class FeedEntry
        {
            public string PatronName { get; set; }
            public string PatronID { get; set; }
            public string BookTitle { get; set; }
            public string AccessionNumber { get; set; }
            public string Condition { get; set; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                string currentPage = System.IO.Path.GetFileName(Request.Url.AbsolutePath);
                if (currentPage.Equals("Book_Return.aspx", StringComparison.OrdinalIgnoreCase))
                {
                    lnkBorrow.CssClass = "nav-link text-secondary fw-semibold";
                    lnkReturn.CssClass = "nav-link active fw-semibold";
                    lnkRenew.CssClass = "nav-link text-secondary fw-semibold";
                }
                BindFeed();
            }
        }

        protected void txtBookReturnQR_TextChanged(object sender, EventArgs e)
        {
            string accNo = txtBookReturnQR.Text.Trim();
            if (string.IsNullOrEmpty(accNo)) return;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                // Join path matches the new schema:
                //   Transactions.user_id  -> Users.user_id
                //   Users.user_id         -> Students.student_id / Faculty.faculty_id / Staff.staff_id
                //   Transactions.accession_number -> Item_Copies.accession_number
                //   Item_Copies.resource_id       -> Library_Resources.resource_id
                string query = @"
                    SELECT  t.transaction_id,
                            t.user_id,
                            t.accession_number,
                            r.title,
                            r.author,
                            COALESCE(s.first_name, f.first_name, st.first_name) AS fname,
                            COALESCE(s.last_name,  f.last_name,  st.last_name ) AS lname,
                            COALESCE(s.course, f.institute, st.office_department) AS dept
                    FROM Transactions t
                    INNER JOIN Item_Copies      c  ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id      = r.resource_id
                    LEFT  JOIN Students  s ON t.user_id = s.student_id
                    LEFT  JOIN Faculty   f ON t.user_id = f.faculty_id
                    LEFT  JOIN Staff     st ON t.user_id = st.staff_id
                    WHERE t.accession_number = @acc
                      AND t.status            = 'Borrowed'
                      AND t.return_date IS NULL
                    LIMIT 1";

                MySqlCommand cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@acc", accNo);

                try
                {
                    conn.Open();
                    using (MySqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            litBookTitle.Text = reader["title"].ToString();
                            litAuthor.Text = reader["author"].ToString();
                            litAccNo.Text = reader["accession_number"].ToString();
                            litPatronName.Text = $"{reader["fname"]} {reader["lname"]}".Trim();
                            litPatronDept.Text = reader["dept"].ToString();

                            ViewState["CurrentUserID"] = reader["user_id"].ToString();
                            ViewState["CurrentTransID"] = Convert.ToInt32(reader["transaction_id"]);
                            ViewState["CurrentAccession"] = reader["accession_number"].ToString();
                            ViewState["CurrentTitle"] = reader["title"].ToString();

                            pnlReturnInfo.Visible = true;
                        }
                        else
                        {
                            pnlReturnInfo.Visible = false;
                            txtBookReturnQR.Text = "";
                            ShowSweetAlert("Not Found",
                                "No active borrow record found for this book.", "warning");
                        }
                    }
                }
                catch (Exception ex)
                {
                    ShowSweetAlert("Error", ex.Message, "error");
                }
            }

            UPReturn.Update();
        }

        protected void btnCompleteReturn_Click(object sender, EventArgs e)
        {
            if (ViewState["CurrentTransID"] == null) return;

            string condition = ddlCondition.SelectedValue;   // "Good" | "Damage" | "Lost"
            string rawNote = txtReturnNote.Text.Trim();

            // Build a human-readable remark (mirrors the original behaviour)
            string formattedRemarks = string.IsNullOrEmpty(rawNote)
                ? condition
                : $"{condition} - {rawNote}";

            // Flags derived from the selected condition — these map directly onto
            // the ENUM values of Item_Copies.status_condition and the new
            // Transactions.is_damaged / is_lost columns.
            int isDamaged = condition == "Damage" ? 1 : 0;
            int isLost = condition == "Lost" ? 1 : 0;
            int isAvailable = condition == "Good" ? 1 : 0;

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // ---------- 1. Update Transactions ----------
                        //  - return_date          : today
                        //  - status               : 'Returned'  (valid ENUM value)
                        //  - remarks              : free text
                        //  - is_damaged / is_lost : flag columns from the new schema
                        string updateTrans = @"
                            UPDATE Transactions
                            SET    return_date = @today,
                                   status      = 'Returned',
                                   remarks     = @remarks,
                                   is_damaged  = @isDamaged,
                                   is_lost     = @isLost
                            WHERE  transaction_id = @tid";

                        MySqlCommand cmdTrans = new MySqlCommand(updateTrans, conn, trans);
                        cmdTrans.Parameters.AddWithValue("@today", DateTime.Now.ToString("yyyy-MM-dd"));
                        cmdTrans.Parameters.AddWithValue("@tid", Convert.ToInt32(ViewState["CurrentTransID"]));
                        cmdTrans.Parameters.AddWithValue("@remarks", formattedRemarks);
                        cmdTrans.Parameters.AddWithValue("@isDamaged", isDamaged);
                        cmdTrans.Parameters.AddWithValue("@isLost", isLost);
                        cmdTrans.ExecuteNonQuery();

                        // ---------- 2. Update Item_Copies ----------
                        //  - status_condition : 'Good' | 'Damage' | 'Lost' (ENUM)
                        //  - is_available     : 1 only when returned in Good condition
                        //  - remarks          : same free-text field
                        string updateCopy = @"
                            UPDATE Item_Copies
                            SET    is_available     = @avail,
                                   status_condition = @cond,
                                   remarks          = @remarks
                            WHERE  accession_number = @acc";

                        MySqlCommand cmdCopy = new MySqlCommand(updateCopy, conn, trans);
                        cmdCopy.Parameters.AddWithValue("@avail", isAvailable);
                        cmdCopy.Parameters.AddWithValue("@cond", condition);
                        cmdCopy.Parameters.AddWithValue("@remarks", formattedRemarks);
                        cmdCopy.Parameters.AddWithValue("@acc", ViewState["CurrentAccession"].ToString());
                        cmdCopy.ExecuteNonQuery();

                        trans.Commit();

                        // ---------- 3. Append to the per-session live feed ----------
                        FeedItems.Insert(0, new FeedEntry
                        {
                            PatronName = litPatronName.Text,
                            PatronID = ViewState["CurrentUserID"]?.ToString(),
                            BookTitle = ViewState["CurrentTitle"]?.ToString(),
                            AccessionNumber = ViewState["CurrentAccession"]?.ToString(),
                            Condition = condition
                        });
                        if (FeedItems.Count > 20)
                            FeedItems.RemoveAt(FeedItems.Count - 1);

                        ResetForm();
                        BindFeed();
                        ShowSweetAlert("Success", "Book returned successfully!", "success");

                        UPReturn.Update();
                        UPLiveFeed.Update();
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        ShowSweetAlert("Error", ex.Message, "error");
                    }
                }
            }
        }

        private void ResetForm()
        {
            pnlReturnInfo.Visible = false;
            txtBookReturnQR.Text = "";
            txtReturnNote.Text = "";
            ddlCondition.SelectedIndex = 0;
            ViewState["CurrentTransID"] = null;
            ViewState["CurrentUserID"] = null;
            ViewState["CurrentAccession"] = null;
            ViewState["CurrentTitle"] = null;
        }

        private void BindFeed()
        {
            divAwaiting.Visible = (FeedItems.Count == 0);
            rptFeed.DataSource = FeedItems;
            rptFeed.DataBind();
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{cleanTitle}', text: '{cleanMsg}', icon: '{icon}', confirmButtonColor: '#10b981' }});";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}