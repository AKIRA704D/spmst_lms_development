<%@ Page Title="Batch Import" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="bookImport.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Inventory.bookImport" %>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container-fluid py-4">
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-body p-4">
                <h4 class="mb-3">Batch Import Resources &amp; Copies</h4>
                <p class="text-muted">Upload a CSV file to bulk add resources and their copies. All columns from the database are supported.</p>

                <div id="alertPlaceholder" runat="server"></div>

                <div class="row g-3 align-items-end">
                    <div class="col-12 col-md-7 col-lg-8">
                        <label class="form-label fw-semibold small text-uppercase mb-1">Select CSV File</label>
                        <asp:FileUpload ID="fuCSVImport" runat="server" CssClass="form-control form-control-sm" accept=".csv" />
                        <small class="text-muted">
                            <i class="fas fa-info-circle"></i> Required: <strong>Title</strong> (resource) and <strong>Barcode</strong> (accession_number).
                            All other fields are optional.
                            &nbsp;–&nbsp;
                            <a href="#" onclick="downloadSampleCSV(); return false;" class="text-primary">
                                <i class="fas fa-download"></i> Download Sample CSV
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
                        <asp:Label ID="lblImportSummary" runat="server" CssClass="fw-semibold" />
                        <div class="progress" style="width: 160px; height: 8px;">
                            <asp:Literal ID="litProgressBar" runat="server" />
                        </div>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive" style="max-height: 450px; overflow-y: auto;">
                        <asp:GridView ID="gvResults" runat="server" AutoGenerateColumns="false"
                            CssClass="table table-hover align-middle mb-0" GridLines="None"
                            EmptyDataText="No rows were processed.">
                            <HeaderStyle CssClass="text-uppercase small text-muted" />
                            <Columns>
                                <asp:BoundField DataField="barcode" HeaderText="BARCODE" />
                                <asp:BoundField DataField="title" HeaderText="TITLE" />
                                <asp:BoundField DataField="author" HeaderText="AUTHOR" />
                                <asp:BoundField DataField="item_type" HeaderText="TYPE" />
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
        document.getElementById('<%= btnImport.ClientID %>').addEventListener('click', function(e) {
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
                'item_type', 'isbn', 'issn', 'call_number', 'dewey_decimal', 'genre',
                'title', 'author', 'section', 'publisher', 'place_of_publication',
                'series', 'edition', 'pub_year', 'copyright_year', 'pages_numeric',
                'height_cm', 'width_cm', 'accompanying_material', 'description',
                'cover_path', 'barcode', 'volume_no', 'issue_no', 'binding_type',
                'campus', 'specific_location', 'status_condition', 'is_available', 'remarks'
            ];

            var sampleRows = [
                ['Book', '978-3-16-148410-0', '', 'QA76.73.C15', '005.133', 'Computer Science',
                    'C Programming Language', 'Brian W. Kernighan, Dennis M. Ritchie', 'Circulation', 'Prentice Hall', 'USA',
                    '', '2nd', 1988, 1988, '272', 23.5, 18.0, 'CD-ROM', 'Classic programming text',
                    'cover_c.jpg', 'C001', '1', '', 'Hardcover', 'Main Campus', 'Circulation Desk', 'Good', '1', ''],
                ['Journal', '', '1234-5678', 'PER001', '', 'Science',
                    'Nature Reviews Physics', 'Various', 'Periodicals', 'Nature Publishing Group', 'UK',
                    '', '', 2024, 2024, '50-60', 28.0, 21.0, '', 'Monthly journal',
                    'cover_n.jpg', 'N001', '5', '1', 'Paperback', 'Malita Campus', 'Periodical Section', 'Good', '1', 'Latest issue'],
                ['DVD', '', '', 'DVD001', '', 'Educational',
                    'Introduction to Astrophysics', 'Dr. Neil deGrasse Tyson', 'AV Section', 'NASA', 'USA',
                    '', '', 2020, 2020, '120', 19.0, 13.5, '', 'Educational DVD',
                    'cover_d.jpg', 'D001', '', '', 'Plastic Case', 'Main Campus', 'AV Room', 'Good', '1', 'Includes booklet']
            ];

            var csvContent = headers.join(',') + '\n';
            sampleRows.forEach(row => {
                var quotedRow = row.map(field => {
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
