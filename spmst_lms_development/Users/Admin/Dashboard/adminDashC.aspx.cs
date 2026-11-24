using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using spmst_lms_development.Assets.Helper.Handlers;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    /// <summary>
    /// Admin Dashboard shell (Circulation / Patrons / Attendance).
    ///
    /// All card data is loaded by DashboardData.ashx (fetch/JSON), so this page only:
    ///   1. authorises the signed-in role (DashboardAccess - single source of truth),
    ///   2. renders ONLY the tabs/panels that role may see (restricted markup is never sent),
    ///   3. loads the server-side KPI figures when the role may see Circulation.
    /// The handler enforces the same matrix again on every data request, so hiding a tab is never
    /// the only protection.
    /// </summary>
    public partial class adminDashC : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        // =================================================================
        // ROLE-BASED TAB VISIBILITY (from the session role, never from the client)
        // =================================================================
        protected bool ShowCircTab { get { return DashboardAccess.CanAccessCurrent(DashTab.Circulation); } }
        protected bool ShowPatronTab { get { return DashboardAccess.CanAccessCurrent(DashTab.Patrons); } }
        protected bool ShowAttendTab { get { return DashboardAccess.CanAccessCurrent(DashTab.Attendance); } }

        /// <summary>Key of the first tab visible to this role ("circ", "patron", "attend" or "").</summary>
        protected string PrimaryTab { get { return DashboardAccess.PrimaryTabKey(); } }

        /// <summary>"active" if the supplied tab is the primary tab for this role.</summary>
        protected string ActiveTabClass(string tabKey) { return PrimaryTab == tabKey ? "active" : ""; }

        /// <summary>"show active" if the supplied pane is the primary pane for this role.</summary>
        protected string ActivePaneClass(string tabKey) { return PrimaryTab == tabKey ? "show active" : ""; }

        /// <summary>Initial values of the Library Trends date inputs (the data call re-confirms them).</summary>
        protected string TrendsFrom { get { return DateTime.Today.AddDays(-30).ToString("yyyy-MM-dd"); } }
        protected string TrendsTo { get { return DateTime.Today.ToString("yyyy-MM-dd"); } }

        // =================================================================
        // PAGE LOAD
        // =================================================================
        protected void Page_Load(object sender, EventArgs e)
        {
            // Strip every restricted panel first, so nothing can be rendered by accident.
            phKpi.Visible = ShowCircTab;
            phTabCirc.Visible = ShowCircTab;
            phTabPatron.Visible = ShowPatronTab;
            phTabAttend.Visible = ShowAttendTab;
            phCircPanel.Visible = ShowCircTab;
            phPatronPanel.Visible = ShowPatronTab;
            phAttendPanel.Visible = ShowAttendTab;

            // --- Only Admin / StaffC / StaffM may view this page at all ---
            if (!DashboardAccess.CanAccessAny())
            {
                string target = sessionHelper.IsLoggedIn() ? sessionHelper.GetDashboardPath() : "~/Login/login.aspx";
                Response.Redirect(target, false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            if (!IsPostBack && ShowCircTab)
            {
                LoadDashboardStats();
            }
        }

        // =================================================================
        // DATA LOADERS
        // =================================================================
        private void LoadDashboardStats()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT 
                        (SELECT COUNT(*) FROM Library_Attendance la 
                            INNER JOIN Faculty f ON la.user_id = f.faculty_id) as FacultyVisits,
                        (SELECT COUNT(*) FROM Transactions WHERE status = 'Borrowed') as Circulated,
                        (SELECT COUNT(*) FROM Transactions 
                            WHERE status = 'Borrowed' AND due_date < CURDATE()) as OverdueCount,
                        (SELECT IFNULL(SUM(fine_amount - amount_paid), 0) 
                            FROM Penalties) as PendingTotal,
                        (SELECT COUNT(DISTINCT user_id) FROM Library_Attendance) as ActivePatrons,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Damage') as DamageCount,
                        (SELECT COUNT(*) FROM Item_Copies WHERE status_condition = 'Lost') as LostCount,
                        (SELECT IFNULL(SUM(amount_paid), 0) FROM Penalties) as Collected";

                try
                {
                    conn.Open();
                    using (MySqlCommand cmd = new MySqlCommand(query, conn))
                    {
                        // Extended timeout for remote database
                        cmd.CommandTimeout = 60;

                        using (MySqlDataReader dr = cmd.ExecuteReader())
                        {
                            if (dr.Read())
                            {
                                litFacultyVisits.Text = dr["FacultyVisits"].ToString();
                                litCirculated.Text = dr["Circulated"].ToString();
                                litOverdue.Text = dr["OverdueCount"].ToString();
                                litPendingFines.Text = Convert.ToDecimal(dr["PendingTotal"]).ToString("N0");
                                litActivePatrons.Text = dr["ActivePatrons"].ToString();
                                litDamageFines.Text = dr["DamageCount"].ToString();
                                litLostBooks.Text = dr["LostCount"].ToString();
                                litFinesCollected.Text = (Convert.ToDouble(dr["Collected"]) / 1000.0).ToString("N1") + "k";
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    // Prevent the entire page from crashing if the DB is slow
                    System.Diagnostics.Trace.TraceError("Dashboard DB Error: " + ex.Message);
                }
            }
        }
    }
}
