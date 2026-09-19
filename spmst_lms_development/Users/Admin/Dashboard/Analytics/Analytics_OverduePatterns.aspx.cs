using MySql.Data.MySqlClient;
using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace spmst_lms_development.Users.Admin.Dashboard
{
    public partial class Analytics_OverduePatterns : System.Web.UI.Page
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadOverduePatterns();
            }
        }

        private void LoadOverduePatterns()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                // Updated query:
                // - TotalBorrows now includes Reserved and Ready
                // - AvgDaysOverdue rounded to whole number
                string query = @"
                    SELECT 
                        Title,
                        Author,
                        ISBN_ISSN,
                        Section,
                        OverdueCount,
                        AvgDaysOverdue,
                        LastOverdueDate,
                        TotalBorrows,
                        CASE 
                            WHEN OverdueCount >= 5 AND TotalBorrows >= 10 THEN 'High Demand + Overdue'
                            WHEN AvgDaysOverdue > 10 THEN 'Extended Loan Period'
                            WHEN OverdueCount >= 3 AND AvgDaysOverdue > 5 THEN 'Moderate Overdue Risk'
                            ELSE 'Low Overdue Rate'
                        END AS Reason,
                        CASE 
                            WHEN OverdueCount >= 5 AND TotalBorrows >= 10 THEN 'This book is very popular; many users borrow it and often return late.'
                            WHEN AvgDaysOverdue > 10 THEN 'Users keep this book for an extended period, exceeding the loan period.'
                            WHEN OverdueCount >= 3 AND AvgDaysOverdue > 5 THEN 'Frequent but moderate overdue; may need shorter loan period or reminders.'
                            ELSE 'Overdue is uncommon for this book; current loan periods seem appropriate.'
                        END AS Explanation
                    FROM (
                        SELECT 
                            lr.title AS Title,
                            lr.author AS Author,
                            COALESCE(lr.isbn, lr.issn) AS ISBN_ISSN,
                            lr.section AS Section,
                            COUNT(t.transaction_id) AS OverdueCount,
                            ROUND(AVG(
                                CASE 
                                    WHEN t.return_date IS NULL THEN DATEDIFF(CURDATE(), t.due_date)
                                    ELSE DATEDIFF(t.return_date, t.due_date)
                                END
                            ), 0) AS AvgDaysOverdue,
                            MAX(t.due_date) AS LastOverdueDate,
                            -- Total Borrows: now includes Reserved and Ready
                            (SELECT COUNT(*) 
                             FROM Transactions t2 
                             INNER JOIN Item_Copies ic2 ON t2.accession_number = ic2.accession_number 
                             WHERE ic2.resource_id = lr.resource_id 
                               AND t2.status NOT IN ('Cancelled')) AS TotalBorrows
                        FROM Library_Resources lr
                        INNER JOIN Item_Copies ic ON lr.resource_id = ic.resource_id
                        INNER JOIN Transactions t ON ic.accession_number = t.accession_number
                        WHERE (t.status = 'Overdue' 
                               OR (t.due_date < CURDATE() AND t.return_date IS NULL)
                               OR (t.return_date > t.due_date))
                          AND t.status NOT IN ('Cancelled')
                        GROUP BY lr.resource_id
                        HAVING OverdueCount > 0
                    ) AS OverdueData
                    ORDER BY OverdueCount DESC, AvgDaysOverdue DESC
                    LIMIT 15";

                conn.Open();
                DataTable dt = new DataTable();
                new MySqlDataAdapter(query, conn).Fill(dt);
                gvOverduePatterns.DataSource = dt;
                gvOverduePatterns.DataBind();
            }
        }

        protected string GetBadgeClass(string reason)
        {
            if (reason == "High Demand + Overdue")
                return "bg-danger text-white";
            else if (reason == "Extended Loan Period")
                return "bg-warning text-dark";
            else if (reason == "Moderate Overdue Risk")
                return "bg-info text-white";
            else
                return "bg-secondary text-white";
        }
    }
}