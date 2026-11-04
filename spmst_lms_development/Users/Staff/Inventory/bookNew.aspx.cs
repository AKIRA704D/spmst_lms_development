using System;
using System.Configuration;
using MySql.Data.MySqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Text.RegularExpressions;
using System.Net;
using System.IO;
using System.Web.Script.Serialization;
using System.Data;
using System.Collections.Generic;
using System.Linq;

namespace spmst_lms_development.Users.Staff.Inventory
{
    public partial class bookNew : System.Web.UI.Page
    {
        // --------------------------------------------------------------------
        // Connection + constants
        // --------------------------------------------------------------------
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;
        private const string DefaultCoverRelative = "Assets/Covers/default-cover.jpg";
        private const string DefaultCoverTilde = "~/Assets/Covers/default-cover.jpg";

        // Static lock — used once per AppDomain when bootstrapping the Campuses lookup.
        private static readonly object CampusLock = new object();

        // --------------------------------------------------------------------
        // Metadata DTO (PascalCase to satisfy naming-rule analyzer)
        // --------------------------------------------------------------------
        private class BookMetadata
        {
            public string Title { get; set; } = "";
            public string Author { get; set; } = "";
            public string Publisher { get; set; } = "";
            public string PublishDate { get; set; } = "";
            public string Description { get; set; } = "";
            public string CoverUrl { get; set; } = "";
            public string Isbn { get; set; } = "";
            public string Issn { get; set; } = "";
            public string DeweyDecimal { get; set; } = "";
            public string Genre { get; set; } = "";
            public string ItemType { get; set; } = "";
            public string Pages { get; set; } = "";
            public string Edition { get; set; } = "";
            public string Language { get; set; } = "";
            public string CopyrightYear { get; set; } = "";
            public string Source { get; set; } = "";
        }

        // ====================================================================
        // PAGE LIFECYCLE
        // ====================================================================

        protected void Page_Load(object sender, EventArgs e)
        {
            EnsureCampusesTable();          // idempotent — creates + seeds the lookup
            if (!IsPostBack)
            {
                LoadDynamicDropdowns();
                SetDefaultValues();
            }
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            // Server-side fallback for the book cover <img>. Assigned here instead of
            // as an inline attribute because <%= %> inside a server-control attribute
            // is not evaluated by the Web Forms parser.
            if (imgCover != null)
            {
                string placeholder = ResolveUrl(DefaultCoverTilde).Replace("'", "\\'");
                imgCover.Attributes["onerror"] =
                    "this.onerror=null;this.src='" + placeholder + "';";
            }
        }

        // ====================================================================
        // CAMPUS LOOKUP BOOTSTRAP
        // ====================================================================

        private void EnsureCampusesTable()
        {
            if (Application["CampusesReady"] != null) return;
            lock (CampusLock)
            {
                if (Application["CampusesReady"] != null) return;
                try
                {
                    using (var conn = new MySqlConnection(_connStr))
                    {
                        conn.Open();

                        const string createSql = @"
                            CREATE TABLE IF NOT EXISTS Campuses (
                                campus_id   INT AUTO_INCREMENT PRIMARY KEY,
                                campus_name VARCHAR(100) NOT NULL,
                                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                UNIQUE KEY uk_campus_name (campus_name)
                            ) ENGINE=InnoDB";
                        using (var cmd = new MySqlCommand(createSql, conn)) cmd.ExecuteNonQuery();

                        // One-time migration — preserve campuses already on Item_Copies.
                        const string seedSql = @"
                            INSERT IGNORE INTO Campuses (campus_name)
                            SELECT DISTINCT campus FROM Item_Copies
                            WHERE campus IS NOT NULL AND campus <> ''";
                        using (var cmd = new MySqlCommand(seedSql, conn)) cmd.ExecuteNonQuery();

                        Application["CampusesReady"] = true;
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("EnsureCampusesTable error: " + ex.Message);
                }
            }
        }

        // ====================================================================
        // DROPDOWN LOADING
        // ====================================================================

        private void SetDefaultValues()
        {
            if (ddlCampus.Items.Count > 1 && string.IsNullOrEmpty(ddlCampus.SelectedValue))
            {
                var preferred = ddlCampus.Items.FindByValue("Malita Campus");
                if (preferred != null)
                {
                    ddlCampus.ClearSelection();
                    preferred.Selected = true;
                }
                else
                {
                    ddlCampus.SelectedIndex = 1;   // first real option after "Choose option..."
                }
            }
            if (string.IsNullOrEmpty(txtSpecificLocation.Text))
                txtSpecificLocation.Text = "Circulation Desk";
        }

        private void LoadDynamicDropdowns()
        {
            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();

                string querySec = "SELECT DISTINCT section FROM Library_Resources WHERE section IS NOT NULL AND section <> '' ORDER BY section";
                FillDropdown(ddlSection, querySec, conn);

                string queryBind = "SELECT DISTINCT binding_type FROM Item_Copies WHERE binding_type IS NOT NULL AND binding_type <> '' ORDER BY binding_type";
                FillDropdown(ddlBinding, queryBind, conn);

                // Campus: UNION of Item_Copies.campus and Campuses.campus_name so that
                // previously-saved book records stay compatible even if a campus was
                // never promoted to the lookup table.
                string queryCampus = @"
                    SELECT name FROM (
                        SELECT campus AS name FROM Item_Copies
                         WHERE campus IS NOT NULL AND campus <> ''
                        UNION
                        SELECT campus_name AS name FROM Campuses
                         WHERE campus_name IS NOT NULL AND campus_name <> ''
                    ) AS c
                    ORDER BY name";
                try
                {
                    FillDropdown(ddlCampus, queryCampus, conn);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Campus UNION error, using Item_Copies only: " + ex.Message);
                    string queryCampusFallback =
                        "SELECT DISTINCT campus FROM Item_Copies WHERE campus IS NOT NULL AND campus <> '' ORDER BY campus";
                    FillDropdown(ddlCampus, queryCampusFallback, conn);
                }
            }
        }

        private void FillDropdown(DropDownList ddl, string query, MySqlConnection conn)
        {
            ddl.Items.Clear();
            ddl.Items.Add(new ListItem("Choose option...", ""));
            using (MySqlCommand cmd = new MySqlCommand(query, conn))
            using (MySqlDataReader dr = cmd.ExecuteReader())
            {
                while (dr.Read())
                {
                    string val = dr[0].ToString();
                    ddl.Items.Add(new ListItem(val, val));
                }
            }
        }

        // ====================================================================
        // CAMPUS HELPERS
        // ====================================================================

        // Returns the first existing campus name (case/whitespace-insensitive) or "".
        private string FindExistingCampus(string name, MySqlConnection conn)
        {
            const string sql = @"
                SELECT name FROM (
                    SELECT campus_name AS name FROM Campuses
                     WHERE LOWER(TRIM(campus_name)) = LOWER(TRIM(@name))
                    UNION
                    SELECT campus AS name FROM Item_Copies
                     WHERE campus IS NOT NULL AND LOWER(TRIM(campus)) = LOWER(TRIM(@name))
                ) AS x
                LIMIT 1";
            using (var cmd = new MySqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@name", name);
                object result = cmd.ExecuteScalar();
                return result == null || result == DBNull.Value ? "" : result.ToString();
            }
        }

