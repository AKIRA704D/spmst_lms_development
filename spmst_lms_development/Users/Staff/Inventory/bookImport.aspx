<%@ Page Title="Batch Import" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="bookImport.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Inventory.bookImport" %>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        /* Long accession codes: never truncated, wrap inside the cell,
           monospace for readability, full value available via tooltip. */
        .code-cell {
            display: inline-block;
            max-width: 260px;
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            font-size: 0.82rem;
            word-break: break-all;
            white-space: normal;
            line-height: 1.15;
        }
        .results-table td { vertical-align: middle; }
    </style>

    <div class="container-fluid py-4">
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-body p-4">
                <h4 class="mb-3">Batch Import Resources &amp; Copies</h4>
                <p class="text-muted mb-2">
                    Upload a CSV file to bulk add resources and their copies. Each row is <strong>one physical copy</strong>.
                    Rows that share the same <code>resource_key</code> (or, if that column is blank, the same
                    <code>isbn</code> / <code>issn</code> / <code>title + author + edition + pub_year</code>)
                    are automatically merged into a <strong>single resource record with multiple copies</strong>.
                </p>
                <p class="text-muted small mb-4">
                    <i class="fas fa-lightbulb text-warning"></i>
                    You only need to fill the bibliographic columns on the <em>first</em> row of a group — blank
                    bibliographic cells on the following rows are inherited from the group.
                    If a row's <strong>barcode</strong> is left blank, the importer will generate one from the
                    <code>resource_key</code> (e.g. <code>BK-001-0004</code>) and check the database for the next
                    available number.
                </p>

                <div id="alertPlaceholder" runat="server"></div>

                <div class="row g-3 align-items-end">
                    <div class="col-12 col-md-7 col-lg-8">
                        <label class="form-label fw-semibold small text-uppercase mb-1">Select CSV File</label>
                        <asp:FileUpload ID="fuCSVImport" runat="server" CssClass="form-control form-control-sm" accept=".csv" />
                        <small class="text-muted">
                            <i class="fas fa-info-circle"></i> Required: <strong>Title</strong> (resource).
                            <strong>Barcode</strong> (accession_number) is optional and auto-generated if blank.
                            &nbsp;–&nbsp;
                            <a href="#" onclick="downloadSampleCSV(); return false;" class="text-primary">
                                <i class="fas fa-download"></i> Download Sample CSV (multi-copy)
                            </a>
                        </small>
                    </div>
                    <div class="col-12 col-md-5 col-lg-4">
                        <asp:Button ID="btnImport" runat="server" Text="Start Import" OnClick="btnImport_Click" CssClass="btn btn-primary btn-sm px-4" />
                    </div>
                </div>
            </div>
        </div>

        <asp:Panel ID="pnlResults" runat="server" Visible="false">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white py-3 border-0 border-bottom d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <h6 class="mb-0 fw-bold text-success">
                        <i class="fas fa-check-circle me-2"></i>Import Results
                    </h6>

                    <div class="d-flex align-items-center gap-3">
                        <asp:Label ID="lblImportSummary" runat="server" CssClass="fw-semibold small" />
                        <div class="progress" style="width: 160px; height: 8px;">
                            <asp:Literal ID="litProgressBar" runat="server" />
                        </div>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive" style="max-height: 450px; overflow-y: auto;">
                        <asp:GridView ID="gvResults" runat="server" AutoGenerateColumns="false"
                            CssClass="table table-hover align-middle mb-0 results-table" GridLines="None"
                            EmptyDataText="No rows were processed.">
                            <HeaderStyle CssClass="text-uppercase small text-muted" />
                            <Columns>
                                <asp:TemplateField HeaderText="ACCESSION / BARCODE">
                                    <ItemTemplate>
                                        <span class="code-cell" title='<%# System.Web.HttpUtility.HtmlAttributeEncode(Convert.ToString(Eval("barcode"))) %>'>
                                            <%# System.Web.HttpUtility.HtmlEncode(Convert.ToString(Eval("barcode"))) %>
                                        </span>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:BoundField DataField="resource"    HeaderText="RESOURCE ID" />
                                <asp:BoundField DataField="title"       HeaderText="TITLE" />
                                <asp:BoundField DataField="author"      HeaderText="AUTHOR" />
                                <asp:BoundField DataField="item_type"   HeaderText="TYPE" />
                                <asp:BoundField DataField="call_number" HeaderText="CALL NO." />
                                <asp:TemplateField HeaderText="STATUS">
                                    <ItemTemplate>
                                        <span class='badge <%# GetStatusBadgeClass(Eval("status").ToString()) %>'>
                                            <%# Eval("status") %>
                                        </span>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </asp:Panel>
    </div>

    <script>
        document.getElementById('<%= btnImport.ClientID %>').addEventListener('click', function (e) {
            var fileInput = document.getElementById('<%= fuCSVImport.ClientID %>');
            if (!fileInput.files || fileInput.files.length === 0) {
                Swal.fire({
                    icon: 'warning',
                    title: 'No File Selected',
                    text: 'Please select a CSV file to import.',
                    confirmButtonColor: '#002447'
                });
                e.preventDefault();
                return false;
            }
        });

        function downloadSampleCSV() {
            var headers = [
                'resource_key', 'item_type', 'isbn', 'issn', 'call_number', 'dewey_decimal', 'genre',
                'title', 'author', 'section', 'publisher', 'place_of_publication',
                'series', 'edition', 'pub_year', 'copyright_year', 'pages_numeric',
                'height_cm', 'width_cm', 'accompanying_material', 'description',
                'cover_path', 'barcode', 'volume_no', 'issue_no', 'binding_type',
                'campus', 'specific_location', 'status_condition', 'is_available', 'remarks'
            ];

            function row(obj) {
                return headers.map(function (h) {
                    return obj[h] !== undefined && obj[h] !== null ? obj[h] : '';
                });
            }

            var sampleRows = [
                // Resource 1 -- one book, three copies (bibliographic data only on row 1)
                row({
                    resource_key: 'BK-001', item_type: 'Book', isbn: '978-0131103627',
                    call_number: 'QA76.73.C15', dewey_decimal: '005.133', genre: 'Computer Science',
                    title: 'The C Programming Language',
                    author: 'Brian W. Kernighan; Dennis M. Ritchie',
                    section: 'Circulation', publisher: 'Prentice Hall', place_of_publication: 'USA',
                    edition: '2nd', pub_year: 1988, copyright_year: 1988, pages_numeric: '272',
                    height_cm: 23.5, width_cm: 18.0,
                    description: 'Classic C reference', cover_path: 'cover_c.jpg',
                    barcode: 'C-0001', binding_type: 'Hardcover',
                    campus: 'Malita Campus', specific_location: 'Circulation Desk',
                    status_condition: 'Good', is_available: 1
                }),
                row({
                    resource_key: 'BK-001', title: 'The C Programming Language',
                    barcode: 'C-0002', binding_type: 'Paperback',
                    campus: 'Main Campus', specific_location: 'Circulation Desk',
                    status_condition: 'Good', is_available: 1, remarks: 'Second copy'
                }),
                row({
                    resource_key: 'BK-001', title: 'The C Programming Language',
                    barcode: 'C-0003', binding_type: 'Hardcover',
                    campus: 'Malita Campus', specific_location: 'Faculty Room',
                    status_condition: 'Damage', is_available: 0, remarks: 'Damaged spine'
                }),

                // Resource 2 -- a journal, two issues
                row({
                    resource_key: 'JR-001', item_type: 'Journal', issn: '1234-5678',
                    call_number: 'PER-001', genre: 'Science',
                    title: 'Nature Reviews Physics', author: 'Various',
                    section: 'Periodicals', publisher: 'Nature Publishing Group',
                    place_of_publication: 'UK', pub_year: 2024, copyright_year: 2024,
                    pages_numeric: '50-60', height_cm: 28.0, width_cm: 21.0,
                    description: 'Monthly journal', cover_path: 'cover_n.jpg',
                    barcode: 'N-0001', volume_no: '5', issue_no: '1', binding_type: 'Paperback',
                    campus: 'Malita Campus', specific_location: 'Periodical Section',
                    status_condition: 'Good', is_available: 1, remarks: 'Latest issue'
                }),
                row({
                    resource_key: 'JR-001', title: 'Nature Reviews Physics',
                    barcode: 'N-0002', volume_no: '5', issue_no: '2', binding_type: 'Paperback',
                    campus: 'Malita Campus', specific_location: 'Periodical Section',
                    status_condition: 'Good', is_available: 1
                }),

                // Resource 3 -- a DVD, two copies
                row({
                    resource_key: 'AV-001', item_type: 'DVD',
                    call_number: 'DVD-001', genre: 'Educational',
                    title: 'Introduction to Astrophysics', author: 'Neil deGrasse Tyson',
                    section: 'AV Section', publisher: 'NASA', place_of_publication: 'USA',
                    pub_year: 2020, copyright_year: 2020, pages_numeric: '120',
                    height_cm: 19.0, width_cm: 13.5,
                    description: 'Educational DVD', cover_path: 'cover_d.jpg',
                    barcode: 'D-0001', binding_type: 'Plastic Case',
                    campus: 'Malita Campus', specific_location: 'AV Room',
                    status_condition: 'Good', is_available: 1, remarks: 'Includes booklet'
                }),
                row({
                    resource_key: 'AV-001', title: 'Introduction to Astrophysics',
                    barcode: 'D-0002', binding_type: 'Plastic Case',
                    campus: 'Malita Campus', specific_location: 'AV Room',
                    status_condition: 'Good', is_available: 1
                })
            ];

            var csvContent = headers.join(',') + '\n';
            sampleRows.forEach(function (r) {
                var quotedRow = r.map(function (field) {
                    if (typeof field === 'string' && (field.includes(',') || field.includes('"'))) {
                        return '"' + field.replace(/"/g, '""') + '"';
                    }
                    return field;
                });
                csvContent += quotedRow.join(',') + '\n';
            });

            var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            var link = document.createElement('a');
            var url = URL.createObjectURL(blob);
            link.href = url;
            link.setAttribute('download', 'sample_library_import.csv');
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    </script>
</asp:Content>