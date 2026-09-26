<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="View_BookDetails.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Catalog.View_BookDetails" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Book Details</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <style>
        .info-label {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            color: #6c757d;
            letter-spacing: 0.5px;
        }
        .info-value {
            font-size: 0.9rem;
            font-weight: 600;
            color: #212529;
        }
        .copy-card {
            border: 1px solid #e9ecef;
            border-radius: 0.75rem;
            padding: 0.75rem;
            margin-bottom: 0.75rem;
            background: #fff;
        }
        .status-available { color: #198754; background-color: #d1fae5; display: inline-block; padding: 0.2rem 0.5rem; border-radius: 2rem; font-size: 0.7rem; font-weight: 600; }
        .status-reserved { color: #0d6efd; background-color: #cfe2ff; display: inline-block; padding: 0.2rem 0.5rem; border-radius: 2rem; font-size: 0.7rem; font-weight: 600; }
        .status-borrowed { color: #dc3545; background-color: #f8d7da; display: inline-block; padding: 0.2rem 0.5rem; border-radius: 2rem; font-size: 0.7rem; font-weight: 600; }
        .status-damaged { color: #fd7e14; background-color: #fff3e0; display: inline-block; padding: 0.2rem 0.5rem; border-radius: 2rem; font-size: 0.7rem; font-weight: 600; }
        body { background: white; }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="d-flex flex-column">
        <!-- Header -->
        <div class="bg-dark text-white p-3 d-flex justify-content-between align-items-center flex-shrink-0">
            <div>
                <h5 class="fw-bold mb-0">Resource Information</h5>
                <small>Primary Acc No: <asp:Literal ID="litAccession" runat="server" Text="N/A" /></small>
            </div>
            <button type="button" class="btn-close btn-close-white" onclick="window.parent.closeUniversalModal()"></button>
        </div>

        <!-- Scrollable Body -->
        <div class="flex-grow-1 overflow-auto p-4">
            <div class="row g-4">
                <!-- Left Column: Cover + Copies -->
                <div class="col-md-4">
                    <div class="card shadow-sm border-0 mb-3">
                        <asp:Image ID="imgCover" runat="server" CssClass="card-Img-top" Style="object-fit: cover; height: 280px;" />
                    </div>
                    <div class="card border-0 shadow-sm">
                        <div class="card-header bg-transparent fw-bold"><i class="fas fa-copy me-2"></i> Physical Copies</div>
                        <div class="card-body">
                            <asp:Repeater ID="rptCopies" runat="server">
                                <ItemTemplate>
                                    <div class="copy-card d-flex justify-content-between align-items-center">
                                        <div>
                                            <div class="small text-muted">Accession No.</div>
                                            <div class="fw-bold"><%# Eval("accession_number") %></div>
                                        </div>
                                        <div>
                                            <span class='<%# GetStatusClass(Eval("availability_reason").ToString()) %>'><%# Eval("availability_reason") %></span>
                                        </div>
                                        <div>
                                            <span class='<%# GetConditionClass(Eval("status_condition").ToString()) %>'><%# Eval("status_condition") %></span>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                            <asp:Panel ID="pnlNoCopies" runat="server" Visible="false" CssClass="text-center py-3">
                                <i class="fas fa-info-circle text-muted"></i> No copies recorded.
                            </asp:Panel>
                        </div>
                    </div>
                </div>

                <!-- Right Column: Details -->
                <div class="col-md-8">
                    <h2 class="fw-bold"><asp:Literal ID="litTitle" runat="server" /></h2>
                    <p class="text-muted">by <asp:Literal ID="litAuthor" runat="server" /></p>
                    <hr />
                    <div class="row g-3">
                        <div class="col-md-4"><div class="info-label">ISBN</div><div class="info-value"><asp:Literal ID="litISBN" runat="server" /></div></div>
                        <div class="col-md-4"><div class="info-label">Edition</div><div class="info-value"><asp:Literal ID="litEdition" runat="server" /></div></div>
                        <div class="col-md-4"><div class="info-label">Call Number</div><div class="info-value"><asp:Literal ID="litCallNum" runat="server" /></div></div>
                        <div class="col-md-6"><div class="info-label">Publisher</div><div class="info-value"><asp:Literal ID="litPublisher" runat="server" /></div></div>
                        <div class="col-md-3"><div class="info-label">Year</div><div class="info-value"><asp:Literal ID="litYear" runat="server" /></div></div>
                        <div class="col-md-3"><div class="info-label">Pages</div><div class="info-value"><asp:Literal ID="litPages" runat="server" /></div></div>
                        <div class="col-12"><div class="info-label">Description</div><div class="info-value mt-1"><asp:Literal ID="litDescription" runat="server" Text="No description available." /></div></div>
                    </div>
                </div>
            </div>
        </div>
    </form>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>