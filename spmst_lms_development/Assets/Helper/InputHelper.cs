using System;
using System.Text;
using System.Text.RegularExpressions;

namespace spmst_lms_development
{
    public static class InputHelper
    {
        // ==========================================
        // TEXT FORMATTERS (Transformers)
        // ==========================================

        public static string ToLowerCase(string input)
        {
            return string.IsNullOrWhiteSpace(input) ? string.Empty : input.Trim().ToLower();
        }

        public static string ToUpperCase(string input)
        {
            return string.IsNullOrWhiteSpace(input) ? string.Empty : input.Trim().ToUpper();
        }

        public static string ToSentenceCase(string input)
        {
            if (string.IsNullOrWhiteSpace(input)) return string.Empty;
            input = input.Trim();
            return char.ToUpper(input[0]) + input.Substring(1).ToLower();
        }

        /// <summary>
        /// Creates an acronym/abbreviation from a phrase or single word
        /// </summary>
        /// <param name="input">The text to abbreviate</param>
        /// <param name="maxLength">Maximum length for single words (default 4)</param>
        /// <returns>Abbreviated version of the input</returns>
        public static string GetAcronymAbbreviation(string input, int maxLength = 4)
        {
            if (string.IsNullOrWhiteSpace(input)) return "UNK";
            input = input.Trim();

            // Handle special cases
            if (input.Equals("Unknown", StringComparison.OrdinalIgnoreCase)) return "UNK";
            if (input.Equals("Faculty / Non-Student", StringComparison.OrdinalIgnoreCase)) return "FNS";

            // Remove special characters
            string cleanText = Regex.Replace(input, @"[.,\/#!$%\^&\*;:{}=\-_`~()]", "");
            string[] words = cleanText.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

            // Single word handling
            if (words.Length == 1)
            {
                return words[0].Length <= maxLength ? words[0].ToUpper() : words[0].Substring(0, maxLength).ToUpper();
            }

            // Multi-word acronym creation
            StringBuilder acronym = new StringBuilder();
            foreach (string word in words)
            {
                string lowerWord = word.ToLower();
                // Skip common connecting words
                if (lowerWord == "of" || lowerWord == "and" || lowerWord == "in" ||
                    lowerWord == "for" || lowerWord == "the" || lowerWord == "to")
                    continue;

                if (word.Length > 0)
                {
                    acronym.Append(char.ToUpper(word[0]));
                }
            }

            return acronym.Length > 0 ? acronym.ToString() : "UNK";
        }

        // ==========================================
        // VALIDATORS (Checkers)
        // ==========================================

        public static bool IsValidEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return false;
            string pattern = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";
            return Regex.IsMatch(email.Trim(), pattern, RegexOptions.IgnoreCase);
        }

        public static bool IsValidMobileNumber(string number)
        {
            if (string.IsNullOrWhiteSpace(number)) return false;
            string pattern = @"^09\d{9}$";
            return Regex.IsMatch(number.Trim(), pattern);
        }

        public static bool IsValidPassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password)) return false;
            string pattern = @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*?.]).{8,}$";
            return Regex.IsMatch(password, pattern);
        }
    }
}