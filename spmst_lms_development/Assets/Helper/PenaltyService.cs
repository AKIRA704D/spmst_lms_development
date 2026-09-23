using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;

namespace spmst_lms_development.Assets.Helper
{
    public static class PenaltyService
    {
        private static readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        private const decimal DAILY_RATE = 50.00m;
        private const decimal DAMAGE_FEE = 100.00m;
        private const decimal LOST_FEE = 200.00m;

        // =============================================================
        // DTOs
        // =============================================================
        public class PenaltyRecord
        {
            public int PenaltyID { get; set; }
            public int TransactionID { get; set; }
            public string UserID { get; set; }
            public string PatronName { get; set; }
            public string Book { get; set; }
            public string AccessionNumber { get; set; }
            public string PenaltyType { get; set; }
            public string Reason { get; set; }
            public decimal Amount { get; set; }
            public decimal Balance { get; set; }
            public string Status { get; set; }
        }

        private class CalculatedPenalty
        {
            public int TransactionID;
            public string UserID;
            public string AccessionNumber;
            public string PenaltyType;
            public string Reason;
            public decimal Amount;
        }

        // Shared SELECT body for both read methods (name resolved across person tables)
        private const string PatronNameExpr = @"
            COALESCE(
                CONCAT(s.first_name,' ',s.last_name),
                CONCAT(f.first_name,' ',f.last_name),
                CONCAT(st.first_name,' ',st.last_name),
                'Unknown'
            ) AS PatronName";

        // =============================================================
        // SYNC — recompute fines from Transactions, upsert into Penalties.
        //        Skips rows whose fine_status is already 'Paid'.
        // =============================================================
        public static void SyncPenalties()
        {
            var toUpsert = new List<CalculatedPenalty>();

            const string selectSql = @"
                SELECT
                    t.transaction_id, t.user_id, t.accession_number,
                    t.due_date, t.return_date,
                    t.is_damaged, t.is_lost
                FROM Transactions t
                WHERE NOT EXISTS (
                        SELECT 1 FROM Penalties p
                        WHERE p.transaction_id = t.transaction_id
                          AND p.fine_status = 'Paid'
                )";

            using (var conn = new MySqlConnection(_connStr))
            {
                conn.Open();

                using (var cmd = new MySqlCommand(selectSql, conn))
                using (var dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        var calc = CalculateFromReader(dr);
                        if (calc != null && calc.Amount > 0)
                            toUpsert.Add(calc);
                    }
                }

                foreach (var calc in toUpsert)
                    UpsertPenalty(conn, calc);
            }
        }

        private static CalculatedPenalty CalculateFromReader(MySqlDataReader dr)
        {
            bool isDamaged = dr["is_damaged"] != DBNull.Value && Convert.ToInt32(dr["is_damaged"]) == 1;
            bool isLost = dr["is_lost"] != DBNull.Value && Convert.ToInt32(dr["is_lost"]) == 1;
            DateTime dueDate = Convert.ToDateTime(dr["due_date"]).Date;

            DateTime? returnDate = dr["return_date"] == DBNull.Value
                ? (DateTime?)null
                : Convert.ToDateTime(dr["return_date"]).Date;

            DateTime calcEndDate = returnDate ?? DateTime.Now.Date;

            decimal calcFine = 0;
            int overdueDays = 0;
            var reasonParts = new List<string>();

            if (calcEndDate > dueDate)
            {
                overdueDays = (calcEndDate - dueDate).Days;
                if (overdueDays > 0)
                {
                    calcFine += overdueDays * DAILY_RATE;
                    reasonParts.Add($"Overdue ({overdueDays} days)");
                }
            }

            if (isDamaged) { calcFine += DAMAGE_FEE; reasonParts.Add("Damaged"); }
            if (isLost) { calcFine += LOST_FEE; reasonParts.Add("Lost"); }

            if (calcFine <= 0) return null;

            string penaltyType;
            if (overdueDays > 0 && isDamaged && isLost) penaltyType = "Overdue_Damaged_Lost";
            else if (overdueDays > 0 && isLost) penaltyType = "Overdue_Lost";
            else if (overdueDays > 0 && isDamaged) penaltyType = "Overdue_Damaged";
            else if (isDamaged && isLost) penaltyType = "Damaged_Lost";
            else if (overdueDays > 0) penaltyType = "Overdue";
            else if (isDamaged) penaltyType = "Damaged";
            else if (isLost) penaltyType = "Lost";
            else penaltyType = "Other";

            return new CalculatedPenalty
            {
                TransactionID = Convert.ToInt32(dr["transaction_id"]),
                UserID = dr["user_id"].ToString(),
                AccessionNumber = dr["accession_number"] == DBNull.Value
                                    ? null : dr["accession_number"].ToString(),
                PenaltyType = penaltyType,
                Reason = string.Join(" + ", reasonParts),
                Amount = calcFine
            };
        }

