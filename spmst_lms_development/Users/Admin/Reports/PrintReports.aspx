<%@ Page Title="Print Report" Language="C#" AutoEventWireup="true" CodeBehind="PrintReports.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Reports.PrintReports" %>
<!DOCTYPE html>
<html>
<head runat="server">
    <title>Print Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
    <style>
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; color: #1a1a1a; margin: 0; background: #F0F0F0; }
        .pr-toolbar { position: sticky; top: 0; background: #fff; border-bottom: 1px solid #E5E7EB; padding: 12px 24px; display: flex; justify-content: space-between; align-items: center; gap: 10px; z-index: 10; }
        .pr-btn { display: inline-flex; align-items: center; gap: 6px; padding: 8px 14px; font-size: 13px; font-weight: 600; background: #fff; cursor: pointer; border: 1.5px solid #0000C0; color: #0000C0; text-decoration: none; }
        .pr-btn:hover { background: #0000C0; color: #fff; }
        .pr-btn-primary { background: #0000C0; color: #fff; }
        .pr-btn-primary:hover { background: #0000a0; }
        .pr-sheet { max-width: 900px; margin: 24px auto; background: #fff; padding: 36px 42px; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
        .pr-title { font-size: 24px; font-weight: 700; margin: 0 0 4px 0; }
        .pr-meta { font-size: 12px; color: #6B7280; margin: 0 0 24px 0; border-bottom: 2px solid #0000C0; padding-bottom: 14px; }
        .pr-section { margin-bottom: 28px; page-break-inside: avoid; }
        .pr-section h2 { font-size: 15px; font-weight: 700; color: #0000C0; border-bottom: 1px solid #E6E9FF; padding-bottom: 6px; margin: 0 0 10px 0; }
        .pr-chart-wrap { position: relative; height: 260px; width: 100%; margin-bottom: 12px; }
        .pr-table-scroll { overflow-x: auto; border: 1px solid #B7B7B7; }
        table.pr-table { width: 100%; border-collapse: collapse; font-size: 11.5px; background: #fff; }
        table.pr-table th { text-align: left; padding: 5px 8px; background: #F2F2F2; color: #111; font-weight: 700; border: 1px solid #B7B7B7; white-space: nowrap; }
        table.pr-table td { padding: 4px 8px; border: 1px solid #D9D9D9; white-space: nowrap; }
        table.pr-table td.wrap { white-space: normal; min-width: 140px; max-width: 340px; word-break: break-word; overflow-wrap: break-word; }
        table.pr-table td.num, table.pr-table th.num { text-align: right; font-variant-numeric: tabular-nums; }
        table.pr-table tbody tr:nth-child(even) { background: #F7F9FF; }
        .pr-resource-thumb { width: 26px; height: 26px; object-fit: cover; border: 1px solid #D9D9D9; vertical-align: middle; }
        .pr-empty { text-align: center; color: #6B7280; font-size: 13px; padding: 60px 20px; }

        .pr-profile { display: flex; gap: 20px; flex-wrap: wrap; }
        .pr-profile-photo { width: 150px; height: 150px; object-fit: cover; border: 1px solid #E5E7EB; background: #E6E9FF; flex-shrink: 0; }
        .pr-profile-info { flex: 1; min-width: 240px; }
        .pr-profile-name { font-size: 16px; font-weight: 700; margin: 0 0 8px 0; }
        .pr-profile-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 16px; font-size: 12px; }
        .pr-profile-grid dt { color: #6B7280; font-weight: 600; margin: 0; }
        .pr-profile-grid dd { margin: 1px 0 6px 0; }
        .pr-profile-stats { display: flex; gap: 20px; margin-top: 10px; padding-top: 10px; border-top: 1px solid #F3F4F6; }
        .pr-profile-stat { text-align: center; }
        .pr-profile-stat .num { font-size: 16px; font-weight: 700; color: #0000C0; }
        .pr-profile-stat .lbl { font-size: 10px; color: #6B7280; }

        .pr-resource-profile { display: flex; flex-direction: column; gap: 6px; }
        .pr-resource-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px 14px; font-size: 12px; }
        .pr-resource-grid dt { color: #6B7280; font-weight: 600; margin: 0; }
        .pr-resource-grid dd { margin: 1px 0 6px 0; }
        .pr-resource-gallery { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 4px; }
        .pr-resource-gallery img { width: 130px; height: 130px; object-fit: cover; border: 1px solid #D9D9D9; }
        .pr-profile-grid dd, .pr-resource-grid dd { word-break: break-word; overflow-wrap: break-word; }
        .pr-copy-status { display: inline-block; padding: 1px 7px; font-size: 9.5px; font-weight: 700; text-transform: uppercase; letter-spacing: .03em; }
        .pr-copy-status.available { background: #DCFCE7; color: #166534; }
        .pr-copy-status.borrowed { background: #FEF3C7; color: #92400E; }
        .pr-copy-status.reserved { background: #DBEAFE; color: #1E40AF; }
        .pr-copy-status.damage, .pr-copy-status.lost { background: #FEE2E2; color: #991B1B; }
        .pr-signature-block { display: flex; gap: 40px; flex-wrap: wrap; margin-top: 40px; padding-top: 10px; }
        .pr-signature-col { flex: 1 1 220px; min-width: 200px; text-align: center; }
        .pr-signature-fill { height: 50px; display: flex; align-items: flex-end; justify-content: center; font-size: 13px; font-weight: 600; color: #1a1a1a; padding-bottom: 4px; word-break: break-word; }
        .pr-signature-line { border-top: 1.5px solid #1a1a1a; margin-bottom: 6px; }
        .pr-signature-label { font-size: 12px; font-weight: 700; color: #1a1a1a; }
        table.pr-table td.narrow, table.pr-table th.narrow { width: 1%; white-space: nowrap; text-align: center; }

        @media print {
            body { background: #fff; }
            .pr-toolbar { display: none; }
            .pr-sheet { box-shadow: none; margin: 0; max-width: 100%; padding: 0; }
            .pr-section { page-break-inside: avoid; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="pr-toolbar">
            <a class="pr-btn" href="~/Users/Admin/Reports/generateReports.aspx" runat="server">&larr; Back to Builder</a>
            <button type="button" class="pr-btn pr-btn-primary" id="btnDoPrint">Print / Save as PDF</button>
        </div>
        <div class="pr-sheet" id="prSheet">
            <div class="pr-empty" id="prEmpty">Loading report…</div>
        </div>
    </form>

    <script>
        (function () {
            "use strict";
            var API = "GetReports.ashx";
            var sheet = document.getElementById("prSheet");

            var PALETTES = {
                blue: ["#0000C0", "#5C6BFF", "#99B3FF", "#3A4DB0", "#0F2A8C"],
                colorblind: ["#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9"]
            };

            function escapeHtml(v) {
                return String(v == null ? "" : v).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            }

            function api(action, params) {
                params = params || {};
                params.action = action;
                var qs = Object.keys(params).map(function (k) {
                    return encodeURIComponent(k) + "=" + encodeURIComponent(params[k]);
                }).join("&");
                return fetch(API + "?" + qs).then(function (res) {
                    if (!res.ok) {
                        return res.json().catch(function () { return { error: "Request failed (" + res.status + ")" }; })
                            .then(function (data) {
                                throw new Error(data.error || "Request failed (" + res.status + ")");
                            });
                    }
                    return res.json();
                });
            }

            function buildExcelTable(columns, rows) {
                var colDefs = columns.map(function (c) {
                    if (typeof c === 'string') return { label: c, numeric: false, wrap: false, narrow: false, allowHtml: false };
                    return c;
                });

                var head = '<tr>' + colDefs.map(function (c) {
                    var classes = [];
                    if (c.numeric) classes.push('num');
                    if (c.narrow) classes.push('narrow');
                    return '<th' + (classes.length ? ' class="' + classes.join(' ') + '"' : '') + '>' + escapeHtml(c.label) + '</th>';
                }).join('') + '</tr>';

                var body;
                if (rows.length) {
                    body = rows.map(function (r) {
                        return '<tr>' + r.map(function (cellHtml, ci) {
                            var classes = [];
                            if (colDefs[ci] && colDefs[ci].numeric) classes.push('num');
                            if (colDefs[ci] && colDefs[ci].wrap) classes.push('wrap');
                            if (colDefs[ci] && colDefs[ci].narrow) classes.push('narrow');
                            var cellContent = (colDefs[ci] && colDefs[ci].allowHtml) ? cellHtml : escapeHtml(cellHtml);
                            return '<td' + (classes.length ? ' class="' + classes.join(' ') + '"' : '') + '>' + cellContent + '</td>';
                        }).join('') + '</tr>';
                    }).join('');
                } else {
                    body = '<tr><td colspan="' + columns.length + '" style="text-align:center;color:#6B7280;">No data available.</td></tr>';
                }
                return '<div class="pr-table-scroll"><table class="pr-table"><thead>' + head + '</thead><tbody>' + body + '</tbody></table></div>';
            }

            function renderTable(data) {
                var colDefs = data.columns.map(function (c) {
                    if (c === 'Cover') return { label: c, numeric: false, wrap: false, narrow: true, allowHtml: true };
                    var isNumeric = /count|checkouts|amount|collected|copies|borrowed|days overdue/i.test(c);
                    var isShort = /^(status|type|year|pub\. year|gender|role|campus|call number|isbn|issn)$/i.test(c);
                    return { label: c, numeric: isNumeric, wrap: !isNumeric && !isShort, narrow: false, allowHtml: false };
                });
                var rows = data.rows.map(function (r) { return r.map(function (c) { return c; }); });
                return buildExcelTable(colDefs, rows);
            }

            function renderChart(canvas, data, palette) {
                var labels = data.rows.map(function (r) { return r[0]; });
                var values = data.rows.map(function (r) { return parseFloat(r[r.length - 1]) || 0; });
                var type = data.chartType === "pie" ? "pie" : (data.chartType === "line" ? "line" : "bar");
                var dataset;
                if (type === "pie") {
                    dataset = { data: values, backgroundColor: labels.map(function (_, i) { return palette[i % palette.length]; }) };
                } else if (type === "line") {
                    dataset = { data: values, borderColor: palette[0], backgroundColor: palette[0], tension: .3, fill: false, pointRadius: 3 };
                } else {
                    dataset = { data: values, backgroundColor: palette[0], maxBarThickness: 40, borderRadius: 0 };
                }
                new Chart(canvas.getContext("2d"), {
                    type: type,
                    data: { labels: labels, datasets: [dataset] },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        animation: false,
                        plugins: { legend: { display: type === "pie" } },
                        scales: type === "pie" ? {} : { y: { beginAtZero: true, ticks: { precision: 0 } } }
                    }
                });
            }

            function renderResourcesBorrowedTable(resources) {
                var columns = [
                    { label: 'Cover', allowHtml: true, narrow: true },
                    { label: 'Title', wrap: true },
                    { label: 'Author', wrap: true },
                    { label: 'Genre' },
                    { label: 'Call Number' },
                    { label: 'Times Borrowed', numeric: true }
                ];
                var rows = resources.map(function (r) {
                    var coverHtml = r.coverUrl ? '<img class="pr-resource-thumb" src="' + escapeHtml(r.coverUrl) + '" alt="" />' : '';
                    return [
                        coverHtml,
                        escapeHtml(r.title),
                        escapeHtml(r.author),
                        escapeHtml(r.genre),
                        escapeHtml(r.callNumber),
                        escapeHtml(r.timesBorrowed)
                    ];
                });
                return buildExcelTable(columns, rows);
            }

            function copyStatusClass(status) {
                var s = (status || "").toLowerCase();
                if (s === "available") return "available";
                if (s === "borrowed") return "borrowed";
                if (s === "reserved") return "reserved";
                if (s === "damage" || s === "lost") return s;
                return "";
            }

            function renderResourceCopiesTable(copies) {
                var columns = [
                    { label: 'Accession No.' },
                    { label: 'Campus', wrap: true },
                    { label: 'Location', wrap: true },
                    { label: 'Status', allowHtml: true }
                ];
                var rows = (copies || []).map(function (c) {
                    return [
                        escapeHtml(c.accessionNumber),
                        escapeHtml(c.campus),
                        escapeHtml(c.location),
                        '<span class="pr-copy-status ' + copyStatusClass(c.status) + '">' + escapeHtml(c.status) + '</span>'
                    ];
                });
                return buildExcelTable(columns, rows);
            }

            function renderResourceProfile(r) {
                var imagesHtml = r.coverUrl
                    ? '<div class="pr-resource-gallery"><img src="' + escapeHtml(r.coverUrl) + '" alt="Cover image" /></div>'
                    : '<p style="color:#6B7280;">No cover image available.</p>';

                var descriptionHtml = r.description ? '<p style="margin-top:8px; font-size:12px; color:#1a1a1a;">' + escapeHtml(r.description) + '</p>' : '';

                return '<div class="pr-resource-profile">' +
                    '<div class="pr-resource-grid">' +
                    '<dt>Author</dt><dd>' + escapeHtml(r.author || '-') + '</dd>' +
                    '<dt>Publisher</dt><dd>' + escapeHtml(r.publisher || '-') + '</dd>' +
                    '<dt>Item Type</dt><dd>' + escapeHtml(r.itemType || '-') + '</dd>' +
                    '<dt>Genre</dt><dd>' + escapeHtml(r.genre || '-') + '</dd>' +
                    '<dt>Call Number</dt><dd>' + escapeHtml(r.callNumber || '-') + '</dd>' +
                    '<dt>ISBN / ISSN</dt><dd>' + escapeHtml(r.isbnIssn || '-') + '</dd>' +
                    '<dt>Edition</dt><dd>' + escapeHtml(r.edition || '-') + '</dd>' +
                    '<dt>Publication Year</dt><dd>' + escapeHtml(r.pubYear || '-') + '</dd>' +
                    '<dt>Total Copies</dt><dd>' + escapeHtml(r.totalCopies || '0') + '</dd>' +
                    '<dt>Copies Available</dt><dd>' + escapeHtml(r.copiesAvailable || '0') + '</dd>' +
                    '<dt>Times Borrowed</dt><dd>' + escapeHtml(r.timesBorrowed || '0') + '</dd>' +
                    '</div>' +
                    descriptionHtml +
                    '<div style="margin-top:8px;"><strong>Cover</strong></div>' +
                    imagesHtml +
                    '<h4 style="font-size:12.5px; margin:12px 0 6px;">Item Copies</h4>' +
                    renderResourceCopiesTable(r.copies) +
                    '</div>';
            }

            function renderTransactionRecordsTable(records) {
                var columns = [
                    { label: 'Borrow Date' },
                    { label: 'Due Date' },
                    { label: 'Return Date' },
                    { label: 'Status' },
                    { label: 'Copy (Accession No.)', wrap: true },
                    { label: 'Fine', numeric: true }
                ];
                var rows = records.map(function (r) {
                    return [
                        escapeHtml(r.borrowDate),
                        escapeHtml(r.dueDate),
                        escapeHtml(r.returnDate),
                        escapeHtml(r.status),
                        escapeHtml(r.accessionNumber),
                        escapeHtml(r.fineAmount)
                    ];
                });
                return buildExcelTable(columns, rows);
            }

            function renderProfile(p) {
                var dateRangeText = 'This Record Covers Borrow Dates From ' + escapeHtml(p.filterDateFrom || '') + ' to ' + escapeHtml(p.filterDateTo || '');

                return '<div class="pr-profile">' +
                    '<img class="pr-profile-photo" src="' + escapeHtml(p.photoUrl) + '" alt="Photo of ' + escapeHtml(p.fullName) + '" />' +
                    '<div class="pr-profile-info">' +
                    '<p class="pr-profile-name">' + escapeHtml(p.fullName) + '</p>' +
                    '<dl class="pr-profile-grid">' +
                    '<dt>Role</dt><dd>' + escapeHtml(p.role) + '</dd>' +
                    '<dt>Gender</dt><dd>' + escapeHtml(p.gender) + '</dd>' +
                    '<dt>Contact No.</dt><dd>' + escapeHtml(p.contact) + '</dd>' +
                    '<dt>Email</dt><dd>' + escapeHtml(p.email) + '</dd>' +
                    '<dt>Institute / Dept.</dt><dd>' + escapeHtml(p.institute) + '</dd>' +
                    '<dt>Course / Section</dt><dd>' + escapeHtml(p.courseSection) + '</dd>' +
                    '<dt>Registered On</dt><dd>' + escapeHtml(p.recordedOn) + '</dd>' +
                    '</dl>' +
                    '<div class="pr-profile-stats">' +
                    '<div class="pr-profile-stat"><div class="num">' + escapeHtml(p.loanCount) + '</div><div class="lbl">Total Checkouts</div></div>' +
                    '<div class="pr-profile-stat"><div class="num">&#8369;' + escapeHtml(p.totalFinesPaid) + '</div><div class="lbl">Fines Paid</div></div>' +
                    '<div class="pr-profile-stat"><div class="num">' + escapeHtml(p.lastBorrowDate) + '</div><div class="lbl">Last Borrow Date</div></div>' +
                    '</div>' +
                    '</div>' +
                    '</div>' +
                    '<p style="font-size:11px; color:#6B7280; margin:14px 0 8px;">' + dateRangeText + '</p>' +
                    '<h4 style="font-size:12.5px; margin:10px 0 6px;">Resources Borrowed</h4>' +
                    renderResourcesBorrowedTable(p.resourcesBorrowed || []) +
                    '<h4 style="font-size:12.5px; margin:14px 0 6px;">Transaction Records</h4>' +
                    renderTransactionRecordsTable(p.transactionRecords || []);
            }

            function renderSignatureBlock(adminName) {
                return '<div class="pr-signature-block">' +
                    '<div class="pr-signature-col">' +
                    '<div class="pr-signature-fill">' + escapeHtml(adminName || '') + '</div>' +
                    '<div class="pr-signature-line"></div>' +
                    '<div class="pr-signature-label">Made by</div>' +
                    '</div>' +
                    '<div class="pr-signature-col">' +
                    '<div class="pr-signature-fill">&nbsp;</div>' +
                    '<div class="pr-signature-line"></div>' +
                    '<div class="pr-signature-label">Approved by</div>' +
                    '</div>' +
                    '</div>';
            }

            var raw = null;
            try { raw = sessionStorage.getItem("grReportConfig"); } catch (e) { /* ignore */ }

            if (!raw) {
                sheet.innerHTML = '<div class="pr-empty">No report is ready to print yet. Go back to the builder, click <strong>Generate Preview</strong>, then <strong>Print Report</strong>.</div>';
                return;
            }

            var config;
            try { config = JSON.parse(raw); } catch (e) {
                sheet.innerHTML = '<div class="pr-empty">The saved report could not be read. Please regenerate it from the builder.</div>';
                return;
            }

            var palette = PALETTES[config.palette] || PALETTES.blue;

            Promise.all(config.items.map(function (it) {
                if (it.type === "borrower") return api("borrower_detail", { id: it.borrowerId, statuses: (it.statuses || []).join(","), dateFrom: it.dateFrom || "", dateTo: it.dateTo || "" });
                if (it.type === "resource") return api("resource_detail", { id: it.resourceId });
                return api("data", { query: it.key });
            }))
                .then(function (results) {
                    var generatedAt = results.length ? results[0].generatedAt : "";
                    var html = '<p class="pr-title">' + escapeHtml(config.title) + '</p>' +
                        '<p class="pr-meta">' + (config.showTimestamp ? "Generated on " + escapeHtml(generatedAt) + " &middot; " : "") + 'Showing library-wide circulation and catalog data.</p>';
                    config.items.forEach(function (item, i) {
                        var isBorrower = item.type === "borrower";
                        var isResource = item.type === "resource";
                        var heading = isBorrower ? "Borrower Profile" : (isResource ? "Resource Details" : escapeHtml(item.label));
                        html += '<div class="pr-section">' +
                            '<h2>' + heading + '</h2>' +
                            (isBorrower
                                ? renderProfile(results[i])
                                : (isResource
                                    ? renderResourceProfile(results[i])
                                    : (((item.mode === "chart" || item.mode === "both") && item.chartType !== "none"
                                        ? '<div class="pr-chart-wrap"><canvas id="prChart' + i + '"></canvas></div>' : '') +
                                        ((item.mode === "table" || item.mode === "both") ? renderTable(results[i]) : '')))) +
                            '</div>';
                    });
                    html += renderSignatureBlock(config.adminName);
                    sheet.innerHTML = html;

                    config.items.forEach(function (item, i) {
                        if (item.type !== "borrower" && item.type !== "resource" && (item.mode === "chart" || item.mode === "both") && item.chartType !== "none") {
                            var canvas = document.getElementById("prChart" + i);
                            if (canvas) renderChart(canvas, results[i], palette);
                        }
                    });
                })
                .catch(function (err) {
                    sheet.innerHTML = '<div class="pr-empty">Unable to load report data: ' + escapeHtml(err.message) + '</div>';
                });

            document.getElementById("btnDoPrint").addEventListener("click", function () {
                window.print();
            });
        })();
    </script>
</body>
</html>
