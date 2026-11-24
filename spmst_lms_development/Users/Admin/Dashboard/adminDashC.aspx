<%@ Page Title="Admin Dashboard" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="adminDashC.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Dashboard.adminDashC" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Assets/Vendor/bootstrap/5.3.3/css/bootstrap.min.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Assets/Themes/admin-dashboard.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Assets/Themes/lmsa-pager.css") %>" />
    <script src="<%= ResolveUrl("~/Assets/Vendor/chartjs/4.4.4/chart.umd.min.js") %>"></script>
    <script src="<%= ResolveUrl("~/Assets/Script/lmsa-dash-core.js") %>"></script>
    <script src="<%= ResolveUrl("~/Assets/Script/lmsa-pager.js") %>"></script>
    <script src="<%= ResolveUrl("~/Assets/Script/lmsa-analytics.js") %>"></script>
    <script>
        // Only tells the client which panels exist. The server re-checks the role on EVERY data request.
        window.LMSA_DASH = {
            endpoint: '<%= ResolveUrl("~/Users/Admin/Dashboard/DashboardData.ashx") %>',
            initialTab: '<%= PrimaryTab %>',
            tabs: { circ: <%= ShowCircTab ? "true" : "false" %>, patron: <%= ShowPatronTab ? "true" : "false" %>, attend: <%= ShowAttendTab ? "true" : "false" %> }
        };
    </script>
    <script src="<%= ResolveUrl("~/Assets/Script/admin-dashboard.js") %>" defer></script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container-fluid px-3 px-md-4 py-4">

        <div id="dashAlert" class="alert d-none" role="alert"></div>

        <!-- ====== KPI Stat Cards (circulation figures: only rendered for roles that may see Circulation) ====== -->
        <asp:PlaceHolder ID="phKpi" runat="server">
            <div class="row g-2 g-md-3 mb-4">
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-blue">
                        <div class="stat-title">TOTAL FACULTY VISITS</div>
                        <div class="stat-value text-blue"><asp:Literal ID="litFacultyVisits" runat="server" Text="0" /></div>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-purple">
                        <div class="stat-title">BOOK CIRCULATED</div>
                        <div class="stat-value text-purple"><asp:Literal ID="litCirculated" runat="server" Text="0" /></div>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-orange">
                        <div class="stat-title">OVERDUE BOOKS</div>
                        <div class="stat-value text-orange"><asp:Literal ID="litOverdue" runat="server" Text="0" /></div>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-gold">
                        <div class="stat-title">PENDING FINES</div>
                        <div class="stat-value text-gold">₱<asp:Literal ID="litPendingFines" runat="server" Text="0" /></div>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-green">
                        <div class="stat-title">ACTIVE PATRONS</div>
                        <div class="stat-value text-green"><asp:Literal ID="litActivePatrons" runat="server" Text="0" /></div>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-red">
                        <div class="stat-title">DAMAGE REPORTS</div>
                        <div class="stat-value text-red"><asp:Literal ID="litDamageFines" runat="server" Text="0" /></div>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-slate">
                        <div class="stat-title">LOST BOOKS</div>
                        <div class="stat-value text-slate"><asp:Literal ID="litLostBooks" runat="server" Text="0" /></div>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card border-left-brown">
                        <div class="stat-title">FINES COLLECTED</div>
                        <div class="stat-value text-brown">₱<asp:Literal ID="litFinesCollected" runat="server" Text="0" /></div>
                    </div>
                </div>
            </div>
        </asp:PlaceHolder>

        <!-- ====== Main Tabs (a tab - and its whole panel - exists only for roles allowed to see it) ====== -->
        <ul class="nav nav-tabs dashboard-tabs border-0 mb-4" id="mainTabs" role="tablist">
            <asp:PlaceHolder ID="phTabCirc" runat="server">
                <li class="nav-item">
                    <button class="nav-link <%= ActiveTabClass("circ") %>" data-tab-key="circ"
                            data-bs-toggle="tab" data-bs-target="#circPanel" type="button" role="tab">Circulation</button>
                </li>
            </asp:PlaceHolder>
            <asp:PlaceHolder ID="phTabPatron" runat="server">
                <li class="nav-item">
                    <button class="nav-link <%= ActiveTabClass("patron") %>" data-tab-key="patron"
                            data-bs-toggle="tab" data-bs-target="#patronPanel" type="button" role="tab">Patrons</button>
                </li>
            </asp:PlaceHolder>
            <asp:PlaceHolder ID="phTabAttend" runat="server">
                <li class="nav-item">
                    <button class="nav-link <%= ActiveTabClass("attend") %>" data-tab-key="attend"
                            data-bs-toggle="tab" data-bs-target="#attendPanel" type="button" role="tab">Attendance</button>
                </li>
            </asp:PlaceHolder>
        </ul>

        <div class="tab-content" id="mainTabContent">

            <!-- ====================================================== Circulation ====================================================== -->
            <asp:PlaceHolder ID="phCircPanel" runat="server">
                <div class='tab-pane fade <%= ActivePaneClass("circ") %>' id="circPanel" role="tabpanel">
                    <div class="dash-stack">

                        <!-- Library Trends Overview -->
                        <div class="trends-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
                                <h5 class="dash-card-title">Library Trends Overview</h5>
                                <div class="dash-toolbar">
                                    <div class="input-group input-group-sm w-auto">
                                        <span class="input-group-text">From</span>
                                        <input type="date" id="trFrom" class="form-control" value="<%= TrendsFrom %>" />
                                    </div>
                                    <div class="input-group input-group-sm w-auto">
                                        <span class="input-group-text">To</span>
                                        <input type="date" id="trTo" class="form-control" value="<%= TrendsTo %>" />
                                    </div>
                                    <button type="button" id="btnTrendsApply" class="btn btn-primary btn-sm"><i class="fas fa-filter"></i> Apply Filter</button>
                                </div>
                            </div>

                            <div class="row g-4 mb-4">
                                <div class="col-lg-8 border-lg-end">
                                    <div class="row">
                                        <div class="col-md-6 text-center">
                                            <h6 class="dash-section-label">TOP SECTIONS</h6>
                                            <div class="chart-container" data-chart="chartSections"><canvas id="chartSections"></canvas></div>
                                        </div>
                                        <div class="col-md-6 text-center">
                                            <h6 class="dash-section-label">TOP SUBJECTS (DDC)</h6>
                                            <div class="chart-container" data-chart="chartSubjects"><canvas id="chartSubjects"></canvas></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-lg-4 text-center">
                                    <h6 class="dash-section-label">PENALTY BREAKDOWN</h6>
                                    <div class="chart-container" style="height:200px;" data-chart="chartFines"><canvas id="chartFines"></canvas></div>
                                    <div class="mt-3 text-start px-3 small">
                                        <div class="d-flex justify-content-between border-bottom pb-1">
                                            <span class="text-secondary">Overall Penalties (Base):</span>
                                            <span class="fw-bold text-dark">₱<span id="litTotalPenalties">0.00</span></span>
                                        </div>
                                        <div class="d-flex justify-content-between border-bottom py-1">
                                            <span class="text-secondary">Total Paid:</span>
                                            <span class="fw-bold text-success">₱<span id="litTotalPaid">0.00</span></span>
                                        </div>
                                        <div class="d-flex justify-content-between pt-1">
                                            <span class="text-secondary">Remaining Balance:</span>
                                            <span class="fw-bold text-danger">₱<span id="litTotalBalance">0.00</span></span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="pt-4 border-top">
                                <h6 class="dash-section-label mb-3">BORROWING DISTRIBUTION</h6>
                                <div class="row g-4">
                                    <div class="col-md-6">
                                        <p class="text-center small text-muted">By Institute</p>
                                        <div class="chart-container" data-chart="chartInstitutes"><canvas id="chartInstitutes"></canvas></div>
                                    </div>
                                    <div class="col-md-6">
                                        <p class="text-center small text-muted">By Program</p>
                                        <div class="chart-container" data-chart="chartPrograms"><canvas id="chartPrograms"></canvas></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Descriptive and Diagnostic Analytics (4 independent, paginated tables) -->
                        <div class="trends-card">
                            <h5 class="dash-card-title mb-3">Descriptive and Diagnostic Analytics</h5>
                            <ul class="nav nav-pills mb-3 flex-wrap gap-1" id="analyticsTabs">
                                <li class="nav-item"><button type="button" class="nav-link" data-kind="trending">Trending Books</button></li>
                                <li class="nav-item"><button type="button" class="nav-link active" data-kind="lowcirc">Low Circulation</button></li>
                                <li class="nav-item"><button type="button" class="nav-link" data-kind="peak">Peak Hours</button></li>
                                <li class="nav-item"><button type="button" class="nav-link" data-kind="overdue">Overdue Patterns</button></li>
                            </ul>
                            <div id="anPane-trending" class="an-pane d-none"></div>
                            <div id="anPane-lowcirc" class="an-pane"></div>
                            <div id="anPane-peak" class="an-pane d-none"></div>
                            <div id="anPane-overdue" class="an-pane d-none"></div>
                        </div>

                        <!-- Top Borrowed Books -->
                        <div class="dash-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-2">
                                <h5 class="dash-card-title">Top Borrowed Books</h5>
                                <div class="d-flex align-items-center gap-3">
                                    <span id="topBooksMeta" class="small text-muted"></span>
                                    <button type="button" id="btnTopViewAll" class="btn btn-link btn-sm text-primary d-none p-0">View All</button>
                                </div>
                            </div>
                            <div id="topBooksList"></div>
                        </div>
                    </div>
                </div>
            </asp:PlaceHolder>

            <!-- ======================================================= Patrons ======================================================= -->
            <asp:PlaceHolder ID="phPatronPanel" runat="server">
                <div class='tab-pane fade <%= ActivePaneClass("patron") %>' id="patronPanel" role="tabpanel">
                    <div class="dash-stack">

                        <div class="dash-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                                <h5 class="dash-card-title">Patron Activity Overview</h5>
                                <span class="small text-muted">Patrons in view: <strong id="patronTotal" class="text-dark">0</strong></span>
                            </div>

                            <div class="dash-filter-bar mb-4">
                                <div><label for="fInstitute">Institute</label><select id="fInstitute" class="form-select form-select-sm"><option value="">All Institutes</option></select></div>
                                <div><label for="fProgram">Program</label><select id="fProgram" class="form-select form-select-sm"><option value="">All Programs</option></select></div>
                                <div><label for="fPtype">Patron</label><select id="fPtype" class="form-select form-select-sm"><option value="">All Patrons</option></select></div>
                                <div><label for="fGender">Gender</label><select id="fGender" class="form-select form-select-sm"><option value="">All Genders</option></select></div>
                                <div class="dash-filter-reset"><button type="button" id="btnResetFilters" class="btn btn-light border btn-sm px-3" disabled><i class="fas fa-rotate-left"></i> Reset</button></div>
                            </div>

                            <div class="row g-4 mb-4">
                                <div class="col-md-6 border-md-end">
                                    <h6 class="dash-subhead">Top Programs</h6>
                                    <div id="topPrograms"></div>
                                </div>
                                <div class="col-md-6">
                                    <h6 class="dash-subhead">Top Institutes</h6>
                                    <div id="topInstitutes"></div>
                                </div>
                            </div>

                            <div class="row g-4 pt-3 border-top">
                                <div class="col-md-6 border-md-end">
                                    <h6 class="dash-subhead">Patron Distribution</h6>
                                    <div class="d-flex align-items-center flex-wrap justify-content-center justify-content-md-start gap-3">
                                        <div id="patronLegend"></div>
                                        <div class="chart-box" data-chart="patronDistChart"><canvas id="patronDistChart"></canvas></div>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <h6 class="dash-subhead">Gender Distribution</h6>
                                    <div class="d-flex align-items-center flex-wrap justify-content-center justify-content-md-start gap-3">
                                        <div id="genderLegend"></div>
                                        <div class="chart-box" data-chart="genderDistChart"><canvas id="genderDistChart"></canvas></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="dash-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                                <h5 class="dash-card-title">Penalty Tracking</h5>
                                <div class="dash-search">
                                    <input type="text" id="penSearch" class="form-control form-control-sm" placeholder="Search by name or ID" maxlength="60" />
                                    <i class="fas fa-search"></i>
                                </div>
                            </div>
                            <div id="penBody"></div>
                            <div id="penPager" class="lmsa-pagination"></div>
                        </div>
                    </div>
                </div>
            </asp:PlaceHolder>

            <!-- ====================================================== Attendance ====================================================== -->
            <asp:PlaceHolder ID="phAttendPanel" runat="server">
                <div class='tab-pane fade <%= ActivePaneClass("attend") %>' id="attendPanel" role="tabpanel">
                    <div class="dash-stack">

                        <!-- ONE date + ONE export for both cards -->
                        <div class="dash-card py-3">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-3">
                                <div class="d-flex align-items-center flex-wrap gap-2">
                                    <label for="attDate" class="fw-bold small mb-0 text-uppercase text-muted">Date</label>
                                    <input type="date" id="attDate" class="form-control form-control-sm w-auto" />
                                    <button type="button" id="btnAttToday" class="btn btn-light border btn-sm px-3"><i class="fas fa-rotate-left"></i> Today</button>
                                    <span class="small text-muted">Applies to Occupancy Overview, Attendance and Export</span>
                                </div>
                                <button type="button" id="btnAttExport" class="btn btn-primary btn-sm px-3"><i class="fas fa-file-excel"></i> Export (.xlsx)</button>
                            </div>
                        </div>

                        <!-- Library Occupancy Overview -->
                        <div class="dash-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
                                <h5 class="dash-card-title">Library Occupancy Overview</h5>
                                <span class="small text-muted">
                                    <span id="occDateLabel">-</span> &middot; <strong id="occVisits" class="text-dark">0</strong> visits &middot; <strong id="occInside" class="text-dark">0</strong> still inside
                                </span>
                            </div>
                            <div class="row align-items-center g-3">
                                <div class="col-md-5 border-md-end text-center">
                                    <h6 class="dash-subhead">Avg. Stay Duration</h6>
                                    <div class="d-flex justify-content-center align-items-center flex-wrap gap-3">
                                        <div id="occCircle" class="occ-circle" style="background:#e4e9e5;">
                                            <span class="occ-left" id="occFacAvg">0m</span>
                                            <span class="occ-right" id="occStuAvg">0m</span>
                                        </div>
                                        <div class="text-start">
                                            <div class="small"><span class="legend-dot" style="background-color:#14532d;"></span>Faculty</div>
                                            <div class="small mt-2"><span class="legend-dot" style="background-color:#1b7a3d;"></span>Student</div>
                                        </div>
                                    </div>
                                    <div id="occNoData" class="small text-muted mt-2 d-none">No visits recorded for this date.</div>
                                </div>
                                <div class="col-md-7 ps-md-4">
                                    <div class="mb-4">
                                        <div class="d-flex justify-content-between small fw-bold mb-1"><span>Total Occupancy (peak)</span><span id="occTotalText">0/100</span></div>
                                        <div class="progress" style="height:12px;border-radius:10px;"><div id="occTotalBar" class="progress-bar" role="progressbar" style="width:0%;background-color:var(--sp-green-700);"></div></div>
                                        <div id="occTotalPct" class="text-center small mt-1 fw-bold">0%</div>
                                    </div>
                                    <div class="mb-3">
                                        <div class="d-flex justify-content-between small mb-1"><span>General Area (Study)</span><span id="occStudyText">0/80</span></div>
                                        <div class="progress" style="height:10px;border-radius:10px;"><div id="occStudyBar" class="progress-bar" style="width:0%;background-color:var(--sp-gold);"></div></div>
                                    </div>
                                    <div>
                                        <div class="d-flex justify-content-between small mb-1"><span>Virtual Room (Research)</span><span id="occResearchText">0/20</span></div>
                                        <div class="progress" style="height:10px;border-radius:10px;"><div id="occResearchBar" class="progress-bar" style="width:0%;background-color:var(--sp-green-700);"></div></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Attendance -->
                        <div class="dash-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                                <h5 class="dash-card-title">Attendance</h5>
                                <div class="dash-search">
                                    <input type="text" id="attSearch" class="form-control form-control-sm" placeholder="Search by name, ID" maxlength="60" />
                                    <i class="fas fa-search"></i>
                                </div>
                            </div>
                            <div class="d-flex justify-content-between border-bottom mb-3 flex-wrap gap-2">
                                <ul class="nav nav-underline">
                                    <li class="nav-item"><button type="button" class="nav-link att-role active" data-role="">All Patron</button></li>
                                    <li class="nav-item"><button type="button" class="nav-link att-role" data-role="Faculty">Faculty</button></li>
                                    <li class="nav-item"><button type="button" class="nav-link att-role" data-role="Student">Student</button></li>
                                    <li class="nav-item"><button type="button" class="nav-link att-role" data-role="Staff">Staff</button></li>
                                </ul>
                                <span class="text-muted small align-self-end pb-2">Count: <strong id="attCount" class="text-dark">0</strong></span>
                            </div>
                            <div id="attBody"></div>
                            <div id="attPager" class="lmsa-pagination"></div>
                        </div>
                    </div>
                </div>
            </asp:PlaceHolder>
        </div>
    </div>

</asp:Content>
