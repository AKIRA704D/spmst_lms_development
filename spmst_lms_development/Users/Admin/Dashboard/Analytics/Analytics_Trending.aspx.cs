using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    public partial class Analytics_Trending : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadTrendingBooks();
            }
        }

        private void LoadTrendingBooks()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                string query = @"
                    SELECT 
                        lr.title AS Title,
                        lr.author AS Author,
                        COALESCE(lr.isbn, lr.issn) AS ISBN_ISSN,
                        lr.section AS Section,
                        COUNT(t.transaction_id) AS Borrows,
                        IFNULL(MAX(t.borrow_date), 'Never') AS LastBorrowed,
                        CASE 
                            WHEN COUNT(t.transaction_id) >= 20 THEN 'High Demand'
                            WHEN COUNT(t.transaction_id) >= 10 THEN 'Moderate Demand'
                            ELSE 'Rising Popularity'
                        END AS Reason,
                        CASE 
                            WHEN COUNT(t.transaction_id) >= 20 THEN 'This book is in extremely high demand – likely a core textbook or popular title.'
                            WHEN COUNT(t.transaction_id) >= 10 THEN 'Consistently borrowed; may be required reading or a frequently referenced work.'
                            WHEN MAX(t.borrow_date) > DATE_SUB(NOW(), INTERVAL 1 MONTH) THEN 'Recently gained popularity – possibly due to new course adoption or current events.'
                            ELSE 'Steady interest – a reliable resource for users.'
                        END AS Explanation
                    FROM Library_Resources lr
                    INNER JOIN Item_Copies ic ON lr.resource_id = ic.resource_id
                    INNER JOIN Transactions t ON ic.accession_number = t.accession_number
                    WHERE t.status NOT IN ('Cancelled')
                    GROUP BY lr.resource_id
                    ORDER BY Borrows DESC
                    LIMIT 10";

                conn.Open();
                DataTable dt = new DataTable();
                new MySqlDataAdapter(query, conn).Fill(dt);
                gvTrendingBooks.DataSource = dt;
                gvTrendingBooks.DataBind();
            }
        }
    }
}