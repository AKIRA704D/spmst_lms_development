<%@ Page Title="Admin Dashboard" Language="C#" MasterPageFile="~/Users/MasterPage/Admin.Master" AutoEventWireup="true" CodeBehind="adminDashC.aspx.cs" Inherits="spmst_lms_development.Users.Admin.adminDashC" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        /* Internal CSS overrides for dashboard */
        .stat-card {
            background: white;
            border-radius: 0.75rem;
            padding: 1rem 1.25rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            border-left: 4px solid;
            transition: transform 0.2s;
        }
        .stat-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .stat-title { font-size: 0.7rem; text-transform: uppercase; color: #6c757d; letter-spacing: 0.5px; }
        .stat-value { font-size: 1.75rem; font-weight: 800; line-height: 1; }
        .border-left-blue { border-left-color: #1e3a8a; }
        .border-left-purple { border-left-color: #6366f1; }
        .border-left-orange { border-left-color: #f59e0b; }
        .border-left-gold { border-left-color: #d97706; }
        .border-left-green { border-left-color: #10b981; }
        .border-left-red { border-left-color: #ef4444; }
        .border-left-slate { border-left-color: #64748b; }
        .border-left-brown { border-left-color: #b45309; }
        .text-blue { color: #1e3a8a; }
        .text-purple { color: #6366f1; }
        .text-orange { color: #f59e0b; }
        .text-gold { color: #d97706; }
        .text-green { color: #10b981; }
        .text-red { color: #ef4444; }
        .text-slate { color: #64748b; }
        .text-brown { color: #b45309; }
        .dashboard-tabs .nav-link { color: #6c757d; border-bottom: 2px solid transparent; }
        .dashboard-tabs .nav-link.active { color: #0d6efd; border-bottom-color: #0d6efd; background: transparent; }
        .trends-card { background: white; border-radius: 0.75rem; padding: 1.5rem; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
        .chart-container { position: relative; height: 220px; width: 100%; margin-bottom: 1rem; }
        .waiting-badge { background-color: #feebc8; color: #c05621; font-size: 0.7rem; padding: 0.2rem 0.5rem; border-radius: 1rem; display: inline-block; }
        .icon-book-purple, .icon-book-green, .icon-book-blue, .icon-book-orange, .icon-book-red {
            width: 40px; height: 50px; border-radius: 6px;
            display: flex; align-items: center; justify-content: center;
            color: white;
        }
        .icon-book-purple { background-color: #9f7aea; }
        .icon-book-green { background-color: #38a169; }
        .icon-book-blue { background-color: #3182ce; }
        .icon-book-orange { background-color: #dd6b20; }
        .icon-book-red { background-color: #e53e3e; }
        iframe { width: 100%; border: none; background: transparent; }
    </style>

  <script>
      let charts = {};

      // ---------- Abbreviation Helper ----------
      function abbreviate(input, maxLength = 4) {
          if (!input || input.trim() === "") return "UNK";
          input = input.trim();

          const specialCases = {
              "unknown": "UNK",
              "faculty / non-student": "FNS"
          };
          const lower = input.toLowerCase();
          if (specialCases[lower]) return specialCases[lower];

          const cleanText = input.replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, "");
          const words = cleanText.split(/\s+/).filter(w => w.length > 0);

          if (words.length === 0) return "UNK";

          if (words.length === 1) {
              const word = words[0];
              return word.length <= maxLength ? word.toUpperCase() : word.substring(0, maxLength).toUpperCase();
          }

          const skipWords = new Set(["of", "and", "in", "for", "the", "to"]);
          let acronym = "";
          for (const w of words) {
              const lowerWord = w.toLowerCase();
              if (skipWords.has(lowerWord)) continue;
              if (w.length > 0) {
                  acronym += w[0].toUpperCase();
              }
          }
          return acronym.length > 0 ? acronym : "UNK";
      }

      // ---------- Dynamic Step Size ----------
      function getStepSize(maxValue) {
          if (maxValue === 0) return 1;
          let step = Math.ceil(maxValue / 8);
          if (step <= 5) return 5;
          if (step <= 10) return 10;
          if (step <= 20) return 20;
          if (step <= 50) return 50;
          return Math.ceil(step / 50) * 50;
      }

      // ---------- Dynamic Color Palette ----------
      function getColor(index, total) {
          const palette = [
              '#4e73df', '#1cc88a', '#36b9cc', '#f6c23e', '#e74a3b',
              '#6f42c1', '#fd7e14', '#20c997', '#0dcaf0', '#d63384',
              '#6c757d', '#198754', '#0d6efd', '#6610f2', '#d63384'
          ];
          return palette[index % palette.length];
      }

      // ---------- Main Render Function ----------
      function renderCharts(sectionData, subjectData, penaltyData, instData, progData) {
          const commonOptions = {
              responsive: true,
              maintainAspectRatio: true,
              plugins: {
                  legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } }
              }
          };

          function createChart(id, config) {
              if (charts[id]) charts[id].destroy();
              const ctx = document.getElementById(id);
              if (ctx) charts[id] = new Chart(ctx, config);
          }

          // Sections Doughnut
          if (sectionData && sectionData.labels) {
              const colors = sectionData.labels.map((_, i) => getColor(i, sectionData.labels.length));
              createChart('chartSections', {
                  type: 'doughnut',
                  data: {
                      labels: sectionData.labels,
                      datasets: [{
                          data: sectionData.values,
                          backgroundColor: colors,
                          borderColor: '#fff',
                          borderWidth: 2
                      }]
                  },
                  options: { cutout: '70%', ...commonOptions }
              });
          }

          // Subjects Doughnut
          if (subjectData && subjectData.labels) {
              const colors = subjectData.labels.map((_, i) => getColor(i + 3, subjectData.labels.length + 3));
              createChart('chartSubjects', {
                  type: 'doughnut',
                  data: {
                      labels: subjectData.labels,
                      datasets: [{
                          data: subjectData.values,
                          backgroundColor: colors,
                          borderColor: '#fff',
                          borderWidth: 2
                      }]
                  },
                  options: { cutout: '70%', ...commonOptions }
              });
          }

          // ---------- Penalty Breakdown (Bar) with amounts & counts ----------
          if (penaltyData && penaltyData.amounts && penaltyData.counts) {
              const labels = ['Damage', 'Lost', 'Overdue'];
              const amounts = penaltyData.amounts;
              const counts = penaltyData.counts;
              const colors = labels.map((_, i) => getColor(i, labels.length));
              const totalFines = amounts.reduce((a, b) => a + b, 0);
              const stepSize = totalFines >= 500 ? 100 : 50;

              createChart('chartFines', {
                  type: 'bar',
                  data: {
                      labels: labels,
                      datasets: [{
                          label: '₱ Amount',
                          data: amounts,
                          backgroundColor: colors,
                          borderRadius: 5
                      }]
                  },
                  options: {
                      ...commonOptions,
                      plugins: {
                          legend: { display: false },
                          tooltip: {
                              callbacks: {
                                  label: function (context) {
                                      const label = context.dataset.label || '';
                                      const value = context.raw;
                                      const count = counts[context.dataIndex];
                                      return label + ': ₱' + value + ' (' + count + ' copies)';
                                  }
                              }
                          }
                      },
                      scales: {
                          y: {
                              beginAtZero: true,
                              ticks: {
                                  stepSize: stepSize,
                                  callback: function (value) { return '₱' + value; }
                              }
                          }
                      }
                  }
              });
          }

          // ---------- Institutes (Horizontal Grouped Bars) ----------
          if (instData && instData.labels) {
              const maxVal = Math.max(
                  ...(instData.borrowed || []),
                  ...(instData.returned || []),
                  ...(instData.reserved || [])
              );
              const step = getStepSize(maxVal);
              const abbreviatedLabels = instData.labels.map(abbreviate);
              const roleData = instData.borrowedRoles || [];

              createChart('chartInstitutes', {
                  type: 'bar',
                  data: {
                      labels: abbreviatedLabels,
                      datasets: [
                          {
                              label: 'Borrowed',
                              data: instData.borrowed || [],
                              backgroundColor: getColor(0, 3)
                          },
                          {
                              label: 'Returned',
                              data: instData.returned || [],
                              backgroundColor: getColor(1, 3)
                          },
                          {
                              label: 'Reserved/Ready',
                              data: instData.reserved || [],
                              backgroundColor: getColor(2, 3)
                          }
                      ]
                  },
                  options: {
                      indexAxis: 'y',
                      ...commonOptions,
                      plugins: {
                          tooltip: {
                              callbacks: {
                                  label: function (context) {
                                      let label = context.dataset.label || '';
                                      let value = context.raw;
                                      let result = label + ': ' + value;
                                      if (context.datasetIndex === 0 && roleData && roleData[context.dataIndex]) {
                                          const r = roleData[context.dataIndex];
                                          result += ' (Student: ' + r.student + ', Faculty: ' + r.faculty + ', Staff: ' + r.staff + ')';
                                      }
                                      return result;
                                  }
                              }
                          }
                      },
                      scales: {
                          x: {
                              stacked: false,
                              beginAtZero: true,
                              ticks: {
                                  stepSize: step,
                                  callback: function (value) { return Number.isInteger(value) ? value : ''; }
                              }
                          },
                          y: {
                              stacked: false
                          }
                      }
                  }
              });
          }

          // ---------- Programs (Horizontal Grouped Bars) ----------
          if (progData && progData.labels) {
              const maxVal = Math.max(
                  ...(progData.borrowed || []),
                  ...(progData.returned || []),
                  ...(progData.reserved || [])
              );
              const step = getStepSize(maxVal);
              const abbreviatedLabels = progData.labels.map(abbreviate);
              const roleData = progData.borrowedRoles || [];

              createChart('chartPrograms', {
                  type: 'bar',
                  data: {
                      labels: abbreviatedLabels,
                      datasets: [
                          {
                              label: 'Borrowed',
                              data: progData.borrowed || [],
                              backgroundColor: getColor(3, 6)
                          },
                          {
                              label: 'Returned',
                              data: progData.returned || [],
                              backgroundColor: getColor(4, 6)
                          },
                          {
                              label: 'Reserved/Ready',
                              data: progData.reserved || [],
                              backgroundColor: getColor(5, 6)
                          }
                      ]
                  },
                  options: {
                      indexAxis: 'y',
                      ...commonOptions,
                      plugins: {
                          tooltip: {
                              callbacks: {
                                  label: function (context) {
                                      let label = context.dataset.label || '';
                                      let value = context.raw;
                                      let result = label + ': ' + value;
                                      if (context.datasetIndex === 0 && roleData && roleData[context.dataIndex]) {
                                          const r = roleData[context.dataIndex];
                                          result += ' (Student: ' + r.student + ', Faculty: ' + r.faculty + ', Staff: ' + r.staff + ')';
                                      }
                                      return result;
                                  }
                              }
                          }
                      },
                      scales: {
                          x: {
                              stacked: false,
                              beginAtZero: true,
                              ticks: {
                                  stepSize: step,
                                  callback: function (value) { return Number.isInteger(value) ? value : ''; }
                              }
                          },
                          y: {
                              stacked: false
                          }
                      }
                  }
              });
          }
      }

      // ---------- Descriptive and Diagnotics Tabs ----------
      function loadAnalytics(element) {
          // Remove active class from all tabs
          document.querySelectorAll('#analyticsTabs .nav-link').forEach(tab => tab.classList.remove('active'));
          // Add active class to the clicked tab
          element.classList.add('active');

          // Get the URL from the data attribute
          var url = element.getAttribute('data-url');
          // Update the iframe src
          var iframe = document.getElementById('<%= analyticsFrame.ClientID %>');
          if (iframe) {
              iframe.src = url;
          }
      }
  </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    
    <div class="container-fluid px-4 py-4">
        <!-- Stats Cards Row -->
        <div class="row g-3 mb-4">
            <div class="col-md-3"><div class="stat-card border-left-blue"><div class="stat-title">TOTAL FACULTY VISITS</div><div class="stat-value text-blue"><asp:Literal ID="litFacultyVisits" runat="server" Text="0" /></div></div></div>
            <div class="col-md-3"><div class="stat-card border-left-purple"><div class="stat-title">BOOK CIRCULATED</div><div class="stat-value text-purple"><asp:Literal ID="litCirculated" runat="server" Text="0" /></div></div></div>
            <div class="col-md-3"><div class="stat-card border-left-orange"><div class="stat-title">OVERDUE BOOKS</div><div class="stat-value text-orange"><asp:Literal ID="litOverdue" runat="server" Text="0" /></div></div></div>
            <div class="col-md-3"><div class="stat-card border-left-gold"><div class="stat-title">PENDING FINES</div><div class="stat-value text-gold">₱<asp:Literal ID="litPendingFines" runat="server" Text="0" /></div></div></div>
            <div class="col-md-3"><div class="stat-card border-left-green"><div class="stat-title">ACTIVE PATRONS</div><div class="stat-value text-green"><asp:Literal ID="litActivePatrons" runat="server" Text="0" /></div></div></div>
            <div class="col-md-3"><div class="stat-card border-left-red"><div class="stat-title">DAMAGE REPORTS</div><div class="stat-value text-red"><asp:Literal ID="litDamageFines" runat="server" Text="0" /></div></div></div>
            <div class="col-md-3"><div class="stat-card border-left-slate"><div class="stat-title">LOST BOOKS</div><div class="stat-value text-slate"><asp:Literal ID="litLostBooks" runat="server" Text="0" /></div></div></div>
            <div class="col-md-3"><div class="stat-card border-left-brown"><div class="stat-title">FINES COLLECTED</div><div class="stat-value text-brown">₱<asp:Literal ID="litFinesCollected" runat="server" Text="0" /></div></div></div>
        </div>

        <!-- Main Tabs (Circulation / Patrons / Attendance) -->
        <ul class="nav nav-tabs dashboard-tabs border-0 mb-4" id="mainTabs" role="tablist">
            <li class="nav-item"><button class="nav-link active" id="tabCirc" data-bs-toggle="tab" data-bs-target="#circPanel" type="button" role="tab">Circulation</button></li>
            <li class="nav-item"><button class="nav-link" id="tabPatron" data-bs-toggle="tab" data-bs-target="#patronPanel" type="button" role="tab">Patrons</button></li>
            <li class="nav-item"><button class="nav-link" id="tabAttend" data-bs-toggle="tab" data-bs-target="#attendPanel" type="button" role="tab">Attendance</button></li>
        </ul>

        <div class="tab-content" id="mainTabContent">
            <!-- Circulation Tab (original content) -->
            <div class="tab-pane fade show active" id="circPanel" role="tabpanel">
                <div class="trends-card mb-4">
                    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
                        <h5 class="fw-bold text-primary mb-0">Library Trends Overview</h5>
                        <div class="d-flex align-items-center gap-3 flex-wrap">
                            <div class="input-group input-group-sm w-auto"><span class="input-group-text">From</span><asp:TextBox ID="txtDateFrom" runat="server" TextMode="Date" CssClass="form-control" /></div>
                            <div class="input-group input-group-sm w-auto"><span class="input-group-text">To</span><asp:TextBox ID="txtDateTo" runat="server" TextMode="Date" CssClass="form-control" /></div>
                            <asp:LinkButton ID="btnFilter" runat="server" CssClass="btn btn-primary btn-sm" OnClick="btnFilter_Click"><i class="fas fa-filter"></i> Apply Filter</asp:LinkButton>
                        </div>
                    </div>
                    <div class="row g-4 mb-4">
                        <div class="col-lg-8 border-end">
                            <div class="row">
                                <div class="col-md-6 text-center"><h6 class="text-muted small fw-bold">TOP SECTIONS</h6><div class="chart-container"><canvas id="chartSections"></canvas></div></div>
                                <div class="col-md-6 text-center"><h6 class="text-muted small fw-bold">TOP SUBJECTS (DDC)</h6><div class="chart-container"><canvas id="chartSubjects"></canvas></div></div>
                            </div>
                        </div>
                        <div class="col-lg-4 text-center">
                            <h6 class="text-muted small fw-bold">PENALTY BREAKDOWN</h6>
                            <div style="height: 200px;"><canvas id="chartFines"></canvas></div>
                            <div class="mt-3 text-start px-3 small">
                                <div class="d-flex justify-content-between border-bottom pb-1"><span class="text-secondary">Overall Penalties (Base):</span><span class="fw-bold text-dark">₱<asp:Literal ID="litTotalPenalties" runat="server" /></span></div>
                                <div class="d-flex justify-content-between border-bottom py-1"><span class="text-secondary">Total Paid:</span><span class="fw-bold text-success">₱<asp:Literal ID="litTotalPaid" runat="server" /></span></div>
                                <div class="d-flex justify-content-between pt-1"><span class="text-secondary">Remaining Balance:</span><span class="fw-bold text-danger">₱<asp:Literal ID="litTotalBalance" runat="server" /></span></div>
                            </div>
                        </div>
                    </div>
                    <div class="pt-4 border-top">
                        <h6 class="text-muted small fw-bold mb-3">BORROWING DISTRIBUTION</h6>
                        <div class="row g-4">
                            <div class="col-md-6"><p class="text-center small text-muted">By Institute</p><div class="chart-container"><canvas id="chartInstitutes"></canvas></div></div>
                            <div class="col-md-6"><p class="text-center small text-muted">By Program</p><div class="chart-container"><canvas id="chartPrograms"></canvas></div></div>
                        </div>
                    </div>
                </div>

                <!-- Descriptive & Diagnostic Analytics Sub‑tabs -->
                <div class="trends-card mt-4">
                    <h4 class="mb-4">Descriptive and Diagnostic Analytics</h4>
                    <ul class="nav nav-pills mb-3" id="analyticsTabs">
                        <li class="nav-item">
                            <a href="#" class="nav-link" data-url="Analytics_Trending.aspx" onclick="loadAnalytics(this); return false;">Trending Books</a>
                        </li>
                        <li class="nav-item">
                            <a href="#" class="nav-link active" data-url="Analytics_LowCirc.aspx" onclick="loadAnalytics(this); return false;">Low Circulation</a>
                        </li>
                        <li class="nav-item">
                            <a href="#" class="nav-link" data-url="Analytics_PeakHours.aspx" onclick="loadAnalytics(this); return false;">Peak Hours</a>
                        </li>
                        <li class="nav-item">
                            <a href="#" class="nav-link" data-url="Analytics_OverduePatterns.aspx" onclick="loadAnalytics(this); return false;">Overdue Patterns</a>
                        </li>
                    </ul>

                    <!-- Single iframe – content will be loaded dynamically -->
                    <iframe id="analyticsFrame" runat="server" style="width:100%; height:450px; border:none;" src=""></iframe>
                </div>

                <!-- Top Borrowed Books -->
                <div class="card shadow-sm border-0 mt-4">
                    <div class="card-header bg-white d-flex justify-content-between align-items-center py-3"><h5 class="fw-bold text-primary mb-0">Top Borrowed Books</h5><asp:LinkButton ID="btnViewAllTop" runat="server" CssClass="btn btn-link small">View All</asp:LinkButton></div>
                    <div class="card-body p-3">
                        <asp:Repeater ID="rptrTopBooks" runat="server" OnItemDataBound="rptrTopBooks_ItemDataBound">
                            <ItemTemplate>
                                <div class="row align-items-center py-3 border-bottom">
                                    <div class="col-auto"><div class="text-muted small fw-bold me-2" style="width:25px;"><%# Container.ItemIndex + 1 %></div></div>
                                    <div class="col-auto"><div class='<%# GetBookIconClass(Container.ItemIndex) %>'><asp:Image ID="imgCover" runat="server" Visible="false" CssClass="w-100 h-100 object-fit-cover" /><asp:PlaceHolder ID="phDefaultIcon" runat="server"><i class="fas fa-book"></i></asp:PlaceHolder></div></div>
                                    <div class="col"><div class="fw-bold text-dark"><%# Eval("Title") %></div><div class="text-secondary small"><%# Eval("Author") %></div><span class="badge bg-light text-dark small"><%# Eval("Category") %></span></div>
                                    <div class="col-auto text-end"><div class="fw-bold text-dark fs-5"><%# Eval("Checkouts") %></div><div class="text-secondary small">checkouts</div><div class="waiting-badge mt-1"><i class="far fa-clock me-1"></i><%# Eval("Waiting") %> waiting</div></div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>
            </div>

            <!-- Patrons Tab (iframe to adminDashP.aspx) -->
            <div class="tab-pane fade" id="patronPanel" role="tabpanel">
                <div class="card shadow-sm border-0 p-0" style="height:85vh;">
                    <iframe src="adminDashPp.aspx" style="width:100%; height:100%; border:none; background:white;"></iframe>
                </div>
            </div>

            <!-- Attendance Tab (iframe to adminDashA.aspx) -->
            <div class="tab-pane fade" id="attendPanel" role="tabpanel">
                <div class="card shadow-sm border-0 p-0" style="height:85vh;">
                    <iframe src="adminDashAa.aspx" style="width:100%; height:100%; border:none; background:white;"></iframe>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</asp:Content>