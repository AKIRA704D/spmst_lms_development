using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;

namespace spmst_lms_development.Services
{
    // ============================================================
    // 1. Schema mirror — Penalties.penalty_type ENUM
    // ============================================================
    /// <summary>
    /// Mirror of the Penalties.penalty_type ENUM in the database.
    /// Use these constants everywhere instead of string literals.
    /// </summary>
    public static class PenaltyTypes
    {
        public const string Overdue = "Overdue";
        public const string Damaged = "Damaged";
        public const string Lost = "Lost";
        public const string OverdueDamaged = "Overdue_Damaged";
        public const string OverdueLost = "Overdue_Lost";
        public const string DamagedLost = "Damaged_Lost";
        public const string OverdueDamagedLost = "Overdue_Damaged_Lost";
        public const string Other = "Other";

        public static readonly IReadOnlyList<string> All = new[]
        {
            Overdue, Damaged, Lost,
            OverdueDamaged, OverdueLost, DamagedLost,
            OverdueDamagedLost, Other
        };

        public static bool IsValid(string type)
            => !string.IsNullOrWhiteSpace(type) && All.Contains(type);
    }

    // ============================================================
    // 2. Schema mirror — Penalties.fine_status ENUM
    // ============================================================
    public static class PenaltyStatuses
    {
        public const string Unpaid = "Unpaid";
        public const string Partial = "Partial";
        public const string Paid = "Paid";

        /// <summary>
        /// Derives the correct fine_status from numeric amounts.
        /// Use this instead of hand-setting the status column.
        /// </summary>
        public static string FromAmounts(decimal fineAmount, decimal amountPaid)
        {
            if (fineAmount <= 0m) return Paid;    // nothing owed
            if (amountPaid <= 0m) return Unpaid;
            if (amountPaid >= fineAmount) return Paid;
            return Partial;
        }
    }

    // ============================================================
    // 3. Result DTO
    // ============================================================
    /// <summary>
    /// Immutable result of a fine calculation. Ready to be written
    /// directly into a Penalties INSERT.
    /// </summary>
    public sealed class PenaltyResult
    {
        public string PenaltyType { get; }
        public decimal FineAmount { get; }
        public string Reason { get; }
        public int OverdueDays { get; }
        public bool IsOverdue { get; }
        public bool IsDamaged { get; }
        public bool IsLost { get; }

        /// <summary>True when there is something to persist.</summary>
        public bool HasPenalty => FineAmount > 0m
                               && !string.IsNullOrEmpty(PenaltyType)
                               && PenaltyType != PenaltyTypes.Other;

        internal PenaltyResult(string type, decimal amount, string reason,
                               int overdueDays, bool damaged, bool lost)
        {
            PenaltyType = type;
            FineAmount = amount;
            Reason = reason;
            OverdueDays = overdueDays;
            IsOverdue = overdueDays > 0;
            IsDamaged = damaged;
            IsLost = lost;
        }

        /// <summary>Empty result (no fine due).</summary>
        public static readonly PenaltyResult None =
            new PenaltyResult(null, 0m, "No penalty", 0, false, false);
    }

    // ============================================================
    // 4. The policy itself
    // ============================================================
    /// <summary>
    /// Centralised fine policy. All rates are read once from
    /// web.config appSettings with hard-coded fallbacks, so policy
    /// changes never require a rebuild.
    /// </summary>
    public static class FinePolicy
    {
        // -------- Configurable rates (web.config > defaults) --------
        public static readonly decimal OverdueFinePerDay =
            GetDecimal("FinePolicy.OverduePerDay", 5.00m);

        public static readonly decimal DamagedFine =
            GetDecimal("FinePolicy.Damaged", 100.00m);

        public static readonly decimal LostFine =
            GetDecimal("FinePolicy.Lost", 500.00m);

        /// <summary>Days past due before the overdue clock starts. 0 = no grace.</summary>
        public static readonly int GracePeriodDays =
            GetInt("FinePolicy.GracePeriodDays", 0);

        /// <summary>Cap on the overdue portion only. 0 = uncapped.</summary>
        public static readonly decimal MaxOverdueFine =
            GetDecimal("FinePolicy.MaxOverdueFine", 0m);

        /// <summary>Optional currency symbol for formatted output.</summary>
        public static readonly string CurrencySymbol =
            ConfigurationManager.AppSettings["FinePolicy.CurrencySymbol"] ?? "₱";

        // ============================================================
        //  Primary API
        // ============================================================

        /// <summary>
        /// Full policy calculation. Feed it a due date, a return date,
        /// and the physical condition of the returned item.
        /// </summary>
        public static PenaltyResult Calculate(
            DateTime dueDate,
            DateTime returnDate,
            bool isDamaged,
            bool isLost)
        {
            int rawOverdue = (returnDate.Date - dueDate.Date).Days;
            int billable = Math.Max(0, rawOverdue - GracePeriodDays);
            return Calculate(billable, isDamaged, isLost);
        }

