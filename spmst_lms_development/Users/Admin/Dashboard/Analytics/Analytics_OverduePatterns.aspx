<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Analytics_OverduePatterns.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Dashboard.Analytics_OverduePatterns" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Overdue Patterns</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <style>
        body { background: transparent; padding: 15px; }
        .table th { background: #f8f9fa; position: sticky; top: 0; z-index: 1; }
        .page-container { background: white; border-radius: 8px; padding: 15px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
        .title-details { font-size: 0.8rem; color: #6c757d; }
        .title-details span { margin-right: 8px; }
        .badge-overdue { background-color: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="page-container">
            <h4 class="mb-3"><i class="fas fa-clock text-warning me-2"></i>Overdue Patterns</h4>
            <p class="text-muted small">Books that are frequently overdue – with diagnostic insights into why.</p>
            <asp:GridView ID="gvOverduePatterns" runat="server" AutoGenerateColumns="False" CssClass="table table-hover table-bordered" GridLines="None">
                <Columns>

                    <asp:TemplateField HeaderText="TITLE">
                        <ItemTemplate>
                            <div class="fw-bold"><%# Eval("Title") %></div>
                            <div class="title-details">
                                <span><%# Eval("Author") %></span>
                                <span>|</span>
                                <span><%# Eval("ISBN_ISSN") %></span>
                                <span>|</span>
                                <span><%# Eval("Section") %></span>
                            </div>
                        </ItemTemplate>
                    </asp:TemplateField>

                    <asp:BoundField DataField="OverdueCount" HeaderText="OVERDUE COUNT" />

                    <asp:BoundField DataField="AvgDaysOverdue" HeaderText="AVG DAYS OVERDUE" />

                    <asp:BoundField DataField="LastOverdueDate" HeaderText="LAST OVERDUE" />

                    <asp:BoundField DataField="TotalBorrows" HeaderText="TOTAL BORROWS" />

                    <asp:TemplateField HeaderText="WHY OVERDUE?">
                        <ItemTemplate>
                            <div class="mb-1">
                                <span class='badge <%# GetBadgeClass(Eval("Reason").ToString()) %>'>%>
                                    <%# Eval("Reason") %>
                                </span>
                            </div>
                            <div class="text-muted small">
                                <i class="fas fa-info-circle me-1"></i><%# Eval("Explanation") %>
                            </div>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
        </div>
    </form>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>