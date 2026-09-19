<%@ Page Title="Live Attendance Monitor" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="AttendanceMonitor.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Attendance.AttendanceMonitor" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <!-- External Libraries -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" />

    <!-- ==================== INTERNAL CSS STYLES ==================== -->
    <style>
        /* ========== 1. GLOBAL & CONTAINER STYLES ========== */
        .monitor-container {
            padding: 20px;
            background: #f8fafc;
            min-height: 100vh;
        }

        /* ========== 2. HEADER SECTION ========== */
        .monitor-header h1 {
            font-size: 1.75rem;
            font-weight: 700;
            color: #1e293b;
            margin: 0 0 5px 0;
        }
        .monitor-header p {
            color: #64748b;
            font-size: 0.875rem;
            margin: 0;
        }
        .btn-kiosk {
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
        }
        .btn-kiosk:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.15);
            background: linear-gradient(135deg, #059669, #047857);
            color: white;
        }
        .staff-assisted-btn {
            background: linear-gradient(135deg, #1e3a8a, #1e40af);
        }
        .staff-assisted-btn:hover {
            background: linear-gradient(135deg, #1e40af, #1e3a8a);
        }

        /* ========== 3. STATS CARDS STYLES ========== */
        .stat-card {
            background: white;
            border-radius: 16px;
            padding: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.2s, box-shadow 0.2s;
            height: 100%;
        }
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        .stat-icon {
            font-size: 2rem;
            margin-bottom: 10px;
        }
        .stat-value {
            font-size: 2rem;
            font-weight: 700;
            color: #1e293b;
            line-height: 1.2;
        }
        .stat-label {
            font-size: 0.75rem;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-top: 8px;
        }
        .stat-trend {
            font-size: 0.7rem;
            margin-top: 5px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
        }
        .trend-up { color: #10b981; }
        .trend-down { color: #ef4444; }

        /* ========== 4. BOOTSTRAP TAB CUSTOMIZATION ========== */
        .custom-tabs .nav-link {
            color: #64748b;
            font-weight: 500;
            border: none;
            padding: 12px 20px;
            transition: all 0.2s;
        }
        .custom-tabs .nav-link:hover {
            color: #1e3a8a;
            border-color: transparent;
        }
        .custom-tabs .nav-link.active {
            color: #1e3a8a;
            background-color: transparent;
            border-bottom: 2px solid #1e3a8a;
            font-weight: 600;
        }
        .tab-content {
            margin-top: 20px;
        }

        /* ========== 5. TABLE & STATUS BADGES ========== */
        .attendance-table {
            width: 100%;
            border-collapse: collapse;
        }
        .attendance-table th,
        .attendance-table td {
            padding: 12px 10px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }
        .attendance-table th {
            background: #f8fafc;
            font-weight: 600;
            font-size: 0.75rem;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .attendance-table td {
            font-size: 0.8rem;
            color: #1e293b;
        }
        .attendance-table tbody tr:hover {
            background: #f1f5f9;
        }
        .status-in {
            background: #dcfce7;
            color: #166534;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            display: inline-block;
        }
        .status-out {
            background: #fee2e2;
            color: #991b1b;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            display: inline-block;
        }
        .no-data {
            text-align: center;
            padding: 40px;
            color: #94a3b8;
        }

        /* ========== 6. CHART CONTAINER STYLES ========== */
        .chart-card {
            background: white;
            border-radius: 16px;
            padding: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .chart-container {
            position: relative;
            height: 400px;
        }
        .refresh-timer {
            font-size: 0.7rem;
            color: #94a3b8;
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .auto-refresh {
            color: #10b981;
            font-weight: 500;
        }

        /* ========== 7. BUTTON & SEARCH STYLES ========== */
        .btn-search, .btn-export, .btn-refresh {
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 0.8rem;
            cursor: pointer;
            transition: all 0.2s;
            border: none;
            font-weight: 500;
        }
        .btn-search {
            background: #1e3a8a;
            color: white;
        }
        .btn-search:hover {
            background: #1e40af;
            transform: translateY(-1px);
        }
        .btn-export {
            background: #f1f5f9;
            color: #475569;
        }
        .btn-export:hover {
            background: #e2e8f0;
            transform: translateY(-1px);
        }
        .btn-refresh {
            background: #e2e8f0;
            color: #475569;
        }
        .btn-refresh:hover {
            background: #cbd5e1;
            transform: translateY(-1px);
        }
        .search-box input {
            padding: 8px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 0.8rem;
            width: 220px;
        }
        .search-box input:focus {
            outline: none;
            border-color: #1e3a8a;
            box-shadow: 0 0 0 2px rgba(30,58,138,0.1);
        }

        /* ========== 8. PAGINATION & FOOTER ========== */
        .table-footer {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #e2e8f0;
            flex-wrap: wrap;
            gap: 10px;
        }
        .entries-info {
            font-size: 0.75rem;
            color: #64748b;
        }

        /* ========== 9. LOADING SPINNER ========== */
        .chart-loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            text-align: center;
            color: #94a3b8;
        }
        .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #1e3a8a;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 10px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* ========== 10. RESPONSIVE ADJUSTMENTS ========== */
        @media (max-width: 768px) {
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            .table-header {
                flex-direction: column;
                align-items: flex-start;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="monitor-container">
        <!-- Header Section -->
        <div class="monitor-header d-flex justify-content-between align-items-center flex-wrap mb-4">
            <div>
                <h1><i class="fas fa-chalkboard-user"></i> Library Patron Monitor</h1>
                <p>Real-time tracking of library entries and exits</p>
            </div>
            <div class="d-flex gap-3 flex-wrap">
                <asp:HyperLink ID="lnkStaffKiosk" runat="server" 
                    NavigateUrl="/Users/Staff/attendance/Kiosk/Kiosk.aspx"
                    CssClass="btn-kiosk staff-assisted-btn">
                    <i class="fas fa-chalkboard-user"></i> Staff-Assisted Kiosk
                </asp:HyperLink>
                <asp:HyperLink ID="lnkSelfServiceKiosk" runat="server" 
                    NavigateUrl="/Users/Staff/Attendance/Kiosk/SelfServiceKiosk.aspx"
                    CssClass="btn-kiosk" Target="_blank">
                    <i class="fas fa-qrcode"></i> Self-Service Kiosk
                </asp:HyperLink>
            </div>
        </div>

        <!-- UpdatePanel for Live Stats and Attendance Grid (Async Refresh) -->
        <asp:UpdatePanel ID="upnlAttendance" runat="server" UpdateMode="Conditional">
            <Triggers>
                <asp:AsyncPostBackTrigger ControlID="TimerRefresh" EventName="Tick" />
                <asp:AsyncPostBackTrigger ControlID="btnRefreshStats" EventName="Click" />
                <asp:AsyncPostBackTrigger ControlID="btnSearch" EventName="Click" />
                <asp:AsyncPostBackTrigger ControlID="gvAttendance" EventName="PageIndexChanging" />
            </Triggers>
            <ContentTemplate>
                <!-- Stats Cards Grid -->
                <div class="row g-3 mb-4 stats-grid">
                    <div class="col-md-2 col-6">
                        <div class="stat-card">
                            <div class="stat-icon"><i class="fas fa-users"></i></div>
                            <div class="stat-value"><asp:Literal ID="litPatronsInside" runat="server" Text="0" /></div>
                            <div class="stat-label">Patrons in library</div>
                            <div class="stat-trend"><asp:Literal ID="litTrendInside" runat="server" Text="" /></div>
                        </div>
                    </div>
                    <div class="col-md-2 col-6">
                        <div class="stat-card">
                            <div class="stat-icon"><i class="fas fa-chart-line"></i></div>
                            <div class="stat-value"><asp:Literal ID="litPeakHour" runat="server" Text="0" /></div>
                            <div class="stat-label">Peak Hour Rate</div>
                            <div class="stat-trend">patrons per hour</div>
                        </div>
                    </div>
                    <div class="col-md-2 col-6">
                        <div class="stat-card">
                            <div class="stat-icon"><i class="fas fa-hourglass-half"></i></div>
                            <div class="stat-value"><asp:Literal ID="litAvgStay" runat="server" Text="0m" /></div>
                            <div class="stat-label">Avg. Stay Duration</div>
                        </div>
                    </div>
                    <div class="col-md-2 col-6">
                        <div class="stat-card">
                            <div class="stat-icon"><i class="fas fa-door-open"></i></div>
                            <div class="stat-value"><asp:Literal ID="litTotalEntries" runat="server" Text="0" /></div>
                            <div class="stat-label">Total Entries Today</div>
                        </div>
                    </div>
                    <div class="col-md-2 col-6">
                        <div class="stat-card">
                            <div class="stat-icon"><i class="fas fa-clock"></i></div>
                            <div class="stat-value"><asp:Literal ID="litPeakTime" runat="server" Text="--:--" /></div>
                            <div class="stat-label">Peak Hour Time</div>
                        </div>
                    </div>
                </div>

                <!-- Bootstrap Tabs with Icons & Active Status -->
                <ul class="nav nav-tabs custom-tabs" id="monitorTabs" role="tablist">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active" id="log-tab" data-bs-toggle="tab" data-bs-target="#logPane" type="button" role="tab" aria-controls="logPane" aria-selected="true">
                            <i class="fas fa-table-list"></i> Live Attendance Log
                        </button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link" id="chart-tab" data-bs-toggle="tab" data-bs-target="#chartPane" type="button" role="tab" aria-controls="chartPane" aria-selected="false">
                            <i class="fas fa-chart-line"></i> Hourly Traffic
                        </button>
                    </li>
                </ul>

                <div class="tab-content" id="monitorTabsContent">
                    <!-- Tab 1: Live Attendance Log -->
                    <div class="tab-pane fade show active" id="logPane" role="tabpanel" aria-labelledby="log-tab">
                        <div class="table-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-3">
                                <h3 class="mb-0"><i class="fas fa-table-list"></i> Live Entry/Exit Log</h3>
                                <div class="search-box d-flex gap-2">
                                    <asp:TextBox ID="txtSearch" runat="server" placeholder="Search by name, ID, or purpose..." />
                                    <asp:LinkButton ID="btnSearch" runat="server" OnClick="btnSearch_Click" CssClass="btn-search">
                                        <i class="fas fa-search"></i> Search
                                    </asp:LinkButton>
                                    <asp:LinkButton ID="btnExport" runat="server" OnClick="btnExport_Click" CssClass="btn-export">
                                        <i class="fas fa-download"></i> Export
                                    </asp:LinkButton>
                                    <asp:LinkButton ID="btnRefreshStats" runat="server" OnClick="btnRefresh_Click" CssClass="btn-refresh">
                                        <i class="fas fa-sync-alt"></i> Refresh
                                    </asp:LinkButton>
                                </div>
                            </div>
                            <div style="overflow-x: auto;">
                                <asp:GridView ID="gvAttendance" runat="server" AutoGenerateColumns="False" CssClass="attendance-table"
                                    GridLines="None" AllowPaging="True" PageSize="10" OnPageIndexChanging="gvAttendance_PageIndexChanging"
                                    PagerStyle-CssClass="pagination justify-content-end mt-3">
                                    <Columns>
                                        <asp:BoundField DataField="PatronName" HeaderText="Patron Name" />
                                        <asp:BoundField DataField="IDNumber" HeaderText="ID Number" />
                                        <asp:BoundField DataField="UserType" HeaderText="Type" />
                                        <asp:BoundField DataField="Purpose" HeaderText="Purpose" />
                                        <asp:BoundField DataField="TimeIn" HeaderText="Time In" />
                                        <asp:BoundField DataField="TimeOut" HeaderText="Time Out" />
                                        <asp:TemplateField HeaderText="Status">
                                            <ItemTemplate>
                                                <span class='status-<%# Eval("Status").ToString().ToLower() %>'>
                                                    <%# Eval("Status") %>
                                                </span>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                    <EmptyDataTemplate>
                                        <div class="no-data">
                                            <i class="fas fa-users-slash" style="font-size: 2rem;"></i>
                                            <p>No attendance records found</p>
                                        </div>
                                    </EmptyDataTemplate>
                                </asp:GridView>
                            </div>
                            <div class="table-footer">
                                <div class="entries-info">
                                    <asp:Literal ID="litEntriesInfo" runat="server" Text="No entries" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Tab 2: Hourly Traffic Chart (outside UpdatePanel to preserve canvas) -->
                    <div class="tab-pane fade" id="chartPane" role="tabpanel" aria-labelledby="chart-tab">
                        <div class="chart-card">
                            <div class="d-flex justify-content-between align-items-center flex-wrap mb-3">
                                <h3 class="mb-0"><i class="fas fa-chart-line"></i> Hourly Traffic Distribution</h3>
                                <div class="refresh-timer">
                                    <i class="fas fa-sync-alt"></i>
                                    <span>Auto-refresh: <span class="auto-refresh">30s</span></span>
                                </div>
                            </div>
                            <div class="chart-container">
                                <canvas id="hourlyChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>

        <!-- Timer for Auto-Refresh (triggers UpdatePanel) -->
        <asp:Timer ID="TimerRefresh" runat="server" Interval="30000" OnTick="TimerRefresh_Tick">
        </asp:Timer>
    </div>

    <!-- ==================== JAVASCRIPT BLOCKS ==================== -->
    <script type="text/javascript">
        // ========== 1. CHART VARIABLES & HELPERS ==========
        let hourlyChart = null;
        let chartRefreshInterval = null;

        // Helper to render or update the chart
        function renderHourlyChart(labels, data) {
            const ctx = document.getElementById('hourlyChart').getContext('2d');
            if (hourlyChart) {
                hourlyChart.destroy();
            }
            // Default empty dataset if no data
            if (!labels || labels.length === 0 || !data || data.length === 0) {
                const defaultLabels = [];
                const defaultData = [];
                for (let i = 7; i <= 21; i++) {
                    defaultLabels.push(i === 12 ? "12 PM" : (i < 12 ? i + " AM" : (i - 12) + " PM"));
                    defaultData.push(0);
                }
                labels = defaultLabels;
                data = defaultData;
            }
            hourlyChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Number of Entries',
                        data: data,
                        borderColor: '#1e3a8a',
                        backgroundColor: 'rgba(30, 58, 138, 0.1)',
                        borderWidth: 3,
                        fill: true,
                        tension: 0.4,
                        pointBackgroundColor: '#1e3a8a',
                        pointBorderColor: 'white',
                        pointBorderWidth: 2,
                        pointRadius: 5,
                        pointHoverRadius: 7
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        tooltip: { callbacks: { label: (ctx) => ctx.raw + ' entries' } }
                    },
                    scales: {
                        y: { beginAtZero: true, title: { display: true, text: 'Number of Entries' }, ticks: { stepSize: 1, precision: 0 } },
                        x: { title: { display: true, text: 'Time of Day' }, ticks: { rotation: 45, maxRotation: 45, minRotation: 45 } }
                    }
                }
            });
        }

        // ========== 2. LOAD CHART DATA VIA AJAX ==========
        function loadChartData() {
            console.log("Loading chart data...");
            const chartContainer = document.querySelector('.chart-container');
            if (chartContainer) chartContainer.style.opacity = '0.6';
            
            $.ajax({
                type: 'POST',
                url: 'AttendanceMonitor.aspx/GetHourlyChartData',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (response) {
                    if (chartContainer) chartContainer.style.opacity = '1';
                    if (response.d && response.d.labels && response.d.values) {
                        renderHourlyChart(response.d.labels, response.d.values);
                    } else {
                        renderHourlyChart(null, null);
                    }
                },
                error: function (xhr, status, error) {
                    console.error("Chart AJAX Error:", error);
                    if (chartContainer) chartContainer.style.opacity = '1';
                    renderHourlyChart(null, null);
                    Swal.fire({
                        icon: 'error', title: 'Data Load Error',
                        text: 'Failed to load chart data. Will retry automatically.',
                        toast: true, position: 'top-end', showConfirmButton: false, timer: 3000
                    });
                }
            });
        }

        // ========== 3. CHART INITIALIZATION & AUTO-REFRESH ==========
        function initChartAndAutoRefresh() {
            renderHourlyChart(null, null); // initial empty
            setTimeout(() => loadChartData(), 500);
            if (chartRefreshInterval) clearInterval(chartRefreshInterval);
            chartRefreshInterval = setInterval(() => {
                console.log("Auto-refreshing chart data...");
                loadChartData();
            }, 30000);
        }

        // ========== 4. TAB EVENT HANDLERS (fix Chart resize on show) ==========
        function handleTabEvents() {
            const chartTab = document.getElementById('chart-tab');
            if (chartTab) {
                chartTab.addEventListener('shown.bs.tab', function (event) {
                    if (hourlyChart) {
                        hourlyChart.resize();
                    } else {
                        loadChartData();
                    }
                });
            }
        }

        // ========== 5. SWEETALERT FOR EXPORT FEEDBACK ==========
        function bindExportNotification() {
            const exportBtn = document.getElementById('<%= btnExport.ClientID %>');
            if (exportBtn) {
                exportBtn.addEventListener('click', function (e) {
                    setTimeout(() => {
                        Swal.fire({
                            icon: 'success', title: 'Export Started',
                            text: 'Your report is being generated.', toast: true,
                            position: 'top-end', showConfirmButton: false, timer: 2000
                        });
                    }, 100);
                });
            }
        }

        // ========== 6. DOCUMENT READY INITIALIZATION ==========
        $(document).ready(function () {
            console.log("Document ready - initializing monitor with Bootstrap 5 tabs & chart");
            initChartAndAutoRefresh();
            handleTabEvents();
            bindExportNotification();
        });
    </script>
</asp:Content>