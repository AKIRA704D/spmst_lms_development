﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="adminDashPp.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Dashboard.adminDashPp" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Patron Analytics - LMSA</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        /* ===== SPAMAST Universal Theme ===== */
        :root {
            --sp-green-900: #0b3d2c;
            --sp-green-800: #0f452d;
            --sp-green-700: #14532d;
            --sp-green-600: #1b7a3d;
            --sp-gold:      #d4a017;
            --sp-gold-200:  #e4b94a;
            --sp-paper:     #f8faf7;
            --sp-line:      #dfe7e0;
            --sp-ink:       #1f2d24;
            --sp-danger:    #c0392b;
        }

        body {
            background-color: transparent;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: var(--sp-ink);
            margin: 0;
        }

        .progress { background-color: #e9ecef; height: 10px; border-radius: 10px; }
        .rounded-card { border-radius: 20px; border: 1px solid var(--sp-line); }

        .table thead th {
            font-weight: 600; font-size: 0.75rem; color: #888;
            text-transform: uppercase; border-top: none;
        }
        .badge-unpaid {
            background-color: #fdecea; color: var(--sp-danger);
            border: 1px solid var(--sp-danger); padding: 5px 10px;
        }
        .border-end { border-right: 1px solid #dee2e6 !important; }

        .chart-container { position: relative; height: 160px; width: 160px; margin: auto; }

        /* SPAMAST overrides */
        .bg-primary { background-color: var(--sp-green-700) !important; }
        .bg-success { background-color: var(--sp-green-600) !important; }
        .bg-warning { background-color: var(--sp-gold) !important; }
        .bg-info    { background-color: #4a9e6a !important; }
        .bg-danger  { background-color: var(--sp-danger) !important; }
        .text-success { color: var(--sp-green-600) !important; }
        .btn-light  { background-color: #f1f5f1; border-color: var(--sp-line); }

        @media (max-width: 767.98px) {
            .rounded-card { border-radius: 12px; }
            .table { font-size: 0.8rem; }
            .table thead th { font-size: 0.7rem; }
            .chart-container { height: 130px; width: 130px; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server" />

        <div class="container-fluid py-3 py-md-4 px-3 px-md-4">

            <!-- Patron Activity Overview -->
            <div class="card shadow-sm border-0 rounded-card mb-4">
                <div class="card-body p-3 p-md-4">
                    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                        <h5 class="fw-bold mb-0" style="color:var(--sp-green-700);">Patron Activity Overview</h5>
                        <div class="d-flex gap-2">
                            <button type="button" class="btn btn-outline-secondary btn-sm rounded-pill px-3" onclick="alert('Filter coming soon')">
                                <i class="fas fa-filter me-1"></i>FILTER
                            </button>
                            <button type="button" class="btn btn-outline-secondary btn-sm rounded-pill px-3" onclick="alert('Export coming soon')">
                                <i class="fas fa-file-export me-1"></i>EXPORT
                            </button>
                        </div>
                    </div>

                    <div class="row g-4 mb-4">
                        <div class="col-md-6 border-md-end">
                            <h6 class="small fw-bold mb-3" style="color:var(--sp-green-600);">Top Programs</h6>
                            <asp:Repeater ID="rptPrograms" runat="server">
                                <ItemTemplate>
                                    <div class="mb-3">
                                        <div class="d-flex justify-content-between mb-1">
                                            <span class="small fw-bold"><%# Eval("course") %></span>
                                            <span class="small text-muted"><%# Eval("Percentage") %>%</span>
                                        </div>
                                        <div class="progress">
                                            <div class='<%# "progress-bar " + GetProgressColor(Container.ItemIndex) %>'
                                                role="progressbar" style='<%# "width: " + Eval("Percentage") + "%" %>'>
                                            </div>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                        <div class="col-md-6">
                            <h6 class="small fw-bold mb-3" style="color:var(--sp-green-600);">Top Institutes</h6>
                            <asp:Repeater ID="rptInstitutes" runat="server">
                                <ItemTemplate>
                                    <div class="mb-3">
                                        <div class="d-flex justify-content-between mb-1">
                                            <span class="small fw-bold"><%# Eval("institute") %></span>
                                            <span class="small text-muted"><%# Eval("Percentage") %>%</span>
                                        </div>
                                        <div class="progress">
                                            <div class='<%# "progress-bar " + GetProgressColor(Container.ItemIndex + 2) %>'
                                                role="progressbar" style='<%# "width: " + Eval("Percentage") + "%" %>'>
                                            </div>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                    </div>

                    <div class="row g-4 pt-3 border-top">
                        <div class="col-md-6 border-md-end">
                            <h6 class="small fw-bold mb-3" style="color:var(--sp-green-600);">Patron Distribution</h6>
                            <div class="d-flex align-items-center flex-wrap justify-content-center justify-content-md-start">
                                <div class="me-md-4 mb-3 mb-md-0">
                                    <div class="mb-2"><span class="badge p-2 me-2" style="background-color:var(--sp-green-700)!important;">&nbsp;</span><small>Faculty</small></div>
                                    <div><span class="badge p-2 me-2" style="background-color:var(--sp-green-600)!important;">&nbsp;</span><small>Student</small></div>
                                </div>
                                <div class="chart-container">
                                    <canvas id="patronDistChart"></canvas>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <h6 class="small fw-bold mb-3" style="color:var(--sp-green-600);">Gender Distribution</h6>
                            <div class="d-flex align-items-center flex-wrap justify-content-center justify-content-md-start">
                                <div class="me-md-4 mb-3 mb-md-0">
                                    <div class="mb-2"><span class="badge p-2 me-2" style="background-color:var(--sp-green-600)!important;">&nbsp;</span><small>Male</small></div>
                                    <div><span class="badge p-2 me-2" style="background-color:var(--sp-gold)!important;">&nbsp;</span><small>Female</small></div>
                                </div>
                                <div class="chart-container">
                                    <canvas id="genderDistChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Penalty Tracking -->
            <div class="card shadow-sm border-0 rounded-card">
                <div class="card-body p-3 p-md-4">
                    <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
                        <h5 class="fw-bold mb-0" style="color:var(--sp-green-700);">Penalty Tracking</h5>
                        <asp:UpdatePanel ID="upnlPenalties" runat="server" UpdateMode="Conditional">
                            <ContentTemplate>
                                <div class="d-flex gap-2 align-items-center">
                                    <div class="input-group input-group-sm" style="width: 250px; max-width:100%;">
                                        <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control rounded-start-pill ps-3"
                                            placeholder="Search name or ID..." AutoPostBack="true" OnTextChanged="txtSearch_TextChanged" />
                                        <span class="input-group-text bg-white rounded-end-pill border-start-0 text-muted">
                                            <i class="fas fa-search"></i>
                                        </span>
                                    </div>
                                </div>
                            </ContentTemplate>
                        </asp:UpdatePanel>
                    </div>

                    <asp:UpdatePanel ID="upnlGridView" runat="server" UpdateMode="Conditional">
                        <ContentTemplate>
                            <div class="table-responsive">
                                <asp:GridView ID="gvPenalties" runat="server" AutoGenerateColumns="False"
                                    CssClass="table table-hover border-top align-middle" GridLines="None" ShowHeaderWhenEmpty="true">
                                    <Columns>
                                        <asp:BoundField DataField="PenaltyDate" HeaderText="Date" DataFormatString="{0:MM.dd.yyyy}" />
                                        <asp:TemplateField HeaderText="Patron Details">
                                            <ItemTemplate>
                                                <div class="fw-bold"><%# Eval("FullName") %></div>
                                                <small class="text-muted"><%# Eval("PatronID") %></small>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:BoundField DataField="Program" HeaderText="Program" />
                                        <asp:TemplateField HeaderText="Book Title">
                                            <ItemTemplate>
                                                <div class="text-truncate" style="max-width: 180px;"><%# Eval("BookTitle") %></div>
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
                            <asp:AsyncPostBackTrigger ControlID="txtSearch" EventName="TextChanged" />
                        </Triggers>
                    </asp:UpdatePanel>
                </div>
            </div>
        </div>

        <asp:Literal ID="litChartData" runat="server"></asp:Literal>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            let chartData = { patron: [0, 0], gender: [0, 0] };
            const dataElement = document.getElementById('chartDataJSON');
            if (dataElement) {
                try { chartData = JSON.parse(dataElement.textContent); } catch (e) { console.error(e); }
            }

            const options = {
                responsive: true, maintainAspectRatio: false, cutout: '75%',
                plugins: { legend: { display: false } }
            };

            const patronCtx = document.getElementById('patronDistChart');
            if (patronCtx) {
                new Chart(patronCtx, {
                    type: 'doughnut',
                    data: {
                        labels: ['Faculty', 'Student'],
                        datasets: [{ data: chartData.patron, backgroundColor: ['#14532d', '#1b7a3d'], borderWidth: 0 }]
                    },
                    options: options
                });
            }

            const genderCtx = document.getElementById('genderDistChart');
            if (genderCtx) {
                new Chart(genderCtx, {
                    type: 'doughnut',
                    data: {
                        labels: ['Male', 'Female'],
                        datasets: [{ data: chartData.gender, backgroundColor: ['#2e7d32', '#d4a017'], borderWidth: 0 }]
                    },
                    options: options
                });
            }
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>