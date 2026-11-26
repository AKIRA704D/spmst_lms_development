using System;
using System.Configuration;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.CompilerServices;
using System.Web;
using System.Web.Hosting;
using MySql.Data.MySqlClient;

namespace spmst_lms_development.Assets.Helper
{
    public enum ImageCategory { Profile, Logo, General }

    public sealed class ImageResult
    {
        public bool Success;
        public string Error;            // user-safe message
        public string RelativePath;     // e.g. Assets/Profile/S2024-0001_20261125_ab12cd34.webp
        public string Format;           // webp | png | jpg  (png/jpg only when WebP engine is unavailable)
        public bool IsWebP;
        public int Width, Height;
        public long OriginalBytes, NewBytes;
        public string Warning;          // e.g. "WebP engine unavailable; saved as PNG"
    }

    /// <summary>
    /// Centralized, secure image pipeline. EVERY image upload goes through Process().
    /// Validate (size, real signature, decode, dimensions) -> orient -> resize (never upscale)
    /// -> encode to real WebP -> save under a generated name -> return the relative path.
    /// Conversion happens once, at upload time (or in the migration utility), never per request.
    ///
    /// Engine: Magick.NET (offline, native). If it cannot load on the host, the service degrades to
    /// System.Drawing and stores an optimized PNG/JPEG instead, reporting Warning so the caller/UI can say so.
    /// </summary>
    public static class ImageService
    {
        public const long MaxUploadBytes = 5L * 1024 * 1024;     // 5 MB input
        public const int MaxSourceDimension = 8000;               // reject absurd sources
        public const long MaxSourcePixels = 40L * 1000 * 1000;    // 40 MP decompression-bomb guard

        // Folders images may be written to (keys are the ONLY allowed values; no caller-supplied paths).
        private static string FolderFor(string key)
        {
            switch (key)
            {
                case "profile":     return "Assets/Profile";
                case "school":      return "Assets/Branding/School";
                case "system":      return "Assets/Branding/System";
                case "departments": return "Assets/Branding/Departments";
                case "institutes":  return "Assets/Branding/Institutes";
                case "programs":    return "Assets/Branding/Programs";
                case "other":       return "Assets/Other";
                default: throw new ArgumentException("Unknown image folder key.");
            }
        }

        private static int MaxEdge(ImageCategory c) { return c == ImageCategory.Profile ? 512 : c == ImageCategory.Logo ? 1200 : 1600; }
        private static int Quality(ImageCategory c) { return c == ImageCategory.Logo ? 92 : 82; }

        // ------------------------------------------------------------------ public API
        public static ImageResult Process(HttpPostedFile file, ImageCategory category, string folderKey, string namePrefix)
        {
            if (file == null || file.ContentLength <= 0) return Fail("No image was uploaded.");
            if (file.ContentLength > MaxUploadBytes) return Fail("Image must be 5 MB or smaller.");
            byte[] data = new byte[file.ContentLength];
            int read = 0;
            using (var s = file.InputStream)
            {
                s.Position = 0;
                while (read < data.Length) { int n = s.Read(data, read, data.Length - read); if (n <= 0) break; read += n; }
            }
            return Process(data, category, folderKey, namePrefix);
        }

