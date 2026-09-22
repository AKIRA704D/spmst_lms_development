<%@ Page Title="Circulation Dashboard" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="CirDash.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Dashboard.CirDash" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <style>
        .stat-card {
            background: #fff;
            border-radius: .75rem;
            padding: 1rem 1.25rem;
            box-shadow: 0 2px 4px rgba(0,0,0,.05);
            border-left: 4px solid;
            transition: transform .2s;
        }

            .stat-card:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(0,0,0,.1);
            }

        .stat-title {
            font-size: .7rem;
            text-transform: uppercase;
            color: #6c757d;
            letter-spacing: .5px;
        }

        .stat-value {
            font-size: 1.75rem;
            font-weight: 800;
            line-height: 1;
        }

        .border-left-blue {
            border-left-color: #1e3a8a;
        }

        .border-left-purple {
            border-left-color: #6366f1;
        }

        .border-left-orange {
            border-left-color: #f59e0b;
        }

        .border-left-gold {
            border-left-color: #d97706;
        }

        .border-left-green {
            border-left-color: #10b981;
        }

        .border-left-red {
            border-left-color: #ef4444;
        }

        .border-left-slate {
            border-left-color: #64748b;
        }

        .border-left-brown {
            border-left-color: #b45309;
        }

        .text-blue {
            color: #1e3a8a;
        }

        .text-purple {
            color: #6366f1;
        }

        .text-orange {
            color: #f59e0b;
        }

        .text-gold {
            color: #d97706;
        }

        .text-green {
            color: #10b981;
        }

        .text-red {
            color: #ef4444;
        }

        .text-slate {
            color: #64748b;
        }

        .text-brown {
            color: #b45309;
        }

        .trends-card {
            background: #fff;
            border-radius: .75rem;
            padding: 1.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,.05);
        }

        .chart-container {
            position: relative;
            height: 220px;
            width: 100%;
            margin-bottom: 1rem;
        }

        .waiting-badge {
            background-color: #feebc8;
            color: #c05621;
            font-size: .7rem;
            padding: .2rem .5rem;
            border-radius: 1rem;
            display: inline-block;
        }

        .icon-book-purple, .icon-book-green, .icon-book-blue, .icon-book-orange, .icon-book-red {
            width: 40px;
            height: 50px;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }

        .icon-book-purple {
            background-color: #9f7aea;
        }

        .icon-book-green {
            background-color: #38a169;
        }

        .icon-book-blue {
            background-color: #3182ce;
        }

        .icon-book-orange {
            background-color: #dd6b20;
        }

        .icon-book-red {
            background-color: #e53e3e;
        }

        iframe {
            width: 100%;
            border: none;
            background: transparent;
        }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid px-4 py-4">
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="stat-card border-left-blue">
                    <div class="stat-title">TOTAL FACULTY VISITS</div>
                    <div class="stat-value text-blue">
                        <asp:Literal ID="litFacultyVisits" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card border-left-purple">
                    <div class="stat-title">BOOKS CIRCULATED</div>
                    <div class="stat-value text-purple">
                        <asp:Literal ID="litCirculated" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card border-left-orange">
                    <div class="stat-title">OVERDUE BOOKS</div>
                    <div class="stat-value text-orange">
                        <asp:Literal ID="litOverdue" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card border-left-gold">
                    <div class="stat-title">PENDING FINES</div>
                    <div class="stat-value text-gold">₱<asp:Literal ID="litPendingFines" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card border-left-green">
                    <div class="stat-title">ACTIVE PATRONS</div>
                    <div class="stat-value text-green">
                        <asp:Literal ID="litActivePatrons" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card border-left-red">
                    <div class="stat-title">DAMAGE REPORTS</div>
                    <div class="stat-value text-red">
                        <asp:Literal ID="litDamageFines" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card border-left-slate">
                    <div class="stat-title">LOST BOOKS</div>
                    <div class="stat-value text-slate">
                        <asp:Literal ID="litLostBooks" runat="server" Text="0" /></div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-card border-left-brown">
                    <div class="stat-title">FINES COLLECTED</div>
                    <div class="stat-value text-brown">₱<asp:Literal ID="litFinesCollected" runat="server" Text="0" /></div>
                </div>
            </div>
        </div>

        <div class="trends-card mb-4">
            <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
                <h5 class="fw-bold text-primary mb-0">Library Trends Overview</h5>
                <div class="d-flex align-items-center gap-3 flex-wrap">
                    <div class="input-group input-group-sm w-auto">
                        <span class="input-group-text">From</span>
                        <asp:TextBox ID="txtDateFrom" runat="server" TextMode="Date" CssClass="form-control" />
                    </div>
                    <div class="input-group input-group-sm w-auto">
                        <span class="input-group-text">To</span>
                        <asp:TextBox ID="txtDateTo" runat="server" TextMode="Date" CssClass="form-control" />
                    </div>
                    <asp:LinkButton ID="btnFilter" runat="server" CssClass="btn btn-primary btn-sm"
                        OnClick="btnFilter_Click"><i class="fas fa-filter"></i> Apply Filter</asp:LinkButton>
                </div>
            </div>

            <div class="row g-4 mb-4">
                <div class="col-lg-8 border-end">
                    <div class="row">
                        <div class="col-md-6 text-center">
                            <h6 class="text-muted small fw-bold">TOP SECTIONS</h6>
                            <div class="chart-container">
                                <canvas id="chartSections"></canvas>
                            </div>
                        </div>
                        <div class="col-md-6 text-center">
                            <h6 class="text-muted small fw-bold">TOP SUBJECTS (DDC)</h6>
                            <div class="chart-container">
                                <canvas id="chartSubjects"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4 text-center">
                    <h6 class="text-muted small fw-bold">PENALTY BREAKDOWN</h6>
                    <div style="height: 200px;">
                        <canvas id="chartFines"></canvas>
                    </div>
                    <div class="mt-3 text-start px-3 small">
                        <div class="d-flex justify-content-between border-bottom pb-1">
                            <span class="text-secondary">Overall Penalties:</span>
                            <span class="fw-bold text-dark">₱<asp:Literal ID="litTotalPenalties" runat="server" /></span>
                        </div>
                        <div class="d-flex justify-content-between border-bottom py-1">
                            <span class="text-secondary">Total Paid:</span>
                            <span class="fw-bold text-success">₱<asp:Literal ID="litTotalPaid" runat="server" /></span>
                        </div>
                        <div class="d-flex justify-content-between pt-1">
                            <span class="text-secondary">Remaining Balance:</span>
                            <span class="fw-bold text-danger">₱<asp:Literal ID="litTotalBalance" runat="server" /></span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="pt-4 border-top">
                <h6 class="text-muted small fw-bold mb-3">BORROWING DISTRIBUTION</h6>
                <div class="row g-4">
                    <div class="col-md-6">
                        <p class="text-center small text-muted">By Institute</p>
                        <div class="chart-container">
                            <canvas id="chartInstitutes"></canvas>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <p class="text-center small text-muted">By Program</p>
                        <div class="chart-container">
                            <canvas id="chartPrograms"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="trends-card mt-4">
            <h4 class="mb-4">Descriptive &amp; Diagnostic Analytics</h4>
            <ul class="nav nav-pills mb-3" id="analyticsTabs">
                <li class="nav-item"><a href="#" class="nav-link"
                    data-url="/Users/Admin/Dashboard/Analytics/Analytics_Trending.aspx"
                    onclick="loadAnalytics(this); return false;">Trending Books</a></li>

                <li class="nav-item"><a href="#" class="nav-link active"
                    data-url="/Users/Admin/Dashboard/Analytics/Analytics_LowCirc.aspx"
                    onclick="loadAnalytics(this); return false;">Low Circulation</a></li>

                <li class="nav-item"><a href="#" class="nav-link"
                    data-url="/Users/Admin/Dashboard/Analytics/Analytics_PeakHours.aspx"
                    onclick="loadAnalytics(this); return false;">Peak Hours</a></li>

                <li class="nav-item"><a href="#" class="nav-link"
                    data-url="/Users/Admin/Dashboard/Analytics/Analytics_OverduePatterns.aspx"
                    onclick="loadAnalytics(this); return false;">Overdue Patterns</a></li>
            </ul>
            <iframe id="analyticsFrame" runat="server"
                style="width: 100%; height: 450px; border: none;" src=""></iframe>
        </div>

        <div class="card shadow-sm border-0 mt-4">
            <div class="card-header bg-white d-flex justify-content-between align-items-center py-3">
                <h5 class="fw-bold text-primary mb-0">Top Borrowed Books</h5>
            </div>
            <div class="card-body p-3">
                <asp:Repeater ID="rptrTopBooks" runat="server"
                    OnItemDataBound="rptrTopBooks_ItemDataBound">
                    <ItemTemplate>
                        <div class="row align-items-center py-3 border-bottom">
                            <div class="col-auto">
                                <div class="text-muted small fw-bold me-2" style="width: 25px;">
                                    <%# Container.ItemIndex + 1 %>
                                </div>
                            </div>
                            <div class="col-auto">
                                <div class='<%# GetBookIconClass(Container.ItemIndex) %>'>
                                    <asp:Image ID="imgCover" runat="server" Visible="false"
                                        CssClass="w-100 h-100 object-fit-cover" />
                                    <asp:PlaceHolder ID="phDefaultIcon" runat="server">
                                        <i class="fas fa-book"></i></asp:PlaceHolder>
                                </div>
                            </div>
                            <div class="col">
                                <div class="fw-bold text-dark"><%# Eval("Title") %></div>
                                <div class="text-secondary small"><%# Eval("Author") %></div>
                                <span class="badge bg-light text-dark small"><%# Eval("Category") %></span>
                            </div>
                            <div class="col-auto text-end">
                                <div class="fw-bold text-dark fs-5"><%# Eval("Checkouts") %></div>
                                <div class="text-secondary small">checkouts</div>
                                <div class="waiting-badge mt-1">
                                    <i class="far fa-clock me-1"></i><%# Eval("Waiting") %> waiting
                                </div>
                            </div>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        let charts = {};

        function abbreviate(input, maxLength) {
            maxLength = maxLength || 4;
            if (!input || input.trim() === "") return "UNK";
            input = input.trim();
            const special = { "unknown": "UNK", "faculty / non-student": "FNS" };
            const lower = input.toLowerCase();
            if (special[lower]) return special[lower];

            const clean = input.replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, "");
            const words = clean.split(/\s+/).filter(function (w) { return w.length > 0; });
            if (words.length === 0) return "UNK";
            if (words.length === 1) {
                const w = words[0];
                return w.length <= maxLength ? w.toUpperCase() : w.substring(0, maxLength).toUpperCase();
            }
            const skip = { "of": 1, "and": 1, "in": 1, "for": 1, "the": 1, "to": 1 };
            let a = "";
            for (let i = 0; i < words.length; i++) {
                if (skip[words[i].toLowerCase()]) continue;
                a += words[i][0].toUpperCase();
            }
            return a.length > 0 ? a : "UNK";
        }

        function getStepSize(maxValue) {
            if (maxValue === 0) return 1;
            let s = Math.ceil(maxValue / 8);
            if (s <= 5) return 5;
            if (s <= 10) return 10;
            if (s <= 20) return 20;
            if (s <= 50) return 50;
            return Math.ceil(s / 50) * 50;
        }

        function getColor(i) {
            const p = ['#4e73df', '#1cc88a', '#36b9cc', '#f6c23e', '#e74a3b',
                '#6f42c1', '#fd7e14', '#20c997', '#0dcaf0', '#d63384',
                '#6c757d', '#198754', '#0d6efd', '#6610f2', '#d63384'];
            return p[i % p.length];
        }

        function renderCharts(sectionData, subjectData, penaltyData, instData, progData) {
            const commonOptions = {
                responsive: true, maintainAspectRatio: true,
                plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } } }
            };
            function create(id, config) {
                if (charts[id]) charts[id].destroy();
                const el = document.getElementById(id);
                if (el) charts[id] = new Chart(el, config);
            }

            if (sectionData && sectionData.labels) {
                create('chartSections', {
                    type: 'doughnut',
                    data: {
                        labels: sectionData.labels,
                        datasets: [{
                            data: sectionData.values,
                            backgroundColor: sectionData.labels.map(function (_, i) { return getColor(i); }),
                            borderColor: '#fff', borderWidth: 2
                        }]
                    },
                    options: Object.assign({ cutout: '70%' }, commonOptions)
                });
            }
            if (subjectData && subjectData.labels) {
                create('chartSubjects', {
                    type: 'doughnut',
                    data: {
                        labels: subjectData.labels,
                        datasets: [{
                            data: subjectData.values,
                            backgroundColor: subjectData.labels.map(function (_, i) { return getColor(i + 3); }),
                            borderColor: '#fff', borderWidth: 2
                        }]
                    },
                    options: Object.assign({ cutout: '70%' }, commonOptions)
                });
            }
            if (penaltyData && penaltyData.amounts) {
                const labels = ['Damage', 'Lost', 'Overdue'];
                const amounts = penaltyData.amounts;
                const counts = penaltyData.counts;
                const total = amounts.reduce(function (a, b) { return a + b; }, 0);
                const step = total >= 500 ? 100 : 50;
                create('chartFines', {
                    type: 'bar',
                    data: {
                        labels: labels,
                        datasets: [{
                            label: '₱ Amount', data: amounts,
                            backgroundColor: labels.map(function (_, i) { return getColor(i); }),
                            borderRadius: 5
                        }]
                    },
                    options: Object.assign({}, commonOptions, {
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                callbacks: {
                                    label: function (ctx) {
                                        return (ctx.dataset.label || '') + ': ₱' + ctx.raw +
                                            ' (' + counts[ctx.dataIndex] + ' copies)';
                                    }
                                }
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                ticks: { stepSize: step, callback: function (v) { return '₱' + v; } }
                            }
                        }
                    })
                });
            }
            if (instData && instData.labels) {
                const maxVal = Math.max.apply(null,
                    (instData.borrowed || []).concat(instData.returned || [], instData.reserved || []));
                const step = getStepSize(maxVal);
                create('chartInstitutes', {
                    type: 'bar',
                    data: {
                        labels: instData.labels.map(function (l) { return abbreviate(l); }),
                        datasets: [
                            { label: 'Borrowed', data: instData.borrowed || [], backgroundColor: getColor(0) },
                            { label: 'Returned', data: instData.returned || [], backgroundColor: getColor(1) },
                            { label: 'Reserved/Ready', data: instData.reserved || [], backgroundColor: getColor(2) }
                        ]
                    },
                    options: Object.assign({ indexAxis: 'y' }, commonOptions, {
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: function (ctx) {
                                        let res = (ctx.dataset.label || '') + ': ' + ctx.raw;
                                        if (ctx.datasetIndex === 0 && instData.borrowedRoles &&
                                            instData.borrowedRoles[ctx.dataIndex]) {
                                            const r = instData.borrowedRoles[ctx.dataIndex];
                                            res += ' (Student:' + r.student + ', Faculty:' + r.faculty + ', Staff:' + r.staff + ')';
                                        }
                                        return res;
                                    }
                                }
                            }
                        },
                        scales: {
                            x: {
                                beginAtZero: true,
                                ticks: { stepSize: step, callback: function (v) { return Number.isInteger(v) ? v : ''; } }
                            },
                            y: { stacked: false }
                        }
                    })
                });
            }
            if (progData && progData.labels) {
                const maxVal = Math.max.apply(null,
                    (progData.borrowed || []).concat(progData.returned || [], progData.reserved || []));
                const step = getStepSize(maxVal);
                create('chartPrograms', {
                    type: 'bar',
                    data: {
                        labels: progData.labels.map(function (l) { return abbreviate(l); }),
                        datasets: [
                            { label: 'Borrowed', data: progData.borrowed || [], backgroundColor: getColor(3) },
                            { label: 'Returned', data: progData.returned || [], backgroundColor: getColor(4) },
                            { label: 'Reserved/Ready', data: progData.reserved || [], backgroundColor: getColor(5) }
                        ]
                    },
                    options: Object.assign({ indexAxis: 'y' }, commonOptions, {
                        plugins: {
                            tooltip: {
                                callbacks: {
                                    label: function (ctx) {
                                        let res = (ctx.dataset.label || '') + ': ' + ctx.raw;
                                        if (ctx.datasetIndex === 0 && progData.borrowedRoles &&
                                            progData.borrowedRoles[ctx.dataIndex]) {
                                            const r = progData.borrowedRoles[ctx.dataIndex];
                                            res += ' (Student:' + r.student + ', Faculty:' + r.faculty + ', Staff:' + r.staff + ')';
                                        }
                                        return res;
                                    }
                                }
                            }
                        },
                        scales: {
                            x: {
                                beginAtZero: true,
                                ticks: { stepSize: step, callback: function (v) { return Number.isInteger(v) ? v : ''; } }
                            },
                            y: { stacked: false }
                        }
                    })
                });
            }
        }

        function loadAnalytics(el) {
            document.querySelectorAll('#analyticsTabs .nav-link').forEach(function (t) {
                t.classList.remove('active');
            });
            el.classList.add('active');
            var url = el.getAttribute('data-url');
            var frame = document.getElementById('<%= analyticsFrame.ClientID %>');
            if (frame) frame.src = url;
        }
    </script>
</asp:Content>