        private void RebindCampusDropdown()
        {
            using (var conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                string query = @"
                    SELECT name FROM (
                        SELECT campus AS name FROM Item_Copies
                         WHERE campus IS NOT NULL AND campus <> ''
                        UNION
                        SELECT campus_name AS name FROM Campuses
                         WHERE campus_name IS NOT NULL AND campus_name <> ''
                    ) AS c
                    ORDER BY name";
                FillDropdown(ddlCampus, query, conn);
            }
        }

        private void SelectCampusValue(string value)
        {
            if (string.IsNullOrEmpty(value) || ddlCampus.Items.Count == 0) return;
            var item = ddlCampus.Items.FindByValue(value);
            if (item != null)
            {
                ddlCampus.ClearSelection();
                item.Selected = true;
            }
        }

        // ====================================================================
        // CAMPUS ADD-NEW HANDLER
        // ====================================================================

        protected void BtnAddCampus_Click(object sender, EventArgs e)
        {
            string newCampus = (txtNewCampus.Text ?? "").Trim();

            if (string.IsNullOrEmpty(newCampus))
            {
                ShowSweetAlert("Input Required", "Please enter a campus name.", "warning");
                txtNewCampus.Focus();
                return;
            }
            if (newCampus.Length > 100)
            {
                ShowSweetAlert("Invalid Input", "Campus name must not exceed 100 characters.", "warning");
                txtNewCampus.Focus();
                return;
            }

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();

                    string existingName = FindExistingCampus(newCampus, conn);
                    if (!string.IsNullOrEmpty(existingName))
                    {
                        // Promote to lookup so it survives a future Item_Copies cleanup.
                        const string promoteSql = "INSERT IGNORE INTO Campuses (campus_name) VALUES (@name)";
                        using (var promote = new MySqlCommand(promoteSql, conn))
                        {
                            promote.Parameters.AddWithValue("@name", existingName);
                            promote.ExecuteNonQuery();
                        }

                        RebindCampusDropdown();
                        SelectCampusValue(existingName);
                        txtNewCampus.Text = "";

                        ShowSweetAlert("Campus Already Exists",
                            $"'{existingName}' is already in the list. It has been selected for you.",
                            "info");
                        return;
                    }

                    const string insertSql = "INSERT INTO Campuses (campus_name) VALUES (@name)";
                    using (var cmd = new MySqlCommand(insertSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@name", newCampus);
                        cmd.ExecuteNonQuery();
                    }

                    RebindCampusDropdown();
                    SelectCampusValue(newCampus);
                    txtNewCampus.Text = "";

                    ShowSweetAlert("Success", $"Campus '{newCampus}' has been added and selected.", "success");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("BtnAddCampus_Click error: " + ex.Message);
                ShowSweetAlert("Error", "The campus could not be added. Please try again.", "error");
            }
        }

        // ====================================================================
        // SAFE DICTIONARY ACCESS
        // ====================================================================

        private string SafeGetString(Dictionary<string, object> dict, string key)
        {
            if (dict == null) return "";
            object val;
            if (!dict.TryGetValue(key, out val) || val == null || val == DBNull.Value)
                return "";
            return val.ToString();
        }

        private string CleanIdentifier(string identifier)
        {
            return string.IsNullOrEmpty(identifier) ? "" : Regex.Replace(identifier.Trim(), @"[-\s]", "");
        }

        // ====================================================================
        // CHECK BUTTON HANDLER
        // ====================================================================