        public static ImageResult Process(byte[] data, ImageCategory category, string folderKey, string namePrefix)
        {
            var res = new ImageResult { OriginalBytes = data == null ? 0 : data.Length };
            try
            {
                if (data == null || data.Length == 0) return Fail("The uploaded file is empty.");
                if (data.Length > MaxUploadBytes) return Fail("Image must be 5 MB or smaller.");

                string kind = DetectSignature(data);
                if (kind == null) return Fail("Unsupported or invalid image. Allowed: JPG, PNG, GIF, BMP, WebP.");

                string folderRel = FolderFor(folderKey);
                string folderAbs = SafeMap(folderRel);
                Directory.CreateDirectory(folderAbs);

                string stem = SafeStem(namePrefix) + "_" + DateTime.UtcNow.ToString("yyyyMMddHHmmss") + "_" + Guid.NewGuid().ToString("N").Substring(0, 8);

                byte[] output; int w, h; string ext; bool webp;
                string warning = null;
                if (!TryEncodeWithMagick(data, category, out output, out w, out h, out string err))
                {
                    if (err != null && err.StartsWith("REJECT:")) return Fail(err.Substring(7));
                    // Engine unavailable -> degrade (documented behaviour)
                    if (!TryEncodeWithGdi(data, category, out output, out w, out h, out ext, out string gdiErr))
                        return Fail(gdiErr ?? "The image could not be processed.");
                    webp = false;
                    warning = "WebP engine is not available on this server; the image was saved as optimized " + ext.ToUpperInvariant() + " instead.";
                }
                else { ext = "webp"; webp = true; }

                string fileName = stem + "." + ext;
                string fullPath = Path.GetFullPath(Path.Combine(folderAbs, fileName));
                if (!fullPath.StartsWith(Path.GetFullPath(folderAbs), StringComparison.OrdinalIgnoreCase))
                    return Fail("Invalid target path.");
                if (File.Exists(fullPath)) return Fail("A file with that name already exists. Please retry.");

                // Write to a temp file then move, so a crash never leaves a half-written image referenced.
                string tmp = fullPath + ".tmp";
                File.WriteAllBytes(tmp, output);
                File.Move(tmp, fullPath);

                res.Success = true; res.RelativePath = folderRel + "/" + fileName;
                res.Format = ext; res.IsWebP = webp; res.Width = w; res.Height = h;
                res.NewBytes = output.Length; res.Warning = warning;
                return res;
            }
            catch (Exception)
            {
                return Fail("The image could not be processed.");
            }
        }

        /// <summary>
        /// Delete an image file ONLY when nothing else references it and it is not a bundled default.
        /// Call AFTER the database update that dropped the reference has committed.
        /// </summary>
        public static bool TryDeleteIfUnreferenced(string relativePath)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(relativePath)) return false;
                string rel = relativePath.Trim().Replace('\\', '/').TrimStart('~', '/');
                if (rel.Contains("..")) return false;
                if (rel.StartsWith("Assets/Logo/", StringComparison.OrdinalIgnoreCase)) return false; // bundled defaults
                if (!(rel.StartsWith("Assets/Branding/", StringComparison.OrdinalIgnoreCase) ||
                      rel.StartsWith("Assets/Profile/", StringComparison.OrdinalIgnoreCase) ||
                      rel.StartsWith("Assets/Other/", StringComparison.OrdinalIgnoreCase))) return false;
                if (IsReferenced(rel)) return false;

