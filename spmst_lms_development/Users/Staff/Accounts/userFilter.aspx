<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="userFilter.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userFilter" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Filter Patrons</title>
    <!-- Bootstrap 5 CSS + Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
     <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>

    <style>
        body {
            background: white;
            overflow: hidden;
        }
        .filter-header {
            background-color: #002447;
            color: white;
        }
        .form-label {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #495057;
            margin-bottom: 0.25rem;
        }
        .form-select, .form-control {
            border-radius: 0.5rem;
            font-size: 0.85rem;
            border: 1px solid #ced4da;
        }
        .form-select:focus, .form-control:focus {
            border-color: #ffc107;
            box-shadow: 0 0 0 0.2rem rgba(255,193,7,0.25);
        }
        .btn-custom-primary {
            background-color: #002447;
            border: none;
            text-transform: uppercase;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        .btn-custom-primary:hover {
            background-color: #001a33;
        }
        .section-title {
            font-size: 0.7rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #0d6efd;
            border-bottom: 1px solid #dee2e6;
            padding-bottom: 0.5rem;
            margin-bottom: 1rem;
        }
        .reset-link {
            color: #dc3545;
            text-decoration: none;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        .reset-link:hover {
            text-decoration: underline;
        }
    </style>
    <script>
        function resetFilters() {
            // Reload parent page without any filter parameters
            window.parent.location.href = 'userAcc.aspx';
        }
    </script>
</head>
<body>
    <form id="form1" runat="server" class="h-100 d-flex flex-column">
        <asp:ScriptManager ID="ScriptManager1" runat="server" />

        <!-- Header with Close Button -->
        <div class="filter-header px-4 py-3 d-flex justify-content-between align-items-center flex-shrink-0">
            <div>
                <h5 class="mb-0 fw-bold text-uppercase">Filter Patrons</h5>
                <small class="text-secondary text-uppercase" style="font-size: 0.65rem;">Refine results by user details</small>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="window.parent.closeUniversalModal()" aria-label="Close"></button>
        </div>

        <!-- Filter Body (UpdatePanel for dynamic dropdowns) -->
        <asp:UpdatePanel ID="upFilterBody" runat="server" UpdateMode="Conditional" CssClass="flex-grow-1 d-flex flex-column">
            <ContentTemplate>
                <div class="p-4 flex-grow-1 overflow-auto">
                    <div class="section-title">Selection Criteria</div>

                    <!-- Patron Type -->
                    <div class="mb-3">
                        <label class="form-label">Patron Type</label>
                        <asp:DropDownList ID="ddlRole" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlRole_SelectedIndexChanged" CssClass="form-select">
                            <asp:ListItem Text="All Patrons" Value="All" />
                            <asp:ListItem Text="Student" Value="Student" />
                            <asp:ListItem Text="Faculty" Value="Faculty" />
                        </asp:DropDownList>
                    </div>

                    <!-- Institute -->
                    <div class="mb-3">
                        <label class="form-label">Institute</label>
                        <asp:DropDownList ID="ddlInstitute" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlInstitute_SelectedIndexChanged" CssClass="form-select" />
                    </div>

                    <!-- Program (visible only for Student) -->
                    <div id="divProgram" runat="server" visible="false" class="mb-3">
                        <label class="form-label">Program / Course</label>
                        <asp:DropDownList ID="ddlProgram" runat="server" CssClass="form-select" />
                    </div>

                    <!-- Year Level (visible only for Student) -->
                    <div id="divYear" runat="server" visible="false" class="mb-3">
                        <label class="form-label">Year Level</label>
                        <asp:DropDownList ID="ddlYear" runat="server" CssClass="form-select">
                            <asp:ListItem Text="All Levels" Value="" />
                            <asp:ListItem Text="1st Year" Value="1st Year" />
                            <asp:ListItem Text="2nd Year" Value="2nd Year" />
                            <asp:ListItem Text="3rd Year" Value="3rd Year" />
                            <asp:ListItem Text="4th Year" Value="4th Year" />
                        </asp:DropDownList>
                    </div>

                    <!-- Account Status -->
                    <div class="mb-3">
                        <label class="form-label">Account Status</label>
                        <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select">
                            <asp:ListItem Text="All Status" Value="" />
                            <asp:ListItem Text="Active" Value="1" />
                            <asp:ListItem Text="Deactivated" Value="2" />
                            <asp:ListItem Text="Pending" Value="0" />
                        </asp:DropDownList>
                    </div>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>

        <!-- Footer Buttons (Reset + Apply) -->
        <div class="bg-light border-top p-3 d-flex justify-content-between align-items-center flex-shrink-0">
            <button type="button" class="btn btn-link reset-link" onclick="resetFilters()">
                <i class="fas fa-undo-alt me-1"></i> Reset
            </button>
            <asp:Button ID="btnApply" runat="server" Text="APPLY FILTERS" CssClass="btn btn-custom-primary text-white px-4 py-2" OnClick="btnApply_Click" />
        </div>
    </form>

  
</body>
</html>