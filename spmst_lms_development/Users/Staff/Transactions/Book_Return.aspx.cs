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
        private static List<object> FeedItems = new List<object>();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Set active tab
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
                string query = @"
                    SELECT t.transaction_id, t.user_id, r.title, r.author, t.accession_number,
                           COALESCE(s.first_name, f.first_name, st.first_name) as fname,
                           COALESCE(s.last_name, f.last_name, st.last_name) as lname,
                           COALESCE(s.course, f.institute, st.office_department) as dept
                    FROM Transactions t
                    INNER JOIN Item_Copies c ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r ON c.resource_id = r.resource_id
                    LEFT JOIN Students s ON t.user_id = s.student_id
                    LEFT JOIN Faculty f ON t.user_id = f.faculty_id
                    LEFT JOIN Staff st ON t.user_id = st.staff_id
                    WHERE t.accession_number = @acc AND t.status = 'Borrowed' AND t.return_date IS NULL";

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
                            litPatronName.Text = $"{reader["fname"]} {reader["lname"]}";
                            litPatronDept.Text = reader["dept"].ToString();
                            ViewState["CurrentUserID"] = reader["user_id"].ToString();
                            ViewState["CurrentTransID"] = reader["transaction_id"];
                            pnlReturnInfo.Visible = true;
                        }
                        else
                        {
                            pnlReturnInfo.Visible = false;
                            txtBookReturnQR.Text = "";
                            ShowSweetAlert("Not Found", "No active borrow record found for this book.", "warning");
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

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        string condition = ddlCondition.SelectedValue;
                        string rawNote = txtReturnNote.Text.Trim();
                        string formattedRemarks = string.IsNullOrEmpty(rawNote) ? condition : $"{condition} - {rawNote}";

                        // Update transaction
                        string updateTrans = @"
                            UPDATE Transactions 
                            SET return_date = @today, status = 'Returned', remarks = @remarks
                            WHERE transaction_id = @tid";
                        MySqlCommand cmdTrans = new MySqlCommand(updateTrans, conn, trans);
                        cmdTrans.Parameters.AddWithValue("@today", DateTime.Now.ToString("yyyy-MM-dd"));
                        cmdTrans.Parameters.AddWithValue("@tid", ViewState["CurrentTransID"]);
                        cmdTrans.Parameters.AddWithValue("@remarks", formattedRemarks);
                        cmdTrans.ExecuteNonQuery();

                        // Update item copy
                        int isAvailable = (condition == "Good") ? 1 : 0;
                        string updateCopy = @"
                            UPDATE Item_Copies 
                            SET is_available = @avail, status_condition = @cond, remarks = @remarks
                            WHERE accession_number = @acc";
                        MySqlCommand cmdCopy = new MySqlCommand(updateCopy, conn, trans);
                        cmdCopy.Parameters.AddWithValue("@avail", isAvailable);
                        cmdCopy.Parameters.AddWithValue("@cond", condition);
                        cmdCopy.Parameters.AddWithValue("@remarks", formattedRemarks);
                        cmdCopy.Parameters.AddWithValue("@acc", litAccNo.Text);
                        cmdCopy.ExecuteNonQuery();

                        trans.Commit();

                        // Add to live feed
                        string patronId = ViewState["CurrentUserID"]?.ToString();
                        string patronName = litPatronName.Text;
                        string bookTitle = litBookTitle.Text;
                        string accession = litAccNo.Text;
                        FeedItems.Insert(0, new { PatronName = patronName, PatronID = patronId, BookTitle = bookTitle, AccessionNumber = accession, Condition = condition });
                        if (FeedItems.Count > 20) FeedItems.RemoveAt(FeedItems.Count - 1);

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