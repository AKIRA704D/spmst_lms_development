<%@ Page Title="Batch Import Users" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="UserImports.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Import.UserImports" %>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container-fluid py-4">
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-body p-4">
                <h4 class="mb-3">Batch Import Users (Students, Faculty &amp; Staff)</h4>
                <p class="text-muted">
                    Upload a CSV file to bulk-add users. Each row creates one record in the matching
                    person table (<strong>Students</strong>, <strong>Faculty</strong>, or <strong>Staff</strong>)
                    and a linked account in <strong>Users</strong>.
                </p>

                <div id="alertPlaceholder" runat="server"></div>

                <div class="row g-3 align-items-end">
                    <div class="col-12 col-md-7 col-lg-8">
                        <label class="form-label fw-semibold small text-uppercase mb-1">Select CSV File</label>
                        <asp:FileUpload ID="fuCSVImport" runat="server" CssClass="form-control form-control-sm" accept=".csv" />
                        <small class="text-muted">
                            <i class="fas fa-info-circle"></i>
                            Required: <strong>user_id</strong>, <strong>email</strong>, <strong>role</strong>,
                            <strong>first_name</strong>, <strong>last_name</strong>.
                            Role must be one of <em>student, faculty, staff, admin</em>.
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
                                <asp:BoundField DataField="user_id" HeaderText="USER ID" />
                                <asp:BoundField DataField="email" HeaderText="EMAIL" />
                                <asp:BoundField DataField="name" HeaderText="NAME" />
                                <asp:BoundField DataField="role" HeaderText="ROLE" />
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
        'user_id', 'email', 'role', 'is_active',
        'first_name', 'middle_name', 'last_name', 'extension_name',
        'gender', 'mobile_number',
        'institute', 'course', 'section', 'year_level',
        'office_department', 'is_head_librarian',
        'address', 'profile_path'
    ];

    var sampleRows = [
        // Student row
        ['2024-0001', 'student@lmsa.edu.ph', 'student', '1',
            'Maria', 'Santos', 'Cruz', '',
            'Female', '09171234567',
            'College of ICT', 'BSIT', 'A', '2nd Year',
            '', '', 'Malita, Davao Occidental', ''],
        // Faculty row
        ['FAC-001', 'faculty@lmsa.edu.ph', 'faculty', '1',
            'Jose', 'Reyes', 'Santos', '',
            'Male', '09181234567',
            'College of ICT', '', '', '',
            '', '', 'Malita, Davao Occidental', ''],
        // Staff row
        ['STAFF-002', 'circulation@lmsa.edu.ph', 'staff', '1',
            'Jane', 'Doe', 'Reyes', '',
            'Female', '09191234567',
            '', '', '', '',
            'Circulation Area', '0', 'Malita, Davao Occidental', ''],
        // Admin row (stored under Staff)
        ['STAFF-003', 'admin@lmsa.edu.ph', 'admin', '1',
            'Head', '', 'Librarian', '',
            'Male', '09201234567',
            '', '', '', '',
            'Head Office', '1', 'Malita, Davao Occidental', '']
    ];

    var csvContent = headers.join(',') + '\n';
    sampleRows.forEach(function(row) {
        var quotedRow = row.map(function(field) {
            if (typeof field === 'string' && (field.indexOf(',') !== -1 || field.indexOf('"') !== -1)) {
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
    link.setAttribute('download', 'sample_user_import.csv');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
        }
    </script>
</asp:Content>