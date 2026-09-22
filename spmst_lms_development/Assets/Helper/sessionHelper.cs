using System;
using System.Web;
using System.Web.SessionState;

namespace spmst_lms_development
{
    public static class sessionHelper
    {
        // Property hooks matching your EXACT login.aspx.cs session naming conventions
        public static string UserID => HttpContext.Current.Session["UserID"]?.ToString() ?? string.Empty;
        public static string FullName => HttpContext.Current.Session["FullName"]?.ToString() ?? "Guest User";
        public static string UserRole => HttpContext.Current.Session["UserRole"]?.ToString() ?? "visitor";
        public static string Email => HttpContext.Current.Session["Email"]?.ToString() ?? string.Empty;

        /// <summary>
        /// Translates backend database codes into clean frontend display names
        /// </summary>
        public static string GetRoleDisplayName()
        {
            string code = UserRole.ToLower().Trim();

            switch (code)
            {
                case "staff-a":
                    return "admin";
                case "staff-c":
                    return "Circulation Librarian";
                case "staff-m":
                    return "Management Specialist";
                case "staff-o":
                    return "Library Staff";
                case "student":
                    return "Student Patron";
                case "faculty":
                    return "Faculty Patron";
                default:
                    return "System Visitor";
            }
        }

        /// <summary>
        /// Generates a two-letter structural abbreviation from a full name (e.g., "Juan Dela Cruz" -> "JC")
        /// </summary>
        public static string GetInitials()
        {
            string name = FullName.Trim();
            if (string.IsNullOrWhiteSpace(name) || name.Equals("Guest User", StringComparison.OrdinalIgnoreCase) || name.Equals("System User", StringComparison.OrdinalIgnoreCase))
            {
                return "SU";
            }

            string[] tokens = name.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (tokens.Length == 1)
            {
                return tokens[0].Substring(0, Math.Min(2, tokens[0].Length)).ToUpper();
            }

            // Grabs the first character of the first name token and the first character of the last name token
            string firstInitial = tokens[0].Substring(0, 1);
            string lastInitial = tokens[tokens.Length - 1].Substring(0, 1);

            return (firstInitial + lastInitial).ToUpper();
        }

        /// <summary>
        /// Security Gate checking user authentication state
        /// </summary>
        public static bool IsLoggedIn()
        {
            return !string.IsNullOrEmpty(UserID);
        }
    }
}