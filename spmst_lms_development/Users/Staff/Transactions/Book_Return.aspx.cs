using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using spmst_lms_development.Assets.Helper.Notifications;
using spmst_lms_development.Assets.Services;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web.Hosting;
using System.Web.UI;

namespace spmst_lms_development.Users.Staff.Transactions
{
    public partial class Book_Return : System.Web.UI.Page
    {
        private readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        // Per-session live feed
        private List<FeedEntry> FeedItems
        {
            get
            {
                if (Session["ReturnFeed"] == null)
                    Session["ReturnFeed"] = new List<FeedEntry>();
                return (List<FeedEntry>)Session["ReturnFeed"];
            }
        }

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
                string query = @"
                    SELECT  t.transaction_id,
                            t.user_id,
                            t.accession_number,
                            t.due_date,
                            r.title,
                            r.author,
                            COALESCE(s.first_name, f.first_name, st.first_name) AS fname,
                            COALESCE(s.last_name,  f.last_name,  st.last_name ) AS lname,
                            COALESCE(s.course, f.institute, st.office_department) AS dept
                    FROM Transactions t
                    INNER JOIN Item_Copies       c  ON t.accession_number = c.accession_number
                    INNER JOIN Library_Resources r  ON c.resource_id      = r.resource_id
                    LEFT  JOIN Students          s  ON t.user_id          = s.student_id
                    LEFT  JOIN Faculty           f  ON t.user_id          = f.faculty_id
                    LEFT  JOIN Staff             st ON t.user_id          = st.staff_id
                    WHERE t.accession_number = @acc
                      AND t.status           = 'Borrowed'
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
                            ViewState["CurrentDueDate"] = Convert.ToDateTime(reader["due_date"]);

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

            string formattedRemarks = string.IsNullOrEmpty(rawNote)
                ? condition
                : $"{condition} - {rawNote}";

            int isDamaged = condition == "Damage" ? 1 : 0;
            int isLost = condition == "Lost" ? 1 : 0;
            int isAvailable = condition == "Good" ? 1 : 0;

            int transactionId = Convert.ToInt32(ViewState["CurrentTransID"]);
            string userId = ViewState["CurrentUserID"]?.ToString();
            string accession = ViewState["CurrentAccession"]?.ToString();

            DateTime dueDate = ViewState["CurrentDueDate"] != null
                               ? (DateTime)ViewState["CurrentDueDate"]
                               : DateTime.Today;

            // We keep this for the success UI message later
            var penalty = FinePolicy.Calculate(
                dueDate: dueDate,
                returnDate: DateTime.Today,
                isDamaged: isDamaged == 1,
                isLost: isLost == 1);

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // ---------- 1. Update Transactions ----------
                        string updateTrans = @"
                            UPDATE Transactions
                               SET return_date = @today,
                                   status      = 'Returned',
                                   remarks     = @remarks,
                                   is_damaged  = @isDamaged,
                                   is_lost     = @isLost
                             WHERE transaction_id = @tid";
                        MySqlCommand cmdTrans = new MySqlCommand(updateTrans, conn, trans);
                        cmdTrans.Parameters.AddWithValue("@today", DateTime.Today);
                        cmdTrans.Parameters.AddWithValue("@tid", transactionId);
                        cmdTrans.Parameters.AddWithValue("@remarks", formattedRemarks);
                        cmdTrans.Parameters.AddWithValue("@isDamaged", isDamaged);
                        cmdTrans.Parameters.AddWithValue("@isLost", isLost);
                        cmdTrans.ExecuteNonQuery();

                        // ---------- 2. Update Item_Copies ----------
                        string updateCopy = @"
                            UPDATE Item_Copies
                               SET is_available     = @avail,
                                   status_condition = @cond,
                                   remarks          = @remarks
                             WHERE accession_number = @acc";
                        MySqlCommand cmdCopy = new MySqlCommand(updateCopy, conn, trans);
                        cmdCopy.Parameters.AddWithValue("@avail", isAvailable);
                        cmdCopy.Parameters.AddWithValue("@cond", condition);
                        cmdCopy.Parameters.AddWithValue("@remarks", formattedRemarks);
                        cmdCopy.Parameters.AddWithValue("@acc", accession);
                        cmdCopy.ExecuteNonQuery();

                        // ---------- 3. REMOVED MANUAL PENALTY INSERT ----------
                        // The old INSERT INTO Penalties is deleted here.
                        // We will let PenaltyService.SyncPenalties() do it after commit.

                        trans.Commit();

                        // ---------- 4. SYNC PENALTIES ----------
                        // This safely creates/updates the Penalties and Penalty_Components
                        try
                        {
                            PenaltyService.SyncPenalties();
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Trace.TraceError("[Book_Return] SyncPenalties failed: " + ex.Message);
                        }

                        // ---------- 5. Append to per-session live feed ----------
                        FeedItems.Insert(0, new FeedEntry
                        {
                            PatronName = litPatronName.Text,
                            PatronID = userId,
                            BookTitle = ViewState["CurrentTitle"]?.ToString(),
                            AccessionNumber = accession,
                            Condition = condition
                        });
                        if (FeedItems.Count > 20)
                            FeedItems.RemoveAt(FeedItems.Count - 1);

                        ResetForm();
                        BindFeed();

                        // ---------- 6. Queue background notification ----------
                        if (penalty.HasPenalty)
                        {
                            int txnSnapshot = transactionId;
                            HostingEnvironment.QueueBackgroundWorkItem(ct =>
                            {
                                try
                                {
                                    PenaltyNotificationService.SendPenaltyNotifications(txnSnapshot);
                                }
                                catch (Exception ex)
                                {
                                    System.Diagnostics.Trace.TraceError(
                                        "[Book_Return] BG penalty notify failed txn=" + txnSnapshot + ": " + ex.Message);
                                }
                            });
                        }

                        // Show fine summary in the success alert
                        if (penalty.HasPenalty)
                        {
                            ShowSweetAlert("Success",
                                $"Book returned. Penalty recorded: " +
                                $"{FinePolicy.DescribeType(penalty.PenaltyType)} — " +
                                $"{FinePolicy.FormatAmount(penalty.FineAmount)}",
                                "success");
                        }
                        else
                        {
                            ShowSweetAlert("Success", "Book returned successfully!", "success");
                        }

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
            ViewState["CurrentDueDate"] = null;
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