        private static void UpsertPenalty(MySqlConnection conn, CalculatedPenalty calc)
        {
            const string sql = @"
                INSERT INTO Penalties
                    (transaction_id, user_id, accession_number,
                     penalty_type, reason, fine_amount, amount_paid, fine_status)
                VALUES
                    (@tid, @uid, @acc, @type, @reason, @amount, 0.00, 'Unpaid')
                ON DUPLICATE KEY UPDATE
                    penalty_type = VALUES(penalty_type),
                    reason       = VALUES(reason),
                    fine_amount  = GREATEST(fine_amount, VALUES(fine_amount)),
                    fine_status  = CASE
                        WHEN amount_paid >= GREATEST(fine_amount, VALUES(fine_amount)) THEN 'Paid'
                        WHEN amount_paid > 0 THEN 'Partial'
                        ELSE 'Unpaid'
                    END,
                    paid_date    = CASE
                        WHEN amount_paid >= GREATEST(fine_amount, VALUES(fine_amount))
                             AND paid_date IS NULL THEN NOW()
                        ELSE paid_date
                    END";

            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@tid", calc.TransactionID);
                cmd.Parameters.AddWithValue("@uid", calc.UserID);
                cmd.Parameters.AddWithValue("@acc", (object)calc.AccessionNumber ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@type", calc.PenaltyType);
                cmd.Parameters.AddWithValue("@reason", calc.Reason);
                cmd.Parameters.AddWithValue("@amount", calc.Amount);
                cmd.ExecuteNonQuery();
            }
        }

        // =============================================================
        // READ
        // =============================================================
        public static List<PenaltyRecord> GetPenalties()
        {
            SyncPenalties();

            var list = new List<PenaltyRecord>();

            // FIX: name is now resolved across Students / Faculty / Staff
            // because Users no longer carries first_name / last_name.
            string sql = @"
                SELECT
                    p.penalty_id, p.transaction_id, p.user_id, p.accession_number,
                    p.penalty_type, p.reason, p.fine_amount, p.amount_paid, p.fine_status,
                    " + PatronNameExpr + @",
                    r.title AS BookTitle
                FROM Penalties p
                LEFT JOIN Students s          ON s.student_id = p.user_id
                LEFT JOIN Faculty  f          ON f.faculty_id = p.user_id
                LEFT JOIN Staff    st         ON st.staff_id  = p.user_id
                LEFT JOIN Item_Copies ic      ON ic.accession_number = p.accession_number
                LEFT JOIN Library_Resources r ON r.resource_id       = ic.resource_id
                WHERE p.fine_status <> 'Paid'
                  AND (p.fine_amount - p.amount_paid) > 0
                ORDER BY p.created_at DESC";

            using (var conn = new MySqlConnection(_connStr))
            using (var cmd = new MySqlCommand(sql, conn))
            {
                conn.Open();
                using (var dr = cmd.ExecuteReader())
                {
                    while (dr.Read()) list.Add(MapRecord(dr));
                }
            }
            return list;
        }

