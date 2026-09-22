<%@ Page Title="Management Dashboard" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="MgtDash.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Dashboard.MgtDash" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <style>
        .attendance-card { border-radius:20px; border:none; background:#fff; padding:10px 0; }
        .search-container { position:relative; width:350px; }
        .search-container i { position:absolute; right:15px; top:10px; color:#6c757d; }
        .search-input { border-radius:10px; padding-right:40px; }
        .nav-underline .nav-link { color:#6c757d; font-weight:500; border-bottom:2px solid transparent; }
        .nav-underline .nav-link.active { color:#000!important; font-weight:700!important;
            border-bottom:2px solid #0d6efd!important; background:transparent; }
        .table thead th { color:#8E8E8E; font-size:.8rem; font-weight:600;
            border-bottom:1px solid #f0f0f0; background-color:#fff; }
        .name-main { font-weight:700; color:#212529; text-transform:uppercase; display:block; }
        .id-sub { font-size:.75rem; color:#6c757d; }
        .badge-in  { background-color:#E6F9F1; color:#198754; padding:5px 15px; border-radius:8px;
            font-weight:700; font-size:.75rem; display:inline-block; }
        .badge-out { background-color:#FFF0F0; color:#DC3545; padding:5px 15px; border-radius:8px;
            font-weight:700; font-size:.75rem; display:inline-block; }
        .progress { background-color:#e9ecef; height:10px; border-radius:10px; }
        .rounded-card { border-radius:20px; }
        .badge-unpaid { background-color:#fff5f5; color:#ff4d4d; border:1px solid #ff4d4d; padding:5px 10px; }
        .chart-container { position:relative; height:160px; width:160px; margin:auto; }
        .mgmt-tabs .nav-link { color:#6c757d; border-bottom:2px solid transparent; }
        .mgmt-tabs .nav-link.active { color:#0d6efd; border-bottom-color:#0d6efd; background:transparent; }
        /* --- KPI stat cards (same palette as CirDash) --- */
        .stat-card { background:#fff; border-radius:.75rem; padding:1rem 1.25rem;
            box-shadow:0 2px 4px rgba(0,0,0,.05); border-left:4px solid; transition:transform .2s; }
        .stat-card:hover { transform:translateY(-2px); box-shadow:0 4px 12px rgba(0,0,0,.1); }
        .stat-title { font-size:.7rem; text-transform:uppercase; color:#6c757d; letter-spacing:.5px; }
        .stat-value { font-size:1.75rem; font-weight:800; line-height:1; }
        .border-left-blue   { border-left-color:#1e3a8a; } .border-left-purple { border-left-color:#6366f1; }
        .border-left-orange { border-left-color:#f59e0b; } .border-left-gold   { border-left-color:#d97706; }
        .border-left-green  { border-left-color:#10b981; } .border-left-red    { border-left-color:#ef4444; }
        .border-left-slate  { border-left-color:#64748b; } .border-left-brown  { border-left-color:#b45309; }
        .text-blue   { color:#1e3a8a; } .text-purple { color:#6366f1; } .text-orange { color:#f59e0b; }
        .text-gold   { color:#d97706; } .text-green  { color:#10b981; } .text-red    { color:#ef4444; }
        .text-slate  { color:#64748b; } .text-brown  { color:#b45309; }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid px-4 py-4">

        <!-- ================= KPI CARDS ================= -->
        <div class="row g-3 mb-4">
            <div class="col-md-3"><div class="stat-card border-left-blue">
                <div class="stat-title">TOTAL FACULTY VISITS</div>
                <div class="stat-value text-blue"><asp:Literal ID="litKpiFacultyVisits" runat="server" Text="0" /></div>
            </div></div>
            <div class="col-md-3"><div class="stat-card border-left-purple">
                <div class="stat-title">TOTAL STUDENT VISITS</div>
                <div class="stat-value text-purple"><asp:Literal ID="litKpiStudentVisits" runat="server" Text="0" /></div>
            </div></div>
            <div class="col-md-3"><div class="stat-card border-left-orange">
                <div class="stat-title">CURRENTLY INSIDE</div>
                <div class="stat-value text-orange"><asp:Literal ID="litKpiCurrentlyInside" runat="server" Text="0" /></div>
            </div></div>
            <div class="col-md-3"><div class="stat-card border-left-gold">
                <div class="stat-title">TODAY'S VISITS</div>
                <div class="stat-value text-gold"><asp:Literal ID="litKpiTodayVisits" runat="server" Text="0" /></div>
            </div></div>
            <div class="col-md-3"><div class="stat-card border-left-green">
                <div class="stat-title">TOTAL FACULTY</div>
                <div class="stat-value text-green"><asp:Literal ID="litKpiTotalFaculty" runat="server" Text="0" /></div>
            </div></div>
            <div class="col-md-3"><div class="stat-card border-left-red">
                <div class="stat-title">TOTAL STUDENTS</div>
                <div class="stat-value text-red"><asp:Literal ID="litKpiTotalStudents" runat="server" Text="0" /></div>
            </div></div>
            <div class="col-md-3"><div class="stat-card border-left-slate">
                <div class="stat-title">PROGRAMS OFFERED</div>
                <div class="stat-value text-slate"><asp:Literal ID="litKpiTotalPrograms" runat="server" Text="0" /></div>
            </div></div>
            <div class="col-md-3"><div class="stat-card border-left-brown">
                <div class="stat-title">CAMPUS INSTITUTES</div>
                <div class="stat-value text-brown"><asp:Literal ID="litKpiTotalInstitutes" runat="server" Text="0" /></div>
            </div></div>
        </div>

        <ul class="nav nav-tabs mgmt-tabs border-0 mb-4" id="mgmtTabs" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="tabAttend" data-bs-toggle="tab"
                        data-bs-target="#attendPanel" type="button" role="tab">Attendance</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="tabPatron" data-bs-toggle="tab"
                        data-bs-target="#patronPanel" type="button" role="tab">Patron Analytics</button>
            </li>
        </ul>

        <div class="tab-content" id="mgmtTabContent">

            <!-- ================= ATTENDANCE TAB ================= -->
            <div class="tab-pane fade show active" id="attendPanel" role="tabpanel">
                <div class="attendance-card">
                    <asp:UpdatePanel ID="upnlAttendance" runat="server" UpdateMode="Conditional">
                        <ContentTemplate>

                            <div class="row g-3 mb-4">
                                <div class="col-md-12">
                                    <div class="attendance-card p-4 shadow-sm border-0 bg-white rounded-4">
                                        <div class="d-flex justify-content-between align-items-center mb-4">
                                            <h5 class="fw-bold m-0">Library Occupancy Overview</h5>
                                        </div>

                                        <div class="row align-items-center">
                                            <div class="col-md-5 border-end text-center">
                                                <h6 class="text-success small fw-bold mb-3">Avg. Stay Duration</h6>
                                                <div class="d-flex justify-content-center align-items-center">
                                                    <div id="chartCircle" runat="server"
                                                         style="width:150px;height:150px;border-radius:50%;position:relative;">
                                                        <div style="position:absolute;top:50%;left:20%;transform:translateY(-50%);
                                                                    color:#fff;font-weight:bold;font-size:.8rem;">
                                                            <asp:Literal ID="litFacultyAvg" runat="server" Text="0m" />
                                                        </div>
                                                        <div style="position:absolute;top:50%;right:20%;transform:translateY(-50%);
                                                                    color:#fff;font-weight:bold;font-size:.8rem;">
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
                                                    <div class="progress" style="height:12px;border-radius:10px;">
                                                        <div id="pbTotal" runat="server" class="progress-bar"
                                                             role="progressbar" style="width:0%"></div>
                                                    </div>
                                                    <div id="lblTotalPercent" runat="server"
                                                         class="text-center small mt-1 fw-bold">0%</div>
                                                </div>

                                                <div class="mb-3">
                                                    <div class="d-flex justify-content-between small mb-1">
                                                        <span>General Area (Study)</span>
                                                        <span><asp:Literal ID="litGeneralCount" runat="server" Text="0" />/80</span>
                                                    </div>
                                                    <div class="progress" style="height:10px;border-radius:10px;">
                                                        <div id="pbGeneral" runat="server" class="progress-bar bg-warning"
                                                             style="width:0%"></div>
                                                    </div>
                                                </div>

                                                <div>
                                                    <div class="d-flex justify-content-between small mb-1">
                                                        <span>Virtual Room (Research)</span>
                                                        <span><asp:Literal ID="litVirtualCount" runat="server" Text="0" />/20</span>
                                                    </div>
                                                    <div class="progress" style="height:10px;border-radius:10px;">
                                                        <div id="pbVirtual" runat="server" class="progress-bar bg-primary"
                                                             style="width:0%"></div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                                <h3 class="fw-bold m-0">Attendance</h3>
                                <div class="search-container">
                                    <asp:TextBox ID="txtAttSearch" runat="server"
                                        CssClass="form-control search-input"
                                        placeholder="Search by name, ID"
                                        OnTextChanged="txtAttSearch_TextChanged" AutoPostBack="true" />
                                    <i class="bi bi-search"></i>
                                </div>
                            </div>

                            <div class="d-flex justify-content-between border-bottom mb-3">
                                <ul class="nav nav-underline">
                                    <li class="nav-item">
                                        <asp:LinkButton ID="lnkAll" runat="server" CssClass="nav-link active"
                                            OnClick="Filter_Click" CommandArgument="All">All Patron</asp:LinkButton>
                                    </li>
                                    <li class="nav-item">
                                        <asp:LinkButton ID="lnkFaculty" runat="server" CssClass="nav-link"
                                            OnClick="Filter_Click" CommandArgument="Faculty">Faculty</asp:LinkButton>
                                    </li>
                                    <li class="nav-item">
                                        <asp:LinkButton ID="lnkStudent" runat="server" CssClass="nav-link"
                                            OnClick="Filter_Click" CommandArgument="Student">Student</asp:LinkButton>
                                    </li>
                                </ul>
                                <span class="text-muted small align-self-end pb-2">
                                    Count: <asp:Literal ID="litCount" runat="server" Text="0" />
                                </span>
                            </div>

                            <div class="table-responsive">
                                <asp:GridView ID="gvAttendance" runat="server" AutoGenerateColumns="False"
                                    CssClass="table table-hover align-middle" GridLines="None" ShowHeaderWhenEmpty="true">
                                    <Columns>
                                        <asp:TemplateField HeaderText="NAME">
                                            <ItemTemplate>
                                                <span class="name-main"><%# Eval("FullName") %></span>
                                                <span class="id-sub"><%# Eval("UserID") %></span>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:BoundField DataField="Institute" HeaderText="INSTITUTE" />
                                        <asp:BoundField DataField="Program"   HeaderText="PROGRAM" />
                                        <asp:BoundField DataField="Purpose"   HeaderText="PURPOSE" />
                                        <asp:BoundField DataField="Year"      HeaderText="YEAR" />
                                        <asp:BoundField DataField="Login"     HeaderText="LOGIN"
                                            DataFormatString="{0:hh:mm tt}" />
                                        <asp:BoundField DataField="Logout"    HeaderText="LOGOUT"
                                            DataFormatString="{0:hh:mm tt}" NullDisplayText="-" />
                                        <asp:TemplateField HeaderText="STATUS">
                                            <ItemTemplate>
                                                <span class='<%# Eval("Status").ToString() == "IN" ? "badge-in" : "badge-out" %>'>
                                                    <%# Eval("Status") %></span>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                </asp:GridView>
                            </div>
                        </ContentTemplate>
                        <Triggers>
                            <asp:AsyncPostBackTrigger ControlID="txtAttSearch" EventName="TextChanged" />
                        </Triggers>
                    </asp:UpdatePanel>
                </div>
            </div>

            <!-- ================= PATRON ANALYTICS TAB ================= -->
            <div class="tab-pane fade" id="patronPanel" role="tabpanel">
                <div class="card shadow-sm border-0 rounded-card mb-4">
                    <div class="card-body p-4">
                        <h5 class="fw-bold mb-4">Patron Activity Overview</h5>

                        <div class="row g-4 mb-4">
                            <div class="col-md-6 border-end">
                                <h6 class="text-success small fw-bold mb-3">Top Programs</h6>
                                <asp:Repeater ID="rptPrograms" runat="server">
                                    <ItemTemplate>
                                        <div class="mb-3">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span class="small fw-bold"><%# Eval("course") %></span>
                                                <span class="small text-muted"><%# Eval("Percentage") %>%</span>
                                            </div>
                                            <div class="progress">
                                                <div class='<%# "progress-bar " + GetProgressColor(Container.ItemIndex) %>'
                                                    role="progressbar"
                                                    style='<%# "width: " + Eval("Percentage") + "%" %>'></div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                            <div class="col-md-6">
                                <h6 class="text-success small fw-bold mb-3">Top Institutes</h6>
                                <asp:Repeater ID="rptInstitutes" runat="server">
                                    <ItemTemplate>
                                        <div class="mb-3">
                                            <div class="d-flex justify-content-between mb-1">
                                                <span class="small fw-bold"><%# Eval("institute") %></span>
                                                <span class="small text-muted"><%# Eval("Percentage") %>%</span>
                                            </div>
                                            <div class="progress">
                                                <div class='<%# "progress-bar " + GetProgressColor(Container.ItemIndex + 2) %>'
                                                    role="progressbar"
                                                    style='<%# "width: " + Eval("Percentage") + "%" %>'></div>
                                            </div>
                                        </div>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </div>

                        <div class="row g-4 pt-3 border-top">
                            <div class="col-md-6 border-end">
                                <h6 class="text-success small fw-bold mb-3">Patron Distribution</h6>
                                <div class="d-flex align-items-center">
                                    <div class="me-4">
                                        <div class="mb-2"><span class="badge bg-primary p-2 me-2">&nbsp;</span><small>Faculty</small></div>
                                        <div><span class="badge bg-success p-2 me-2">&nbsp;</span><small>Student</small></div>
                                    </div>
                                    <div class="chart-container"><canvas id="patronDistChart"></canvas></div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <h6 class="text-success small fw-bold mb-3">Gender Distribution</h6>
                                <div class="d-flex align-items-center">
                                    <div class="me-4">
                                        <div class="mb-2"><span class="badge bg-info p-2 me-2">&nbsp;</span><small>Male</small></div>
                                        <div><span class="badge p-2 me-2" style="background-color:#ff69b4;">&nbsp;</span><small>Female</small></div>
                                    </div>
                                    <div class="chart-container"><canvas id="genderDistChart"></canvas></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card shadow-sm border-0 rounded-card">
                    <div class="card-body p-4">
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <h5 class="fw-bold mb-0">Penalty Tracking</h5>
                            <asp:UpdatePanel ID="upnlPenalties" runat="server" UpdateMode="Conditional">
                                <ContentTemplate>
                                    <div class="input-group input-group-sm" style="width:250px;">
                                        <asp:TextBox ID="txtPatronSearch" runat="server"
                                            CssClass="form-control rounded-start-pill ps-3"
                                            placeholder="Search name or ID..."
                                            AutoPostBack="true"
                                            OnTextChanged="txtPatronSearch_TextChanged" />
                                        <span class="input-group-text bg-white rounded-end-pill border-start-0 text-muted">
                                            <i class="fas fa-search"></i>
                                        </span>
                                    </div>
                                </ContentTemplate>
                            </asp:UpdatePanel>
                        </div>

                        <asp:UpdatePanel ID="upnlGridView" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div class="table-responsive">
                                    <asp:GridView ID="gvPenalties" runat="server" AutoGenerateColumns="False"
                                        CssClass="table table-hover border-top align-middle" GridLines="None"
                                        ShowHeaderWhenEmpty="true">
                                        <Columns>
                                            <asp:BoundField DataField="PenaltyDate" HeaderText="Date"
                                                DataFormatString="{0:MM.dd.yyyy}" />
                                            <asp:TemplateField HeaderText="Patron Details">
                                                <ItemTemplate>
                                                    <div class="fw-bold"><%# Eval("FullName") %></div>
                                                    <small class="text-muted"><%# Eval("PatronID") %></small>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:BoundField DataField="Program"     HeaderText="Program" />
                                            <asp:TemplateField HeaderText="Book Title">
                                                <ItemTemplate>
                                                    <div class="text-truncate" style="max-width:180px;">
                                                        <%# Eval("BookTitle") %></div>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:BoundField DataField="PenaltyType" HeaderText="Violation" />
                                            <asp:TemplateField HeaderText="Amount">
                                                <ItemTemplate>
                                                    <span class="fw-bold">₱<%# string.Format("{0:N2}", Eval("Amount")) %></span>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Status">
                                                <ItemTemplate>
                                                    <span class="badge rounded-pill badge-unpaid"><%# Eval("Status") %></span>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                        </Columns>
                                    </asp:GridView>
                                </div>
                            </ContentTemplate>
                            <Triggers>
                                <asp:AsyncPostBackTrigger ControlID="txtPatronSearch" EventName="TextChanged" />
                            </Triggers>
                        </asp:UpdatePanel>
                    </div>
                </div>

                <asp:Literal ID="litChartData" runat="server"></asp:Literal>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
(function() {
    // Render doughnut charts once DOM + JSON are ready
    function initCharts() {
        var dataEl = document.getElementById('chartDataJSON');
        var chartData = { patron: [0, 0], gender: [0, 0] };
        if (dataEl) { try { chartData = JSON.parse(dataEl.textContent); } catch (e) { console.error(e); } }

        var opts = {
            responsive: true, maintainAspectRatio: false,
            cutout: '75%', plugins: { legend: { display: false } }
        };

        var p = document.getElementById('patronDistChart');
        if (p) new Chart(p, {
            type: 'doughnut',
            data: {
                labels: ['Faculty', 'Student'],
                datasets: [{
                    data: chartData.patron,
                    backgroundColor: ['#0d6efd', '#198754'], borderWidth: 0
                }]
            },
            options: opts
        });

        var g = document.getElementById('genderDistChart');
        if (g) new Chart(g, {
            type: 'doughnut',
            data: {
                labels: ['Male', 'Female'],
                datasets: [{
                    data: chartData.gender,
                    backgroundColor: ['#0dcaf0', '#ff69b4'], borderWidth: 0
                }]
            },
            options: opts
        });
    }

    // Persist / restore active tab across postbacks
    var saved = sessionStorage.getItem('mgmtActiveTab');
    if (saved) {
        var btn = document.querySelector('#mgmtTabs button[data-bs-target="' + saved + '"]');
        if (btn && window.bootstrap) new bootstrap.Tab(btn).show();
    }
    document.querySelectorAll('#mgmtTabs button').forEach(function(b) {
        b.addEventListener('shown.bs.tab', function(e) {
            sessionStorage.setItem('mgmtActiveTab', e.target.getAttribute('data-bs-target'));
        });
    });

    if (document.readyState === 'loading')
        document.addEventListener('DOMContentLoaded', initCharts);
    else
        initCharts();

    // Re-render charts whenever the AJAX UpdatePanel finishes
    if (window.Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance()
            .add_endRequest(function() { initCharts(); });
    }
        })();
    </script>
</asp:Content>