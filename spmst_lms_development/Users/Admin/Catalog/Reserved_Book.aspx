<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Reserved_Book.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Catalog.Reserved_Book" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <title>Reserve Book</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        .custom-rbl {
            list-style: none;
            padding-left: 0;
        }
        .custom-rbl li {
            border: 1px solid #e2e8f0;
            border-radius: 0.75rem;
            padding: 0.75rem;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
        }
        .custom-rbl input {
            margin-right: 0.5rem;
            transform: scale(1.1);
        }
        .custom-rbl label {
            font-weight: 500;
            color: #1e293b;
            cursor: pointer;
            flex-grow: 1;
        }
        body { background: white; overflow: hidden; }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="d-flex flex-column">
        <asp:ScriptManager ID="sm1" runat="server" />

        <asp:UpdatePanel ID="upReservation" runat="server" UpdateMode="Conditional" CssClass="h-100 d-flex flex-column">
            <ContentTemplate>
                <!-- Header with close button -->
                <div class="bg-dark text-white p-3 d-flex justify-content-between align-items-center flex-shrink-0">
                    <h5 class="mb-0 fw-bold">Reserve Book</h5>
                    <asp:LinkButton ID="btnClose" runat="server" OnClick="Cancel_Click" CssClass="btn-close btn-close-white"></asp:LinkButton>
                </div>

                <!-- Scrollable Body -->
                <div class="flex-grow-1 overflow-auto p-4">
                    <!-- Step 1: Review -->
                    <asp:Panel ID="pnlStep1" runat="server">
                        <div class="d-flex gap-3 mb-4">
                            <div class="flex-shrink-0">
                                <asp:Image ID="imgCover" runat="server" CssClass="rounded-3 shadow-sm" Style="width: 80px; height: 110px; object-fit: cover;" />
                            </div>
                            <div>
                                <h6 class="fw-bold mb-1"><asp:Literal ID="litTitle" runat="server" /></h6>
                                <p class="text-muted small">by <asp:Literal ID="litAuthor" runat="server" /></p>
                                <span class="badge bg-primary"><asp:Literal ID="litSection" runat="server" /></span>
                            </div>
                        </div>
                        <div class="alert alert-warning small">
                            <i class="fas fa-exclamation-triangle me-2"></i> This reservation is valid for <strong>1 HOUR only</strong>. Please pick up the book before the it expires.
                        </div>
                        <asp:Button ID="btnContinue" runat="server" Text="Continue" CssClass="btn btn-primary w-100 py-2" OnClick="Next_Click" />
                    </asp:Panel>

                    <!-- Step 2: Pickup Details -->
                    <asp:Panel ID="pnlStep2" runat="server" Visible="false">
                        <h6 class="fw-bold mb-2">Select Pickup Location</h6>
                        <p class="small text-muted mb-3">Available copies and their designated areas:</p>
                        <div class="mb-3" style="max-height: 200px; overflow-y: auto;">
                            <asp:RadioButtonList ID="rblLocations" runat="server" CssClass="custom-rbl" />
                        </div>
                        <div class="form-check mb-3">
                            <asp:CheckBox ID="chkTerms" runat="server" CssClass="form-check-input" />
                            <label class="form-check-label small" for="chkTerms">
                                I agree to pick up this book <strong>within 1 hour</strong> before it expires.
                            </label>
                        </div>
                        <div class="d-flex gap-2">
                            <asp:Button ID="btnBack" runat="server" Text="Back" CssClass="btn btn-outline-secondary flex-grow-1" OnClick="Back_Click" />
                            <asp:Button ID="btnConfirm" runat="server" Text="Confirm" CssClass="btn btn-primary flex-grow-1" OnClick="Confirm_Click" />
                        </div>
                    </asp:Panel>

                    <!-- Step 3: Success -->
                    <asp:Panel ID="pnlStep3" runat="server" Visible="false" CssClass="text-center">
                        <div class="bg-success bg-opacity-10 rounded-circle d-inline-flex p-3 mb-3">
                            <i class="fas fa-check text-success fa-2x"></i>
                        </div>
                        <h4 class="fw-bold">Reserved!</h4>
                        <div class="bg-light p-3 rounded-3 mt-3 text-start">
                            <div class="d-flex gap-2">
                                <i class="fas fa-calendar-alt text-primary"></i>
                                <div>
                                    <small class="text-muted">Pickup Deadline</small>
                                    <p class="mb-0 fw-bold"><asp:Literal ID="litDeadline" runat="server" /></p>
                                </div>
                            </div>
                        </div>
                        <asp:LinkButton ID="btnBrowseMore" runat="server" OnClick="Cancel_Click" CssClass="btn btn-dark w-100 mt-3">Browse More Books</asp:LinkButton>
                    </asp:Panel>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </form>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>