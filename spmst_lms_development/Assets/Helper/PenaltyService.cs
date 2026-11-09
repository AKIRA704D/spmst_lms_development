using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;

namespace spmst_lms_development.Assets.Helper
{
    /// <summary>
    /// Source of truth for penalty computation, sync, and payment processing.
    ///
    /// Rates intentionally match spamast_lms v4 events.sql:
    ///   loan-in  (borrow_date = due_date)  → ₱5.00 per overdue hour (from created_at)
    ///   loan-out (borrow_date &lt; due_date) → ₱5.00 per overdue day  (from due_date)
    ///
    /// Fixed fees for physical defects are configuration constants.
    /// Settlement is component-level: Overdue / Damaged / Lost each tracked
    /// independently in Penalty_Components. The umbrella Penalties row is
    /// recomposed from its components after every mutation.
    /// </summary>
    public static class PenaltyService
    {
        private static readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        // ---- Rates (must match the MySQL event) ----
        private const decimal HOURLY_RATE = 5.00m;   // loan-in overdue
        private const decimal DAILY_RATE = 5.00m;   // loan-out overdue
        private const decimal DAMAGE_FEE = 100.00m; // physical damage
        private const decimal LOST_FEE = 200.00m; // lost book

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

            /// <summary>Per-component breakdown. Consumed by SettlePay.aspx.</summary>
            public List<PenaltyComponent> Components { get; set; } = new List<PenaltyComponent>();
        }

        public class PenaltyComponent
        {
            public int ComponentID { get; set; }
            public string Type { get; set; }              // "Overdue" | "Damaged" | "Lost"
            public decimal Amount { get; set; }
            public decimal AmountPaid { get; set; }
            public string SettlementType { get; set; }    // "Pending" | "Payment" | "Replacement"
            public DateTime? SettledAt { get; set; }
            public string SettledBy { get; set; }

            // Overdue-only (filled by MapComponent)
            public string LoanType { get; set; }          // "LoanIn" | "LoanOut"
            public int OverdueHours { get; set; }
            public int OverdueDays { get; set; }

            // Replacement-only
            public string ReplacementAccession { get; set; }
            public DateTime? ReplacementDate { get; set; }
        }

        private class TransactionRow
        {
            public int TransactionID;
            public string UserID;
            public string AccessionNumber;
            public DateTime BorrowDate;
            public DateTime DueDate;
            public DateTime? ReturnDate;
            public DateTime CreatedAt;
            public DateTime UpdatedAt;
            public bool IsDamaged;
            public bool IsLost;
        }

        private const string PatronNameExpr = @"
            COALESCE(
                CONCAT(s.first_name,' ',s.last_name),
                CONCAT(f.first_name,' ',f.last_name),
                CONCAT(st.first_name,' ',st.last_name),
                'Unknown'
            ) AS PatronName";

        // =============================================================
        // SYNC — recompute components from Transactions, then recompose
        //        the umbrella Penalties row. Never decreases an existing
        //        amount. Never touches Replacement-settled components.
        // =============================================================
        public static void SyncPenalties()
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                using (var tx = conn.BeginTransaction())
                {
                    var rows = new List<TransactionRow>();

                    const string selectSql = @"
                        SELECT t.transaction_id, t.user_id, t.accession_number,
                               t.borrow_date, t.due_date, t.return_date,
                               t.created_at, t.updated_at, t.is_damaged, t.is_lost
                        FROM Transactions t
                        WHERE (
                            NOT EXISTS (
                                SELECT 1 FROM Penalties p
                                WHERE p.transaction_id = t.transaction_id
                                  AND p.fine_status = 'Paid'
                            )
                            OR (
                                (t.is_damaged = 1 OR t.is_lost = 1)
                                AND EXISTS (
                                    SELECT 1 FROM Penalties p
                                    WHERE p.transaction_id = t.transaction_id
                                      AND p.fine_status = 'Paid'
                                      AND NOT EXISTS (
                                          SELECT 1 FROM Penalty_Components pc
                                          WHERE pc.penalty_id = p.penalty_id
                                            AND pc.component_type =
                                                CASE WHEN t.is_damaged = 1 THEN 'Damaged' ELSE 'Lost' END
                                      )
                                )
                            )
                        )";

                    using (var cmd = new MySqlCommand(selectSql, conn, tx))
                    using (var dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            rows.Add(new TransactionRow
                            {
                                TransactionID = Convert.ToInt32(dr["transaction_id"]),
                                UserID = dr["user_id"].ToString(),
                                AccessionNumber = dr["accession_number"] == DBNull.Value
                                    ? null : dr["accession_number"].ToString(),
                                BorrowDate = Convert.ToDateTime(dr["borrow_date"]).Date,
                                DueDate = Convert.ToDateTime(dr["due_date"]).Date,
                                ReturnDate = dr["return_date"] == DBNull.Value
                                    ? (DateTime?)null
                                    : Convert.ToDateTime(dr["return_date"]).Date,
                                CreatedAt = Convert.ToDateTime(dr["created_at"]),
                                UpdatedAt = Convert.ToDateTime(dr["updated_at"]),
                                IsDamaged = dr["is_damaged"] != DBNull.Value
                                    && Convert.ToInt32(dr["is_damaged"]) == 1,
                                IsLost = dr["is_lost"] != DBNull.Value
                                    && Convert.ToInt32(dr["is_lost"]) == 1
                            });
                        }
                    }

