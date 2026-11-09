using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Configuration;

namespace spmst_lms_development.Assets.Helper
{
    /// <summary>
    /// Handles damage/lost book replacement settlement.
    /// A replacement settles exactly one Damaged or Lost component.
    /// Overdue components are NEVER eligible.
    /// </summary>
    public static class ReplacementService
    {
        private static readonly string _connStr =
            ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        public class ReplacementRequest
        {
            public string Type { get; set; }      // "Damaged" | "Lost"
            public string Accession { get; set; }
            public string Title { get; set; }
            public string Author { get; set; }
            public string Isbn { get; set; }
            public string Remarks { get; set; }
        }

        public static bool ProcessReplacements(
            int transactionId,
            List<ReplacementRequest> requests,
            string commonRemarks,
            string processedBy,
            out string errorMessage)
        {
            errorMessage = null;
            if (requests == null || requests.Count == 0)
            {
                errorMessage = "No replacements submitted.";
                return false;
            }

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    using (var tx = conn.BeginTransaction())
                    {
                        int penaltyId;
                        string originalAcc;

                        using (var cmd = new MySqlCommand(
                            "SELECT p.penalty_id, p.accession_number FROM Penalties p " +
                            "WHERE p.transaction_id = @tid FOR UPDATE", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@tid", transactionId);
                            using (var dr = cmd.ExecuteReader())
                            {
                                if (!dr.Read())
                                {
                                    errorMessage = "Penalty record not found.";
                                    return false;
                                }
                                penaltyId = Convert.ToInt32(dr["penalty_id"]);
                                originalAcc = dr["accession_number"] == DBNull.Value
                                    ? null : dr["accession_number"].ToString();
                            }
                        }

                        foreach (var req in requests)
                        {
                            string type = (req.Type ?? "").Trim();
                            if (type != "Damaged" && type != "Lost")
                            {
                                errorMessage = "Invalid replacement type '" + req.Type + "'.";
                                return false;
                            }
                            if (string.IsNullOrWhiteSpace(req.Accession))
                            {
                                errorMessage = "Replacement accession number is required for " + type + ".";
                                return false;
                            }

                            int compId;
                            string compSettle;

                            using (var cmd = new MySqlCommand(
                                "SELECT component_id, settlement_type " +
                                "FROM Penalty_Components " +
                                "WHERE penalty_id = @p AND component_type = @t FOR UPDATE",
                                conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@p", penaltyId);
                                cmd.Parameters.AddWithValue("@t", type);
                                using (var dr = cmd.ExecuteReader())
                                {
                                    if (!dr.Read())
                                    {
                                        errorMessage = "No " + type + " component exists on this transaction.";
                                        return false;
                                    }
                                    compId = Convert.ToInt32(dr["component_id"]);
                                    compSettle = dr["settlement_type"].ToString();
                                }
                            }

                            if (compSettle == "Replacement")
                            {
                                errorMessage = "The " + type + " component has already been replaced.";
                                return false;
                            }

                            using (var cmd = new MySqlCommand(
                                "SELECT COUNT(1) FROM Penalty_Replacements " +
                                "WHERE penalty_id = @p AND component_type = @t", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@p", penaltyId);
                                cmd.Parameters.AddWithValue("@t", type);
                                long c = Convert.ToInt64(cmd.ExecuteScalar());
                                if (c > 0)
                                {
                                    errorMessage = "A replacement record already exists for the " + type + " component.";
                                    return false;
                                }
                            }

                            using (var cmd = new MySqlCommand(
                                @"INSERT INTO Penalty_Replacements
                                    (penalty_id, transaction_id, component_type,
                                     original_accession_number, replacement_accession_number,
                                     replacement_status, replacement_book_title,
                                     replacement_book_author, replacement_book_isbn,
                                     remarks, processed_by, replacement_date)
                                  VALUES
                                    (@p, @tid, @t,
                                     @orig, @repl,
                                     'Approved', @title,
                                     @auth, @isbn,
                                     @rem, @by, NOW())", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@p", penaltyId);
                                cmd.Parameters.AddWithValue("@tid", transactionId);
                                cmd.Parameters.AddWithValue("@t", type);
                                cmd.Parameters.AddWithValue("@orig", (object)originalAcc ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@repl", req.Accession);
                                cmd.Parameters.AddWithValue("@title", (object)req.Title ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@auth", (object)req.Author ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@isbn", (object)req.Isbn ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@rem",
                                    (!string.IsNullOrWhiteSpace(req.Remarks)
                                        ? req.Remarks
                                        : (object)commonRemarks) ?? DBNull.Value);
                                cmd.Parameters.AddWithValue("@by", processedBy);
                                cmd.ExecuteNonQuery();
                            }

                            using (var cmd = new MySqlCommand(
                                "UPDATE Penalty_Components SET settlement_type = 'Replacement', " +
                                "settled_at = NOW(), settled_by = @by WHERE component_id = @id",
                                conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@by", processedBy);
                                cmd.Parameters.AddWithValue("@id", compId);
                                cmd.ExecuteNonQuery();
                            }

                            if (!string.IsNullOrEmpty(originalAcc))
                            {
                                string cond = type == "Lost" ? "Lost" : "Damage";
                                using (var cmd = new MySqlCommand(
                                    "UPDATE Item_Copies SET is_available = 0, status_condition = @c " +
                                    "WHERE accession_number = @a", conn, tx))
                                {
                                    cmd.Parameters.AddWithValue("@c", cond);
                                    cmd.Parameters.AddWithValue("@a", originalAcc);
                                    cmd.ExecuteNonQuery();
                                }
                            }

                            using (var cmd = new MySqlCommand(
                                @"INSERT INTO Audit_Logs
                                    (user_id, action_type, table_affected, action_details)
                                  VALUES (@by, 'REPLACEMENT', 'Penalty_Replacements', @d)",
                                conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@by", processedBy);
                                cmd.Parameters.AddWithValue("@d",
                                    $"Replacement approved for txn={transactionId} type={type} " +
                                    $"orig={originalAcc} repl={req.Accession}");
                                cmd.ExecuteNonQuery();
                            }
                        }

                        // recompose umbrella (balance now excludes replaced components)
                        using (var cmd = new MySqlCommand(
                            @"UPDATE Penalties p SET
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
                              WHERE p.penalty_id = @p", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@p", penaltyId);
                            cmd.ExecuteNonQuery();
                        }

                        tx.Commit();
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                errorMessage = "An error occurred while recording the replacement: " + ex.Message;
                return false;
            }
        }
    }
}