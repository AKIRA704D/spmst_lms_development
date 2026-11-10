using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Catalog
{
    public partial class Reserved_Book : System.Web.UI.Page
    {
        private readonly string connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        /// <summary>
        /// Internal step state:
        ///   1 = notices
        ///   2 = location
        ///   3 = confirmation (pre-submit)
        ///   4 = success (post-commit)
        /// Persisted via ViewState so a postback never loses progress.
        /// </summary>
        private int CurrentStep
        {
            get { object v = ViewState["CurrentStep"]; return v == null ? 1 : (int)v; }
            set { ViewState["CurrentStep"] = value; }
        }

        private string CurrentBookId
        {
            get
            {
                object v = ViewState["BookId"];
                if (v != null && !string.IsNullOrEmpty(v.ToString())) return v.ToString();
                return Request.QueryString["BookID"] ?? string.Empty;
            }
            set
            {
                if (!string.IsNullOrEmpty(value)) ViewState["BookId"] = value;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack) return;

            string bookId = Request.QueryString["BookID"];
            if (!string.IsNullOrEmpty(bookId))
            {
                CurrentBookId = bookId;
                LoadBookDetails(bookId);
                ShowStep(1);
            }
            else
            {
                litTitle.Text = "Book not found";
                litAuthor.Text = string.Empty;
                litSection.Text = string.Empty;
                imgCover.ImageUrl = "~/Assets/Covers/default-cover.jpg";
                btnNext1.Enabled = false;
                ShowStep(1);
            }
        }

        private void LoadBookDetails(string bookId)
        {
            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();

                string bookQuery = @"SELECT title, author, section, cover_path
                                     FROM Library_Resources
                                     WHERE resource_id = @id";
                using (MySqlCommand cmd = new MySqlCommand(bookQuery, conn))
                {
                    cmd.Parameters.AddWithValue("@id", bookId);
                    using (MySqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            litTitle.Text = SafeStr(dr["title"], "Untitled");
                            litAuthor.Text = SafeStr(dr["author"], "Unknown Author");
                            litSection.Text = SafeStr(dr["section"], "General");
                            imgCover.ImageUrl = ResolveCoverUrl(dr["cover_path"] as string);
                        }
                        else
                        {
                            litTitle.Text = "Book not found";
                            litAuthor.Text = string.Empty;
                            litSection.Text = string.Empty;
                            imgCover.ImageUrl = "~/Assets/Covers/default-cover.jpg";
                            btnNext1.Enabled = false;
                        }
                    }
                }

                LoadLocations(conn, bookId);
            }
        }

        /// <summary>
        /// Populates rblLocations with only locations that currently have at
        /// least one eligible copy. A copy is eligible when:
        ///   - Item_Copies.is_available = 1
        ///   - Item_Copies.status_condition = 'Good'
        ///   - No conflicting active transaction
        ///     (Reserved / Ready / Borrowed / Renewal / Renewed)
        /// Value = MIN(accession_number) per (campus, specific_location).
        /// </summary>
        private void LoadLocations(MySqlConnection conn, string bookId)
        {
            const string locQuery = @"
                SELECT
                    c.campus,
                    c.specific_location,
                    MIN(c.accession_number) AS first_copy,
                    COUNT(*) AS available_count
                FROM Item_Copies c
                WHERE c.resource_id = @id
                  AND c.is_available = 1
                  AND c.status_condition = 'Good'
                  AND NOT EXISTS (
                      SELECT 1
                      FROM Transactions t
                      WHERE t.accession_number = c.accession_number
                        AND t.status IN ('Reserved','Ready','Borrowed','Renewal','Renewed')
                  )
                GROUP BY c.campus, c.specific_location
                ORDER BY c.campus, c.specific_location";

            rblLocations.Items.Clear();

            using (MySqlCommand cmd = new MySqlCommand(locQuery, conn))
            {
                cmd.Parameters.AddWithValue("@id", bookId);
                using (MySqlDataReader dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        string campus = SafeStr(dr["campus"], "Main Campus");
                        string loc = SafeStr(dr["specific_location"], "Circulation Desk");
                        string acc = SafeStr(dr["first_copy"]);
                        int count = Convert.ToInt32(dr["available_count"]);

                        string text = string.Format("{0} - {1} ({2} Available)",
                                                    campus, loc, count);

                        rblLocations.Items.Add(new ListItem(text, acc));
                    }
                }
            }

            bool hasLocations = rblLocations.Items.Count > 0;
            pnlNoLocations.Visible = !hasLocations;
            btnNext2.Enabled = hasLocations;

            if (hasLocations) rblLocations.SelectedIndex = 0;
        }

        // ============================================================
        // Step navigation (no DB writes on steps 1 and 2)
        // ============================================================

        protected void Step1Next_Click(object sender, EventArgs e)
        {
            // Nothing to validate — Step 1 is purely informational.
            ShowStep(2);
            upReservation.Update();
            TriggerParentResize();
        }

        protected void Step2Next_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(rblLocations.SelectedValue))
            {
                ShowAlert("Location Required",
                    "Please select a pickup location before continuing.",
                    "warning");
                return;
            }

            // Capture the selected pickup text for the confirmation view.
            litConfirmBook.Text = litTitle.Text;
            litConfirmLocation.Text = rblLocations.SelectedItem != null
                ? rblLocations.SelectedItem.Text
                : string.Empty;

            ShowStep(3);
            upReservation.Update();
            TriggerParentResize();
        }

        // ============================================================
        // FINAL SUBMIT — the ONLY place a reservation is written
        // ============================================================

        protected void Confirm_Click(object sender, EventArgs e)
        {
            // ---- 1. Agreement must be checked ----
            if (!chkTerms.Checked)
            {
                ShowAlert("Agreement Required",
                    "Please agree to the pickup terms before confirming your reservation.",
                    "warning");
                return;
            }

            // ---- 2. Session / copy sanity ----
            if (string.IsNullOrEmpty(rblLocations.SelectedValue))
            {
                // Defensive — should not happen because Step 2 required a value.
                ShowStep(2);
                upReservation.Update();
                TriggerParentResize();
                ShowAlert("Location Required",
                    "Please select a pickup location again.",
                    "warning");
                return;
            }

            string userId = Session["UserID"]?.ToString();
            if (string.IsNullOrEmpty(userId))
            {
                ShowAlert("Session Expired", "Please log in again.", "error");
                return;
            }

            string bookId = CurrentBookId;
            string selected = rblLocations.SelectedValue;
            string selectedText = rblLocations.SelectedItem != null
                ? rblLocations.SelectedItem.Text
                : string.Empty;

            using (MySqlConnection conn = new MySqlConnection(connStr))
            {
                conn.Open();
                using (MySqlTransaction trans = conn.BeginTransaction())
                {
                    try
                    {
                        // ---- 3. Lock + revalidate the copy ----
                        bool canReserve = false;

                        string checkSql = @"
                            SELECT is_available, status_condition, resource_id
                            FROM Item_Copies
                            WHERE accession_number = @acc
                            FOR UPDATE";
                        using (MySqlCommand cmd = new MySqlCommand(checkSql, conn, trans))
                        {
                            cmd.Parameters.AddWithValue("@acc", selected);
                            using (MySqlDataReader r = cmd.ExecuteReader())
                            {
                                if (r.Read())
                                {
                                    canReserve =
                                        Convert.ToInt32(r["is_available"]) == 1 &&
                                        string.Equals(r["status_condition"].ToString(),
                                                      "Good", StringComparison.OrdinalIgnoreCase) &&
                                        r["resource_id"].ToString() == bookId;
                                }
                            }
                        }

                        // ---- 4. Ensure no conflicting active transaction ----
                        if (canReserve)
                        {
                            string conflictSql = @"
                                SELECT 1 FROM Transactions
                                WHERE accession_number = @acc
                                  AND status IN ('Reserved','Ready','Borrowed','Renewal','Renewed')
                                LIMIT 1";
                            using (MySqlCommand cmd = new MySqlCommand(conflictSql, conn, trans))
                            {
                                cmd.Parameters.AddWithValue("@acc", selected);
                                canReserve = cmd.ExecuteScalar() == null;
                            }
                        }

                        if (!canReserve)
                        {
                            trans.Rollback();

                            // Refresh the available locations and send user back to Step 2.
                            LoadLocations(conn, bookId);
                            ShowStep(2);
                            upReservation.Update();
                            TriggerParentResize();
                            ShowAlert("Unavailable",
                                "This copy was just reserved by someone else. Please pick another location.",
                                "warning");
                            return;
                        }

                        // ---- 5. Insert reservation with status 'Reserved' ----
                        // status = 'Reserved' (NOT 'Ready'). The one-hour pickup
                        // window does not start until library staff set status = 'Ready',
                        // which updates Transactions.updated_at. The auto-cancel event
                        // derives its one-hour window from updated_at.
                        // borrow_date / due_date are placeholders (schema NOT NULL).
                        string ins = @"
                            INSERT INTO Transactions
                                (user_id, accession_number, borrow_date, due_date, status)
                            VALUES
                                (@uid, @acc, @bd, @dd, 'Reserved')";
                        using (MySqlCommand cmd = new MySqlCommand(ins, conn, trans))
                        {
                            cmd.Parameters.AddWithValue("@uid", userId);
                            cmd.Parameters.AddWithValue("@acc", selected);
                            cmd.Parameters.AddWithValue("@bd", DateTime.Today);
                            cmd.Parameters.AddWithValue("@dd", DateTime.Today);
                            cmd.ExecuteNonQuery();
                        }

                        // ---- 6. Flip availability ----
                        // AFTER UPDATE triggers cover Reserved → Ready / Borrowed
                        // transitions, but INSERTs do NOT fire AFTER UPDATE triggers,
                        // so the explicit flip is required here.
                        string upd = @"UPDATE Item_Copies
                                       SET is_available = 0
                                       WHERE accession_number = @acc";
                        using (MySqlCommand cmd = new MySqlCommand(upd, conn, trans))
                        {
                            cmd.Parameters.AddWithValue("@acc", selected);
                            cmd.ExecuteNonQuery();
                        }

                        trans.Commit();

                        // ---- 7. Move to success view ----
                        litTitleStep3.Text = litTitle.Text;
                        litPickupLocation.Text = selectedText;

                        ShowStep(4);
                        upReservation.Update();
                        TriggerParentResize();
                    }
                    catch (Exception)
                    {
                        try { trans.Rollback(); } catch { /* ignore */ }
                        ShowAlert("Error",
                            "Could not complete your reservation. Please try again.",
                            "error");
                    }
                }
            }
        }

        // ============================================================
        // Cancel / close (used by every Cancel + Browse More button)
        // ============================================================

        protected void Cancel_Click(object sender, EventArgs e)
        {
            // No DB write ever occurs on Cancel. Any partially collected state is
            // discarded when the modal closes and the iframe unloads.
            ScriptManager.RegisterStartupScript(this, GetType(), "CloseModal",
                "if (window.parent && window.parent.closeUniversalModal) window.parent.closeUniversalModal();",
                true);
        }

        // ============================================================
        // Step state & indicator
        // ============================================================

        private void ShowStep(int step)
        {
            CurrentStep = step;

            pnlStep1.Visible = step == 1;
            pnlStep2.Visible = step == 2;
            pnlStep3Confirm.Visible = step == 3;
            pnlStep3Success.Visible = step == 4;

            // Step indicator classes:
            //   step < n   → completed
            //   step == n  → active
            //   step > n   → default (gray outline)
            step1.CssClass = "step-item" +
                (step > 1 ? " completed" : step == 1 ? " active" : "");

            step2.CssClass = "step-item" +
                (step > 2 ? " completed" : step == 2 ? " active" : "");

            // Step 3 stays "active" through confirmation, then becomes
            // "completed" once the success view is shown.
            step3.CssClass = "step-item" +
                (step >= 4 ? " completed" : step == 3 ? " active" : "");
        }

        /// <summary>
        /// Asks the parent modal to re-measure our content height.
        /// Each step has a different natural height.
        /// </summary>
        private void TriggerParentResize()
        {
            ScriptManager.RegisterStartupScript(this, GetType(),
                "ResizeModal_" + Guid.NewGuid().ToString("N"),
                "setTimeout(function(){ if (window.parent && window.parent.resizeModalIframe) window.parent.resizeModalIframe(); }, 80);",
                true);
        }

        // ============================================================
        // Helpers
        // ============================================================

        private string ResolveCoverUrl(string coverPath)
        {
            const string fallback = "~/Assets/Covers/default-cover.jpg";
            if (string.IsNullOrWhiteSpace(coverPath)) return fallback;

            string normalized = coverPath.Trim()
                                         .TrimStart('~', '/', '\\')
                                         .Replace("\\", "/");
            if (string.IsNullOrEmpty(normalized)) return fallback;

            try
            {
                string physical = Server.MapPath("~/" + normalized);
                if (File.Exists(physical)) return "~/" + normalized;
            }
            catch { /* fall through */ }

            return fallback;
        }

        private static string SafeStr(object value, string fallback = "")
        {
            if (value == null || value == DBNull.Value) return fallback;
            string s = value.ToString();
            return string.IsNullOrWhiteSpace(s) ? fallback : s;
        }

        private void ShowAlert(string title, string message, string icon)
        {
            string script = string.Format(
                "Swal.fire({{ title: {0}, text: {1}, icon: {2}, confirmButtonColor: '#14532d' }});",
                JsStr(title), JsStr(message), JsStr(icon));
            ScriptManager.RegisterStartupScript(this, GetType(),
                "Alert_" + Guid.NewGuid().ToString("N"), script, true);
        }

        private static string JsStr(string s)
        {
            if (s == null) return "''";
            return "'" + s.Replace("\\", "\\\\")
                          .Replace("'", "\\'")
                          .Replace("\n", "\\n")
                          .Replace("\r", "") + "'";
        }
    }
}