        protected void CheckExistingResource(object sender, EventArgs e)
        {
            string rawIsbn = txtISBN.Text.Trim();
            string rawIssn = txtISSN.Text.Trim();
            string cleanIsbn = CleanIdentifier(rawIsbn);
            string cleanIssn = CleanIdentifier(rawIssn);
            string title = txtTitle.Text.Trim();
            string author = txtAuthors.Text.Trim();

            ViewState["CleanISBN"] = cleanIsbn;
            ViewState["CleanISSN"] = cleanIssn;

            if (string.IsNullOrEmpty(cleanIsbn) && string.IsNullOrEmpty(cleanIssn) && string.IsNullOrEmpty(title))
            {
                ShowSweetAlert("No Identifier", "Please enter ISBN, ISSN, or Book Title to check.", "warning");
                return;
            }

            try
            {
                using (MySqlConnection conn = new MySqlConnection(_connStr))
                {
                    conn.Open();

                    // SELECT every column PopulateFormFromDictionary may read.
                    string query = @"SELECT resource_id, item_type, isbn, issn, call_number, dewey_decimal,
                                            genre, title, author, section, publisher, place_of_publication,
                                            series, edition, pub_year, copyright_year, pages_numeric,
                                            height_cm, width_cm, accompanying_material, description, cover_path
                                     FROM Library_Resources
                                     WHERE (isbn = @isbnRaw OR isbn = @isbnClean)
                                        OR (issn = @issnRaw OR issn = @issnClean)
                                        OR (title = @title AND (@author = '' OR author = @author))
                                     LIMIT 5";
                    var cmd = new MySqlCommand(query, conn);
                    cmd.Parameters.AddWithValue("@isbnRaw", rawIsbn);
                    cmd.Parameters.AddWithValue("@isbnClean", cleanIsbn);
                    cmd.Parameters.AddWithValue("@issnRaw", rawIssn);
                    cmd.Parameters.AddWithValue("@issnClean", cleanIssn);
                    cmd.Parameters.AddWithValue("@title", title);
                    cmd.Parameters.AddWithValue("@author", author);

                    var matches = new List<Dictionary<string, object>>();
                    using (var dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            var match = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
                            for (int i = 0; i < dr.FieldCount; i++)
                                match[dr.GetName(i)] = dr.GetValue(i);
                            matches.Add(match);
                        }
                    }

                    if (matches.Count > 0)
                    {
                        var exactIsbnMatch = matches.FirstOrDefault(m =>
                            !string.IsNullOrEmpty(cleanIsbn) &&
                            (SafeGetString(m, "isbn") == rawIsbn || SafeGetString(m, "isbn") == cleanIsbn));

                        var exactIssnMatch = matches.FirstOrDefault(m =>
                            !string.IsNullOrEmpty(cleanIssn) &&
                            (SafeGetString(m, "issn") == rawIssn || SafeGetString(m, "issn") == cleanIssn));

                        var exactTitleAuthorMatch = matches.FirstOrDefault(m =>
                            SafeGetString(m, "title") == title &&
                            (string.IsNullOrEmpty(author) || SafeGetString(m, "author") == author));

                        var differentEditionMatches = matches.Where(m =>
                            SafeGetString(m, "title") == title &&
                            SafeGetString(m, "author") == author &&
                            SafeGetString(m, "isbn") != cleanIsbn &&
                            !string.IsNullOrEmpty(cleanIsbn)).ToList();

                        if (exactIsbnMatch != null || exactIssnMatch != null)
                        {
                            var matchRecord = exactIsbnMatch ?? exactIssnMatch;
                            PopulateFormFromDictionary(matchRecord);
                            ShowSweetAlert("Record Found",
                                $"An existing record was found with the same {(exactIsbnMatch != null ? "ISBN" : "ISSN")}. " +
                                "You can update the details or add a new copy.", "info");
                            return;
                        }
                        else if (differentEditionMatches.Count > 0)
                        {
                            var existingMatch = differentEditionMatches.First();
                            string existingIsbn = SafeGetString(existingMatch, "isbn");
                            string existingEdition = SafeGetString(existingMatch, "edition");
                            string existingPublisher = SafeGetString(existingMatch, "publisher");
                            string existingYear = SafeGetString(existingMatch, "pub_year");

                            string message = $"<b>⚠️ DIFFERENT EDITION/FORMAT DETECTED</b><br/><br/>" +
                                             $"A book with the same title and author already exists but with a different ISBN.<br/><br/>" +
                                             $"<b>📚 EXISTING RECORD:</b><br/>" +
                                             $"• ISBN: {(string.IsNullOrEmpty(existingIsbn) ? "N/A" : existingIsbn)}<br/>" +
                                             $"• Edition: {(string.IsNullOrEmpty(existingEdition) ? "Unknown Edition" : existingEdition)}<br/>" +
                                             $"• Publisher: {(string.IsNullOrEmpty(existingPublisher) ? "Unknown Publisher" : existingPublisher)}<br/>" +
                                             $"• Year: {(string.IsNullOrEmpty(existingYear) ? "Unknown Year" : existingYear)}<br/><br/>" +
                                             $"<b>📖 YOUR INPUT:</b><br/>• ISBN: {(string.IsNullOrEmpty(cleanIsbn) ? "Not provided" : cleanIsbn)}<br/><br/>" +
                                             $"<b>❓ WHAT WOULD YOU LIKE TO DO?</b><br/>" +
                                             $"• <b>Add as New Resource</b> - Create a separate record<br/>" +
                                             $"• <b>Update Existing</b> - Replace the existing record<br/>" +
                                             $"• <b>Cancel</b> - Review your input";

                            object ridVal;
                            if (existingMatch.TryGetValue("resource_id", out ridVal) && ridVal != null && ridVal != DBNull.Value)
                            {
                                Session["ExistingResourceId"] = Convert.ToInt32(ridVal);
                                Session["IsDifferentEdition"] = true;
                            }
                            ShowSweetAlertWithThreeOptions("Different Edition Detected", message, "question",
                                "Add as New Resource", "Update Existing", "Cancel");
                            return;
                        }
                        else if (exactTitleAuthorMatch == null && matches.Any(m => SafeGetString(m, "title") == title))
                        {
                            var titleMatch = matches.First(m => SafeGetString(m, "title") == title);
                            string existingAuthor = SafeGetString(titleMatch, "author");
                            string existingIsbn = SafeGetString(titleMatch, "isbn");
                            string message = $"<b>⚠️ TITLE CONFLICT DETECTED</b><br/><br/>" +
                                             $"A book with the same title but different author exists.<br/><br/>" +
                                             $"<b>EXISTING:</b> {title}<br/>" +
                                             $"Author: {(string.IsNullOrEmpty(existingAuthor) ? "Unknown Author" : existingAuthor)}, " +
                                             $"ISBN: {(string.IsNullOrEmpty(existingIsbn) ? "N/A" : existingIsbn)}<br/>" +
                                             $"<b>YOUR INPUT:</b> Author: {(string.IsNullOrEmpty(author) ? "Not provided" : author)}<br/><br/>" +
                                             $"Please choose an action:";

                            object ridVal2;
                            if (titleMatch.TryGetValue("resource_id", out ridVal2) && ridVal2 != null && ridVal2 != DBNull.Value)
                                Session["ExistingResourceId"] = Convert.ToInt32(ridVal2);

                            ShowSweetAlertWithThreeOptions("Title Conflict", message, "warning",
                                "Add as New Book", "Use Existing Record", "Cancel");
                            return;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("CheckExistingResource DB error: " + ex);
                ShowSweetAlert("Lookup Error",
                    "We could not check the local catalog right now. External lookup will still be attempted.", "warning");
            }

            ShowSweetAlert("Fetching Data", "No existing record found. Retrieving from external sources...", "info");
            FetchAndPopulateFromAPIs(cleanIsbn, cleanIssn);
        }

        // ====================================================================
        // EXTERNAL METADATA PIPELINE
        // ====================================================================

        private void FetchAndPopulateFromAPIs(string cleanIsbn, string cleanIssn)
        {
            var metadata = new BookMetadata();
            if (!string.IsNullOrEmpty(cleanIsbn))
            {
                metadata = GetMetadataFromGoogleBooks(cleanIsbn);
                if (string.IsNullOrEmpty(metadata.Title))
                    metadata = GetMetadataFromOpenLibrary(cleanIsbn);
                if (string.IsNullOrEmpty(metadata.Title))
                    metadata = GetMetadataFromCrossRef(cleanIsbn);
                if (!string.IsNullOrEmpty(metadata.Title))
                    txtISBN.Text = string.IsNullOrEmpty(metadata.Isbn) ? cleanIsbn : metadata.Isbn;
            }
            else if (!string.IsNullOrEmpty(cleanIssn))
            {
                metadata = GetMetadataFromCrossRef(cleanIssn);
                if (string.IsNullOrEmpty(metadata.Title))
                    metadata = GetMetadataFromOpenLibraryByIssn(cleanIssn);
                if (!string.IsNullOrEmpty(metadata.Title))
                    txtISSN.Text = string.IsNullOrEmpty(metadata.Issn) ? cleanIssn : metadata.Issn;
            }

            if (!string.IsNullOrEmpty(metadata.Title))
            {
                PopulateFormFromMetadata(metadata);
                ShowSweetAlert($"Data Retrieved from {metadata.Source}",
                    "Book/Journal details have been auto-populated.", "success");
            }
            else
            {
                ViewState["FetchedCoverPath"] = null;
                imgCover.ImageUrl = DefaultCoverTilde;
                ShowSweetAlert("No Record Found",
                    "No existing book found and unable to retrieve from external APIs. You can continue manually.", "info");
            }
        }

        // ====================================================================
        // PROVIDER: GOOGLE BOOKS
        // ====================================================================
        private BookMetadata GetMetadataFromGoogleBooks(string cleanIsbn)
        {
            var metadata = new BookMetadata { Source = "Google Books" };
            try
            {
                string url = $"https://www.googleapis.com/books/v1/volumes?q=isbn:{cleanIsbn}";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    var root = serializer.Deserialize<Dictionary<string, object>>(json);
                    if (root == null) return metadata;

                    if (!root.ContainsKey("totalItems")) return metadata;
                    if (Convert.ToInt32(root["totalItems"]) <= 0) return metadata;
                    if (!root.ContainsKey("items")) return metadata;

                    var items = root["items"] as object[];
                    if (items == null || items.Length == 0) return metadata;

                    var firstItem = items[0] as Dictionary<string, object>;
                    if (firstItem == null || !firstItem.ContainsKey("volumeInfo")) return metadata;

                    var volumeInfo = firstItem["volumeInfo"] as Dictionary<string, object>;
                    if (volumeInfo == null) return metadata;

                    if (volumeInfo.ContainsKey("title") && volumeInfo["title"] != null)
                        metadata.Title = volumeInfo["title"].ToString();
                    if (volumeInfo.ContainsKey("subtitle") && volumeInfo["subtitle"] != null)
                        metadata.Title += (metadata.Title.Length > 0 ? ": " : "") + volumeInfo["subtitle"].ToString();

                    var authorsArr = volumeInfo.ContainsKey("authors") ? volumeInfo["authors"] as object[] : null;
                    if (authorsArr != null && authorsArr.Length > 0)
                        metadata.Author = string.Join(", ", authorsArr.Where(a => a != null).Select(a => a.ToString()));

                    if (volumeInfo.ContainsKey("publisher") && volumeInfo["publisher"] != null)
                        metadata.Publisher = volumeInfo["publisher"].ToString();

                    if (volumeInfo.ContainsKey("publishedDate") && volumeInfo["publishedDate"] != null)
                    {
                        metadata.PublishDate = volumeInfo["publishedDate"].ToString();
                        var y = Regex.Match(metadata.PublishDate, @"\d{4}");
                        if (y.Success) metadata.CopyrightYear = y.Value;
                    }

                    if (volumeInfo.ContainsKey("description") && volumeInfo["description"] != null)
                        metadata.Description = volumeInfo["description"].ToString();

                    if (volumeInfo.ContainsKey("pageCount") && volumeInfo["pageCount"] != null)
                        metadata.Pages = volumeInfo["pageCount"].ToString();

                    var idsArr = volumeInfo.ContainsKey("industryIdentifiers") ? volumeInfo["industryIdentifiers"] as object[] : null;
                    if (idsArr != null)
                    {
                        string isbn10 = "", isbn13 = "";
                        foreach (var id in idsArr)
                        {
                            var d = id as Dictionary<string, object>;
                            if (d == null) continue;
                            string type = d.ContainsKey("type") ? (d["type"] ?? "").ToString() : "";
                            string value = d.ContainsKey("identifier") ? (d["identifier"] ?? "").ToString() : "";
                            if (type == "ISBN_13") isbn13 = value;
                            else if (type == "ISBN_10") isbn10 = value;
                        }
                        metadata.Isbn = !string.IsNullOrEmpty(isbn13) ? isbn13 : isbn10;
                    }
                    if (string.IsNullOrEmpty(metadata.Isbn)) metadata.Isbn = cleanIsbn;

                    // categories[] → Genre (NOT DDC!)
                    var catArr = volumeInfo.ContainsKey("categories") ? volumeInfo["categories"] as object[] : null;
                    if (catArr != null && catArr.Length > 0)
                        metadata.Genre = string.Join(", ", catArr.Where(c => c != null).Select(c => c.ToString()));

                    var links = volumeInfo.ContainsKey("imageLinks") ? volumeInfo["imageLinks"] as Dictionary<string, object> : null;
                    if (links != null)
                    {
                        string thumb = "";
                        if (links.ContainsKey("thumbnail") && links["thumbnail"] != null)
                            thumb = links["thumbnail"].ToString();
                        else if (links.ContainsKey("smallThumbnail") && links["smallThumbnail"] != null)
                            thumb = links["smallThumbnail"].ToString();
                        if (!string.IsNullOrEmpty(thumb))
                            metadata.CoverUrl = thumb.Replace("http://", "https://");
                    }
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"Google Books error: {ex.Message}"); }
            return metadata;
        }

        // ====================================================================
        // PROVIDER: OPENLIBRARY (ISBN)
        // ====================================================================
        private BookMetadata GetMetadataFromOpenLibrary(string cleanIsbn)
        {
            var metadata = new BookMetadata { Source = "OpenLibrary" };
            try
            {
                string url = $"https://openlibrary.org/api/books?bibkeys=ISBN:{cleanIsbn}&format=json&jscmd=data";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    var root = serializer.Deserialize<Dictionary<string, object>>(json);
                    if (root == null) return metadata;

                    string key = $"ISBN:{cleanIsbn}";
                    if (!root.ContainsKey(key) || root[key] == null) return metadata;

                    var bookData = root[key] as Dictionary<string, object>;
                    if (bookData == null) return metadata;

                    if (bookData.ContainsKey("title") && bookData["title"] != null)
                        metadata.Title = bookData["title"].ToString();
                    metadata.Isbn = cleanIsbn;

                    var authArr = bookData.ContainsKey("authors") ? bookData["authors"] as object[] : null;
                    if (authArr != null)
                    {
                        var names = new List<string>();
                        foreach (var a in authArr)
                        {
                            var d = a as Dictionary<string, object>;
                            if (d != null && d.ContainsKey("name") && d["name"] != null)
                                names.Add(d["name"].ToString());
                        }
                        metadata.Author = string.Join(", ", names.Where(n => n.Length > 0));
                    }

                    var pubArr = bookData.ContainsKey("publishers") ? bookData["publishers"] as object[] : null;
                    if (pubArr != null && pubArr.Length > 0)
                    {
                        var p = pubArr[0] as Dictionary<string, object>;
                        if (p != null && p.ContainsKey("name") && p["name"] != null)
                            metadata.Publisher = p["name"].ToString();
                    }

                    if (bookData.ContainsKey("publish_date") && bookData["publish_date"] != null)
                        metadata.PublishDate = bookData["publish_date"].ToString();

                    if (bookData.ContainsKey("description") && bookData["description"] != null)
                    {
                        if (bookData["description"] is string) metadata.Description = (string)bookData["description"];
                        else
                        {
                            var descDict = bookData["description"] as Dictionary<string, object>;
                            if (descDict != null && descDict.ContainsKey("value") && descDict["value"] != null)
                                metadata.Description = descDict["value"].ToString();
                        }
                    }

                    if (bookData.ContainsKey("number_of_pages") && bookData["number_of_pages"] != null)
                        metadata.Pages = bookData["number_of_pages"].ToString();

                    // REAL dewey_decimal_class — safe to map
                    if (bookData.ContainsKey("classifications"))
                    {
                        var cls = bookData["classifications"] as Dictionary<string, object>;
                        if (cls != null && cls.ContainsKey("dewey_decimal_class"))
                        {
                            var ddcArr = cls["dewey_decimal_class"] as object[];
                            if (ddcArr != null && ddcArr.Length > 0 && ddcArr[0] != null)
                                metadata.DeweyDecimal = ddcArr[0].ToString();
                        }
                    }

                    var subjArr = bookData.ContainsKey("subjects") ? bookData["subjects"] as object[] : null;
                    if (subjArr != null)
                    {
                        var names = new List<string>();
                        foreach (var s in subjArr)
                        {
                            var d = s as Dictionary<string, object>;
                            if (d != null && d.ContainsKey("name") && d["name"] != null)
                                names.Add(d["name"].ToString());
                            if (names.Count >= 3) break;
                        }
                        if (names.Count > 0) metadata.Genre = string.Join(", ", names.Where(n => n.Length > 0));
                    }

                    var coverDict = bookData.ContainsKey("cover") ? bookData["cover"] as Dictionary<string, object> : null;
                    if (coverDict != null)
                    {
                        if (coverDict.ContainsKey("large") && coverDict["large"] != null)
                            metadata.CoverUrl = "https:" + coverDict["large"].ToString();
                        else if (coverDict.ContainsKey("medium") && coverDict["medium"] != null)
                            metadata.CoverUrl = "https:" + coverDict["medium"].ToString();
                    }
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"OpenLibrary error: {ex.Message}"); }
            return metadata;
        }

