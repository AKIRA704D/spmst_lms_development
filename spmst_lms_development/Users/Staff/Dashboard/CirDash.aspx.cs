using spmst_lms_development.Assets.Helper;
using spmst_lms_development.Assets.Helper.Handlers;
using System;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Dashboard
{
    public partial class CirDash : System.Web.UI.Page
    {
        private readonly CirculationHelper _circ = new CirculationHelper();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                txtDateFrom.Text = DateTime.Now.AddDays(-30).ToString("yyyy-MM-dd");
                txtDateTo.Text = DateTime.Now.ToString("yyyy-MM-dd");

                LoadDashboardStats();
                LoadUnifiedAnalytics(txtDateFrom.Text, txtDateTo.Text);
                LoadTopBorrowedData();

                analyticsFrame.Attributes["src"] = ResolveUrl("~/Users/Admin/Dashboard/Analytics/Analytics_LowCirc.aspx");
            }
        }

        protected void btnFilter_Click(object sender, EventArgs e)
        {
            LoadUnifiedAnalytics(txtDateFrom.Text, txtDateTo.Text);
        }

        private void LoadDashboardStats()
        {
            try
            {
                var s = _circ.GetDashboardStats();
                litFacultyVisits.Text = s.FacultyVisits.ToString();
                litCirculated.Text = s.Circulated.ToString();
                litOverdue.Text = s.OverdueCount.ToString();
                litPendingFines.Text = s.PendingTotal.ToString("N0");
                litActivePatrons.Text = s.ActivePatrons.ToString();
                litDamageFines.Text = s.DamageCount.ToString();
                litLostBooks.Text = s.LostCount.ToString();
                litFinesCollected.Text = (Convert.ToDouble(s.Collected) / 1000.0).ToString("N1") + "k";
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load dashboard stats: " + ex.Message, "error");
            }
        }

        private void LoadUnifiedAnalytics(string start, string end)
        {
            try
            {
                string sectionJson = _circ.GetSectionJson(start, end);
                string subjectJson = _circ.GetSubjectJson(start, end);
                string instJson = _circ.GetInstituteJson(start, end);
                string progJson = _circ.GetProgramJson(start, end);

                var pen = _circ.GetPenaltyBreakdown(start, end);
                litTotalPenalties.Text = pen.TotalFine.ToString("N2");
                litTotalPaid.Text = pen.TotalPaid.ToString("N2");
                litTotalBalance.Text = pen.Balance.ToString("N2");

                var penaltyData = new
                {
                    amounts = new[] { pen.DamageAmt, pen.LostAmt, pen.OverdueAmt },
                    counts = new[] { pen.DamageCount, pen.LostCount, pen.OverdueCount }
                };
                string penaltyJson = DbHelper.ToJson(penaltyData);

                string script =
                    $"renderCharts({sectionJson}, {subjectJson}, {penaltyJson}, {instJson}, {progJson});";
                ScriptManager.RegisterStartupScript(this, GetType(), "loadCharts", script, true);
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load analytics: " + ex.Message, "error");
            }
        }

        private void LoadTopBorrowedData()
        {
            try
            {
                rptrTopBooks.DataSource = _circ.GetTopBorrowedBooks(5);
                rptrTopBooks.DataBind();
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load top books: " + ex.Message, "error");
            }
        }

        protected string GetBookIconClass(int index)
        {
            string[] cls = { "icon-book-purple","icon-book-green","icon-book-blue",
                             "icon-book-orange","icon-book-red" };
            return cls[index % cls.Length];
        }

        protected void rptrTopBooks_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item &&
                e.Item.ItemType != ListItemType.AlternatingItem) return;

            var row = (DataRowView)e.Item.DataItem;
            var imgCover = (Image)e.Item.FindControl("imgCover");
            var phDefaultIcon = (PlaceHolder)e.Item.FindControl("phDefaultIcon");
            string path = row["cover_path"]?.ToString();

            if (!string.IsNullOrEmpty(path) && System.IO.File.Exists(Server.MapPath("~/" + path)))
            {
                imgCover.ImageUrl = "~/" + path;
                imgCover.Visible = true;
                phDefaultIcon.Visible = false;
            }
            else
            {
                imgCover.Visible = false;
                phDefaultIcon.Visible = true;
            }
        }

        private void ShowSweetAlert(string title, string message, string icon)
        {
            string t = title.Replace("'", "\\'");
            string m = message.Replace("'", "\\'");
            string script = $"Swal.fire({{ title: '{t}', text: '{m}', icon: '{icon}', confirmButtonColor: '#0d6efd' }});";
            ScriptManager.RegisterStartupScript(this, GetType(),
                Guid.NewGuid().ToString(), script, true);
        }
    }
}