        /// <summary>
        /// Overload when overdue days have already been computed.
        /// </summary>
        public static PenaltyResult Calculate(
            int overdueDays,
            bool isDamaged,
            bool isLost)
        {
            if (overdueDays < 0) overdueDays = 0;

            string type = ResolvePenaltyType(overdueDays, isDamaged, isLost);
            if (type == null)
                return PenaltyResult.None;

            decimal amount =
                OverdueComponent(overdueDays) +
                (isDamaged ? DamagedFine : 0m) +
                (isLost ? LostFine : 0m);

            string reason = BuildReason(type, overdueDays);

            return new PenaltyResult(type, amount, reason,
                                     overdueDays, isDamaged, isLost);
        }

        // ============================================================
        //  Component helpers
        // ============================================================

        /// <summary>Overdue fine only, respecting grace and cap.</summary>
        public static decimal OverdueComponent(int overdueDays)
        {
            if (overdueDays <= GracePeriodDays) return 0m;

            int billable = overdueDays - GracePeriodDays;
            decimal raw = billable * OverdueFinePerDay;

            if (MaxOverdueFine > 0m && raw > MaxOverdueFine)
                raw = MaxOverdueFine;

            return raw;
        }

        /// <summary>
        /// Returns the correct ENUM value for the given conditions,
        /// or null when no penalty applies.
        /// </summary>
        public static string ResolvePenaltyType(int overdueDays, bool isDamaged, bool isLost)
        {
            bool od = overdueDays > GracePeriodDays;

            if (od && isDamaged && isLost) return PenaltyTypes.OverdueDamagedLost;
            if (od && isDamaged) return PenaltyTypes.OverdueDamaged;
            if (od && isLost) return PenaltyTypes.OverdueLost;
            if (isDamaged && isLost) return PenaltyTypes.DamagedLost;
            if (isDamaged) return PenaltyTypes.Damaged;
            if (isLost) return PenaltyTypes.Lost;
            if (od) return PenaltyTypes.Overdue;
            return null;
        }

        /// <summary>Base fine amount (no overdue) for a given penalty type.</summary>
        public static decimal GetBaseAmount(string penaltyType)
        {
            switch (penaltyType)
            {
                case PenaltyTypes.Damaged:
                case PenaltyTypes.OverdueDamaged:
                    return DamagedFine;

                case PenaltyTypes.Lost:
                case PenaltyTypes.OverdueLost:
                    return LostFine;

                case PenaltyTypes.DamagedLost:
                case PenaltyTypes.OverdueDamagedLost:
                    return DamagedFine + LostFine;

                default:
                    return 0m;
            }
        }

        // ============================================================
        //  Reason builder
        // ============================================================

        public static string BuildReason(string penaltyType, int overdueDays)
        {
            switch (penaltyType)
            {
                case PenaltyTypes.Overdue:
                    return $"Returned {overdueDays} day(s) past due date";
                case PenaltyTypes.Damaged:
                    return "Book returned damaged";
                case PenaltyTypes.Lost:
                    return "Book reported lost on return";
                case PenaltyTypes.OverdueDamaged:
                    return $"Returned {overdueDays} day(s) late and damaged";
                case PenaltyTypes.OverdueLost:
                    return $"Returned {overdueDays} day(s) late and lost";
                case PenaltyTypes.DamagedLost:
                    return "Book returned both damaged and lost";
                case PenaltyTypes.OverdueDamagedLost:
                    return $"Returned {overdueDays} day(s) late, damaged, and lost";
                default:
                    return "Library penalty";
            }
        }

        // ============================================================
        //  Formatting / display
        // ============================================================

        /// <summary>e.g. ₱150.00</summary>
        public static string FormatAmount(decimal amount)
            => CurrencySymbol + amount.ToString("N2");

        /// <summary>Human label for the penalty_type ENUM.</summary>
        public static string DescribeType(string penaltyType)
        {
            switch (penaltyType)
            {
                case PenaltyTypes.Overdue: return "Overdue";
                case PenaltyTypes.Damaged: return "Damaged";
                case PenaltyTypes.Lost: return "Lost";
                case PenaltyTypes.OverdueDamaged: return "Overdue + Damaged";
                case PenaltyTypes.OverdueLost: return "Overdue + Lost";
                case PenaltyTypes.DamagedLost: return "Damaged + Lost";
                case PenaltyTypes.OverdueDamagedLost: return "Overdue + Damaged + Lost";
                default: return penaltyType ?? "—";
            }
        }

        // ============================================================
        //  Internals
        // ============================================================

        private static decimal GetDecimal(string key, decimal fallback)
        {
            string raw = ConfigurationManager.AppSettings[key];
            return decimal.TryParse(raw, out decimal v) ? v : fallback;
        }

        private static int GetInt(string key, int fallback)
        {
            string raw = ConfigurationManager.AppSettings[key];
            return int.TryParse(raw, out int v) ? v : fallback;
        }
    }
}