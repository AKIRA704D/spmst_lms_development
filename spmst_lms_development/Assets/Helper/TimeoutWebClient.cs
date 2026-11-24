using System;
using System.Net;

namespace spmst_lms_development.Assets.Helper
{
    /// <summary>
    /// WebClient with a bounded timeout. The stock WebClient has no Timeout property and
    /// waits up to 100 seconds, which freezes the page when an external API is unreachable.
    /// </summary>
    public class TimeoutWebClient : WebClient
    {
        public int TimeoutMs { get; set; }

        public TimeoutWebClient() : this(8000) { }

        public TimeoutWebClient(int timeoutMs)
        {
            TimeoutMs = timeoutMs;
        }

        protected override WebRequest GetWebRequest(Uri address)
        {
            WebRequest req = base.GetWebRequest(address);
            if (req != null)
            {
                req.Timeout = TimeoutMs;
                var http = req as HttpWebRequest;
                if (http != null) http.ReadWriteTimeout = TimeoutMs;
            }
            return req;
        }
    }
}
