<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Analytics_PeakHours.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Dashboard.Analytics_PeakHours" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Peak Hours</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { background: transparent; padding: 15px; }
        .page-container { background: white; border-radius: 8px; padding: 15px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
        .table th { background: #f8f9fa; position: sticky; top: 0; z-index: 1; }
        .chart-container { position: relative; height: 300px; margin-top: 20px; }
        .badge-peak { background-color: #cce5ff; color: #004085; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="page-container">
            <h4 class="mb-3"><i class="fas fa-clock text-primary me-2"></i>Peak Hours - Library Attendance</h4>
            <p class="text-muted small">Analysis of entries (time_in) and exits (time_out) by hour of day.</p>

            <div class="row mb-4">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header bg-light">Entry Hours</div>
                        <div class="card-body">
                            <asp:GridView ID="gvEntries" runat="server" AutoGenerateColumns="False" CssClass="table table-sm table-hover" GridLines="None">
                                <Columns>
                                    <asp:BoundField DataField="Hour" HeaderText="Hour" />
                                    <asp:BoundField DataField="Count" HeaderText="Entries" />
                                </Columns>
                            </asp:GridView>
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header bg-light">Exit Hours</div>
                        <div class="card-body">
                            <asp:GridView ID="gvExits" runat="server" AutoGenerateColumns="False" CssClass="table table-sm table-hover" GridLines="None">
                                <Columns>
                                    <asp:BoundField DataField="Hour" HeaderText="Hour" />
                                    <asp:BoundField DataField="Count" HeaderText="Exits" />
                                </Columns>
                            </asp:GridView>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Combined Bar Chart -->
            <div class="card">
                <div class="card-header bg-light">Attendance Distribution by Hour</div>
                <div class="card-body">
                    <div class="chart-container">
                        <canvas id="peakChart"></canvas>
                    </div>
                </div>
            </div>

            <!-- Diagnostic Insights -->
            <div class="card mt-3">
                <div class="card-header bg-light">Diagnostic Insights</div>
                <div class="card-body">
                    <asp:Literal ID="litInsights" runat="server" />
                </div>
            </div>
        </div>
    </form>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Render chart using data from server-side
        function renderPeakChart(labels, entries, exits) {
            const ctx = document.getElementById('peakChart').getContext('2d');
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Entries (time_in)',
                            data: entries,
                            backgroundColor: 'rgba(54, 162, 235, 0.6)',
                            borderColor: 'rgba(54, 162, 235, 1)',
                            borderWidth: 1
                        },
                        {
                            label: 'Exits (time_out)',
                            data: exits,
                            backgroundColor: 'rgba(255, 159, 64, 0.6)',
                            borderColor: 'rgba(255, 159, 64, 1)',
                            borderWidth: 1
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { stepSize: 1 }
                        }
                    }
                }
            });
        }
    </script>
</body>
</html>