<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="bookFilter.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Inventory.bookFilter" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <title>Filter Inventory</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        body {
            background: #f8f9fa;
            overflow: hidden;
            height: 100vh;
        }
        .filter-header {
            background-color: #002447;
            color: white;
        }
        .filter-body {
            background: white;
            height: calc(100% - 130px);
            overflow-y: auto;
        }
        .form-label {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #495057;
            margin-bottom: 0.25rem;
        }
        .form-control, .form-select {
            font-size: 0.85rem;
            border-radius: 0.375rem;
            border: 1px solid #ced4da;
        }
        .form-control:focus, .form-select:focus {
            border-color: #ffc107;
            box-shadow: 0 0 0 0.2rem rgba(255,193,7,0.25);
        }
        .btn-primary-custom {
            background-color: #002447;
            border: none;
        }
        .btn-primary-custom:hover {
            background-color: #001a33;
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
</head>
<body>
    <form id="form1" runat="server" class="h-100 d-flex flex-column">
        <!-- Header -->
        <div class="filter-header px-4 py-3 d-flex justify-content-between align-items-center flex-shrink-0">
            <div>
                <h5 class="mb-0 fw-bold text-uppercase">Filter Inventory</h5>
                <small class="text-secondary text-uppercase" style="font-size: 0.65rem;">Refine Results by Copy Details</small>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="window.parent.closeUniversalModal()" aria-label="Close"></button>
        </div>

        <!-- Filter Body -->
        <div class="filter-body p-4 flex-grow-1">
            <div class="section-title mb-3">
                <h6 class="text-primary fw-bold text-uppercase small border-bottom pb-2">Selection Criteria</h6>
            </div>

            <div class="mb-3">
                <label class="form-label">Book Section</label>
                <asp:DropDownList ID="ddlSection" runat="server" CssClass="form-select"></asp:DropDownList>
            </div>

            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label">Acquired From</label>
                    <asp:TextBox ID="txtDateFrom" runat="server" TextMode="Date" CssClass="form-control" />
                </div>
                <div class="col-md-6">
                    <label class="form-label">Acquired To</label>
                    <asp:TextBox ID="txtDateTo" runat="server" TextMode="Date" CssClass="form-control" />
                </div>
            </div>
        </div>

        <!-- Footer Buttons -->
        <div class="bg-light border-top p-3 d-flex justify-content-between align-items-center flex-shrink-0">
            <button type="button" class="reset-link" onclick="resetFilters()">
                <i class="fas fa-undo-alt me-1"></i> Reset
            </button>
            <asp:Button ID="btnApply" runat="server" Text="Apply Filters" CssClass="btn btn-primary-custom text-white px-4 py-2" OnClick="Apply_Click" />
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function resetFilters() {
            document.getElementById('<%= ddlSection.ClientID %>').selectedIndex = 0;
            document.getElementById('<%= txtDateFrom.ClientID %>').value = '';
            document.getElementById('<%= txtDateTo.ClientID %>').value = '';
            Swal.fire({
                icon: 'info',
                title: 'Filters Reset',
                text: 'All filter values have been cleared.',
                timer: 1500,
                showConfirmButton: false
            });
        }
    </script>
</body>
</html>