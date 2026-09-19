<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="adminDashAa.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Dashboard.adminDashAa" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Patron Analytics - LMSA </title>
     <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
 <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css" />
 <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
     <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
     <style>
     body {
         background-color: transparent !important;
         font-family: 'Segoe UI', system-ui, sans-serif;
         margin: 0;
         padding: 0;
     }
     .attendance-card {
         border-radius: 20px;
         border: none;
         background: #fff;
         padding: 10px 0;
     }
     .search-container {
         position: relative;
         width: 350px;
     }
     .search-container i {
         position: absolute;
         right: 15px;
         top: 10px;
         color: #6c757d;
     }
     .search-input {
         border-radius: 10px;
         padding-right: 40px;
     }
     .nav-underline .nav-link {
         color: #6c757d;
         font-weight: 500;
         border-bottom: 2px solid transparent;
     }
     .nav-underline .nav-link.active {
         color: #000 !important;
         font-weight: 700 !important;
         border-bottom: 2px solid #0d6efd !important;
         background: transparent;
     }
     .table thead th {
         color: #8E8E8E;
         font-size: 0.8rem;
         font-weight: 600;
         border-bottom: 1px solid #f0f0f0;
         background-color: white;
     }
     .name-main {
         font-weight: 700;
         color: #212529;
         text-transform: uppercase;
         display: block;
     }
     .id-sub {
         font-size: 0.75rem;
         color: #6c757d;
     }
     .badge-in {
         background-color: #E6F9F1;
         color: #198754;
         padding: 5px 15px;
         border-radius: 8px;
         font-weight: 700;
         font-size: 0.75rem;
         display: inline-block;
     }
     .badge-out {
         background-color: #FFF0F0;
         color: #DC3545;
         padding: 5px 15px;
         border-radius: 8px;
         font-weight: 700;
         font-size: 0.75rem;
         display: inline-block;
     }
 </style>