        // ====================================================================
        // PROVIDER: OPENLIBRARY (ISSN)
        // ====================================================================
        private BookMetadata GetMetadataFromOpenLibraryByIssn(string issn)
        {
            var metadata = new BookMetadata { Source = "OpenLibrary" };
            try
            {
                string cleanIssn = issn.Replace("-", "").Trim();
                string url = $"https://openlibrary.org/search.json?q=issn:{cleanIssn}&limit=1";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    var root = serializer.Deserialize<Dictionary<string, object>>(json);
                    if (root == null) return metadata;

                    var docs = root.ContainsKey("docs") ? root["docs"] as object[] : null;
                    if (docs == null || docs.Length == 0) return metadata;

                    var doc = docs[0] as Dictionary<string, object>;
                    if (doc == null) return metadata;

                    if (doc.ContainsKey("title") && doc["title"] != null)
                        metadata.Title = doc["title"].ToString();
                    metadata.Issn = issn;

                    var authors = doc.ContainsKey("author_name") ? doc["author_name"] as object[] : null;
                    if (authors != null)
                        metadata.Author = string.Join(", ", authors.Where(a => a != null).Select(a => a.ToString()));

                    var pubs = doc.ContainsKey("publisher") ? doc["publisher"] as object[] : null;
                    if (pubs != null)
                        metadata.Publisher = string.Join(", ", pubs.Where(p => p != null).Select(p => p.ToString()));

                    if (doc.ContainsKey("first_publish_year") && doc["first_publish_year"] != null)
                        metadata.PublishDate = doc["first_publish_year"].ToString();

                    var subjects = doc.ContainsKey("subject") ? doc["subject"] as object[] : null;
                    if (subjects != null)
                    {
                        var names = new List<string>();
                        foreach (var s in subjects) { if (s != null) names.Add(s.ToString()); if (names.Count >= 3) break; }
                        metadata.Genre = string.Join(", ", names.Where(n => n.Length > 0));
                    }

                    if (doc.ContainsKey("cover_i") && doc["cover_i"] != null)
                        metadata.CoverUrl = $"https://covers.openlibrary.org/b/id/{doc["cover_i"]}-L.jpg";
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"OpenLibrary ISSN error: {ex.Message}"); }
            return metadata;
        }

