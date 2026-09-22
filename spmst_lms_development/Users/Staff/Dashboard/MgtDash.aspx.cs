using MySql.Data.MySqlClient;
using spmst_lms_development.Assets.Helper;
using spmst_lms_development.Assets.Helper.Handlers;
using System;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Staff.Dashboard
{
    public partial class MgtDash : System.Web.UI.Page
    {
        private readonly AttendanceHelper _attendance = new AttendanceHelper();
        private readonly PatronAnalyticsHelper _patron = new PatronAnalyticsHelper();

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadKpis();
                RefreshAttendanceUI();
                RefreshPatronUI();
            }
        }

        private void LoadKpis()
        {
            try
            {
                var k = _attendance.GetManagementKpis();
                litKpiFacultyVisits.Text = k.FacultyVisits.ToString();
                litKpiStudentVisits.Text = k.StudentVisits.ToString();
                litKpiCurrentlyInside.Text = k.CurrentlyInside.ToString();
                litKpiTodayVisits.Text = k.TodayVisits.ToString();
                litKpiTotalFaculty.Text = k.TotalFaculty.ToString();
                litKpiTotalStudents.Text = k.TotalStudents.ToString();
                litKpiTotalPrograms.Text = k.TotalPrograms.ToString();
                litKpiTotalInstitutes.Text = k.TotalInstitutes.ToString();
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load KPI stats: " + ex.Message, "error");
            }
        }

        // ---------- Attendance side ----------
        private void RefreshAttendanceUI()
        {
            LoadOccupancy();
            LoadStayDuration();
            LoadAttendance(GetCurrentFilter(), txtAttSearch.Text.Trim());
        }

        private string GetCurrentFilter()
        {
            if (lnkFaculty.CssClass.Contains("active")) return "Faculty";
            if (lnkStudent.CssClass.Contains("active")) return "Student";
            return "All";
        }

        private void LoadOccupancy()
        {
            try
            {
                var s = _attendance.GetOccupancyStats();
                UpdateBar(pbTotal, litCurrentOccupancy, lblTotalPercent, s.Total, 100);
                UpdateBar(pbGeneral, litGeneralCount, null, s.StudyArea, 80);
                UpdateBar(pbVirtual, litVirtualCount, null, s.ResearchArea, 20);
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load occupancy stats: " + ex.Message, "error");
            }
        }

        private void UpdateBar(System.Web.UI.HtmlControls.HtmlGenericControl bar,
                               Literal lit,
                               System.Web.UI.HtmlControls.HtmlGenericControl percentLbl,
                               int count, int capacity)
        {
            double pct = capacity > 0 ? ((double)count / capacity) * 100 : 0;
            if (pct > 100) pct = 100;

            if (lit != null) lit.Text = count.ToString();
            if (bar != null)
            {
                bar.Style["width"] = pct.ToString("0") + "%";
                if (bar.ID == "pbTotal")
                {
                    if (pct > 85) bar.Attributes["class"] = "progress-bar bg-danger";
                    else if (pct > 50) bar.Attributes["class"] = "progress-bar bg-warning";
                    else bar.Attributes["class"] = "progress-bar bg-success";
                }
            }
            if (percentLbl != null) percentLbl.InnerText = pct.ToString("0") + "%";
        }

        private void LoadStayDuration()
        {
            try
            {
                var s = _attendance.GetStayDurationStats();
                litFacultyAvg.Text = FormatDuration(s.FacultyAvg);
                litStudentAvg.Text = FormatDuration(s.StudentAvg);

                double total = s.FacultyAvg + s.StudentAvg;
                double facPercent = total > 0 ? (s.FacultyAvg / total) * 100 : 50;
                chartCircle.Style["background"] =
                    $"conic-gradient(#0d6efd 0% {facPercent}%, #198754 {facPercent}% 100%)";
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load stay duration: " + ex.Message, "error");
            }
        }

        private string FormatDuration(double minutes)
        {
            if (minutes >= 60) return (minutes / 60.0).ToString("0.#") + "h";
            return Math.Round(minutes) + "m";
        }

        private void LoadAttendance(string roleFilter, string searchTerm)
        {
            try
            {
                DataTable dt = _attendance.GetAttendance(roleFilter, searchTerm);
                gvAttendance.DataSource = dt;
                gvAttendance.DataBind();
                litCount.Text = dt.Rows.Count.ToString();
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load attendance: " + ex.Message, "error");
            }
        }

        protected void Filter_Click(object sender, EventArgs e)
        {
            var btn = (LinkButton)sender;
            lnkAll.CssClass = "nav-link";
            lnkFaculty.CssClass = "nav-link";
            lnkStudent.CssClass = "nav-link";
            btn.CssClass = "nav-link active";
            RefreshAttendanceUI();
        }

        protected void txtAttSearch_TextChanged(object sender, EventArgs e)
        {
            LoadAttendance(GetCurrentFilter(), txtAttSearch.Text.Trim());
        }

        // ---------- Patron side ----------
        private void RefreshPatronUI()
        {
            try
            {
                rptPrograms.DataSource = _patron.GetTopPrograms();
                rptPrograms.DataBind();
                rptInstitutes.DataSource = _patron.GetTopInstitutes();
                rptInstitutes.DataBind();

                object dist = _patron.GetDistribution();
                litChartData.Text =
                    $"<script type='application/json' id='chartDataJSON'>{DbHelper.ToJson(dist)}</script>";

                LoadPenaltyTable("");
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load patron analytics: " + ex.Message, "error");
            }
        }

        private void LoadPenaltyTable(string searchTerm)
        {
            try
            {
                gvPenalties.DataSource = _patron.GetPenalties(searchTerm);
                gvPenalties.DataBind();
            }
            catch (Exception ex)
            {
                ShowSweetAlert("Error", "Failed to load penalties: " + ex.Message, "error");
            }
        }

        protected void txtPatronSearch_TextChanged(object sender, EventArgs e)
        {
            LoadPenaltyTable(txtPatronSearch.Text.Trim());
            upnlGridView.Update();
        }

        protected string GetProgressColor(int index)
        {
            string[] colors = { "bg-primary", "bg-success", "bg-warning", "bg-info", "bg-danger" };
            return colors[Math.Abs(index) % colors.Length];
        }

        // ---------- shared ----------
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