                    foreach (var row in rows)
                        SyncOneTransaction(conn, tx, row);

                    tx.Commit();
                }
            }
        }

        private static void SyncOneTransaction(MySqlConnection conn, MySqlTransaction tx, TransactionRow row)
        {
            bool isLoanIn = row.BorrowDate == row.DueDate;

            int overdueHours = 0, overdueDays = 0;
            decimal overdueAmount = 0;
            string loanType;

            if (isLoanIn)
            {
                DateTime end = row.ReturnDate.HasValue ? row.UpdatedAt : DateTime.Now;
                overdueHours = Math.Max(0, (int)(end - row.CreatedAt).TotalHours);
                overdueAmount = overdueHours * HOURLY_RATE;
                loanType = "LoanIn";
            }
            else
            {
                DateTime endDate = row.ReturnDate ?? DateTime.Now.Date;
                overdueDays = Math.Max(0, (int)(endDate - row.DueDate).TotalDays);
                overdueAmount = overdueDays * DAILY_RATE;
                loanType = "LoanOut";
            }

            int penaltyId = EnsurePenaltyRow(conn, tx, row);

            // SAFETY FALLBACK: If no flags are set but an old penalty exists, preserve it.
            if (!row.IsDamaged && !row.IsLost && overdueAmount == 0)
            {
                string existingType = "";
                decimal oldFine = 0;
                using (var cmd = new MySqlCommand("SELECT penalty_type, fine_amount FROM Penalties WHERE penalty_id = @p", conn, tx))
                {
                    cmd.Parameters.AddWithValue("@p", penaltyId);
                    using (var dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            existingType = dr["penalty_type"].ToString();
                            oldFine = Convert.ToDecimal(dr["fine_amount"]);
                        }
                    }
                }

                if (existingType.Contains("Damaged")) { UpsertComponent(conn, tx, penaltyId, "Damaged", oldFine > 0 ? oldFine : DAMAGE_FEE); row.IsDamaged = true; }
                else if (existingType.Contains("Lost")) { UpsertComponent(conn, tx, penaltyId, "Lost", oldFine > 0 ? oldFine : LOST_FEE); row.IsLost = true; }
                else if (existingType.Contains("Overdue") && oldFine > 0) { UpsertComponent(conn, tx, penaltyId, "Overdue", oldFine); overdueAmount = oldFine; }
            }

            var parts = new List<string>();
            string penaltyType = "Other";

            if (overdueAmount > 0)
            {
                UpsertComponent(conn, tx, penaltyId, "Overdue", overdueAmount);
                parts.Add(loanType == "LoanIn"
                    ? $"Overdue Loan-in ({overdueHours}h)"
                    : $"Overdue Loan-out ({overdueDays}d)");
            }
            if (row.IsDamaged)
            {
                UpsertComponent(conn, tx, penaltyId, "Damaged", DAMAGE_FEE);
                parts.Add("Damaged");
            }
            if (row.IsLost)
            {
                UpsertComponent(conn, tx, penaltyId, "Lost", LOST_FEE);
                parts.Add("Lost");
            }

            penaltyType =
                overdueAmount > 0 && row.IsDamaged && row.IsLost ? "Overdue_Damaged_Lost" :
                overdueAmount > 0 && row.IsLost ? "Overdue_Lost" :
                overdueAmount > 0 && row.IsDamaged ? "Overdue_Damaged" :
                row.IsDamaged && row.IsLost ? "Damaged_Lost" :
                overdueAmount > 0 ? "Overdue" :
                row.IsDamaged ? "Damaged" :
                row.IsLost ? "Lost" : "Other";

            string reason = parts.Count > 0 ? string.Join(" + ", parts) : "Pending";

            using (var cmd = new MySqlCommand(
                "UPDATE Penalties SET penalty_type = @t, reason = @r WHERE penalty_id = @p",
                conn, tx))
            {
                cmd.Parameters.AddWithValue("@t", penaltyType);
                cmd.Parameters.AddWithValue("@r", reason);
                cmd.Parameters.AddWithValue("@p", penaltyId);
                cmd.ExecuteNonQuery();
            }

            RecomposeUmbrella(conn, tx, penaltyId);
        }

        private static int EnsurePenaltyRow(MySqlConnection conn, MySqlTransaction tx, TransactionRow row)
        {
            using (var cmd = new MySqlCommand(
                "SELECT penalty_id FROM Penalties WHERE transaction_id = @tid", conn, tx))
            {
                cmd.Parameters.AddWithValue("@tid", row.TransactionID);
                var o = cmd.ExecuteScalar();
                if (o != null && o != DBNull.Value) return Convert.ToInt32(o);
            }

            const string ins = @"
                INSERT INTO Penalties
                    (transaction_id, user_id, accession_number,
                     penalty_type, reason, fine_amount, amount_paid, fine_status)
                VALUES (@tid, @uid, @acc, 'Other', 'Pending', 0.00, 0.00, 'Unpaid')";
            using (var cmd = new MySqlCommand(ins, conn, tx))
            {
                cmd.Parameters.AddWithValue("@tid", row.TransactionID);
                cmd.Parameters.AddWithValue("@uid", row.UserID);
                cmd.Parameters.AddWithValue("@acc", (object)row.AccessionNumber ?? DBNull.Value);
                cmd.ExecuteNonQuery();
                return (int)cmd.LastInsertedId;
            }
        }

        private static void UpsertComponent(
            MySqlConnection conn, MySqlTransaction tx,
            int penaltyId, string type, decimal amount)
        {
            const string sql = @"
                INSERT INTO Penalty_Components (penalty_id, component_type, amount)
                VALUES (@p, @t, @a)
                ON DUPLICATE KEY UPDATE
                    amount = GREATEST(amount, VALUES(amount))";

            using (var cmd = new MySqlCommand(sql, conn, tx))
            {
                cmd.Parameters.AddWithValue("@p", penaltyId);
                cmd.Parameters.AddWithValue("@t", type);
                cmd.Parameters.AddWithValue("@a", amount);
                cmd.ExecuteNonQuery();
            }
        }

        private static void RecomposeUmbrella(MySqlConnection conn, MySqlTransaction tx, int penaltyId)
        {
            const string sql = @"
                UPDATE Penalties p SET
                    fine_amount = COALESCE(
                        (SELECT SUM(amount) FROM Penalty_Components WHERE penalty_id = p.penalty_id), 0),
                    amount_paid = COALESCE(
                        (SELECT SUM(amount_paid) FROM Penalty_Components WHERE penalty_id = p.penalty_id), 0),
                    fine_status = CASE
                        WHEN NOT EXISTS (
                            SELECT 1 FROM Penalty_Components pc
                            WHERE pc.penalty_id = p.penalty_id
                              AND pc.settlement_type <> 'Replacement'
                              AND pc.amount > pc.amount_paid
                        ) THEN 'Paid'
                        WHEN COALESCE(
                            (SELECT SUM(amount_paid) FROM Penalty_Components WHERE penalty_id = p.penalty_id), 0) > 0
                            THEN 'Partial'
                        ELSE 'Unpaid'
                    END,
                    paid_date = CASE
                        WHEN paid_date IS NOT NULL THEN paid_date
                        WHEN NOT EXISTS (
                            SELECT 1 FROM Penalty_Components pc
                            WHERE pc.penalty_id = p.penalty_id
                              AND pc.settlement_type <> 'Replacement'
                              AND pc.amount > pc.amount_paid
                        ) THEN NOW()
                        ELSE NULL
                    END
                WHERE p.penalty_id = @p";

            using (var cmd = new MySqlCommand(sql, conn, tx))
            {
                cmd.Parameters.AddWithValue("@p", penaltyId);
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

            const string sql = @"
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
                  AND EXISTS (
                      SELECT 1 FROM Penalty_Components pc
                      WHERE pc.penalty_id = p.penalty_id
                        AND pc.settlement_type <> 'Replacement'
                        AND pc.amount > pc.amount_paid
                  )
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

            if (list.Count > 0)
            {
                var ids = new List<string>();
                foreach (var r in list) ids.Add(r.PenaltyID.ToString());
                string inClause = string.Join(",", ids);

                string compSql = @"
                    SELECT pc.component_id, pc.penalty_id, pc.component_type,
                           pc.amount, pc.amount_paid, pc.settlement_type, pc.settled_at, pc.settled_by,
                           pr.replacement_accession_number, pr.replacement_date,
                           t.borrow_date, t.due_date
                    FROM Penalty_Components pc
                    JOIN Penalties p    ON p.penalty_id = pc.penalty_id
                    JOIN Transactions t ON t.transaction_id = p.transaction_id
                    LEFT JOIN Penalty_Replacements pr
                           ON pr.penalty_id = pc.penalty_id
                          AND pr.component_type = pc.component_type
                    WHERE pc.penalty_id IN (" + inClause + @")
                    ORDER BY FIELD(pc.component_type,'Overdue','Damaged','Lost')";

                var map = new Dictionary<int, List<PenaltyComponent>>();
                using (var conn = new MySqlConnection(_connStr))
                using (var cmd = new MySqlCommand(compSql, conn))
                {
                    conn.Open();
                    using (var dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            int pid = Convert.ToInt32(dr["penalty_id"]);
                            if (!map.ContainsKey(pid)) map[pid] = new List<PenaltyComponent>();
                            map[pid].Add(MapComponent(dr));
                        }
                    }
                }

                foreach (var r in list)
                {
                    if (map.TryGetValue(r.PenaltyID, out var comps)) r.Components = comps;
                    r.Balance = SumOutstanding(r.Components, r.Amount, r.Status);
                }
            }

            return list;
        }

        public static PenaltyRecord GetPenaltyRecord(int transactionId)
        {
            SyncPenalties();

            const string sql = @"
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

            PenaltyRecord rec = null;
            using (var conn = new MySqlConnection(_connStr))
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@tid", transactionId);
                conn.Open();
                using (var dr = cmd.ExecuteReader())
                {
                    if (dr.Read()) rec = MapRecord(dr);
                }
            }
            if (rec == null) return null;

            rec.Components = LoadComponentsForPenalty(rec.PenaltyID);
            rec.Balance = SumOutstanding(rec.Components, rec.Amount, rec.Status);
            return rec;
        }

        private static List<PenaltyComponent> LoadComponentsForPenalty(int penaltyId)
        {
            var list = new List<PenaltyComponent>();
            const string sql = @"
                SELECT pc.component_id, pc.penalty_id, pc.component_type,
                       pc.amount, pc.amount_paid, pc.settlement_type, pc.settled_at, pc.settled_by,
                       pr.replacement_accession_number, pr.replacement_date,
                       t.borrow_date, t.due_date
                FROM Penalty_Components pc
                JOIN Penalties p    ON p.penalty_id = pc.penalty_id
                JOIN Transactions t ON t.transaction_id = p.transaction_id
                LEFT JOIN Penalty_Replacements pr
                       ON pr.penalty_id = pc.penalty_id
                      AND pr.component_type = pc.component_type
                WHERE pc.penalty_id = @p
                ORDER BY FIELD(pc.component_type,'Overdue','Damaged','Lost')";

            using (var conn = new MySqlConnection(_connStr))
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@p", penaltyId);
                conn.Open();
                using (var dr = cmd.ExecuteReader())
                {
                    while (dr.Read()) list.Add(MapComponent(dr));
                }
            }
            return list;
        }

        private static PenaltyComponent MapComponent(MySqlDataReader dr)
        {
            var comp = new PenaltyComponent
            {
                ComponentID = Convert.ToInt32(dr["component_id"]),
                Type = dr["component_type"].ToString(),
                Amount = Convert.ToDecimal(dr["amount"]),
                AmountPaid = Convert.ToDecimal(dr["amount_paid"]),
                SettlementType = dr["settlement_type"].ToString(),
                SettledBy = dr["settled_by"] == DBNull.Value ? null : dr["settled_by"].ToString()
            };
            if (dr["settled_at"] != DBNull.Value) comp.SettledAt = Convert.ToDateTime(dr["settled_at"]);
            if (dr["replacement_accession_number"] != DBNull.Value)
                comp.ReplacementAccession = dr["replacement_accession_number"].ToString();
            if (dr["replacement_date"] != DBNull.Value)
                comp.ReplacementDate = Convert.ToDateTime(dr["replacement_date"]);

            // Derive loan type and overdue count from component amount so the
            // displayed "X hours/days × rate" always equals the actual fee.
            if (comp.Type == "Overdue")
            {
                var borrowDate = Convert.ToDateTime(dr["borrow_date"]).Date;
                var dueDate = Convert.ToDateTime(dr["due_date"]).Date;
                if (borrowDate == dueDate)
                {
                    comp.LoanType = "LoanIn";
                    comp.OverdueHours = (int)(comp.Amount / HOURLY_RATE);
                }
                else
                {
                    comp.LoanType = "LoanOut";
                    comp.OverdueDays = (int)(comp.Amount / DAILY_RATE);
                }
            }
            return comp;
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
                AccessionNumber = dr["accession_number"] == DBNull.Value
                    ? "" : dr["accession_number"].ToString(),
                PenaltyType = dr["penalty_type"].ToString(),
                Reason = dr["reason"].ToString(),
                Amount = fine,
                Balance = fine - paid,
                Status = dr["fine_status"].ToString()
            };
        }

        private static decimal SumOutstanding(
            List<PenaltyComponent> comps, decimal umbrellaAmount, string umbrellaStatus)
        {
            if (comps == null || comps.Count == 0)
                return umbrellaStatus == "Paid" ? 0 : umbrellaAmount;

            decimal balance = 0;
            foreach (var c in comps)
            {
                if (c.SettlementType == "Replacement") continue;
                balance += Math.Max(0, c.Amount - c.AmountPaid);
            }
            return balance;
        }

        // =============================================================
        // PAYMENT — partial-aware, component-aware, transactional
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

            if (amount <= 0) { errorMessage = "Payment amount must be greater than zero."; return false; }

            bool isCash = string.Equals(method, "Cash", StringComparison.OrdinalIgnoreCase);
            if (isCash && cashTendered < amount)
            {
                errorMessage = "Cash tendered is less than the payment amount.";
                return false;
            }
            if (!isCash && string.IsNullOrWhiteSpace(reference))
            {
                errorMessage = "A reference number is required for " + method + ".";
                return false;
            }

            decimal change = isCash ? Math.Max(0, cashTendered - amount) : 0;

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    using (var tx = conn.BeginTransaction())
                    {
                        // ---- lock penalty row ----
                        int penaltyId;
                        using (var lockCmd = new MySqlCommand(
                            "SELECT penalty_id FROM Penalties WHERE transaction_id = @tid FOR UPDATE",
                            conn, tx))
                        {
                            lockCmd.Parameters.AddWithValue("@tid", transactionId);
                            var o = lockCmd.ExecuteScalar();
                            if (o == null || o == DBNull.Value)
                            {
                                errorMessage = "Penalty record not found.";
                                return false;
                            }
                            penaltyId = Convert.ToInt32(o);
                        }

                        // ---- load components FOR UPDATE ----
                        var components = new List<(int Id, string Type, decimal Amount, decimal Paid, string Settle)>();
                        using (var ccmd = new MySqlCommand(
                            "SELECT component_id, component_type, amount, amount_paid, settlement_type " +
                            "FROM Penalty_Components WHERE penalty_id = @p " +
                            "ORDER BY FIELD(component_type,'Overdue','Damaged','Lost') FOR UPDATE",
                            conn, tx))
                        {
                            ccmd.Parameters.AddWithValue("@p", penaltyId);
                            using (var dr = ccmd.ExecuteReader())
                            {
                                while (dr.Read())
                                    components.Add((
                                        Convert.ToInt32(dr["component_id"]),
                                        dr["component_type"].ToString(),
                                        Convert.ToDecimal(dr["amount"]),
                                        Convert.ToDecimal(dr["amount_paid"]),
                                        dr["settlement_type"].ToString()));
                            }
                        }

                        decimal outstanding = 0;
                        foreach (var c in components)
                        {
                            if (c.Settle == "Replacement") continue;
                            outstanding += Math.Max(0, c.Amount - c.Paid);
                        }
                        if (outstanding <= 0)
                        {
                            errorMessage = "This penalty is already fully settled.";
                            return false;
                        }
                        if (amount > outstanding)
                        {
                            errorMessage = $"Payment exceeds the outstanding balance of ₱{outstanding:N2}.";
                            return false;
                        }

                        // ---- allocate across components ----
                        decimal remaining = amount;
                        foreach (var c in components)
                        {
                            if (remaining <= 0) break;
                            if (c.Settle == "Replacement") continue;

                            decimal due = c.Amount - c.Paid;
                            if (due <= 0) continue;

                            decimal apply = Math.Min(due, remaining);
                            decimal newPaid = c.Paid + apply;
                            string newSettle = (newPaid >= c.Amount) ? "Payment" : c.Settle;

                            using (var u = new MySqlCommand(
                                "UPDATE Penalty_Components SET amount_paid = @ap, " +
                                "settlement_type = @st, " +
                                "settled_at = CASE WHEN @st='Payment' AND settled_at IS NULL THEN NOW() ELSE settled_at END " +
                                "WHERE component_id = @id", conn, tx))
                            {
                                u.Parameters.AddWithValue("@ap", newPaid);
                                u.Parameters.AddWithValue("@st", newSettle);
                                u.Parameters.AddWithValue("@id", c.Id);
                                u.ExecuteNonQuery();
                            }
                            remaining -= apply;
                        }

                        RecomposeUmbrella(conn, tx, penaltyId);

                        // ---- record payment ----
                        using (var payCmd = new MySqlCommand(
                            @"INSERT INTO Penalty_Payments
                                (penalty_id, amount, cash_tendered, change_given,
                                 payment_method, payment_reference, payment_notes, received_by)
                              VALUES (@pid, @amt, @cash, @chg, @m, @r, @n, @by)", conn, tx))
                        {
                            payCmd.Parameters.AddWithValue("@pid", penaltyId);
                            payCmd.Parameters.AddWithValue("@amt", amount);
                            payCmd.Parameters.AddWithValue("@cash", isCash ? cashTendered : amount);
                            payCmd.Parameters.AddWithValue("@chg", change);
                            payCmd.Parameters.AddWithValue("@m", method);
                            payCmd.Parameters.AddWithValue("@r", (object)reference ?? DBNull.Value);
                            payCmd.Parameters.AddWithValue("@n", (object)notes ?? DBNull.Value);
                            payCmd.Parameters.AddWithValue("@by", (object)receivedBy ?? DBNull.Value);
                            payCmd.ExecuteNonQuery();
                        }

                        // ---- link transaction → penalty ----
                        using (var linkCmd = new MySqlCommand(
                            "UPDATE Transactions SET penalty_id = @pid " +
                            "WHERE transaction_id = @tid AND (penalty_id IS NULL OR penalty_id <> @pid)",
                            conn, tx))
                        {
                            linkCmd.Parameters.AddWithValue("@pid", penaltyId);
                            linkCmd.Parameters.AddWithValue("@tid", transactionId);
                            linkCmd.ExecuteNonQuery();
                        }

                        tx.Commit();
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                errorMessage = "An error occurred while processing the payment: " + ex.Message;
                return false;
            }
        }
    }
}