</head>
<body>
    <form id="form1" runat="server">
          <!-- ScriptManager required for UpdatePanel -->
        <asp:ScriptManager ID="ScriptManager1" runat="server" />

 <div class="container-fluid px-4 py-4">
     <div class="attendance-card">
         <asp:UpdatePanel ID="upnlAttendance" runat="server" UpdateMode="Conditional">
             <ContentTemplate>
                 <!-- Occupancy Overview Card -->
                 <div class="row g-3 mb-4">
                     <div class="col-md-12">
                         <div class="attendance-card p-4 shadow-sm border-0 bg-white rounded-4">
                             <div class="d-flex justify-content-between align-items-center mb-4">
                                 <h5 class="fw-bold m-0">Library Occupancy Overview</h5>
                                 <div class="d-flex gap-2">
                                     <button type="button" class="btn btn-light border btn-sm px-3" onclick="alert('Date filter coming soon')"><i class="bi bi-funnel"></i> DATE FILTER</button>
                                     <button type="button" class="btn btn-light border btn-sm px-3" onclick="alert('Export coming soon')"><i class="bi bi-box-arrow-right"></i> EXPORT</button>
                                 </div>
                             </div>

                             <div class="row align-items-center">
                                 <div class="col-md-5 border-end text-center">
                                     <h6 class="text-success small fw-bold mb-3">Avg. Stay Duration</h6>
                                     <div class="d-flex justify-content-center align-items-center">
                                         <div id="chartCircle" runat="server" style="width: 150px; height: 150px; border-radius: 50%; position: relative;">
                                             <div style="position: absolute; top: 50%; left: 20%; transform: translateY(-50%); color: white; font-weight: bold; font-size: 0.8rem;">
                                                 <asp:Literal ID="litFacultyAvg" runat="server" Text="0m" />
                                             </div>
                                             <div style="position: absolute; top: 50%; right: 20%; transform: translateY(-50%); color: white; font-weight: bold; font-size: 0.8rem;">
                                                 <asp:Literal ID="litStudentAvg" runat="server" Text="0m" />
                                             </div>
                                         </div>
                                         <div class="text-start ms-4">
                                             <div class="small"><span class="badge bg-primary me-2">&nbsp;</span> Faculty</div>
                                             <div class="small mt-2"><span class="badge bg-success me-2">&nbsp;</span> Student</div>
                                         </div>
                                     </div>
                                 </div>

                                 <div class="col-md-7 ps-4">
                                     <div class="mb-4">
                                         <div class="d-flex justify-content-between small fw-bold mb-1">
                                             <span>Total Occupancy</span>
                                             <span><asp:Literal ID="litCurrentOccupancy" runat="server" Text="0" />/100</span>
                                         </div>
                                         <div class="progress" style="height: 12px; border-radius: 10px;">
                                             <div id="pbTotal" runat="server" class="progress-bar" role="progressbar" style="width: 0%"></div>
                                         </div>
                                         <div id="lblTotalPercent" runat="server" class="text-center small mt-1 fw-bold">0%</div>
                                     </div>

                                     <div class="mb-3">
                                         <div class="d-flex justify-content-between small mb-1">
                                             <span>General Area (Study)</span>
                                             <span><asp:Literal ID="litGeneralCount" runat="server" Text="0" />/80</span>
                                         </div>
                                         <div class="progress" style="height: 10px; border-radius: 10px;">
                                             <div id="pbGeneral" runat="server" class="progress-bar bg-warning" style="width: 0%"></div>
                                         </div>
                                     </div>

                                     <div>
                                         <div class="d-flex justify-content-between small mb-1">
                                             <span>Virtual Room (Research)</span>
                                             <span><asp:Literal ID="litVirtualCount" runat="server" Text="0" />/20</span>
                                         </div>
                                         <div class="progress" style="height: 10px; border-radius: 10px;">
                                             <div id="pbVirtual" runat="server" class="progress-bar bg-primary" style="width: 0%"></div>
                                         </div>
                                     </div>
                                 </div>
                             </div>
                         </div>
                     </div>
                 </div>

                 <!-- Attendance List Section -->
                 <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                     <h3 class="fw-bold m-0">Attendance</h3>
                     <div class="d-flex gap-3 align-items-center flex-wrap">
                         <div class="search-container">
                             <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control search-input" placeholder="Search by name, ID" OnTextChanged="txtSearch_TextChanged" AutoPostBack="true"></asp:TextBox>
                             <i class="bi bi-search"></i>
                         </div>
                         <button type="button" class="btn btn-light border btn-sm px-3" onclick="alert('Date filter coming soon')"><i class="bi bi-funnel"></i> DATE FILTER</button>
                         <button type="button" class="btn btn-light border btn-sm px-3" onclick="alert('Export coming soon')"><i class="bi bi-box-arrow-right"></i> EXPORT</button>
                     </div>
                 </div>

                 <div class="d-flex justify-content-between border-bottom mb-3">
                     <ul class="nav nav-underline">
                         <li class="nav-item">
                             <asp:LinkButton ID="lnkAll" runat="server" CssClass="nav-link active" OnClick="Filter_Click" CommandArgument="All">All Patron</asp:LinkButton>
                         </li>
                         <li class="nav-item">
                             <asp:LinkButton ID="lnkFaculty" runat="server" CssClass="nav-link" OnClick="Filter_Click" CommandArgument="Faculty">Faculty</asp:LinkButton>
                         </li>
                         <li class="nav-item">
                             <asp:LinkButton ID="lnkStudent" runat="server" CssClass="nav-link" OnClick="Filter_Click" CommandArgument="Student">Student</asp:LinkButton>
                         </li>
                     </ul>
                     <span class="text-muted small align-self-end pb-2">Count: <asp:Literal ID="litCount" runat="server" Text="0" /></span>
                 </div>

                 <div class="table-responsive">
                     <asp:GridView ID="gvAttendance" runat="server" AutoGenerateColumns="False" CssClass="table table-hover align-middle" GridLines="None" ShowHeaderWhenEmpty="true">
                         <Columns>
                             <asp:TemplateField HeaderText="NAME">
                                 <ItemTemplate>
                                     <span class="name-main"><%# Eval("FullName") %></span>
                                     <span class="id-sub"><%# Eval("UserID") %></span>
                                 </ItemTemplate>
                             </asp:TemplateField>
                             <asp:BoundField DataField="Institute" HeaderText="INSTITUTE" />
                             <asp:BoundField DataField="Program" HeaderText="PROGRAM" />
                             <asp:BoundField DataField="Purpose" HeaderText="PURPOSE" />
                             <asp:BoundField DataField="Year" HeaderText="YEAR" />
                             <asp:BoundField DataField="Login" HeaderText="LOGIN" DataFormatString="{0:hh:mm tt}" />
                             <asp:BoundField DataField="Logout" HeaderText="LOGOUT" DataFormatString="{0:hh:mm tt}" NullDisplayText="-" />
                             <asp:TemplateField HeaderText="STATUS">
                                 <ItemTemplate>
                                     <span class='<%# Eval("Status").ToString() == "IN" ? "badge-in" : "badge-out" %>'><%# Eval("Status") %></span>
                                 </ItemTemplate>
                             </asp:TemplateField>
                         </Columns>
                     </asp:GridView>
                 </div>
             </ContentTemplate>
             <Triggers>
                 <asp:AsyncPostBackTrigger ControlID="txtSearch" EventName="TextChanged" />
             </Triggers>
         </asp:UpdatePanel>
     </div>
 </div>
    </form>
</body>
</html>
