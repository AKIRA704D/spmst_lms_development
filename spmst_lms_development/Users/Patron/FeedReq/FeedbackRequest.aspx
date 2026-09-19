<%@ Page Title="Feedback & Requests Management" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="FeedbackRequest.aspx.cs" Inherits="spmst_lms_development.Users.Patron.FeedReq.FeedbackRequest" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ============================================
           1. TABLE STYLES
           ============================================ */
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        .data-table th, .data-table td {
            padding: 0.75rem 1rem;
            text-align: left;
            border-bottom: 1px solid #e5e7eb;
        }
        .data-table th {
            background-color: #f8f9fa;
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: #6b7280;
        }
        .data-table tbody tr:hover {
            background-color: #f9fafb;
        }

        /* ============================================
           2. BADGES & TABS
           ============================================ */
        .badge-feedback {
            background-color: #dbeafe;
            color: #1e40af;
            padding: 0.25rem 0.75rem;
            border-radius: 2rem;
            font-size: 0.7rem;
            font-weight: 600;
        }
        .badge-request {
            background-color: #fef3c7;
            color: #92400e;
            padding: 0.25rem 0.75rem;
            border-radius: 2rem;
            font-size: 0.7rem;
            font-weight: 600;
        }
        .tab-custom {
            border-bottom: 2px solid #e2e8f0;
        }
        .tab-custom .nav-link {
            color: #6c757d;
            border: none;
            border-bottom: 2px solid transparent;
            padding: 0.5rem 1rem;
            font-weight: 500;
        }
        .tab-custom .nav-link.active {
            color: #0d6efd;
            border-bottom-color: #0d6efd;
            background: transparent;
        }
        .msg-snippet {
            max-width: 250px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            display: inline-block;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-4">
        <!-- Header -->
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
            <div>
                <h1 class="h2 fw-bold">Feedback &amp; Requests</h1>
                <p class="text-muted">Review user feedbacks and book requests.</p>
            </div>
            <div class="d-flex gap-2">
                <asp:LinkButton ID="btnSubmitFeedback" runat="server" CssClass="btn btn-primary btn-sm" OnClick="btnSubmitFeedback_Click" Visible="false">
                    <i class="fas fa-pen-alt me-1"></i> Submit Feedback
                </asp:LinkButton>
                <div class="input-group input-group-sm w-auto">
                    <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="Search by name or ID..." />
                    <button type="button" class="btn btn-outline-secondary" onclick="searchNow()"><i class="fas fa-search"></i></button>
                </div>
                <asp:LinkButton ID="btnExport" runat="server" CssClass="btn btn-outline-secondary btn-sm" OnClick="btnExport_Click">
                    <i class="fas fa-file-export me-1"></i> EXPORT
                </asp:LinkButton>
            </div>
        </div>

        <!-- Tabs -->
        <ul class="nav nav-tabs tab-custom mb-4" id="feedbackTabs" role="tablist">
            <li class="nav-item">
                <asp:LinkButton ID="tabAll" runat="server" CssClass="nav-link active" OnClick="tabAll_Click">
                    <i class="fas fa-list me-1"></i> All Submissions
                </asp:LinkButton>
            </li>
            <li class="nav-item">
                <asp:LinkButton ID="tabFeedback" runat="server" CssClass="nav-link" OnClick="tabFeedback_Click">
                    <i class="fas fa-comment-dots me-1"></i> General Feedbacks
                </asp:LinkButton>
            </li>
            <li class="nav-item">
                <asp:LinkButton ID="tabRequest" runat="server" CssClass="nav-link" OnClick="tabRequest_Click">
                    <i class="fas fa-book me-1"></i> Book Requests
                </asp:LinkButton>
            </li>
        </ul>

        <!-- Table -->
        <asp:UpdatePanel ID="upTable" runat="server" UpdateMode="Conditional">
            <ContentTemplate>
                <div class="table-responsive">
                    <asp:Repeater ID="rptSubmissions" runat="server">
                        <HeaderTemplate>
                            <table class="data-table table table-hover">
                                <thead>
                                    <tr>
                                        <th>Date Submitted</th>
                                        <th>Patron Name</th>
                                        <th>Role</th>
                                        <th>Category</th>
                                        <th>Message Snippet</th>
                                        <th class="text-center">Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr>
                                <td><i class="far fa-calendar-alt me-1"></i> <%# Eval("FormattedDate") %></td>
                                <td class="fw-semibold"><%# Eval("DisplayName") %><br /><span class="text-muted small"><%# Eval("UserId") %></span></td>
                                <td class="text-capitalize"><%# Eval("Role") %></td>
                                <td><span class='<%# Eval("Type").ToString() == "Request" ? "badge-request" : "badge-feedback" %>'><%# Eval("CategoryTitle") %></span></td>
                                <td><span class="msg-snippet" title="<%# Eval("CleanMessage") %>"><%# Eval("CleanMessage") %></span></td>
                                <td class="text-center">
                                    <button type="button" class="btn btn-primary btn-sm" onclick='viewSubmission("<%# Eval("PatronName") %>", "<%# Eval("CategoryTitle") %>", "<%# Eval("FormattedDate") %>", "<%# Eval("CleanMessage").ToString().Replace("\"", "&quot;").Replace("\n", "\\n") %>")'>
                                        VIEW
                                    </button>
                                </td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate>
                                </tbody>
                            </table>
                            <asp:PlaceHolder runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'>
                                <div class="text-center py-5 text-muted">No submissions found.</div>
                            </asp:PlaceHolder>
                        </FooterTemplate>
                    </asp:Repeater>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>

    <!-- Modal -->
    <div class="modal fade" id="viewModal" tabindex="-1" data-bs-backdrop="static">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="modalCategory">Category</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <p class="small text-muted mb-1">Submitted by</p>
                    <p id="modalPatron" class="fw-bold text-primary"></p>
                    <p class="small text-muted mb-1">Date</p>
                    <p id="modalDate" class="text-muted"></p>
                    <p class="small text-muted mb-1">Message</p>
                    <div id="modalMessage" class="bg-light p-3 rounded"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. MODAL FUNCTIONS
        // ============================================
        let modalInstance = null;

        function viewSubmission(patron, category, date, message) {
            document.getElementById('modalPatron').innerText = patron;
            document.getElementById('modalCategory').innerText = category;
            document.getElementById('modalDate').innerText = date;
            document.getElementById('modalMessage').innerText = message;
            const modalEl = document.getElementById('viewModal');
            modalInstance = new bootstrap.Modal(modalEl);
            modalInstance.show();
        }

        // ============================================
        // 2. SEARCH FUNCTION (manual trigger)
        // ============================================
        function searchNow() {
            const searchBox = document.getElementById('<%= txtSearch.ClientID %>');
            if (searchBox) {
                __doPostBack('<%= txtSearch.UniqueID %>', '');
            }
        }

        // ============================================
        // 3. SWEETALERT (optional for export errors)
        // ============================================
        function showSweetAlert(title, message, icon) {
            Swal.fire({ title: title, text: message, icon: icon, confirmButtonColor: '#0d6efd' });
        }
    </script>
</asp:Content>