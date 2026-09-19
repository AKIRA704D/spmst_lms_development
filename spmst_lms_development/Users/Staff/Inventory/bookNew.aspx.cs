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
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["LmsDb"].ConnectionString;

        private class BookMetadata
        {
            public string title { get; set; } = "";
            public string author { get; set; } = "";
            public string publisher { get; set; } = "";
            public string publishDate { get; set; } = "";
            public string description { get; set; } = "No description available.";
            public string coverUrl { get; set; } = "";
            public string isbn { get; set; } = "";
            public string issn { get; set; } = "";
            public string deweyDecimal { get; set; } = "";
            public string pages { get; set; } = "";
            public string edition { get; set; } = "";
            public string language { get; set; } = "";
            public string source { get; set; } = "";
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadDynamicDropdowns();
                SetDefaultValues();
            }
        }

        private void SetDefaultValues()
        {
            if (ddlCampus.Items.Count > 0 && string.IsNullOrEmpty(ddlCampus.SelectedValue))
                ddlCampus.SelectedValue = "Malita Campus";
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

        private string CleanIdentifier(string identifier)
        {
            return string.IsNullOrEmpty(identifier) ? "" : Regex.Replace(identifier.Trim(), @"[-\s]", "");
        }

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

            using (MySqlConnection conn = new MySqlConnection(_connStr))
            {
                conn.Open();
                string query = @"SELECT resource_id, isbn, issn, title, author, edition, publisher, 
                                pub_year, dewey_decimal, cover_path, description
                         FROM Library_Resources 
                         WHERE (isbn = @isbnRaw OR isbn = @isbnClean OR isbn = @isbnCleanAlt)
                            OR (issn = @issnRaw OR issn = @issnClean)
                            OR (title = @title AND (author = @author OR @author = ''))
                         LIMIT 5";
                var cmd = new MySqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@isbnRaw", rawIsbn);
                cmd.Parameters.AddWithValue("@isbnClean", cleanIsbn);
                cmd.Parameters.AddWithValue("@isbnCleanAlt", cleanIsbn?.Replace("-", ""));
                cmd.Parameters.AddWithValue("@issnRaw", rawIssn);
                cmd.Parameters.AddWithValue("@issnClean", cleanIssn);
                cmd.Parameters.AddWithValue("@title", title);
                cmd.Parameters.AddWithValue("@author", author);

                var matches = new List<Dictionary<string, object>>();
                using (var dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        var match = new Dictionary<string, object>();
                        for (int i = 0; i < dr.FieldCount; i++)
                            match[dr.GetName(i)] = dr.GetValue(i);
                        matches.Add(match);
                    }
                }

                if (matches.Count > 0)
                {
                    var exactIsbnMatch = matches.FirstOrDefault(m =>
                        (m["isbn"]?.ToString() == rawIsbn || m["isbn"]?.ToString() == cleanIsbn) &&
                        !string.IsNullOrEmpty(cleanIsbn));
                    var exactIssnMatch = matches.FirstOrDefault(m =>
                        (m["issn"]?.ToString() == rawIssn || m["issn"]?.ToString() == cleanIssn) &&
                        !string.IsNullOrEmpty(cleanIssn));
                    var exactTitleAuthorMatch = matches.FirstOrDefault(m =>
                        m["title"]?.ToString() == title &&
                        (string.IsNullOrEmpty(author) || m["author"]?.ToString() == author));
                    var differentEditionMatches = matches.Where(m =>
                        m["title"]?.ToString() == title &&
                        m["author"]?.ToString() == author &&
                        m["isbn"]?.ToString() != cleanIsbn &&
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
                        string existingIsbn = existingMatch["isbn"]?.ToString() ?? "N/A";
                        string existingEdition = existingMatch["edition"]?.ToString() ?? "Unknown Edition";
                        string existingPublisher = existingMatch["publisher"]?.ToString() ?? "Unknown Publisher";
                        string existingYear = existingMatch["pub_year"]?.ToString() ?? "Unknown Year";
                        string message = $"<b>⚠️ DIFFERENT EDITION/FORMAT DETECTED</b><br/><br/>" +
                                        $"A book with the same title and author already exists but with a different ISBN.<br/><br/>" +
                                        $"<b>📚 EXISTING RECORD:</b><br/>" +
                                        $"• ISBN: {existingIsbn}<br/>• Edition: {existingEdition}<br/>• Publisher: {existingPublisher}<br/>• Year: {existingYear}<br/><br/>" +
                                        $"<b>📖 YOUR INPUT:</b><br/>• ISBN: {(string.IsNullOrEmpty(cleanIsbn) ? "Not provided" : cleanIsbn)}<br/><br/>" +
                                        $"<b>❓ WHAT WOULD YOU LIKE TO DO?</b><br/>" +
                                        $"• <b>Add as New Resource</b> - Create a separate record<br/>• <b>Update Existing</b> - Replace the existing record<br/>• <b>Cancel</b> - Review your input";
                        Session["ExistingResourceId"] = Convert.ToInt32(existingMatch["resource_id"]);
                        Session["IsDifferentEdition"] = true;
                        ShowSweetAlertWithThreeOptions("Different Edition Detected", message, "question",
                            "Add as New Resource", "Update Existing", "Cancel");
                        return;
                    }
                    else if (exactTitleAuthorMatch == null && matches.Any(m => m["title"]?.ToString() == title))
                    {
                        var titleMatch = matches.First(m => m["title"]?.ToString() == title);
                        string existingAuthor = titleMatch["author"]?.ToString() ?? "Unknown Author";
                        string existingIsbn = titleMatch["isbn"]?.ToString() ?? "N/A";
                        string message = $"<b>⚠️ TITLE CONFLICT DETECTED</b><br/><br/>" +
                                        $"A book with the same title but different author exists.<br/><br/>" +
                                        $"<b>EXISTING:</b> {title}<br/>Author: {existingAuthor}, ISBN: {existingIsbn}<br/>" +
                                        $"<b>YOUR INPUT:</b> Author: {(string.IsNullOrEmpty(author) ? "Not provided" : author)}<br/><br/>" +
                                        $"Please choose an action:";
                        Session["ExistingResourceId"] = Convert.ToInt32(titleMatch["resource_id"]);
                        ShowSweetAlertWithThreeOptions("Title Conflict", message, "warning",
                            "Add as New Book", "Use Existing Record", "Cancel");
                        return;
                    }
                }
            }

            ShowSweetAlert("Fetching Data", "No existing record found. Retrieving from external sources...", "info");
            FetchAndPopulateFromAPIs(cleanIsbn, cleanIssn);
        }

        private void FetchAndPopulateFromAPIs(string cleanIsbn, string cleanIssn)
        {
            var metadata = new BookMetadata();
            if (!string.IsNullOrEmpty(cleanIsbn))
            {
                metadata = GetMetadataFromGoogleBooks(cleanIsbn);
                if (string.IsNullOrEmpty(metadata.title))
                    metadata = GetMetadataFromOpenLibrary(cleanIsbn);
                if (string.IsNullOrEmpty(metadata.title))
                    metadata = GetMetadataFromCrossRef(cleanIsbn);
                if (!string.IsNullOrEmpty(metadata.title))
                    txtISBN.Text = metadata.isbn ?? cleanIsbn;
            }
            else if (!string.IsNullOrEmpty(cleanIssn))
            {
                metadata = GetMetadataFromCrossRef(cleanIssn);
                if (string.IsNullOrEmpty(metadata.title))
                    metadata = GetMetadataFromOpenLibraryByIssn(cleanIssn);
                if (!string.IsNullOrEmpty(metadata.title))
                    txtISSN.Text = metadata.issn ?? cleanIssn;
            }

            if (!string.IsNullOrEmpty(metadata.title))
            {
                PopulateFormFromMetadata(metadata);
                ShowSweetAlert($"Data Retrieved from {metadata.source}",
                    "Book/Journal details have been auto-populated.", "success");
            }
            else
            {
                ShowSweetAlert("No Record Found",
                    "No existing book found and unable to retrieve from external APIs. You can continue manually.", "info");
            }
        }

        #region API Methods (unchanged, but cover download uses local path)

        private BookMetadata GetMetadataFromGoogleBooks(string cleanIsbn)
        {
            var metadata = new BookMetadata { source = "Google Books" };
            try
            {
                string url = $"https://www.googleapis.com/books/v1/volumes?q=isbn:{cleanIsbn}";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    dynamic result = serializer.Deserialize<object>(json);
                    if (result["totalItems"] > 0)
                    {
                        var volumeInfo = result["items"][0]["volumeInfo"];
                        metadata.title = volumeInfo.ContainsKey("title") ? volumeInfo["title"] : "";
                        metadata.author = volumeInfo.ContainsKey("authors") ? string.Join(", ", volumeInfo["authors"]) : "";
                        metadata.publisher = volumeInfo.ContainsKey("publisher") ? volumeInfo["publisher"] : "";
                        metadata.publishDate = volumeInfo.ContainsKey("publishedDate") ? volumeInfo["publishedDate"] : "";
                        metadata.description = volumeInfo.ContainsKey("description") ? volumeInfo["description"] : "No description.";
                        metadata.pages = volumeInfo.ContainsKey("pageCount") ? volumeInfo["pageCount"].ToString() : "";
                        metadata.isbn = cleanIsbn;
                        if (volumeInfo.ContainsKey("categories") && volumeInfo["categories"].Count > 0)
                            metadata.deweyDecimal = ExtractDeweyFromCategories(volumeInfo["categories"][0].ToString());
                        if (volumeInfo.ContainsKey("imageLinks"))
                        {
                            var links = volumeInfo["imageLinks"];
                            metadata.coverUrl = links.ContainsKey("thumbnail") ? links["thumbnail"] :
                                               (links.ContainsKey("smallThumbnail") ? links["smallThumbnail"] : "");
                            metadata.coverUrl = metadata.coverUrl?.Replace("http://", "https://");
                        }
                    }
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"Google Books error: {ex.Message}"); }
            return metadata;
        }

        private BookMetadata GetMetadataFromOpenLibrary(string cleanIsbn)
        {
            var metadata = new BookMetadata { source = "OpenLibrary" };
            try
            {
                string url = $"https://openlibrary.org/api/books?bibkeys=ISBN:{cleanIsbn}&format=json&jscmd=data";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    dynamic result = serializer.Deserialize<object>(json);
                    string key = $"ISBN:{cleanIsbn}";
                    if (result[key] != null)
                    {
                        var bookData = result[key];
                        metadata.title = bookData.ContainsKey("title") ? bookData["title"] : "";
                        metadata.isbn = cleanIsbn;
                        if (bookData.ContainsKey("authors") && bookData["authors"].Count > 0)
                        {
                            var authors = new List<string>();
                            foreach (var author in bookData["authors"])
                                authors.Add(author.ContainsKey("name") ? author["name"] : "");
                            metadata.author = string.Join(", ", authors);
                        }
                        if (bookData.ContainsKey("publishers") && bookData["publishers"].Count > 0)
                            metadata.publisher = bookData["publishers"][0].ContainsKey("name") ? bookData["publishers"][0]["name"] : "";
                        if (bookData.ContainsKey("publish_date")) metadata.publishDate = bookData["publish_date"];
                        if (bookData.ContainsKey("description"))
                            metadata.description = bookData["description"] is string ? bookData["description"] : (bookData["description"].ContainsKey("value") ? bookData["description"]["value"] : "");
                        if (bookData.ContainsKey("number_of_pages")) metadata.pages = bookData["number_of_pages"].ToString();
                        if (bookData.ContainsKey("classifications") && bookData["classifications"].ContainsKey("dewey_decimal_class") && bookData["classifications"]["dewey_decimal_class"].Count > 0)
                            metadata.deweyDecimal = bookData["classifications"]["dewey_decimal_class"][0];
                        if (bookData.ContainsKey("cover") && bookData["cover"].ContainsKey("large"))
                            metadata.coverUrl = "https:" + bookData["cover"]["large"];
                        else if (bookData.ContainsKey("cover") && bookData["cover"].ContainsKey("medium"))
                            metadata.coverUrl = "https:" + bookData["cover"]["medium"];
                    }
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"OpenLibrary error: {ex.Message}"); }
            return metadata;
        }

        private BookMetadata GetMetadataFromOpenLibraryByIssn(string issn)
        {
            var metadata = new BookMetadata { source = "OpenLibrary" };
            try
            {
                string cleanIssn = issn.Replace("-", "").Trim();
                string url = $"https://openlibrary.org/search.json?q=issn:{cleanIssn}&limit=1";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    dynamic result = serializer.Deserialize<object>(json);
                    if (result["docs"] != null && result["docs"].Count > 0)
                    {
                        var doc = result["docs"][0];
                        metadata.title = doc.ContainsKey("title") ? doc["title"] : "";
                        metadata.author = doc.ContainsKey("author_name") ? string.Join(", ", doc["author_name"]) : "";
                        metadata.publisher = doc.ContainsKey("publisher") ? string.Join(", ", doc["publisher"]) : "";
                        metadata.publishDate = doc.ContainsKey("first_publish_year") ? doc["first_publish_year"].ToString() : "";
                        metadata.issn = issn;
                        if (doc.ContainsKey("cover_i") && doc["cover_i"] != null)
                            metadata.coverUrl = $"https://covers.openlibrary.org/b/id/{doc["cover_i"]}-L.jpg";
                    }
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"OpenLibrary ISSN error: {ex.Message}"); }
            return metadata;
        }

        private BookMetadata GetMetadataFromCrossRef(string cleanIdentifier)
        {
            var metadata = new BookMetadata { source = "CrossRef" };
            try
            {
                string url = $"https://api.crossref.org/works/{cleanIdentifier}";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    client.Headers.Add("Accept", "application/json");
                    string json = client.DownloadString(url);
                    var serializer = new JavaScriptSerializer();
                    dynamic result = serializer.Deserialize<object>(json);
                    if (result["status"] == "ok" && result["message"] != null)
                    {
                        var message = result["message"];
                        metadata.title = message.ContainsKey("title") && message["title"].Count > 0 ? message["title"][0] : "";
                        if (message.ContainsKey("author") && message["author"].Count > 0)
                        {
                            var authors = new List<string>();
                            foreach (var author in message["author"])
                            {
                                string authorName = "";
                                if (author.ContainsKey("given") && author.ContainsKey("family"))
                                    authorName = $"{author["given"]} {author["family"]}";
                                else if (author.ContainsKey("family"))
                                    authorName = author["family"];
                                authors.Add(authorName);
                            }
                            metadata.author = string.Join(", ", authors);
                        }
                        if (message.ContainsKey("publisher")) metadata.publisher = message["publisher"];
                        if (message.ContainsKey("issued") && message["issued"].ContainsKey("date-parts") && message["issued"]["date-parts"].Count > 0)
                        {
                            var dateParts = message["issued"]["date-parts"][0];
                            if (dateParts.Count > 0) metadata.publishDate = dateParts[0].ToString();
                        }
                        if (message.ContainsKey("abstract"))
                        {
                            string abstractText = message["abstract"].ToString();
                            metadata.description = Regex.Replace(abstractText, "<.*?>", string.Empty);
                            if (metadata.description.Length > 500) metadata.description = metadata.description.Substring(0, 500) + "...";
                        }
                        if (message.ContainsKey("page")) metadata.pages = message["page"];
                        if (message.ContainsKey("ISSN") && message["ISSN"].Count > 0) metadata.issn = message["ISSN"][0];
                        if (message.ContainsKey("ISBN") && message["ISBN"].Count > 0) metadata.isbn = message["ISBN"][0];
                    }
                }
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"CrossRef error: {ex.Message}"); }
            return metadata;
        }

        private string ExtractDeweyFromCategories(string category)
        {
            var match = Regex.Match(category, @"\b(\d{3}(?:\.\d+)?)\b");
            return match.Success ? match.Groups[1].Value : "";
        }

        private void PopulateFormFromDictionary(Dictionary<string, object> record)
        {
            txtItemType.Text = record["item_type"]?.ToString() ?? "";
            txtGenre.Text = record["genre"]?.ToString() ?? "";
            txtCallNumber.Text = record["call_number"]?.ToString() ?? "";
            txtDewey.Text = record["dewey_decimal"]?.ToString() ?? "";
            txtTitle.Text = record["title"]?.ToString() ?? "";
            txtAuthors.Text = record["author"]?.ToString() ?? "";
            txtPublisher.Text = record["publisher"]?.ToString() ?? "";
            txtPlace.Text = record["place_of_publication"]?.ToString() ?? "";
            txtSeries.Text = record["series"]?.ToString() ?? "";
            txtEdition.Text = record["edition"]?.ToString() ?? "";
            txtPubYear.Text = record["pub_year"]?.ToString() ?? "";
            txtCopyright.Text = record["copyright_year"]?.ToString() ?? "";
            txtPages.Text = record["pages_numeric"]?.ToString() ?? "";
            txtHeight.Text = record["height_cm"]?.ToString() ?? "";
            txtWidth.Text = record["width_cm"]?.ToString() ?? "";
            txtMaterial.Text = record["accompanying_material"]?.ToString() ?? "";
            txtDescription.Text = record["description"]?.ToString() ?? "";
            txtAccession.Text = "";
            txtAccession.Focus();
        }

        private void PopulateFormFromMetadata(BookMetadata metadata)
        {
            if (!string.IsNullOrEmpty(metadata.title)) txtTitle.Text = metadata.title;
            if (!string.IsNullOrEmpty(metadata.author)) txtAuthors.Text = metadata.author;
            if (!string.IsNullOrEmpty(metadata.publisher)) txtPublisher.Text = metadata.publisher;
            if (!string.IsNullOrEmpty(metadata.publishDate))
            {
                var yearMatch = Regex.Match(metadata.publishDate, @"\d{4}");
                txtPubYear.Text = yearMatch.Success ? yearMatch.Value : metadata.publishDate;
            }
            if (!string.IsNullOrEmpty(metadata.description)) txtDescription.Text = metadata.description;
            if (!string.IsNullOrEmpty(metadata.pages)) txtPages.Text = metadata.pages;
            if (!string.IsNullOrEmpty(metadata.deweyDecimal)) txtDewey.Text = metadata.deweyDecimal;
            if (!string.IsNullOrEmpty(metadata.coverUrl))
            {
                string coverPath = DownloadAndSaveCover(metadata.coverUrl,
                    !string.IsNullOrEmpty(metadata.isbn) ? metadata.isbn : txtISBN.Text,
                    txtISSN.Text);
                ViewState["FetchedCoverUrl"] = coverPath;
            }
            txtAccession.Focus();
        }

        private string DownloadAndSaveCover(string url, string isbn, string issn)
        {
            if (string.IsNullOrEmpty(url)) return "Assets/Covers/default-cover.jpg";
            try
            {
                string folderPath = Server.MapPath("~/Assets/Covers/");
                if (!Directory.Exists(folderPath)) Directory.CreateDirectory(folderPath);
                string identifier = !string.IsNullOrWhiteSpace(isbn) ? isbn.Trim() : issn.Trim();
                if (string.IsNullOrEmpty(identifier)) return "Assets/Covers/default-cover.jpg";
                foreach (char c in Path.GetInvalidFileNameChars()) identifier = identifier.Replace(c.ToString(), "");
                string fileName = $"{identifier}.jpg";
                string fullPath = Path.Combine(folderPath, fileName);
                if (File.Exists(fullPath)) return $"Assets/Covers/{fileName}";
                using (WebClient client = new WebClient())
                {
                    client.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
                    client.DownloadFile(url.Replace("http://", "https://"), fullPath);
                }
                return $"Assets/Covers/{fileName}";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Cover download error: {ex.Message}");
                return "Assets/Covers/default-cover.jpg";
            }
        }
        #endregion

        protected void BtnSave_Click(object sender, EventArgs e)
        {
            string accession = txtAccession.Text.Trim().ToUpper();
            txtAccession.Text = accession;
            string binding = !string.IsNullOrEmpty(txtNewBinding.Text) ? txtNewBinding.Text.Trim() : ddlBinding.SelectedValue;
            string condition = ddlCondition.SelectedValue;
            string campus = ddlCampus.SelectedValue;
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

                if (!forceUpdate && !isDifferentEdition && (!string.IsNullOrEmpty(isbn) || !string.IsNullOrEmpty(issn) || !string.IsNullOrEmpty(title)))
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
                                string dbIsbn = dr["isbn"].ToString();
                                string dbIssn = dr["issn"].ToString();
                                string dbTitle = dr["title"].ToString();
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
            string savedCoverPath = "Assets/Covers/default-cover.jpg";
            if (ViewState["FetchedCoverUrl"] != null)
                savedCoverPath = DownloadAndSaveCover(ViewState["FetchedCoverUrl"].ToString(), txtISBN.Text, txtISSN.Text);
            string finalDescription = !string.IsNullOrEmpty(txtDescription.Text.Trim()) ? txtDescription.Text.Trim() : "No description available.";

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
                        ScriptManager.RegisterStartupScript(this, GetType(), "saveSuccess",
                            "Swal.fire({ icon: 'success', title: 'Success', text: 'The book record has been saved successfully!', confirmButtonColor: '#002447' });", true);
                    }
                    catch (Exception ex)
                    {
                        trans.Rollback();
                        ShowSweetAlert("Database Error", ex.Message, "error");
                    }
                }
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

        private void ClearFormFields()
        {
            txtAccession.Text = "";
            txtItemType.Text = "";
            txtGenre.Text = "";
            txtCallNumber.Text = "";
            txtDewey.Text = "";
            txtISBN.Text = "";
            txtISSN.Text = "";
            txtTitle.Text = "";
            txtAuthors.Text = "";
            txtVolume.Text = "";
            txtIssue.Text = "";
            txtSeries.Text = "";
            txtNewSection.Text = "";
            txtPublisher.Text = "";
            txtPlace.Text = "";
            txtEdition.Text = "";
            txtPubYear.Text = "";
            txtCopyright.Text = "";
            txtPages.Text = "";
            txtHeight.Text = "";
            txtWidth.Text = "";
            txtMaterial.Text = "";
            txtDescription.Text = "";
            txtNewBinding.Text = "";
            txtSpecificLocation.Text = "";
            txtRemarks.Text = "";
            if (ddlSection.Items.Count > 0) ddlSection.SelectedIndex = 0;
            if (ddlBinding.Items.Count > 0) ddlBinding.SelectedIndex = 0;
            if (ddlCondition.Items.Count > 0) ddlCondition.SelectedIndex = 0;
            if (ddlCampus.Items.Count > 0) ddlCampus.SelectedValue = "Malita Campus";
            hfForceUpdate.Value = "false";
            ViewState["FetchedCoverUrl"] = null;
        }

        private void ShowSweetAlert(string title, string message, string icon, bool isMismatch = false)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMsg = message.Replace("'", "\\'");
            string script = $"showSweetAlert('{cleanTitle}', '{cleanMsg}', '{icon}', {isMismatch.ToString().ToLower()});";
            ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString(), script, true);
        }

        private void ShowSweetAlertWithThreeOptions(string title, string message, string icon,
            string option1Text, string option2Text, string option3Text)
        {
            string cleanTitle = title.Replace("'", "\\'");
            string cleanMessage = message.Replace("'", "\\'");
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
                    confirmButtonColor: '#3085d6',
                    denyButtonColor: '#28a745',
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