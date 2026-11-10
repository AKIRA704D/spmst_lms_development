using System;
using System.Collections.Generic;
using System.Configuration;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Script.Serialization;

namespace spmst_lms_development.Assets.Helper
{
    public sealed class SmsResult
    {
        public bool Success { get; set; }
        public string MessageId { get; set; }
        public string State { get; set; }
        public string Raw { get; set; }
        public string Error { get; set; }

        public static SmsResult Ok(string id, string state, string raw)
        {
            return new SmsResult { Success = true, MessageId = id, State = state, Raw = raw };
        }

        public static SmsResult Fail(string error, string raw = null)
        {
            return new SmsResult { Success = false, Error = error, Raw = raw };
        }
    }

    /// <summary>
    /// Sends SMS through the Android SMS Gateway (via the PHP bridge or the cloud API).
    /// Usage:  var r = SmsHelper.Send("09171234567", "Hello!");
    /// </summary>
    public static class SmsHelper
    {
        private static readonly HttpClient Client =
            new HttpClient { Timeout = TimeSpan.FromSeconds(30) };

        // ---------------- config ----------------

        private static string Cfg(string key, string fallback = null)
        {
            var v = ConfigurationManager.AppSettings[key];
            return string.IsNullOrWhiteSpace(v) ? fallback : v.Trim();
        }

        private static bool IsEnabled
        {
            get { return !string.Equals(Cfg("SmsEnabled", "true"), "false", StringComparison.OrdinalIgnoreCase); }
        }

        private static string Mode { get { return Cfg("SmsMode", "php").ToLowerInvariant(); } }
        private static string GatewayUrl { get { return Cfg("SmsGatewayUrl"); } }
        private static string ApiBaseUrl { get { return Cfg("SmsApiBaseUrl", "https://api.sms-gate.app"); } }
        private static string Username { get { return Cfg("SmsUsername"); } }
        private static string Password { get { return Cfg("SmsPassword"); } }

        // ---------------- public API ----------------

        /// <summary>Synchronous send. Never throws.</summary>
        public static SmsResult Send(string phoneNumber, string message)
        {
            try
            {
                // Task.Run moves the async work off the ASP.NET request thread.
                // Without this, await continuations deadlock against the page's
                // SynchronizationContext and Page_Load never returns.
                return Task.Run(() => SendAsync(phoneNumber, message))
                           .GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                return SmsResult.Fail(ex.Message);
            }
        }

        /// <summary>Async send. Never throws.</summary>
        public static async Task<SmsResult> SendAsync(string phoneNumber, string message)
        {
            if (!IsEnabled)
                return SmsResult.Fail("SMS sending is disabled (SmsEnabled=false).");

            if (string.IsNullOrWhiteSpace(message))
                return SmsResult.Fail("Message is empty.");

            string local = ToLocalPhMobile(phoneNumber);
            if (local == null)
                return SmsResult.Fail("Invalid PH mobile number: " + phoneNumber);

            try
            {
                Task<SmsResult> task = (Mode == "cloud")
                    ? SendViaCloudApiAsync("+63" + local, message)
                    : SendViaPhpBridgeAsync(local, message);

                Task completed = await Task.WhenAny(task, Task.Delay(TimeSpan.FromSeconds(15)));

                if (completed != task)
                    return SmsResult.Fail("SMS send timed out after 15 s.");

                return await task;
            }
            catch (Exception ex)
            {
                return SmsResult.Fail(ex.Message);
            }
        }

        /// <summary>Exposed for tests / debugging.</summary>
        public static string ToLocalPhMobile(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;

            string d = Regex.Replace(raw, @"[^\d]", "");

            if (d.StartsWith("63") && d.Length == 12) d = d.Substring(2);        // 639171234567
            else if (d.StartsWith("0") && d.Length == 11) d = d.Substring(1);    // 09171234567

            if (d.Length != 10 || !d.StartsWith("9")) return null;
            return d; // e.g. 9171234567
        }

        // ---------------- transport: PHP bridge ----------------

        private static async Task<SmsResult> SendViaPhpBridgeAsync(string localNumber, string message)
        {
            if (string.IsNullOrWhiteSpace(GatewayUrl))
                return SmsResult.Fail("SmsGatewayUrl is not configured.");

            var form = new Dictionary<string, string>
            {
                { "username", Username },
                { "password", Password },
                { "number",   localNumber },   // sms.php prepends "+63" itself
                { "message",  message }
            };

            using (var content = new FormUrlEncodedContent(form))
            using (var resp = await Client.PostAsync(GatewayUrl, content))
            {
                string body = await resp.Content.ReadAsStringAsync();

                if (!resp.IsSuccessStatusCode)
                    return SmsResult.Fail("Gateway returned HTTP " + (int)resp.StatusCode, body);

                if (body.IndexOf("Error", StringComparison.OrdinalIgnoreCase) >= 0)
                    return SmsResult.Fail(body.Trim(), body);

                var idMatch = Regex.Match(body, @"Message sent with ID:\s*(\S+)");
                var stateMatch = Regex.Match(body, @"Message state:\s*(\S+)");

                return SmsResult.Ok(
                    idMatch.Success ? idMatch.Groups[1].Value : null,
                    stateMatch.Success ? stateMatch.Groups[1].Value : null,
                    body);
            }
        }

        // ---------------- transport: cloud API (no PHP needed) ----------------

        private static async Task<SmsResult> SendViaCloudApiAsync(string e164Number, string message)
        {
            var payload = new Dictionary<string, object>
            {
                { "textMessage",  new Dictionary<string, object> { { "text", message } } },
                { "phoneNumbers", new[] { e164Number } },
                 { "simNumber", 2 } // 1 for SIM1, 2 for SIM2
            };
            string json = new JavaScriptSerializer().Serialize(payload);

            string url = ApiBaseUrl.TrimEnd('/') + "/3rdparty/v1/messages";

            using (var req = new HttpRequestMessage(HttpMethod.Post, url))
            {
                string auth = Convert.ToBase64String(
                    Encoding.UTF8.GetBytes((Username ?? "") + ":" + (Password ?? "")));

                req.Headers.Authorization = new AuthenticationHeaderValue("Basic", auth);
                req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                req.Content = new StringContent(json, Encoding.UTF8, "application/json");

                using (var resp = await Client.SendAsync(req))
                {
                    string body = await resp.Content.ReadAsStringAsync();

                    if (!resp.IsSuccessStatusCode)
                        return SmsResult.Fail("Gateway returned HTTP " + (int)resp.StatusCode + ": " + body, body);

                    string id = null;
                    try
                    {
                        var dict = new JavaScriptSerializer()
                            .Deserialize<Dictionary<string, object>>(body);
                        if (dict != null && dict.ContainsKey("id"))
                            id = Convert.ToString(dict["id"]);
                    }
                    catch { /* response shape changed - not fatal */ }

                    return SmsResult.Ok(id, "Pending", body);
                }
            }
        }
    }
}