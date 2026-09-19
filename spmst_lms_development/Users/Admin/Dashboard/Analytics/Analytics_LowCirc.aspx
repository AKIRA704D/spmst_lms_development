<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Analytics_LowCirc.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Dashboard.Analytics.Analytics_LowCirc" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Low Circulation</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <style>
        body { background: transparent; padding: 15px; }
        .table th { background: #f8f9fa; position: sticky; top: 0; z-index: 1; }
        .badge-custom { font-size: 0.8rem; padding: 0.3rem 0.6rem; }
        .page-container { background: white; border-radius: 8px; padding: 15px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="page-container">
            <h4 class="mb-3"><i class="fas fa-chart-line text-primary me-2"></i>Low Circulation Books</h4>
            <p class="text-muted small">Books borrowed fewer than 5 times – with diagnostic explanations.</p>
            <asp:GridView ID="gvLowCirculation" runat="server" AutoGenerateColumns="False" CssClass="table table-hover table-bordered" GridLines="None">
                <Columns>
                    <asp:TemplateField HeaderText="TITLE">
                        <ItemTemplate>
                            <div class="fw-bold"><%# Eval("Title") %></div>
                            <div class="text-muted small"><%# Eval("Category") %></div>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="Borrows" HeaderText="BORROWS" />
                    <asp:BoundField DataField="LastBorrowed" HeaderText="LAST BORROWED" />
                    <asp:TemplateField HeaderText="WHY NOT CIRCULATING?">
                        <ItemTemplate>
                            <div class="mb-1">
                                <span class='badge <%# GetBadgeClass(Eval("Reason").ToString()) %>'>
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