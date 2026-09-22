using System;
using System.Collections.Generic;

namespace spmst_lms_development.Assets.Helper
{
    public static class ProfileHelper
    {
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