        // ====================================================================
        // PROVIDER: CROSSREF
        // ====================================================================
        private BookMetadata GetMetadataFromCrossRef(string cleanIdentifier)
        {
            var metadata = new BookMetadata { Source = "CrossRef" };
            try
            {
                string url = $"https://api.crossref.org/works/{cleanIdentifier}";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    client.Headers.Add("Accept", "application/json");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    var root = serializer.Deserialize<Dictionary<string, object>>(json);
                    if (root == null) return metadata;

                    if (!root.ContainsKey("status")) return metadata;
                    if (!"ok".Equals(root["status"] as string)) return metadata;
                    if (!root.ContainsKey("message") || root["message"] == null) return metadata;

                    var message = root["message"] as Dictionary<string, object>;
                    if (message == null) return metadata;

                    if (message.ContainsKey("title") && message["title"] != null)
                    {
                        var titles = message["title"] as object[];
                        if (titles != null && titles.Length > 0 && titles[0] != null)
                            metadata.Title = titles[0].ToString();
                    }

                    var authorArr = message.ContainsKey("author") ? message["author"] as object[] : null;
                    if (authorArr != null)
                    {
                        var authors = new List<string>();
                        foreach (var a in authorArr)
                        {
                            var d = a as Dictionary<string, object>;
                            if (d == null) continue;
                            string given = d.ContainsKey("given") && d["given"] != null ? d["given"].ToString() : "";
                            string family = d.ContainsKey("family") && d["family"] != null ? d["family"].ToString() : "";
                            string name = (given + " " + family).Trim();
                            if (string.IsNullOrEmpty(name) && d.ContainsKey("name") && d["name"] != null)
                                name = d["name"].ToString();
                            if (!string.IsNullOrEmpty(name)) authors.Add(name);
                        }
                        metadata.Author = string.Join(", ", authors);
                    }

                    if (message.ContainsKey("publisher") && message["publisher"] != null)
                        metadata.Publisher = message["publisher"].ToString();

                    var issued = message.ContainsKey("issued") ? message["issued"] as Dictionary<string, object> : null;
                    if (issued != null && issued.ContainsKey("date-parts"))
                    {
                        var dateParts = issued["date-parts"] as object[];
                        if (dateParts != null && dateParts.Length > 0)
                        {
                            var inner = dateParts[0] as object[];
                            if (inner != null && inner.Length > 0 && inner[0] != null)
                                metadata.PublishDate = inner[0].ToString();
                        }
                    }

                    var print = message.ContainsKey("published-print") ? message["published-print"] as Dictionary<string, object> : null;
                    if (print != null && print.ContainsKey("date-parts"))
                    {
                        var dateParts = print["date-parts"] as object[];
                        if (dateParts != null && dateParts.Length > 0)
                        {
                            var inner = dateParts[0] as object[];
                            if (inner != null && inner.Length > 0 && inner[0] != null)
                            {
                                string cy = inner[0].ToString();
                                if (Regex.IsMatch(cy, @"^\d{4}$")) metadata.CopyrightYear = cy;
                            }
                        }
                    }

                    if (message.ContainsKey("abstract") && message["abstract"] != null)
                    {
                        string abstractText = message["abstract"].ToString();
                        metadata.Description = Regex.Replace(abstractText, "<.*?>", string.Empty).Trim();
                        if (metadata.Description.Length > 500)
                            metadata.Description = metadata.Description.Substring(0, 500) + "...";
                    }

                    if (message.ContainsKey("page") && message["page"] != null)
                        metadata.Pages = message["page"].ToString();

                    var issnArr = message.ContainsKey("ISSN") ? message["ISSN"] as object[] : null;
                    if (issnArr != null && issnArr.Length > 0 && issnArr[0] != null)
                        metadata.Issn = issnArr[0].ToString();

                    var isbnArr = message.ContainsKey("ISBN") ? message["ISBN"] as object[] : null;
                    if (isbnArr != null && isbnArr.Length > 0 && isbnArr[0] != null)
                        metadata.Isbn = isbnArr[0].ToString();

                    if (message.ContainsKey("type") && message["type"] != null)
                        metadata.ItemType = MapCrossRefType(message["type"].ToString());

                    var subjArr = message.ContainsKey("subject") ? message["subject"] as object[] : null;
                    if (subjArr != null)
                    {
                        var names = new List<string>();
                        foreach (var s in subjArr) { if (s != null) names.Add(s.ToString()); if (names.Count >= 3) break; }
                        metadata.Genre = string.Join(", ", names.Where(n => n.Length > 0));
                    }
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"CrossRef error: {ex.Message}"); }
            return metadata;
        }

        private string MapCrossRefType(string type)
        {
            if (string.IsNullOrEmpty(type)) return "";
            switch (type.ToLowerInvariant())
            {
                case "book":
                case "monograph":
                case "edited-book":
                case "reference-book":
                case "book-set": return "Book";
                case "book-chapter":
                case "book-part":
                case "book-section": return "Book Chapter";
                case "journal":
                case "journal-article":
                case "journal-issue":
                case "journal-volume": return "Journal";
                case "proceedings":
                case "proceedings-article":
                case "proceedings-series": return "Proceedings";
                case "report":
                case "report-series": return "Report";
                case "dissertation": return "Thesis";
                case "posted-content": return "Preprint";
                case "reference-entry": return "Reference";
                default: return "";
            }
        }

        // ====================================================================
        // FORM POPULATION
        // ====================================================================

        private void PopulateFormFromDictionary(Dictionary<string, object> record)
        {
            if (record == null) return;

            txtItemType.Text = SafeGetString(record, "item_type");
            txtGenre.Text = SafeGetString(record, "genre");
            txtCallNumber.Text = SafeGetString(record, "call_number");
            txtDewey.Text = SafeGetString(record, "dewey_decimal");
            txtTitle.Text = SafeGetString(record, "title");
            txtAuthors.Text = SafeGetString(record, "author");
            txtPublisher.Text = SafeGetString(record, "publisher");
            txtPlace.Text = SafeGetString(record, "place_of_publication");
            txtSeries.Text = SafeGetString(record, "series");
            txtEdition.Text = SafeGetString(record, "edition");
            txtPubYear.Text = SafeGetString(record, "pub_year");
            txtCopyright.Text = SafeGetString(record, "copyright_year");
            txtPages.Text = SafeGetString(record, "pages_numeric");
            txtHeight.Text = SafeGetString(record, "height_cm");
            txtWidth.Text = SafeGetString(record, "width_cm");
            txtMaterial.Text = SafeGetString(record, "accompanying_material");
            txtDescription.Text = SafeGetString(record, "description");

            string recIsbn = SafeGetString(record, "isbn");
            string recIssn = SafeGetString(record, "issn");
            if (!string.IsNullOrEmpty(recIsbn)) txtISBN.Text = recIsbn;
            if (!string.IsNullOrEmpty(recIssn)) txtISSN.Text = recIssn;

            string coverPath = SafeGetString(record, "cover_path");
            if (!string.IsNullOrEmpty(coverPath))
            {
                string clean = coverPath.Replace("~/", "").TrimStart('/');
                ViewState["FetchedCoverPath"] = clean;
                imgCover.ImageUrl = "~/" + clean;
            }
            else
            {
                ViewState["FetchedCoverPath"] = null;
                imgCover.ImageUrl = DefaultCoverTilde;
            }

            txtAccession.Text = "";
            txtAccession.Focus();
        }

        private void PopulateFormFromMetadata(BookMetadata metadata)
        {
            if (metadata == null) return;

            if (!string.IsNullOrEmpty(metadata.Title)) txtTitle.Text = metadata.Title;
            if (!string.IsNullOrEmpty(metadata.Author)) txtAuthors.Text = metadata.Author;
            if (!string.IsNullOrEmpty(metadata.Publisher)) txtPublisher.Text = metadata.Publisher;
            if (!string.IsNullOrEmpty(metadata.Pages)) txtPages.Text = metadata.Pages;
            if (!string.IsNullOrEmpty(metadata.Edition)) txtEdition.Text = metadata.Edition;
            if (!string.IsNullOrEmpty(metadata.ItemType)) txtItemType.Text = metadata.ItemType;
            if (!string.IsNullOrEmpty(metadata.Genre)) txtGenre.Text = metadata.Genre;
            if (!string.IsNullOrEmpty(metadata.Description)) txtDescription.Text = metadata.Description;

            if (!string.IsNullOrEmpty(metadata.Isbn) && string.IsNullOrEmpty(txtISBN.Text.Trim()))
                txtISBN.Text = metadata.Isbn;
            if (!string.IsNullOrEmpty(metadata.Issn) && string.IsNullOrEmpty(txtISSN.Text.Trim()))
                txtISSN.Text = metadata.Issn;

            if (!string.IsNullOrEmpty(metadata.DeweyDecimal) && string.IsNullOrEmpty(txtDewey.Text.Trim()))
                txtDewey.Text = metadata.DeweyDecimal;

            if (!string.IsNullOrEmpty(metadata.PublishDate))
            {
                var yearMatch = Regex.Match(metadata.PublishDate, @"\d{4}");
                if (yearMatch.Success) txtPubYear.Text = yearMatch.Value;
            }

            if (!string.IsNullOrEmpty(metadata.CopyrightYear) && string.IsNullOrEmpty(txtCopyright.Text.Trim()))
            {
                var cyMatch = Regex.Match(metadata.CopyrightYear, @"^\d{4}$");
                if (cyMatch.Success) txtCopyright.Text = cyMatch.Value;
            }

            if (!string.IsNullOrEmpty(metadata.CoverUrl))
            {
                string coverPath = DownloadAndSaveCover(metadata.CoverUrl, txtISBN.Text, txtISSN.Text);
                ViewState["FetchedCoverPath"] = coverPath;
                imgCover.ImageUrl = coverPath == DefaultCoverRelative
                    ? DefaultCoverTilde
                    : "~/" + coverPath;
            }
            else
            {
                ViewState["FetchedCoverPath"] = null;
                imgCover.ImageUrl = DefaultCoverTilde;
            }

            txtAccession.Focus();
        }

        // ====================================================================
        // COVER DOWNLOAD — always returns a DB-safe relative path
        // ====================================================================

        private string DownloadAndSaveCover(string url, string isbn, string issn)
        {
            if (string.IsNullOrWhiteSpace(url)) return DefaultCoverRelative;

            try
            {
                string folderPath = Server.MapPath("~/Assets/Covers/");
                if (!Directory.Exists(folderPath)) Directory.CreateDirectory(folderPath);

                string identifier = !string.IsNullOrWhiteSpace(isbn) ? isbn.Trim() : issn.Trim();
                if (string.IsNullOrEmpty(identifier)) return DefaultCoverRelative;
                foreach (char c in Path.GetInvalidFileNameChars())
                    identifier = identifier.Replace(c.ToString(), "");

                string fileName = $"{identifier}.jpg";
                string fullPath = Path.Combine(folderPath, fileName);

                if (File.Exists(fullPath) && new FileInfo(fullPath).Length > 0)
                    return $"Assets/Covers/{fileName}";

                string httpsUrl = url.Replace("http://", "https://");
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    client.DownloadFile(httpsUrl, fullPath);
                }

                // Magic-byte check — reject HTML error pages etc.
                bool isImage = false;
                if (File.Exists(fullPath) && new FileInfo(fullPath).Length > 4)
                {
                    byte[] hdr = new byte[4];
                    using (var fs = File.OpenRead(fullPath)) { fs.Read(hdr, 0, 4); }
                    bool jpeg = hdr[0] == 0xFF && hdr[1] == 0xD8;
                    bool png = hdr[0] == 0x89 && hdr[1] == 0x50 && hdr[2] == 0x4E && hdr[3] == 0x47;
                    isImage = jpeg || png;
                }

                if (!isImage)
                {
                    try { if (File.Exists(fullPath)) File.Delete(fullPath); } catch { }
                    return DefaultCoverRelative;
                }

                return $"Assets/Covers/{fileName}";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Cover download error: {ex.Message}");
                return DefaultCoverRelative;
            }
        }

        // ====================================================================
        // SAVE
        // ====================================================================

        protected void BtnSave_Click(object sender, EventArgs e)
        {
            string accession = txtAccession.Text.Trim().ToUpper();
            txtAccession.Text = accession;
            string binding = !string.IsNullOrEmpty(txtNewBinding.Text) ? txtNewBinding.Text.Trim() : ddlBinding.SelectedValue;
            string condition = ddlCondition.SelectedValue;

            // Match Binding Type behaviour: a freshly-typed value takes precedence.
            string campus = !string.IsNullOrEmpty(txtNewCampus.Text.Trim())
                ? txtNewCampus.Text.Trim()
                : ddlCampus.SelectedValue;

            string specificLocation = string.IsNullOrEmpty(txtSpecificLocation.Text.Trim()) ? "Circulation Desk" : txtSpecificLocation.Text.Trim();
            string remarks = txtRemarks.Text.Trim();
            string isbn = txtISBN.Text.Trim();
            string issn = txtISSN.Text.Trim();
            string title = txtTitle.Text.Trim();

            bool isDifferentEdition = Session["IsDifferentEdition"] != null && (bool)Session["IsDifferentEdition"];
            bool forceUpdate = hfForceUpdate.Value == "true";

            if (isDifferentEdition && !forceUpdate)
            {
                Session["IsDifferentEdition"] = null;
                Session["ExistingResourceId"] = null;
            }

            if (string.IsNullOrWhiteSpace(accession))
            {
                ShowSweetAlert("Input Required", "Accession Number is required.", "warning");
                txtAccession.Focus();
                return;
            }
            if (string.IsNullOrWhiteSpace(binding) || binding == "Choose option...")
            {
                ShowSweetAlert("Input Required", "Please select or enter a Binding Type.", "warning");
                return;
            }
            if (string.IsNullOrWhiteSpace(condition) || condition == "Choose option...")
            {
                ShowSweetAlert("Input Required", "Please select a Condition.", "warning");
                return;
            }
            if (string.IsNullOrWhiteSpace(campus))
            {
                ShowSweetAlert("Input Required",
                    "Please select an existing Campus or add a new one using the Add button.", "warning");
                return;
            }

            try
            {
                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    string checkAccSql = "SELECT COUNT(*) FROM Item_Copies WHERE accession_number = @acc";
                    using (MySqlCommand checkAccCmd = new MySqlCommand(checkAccSql, conn))
                    {
                        checkAccCmd.Parameters.AddWithValue("@acc", accession);
                        if (Convert.ToInt32(checkAccCmd.ExecuteScalar()) > 0)
                        {
                            ShowSweetAlert("Duplicate Accession", $"'{accession}' already assigned.", "error");
                            txtAccession.Text = "";
                            txtAccession.Focus();
                            return;
                        }
                    }

                    if (!forceUpdate && !isDifferentEdition &&
                        (!string.IsNullOrEmpty(isbn) || !string.IsNullOrEmpty(issn) || !string.IsNullOrEmpty(title)))
                    {
                        string checkConflictSql = @"SELECT isbn, issn, title FROM Library_Resources
                                                   WHERE (isbn = @isbn AND @isbn <> '')
                                                      OR (issn = @issn AND @issn <> '')
                                                      OR title = @title LIMIT 1";
                        using (var cmdConflict = new MySqlCommand(checkConflictSql, conn))
                        {
                            cmdConflict.Parameters.AddWithValue("@isbn", isbn);
                            cmdConflict.Parameters.AddWithValue("@issn", issn);
                            cmdConflict.Parameters.AddWithValue("@title", title);
                            using (var dr = cmdConflict.ExecuteReader())
                            {
                                if (dr.Read())
                                {
                                    string dbIsbn = dr["isbn"]?.ToString() ?? "";
                                    string dbIssn = dr["issn"]?.ToString() ?? "";
                                    string dbTitle = dr["title"]?.ToString() ?? "";
                                    bool idMatches = (isbn != "" && isbn == dbIsbn) || (issn != "" && issn == dbIssn);
                                    bool titleMatches = title.Equals(dbTitle, StringComparison.OrdinalIgnoreCase);
                                    if (idMatches != titleMatches)
                                    {
                                        string matchDetails = $"<b>MATCH FOUND IN DATABASE</b><br/>YOUR INPUT: Title={title}, ID={(string.IsNullOrEmpty(isbn) ? issn : isbn)}<br/>" +
                                                              $"RECORD FOUND: Title={dbTitle}, ID={(string.IsNullOrEmpty(dbIsbn) ? dbIssn : dbIsbn)}<br/>WHAT WOULD YOU LIKE TO DO?";
                                        ShowSweetAlert("Resource Mismatch", matchDetails, "info", true);
                                        return;
                                    }
                                }
                            }
                        }
                    }
                }

                hfForceUpdate.Value = "false";

                // Use the already-downloaded relative path.
                string savedCoverPath = DefaultCoverRelative;
                if (ViewState["FetchedCoverPath"] != null)
                {
                    string p = ViewState["FetchedCoverPath"].ToString();
                    if (!string.IsNullOrEmpty(p))
                        savedCoverPath = p.Replace("~/", "").TrimStart('/');
                }

                string finalDescription = !string.IsNullOrEmpty(txtDescription.Text.Trim())
                    ? txtDescription.Text.Trim() : "No description available.";

                using (var conn = new MySqlConnection(_connStr))
                {
                    conn.Open();
                    using (var trans = conn.BeginTransaction())
                    {
                        try
                        {
                            int? existingId = null;
                            if (forceUpdate && Session["ExistingResourceId"] != null)
                            {
                                existingId = (int)Session["ExistingResourceId"];
                                Session["ExistingResourceId"] = null;
                                Session["IsDifferentEdition"] = null;
                            }
                            else if (!isDifferentEdition)
                            {
                                existingId = FindExistingResourceId(isbn, issn, title, conn, trans);
                            }

                            int targetResourceId;
                            if (existingId.HasValue)
                            {
                                targetResourceId = existingId.Value;
                                const string sqlUpdate = @"UPDATE Library_Resources
                                   SET item_type=@item, isbn=@isbn, issn=@issn, call_number=@call, dewey_decimal=@dewey, genre=@genre,
                                       title=@title, author=@author, section=@sec, publisher=@pub, place_of_publication=@place,
                                       series=@series, edition=@edi, pub_year=@py, copyright_year=@cy, pages_numeric=@pg,
                                       height_cm=@h, width_cm=@w, accompanying_material=@acc_mat, description=@desc, cover_path=@cover
                                   WHERE resource_id=@rid";
                                using (var cmdUpd = new MySqlCommand(sqlUpdate, conn, trans))
                                {
                                    AddResourceParameters(cmdUpd);
                                    cmdUpd.Parameters.AddWithValue("@rid", targetResourceId);
                                    cmdUpd.Parameters.AddWithValue("@desc", finalDescription);
                                    cmdUpd.Parameters.AddWithValue("@cover", savedCoverPath);
                                    cmdUpd.ExecuteNonQuery();
                                }
                            }
                            else
                            {
                                const string sqlIns = @"INSERT INTO Library_Resources
                                      (item_type, isbn, issn, call_number, dewey_decimal, genre, title, author, section, publisher,
                                       place_of_publication, series, edition, pub_year, copyright_year, pages_numeric, height_cm,
                                       width_cm, accompanying_material, description, cover_path)
                                      VALUES (@item, @isbn, @issn, @call, @dewey, @genre, @title, @author, @sec, @pub, @place,
                                              @series, @edi, @py, @cy, @pg, @h, @w, @acc_mat, @desc, @cover);
                                      SELECT LAST_INSERT_ID();";
                                using (var cmdIns = new MySqlCommand(sqlIns, conn, trans))
                                {
                                    AddResourceParameters(cmdIns);
                                    cmdIns.Parameters.AddWithValue("@desc", finalDescription);
                                    cmdIns.Parameters.AddWithValue("@cover", savedCoverPath);
                                    targetResourceId = Convert.ToInt32(cmdIns.ExecuteScalar());
                                }
                            }

                            const string sqlCopy = @"INSERT INTO Item_Copies
                                    (accession_number, resource_id, volume_no, issue_no, binding_type, campus, specific_location, status_condition, remarks)
                                    VALUES (@acc, @rid, @vol, @issue, @bind, @campus, @location, @cond, @remarks)";
                            using (var cmdCopy = new MySqlCommand(sqlCopy, conn, trans))
                            {
                                cmdCopy.Parameters.AddWithValue("@acc", accession);
                                cmdCopy.Parameters.AddWithValue("@rid", targetResourceId);
                                cmdCopy.Parameters.AddWithValue("@vol", txtVolume.Text.Trim());
                                cmdCopy.Parameters.AddWithValue("@issue", txtIssue.Text.Trim());
                                cmdCopy.Parameters.AddWithValue("@bind", binding);
                                cmdCopy.Parameters.AddWithValue("@campus", campus);
                                cmdCopy.Parameters.AddWithValue("@location", specificLocation);
                                cmdCopy.Parameters.AddWithValue("@cond", condition);
                                cmdCopy.Parameters.AddWithValue("@remarks", remarks);
                                cmdCopy.ExecuteNonQuery();
                            }

                            trans.Commit();
                            Session["IsDifferentEdition"] = null;
                            Session["ExistingResourceId"] = null;

                            ClearFormFields();
                            ClientScript.RegisterStartupScript(GetType(), "saveSuccess",
                                "Swal.fire({ icon: 'success', title: 'Success', text: 'The book record has been saved successfully!', confirmButtonColor: '#14532d' });", true);
                        }
                        catch (Exception ex)
                        {
                            trans.Rollback();
                            System.Diagnostics.Debug.WriteLine("Save error: " + ex);
                            ShowSweetAlert("Database Error", "The record could not be saved. Please try again.", "error");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("BtnSave outer error: " + ex);
                ShowSweetAlert("Error", "An unexpected error occurred while saving the record.", "error");
            }
        }

        private int? FindExistingResourceId(string isbn, string issn, string title, MySqlConnection conn, MySqlTransaction trans)
        {
            string query = "SELECT resource_id FROM Library_Resources WHERE (isbn = @isbn AND @isbn <> '') OR (issn = @issn AND @issn <> '') OR title = @title LIMIT 1";
            using (var cmd = new MySqlCommand(query, conn, trans))
            {
                cmd.Parameters.AddWithValue("@isbn", isbn);
                cmd.Parameters.AddWithValue("@issn", issn);
                cmd.Parameters.AddWithValue("@title", title);
                object result = cmd.ExecuteScalar();
                return result != null ? (int?)Convert.ToInt32(result) : null;
            }
        }

        private void AddResourceParameters(MySqlCommand cmd)
        {
            int? pubYear = string.IsNullOrEmpty(txtPubYear.Text.Trim()) ? (int?)null : Convert.ToInt32(txtPubYear.Text.Trim());
            int? copyrightYear = string.IsNullOrEmpty(txtCopyright.Text.Trim()) ? (int?)null : Convert.ToInt32(txtCopyright.Text.Trim());
            decimal? height = string.IsNullOrEmpty(txtHeight.Text.Trim()) ? (decimal?)null : Convert.ToDecimal(txtHeight.Text.Trim());
            decimal? width = string.IsNullOrEmpty(txtWidth.Text.Trim()) ? (decimal?)null : Convert.ToDecimal(txtWidth.Text.Trim());

            cmd.Parameters.AddWithValue("@item", txtItemType.Text.Trim());
            cmd.Parameters.AddWithValue("@isbn", txtISBN.Text.Trim());
            cmd.Parameters.AddWithValue("@issn", txtISSN.Text.Trim());
            cmd.Parameters.AddWithValue("@call", txtCallNumber.Text.Trim());
            cmd.Parameters.AddWithValue("@dewey", txtDewey.Text.Trim());
            cmd.Parameters.AddWithValue("@genre", txtGenre.Text.Trim());
            cmd.Parameters.AddWithValue("@title", txtTitle.Text.Trim());
            cmd.Parameters.AddWithValue("@author", txtAuthors.Text.Trim());
            cmd.Parameters.AddWithValue("@sec", !string.IsNullOrEmpty(txtNewSection.Text) ? txtNewSection.Text.Trim() : (ddlSection.SelectedValue ?? ""));
            cmd.Parameters.AddWithValue("@pub", txtPublisher.Text.Trim());
            cmd.Parameters.AddWithValue("@place", txtPlace.Text.Trim());
            cmd.Parameters.AddWithValue("@series", txtSeries.Text.Trim());
            cmd.Parameters.AddWithValue("@edi", txtEdition.Text.Trim());
            cmd.Parameters.AddWithValue("@py", pubYear ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("@cy", copyrightYear ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("@pg", txtPages.Text.Trim());
            cmd.Parameters.AddWithValue("@h", height ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("@w", width ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("@acc_mat", txtMaterial.Text.Trim());
        }

        protected void BtnExit_Click(object sender, EventArgs e)
        {
            Response.Redirect("bookInventory.aspx");
        }

        // ====================================================================
        // CLEAR FORM
        // ====================================================================

        private void ClearFormFields()
        {
            txtAccession.Text = ""; txtItemType.Text = ""; txtGenre.Text = ""; txtCallNumber.Text = "";
            txtDewey.Text = ""; txtISBN.Text = ""; txtISSN.Text = ""; txtTitle.Text = "";
            txtAuthors.Text = ""; txtVolume.Text = ""; txtIssue.Text = ""; txtSeries.Text = "";
            txtNewSection.Text = ""; txtPublisher.Text = ""; txtPlace.Text = ""; txtEdition.Text = "";
            txtPubYear.Text = ""; txtCopyright.Text = ""; txtPages.Text = ""; txtHeight.Text = "";
            txtWidth.Text = ""; txtMaterial.Text = ""; txtDescription.Text = ""; txtNewBinding.Text = "";
            txtSpecificLocation.Text = ""; txtRemarks.Text = "";
            txtNewCampus.Text = "";

            if (ddlSection.Items.Count > 0) ddlSection.SelectedIndex = 0;
            if (ddlBinding.Items.Count > 0) ddlBinding.SelectedIndex = 0;
            if (ddlCondition.Items.Count > 0) ddlCondition.SelectedIndex = 0;

            // Campus default — safe even if "Malita Campus" isn't present
            SelectCampusValue("Malita Campus");
            if (string.IsNullOrEmpty(ddlCampus.SelectedValue) && ddlCampus.Items.Count > 0)
                ddlCampus.SelectedIndex = 0;

            hfForceUpdate.Value = "false";
            ViewState["FetchedCoverPath"] = null;
            imgCover.ImageUrl = DefaultCoverTilde;
        }

        // ====================================================================
        // SWEETALERT HELPERS
        // ====================================================================

        private void ShowSweetAlert(string title, string message, string icon, bool isMismatch = false)
        {
            string cleanTitle = (title ?? "").Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", "").Replace("\n", " ");
            string cleanMsg = (message ?? "").Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", "").Replace("\n", "\\n");
            string script = $"showSweetAlert('{cleanTitle}', '{cleanMsg}', '{icon}', {(isMismatch ? "true" : "false")});";
            ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString(), script, true);
        }

        private void ShowSweetAlertWithThreeOptions(string title, string message, string icon,
            string option1Text, string option2Text, string option3Text)
        {
            string cleanTitle = (title ?? "").Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", "").Replace("\n", " ");
            string cleanMessage = (message ?? "").Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", "").Replace("\n", "\\n");
            string script = $@"
                Swal.fire({{
                    title: '{cleanTitle}',
                    html: '{cleanMessage}',
                    icon: '{icon}',
                    showDenyButton: true,
                    showCancelButton: true,
                    confirmButtonText: '{option1Text}',
                    denyButtonText: '{option2Text}',
                    cancelButtonText: '{option3Text}',
                    confirmButtonColor: '#14532d',
                    denyButtonColor: '#d4a017',
                    cancelButtonColor: '#d33'
                }}).then((result) => {{
                    if (result.isConfirmed) {{
                        document.getElementById('{hfForceUpdate.ClientID}').value = 'false';
                        document.getElementById('{btnSave.ClientID}').click();
                    }} else if (result.isDenied) {{
                        document.getElementById('{hfForceUpdate.ClientID}').value = 'true';
                        document.getElementById('{btnSave.ClientID}').click();
                    }}
                }});
            ";
            ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString(), script, true);
        }
    }
}