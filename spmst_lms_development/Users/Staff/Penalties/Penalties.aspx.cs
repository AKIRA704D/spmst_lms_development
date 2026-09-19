using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web.Services;

namespace spmst_lms_development.Users.Staff.Penalties
{
    public partial class Penalties : System.Web.UI.Page
    {
        private static readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        [WebMethod]
        public static List<PenaltyRecord> GetPenalties()
        {
            List<PenaltyRecord> list = new List<PenaltyRecord>();
            const decimal DAILY_RATE = 50.00m;
            const decimal DAMAGE_FEE = 100.00m;
            const decimal LOST_FEE = 200.00m;

            string query = @"
                SELECT 
                    t.transaction_id, t.user_id, t.due_date, t.return_date, t.status, t.accession_number,
                    t.fine_amount as db_fine_amount, t.amount_paid as db_amount_paid,
                    COALESCE(CONCAT(s.first_name, ' ', s.last_name), CONCAT(f.first_name, ' ', f.last_name), 'Unknown') as FullName,
                    r.title, ic.status_condition
                FROM Transactions t
                LEFT JOIN Students s ON t.user_id = s.student_id
                LEFT JOIN Faculty f ON t.user_id = f.faculty_id
                INNER JOIN Item_Copies ic ON t.accession_number = ic.accession_number
                INNER JOIN Library_Resources r ON ic.resource_id = r.resource_id
                WHERE t.status IN ('Borrowed', 'Overdue', 'Returned')
                  AND (t.fine_status != 'Paid' OR t.fine_status IS NULL)";

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                MySqlCommand cmd = new MySqlCommand(query, conn);
                conn.Open();
                using (MySqlDataReader dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        decimal calculatedFine = 0;
                        string transStatus = dr["status"].ToString();
                        string bookCondition = dr["status_condition"].ToString();
                        DateTime dbDueDate = Convert.ToDateTime(dr["due_date"]).Date;
                        List<string> penaltyLabels = new List<string>();

                        DateTime calculationEndDate = (transStatus == "Returned" && dr["return_date"] != DBNull.Value)
                            ? Convert.ToDateTime(dr["return_date"]).Date
                            : DateTime.Now.Date;

                        // Overdue calculation
                        if (calculationEndDate > dbDueDate)
                        {
                            int overdueDays = (calculationEndDate - dbDueDate).Days;
                            if (overdueDays > 0)
                            {
                                calculatedFine += (overdueDays * DAILY_RATE);
                                penaltyLabels.Add($"Overdue ({overdueDays} days)");
                            }
                        }

                        // Damage/Lost fees (only for returned or overdue)
                        if (transStatus == "Returned" || transStatus == "Overdue")
                        {
                            if (bookCondition == "Damage")
                            {
                                calculatedFine += DAMAGE_FEE;
                                penaltyLabels.Add("Damaged");
                            }
                            else if (bookCondition == "Lost")
                            {
                                calculatedFine += LOST_FEE;
                                penaltyLabels.Add("Lost");
                            }
                        }

                        decimal dbFineAmount = dr["db_fine_amount"] != DBNull.Value ? Convert.ToDecimal(dr["db_fine_amount"]) : 0;
                        decimal dbAmountPaid = dr["db_amount_paid"] != DBNull.Value ? Convert.ToDecimal(dr["db_amount_paid"]) : 0;

                        decimal totalFine = Math.Max(calculatedFine, dbFineAmount);
                        decimal currentBalance = totalFine - dbAmountPaid;

                        if (currentBalance > 0)
                        {
                            list.Add(new PenaltyRecord
                            {
                                TransactionID = dr["transaction_id"].ToString(),
                                UserID = dr["user_id"].ToString(),
                                PatronName = dr["FullName"].ToString(),
                                Book = dr["title"].ToString(),
                                AccessionNumber = dr["accession_number"].ToString(),
                                Reason = penaltyLabels.Count > 0 ? string.Join(" + ", penaltyLabels) : "Penalty",
                                Amount = totalFine,
                                Balance = currentBalance,
                                Status = transStatus
                            });
                        }
                    }
                }
            }
            return list;
        }

        public class PenaltyRecord
        {
            public string TransactionID { get; set; }
            public string UserID { get; set; }
            public string PatronName { get; set; }
            public string Book { get; set; }
            public string AccessionNumber { get; set; }
            public string Reason { get; set; }
            public decimal Amount { get; set; }
            public decimal Balance { get; set; }
            public string Status { get; set; }
        }
    }
}