        public static PenaltyRecord GetPenaltyRecord(int transactionId)
        {
            SyncPenalties();

            // FIX: same name-resolution change as GetPenalties.
            string sql = @"
                SELECT
                    p.penalty_id, p.transaction_id, p.user_id, p.accession_number,
                    p.penalty_type, p.reason, p.fine_amount, p.amount_paid, p.fine_status,
                    " + PatronNameExpr + @",
                    r.title AS BookTitle
                FROM Penalties p
                LEFT JOIN Students s          ON s.student_id = p.user_id
                LEFT JOIN Faculty  f          ON f.faculty_id = p.user_id
                LEFT JOIN Staff    st         ON st.staff_id  = p.user_id
                LEFT JOIN Item_Copies ic      ON ic.accession_number = p.accession_number
                LEFT JOIN Library_Resources r ON r.resource_id       = ic.resource_id
                WHERE p.transaction_id = @tid";

            using (var conn = new MySqlConnection(_connStr))
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@tid", transactionId);
                conn.Open();
                using (var dr = cmd.ExecuteReader())
                {
                    if (dr.Read()) return MapRecord(dr);
                }
            }
            return null;
        }

        private static PenaltyRecord MapRecord(MySqlDataReader dr)
        {
            decimal fine = Convert.ToDecimal(dr["fine_amount"]);
            decimal paid = Convert.ToDecimal(dr["amount_paid"]);

            return new PenaltyRecord
            {
                PenaltyID = Convert.ToInt32(dr["penalty_id"]),
                TransactionID = Convert.ToInt32(dr["transaction_id"]),
                UserID = dr["user_id"].ToString(),
                PatronName = dr["PatronName"].ToString(),
                Book = dr["BookTitle"] == DBNull.Value ? "Unknown" : dr["BookTitle"].ToString(),
                AccessionNumber = dr["accession_number"] == DBNull.Value ? "" : dr["accession_number"].ToString(),
                PenaltyType = dr["penalty_type"].ToString(),
                Reason = dr["reason"].ToString(),
                Amount = fine,
                Balance = fine - paid,
                Status = dr["fine_status"].ToString()
            };
        }

        // =============================================================
        // PAYMENT  (unchanged — already matches schema)
        // =============================================================
        public static bool ProcessPayment(
            int transactionId,
            decimal amount,
            decimal cashTendered,
            string method,
            string reference,
            string notes,
            string receivedBy,
            out string errorMessage)
        {
            errorMessage = null;

            if (amount <= 0)
            {
                errorMessage = "Payment amount must be greater than zero.";
                return false;
            }

            decimal change = cashTendered - amount;
            if (method == "Cash" && cashTendered > 0 && change < 0)
            {
                errorMessage = "Cash tendered is less than the payment amount.";
                return false;
            }
            if (change < 0) change = 0;

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    using (var tx = conn.BeginTransaction())
                    {
                        int penaltyId;
                        decimal fineAmount;
                        decimal amountPaid;

                        const string lockSql = @"
                            SELECT penalty_id, fine_amount, amount_paid
                            FROM Penalties
                            WHERE transaction_id = @tid
                            FOR UPDATE";

                        using (var lockCmd = new MySqlCommand(lockSql, conn, tx))
                        {
                            lockCmd.Parameters.AddWithValue("@tid", transactionId);
                            using (var dr = lockCmd.ExecuteReader())
                            {
                                if (!dr.Read())
                                {
                                    errorMessage = "Penalty record not found.";
                                    return false;
                                }
                                penaltyId = Convert.ToInt32(dr["penalty_id"]);
                                fineAmount = Convert.ToDecimal(dr["fine_amount"]);
                                amountPaid = Convert.ToDecimal(dr["amount_paid"]);
                            }
                        }

                        decimal balance = fineAmount - amountPaid;
                        if (balance <= 0)
                        {
                            errorMessage = "This penalty is already fully paid.";
                            return false;
                        }
                        if (amount > balance)
                        {
                            errorMessage = $"Payment exceeds the outstanding balance of ₱{balance:N2}.";
                            return false;
                        }

                        decimal newPaid = amountPaid + amount;
                        bool nowPaid = newPaid >= fineAmount;
                        string newState = nowPaid ? "Paid" : "Partial";

                        const string updateSql = @"
                            UPDATE Penalties
                            SET amount_paid = @paid,
                                fine_status = @status,
                                paid_date   = CASE WHEN @status = 'Paid' THEN NOW() ELSE paid_date END
                            WHERE penalty_id = @pid";

                        using (var updateCmd = new MySqlCommand(updateSql, conn, tx))
                        {
                            updateCmd.Parameters.AddWithValue("@paid", newPaid);
                            updateCmd.Parameters.AddWithValue("@status", newState);
                            updateCmd.Parameters.AddWithValue("@pid", penaltyId);
                            updateCmd.ExecuteNonQuery();
                        }

                        const string paySql = @"
                            INSERT INTO Penalty_Payments
                                (penalty_id, amount, cash_tendered, change_given,
                                 payment_method, payment_reference, payment_notes, received_by)
                            VALUES
                                (@pid, @amt, @cash, @chg, @method, @ref, @notes, @by)";

                        using (var payCmd = new MySqlCommand(paySql, conn, tx))
                        {
                            payCmd.Parameters.AddWithValue("@pid", penaltyId);
                            payCmd.Parameters.AddWithValue("@amt", amount);
                            payCmd.Parameters.AddWithValue("@cash", method == "Cash" ? cashTendered : amount);
                            payCmd.Parameters.AddWithValue("@chg", method == "Cash" ? change : 0);
                            payCmd.Parameters.AddWithValue("@method", method);
                            payCmd.Parameters.AddWithValue("@ref", (object)reference ?? DBNull.Value);
                            payCmd.Parameters.AddWithValue("@notes", (object)notes ?? DBNull.Value);
                            payCmd.Parameters.AddWithValue("@by", (object)receivedBy ?? DBNull.Value);
                            payCmd.ExecuteNonQuery();
                        }

                        const string linkSql = @"
                            UPDATE Transactions
                            SET penalty_id = @pid
                            WHERE transaction_id = @tid
                              AND (penalty_id IS NULL OR penalty_id <> @pid)";

                        using (var linkCmd = new MySqlCommand(linkSql, conn, tx))
                        {
                            linkCmd.Parameters.AddWithValue("@pid", penaltyId);
                            linkCmd.Parameters.AddWithValue("@tid", transactionId);
                            linkCmd.ExecuteNonQuery();
                        }

                        tx.Commit();
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                errorMessage = "An error occurred while processing the payment: " + ex.Message;
                return false;
            }
        }
    }
}