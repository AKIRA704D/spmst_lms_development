<%@ Page Title="Feedback & Requests" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="Feedback.aspx.cs" Inherits="spmst_lms_development.Users.Patron.FeedReq.Feedback" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        /* ============================================
           1. FORM & CARD STYLES
           ============================================ */
        .form-card {
            background: #ffffff;
            border-radius: 1.5rem;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.05);
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            border: 1px solid #e2e8f0;
        }
        .form-label-custom {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #475569;
            margin-bottom: 0.25rem;
            display: block;
        }
        .form-control-custom {
            width: 100%;
            border: 1px solid #cbd5e1;
            border-radius: 0.75rem;
            padding: 0.75rem;
            font-size: 0.9rem;
            transition: border-color 0.2s;
        }
        .form-control-custom:focus {
            outline: none;
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59,130,246,0.1);
        }
        .btn-primary-custom {
            background-color: #2563eb;
            color: white;
            border: none;
            border-radius: 0.75rem;
            padding: 0.75rem;
            font-weight: 600;
            width: 100%;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        .btn-primary-custom:hover {
            background-color: #1d4ed8;
        }
        .textarea-wrapper {
            position: relative;
        }
        .char-count {
            position: absolute;
            bottom: 0.5rem;
            left: 0.75rem;
            font-size: 0.7rem;
            color: #94a3b8;
        }

        /* ============================================
           2. SIDEBAR CARDS
           ============================================ */
        .guidelines-card {
            background-color: #f0f7ff;
            border: 1px solid #bfdbfe;
            border-radius: 1.5rem;
            padding: 1.25rem;
            margin-bottom: 1rem;
        }
        .response-card {
            background-color: #fffbeb;
            border: 1px solid #fde68a;
            border-radius: 1.5rem;
            padding: 1.25rem;
            margin-bottom: 1rem;
        }
        .help-card {
            background-color: #65a36b;
            color: white;
            border-radius: 1.5rem;
            padding: 1.25rem;
        }

        /* ============================================
           3. RECENT ACTIVITY
           ============================================ */
        .activity-item {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 0.75rem;
            border: 1px solid #f1f5f9;
            border-radius: 1rem;
            margin-bottom: 0.75rem;
            transition: transform 0.2s;
        }
        .activity-item:hover {
            transform: translateY(-2px);
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        .activity-icon {
            width: 40px;
            height: 40px;
            background: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #3b82f6;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        .badge-pending {
            background-color: #fef3c7;
            color: #b45309;
            padding: 0.25rem 0.75rem;
            border-radius: 2rem;
            font-size: 0.65rem;
            font-weight: 700;
        }

        /* ============================================
           4. TABS (Toggle Buttons)
           ============================================ */
        .tab-toggle {
            display: inline-flex;
            border: 1px solid #e2e8f0;
            border-radius: 0.75rem;
            overflow: hidden;
            background: white;
        }
        .tab-btn {
            padding: 0.5rem 1.5rem;
            font-weight: 600;
            font-size: 0.85rem;
            border: none;
            background: white;
            color: #2563eb;
            cursor: pointer;
            transition: all 0.2s;
        }
        .tab-btn.active {
            background-color: #2563eb;
            color: white;
        }
        .tab-btn.inactive:hover {
            background-color: #f1f5f9;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container py-4">
        <!-- Header & Toggle -->
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
            <h1 class="h2 fw-bold">Feedback & <span class="text-primary">Requests</span></h1>
            <div class="tab-toggle">
                <asp:LinkButton ID="btnTabFeedback" runat="server" CssClass="tab-btn active" OnClick="btnTabFeedback_Click">
                    <i class="fas fa-comment-dots me-1"></i> General Feedback
                </asp:LinkButton>
                <asp:LinkButton ID="btnTabRequest" runat="server" CssClass="tab-btn inactive" OnClick="btnTabRequest_Click">
                    <i class="fas fa-book me-1"></i> Book Request
                </asp:LinkButton>
            </div>
        </div>

        <div class="row g-4">
            <!-- Left Column: Form + Recent Activity -->
            <div class="col-lg-8">
                <asp:UpdatePanel ID="upFeedback" runat="server" UpdateMode="Conditional">
                    <ContentTemplate>
                        <asp:MultiView ID="mvForms" runat="server" ActiveViewIndex="0">
                            <!-- Feedback Form -->
                            <asp:View ID="vwFeedback" runat="server">
                                <div class="form-card">
                                    <div class="d-flex align-items-center gap-3 mb-3">
                                        <div class="bg-primary bg-opacity-10 p-2 rounded-circle">
                                            <i class="fas fa-smile-wink text-primary fa-2x"></i>
                                        </div>
                                        <h4 class="mb-0 fw-bold">Share Your Experience</h4>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label-custom">Feedback Category</label>
                                        <asp:DropDownList ID="ddlCategory" runat="server" CssClass="form-control-custom">
                                            <asp:ListItem Text="" Value=""></asp:ListItem>
                                            <asp:ListItem Text="System Performance Issue" Value="System Performance Issue"></asp:ListItem>
                                            <asp:ListItem Text="User Interface Suggestion" Value="User Interface Suggestion"></asp:ListItem>
                                            <asp:ListItem Text="Other Issue" Value="Other Issue"></asp:ListItem>
                                        </asp:DropDownList>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label-custom">Your Message</label>
                                        <div class="textarea-wrapper">
                                            <asp:TextBox ID="txtMessage" runat="server" TextMode="MultiLine" Rows="5" CssClass="form-control-custom" style="resize: none; padding-bottom: 2rem;"></asp:TextBox>
                                            <span class="char-count" id="charCountDisplay">0 / 500</span>
                                        </div>
                                    </div>
                                    <asp:Button ID="btnSubmitFeedback" runat="server" Text="Submit Feedback" CssClass="btn-primary-custom" OnClick="btnSubmitFeedback_Click" />
                                </div>
                            </asp:View>

                            <!-- Book Request Form -->
                            <asp:View ID="vwBookRequest" runat="server">
                                <div class="form-card">
                                    <div class="d-flex align-items-center gap-3 mb-3">
                                        <div class="bg-primary bg-opacity-10 p-2 rounded-circle">
                                            <i class="fas fa-book text-primary fa-2x"></i>
                                        </div>
                                        <h4 class="mb-0 fw-bold">Request a New Book</h4>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label-custom">Book Title</label>
                                        <asp:TextBox ID="txtReqTitle" runat="server" CssClass="form-control-custom" placeholder="Enter full book title..." />
                                    </div>
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label-custom">Author</label>
                                            <asp:TextBox ID="txtReqAuthor" runat="server" CssClass="form-control-custom" placeholder="Author name" />
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="form-label-custom">Publication Year</label>
                                            <asp:TextBox ID="txtReqYear" runat="server" CssClass="form-control-custom" placeholder="e.g., 2023" />
                                        </div>
                                    </div>
                                    <asp:Button ID="btnSubmitRequest" runat="server" Text="Submit Request" CssClass="btn-primary-custom" OnClick="btnSubmitRequest_Click" />
                                </div>
                            </asp:View>
                        </asp:MultiView>

                        <!-- Recent Activity -->
                        <div class="form-card">
                            <h5 class="fw-bold mb-3"><i class="fas fa-history me-2"></i> Recent Activity</h5>
                            <asp:Repeater ID="rptRecentActivity" runat="server">
                                <ItemTemplate>
                                    <div class="activity-item">
                                        <div class="activity-icon"><i class="fas fa-comment"></i></div>
                                        <div class="flex-grow-1">
                                            <p class="fw-semibold mb-0"><%# Eval("CategoryTitle") %></p>
                                            <small class="text-muted"><%# Eval("TimeAgo") %></small>
                                        </div>
                                        <span class="badge-pending">SUBMITTED</span>
                                    </div>
                                </ItemTemplate>
                                <FooterTemplate>
                                    <asp:PlaceHolder runat="server" Visible='<%# ((Repeater)Container.NamingContainer).Items.Count == 0 %>'>
                                        <div class="text-center py-4 text-muted">You have not submitted any feedback recently.</div>
                                    </asp:PlaceHolder>
                                </FooterTemplate>
                            </asp:Repeater>
                        </div>
                    </ContentTemplate>
                </asp:UpdatePanel>
            </div>

            <!-- Right Column: Info Cards -->
            <div class="col-lg-4">
                <div class="guidelines-card">
                    <h6 class="fw-bold mb-3"><i class="fas fa-info-circle me-2"></i> Guidelines</h6>
                    <div class="d-flex gap-2 mb-2"><i class="fas fa-check-circle text-primary mt-1"></i> <span><strong>Be Specific:</strong> Provide detailed information.</span></div>
                    <div class="d-flex gap-2"><i class="fas fa-check-circle text-primary mt-1"></i> <span><strong>Be Constructive:</strong> Focus on how we can improve.</span></div>
                </div>
                <div class="response-card">
                    <h6 class="fw-bold mb-2"><i class="fas fa-clock me-2"></i> Average Response Time</h6>
                    <p class="mb-0">We typically respond within 2-3 business days.</p>
                </div>
                <div class="help-card">
                    <h6 class="fw-bold mb-2"><i class="fas fa-envelope me-2"></i> Need direct help?</h6>
                    <p class="mb-0 small">library@spamast.edu.ph</p>
                    <p class="mb-0 small">Visit SPAMAST Library</p>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script type="text/javascript">
        // ============================================
        // 1. CHARACTER COUNTER FOR MESSAGE
        // ============================================
        function initCharCounter() {
            const txtMsg = document.getElementById('<%= txtMessage.ClientID %>');
            const charCount = document.getElementById('charCountDisplay');
            if (txtMsg && charCount) {
                charCount.textContent = txtMsg.value.length + ' / 500';
                txtMsg.addEventListener('input', function () {
                    let len = this.value.length;
                    if (len > 500) {
                        this.value = this.value.substring(0, 500);
                        charCount.textContent = '500 / 500';
                    } else {
                        charCount.textContent = len + ' / 500';
                    }
                });
            }
        }
        document.addEventListener("DOMContentLoaded", initCharCounter);
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(initCharCounter);

        // ============================================
        // 2. SWEETALERT FUNCTION (called from code-behind)
        // ============================================
        function showSweetAlert(title, message, icon) {
            Swal.fire({ title: title, text: message, icon: icon, confirmButtonColor: '#2563eb' });
        }
    </script>
</asp:Content>