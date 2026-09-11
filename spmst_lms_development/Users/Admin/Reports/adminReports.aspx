<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="adminReports.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Reports.adminReports" %>

<asp:Content ID="Content3" ContentPlaceHolderID="head" runat="server">

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>

    <style>
        :root {
            --primary: #0000C0;
            --primary-dark: #000080;
            --primary-light: #E6E9FF;
            --success: #059669;
            --success-light: #D1FAE5;
            --danger: #DC2626;
            --danger-light: #FEE2E2;
            --warning: #D97706;
            --warning-light: #FEF3C7;
            --gray-50: #F8FAFC;
            --gray-100: #F1F5F9;
            --gray-200: #E2E8F0;
            --gray-300: #CBD5E1;
            --gray-400: #94A3B8;
            --gray-500: #64748B;
            --gray-600: #475569;
            --gray-700: #334155;
            --gray-800: #1E293B;
            --gray-900: #0F172A;
            --shadow: 0 1px 3px rgba(0,0,0,.1), 0 1px 2px rgba(0,0,0,.06);
            --shadow-md: 0 4px 6px -1px rgba(0,0,0,.1), 0 2px 4px -1px rgba(0,0,0,.06);
            --transition: all .25s cubic-bezier(.4,0,.2,1);
        }

        .lr-dash {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }

        .lr-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
            margin-bottom: 20px;
            padding: 16px 20px;
            background: #fff;
            border: 1px solid var(--gray-200);
            box-shadow: var(--shadow);
        }
        .lr-header-left { display: flex; align-items: center; gap: 14px; }
        .lr-header-left .icon-wrap {
            width: 40px; height: 40px;
            background: var(--primary-light);
            display: flex; align-items: center; justify-content: center;
            font-size: 18px; color: var(--primary);
            border: 1px solid var(--gray-200);
        }
        .lr-header-left h1 { font-size: 20px; font-weight: 800; color: var(--gray-900); margin: 0; }
        .lr-header-left .subtitle { font-size: 13px; color: var(--gray-500); margin: 2px 0 0 0; }
        .lr-header-right { display: flex; gap: 10px; flex-wrap: wrap; }

        .lr-btn {
            display: inline-flex; align-items: center; gap: 8px;
            padding: 8px 16px; font-size: 13px; font-weight: 600; font-family: inherit;
            cursor: pointer; border: 1px solid transparent; text-decoration: none;
            transition: var(--transition);
        }
        .lr-btn-primary { background: var(--primary); color: #fff; border-color: var(--primary); }
        .lr-btn-primary:hover { background: var(--primary-dark); border-color: var(--primary-dark); }
        .lr-btn-outline { background: #fff; color: var(--gray-700); border-color: var(--gray-300); }
        .lr-btn-outline:hover { background: var(--gray-100); }

        .lr-kpi-row {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 14px;
            margin-bottom: 20px;
        }
        .lr-kpi-card {
            background: #fff;
            border: 1px solid var(--gray-200);
            box-shadow: var(--shadow);
            padding: 16px;
        }
        .lr-kpi-card .lbl { font-size: 11.5px; font-weight: 600; color: var(--gray-500); text-transform: uppercase; letter-spacing: .3px; }
        .lr-kpi-card .val { font-size: 24px; font-weight: 800; color: var(--gray-900); margin-top: 6px; }
        .lr-kpi-card .val.accent { color: var(--primary); }
        .lr-kpi-card .val.warn { color: var(--warning); }
        .lr-kpi-card .val.danger { color: var(--danger); }

        .lr-panel {
            background: #fff;
            border: 1px solid var(--gray-200);
            box-shadow: var(--shadow);
            overflow: hidden;
        }
        .lr-panel-header {
            display: flex; align-items: center; justify-content: space-between;
            flex-wrap: wrap; gap: 8px;
            padding: 12px 16px; border-bottom: 1px solid var(--gray-200); background: var(--gray-50);
        }
        .lr-panel-header h3 { margin: 0; font-size: 14px; font-weight: 700; color: var(--gray-800); display: flex; align-items: center; gap: 8px; }
        .lr-panel-header h3 i { color: var(--primary); }
        .lr-panel-body { padding: 16px; }

        .lr-pill {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 3px 12px; font-size: 11px; font-weight: 600;
            background: var(--primary); color: #fff; border: 1px solid var(--primary);
        }

        .lr-row2 { display: grid; grid-template-columns: 1.4fr 1fr; gap: 16px; margin-bottom: 16px; }
        .lr-row3 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }

        .lr-chart-wrap { position: relative; height: 240px; width: 100%; }
        .lr-donut-wrap { position: relative; width: 100%; max-width: 220px; margin: 0 auto; aspect-ratio: 1/1; }

        .lr-group-select {
            padding: 4px 28px 4px 10px; border: 1px solid var(--gray-300); font-size: 12px; font-weight: 600;
            background: #fff; color: var(--gray-700); cursor: pointer; font-family: inherit; appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%2364748b' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
            background-repeat: no-repeat; background-position: right 8px center;
        }

        .lr-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
        .lr-table th {
            text-align: left; padding: 8px 10px; background: var(--gray-50); color: var(--gray-600);
            font-weight: 700; font-size: 11px; text-transform: uppercase; letter-spacing: .3px;
            border-bottom: 1px solid var(--gray-200);
        }
        .lr-table td { padding: 9px 10px; border-bottom: 1px solid var(--gray-100); color: var(--gray-800); }
        .lr-table tr:last-child td { border-bottom: none; }
        .lr-badge-danger { color: var(--danger); font-weight: 700; }
        .lr-badge-role {
            font-size: 10.5px; font-weight: 700; text-transform: uppercase;
            padding: 2px 8px; background: var(--primary-light); color: var(--primary);
        }

        .lr-empty-row { text-align: center; color: var(--gray-500); padding: 30px 0; font-size: 13px; }
        .lr-empty-row i { display: block; font-size: 32px; color: var(--gray-300); margin-bottom: 8px; }

        @media (max-width: 1200px) { .lr-kpi-row { grid-template-columns: repeat(3, 1fr); } }
        @media (max-width: 900px) {
            .lr-row2, .lr-row3 { grid-template-columns: 1fr; }
            .lr-kpi-row { grid-template-columns: repeat(2, 1fr); }
        }
    </style>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">
    <div class="lr-dash">

        <!-- Header -->
        <div class="lr-header">
            <div class="lr-header-left">
                <div class="icon-wrap"><i class="fa-solid fa-chart-line"></i></div>
                <div>
                    <h1>Library Reports &amp; Analytics</h1>
                    <p class="subtitle">Circulation and catalog overview &mdash; spamast_lmsv2</p>
                </div>
            </div>
            <div class="lr-header-right">
                <button type="button" class="lr-btn lr-btn-outline" onclick="location.reload();">
                    <i class="fa-solid fa-rotate"></i> Refresh
                </button>
                <asp:Button ID="btnExportOverdueCsv" runat="server" CssClass="lr-btn lr-btn-primary"
                    Text="Export Overdue CSV" OnClick="btnExportOverdueCsv_Click" />
            </div>
        </div>

        <!-- KPI cards -->
        <div class="lr-kpi-row">
            <div class="lr-kpi-card">
                <div class="lbl">Total Titles</div>
                <div class="val"><%= TotalTitles %></div>
            </div>
            <div class="lr-kpi-card">
                <div class="lbl">Total Copies</div>
                <div class="val"><%= TotalCopies %></div>
            </div>
            <div class="lr-kpi-card">
                <div class="lbl">Available Copies</div>
                <div class="val accent"><%= AvailableCopies %></div>
            </div>
            <div class="lr-kpi-card">
                <div class="lbl">Currently Borrowed</div>
                <div class="val"><%= CurrentlyBorrowed %></div>
            </div>
            <div class="lr-kpi-card">
                <div class="lbl">Overdue</div>
                <div class="val danger"><%= OverdueCount %></div>
            </div>
            <div class="lr-kpi-card">
                <div class="lbl">Outstanding Fines</div>
                <div class="val warn">&#8369;<%= OutstandingFines.ToString("N2") %></div>
            </div>
        </div>

        <!-- Row: Circulation trend + status donut -->
        <div class="lr-row2">
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-chart-area"></i> Circulation Trend</h3>
                    <select id="trendGroupSelect" class="lr-group-select">
                        <option value="daily">Last 30 Days</option>
                        <option value="weekly">Last 12 Weeks</option>
                        <option value="monthly">Last 12 Months</option>
                    </select>
                </div>
                <div class="lr-panel-body">
                    <div class="lr-chart-wrap"><canvas id="trendChart"></canvas></div>
                </div>
            </div>
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-circle-half-stroke"></i> Transaction Status</h3>
                    <span class="lr-pill" id="statusBadge">0 total</span>
                </div>
                <div class="lr-panel-body">
                    <div class="lr-donut-wrap"><canvas id="statusDonut"></canvas></div>
                </div>
            </div>
        </div>

        <!-- Row: Top titles + genre mix -->
        <div class="lr-row3">
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-fire"></i> Top Borrowed Titles</h3>
                </div>
                <div class="lr-panel-body">
                    <div class="lr-chart-wrap"><canvas id="topTitlesChart"></canvas></div>
                </div>
            </div>
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-layer-group"></i> Catalog by Genre</h3>
                </div>
                <div class="lr-panel-body">
                    <div class="lr-chart-wrap"><canvas id="genreChart"></canvas></div>
                </div>
            </div>
        </div>

        <!-- Row: Fine status + item condition -->
        <div class="lr-row3">
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-sack-dollar"></i> Fine Status</h3>
                </div>
                <div class="lr-panel-body">
                    <div class="lr-donut-wrap"><canvas id="fineDonut"></canvas></div>
                </div>
            </div>
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-book-open-reader"></i> Item Condition</h3>
                </div>
                <div class="lr-panel-body">
                    <div class="lr-chart-wrap"><canvas id="conditionChart"></canvas></div>
                </div>
            </div>
        </div>

        <!-- Row: Overdue list + top borrowers -->
        <div class="lr-row3">
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-triangle-exclamation"></i> Overdue Items</h3>
                </div>
                <div class="lr-panel-body">
                    <asp:Panel ID="pnlOverdueEmpty" runat="server" Visible="false">
                        <div class="lr-empty-row"><i class="fa-solid fa-circle-check"></i>No overdue items right now.</div>
                    </asp:Panel>
                    <table class="lr-table">
                        <thead>
                            <tr>
                                <th>Borrower</th>
                                <th>Title</th>
                                <th>Due Date</th>
                                <th>Days Overdue</th>
                                <th>Balance</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptOverdue" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><%# Eval("BorrowerName") %></td>
                                        <td><%# Eval("Title") %></td>
                                        <td><%# Eval("DueDate") %></td>
                                        <td class="lr-badge-danger"><%# Eval("DaysOverdue") %> d</td>
                                        <td>&#8369;<%# Eval("Balance", "{0:N2}") %></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="lr-panel">
                <div class="lr-panel-header">
                    <h3><i class="fa-solid fa-user-group"></i> Most Active Borrowers</h3>
                </div>
                <div class="lr-panel-body">
                    <asp:Panel ID="pnlBorrowersEmpty" runat="server" Visible="false">
                        <div class="lr-empty-row"><i class="fa-solid fa-user-slash"></i>No borrowing activity yet.</div>
                    </asp:Panel>
                    <table class="lr-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Role</th>
                                <th>Total Borrows</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptTopBorrowers" runat="server">
                                <ItemTemplate>
                                    <tr>
                                        <td><%# Eval("Name") %></td>
                                        <td><span class="lr-badge-role"><%# Eval("Role") %></span></td>
                                        <td><%# Eval("TotalBorrows") %></td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    </div>

    <!-- Server-rendered JSON payload consumed by the charts below -->
    <script type="application/json" id="reportDataJson"><asp:Literal ID="litReportDataJson" runat="server" /></script>

    <script>
        (function () {
            var reportData = {};
            try {
                reportData = JSON.parse(document.getElementById("reportDataJson").textContent || "{}");
            } catch (e) {
                reportData = {};
            }

            var charts = {};
            function destroyChart(id) { if (charts[id]) { charts[id].destroy(); charts[id] = null; } }
            var palette = ['#0000C0', '#3B82F6', '#059669', '#D97706', '#DC2626', '#8B5CF6', '#0EA5E9', '#EC4899', '#64748B', '#16A34A'];

            function emptyState(canvasId, iconClass, message) {
                var canvas = document.getElementById(canvasId);
                if (!canvas) return;
                canvas.parentElement.innerHTML =
                    '<div class="lr-empty-row"><i class="' + iconClass + '"></i>' + message + '</div>';
            }

            // ===== Circulation Trend =====
            var currentGroup = "daily";
            function renderTrend(group) {
                var series = (reportData.trend && reportData.trend[group]) || [];
                if (series.length === 0) { emptyState("trendChart", "fa-solid fa-chart-area", "No circulation activity in this period."); return; }
                var canvas = document.getElementById("trendChart");
                if (!canvas) return;
                destroyChart("trendChart");
                charts.trendChart = new Chart(canvas.getContext("2d"), {
                    type: "line",
                    data: {
                        labels: series.map(function (s) { return s.label; }),
                        datasets: [{
                            label: "Borrows",
                            data: series.map(function (s) { return s.count; }),
                            borderColor: "#0000C0",
                            backgroundColor: "rgba(0,0,192,.08)",
                            fill: true,
                            tension: 0.3,
                            pointRadius: 3
                        }]
                    },
                    options: {
                        responsive: true, maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: {
                            y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: "rgba(0,0,0,.06)" } },
                            x: { grid: { display: false }, ticks: { font: { size: 10 }, maxRotation: 45 } }
                        }
                    }
                });
            }

            // ===== Status donut =====
            function renderStatusDonut() {
                var data = reportData.statusBreakdown || [];
                var total = data.reduce(function (s, d) { return s + d.count; }, 0);
                document.getElementById("statusBadge").textContent = total + (total === 1 ? " total" : " total");
                if (data.length === 0) { emptyState("statusDonut", "fa-solid fa-circle-half-stroke", "No transaction data yet."); return; }
                var canvas = document.getElementById("statusDonut");
                destroyChart("statusDonut");
                charts.statusDonut = new Chart(canvas.getContext("2d"), {
                    type: "doughnut",
                    data: {
                        labels: data.map(function (d) { return d.label; }),
                        datasets: [{ data: data.map(function (d) { return d.count; }), backgroundColor: palette }]
                    },
                    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: "bottom", labels: { boxWidth: 10, font: { size: 11 } } } } }
                });
            }

            // ===== Top titles bar =====
            function renderTopTitles() {
                var data = reportData.topTitles || [];
                if (data.length === 0) { emptyState("topTitlesChart", "fa-solid fa-fire", "No borrowing history yet."); return; }
                var canvas = document.getElementById("topTitlesChart");
                destroyChart("topTitlesChart");
                charts.topTitlesChart = new Chart(canvas.getContext("2d"), {
                    type: "bar",
                    data: {
                        labels: data.map(function (d) { return d.title; }),
                        datasets: [{ data: data.map(function (d) { return d.count; }), backgroundColor: "#0000C0", borderRadius: 0, maxBarThickness: 30 }]
                    },
                    options: {
                        indexAxis: "y", responsive: true, maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: { x: { beginAtZero: true, ticks: { precision: 0 } }, y: { ticks: { font: { size: 10 } } } }
                    }
                });
            }

            // ===== Genre chart =====
            function renderGenre() {
                var data = reportData.genreBreakdown || [];
                if (data.length === 0) { emptyState("genreChart", "fa-solid fa-layer-group", "No catalog data yet."); return; }
                var canvas = document.getElementById("genreChart");
                destroyChart("genreChart");
                charts.genreChart = new Chart(canvas.getContext("2d"), {
                    type: "bar",
                    data: {
                        labels: data.map(function (d) { return d.label; }),
                        datasets: [{ data: data.map(function (d) { return d.count; }), backgroundColor: palette, borderRadius: 0, maxBarThickness: 30 }]
                    },
                    options: {
                        responsive: true, maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: { y: { beginAtZero: true, ticks: { precision: 0 } }, x: { ticks: { font: { size: 9 }, maxRotation: 45 } } }
                    }
                });
            }

            // ===== Fine status donut =====
            function renderFine() {
                var data = reportData.fineStatus || [];
                if (data.length === 0) { emptyState("fineDonut", "fa-solid fa-sack-dollar", "No fines recorded yet."); return; }
                var canvas = document.getElementById("fineDonut");
                destroyChart("fineDonut");
                charts.fineDonut = new Chart(canvas.getContext("2d"), {
                    type: "doughnut",
                    data: {
                        labels: data.map(function (d) { return d.label; }),
                        datasets: [{ data: data.map(function (d) { return d.amount; }), backgroundColor: ["#DC2626", "#D97706", "#059669"] }]
                    },
                    options: {
                        responsive: true, maintainAspectRatio: false,
                        plugins: {
                            legend: { position: "bottom", labels: { boxWidth: 10, font: { size: 11 } } },
                            tooltip: { callbacks: { label: function (ctx) { return ctx.label + ": \u20B1" + ctx.parsed.toFixed(2); } } }
                        }
                    }
                });
            }

            // ===== Condition chart =====
            function renderCondition() {
                var data = reportData.conditionBreakdown || [];
                if (data.length === 0) { emptyState("conditionChart", "fa-solid fa-book-open-reader", "No item copies recorded yet."); return; }
                var canvas = document.getElementById("conditionChart");
                destroyChart("conditionChart");
                charts.conditionChart = new Chart(canvas.getContext("2d"), {
                    type: "bar",
                    data: {
                        labels: data.map(function (d) { return d.label; }),
                        datasets: [{ data: data.map(function (d) { return d.count; }), backgroundColor: "#0000C0", borderRadius: 0, maxBarThickness: 36 }]
                    },
                    options: {
                        responsive: true, maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: { y: { beginAtZero: true, ticks: { precision: 0 } }, x: { grid: { display: false } } }
                    }
                });
            }

            document.getElementById("trendGroupSelect").addEventListener("change", function () {
                currentGroup = this.value;
                renderTrend(currentGroup);
            });

            renderTrend(currentGroup);
            renderStatusDonut();
            renderTopTitles();
            renderGenre();
            renderFine();
            renderCondition();
        })();
    </script>
</asp:Content>
