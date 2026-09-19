<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="bookUD.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Inventory.bookUD" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Edit Resource Details</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        html, body {
            height: 100%;
            margin: 0;
            overflow: hidden;
        }
        body {
            background-color: #f8f9fa;
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
        .bg-readonly {
            background-color: #e9ecef;
            cursor: not-allowed;
        }
        .section-header {
            font-size: 0.7rem;
            font-weight: 800;
            text-transform: uppercase;
            color: #0d6efd;
            border-bottom: 1px solid #dee2e6;
            padding-bottom: 0.5rem;
            margin-bottom: 1rem;
        }
        .custom-scroll {
            overflow-y: auto;
            scrollbar-width: thin;
        }
        .custom-scroll::-webkit-scrollbar {
            width: 6px;
        }
        .custom-scroll::-webkit-scrollbar-track {
            background: #f1f1f1;
        }
        .custom-scroll::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 10px;
        }
        .btn-custom-primary {
            background-color: #002447;
            border: none;
        }
        .btn-custom-primary:hover {
            background-color: #001a33;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="h-100 d-flex flex-column">
        <!-- Header -->
        <div class="bg-dark text-white px-4 py-3 d-flex justify-content-between align-items-center flex-shrink-0">
            <div>
                <h5 class="mb-0 fw-bold text-uppercase">Edit Resource Details</h5>
                <small class="text-secondary text-uppercase" style="font-size: 0.65rem;">Resource ID: <asp:Literal ID="litResID" runat="server" /></small>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="window.parent.closeUniversalModal()" aria-label="Close"></button>
        </div>

        <!-- Form Body (scrollable) -->
        <div class="flex-grow-1 p-4 custom-scroll" style="background: white;">
            <div class="row g-4">
                <!-- General Info Column -->
                <div class="col-md-6">
                    <div class="section-header">General Info</div>
                    <div class="mb-3">
                        <label class="form-label">Book Title</label>
                        <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" />
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Author(s)</label>
                        <asp:TextBox ID="txtAuthors" runat="server" CssClass="form-control" />
                    </div>
                    <div class="row g-2">
                        <div class="col-md-6">
                            <label class="form-label">ISBN</label>
                            <asp:TextBox ID="txtISBN" runat="server" CssClass="form-control bg-readonly" ReadOnly="true" />
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Edition</label>
                            <asp:TextBox ID="txtEdition" runat="server" CssClass="form-control" />
                        </div>
                    </div>
                </div>

                <!-- Publication Column -->
                <div class="col-md-6">
                    <div class="section-header">Publication</div>
                    <div class="mb-3">
                        <label class="form-label">Publisher</label>
                        <asp:TextBox ID="txtPublisher" runat="server" CssClass="form-control" />
                    </div>
                    <div class="row g-2">
                        <div class="col-md-6">
                            <label class="form-label">Pages</label>
                            <asp:TextBox ID="txtPages" runat="server" CssClass="form-control" />
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">Copyright Year</label>
                            <asp:TextBox ID="txtCopyright" runat="server" CssClass="form-control" />
                        </div>
                    </div>
                    <div class="mt-3">
                        <label class="form-label">Description / Abstract</label>
                        <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" Rows="4" CssClass="form-control" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Footer Buttons -->
        <div class="bg-light border-top p-3 d-flex justify-content-end gap-3 flex-shrink-0">
            <asp:Button ID="btnCancel" runat="server" Text="Discard" CssClass="btn btn-outline-secondary px-4" OnClick="BtnExit_Click" />
            <asp:Button ID="btnUpdate" runat="server" Text="Save Changes" CssClass="btn btn-custom-primary text-white px-5" OnClick="BtnUpdate_Click" />
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>