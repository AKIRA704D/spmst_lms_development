using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Dashboard.Analytics
{
    public partial class Analytics_LowCirc : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadLowCirculationData();
            }
        }

        private void LoadLowCirculationData()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT lr.title AS Title, lr.section AS Category, COUNT(t.transaction_id) AS Borrows,
                        IFNULL(MAX(t.borrow_date), 'Never') AS LastBorrowed,
                        CASE WHEN COUNT(t.transaction_id)=0 THEN 'No Curriculum Match'
                             WHEN MAX(t.borrow_date) < DATE_SUB(NOW(), INTERVAL 1 YEAR) THEN 'Outdated Content'
                             ELSE 'Niche Subject' END AS Reason,
                        CASE WHEN COUNT(t.transaction_id)=0 THEN 'This book has never been borrowed; it may not align with current course offerings.'
                             WHEN MAX(t.borrow_date) < DATE_SUB(NOW(), INTERVAL 1 YEAR) THEN 'The content may be obsolete or replaced by newer editions.'
                             ELSE 'This item covers a highly specific topic with a limited target audience.' END AS Explanation
                    FROM Library_Resources lr
                    LEFT JOIN Item_Copies ic ON lr.resource_id = ic.resource_id
                    LEFT JOIN Transactions t ON ic.accession_number = t.accession_number
                    GROUP BY lr.resource_id HAVING Borrows < 5 ORDER BY Borrows ASC";

                conn.Open();
                DataTable dt = new DataTable();
                new MySqlDataAdapter(query, conn).Fill(dt);
                gvLowCirculation.DataSource = dt;
                gvLowCirculation.DataBind();
            }
        }

        protected string GetBadgeClass(string reason)
        {
            if (reason == "No Curriculum Match")
                return "bg-danger text-white";
            else if (reason == "Outdated Content")
                return "bg-warning text-dark";
            else if (reason == "Niche Subject")
                return "bg-info text-dark";
            else
                return "bg-secondary text-white";
        }
    }
}