                string abs = SafeMap(rel);
                if (!File.Exists(abs)) return false;
                File.Delete(abs);
                return true;
            }
            catch { return false; }
        }

        public static bool IsReferenced(string rel)
        {
            var cs = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
            using (var conn = new MySqlConnection(cs))
            {
                conn.Open();
                const string sql = @"
                    SELECT (SELECT COUNT(*) FROM branding_logos WHERE logo_path = @p)
                         + (SELECT COUNT(*) FROM students WHERE profile_path = @p OR profile_path = CONCAT('~/', @p))
                         + (SELECT COUNT(*) FROM faculty  WHERE profile_path = @p OR profile_path = CONCAT('~/', @p))
                         + (SELECT COUNT(*) FROM staff    WHERE profile_path = @p OR profile_path = CONCAT('~/', @p))
                         + (SELECT COUNT(*) FROM organization_logos WHERE logo_path = @p)";
                using (var cmd = new MySqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@p", rel);
                    return Convert.ToInt64(cmd.ExecuteScalar()) > 0;
                }
            }
        }

        // ------------------------------------------------------------------ validation helpers
        /// <summary>Real format from magic bytes - extension and MIME type are ignored.</summary>
        public static string DetectSignature(byte[] d)
        {
            if (d.Length < 12) return null;
            if (d[0] == 0x89 && d[1] == 0x50 && d[2] == 0x4E && d[3] == 0x47 && d[4] == 0x0D && d[5] == 0x0A && d[6] == 0x1A && d[7] == 0x0A) return "png";
            if (d[0] == 0xFF && d[1] == 0xD8 && d[2] == 0xFF) return "jpg";
            if (d[0] == 'G' && d[1] == 'I' && d[2] == 'F' && d[3] == '8' && (d[4] == '7' || d[4] == '9') && d[5] == 'a') return "gif";
            if (d[0] == 'B' && d[1] == 'M') return "bmp";
            if (d[0] == 'R' && d[1] == 'I' && d[2] == 'F' && d[3] == 'F' && d[8] == 'W' && d[9] == 'E' && d[10] == 'B' && d[11] == 'P') return "webp";
            return null;
        }

        private static string SafeStem(string prefix)
        {
            var sb = new System.Text.StringBuilder();
            foreach (char c in prefix ?? "img")
                if (char.IsLetterOrDigit(c) || c == '-' ) sb.Append(c);
            if (sb.Length == 0) sb.Append("img");
            return sb.Length > 40 ? sb.ToString(0, 40) : sb.ToString();
        }

        private static string SafeMap(string rel)
        {
            string root = Path.GetFullPath(HostingEnvironment.MapPath("~/"));
            string full = Path.GetFullPath(HostingEnvironment.MapPath("~/" + rel));
            if (!full.StartsWith(root, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Path escapes web root.");
            return full;
        }

        private static ImageResult Fail(string msg) { return new ImageResult { Success = false, Error = msg }; }

        // ------------------------------------------------------------------ Magick.NET engine
        // NoInlining + separate method: if Magick.NET (or its native DLL) is missing, the
        // FileNotFound/BadImageFormat exception surfaces HERE and is converted to "engine unavailable".
        [MethodImpl(MethodImplOptions.NoInlining)]
        private static bool TryEncodeWithMagick(byte[] data, ImageCategory cat, out byte[] output, out int w, out int h, out string err)
        {
            output = null; w = 0; h = 0; err = null;
            try { return MagickEncode(data, cat, out output, out w, out h, out err); }
            catch (FileNotFoundException) { err = "engine"; return false; }
            catch (FileLoadException) { err = "engine"; return false; }
            catch (BadImageFormatException) { err = "engine"; return false; }
            catch (DllNotFoundException) { err = "engine"; return false; }
            catch (TypeInitializationException) { err = "engine"; return false; }
        }

        [MethodImpl(MethodImplOptions.NoInlining)]
        private static bool MagickEncode(byte[] data, ImageCategory cat, out byte[] output, out int w, out int h, out string err)
        {
            output = null; w = 0; h = 0; err = null;

            // 1. Cheap header read first (no full decode): dimension / pixel limits.
            ImageMagick.MagickImageInfo info;
            try { info = new ImageMagick.MagickImageInfo(data); }
            catch (ImageMagick.MagickException) { err = "REJECT:The file is corrupted or is not a valid image."; return false; }
            if (info.Width > MaxSourceDimension || info.Height > MaxSourceDimension || (long)info.Width * info.Height > MaxSourcePixels)
            { err = "REJECT:Image dimensions are too large (max 8000 px per side)."; return false; }

            // 2. Decode. Animated GIF policy: keep the FIRST frame only (static), documented.
            var settings = new ImageMagick.MagickReadSettings();
            using (var image = new ImageMagick.MagickImage())
            {
                try { image.Ping(data); } catch (ImageMagick.MagickException) { err = "REJECT:The file is corrupted or is not a valid image."; return false; }
                try
                {
                    settings.FrameIndex = 0; settings.FrameCount = 1;
                    image.Read(data, settings);
                }
                catch (ImageMagick.MagickException) { err = "REJECT:The file is corrupted or is not a valid image."; return false; }

                image.AutoOrient();          // honour EXIF rotation, then drop metadata
                image.Strip();               // privacy: removes EXIF/GPS/ICC (sRGB assumed)

                int max = MaxEdge(cat);
                if ((int)image.Width > max || (int)image.Height > max)
                {
                    var g = new ImageMagick.MagickGeometry((uint)max, (uint)max) { IgnoreAspectRatio = false, Greater = true };
                    image.Resize(g);         // aspect preserved; images smaller than max are never enlarged
                }
                w = (int)image.Width; h = (int)image.Height;

                image.Format = ImageMagick.MagickFormat.WebP;
                image.Settings.SetDefine(ImageMagick.MagickFormat.WebP, "method", "6");

                byte[] lossy; byte[] lossless = null;
                image.Quality = (uint)Quality(cat);
                image.Settings.SetDefine(ImageMagick.MagickFormat.WebP, "lossless", "false");
                image.Settings.SetDefine(ImageMagick.MagickFormat.WebP, "alpha-quality", "100"); // keep transparency crisp
                lossy = image.ToByteArray();

                if (cat == ImageCategory.Logo)
                {
                    // Flat-colour logos often look better AND are smaller lossless; keep whichever is smaller.
                    image.Settings.SetDefine(ImageMagick.MagickFormat.WebP, "lossless", "true");
                    lossless = image.ToByteArray();
                }
                output = (lossless != null && lossless.Length <= lossy.Length) ? lossless : lossy;
            }

            // 3. Verify the result really is WebP and decodes before we ever persist it.
            if (DetectSignature(output) != "webp") { err = "REJECT:Conversion failed."; return false; }
            try { var chk = new ImageMagick.MagickImageInfo(output); if (chk.Width == 0) { err = "REJECT:Conversion failed."; return false; } }
            catch (ImageMagick.MagickException) { err = "REJECT:Conversion failed."; return false; }
            return true;
        }

        // ------------------------------------------------------------------ System.Drawing fallback
        private static bool TryEncodeWithGdi(byte[] data, ImageCategory cat, out byte[] output, out int w, out int h, out string ext, out string err)
        {
            output = null; w = 0; h = 0; ext = "png"; err = null;
            try
            {
                using (var ms = new MemoryStream(data))
                using (var src = Image.FromStream(ms, true, true))   // validates the image data
                {
                    if (src.Width > MaxSourceDimension || src.Height > MaxSourceDimension || (long)src.Width * src.Height > MaxSourcePixels)
                    { err = "Image dimensions are too large (max 8000 px per side)."; return false; }

                    int max = MaxEdge(cat);
                    double scale = Math.Min(1.0, Math.Min((double)max / src.Width, (double)max / src.Height)); // never upscale
                    w = Math.Max(1, (int)Math.Round(src.Width * scale));
                    h = Math.Max(1, (int)Math.Round(src.Height * scale));

                    bool hasAlpha = Image.IsAlphaPixelFormat(src.PixelFormat);
                    using (var bmp = new Bitmap(w, h, hasAlpha ? PixelFormat.Format32bppArgb : PixelFormat.Format24bppRgb))
                    {
                        using (var g = Graphics.FromImage(bmp))
                        {
                            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                            g.SmoothingMode = SmoothingMode.HighQuality;
                            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                            if (!hasAlpha) g.Clear(Color.White);
                            g.DrawImage(src, 0, 0, w, h);
                        }
                        using (var outMs = new MemoryStream())
                        {
                            if (hasAlpha || cat == ImageCategory.Logo) { bmp.Save(outMs, ImageFormat.Png); ext = "png"; }
                            else
                            {
                                var enc = Array.Find(ImageCodecInfo.GetImageEncoders(), c => c.FormatID == ImageFormat.Jpeg.Guid);
                                var ep = new EncoderParameters(1);
                                ep.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, (long)Quality(cat));
                                bmp.Save(outMs, enc, ep); ext = "jpg";
                            }
                            output = outMs.ToArray();
                            return true;
                        }
                    }
                }
            }
            catch (Exception) { err = "The file is corrupted or is not a valid image."; return false; }
        }
    }
}
