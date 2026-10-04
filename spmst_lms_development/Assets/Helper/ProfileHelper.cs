using System;
using System.Collections.Generic;
using System.Web;

namespace spmst_lms_development.Assets.Helper
{
    public static class ProfileHelper
    {
        /// <summary>
        /// Normalises a stored image path to an app-relative URL.
        /// Returns null if the path is empty or the file doesn't exist on disk,
        /// so the caller can fall back to initials.
        ///
        /// Static-safe variant: uses HttpContext.Current.Server and
        /// VirtualPathUtility so it can be called from any context
        /// (Page, MasterPage, UserControl, plain class).
        /// </summary>
        public static string ResolveProfileImage(string profilePath)
        {
            if (string.IsNullOrWhiteSpace(profilePath)) return null;

            // Tolerate backslashes copied in from Windows tooling.
            string raw = profilePath.Trim().Replace('\\', '/');

            // Absolute URLs are left alone.
            if (raw.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                raw.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                return raw;
            }

            // Anything without "~/" or "/" is treated as app-root-relative.
            if (!raw.StartsWith("~/") && !raw.StartsWith("/"))
                raw = "~/" + raw;

            // Make sure the file actually exists on disk.
            try
            {
                var ctx = HttpContext.Current;
                if (ctx == null) return null;

                if (!System.IO.File.Exists(ctx.Server.MapPath(raw)))
                    return null;

                return VirtualPathUtility.ToAbsolute(raw);
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Defines which fields are available for each role based on the database schema.
        /// </summary>
        public static HashSet<string> GetAllowedFields(string role)
        {
            var fields = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            // Fields common to ALL roles
            string[] commonFields = {
                "first_name", "middle_name", "last_name", "extension_name",
                "gender", "mobile_number", "email", "department", "address"
            };

            foreach (var f in commonFields)
                fields.Add(f);

            role = (role ?? string.Empty).Trim().ToLower();

            if (role == "student")
            {
                fields.Add("course");
                fields.Add("year_level");
                fields.Add("section");
            }

            return fields;
        }

        /// <summary>
        /// Converts a string to Sentence case (e.g., "JOHN DOE" -> "John doe").
        /// Keeps emails and specific codes untouched if needed, but applies standard sentence casing.
        /// </summary>
        public static string ToSentenceCase(string input)
        {
            if (string.IsNullOrWhiteSpace(input) || input == "N/A")
                return input;

            string trimmed = input.Trim().ToLower();

            // Capitalize the very first letter of the string
            return char.ToUpper(trimmed[0]) + trimmed.Substring(1);
        }
    }
}