using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    public partial class Analytics_PeakHours : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadPeakData();
            }
        }

        private void LoadPeakData()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();

                // 1. Entries grouped by hour (time_in)
                string entriesQuery = @"
                    SELECT HOUR(time_in) AS Hour, COUNT(*) AS Count
                    FROM Library_Attendance
                    WHERE time_in IS NOT NULL
                      AND time_in >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                    GROUP BY HOUR(time_in)
                    ORDER BY Hour";

                DataTable dtEntries = new DataTable();
                using (MySqlCommand cmd = new MySqlCommand(entriesQuery, conn))
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                {
                    da.Fill(dtEntries);
                }
                gvEntries.DataSource = dtEntries;
                gvEntries.DataBind();

                // 2. Exits grouped by hour (time_out)
                string exitsQuery = @"
                    SELECT HOUR(time_out) AS Hour, COUNT(*) AS Count
                    FROM Library_Attendance
                    WHERE time_out IS NOT NULL
                      AND time_out >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                    GROUP BY HOUR(time_out)
                    ORDER BY Hour";

                DataTable dtExits = new DataTable();
                using (MySqlCommand cmd = new MySqlCommand(exitsQuery, conn))
                using (MySqlDataAdapter da = new MySqlDataAdapter(cmd))
                {
                    da.Fill(dtExits);
                }
                gvExits.DataSource = dtExits;
                gvExits.DataBind();

                // 3. Prepare data for Chart.js
                // Merge all hours 0-23, fill missing with 0
                int[] entriesByHour = new int[24];
                int[] exitsByHour = new int[24];

                foreach (DataRow row in dtEntries.Rows)
                {
                    int hour = Convert.ToInt32(row["Hour"]);
                    entriesByHour[hour] = Convert.ToInt32(row["Count"]);
                }
                foreach (DataRow row in dtExits.Rows)
                {
                    int hour = Convert.ToInt32(row["Hour"]);
                    exitsByHour[hour] = Convert.ToInt32(row["Count"]);
                }

                // Build labels (0-23)
                List<string> labels = new List<string>();
                for (int i = 0; i < 24; i++)
                {
                    labels.Add(i.ToString("00") + ":00");
                }

                // Serialize to JSON for JavaScript
                string labelsJson = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(labels);
                string entriesJson = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(entriesByHour);
                string exitsJson = new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(exitsByHour);

                string script = $"renderPeakChart({labelsJson}, {entriesJson}, {exitsJson});";
                ScriptManager.RegisterStartupScript(this, GetType(), "peakChart", script, true);

                // 4. Diagnostic Insights
                GenerateInsights(entriesByHour, exitsByHour);
            }
        }

        private void GenerateInsights(int[] entries, int[] exits)
        {
            // Find peak entry hour and peak exit hour
            int maxEntries = 0, peakEntryHour = 0;
            int maxExits = 0, peakExitHour = 0;
            for (int i = 0; i < 24; i++)
            {
                if (entries[i] > maxEntries)
                {
                    maxEntries = entries[i];
                    peakEntryHour = i;
                }
                if (exits[i] > maxExits)
                {
                    maxExits = exits[i];
                    peakExitHour = i;
                }
            }

            // Calculate total entries and exits
            int totalEntries = 0, totalExits = 0;
            foreach (int e in entries) totalEntries += e;
            foreach (int x in exits) totalExits += x;

            string insight = $@"
                <div class='row'>
                    <div class='col-md-4'>
                        <div class='card bg-light'>
                            <div class='card-body text-center'>
                                <h6 class='card-title'>Peak Entry Hour</h6>
                                <h4 class='text-primary'>{peakEntryHour:00}:00 - {peakEntryHour + 1:00}:00</h4>
                                <p class='small text-muted'>{maxEntries} entries</p>
                            </div>
                        </div>
                    </div>
                    <div class='col-md-4'>
                        <div class='card bg-light'>
                            <div class='card-body text-center'>
                                <h6 class='card-title'>Peak Exit Hour</h6>
                                <h4 class='text-warning'>{peakExitHour:00}:00 - {peakExitHour + 1:00}:00</h4>
                                <p class='small text-muted'>{maxExits} exits</p>
                            </div>
                        </div>
                    </div>
                    <div class='col-md-4'>
                        <div class='card bg-light'>
                            <div class='card-body text-center'>
                                <h6 class='card-title'>Total Attendance</h6>
                                <h4>{totalEntries} Entries / {totalExits} Exits</h4>
                            </div>
                        </div>
                    </div>
                </div>
                <hr />
                <p class='mb-0'><i class='fas fa-info-circle me-2'></i> 
                <strong>Diagnostic:</strong> 
                Peak entry occurs around {peakEntryHour:00}:00, likely corresponding to class start times.
                Peak exit occurs around {peakExitHour:00}:00, coinciding with class end times. 
                The library sees steady traffic throughout the day.
                </p>
            ";

            litInsights.Text = insight;
        }
    }
}