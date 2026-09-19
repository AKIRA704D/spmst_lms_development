<%@ Page Title="Generate Report" Language="C#" MasterPageFile="~/Users/MasterPage/admin.master" AutoEventWireup="true" CodeBehind="generateReports.aspx.cs" Inherits="spmst_lms_development.Users.Admin.Reports.generateReports" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
    
    <style>
        /* ===== CSS Variables ===== */
        :root {
            --primary: #0000C0;
            --primary-dark: #000080;
            --primary-light: #E6E9FF;
            --primary-gradient: linear-gradient(135deg, #0000C0, #000080);
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
            --shadow-lg: 0 10px 15px -3px rgba(0,0,0,.1), 0 4px 6px -2px rgba(0,0,0,.05);
            --shadow-xl: 0 20px 25px -5px rgba(0,0,0,.1), 0 10px 10px -5px rgba(0,0,0,.05);
            --transition: all .25s cubic-bezier(.4,0,.2,1);
            --radius: 0px;
        }

        /* ===== Page Styles ===== */
        .gr-dash {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            padding: 24px;
            max-width: 1400px;
            margin: 0 auto;
            background: var(--gray-50);
            min-height: calc(100vh - 100px);
        }

        /* ===== Header ===== */
        .gr-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
            margin-bottom: 24px;
            padding: 16px 20px;
            background: #fff;
            border: 1px solid var(--gray-200);
            box-shadow: var(--shadow);
        }
        .gr-header-left {
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .gr-header-left .icon-wrap {
            width: 40px;
            height: 40px;
            background: var(--primary-light);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            color: var(--primary);
            border: 1px solid var(--gray-200);
            flex-shrink: 0;
        }
        .gr-header-left h1 {
            font-size: 20px;
            font-weight: 800;
            color: var(--gray-900);
            margin: 0;
            letter-spacing: -0.3px;
        }
        .gr-header-left .subtitle {
            font-size: 13px;
            color: var(--gray-500);
            margin: 2px 0 0 0;
            font-weight: 400;
        }
        .gr-header-right {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .gr-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 16px;
            font-size: 13px;
            font-weight: 600;
            font-family: inherit;
            cursor: pointer;
            border: 1px solid transparent;
            text-decoration: none;
            transition: var(--transition);
        }
        .gr-btn-primary {
            background: var(--primary);
            color: #fff;
            border-color: var(--primary);
        }
        .gr-btn-primary:hover {
            background: var(--primary-dark);
            border-color: var(--primary-dark);
        }
        .gr-btn-primary:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        .gr-btn-primary:disabled:hover {
            background: var(--primary);
        }
        .gr-btn-outline {
            background: #fff;
            color: var(--gray-700);
            border-color: var(--gray-300);
        }
        .gr-btn-outline:hover {
            background: var(--gray-100);
        }
        .gr-btn i {
            font-size: 14px;
        }
        .gr-btn .btn-text {
            display: inline;
        }

        /* ===== Error ===== */
        .gr-error {
            background: var(--danger-light);
            border: 1px solid var(--danger);
            color: var(--danger);
            padding: 12px 16px;
            margin-bottom: 16px;
            font-size: 13px;
            font-weight: 500;
            display: none;
            align-items: center;
            gap: 10px;
        }

        /* ===== Layout ===== */
        .gr-layout {
            position: relative;
            display: grid;
            grid-template-columns: 340px 1fr;
            gap: 16px;
            align-items: start;
            transition: grid-template-columns .22s ease;
        }

        /* ===== Sidebar ===== */
        .gr-panel {
            background: #fff;
            border: 1px solid var(--gray-200);
            box-shadow: var(--shadow);
        }
        .gr-sidebar {
            padding: 16px;
            position: sticky;
            top: 16px;
            overflow: hidden;
            transition: padding .22s ease, opacity .18s ease;
        }
        .gr-sidebar-title {
            font-size: 13px;
            font-weight: 700;
            color: var(--gray-800);
            margin: 0 0 10px 0;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .gr-sidebar-title i {
            color: var(--primary);
        }
        .gr-field-label {
            font-size: 11px;
            font-weight: 600;
            color: var(--gray-600);
            margin-bottom: 4px;
            display: block;
            text-transform: uppercase;
            letter-spacing: .04em;
        }
        .gr-input {
            width: 100%;
            border: 1px solid var(--gray-300);
            padding: 6px 10px;
            font-size: 13px;
            margin-bottom: 12px;
            font-family: inherit;
            color: var(--gray-800);
            transition: var(--transition);
        }
        .gr-input:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 2px rgba(0,0,192,.1);
        }
        .gr-section {
            border-top: 1px solid var(--gray-200);
            padding-top: 12px;
            margin-top: 12px;
        }
        .gr-section-title {
            font-size: 11px;
            font-weight: 700;
            color: var(--gray-600);
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: .04em;
        }

        /* ===== Query List ===== */
        .gr-query-list {
            max-height: 180px;
            overflow-y: auto;
            border: 1px solid var(--gray-200);
            padding: 6px;
        }
        .gr-query-list::-webkit-scrollbar { width: 3px; }
        .gr-query-list::-webkit-scrollbar-track { background: transparent; }
        .gr-query-list::-webkit-scrollbar-thumb { background: var(--gray-300); }
        .gr-query-cat {
            font-size: 10px;
            font-weight: 700;
            color: var(--gray-500);
            text-transform: uppercase;
            margin: 6px 2px 2px;
            letter-spacing: .04em;
        }
        .gr-query-cat:first-child { margin-top: 0; }
        .gr-query-row {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 4px 4px;
            font-size: 12px;
            cursor: pointer;
            transition: var(--transition);
        }
        .gr-query-row:hover {
            background: var(--primary-light);
        }
        .gr-query-row input {
            accent-color: var(--primary);
            cursor: pointer;
        }

        .gr-add-btn {
            width: 100%;
            margin: 8px 0;
            padding: 5px;
            font-size: 12px;
            justify-content: center;
        }

        /* ===== Included List ===== */
        .gr-included-list {
            max-height: 240px;
            overflow-y: auto;
        }
        .gr-included-list::-webkit-scrollbar { width: 3px; }
        .gr-included-list::-webkit-scrollbar-track { background: transparent; }
        .gr-included-list::-webkit-scrollbar-thumb { background: var(--gray-300); }
        .gr-included-empty {
            font-size: 11px;
            color: var(--gray-500);
            text-align: center;
            padding: 14px 6px;
            border: 1px dashed var(--gray-300);
        }
        .gr-included-item {
            border: 1px solid var(--gray-200);
            padding: 6px 8px;
            margin-bottom: 4px;
            transition: var(--transition);
        }
        .gr-included-item:hover {
            border-color: var(--primary);
        }
        .gr-included-item-top {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 6px;
        }
        .gr-included-item-title {
            font-size: 12px;
            font-weight: 600;
            color: var(--gray-800);
            flex: 1;
        }
        .gr-icon-btn {
            background: none;
            border: none;
            cursor: pointer;
            color: var(--gray-400);
            font-size: 12px;
            padding: 0 3px;
            line-height: 1;
            transition: var(--transition);
            font-family: inherit;
        }
        .gr-icon-btn:hover {
            color: var(--primary);
        }
        .gr-included-item select {
            width: 100%;
            margin-top: 4px;
            font-size: 11px;
            padding: 3px 6px;
            border: 1px solid var(--gray-300);
            font-family: inherit;
            color: var(--gray-800);
        }

        .gr-generate-btn {
            width: 100%;
            margin-top: 12px;
            padding: 10px;
            font-size: 13px;
            justify-content: center;
        }

        /* ===== Options ===== */
        .gr-checkbox-row {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            color: var(--gray-700);
            margin-top: 8px;
        }
        .gr-checkbox-row input {
            accent-color: var(--primary);
        }

        /* ===== Sidebar Toggle ===== */
        .gr-sidebar-toggle {
            position: absolute;
            top: 12px;
            left: 340px;
            margin-left: -14px;
            width: 28px;
            height: 28px;
            background: var(--primary);
            color: #fff;
            border: none;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            z-index: 10;
            box-shadow: var(--shadow);
            transition: left .22s ease, background .15s ease;
            font-size: 12px;
        }
        .gr-sidebar-toggle:hover {
            background: var(--primary-dark);
        }

        /* ===== Results ===== */
        .gr-results {
            padding: 0;
            min-height: 500px;
        }
        .gr-results-head {
            padding: 14px 18px;
            border-bottom: 1px solid var(--gray-200);
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            gap: 10px;
            flex-wrap: wrap;
        }
        .gr-results-title {
            font-size: 17px;
            font-weight: 700;
            color: var(--gray-800);
            margin: 0;
            word-break: break-word;
        }
        .gr-results-meta {
            font-size: 11px;
            color: var(--gray-500);
            margin-top: 2px;
        }
        .gr-results-body {
            padding: 16px;
        }
        .gr-empty-state {
            text-align: center;
            color: var(--gray-500);
            font-size: 13px;
            padding: 60px 20px;
        }
        .gr-empty-state i {
            font-size: 40px;
            color: var(--gray-300);
            margin-bottom: 12px;
            display: block;
        }

        /* ===== Section Card ===== */
        .gr-section-card {
            border: 1px solid var(--gray-200);
            margin-bottom: 16px;
        }
        .gr-section-card-head {
            padding: 10px 14px;
            border-bottom: 1px solid var(--gray-200);
            background: var(--gray-50);
            font-size: 13px;
            font-weight: 700;
            color: var(--gray-800);
        }
        .gr-section-card-body {
            padding: 14px;
        }
        .gr-chart-wrap {
            position: relative;
            height: 240px;
            width: 100%;
            margin-bottom: 12px;
        }

        /* ===== Table ===== */
        .gr-table-scroll {
            overflow-x: auto;
            border: 1px solid var(--gray-200);
            max-height: 400px;
            overflow-y: auto;
        }
        .gr-table-scroll::-webkit-scrollbar { width: 4px; height: 4px; }
        .gr-table-scroll::-webkit-scrollbar-track { background: transparent; }
        .gr-table-scroll::-webkit-scrollbar-thumb { background: var(--gray-300); }
        table.gr-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
            background: #fff;
        }
        table.gr-table th {
            position: sticky;
            top: 0;
            z-index: 1;
            text-align: left;
            padding: 6px 9px;
            background: var(--gray-100);
            color: var(--gray-700);
            font-weight: 700;
            border: 1px solid var(--gray-200);
            white-space: nowrap;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: .04em;
        }
        table.gr-table td {
            padding: 5px 9px;
            border: 1px solid var(--gray-200);
            color: var(--gray-800);
            white-space: nowrap;
            font-size: 12px;
        }
        table.gr-table td.wrap {
            white-space: normal;
            min-width: 140px;
            max-width: 340px;
            word-break: break-word;
            overflow-wrap: break-word;
        }
        table.gr-table td.num {
            text-align: right;
            font-variant-numeric: tabular-nums;
        }
        table.gr-table th.num {
            text-align: right;
        }
        table.gr-table tbody tr:nth-child(even) {
            background: var(--gray-50);
        }
        table.gr-table tbody tr:hover {
            background: var(--primary-light);
        }

        .gr-resource-thumb {
            width: 28px;
            height: 28px;
            object-fit: cover;
            border: 1px solid var(--gray-200);
            vertical-align: middle;
            margin-right: 4px;
        }
        .gr-map-pin {
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
            white-space: nowrap;
        }
        .gr-map-pin:hover {
            text-decoration: underline;
        }

        /* ===== Skeleton ===== */
        .gr-skeleton {
            background: linear-gradient(90deg, var(--gray-100) 25%, var(--gray-50) 37%, var(--gray-100) 63%);
            background-size: 400% 100%;
            animation: gr-shimmer 1.4s ease infinite;
            height: 160px;
        }
        @keyframes gr-shimmer {
            0% { background-position: 100% 50%; }
            100% { background-position: 0 50%; }
        }

        /* ===== Profile ===== */
        .gr-profile {
            display: flex;
            gap: 16px;
            flex-wrap: wrap;
        }
        .gr-profile-photo {
            width: 120px;
            height: 120px;
            object-fit: cover;
            border: 1px solid var(--gray-200);
            background: var(--gray-100);
            flex-shrink: 0;
        }
        .gr-profile-info {
            flex: 1;
            min-width: 200px;
        }
        .gr-profile-name {
            font-size: 16px;
            font-weight: 700;
            color: var(--gray-800);
            margin: 0 0 6px 0;
        }
        .gr-profile-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 4px 16px;
            font-size: 12px;
        }
        .gr-profile-grid dt {
            color: var(--gray-500);
            font-weight: 600;
            margin: 0;
        }
        .gr-profile-grid dd {
            margin: 0 0 4px 0;
            color: var(--gray-800);
            word-break: break-word;
            overflow-wrap: break-word;
        }
        .gr-profile-stats {
            display: flex;
            gap: 16px;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid var(--gray-200);
            flex-wrap: wrap;
        }
        .gr-profile-stat {
            text-align: center;
        }
        .gr-profile-stat .num {
            font-size: 16px;
            font-weight: 700;
            color: var(--primary);
        }
        .gr-profile-stat .lbl {
            font-size: 10px;
            color: var(--gray-500);
        }

        /* ===== Resource Copies (sidebar quick-preview + report card) ===== */
        .gr-copies-preview {
            margin-top: 8px;
            border: 1px solid var(--gray-200);
            background: var(--gray-50);
            max-height: 160px;
            overflow-y: auto;
            overflow-x: auto;
            font-size: 11px;
        }
        .gr-copies-preview table {
            width: 100%;
            border-collapse: collapse;
        }
        .gr-copies-preview th {
            position: sticky;
            top: 0;
            background: var(--gray-100);
            text-align: left;
            padding: 4px 6px;
            font-size: 9.5px;
            text-transform: uppercase;
            letter-spacing: .03em;
            color: var(--gray-600);
            border-bottom: 1px solid var(--gray-200);
            white-space: nowrap;
        }
        .gr-copies-preview td {
            padding: 4px 6px;
            border-bottom: 1px solid var(--gray-200);
            white-space: nowrap;
        }
        .gr-copies-preview .gr-empty-note,
        .gr-copies-preview .gr-loading-note {
            padding: 8px;
            color: var(--gray-500);
            white-space: normal;
        }
        .gr-copy-status {
            display: inline-block;
            padding: 1px 7px;
            font-size: 9.5px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .03em;
        }
        .gr-copy-status.available { background: #DCFCE7; color: #166534; }
        .gr-copy-status.borrowed { background: #FEF3C7; color: #92400E; }
        .gr-copy-status.reserved { background: #DBEAFE; color: #1E40AF; }
        .gr-copy-status.damage,
        .gr-copy-status.lost { background: #FEE2E2; color: #991B1B; }

        /* ===== Signature block (bottom of generated report) ===== */
        .gr-signature-block {
            display: flex;
            gap: 40px;
            flex-wrap: wrap;
            margin-top: 36px;
            padding-top: 20px;
        }
        .gr-signature-col {
            flex: 1 1 220px;
            min-width: 200px;
            text-align: center;
        }
        .gr-signature-space {
            height: 46px;
        }
        .gr-signature-line {
            border-top: 1.5px solid var(--gray-800);
            margin-bottom: 6px;
        }
        .gr-signature-label {
            font-size: 12px;
            font-weight: 700;
            color: var(--gray-800);
        }
        .gr-signature-name {
            font-size: 11px;
            color: var(--gray-500);
            margin-top: 2px;
        }

        /* ===== Resource Profile ===== */
        .gr-resource-profile {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .gr-resource-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 4px 16px;
            font-size: 12px;
        }
        .gr-resource-grid dt {
            color: var(--gray-500);
            font-weight: 600;
            margin: 0;
        }
        .gr-resource-grid dd {
            margin: 0 0 4px 0;
            color: var(--gray-800);
            word-break: break-word;
            overflow-wrap: break-word;
        }
        .gr-resource-gallery {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            margin-top: 4px;
        }
        .gr-resource-gallery img {
            width: 100px;
            height: 100px;
            object-fit: cover;
            border: 1px solid var(--gray-200);
        }

        /* ===== Responsive ===== */
        .gr-layout.gr-sidebar-collapsed {
            grid-template-columns: 0 1fr;
        }
        .gr-layout.gr-sidebar-collapsed .gr-sidebar {
            padding: 0;
            opacity: 0;
            pointer-events: none;
        }
        .gr-layout.gr-sidebar-collapsed .gr-sidebar-toggle {
            left: 0;
            margin-left: 0;
        }
        .gr-layout.gr-sidebar-collapsed .gr-sidebar-toggle svg {
            transform: rotate(180deg);
        }

        /* ===== MOBILE RESPONSIVE FIXES ===== */
        @media (max-width: 900px) {
            .gr-layout {
                grid-template-columns: 1fr;
            }
            .gr-sidebar {
                position: static;
            }
            .gr-sidebar-toggle {
                left: auto;
                right: 8px;
                top: 8px;
                margin-left: 0;
            }
            .gr-layout.gr-sidebar-collapsed .gr-sidebar-toggle {
                right: auto;
                left: 8px;
                top: 8px;
            }
        }
        
        @media (max-width: 768px) {
            .gr-dash { 
                padding: 12px; 
            }
            
            /* Header - row layout with left alignment */
            .gr-header {
                flex-direction: row;
                align-items: center;
                justify-content: space-between;
                padding: 12px 14px;
                gap: 10px;
                margin-bottom: 16px;
                text-align: left;
            }
            .gr-header-left {
                flex-direction: row;
                align-items: center;
                gap: 10px;
                flex: 1;
                min-width: 0;
            }
            .gr-header-left .icon-wrap {
                width: 32px;
                height: 32px;
                font-size: 14px;
                flex-shrink: 0;
            }
            .gr-header-left h1 {
                font-size: 16px;
                white-space: nowrap;
            }
            .gr-header-left .subtitle {
                font-size: 11px;
                white-space: nowrap;
            }
            /* Header buttons - icon only */
            .gr-header-right {
                gap: 6px;
                flex-shrink: 0;
            }
            .gr-header-right .gr-btn {
                padding: 6px 8px;
                font-size: 14px;
                min-width: 36px;
                min-height: 36px;
                justify-content: center;
                gap: 0;
            }
            .gr-header-right .gr-btn .btn-text {
                display: none;
            }
            .gr-header-right .gr-btn i {
                font-size: 15px;
                margin: 0;
            }
            
            /* Sidebar */
            .gr-sidebar {
                padding: 12px 14px;
                max-height: none;
                overflow-y: visible;
            }
            .gr-sidebar-title {
                font-size: 12px;
            }
            .gr-input {
                font-size: 14px;
                padding: 8px 12px;
            }
            
            /* Query list */
            .gr-query-list {
                max-height: 140px;
            }
            .gr-query-row {
                font-size: 11px;
                padding: 6px 4px;
            }
            .gr-add-btn {
                padding: 8px 12px;
                font-size: 13px;
                min-height: 38px;
            }
            
            /* Included list */
            .gr-included-list {
                max-height: 180px;
            }
            .gr-included-item {
                padding: 8px 10px;
            }
            .gr-included-item-title {
                font-size: 11px;
            }
            .gr-included-item select {
                font-size: 12px;
                padding: 4px 8px;
            }
            
            /* Options */
            .gr-checkbox-row {
                font-size: 11px;
            }
            
            /* Generate button */
            .gr-generate-btn {
                padding: 12px 16px;
                font-size: 14px;
                min-height: 44px;
            }
            
            /* Results */
            .gr-results {
                min-height: 300px;
            }
            .gr-results-head {
                padding: 10px 14px;
                flex-direction: column;
                text-align: left;
                gap: 6px;
            }
            .gr-results-title {
                font-size: 15px;
            }
            .gr-results-meta {
                font-size: 10px;
            }
            .gr-results-body {
                padding: 12px;
            }
            .gr-empty-state {
                padding: 40px 16px;
                font-size: 12px;
            }
            .gr-empty-state i {
                font-size: 32px;
            }
            
            /* Section cards */
            .gr-section-card {
                margin-bottom: 12px;
            }
            .gr-section-card-head {
                padding: 8px 12px;
                font-size: 12px;
            }
            .gr-section-card-body {
                padding: 10px 12px;
            }
            
            /* Chart */
            .gr-chart-wrap {
                height: 180px;
            }
            
            /* Profile */
            .gr-profile {
                flex-direction: column;
                align-items: center;
                text-align: center;
            }
            .gr-profile-photo {
                width: 100px;
                height: 100px;
            }
            .gr-profile-grid {
                grid-template-columns: 1fr;
            }
            .gr-profile-name {
                font-size: 15px;
            }
            .gr-profile-stats {
                justify-content: center;
                gap: 12px;
            }
            .gr-profile-stat .num {
                font-size: 14px;
            }
            
            /* Resource */
            .gr-resource-grid {
                grid-template-columns: 1fr;
            }
            .gr-resource-gallery {
                justify-content: center;
            }
            .gr-resource-gallery img {
                width: 80px;
                height: 80px;
            }
            
            /* Table */
            .gr-table-scroll {
                max-height: 300px;
                margin: 0 -12px;
                padding: 0 12px;
            }
            table.gr-table {
                font-size: 11px;
                min-width: 500px;
            }
            table.gr-table th,
            table.gr-table td {
                padding: 4px 6px;
                font-size: 10px;
            }
            table.gr-table th {
                font-size: 9px;
            }
            table.gr-table td.wrap {
                min-width: 100px;
            }
            .gr-resource-thumb {
                width: 24px;
                height: 24px;
            }
            
            /* Error */
            .gr-error {
                font-size: 12px;
                padding: 10px 14px;
                gap: 8px;
            }
        }

        @media (max-width: 480px) {
            .gr-dash { 
                padding: 8px; 
            }
            
            .gr-header {
                padding: 10px 12px;
                gap: 8px;
            }
            .gr-header-left .icon-wrap {
                width: 28px;
                height: 28px;
                font-size: 12px;
            }
            .gr-header-left h1 {
                font-size: 14px;
            }
            .gr-header-left .subtitle {
                font-size: 10px;
            }
            .gr-header-right .gr-btn {
                padding: 4px 6px;
                min-width: 32px;
                min-height: 32px;
                font-size: 12px;
            }
            .gr-header-right .gr-btn i {
                font-size: 13px;
            }
            
            .gr-sidebar {
                padding: 10px 12px;
            }
            .gr-input {
                font-size: 13px;
                padding: 6px 10px;
                margin-bottom: 10px;
            }
            .gr-field-label {
                font-size: 10px;
            }
            .gr-section-title {
                font-size: 10px;
            }
            
            .gr-query-list {
                max-height: 120px;
            }
            .gr-query-row {
                font-size: 10px;
                padding: 5px 4px;
            }
            .gr-query-cat {
                font-size: 9px;
            }
            .gr-add-btn {
                padding: 6px 10px;
                font-size: 12px;
                min-height: 34px;
            }
            
            .gr-included-list {
                max-height: 150px;
            }
            .gr-included-item {
                padding: 6px 8px;
            }
            .gr-included-item-title {
                font-size: 10px;
            }
            .gr-included-item select {
                font-size: 11px;
                padding: 3px 6px;
            }
            .gr-icon-btn {
                font-size: 11px;
                padding: 0 2px;
            }
            
            .gr-generate-btn {
                padding: 10px 14px;
                font-size: 13px;
                min-height: 40px;
            }
            
            .gr-results-head {
                padding: 8px 12px;
            }
            .gr-results-title {
                font-size: 14px;
            }
            .gr-results-body {
                padding: 10px;
            }
            
            .gr-section-card-head {
                padding: 6px 10px;
                font-size: 11px;
            }
            .gr-section-card-body {
                padding: 8px 10px;
            }
            .gr-chart-wrap {
                height: 150px;
            }
            
            .gr-profile-photo {
                width: 80px;
                height: 80px;
            }
            .gr-profile-name {
                font-size: 14px;
            }
            .gr-profile-grid {
                font-size: 11px;
            }
            .gr-profile-stats {
                gap: 10px;
            }
            .gr-profile-stat .num {
                font-size: 13px;
            }
            
            .gr-resource-gallery img {
                width: 60px;
                height: 60px;
            }
            .gr-resource-grid {
                font-size: 11px;
            }
            
            .gr-table-scroll {
                max-height: 250px;
                margin: 0 -10px;
                padding: 0 10px;
            }
            table.gr-table {
                font-size: 10px;
                min-width: 400px;
            }
            table.gr-table th,
            table.gr-table td {
                padding: 3px 4px;
                font-size: 9px;
            }
            .gr-resource-thumb {
                width: 20px;
                height: 20px;
            }
            
            .gr-empty-state {
                padding: 30px 12px;
                font-size: 11px;
            }
            .gr-empty-state i {
                font-size: 28px;
            }
            
            .gr-error {
                font-size: 11px;
                padding: 8px 12px;
            }
            
            /* Sidebar toggle */
            .gr-sidebar-toggle {
                width: 24px;
                height: 24px;
                font-size: 10px;
                top: 6px;
                right: 6px;
            }
        }

        @media (max-width: 380px) {
            .gr-dash { 
                padding: 6px; 
            }
            
            .gr-header {
                padding: 8px 10px;
                gap: 6px;
            }
            .gr-header-left .icon-wrap {
                width: 24px;
                height: 24px;
                font-size: 10px;
            }
            .gr-header-left h1 {
                font-size: 13px;
            }
            .gr-header-left .subtitle {
                font-size: 9px;
            }
            .gr-header-right .gr-btn {
                padding: 4px 5px;
                min-width: 28px;
                min-height: 28px;
                font-size: 11px;
            }
            .gr-header-right .gr-btn i {
                font-size: 11px;
            }
            
            .gr-sidebar {
                padding: 8px 10px;
            }
            
            .gr-query-list {
                max-height: 100px;
            }
            .gr-add-btn {
                padding: 5px 8px;
                font-size: 11px;
                min-height: 30px;
            }
            
            .gr-generate-btn {
                padding: 8px 12px;
                font-size: 12px;
                min-height: 36px;
            }
            
            .gr-chart-wrap {
                height: 130px;
            }
            
            table.gr-table {
                min-width: 350px;
            }
        }
        </style>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="gr-dash">

        <!-- ===== ERROR ===== -->
        <div id="grError" class="gr-error">
            <i class="fas fa-exclamation-circle"></i>
            <span id="grErrorText"></span>
        </div>

        <!-- ===== HEADER ===== -->
        <div class="gr-header">
            <div class="gr-header-left">
                <div class="icon-wrap">
                    <i class="fas fa-file-alt"></i>
                </div>
                <div>
                    <h1>Generate Report</h1>
                    <p class="subtitle">
                        Welcome, <asp:Literal ID="litAdminName" runat="server" Text="Admin" />
                        (<asp:Literal ID="litAdminEmail" runat="server" Text="email" />).
                        Pick the data you want, arrange it, and preview before printing.
                    </p>
                </div>
            </div>
            <div class="gr-header-right">
                <a class="gr-btn gr-btn-outline" href="~/Users/Admin/Reports/adminReports.aspx" runat="server">
                    <i class="fas fa-arrow-left"></i>
                    <span class="btn-text">Back to Reports</span>
                </a>
                <button type="button" class="gr-btn gr-btn-primary" id="btnPrint" disabled>
                    <i class="fas fa-print"></i>
                    <span class="btn-text">Print Report</span>
                </button>
            </div>
        </div>

        <!-- ===== LAYOUT ===== -->
        <div class="gr-layout" id="grLayout">

            <!-- ===== SIDEBAR TOGGLE ===== -->
            <button type="button" class="gr-sidebar-toggle" id="btnToggleSidebar" title="Collapse panel" aria-label="Collapse panel" aria-expanded="true" aria-controls="grSidebar">
                <i class="fas fa-chevron-left"></i>
            </button>

            <!-- ===== SIDEBAR ===== -->
            <div class="gr-panel gr-sidebar" id="grSidebar">
                <h3 class="gr-sidebar-title">
                    <i class="fas fa-file-signature"></i> My Report
                </h3>

                <label class="gr-field-label" for="inpReportTitle"><i class="fas fa-heading"></i> Report title</label>
                <input type="text" id="inpReportTitle" class="gr-input" value="My Report" maxlength="120" />

                <!-- Available Queries -->
                <div class="gr-section">
                    <div class="gr-section-title"><i class="fas fa-database"></i> Available Queries</div>
                    <div class="gr-query-list" id="queryList">
                        <div class="gr-skeleton"></div>
                    </div>
                    <button type="button" class="gr-btn gr-btn-outline gr-add-btn" id="btnAddQueries">
                        <i class="fas fa-plus"></i> Add Selected
                    </button>
                </div>

                <!-- Borrower Report -->
                <div class="gr-section">
                    <div class="gr-section-title"><i class="fas fa-user"></i> Select a Borrower</div>
                    <select id="selBorrower" class="gr-input" style="margin-bottom:8px;">
                        <option value="">Loading borrowers…</option>
                    </select>

                    <label class="gr-field-label"><i class="fas fa-calendar-alt"></i> Borrow date from / to</label>
                    <div style="display:flex; gap:8px; margin-bottom:8px;">
                        <input type="date" id="inpDateFrom" class="gr-input" style="margin-bottom:0;" />
                        <input type="date" id="inpDateTo" class="gr-input" style="margin-bottom:0;" />
                    </div>

                    <button type="button" class="gr-btn gr-btn-outline gr-add-btn" id="btnAddBorrower" style="margin-top:0;">
                        <i class="fas fa-user-plus"></i> Add Borrower Report
                    </button>
                    <p style="font-size:11px; color:var(--gray-500); margin:4px 2px 0;"><i class="fas fa-info-circle"></i> Shows full profile, loan stats, resources borrowed, and matching transaction records.</p>
                </div>

                <!-- Resource Report -->
                <div class="gr-section">
                    <div class="gr-section-title"><i class="fas fa-book"></i> Select a Resource</div>
                    <div style="margin-bottom:8px; display:flex; gap:12px; font-size:12px;">
                        <label><input type="radio" name="resourceFilter" value="all" checked /> All</label>
                        <label><input type="radio" name="resourceFilter" value="book" /> Books</label>
                        <label><input type="radio" name="resourceFilter" value="periodical" /> Periodicals</label>
                    </div>
                    <div style="position:relative; margin-bottom:8px;">
                        <i class="fas fa-search" style="position:absolute; left:10px; top:50%; transform:translateY(-50%); font-size:11px; color:var(--gray-400);"></i>
                        <input type="text" id="inpResourceSearch" class="gr-input" style="margin-bottom:0; padding-left:28px;" placeholder="Search by title or author…" />
                    </div>
                    <select id="selResource" class="gr-input" style="margin-bottom:6px;">
                        <option value="">Loading resources…</option>
                    </select>
                    <div class="gr-copies-preview" id="resourceCopiesPreview" style="display:none;"></div>
                    <button type="button" class="gr-btn gr-btn-outline gr-add-btn" id="btnAddResource">
                        <i class="fas fa-plus"></i> Add Resource Report
                    </button>
                    <p style="font-size:11px; color:var(--gray-500); margin:4px 2px 0;"><i class="fas fa-info-circle"></i> Adds a resource reference card with full catalog details, cover, and item copy statuses.</p>
                </div>

                <!-- Resource List -->
                <div class="gr-section">
                    <div class="gr-section-title"><i class="fas fa-table"></i> Resource List (Table)</div>
                    <div style="margin-bottom:8px; display:flex; gap:12px; font-size:12px;">
                        <label><input type="radio" name="resourceListFilter" value="all" checked /> All</label>
                        <label><input type="radio" name="resourceListFilter" value="book" /> Books</label>
                        <label><input type="radio" name="resourceListFilter" value="periodical" /> Periodicals</label>
                    </div>
                    <button type="button" class="gr-btn gr-btn-outline gr-add-btn" id="btnAddResourceList" style="margin-top:0;">
                        <i class="fas fa-table"></i> Add Resource List
                    </button>
                    <p style="font-size:11px; color:var(--gray-500); margin:4px 2px 0;"><i class="fas fa-info-circle"></i> Adds a table of resources with Cover, Type, Title, Author, Call Number &amp; Pub. Year.</p>
                </div>

                <!-- Included -->
                <div class="gr-section">
                    <div class="gr-section-title"><i class="fas fa-list"></i> Included in Report</div>
                    <div class="gr-included-list" id="includedList">
                        <div class="gr-included-empty"><i class="fas fa-plus-circle"></i> Nothing added yet. Check items above and click "Add Selected".</div>
                    </div>
                </div>

                <!-- Options -->
                <div class="gr-section">
                    <div class="gr-section-title"><i class="fas fa-sliders-h"></i> Options</div>
                    <label class="gr-field-label" for="selChartColor"><i class="fas fa-palette"></i> Chart color palette</label>
                    <select id="selChartColor" class="gr-input" style="margin-bottom:0;">
                        <option value="blue" selected>LMSA Blue</option>
                        <option value="colorblind">Colorblind-friendly</option>
                    </select>
                    <div class="gr-checkbox-row">
                        <input type="checkbox" id="chkTimestamp" checked />
                        <label for="chkTimestamp"><i class="fas fa-clock"></i> Show generated-on timestamp</label>
                    </div>
                </div>

                <button type="button" class="gr-btn gr-btn-primary gr-generate-btn" id="btnGenerate">
                    <i class="fas fa-play"></i> Generate Preview
                </button>
            </div>

            <!-- ===== RESULTS ===== -->
            <div class="gr-panel gr-results">
                <div class="gr-results-head">
                    <div>
                        <p class="gr-results-title" id="resultsTitle">My Report</p>
                        <p class="gr-results-meta" id="resultsMeta">Showing library-wide circulation and catalog data.</p>
                    </div>
                </div>
                <div class="gr-results-body" id="resultsBody">
                    <div class="gr-empty-state" id="emptyState">
                        <i class="fas fa-file-alt"></i>
                        <div>Select queries on the left, then click <strong>Generate Preview</strong> to see your report here.</div>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <script>
        (function () {
            "use strict";

            var adminName = '<%= litAdminName.Text %>';
            var adminEmail = '<%= litAdminEmail.Text %>';

            var API = "GetReports.ashx";
            var catalog = [];
            var included = [];
            var lastRun = null;

            var els = {
                error: document.getElementById("grError"),
                errorText: document.getElementById("grErrorText"),
                queryList: document.getElementById("queryList"),
                includedList: document.getElementById("includedList"),
                btnAddQueries: document.getElementById("btnAddQueries"),
                btnGenerate: document.getElementById("btnGenerate"),
                btnPrint: document.getElementById("btnPrint"),
                inpTitle: document.getElementById("inpReportTitle"),
                resultsTitle: document.getElementById("resultsTitle"),
                resultsMeta: document.getElementById("resultsMeta"),
                resultsBody: document.getElementById("resultsBody"),
                emptyState: document.getElementById("emptyState"),
                selChartColor: document.getElementById("selChartColor"),
                chkTimestamp: document.getElementById("chkTimestamp"),
                selBorrower: document.getElementById("selBorrower"),
                btnAddBorrower: document.getElementById("btnAddBorrower"),
                inpDateFrom: document.getElementById("inpDateFrom"),
                inpDateTo: document.getElementById("inpDateTo"),
                selResource: document.getElementById("selResource"),
                btnAddResource: document.getElementById("btnAddResource"),
                inpResourceSearch: document.getElementById("inpResourceSearch"),
                resourceCopiesPreview: document.getElementById("resourceCopiesPreview"),
                grLayout: document.getElementById("grLayout"),
                btnToggleSidebar: document.getElementById("btnToggleSidebar"),
                btnAddResourceList: document.getElementById("btnAddResourceList")
            };

            var allResources = [];

            var PALETTES = {
                blue: ["#0000C0", "#5C6BFF", "#99B3FF", "#3A4DB0", "#0F2A8C"],
                colorblind: ["#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9"]
            };

            function showError(msg) {
                els.errorText.textContent = msg;
                els.error.style.display = "flex";
                console.error(msg);
            }
            function hideError() {
                els.error.style.display = "none";
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

            function escapeHtml(v) {
                return String(v == null ? "" : v).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            }

            var SIDEBAR_STATE_KEY = "grSidebarCollapsed";

            function setSidebarCollapsed(collapsed) {
                els.grLayout.classList.toggle("gr-sidebar-collapsed", collapsed);
                els.btnToggleSidebar.setAttribute("aria-expanded", collapsed ? "false" : "true");
                els.btnToggleSidebar.title = collapsed ? "Expand panel" : "Collapse panel";
                els.btnToggleSidebar.setAttribute("aria-label", collapsed ? "Expand panel" : "Collapse panel");
                try { window.localStorage.setItem(SIDEBAR_STATE_KEY, collapsed ? "1" : "0"); } catch (e) { /* storage unavailable, ignore */ }
            }

            els.btnToggleSidebar.addEventListener("click", function () {
                setSidebarCollapsed(!els.grLayout.classList.contains("gr-sidebar-collapsed"));
            });

            (function restoreSidebarState() {
                var saved = "0";
                try { saved = window.localStorage.getItem(SIDEBAR_STATE_KEY) || "0"; } catch (e) { /* storage unavailable, ignore */ }
                setSidebarCollapsed(saved === "1");
            })();

            function loadCatalog() {
                api("list").then(function (list) {
                    catalog = list;
                    renderQueryList();
                }).catch(function (err) {
                    showError("Unable to load available queries: " + err.message);
                    els.queryList.innerHTML = '<div class="gr-included-empty"><i class="fas fa-exclamation-triangle"></i> Could not load queries.</div>';
                });
            }

            function renderQueryList() {
                var byCategory = {};
                catalog.forEach(function (q) {
                    (byCategory[q.category] = byCategory[q.category] || []).push(q);
                });
                var html = "";
                Object.keys(byCategory).forEach(function (cat) {
                    html += '<div class="gr-query-cat">' + escapeHtml(cat) + '</div>';
                    byCategory[cat].forEach(function (q) {
                        html += '<label class="gr-query-row">' +
                            '<input type="checkbox" value="' + escapeHtml(q.key) + '" />' +
                            '<span>' + escapeHtml(q.label) + '</span>' +
                            '</label>';
                    });
                });
                els.queryList.innerHTML = html;
            }

            function loadBorrowers() {
                api("borrowers").then(function (list) {
                    if (!list || !list.length) {
                        els.selBorrower.innerHTML = '<option value="">No borrowers on file yet</option>';
                        return;
                    }
                    var html = list.map(function (b) {
                        return '<option value="' + escapeHtml(b.id) + '">' + escapeHtml(b.name) + '</option>';
                    }).join("");
                    els.selBorrower.innerHTML = html;
                }).catch(function (err) {
                    els.selBorrower.innerHTML = '<option value="">Could not load borrowers</option>';
                    showError("Unable to load borrowers: " + err.message);
                });
            }

            function addBorrowerProfile() {
                var opt = els.selBorrower.options[els.selBorrower.selectedIndex];
                if (!opt || !opt.value) return;

                var statuses = ["Borrowed", "Returned", "Overdue", "Reserved", "Ready", "Cancelled"];

                var key = "borrower:" + opt.value;
                if (included.some(function (it) { return it.type === "borrower" && it.borrowerId === opt.value; })) return;

                var borrowerName = opt.textContent;

                included.push({
                    type: "borrower",
                    key: key,
                    borrowerId: opt.value,
                    label: borrowerName,
                    chartType: "none",
                    mode: "profile",
                    statuses: statuses,
                    dateFrom: els.inpDateFrom.value || "",
                    dateTo: els.inpDateTo.value || ""
                });
                renderIncluded();
            }

            function loadResources() {
                var filter = document.querySelector('input[name="resourceFilter"]:checked').value;
                els.resourceCopiesPreview.style.display = "none";
                els.resourceCopiesPreview.innerHTML = "";
                api("resources", { kind: filter }).then(function (list) {
                    allResources = list || [];
                    els.inpResourceSearch.value = "";
                    renderResourceOptions(allResources);
                }).catch(function (err) {
                    allResources = [];
                    els.selResource.innerHTML = '<option value="">Could not load resources</option>';
                    showError("Unable to load resources: " + err.message);
                });
            }

            function renderResourceOptions(list) {
                if (!list.length) {
                    els.selResource.innerHTML = '<option value="">No matching resources</option>';
                    return;
                }
                els.selResource.innerHTML = list.map(function (r) {
                    return '<option value="' + r.id + '">' + escapeHtml(r.name) + '</option>';
                }).join("");
            }

            els.inpResourceSearch.addEventListener("input", function () {
                var term = els.inpResourceSearch.value.trim().toLowerCase();
                var filtered = !term ? allResources : allResources.filter(function (r) {
                    return r.name.toLowerCase().indexOf(term) !== -1;
                });
                renderResourceOptions(filtered);
                els.resourceCopiesPreview.style.display = "none";
                els.resourceCopiesPreview.innerHTML = "";
            });

            function copyStatusClass(status) {
                var s = (status || "").toLowerCase();
                if (s === "available") return "available";
                if (s === "borrowed") return "borrowed";
                if (s === "reserved") return "reserved";
                if (s === "damage" || s === "lost") return s;
                return "";
            }

            function renderCopiesTable(copies) {
                if (!copies || !copies.length) {
                    return '<div class="gr-empty-note"><i class="fas fa-info-circle"></i> No item copies on file for this resource.</div>';
                }
                var rows = copies.map(function (c) {
                    return '<tr>' +
                        '<td>' + escapeHtml(c.accessionNumber) + '</td>' +
                        '<td>' + escapeHtml(c.campus) + '</td>' +
                        '<td>' + escapeHtml(c.location) + '</td>' +
                        '<td><span class="gr-copy-status ' + copyStatusClass(c.status) + '">' + escapeHtml(c.status) + '</span></td>' +
                        '</tr>';
                }).join("");
                return '<table><thead><tr><th>Accession No.</th><th>Campus</th><th>Location</th><th>Status</th></tr></thead><tbody>' + rows + '</tbody></table>';
            }

            els.selResource.addEventListener("change", function () {
                var opt = els.selResource.options[els.selResource.selectedIndex];
                if (!opt || !opt.value) {
                    els.resourceCopiesPreview.style.display = "none";
                    els.resourceCopiesPreview.innerHTML = "";
                    return;
                }
                els.resourceCopiesPreview.style.display = "block";
                els.resourceCopiesPreview.innerHTML = '<div class="gr-loading-note"><i class="fas fa-spinner fa-spin"></i> Loading copies…</div>';
                api("resource_copies", { id: opt.value }).then(function (copies) {
                    els.resourceCopiesPreview.innerHTML = renderCopiesTable(copies);
                }).catch(function (err) {
                    els.resourceCopiesPreview.innerHTML = '<div class="gr-empty-note"><i class="fas fa-exclamation-triangle"></i> Could not load copies.</div>';
                });
            });

            document.querySelectorAll('input[name="resourceFilter"]').forEach(function (radio) {
                radio.addEventListener("change", loadResources);
            });

            function addResourceReport() {
                var opt = els.selResource.options[els.selResource.selectedIndex];
                if (!opt || !opt.value) return;
                var id = opt.value;

                var key = "resource:" + id;
                if (included.some(function (it) { return it.type === "resource" && it.resourceId === id; })) return;

                var resourceName = opt.textContent;

                included.push({
                    type: "resource",
                    key: key,
                    resourceId: id,
                    label: resourceName,
                    chartType: "none",
                    mode: "resource"
                });
                renderIncluded();
            }

            function addResourceList() {
                var filter = document.querySelector('input[name="resourceListFilter"]:checked').value;
                var key = "resource_list_" + filter;
                var labelMap = { all: "Resource List (All)", book: "Resource List (Books)", periodical: "Resource List (Periodicals)" };
                var label = labelMap[filter] || "Resource List";

                if (included.some(function (it) { return it.type === "query" && it.key === key; })) return;

                included.push({
                    type: "query",
                    key: key,
                    label: label,
                    chartType: "none",
                    mode: "table"
                });
                renderIncluded();
            }

            els.btnAddResourceList.addEventListener("click", addResourceList);

            function addSelected() {
                var checked = Array.prototype.slice.call(els.queryList.querySelectorAll("input:checked"));
                if (checked.length === 0) return;
                checked.forEach(function (cb) {
                    var q = catalog.find(function (c) { return c.key === cb.value; });
                    if (!q) return;
                    if (included.some(function (it) { return it.type !== "borrower" && it.key === q.key; })) return;
                    included.push({
                        type: "query",
                        key: q.key,
                        label: q.label,
                        chartType: q.chartType,
                        mode: q.chartType === "none" ? "table" : "both"
                    });
                    cb.checked = false;
                });
                renderIncluded();
            }

            function renderIncluded() {
                if (included.length === 0) {
                    els.includedList.innerHTML = '<div class="gr-included-empty"><i class="fas fa-plus-circle"></i> Nothing added yet. Check items above and click "Add Selected".</div>';
                    return;
                }
                var html = "";
                included.forEach(function (item, idx) {
                    var isBorrower = item.type === "borrower";
                    var isResource = item.type === "resource";
                    var modeOptions = item.chartType === "none"
                        ? '<option value="table" selected>Table Only</option>'
                        : (
                            '<option value="table"' + (item.mode === "table" ? " selected" : "") + '>Table Only</option>' +
                            '<option value="chart"' + (item.mode === "chart" ? " selected" : "") + '>Chart Only (' + item.chartType + ')</option>' +
                            '<option value="both"' + (item.mode === "both" ? " selected" : "") + '>Table + Chart</option>'
                        );
                    html += '<div class="gr-included-item" data-idx="' + idx + '">' +
                        '<div class="gr-included-item-top">' +
                        '<span class="gr-included-item-title">' + escapeHtml(item.label) + '</span>' +
                        '<span>' +
                        '<button type="button" class="gr-icon-btn" data-act="up" title="Move up"><i class="fas fa-chevron-up"></i></button>' +
                        '<button type="button" class="gr-icon-btn" data-act="down" title="Move down"><i class="fas fa-chevron-down"></i></button>' +
                        '<button type="button" class="gr-icon-btn" data-act="remove" title="Remove"><i class="fas fa-times"></i></button>' +
                        '</span>' +
                        '</div>' +
                        (isBorrower
                            ? '<div style="font-size:11px; color:var(--gray-500); margin-top:4px;"><i class="fas fa-user"></i> Full profile with loan stats</div>'
                            : (isResource
                                ? '<div style="font-size:11px; color:var(--gray-500); margin-top:4px;"><i class="fas fa-book"></i> Resource reference card with cover</div>'
                                : '<select data-act="mode">' + modeOptions + '</select>')) +
                        '</div>';
                });
                els.includedList.innerHTML = html;
            }

            els.includedList.addEventListener("click", function (e) {
                var btn = e.target.closest("button[data-act]");
                if (!btn) return;
                var row = btn.closest(".gr-included-item");
                var idx = parseInt(row.getAttribute("data-idx"), 10);
                if (btn.getAttribute("data-act") === "remove") {
                    included.splice(idx, 1);
                } else if (btn.getAttribute("data-act") === "up" && idx > 0) {
                    var tmp = included[idx - 1]; included[idx - 1] = included[idx]; included[idx] = tmp;
                } else if (btn.getAttribute("data-act") === "down" && idx < included.length - 1) {
                    var tmp2 = included[idx + 1]; included[idx + 1] = included[idx]; included[idx] = tmp2;
                }
                renderIncluded();
            });

            els.includedList.addEventListener("change", function (e) {
                var sel = e.target.closest("select[data-act='mode']");
                if (!sel) return;
                var row = sel.closest(".gr-included-item");
                var idx = parseInt(row.getAttribute("data-idx"), 10);
                included[idx].mode = sel.value;
            });

            els.inpTitle.addEventListener("input", function () {
                els.resultsTitle.textContent = els.inpTitle.value || "My Report";
                if (lastRun) lastRun.title = els.inpTitle.value || "My Report";
            });

            var charts = {};
            function destroyChart(id) {
                if (charts[id]) { charts[id].destroy(); delete charts[id]; }
            }

            function renderChart(canvas, data) {
                var palette = PALETTES[els.selChartColor.value] || PALETTES.blue;
                var labels = data.rows.map(function (r) { return r[0]; });
                var values = data.rows.map(function (r) { return parseFloat(r[r.length - 1]) || 0; });
                var type = data.chartType === "pie" ? "pie" : (data.chartType === "line" ? "line" : "bar");

                var dataset;
                if (type === "pie") {
                    dataset = { data: values, backgroundColor: labels.map(function (_, i) { return palette[i % palette.length]; }) };
                } else if (type === "line") {
                    dataset = { data: values, borderColor: palette[0], backgroundColor: palette[0], tension: .3, fill: false, pointRadius: 3 };
                } else {
                    dataset = { data: values, backgroundColor: palette[0], maxBarThickness: 36, borderRadius: 0 };
                }

                destroyChart(canvas.id);
                charts[canvas.id] = new Chart(canvas.getContext("2d"), {
                    type: type,
                    data: { labels: labels, datasets: [dataset] },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { display: type === "pie" } },
                        scales: type === "pie" ? {} : {
                            y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: "rgba(0,0,0,.06)" } },
                            x: { grid: { display: false }, ticks: { font: { size: 9 }, maxRotation: 45 } }
                        }
                    }
                });
            }

            function buildExcelTable(columns, rows) {
                var colDefs = columns.map(function (c) {
                    if (typeof c === 'string') return { label: c, numeric: false, wrap: false, allowHtml: false };
                    return c;
                });

                var head = '<tr>' + colDefs.map(function (c) {
                    return '<th' + (c.numeric ? ' class="num"' : '') + '>' + escapeHtml(c.label) + '</th>';
                }).join('') + '</tr>';

                var body;
                if (rows.length) {
                    body = rows.map(function (r) {
                        return '<tr>' + r.map(function (cellHtml, ci) {
                            var classes = [];
                            if (colDefs[ci] && colDefs[ci].numeric) classes.push('num');
                            if (colDefs[ci] && colDefs[ci].wrap) classes.push('wrap');
                            var cellContent = (colDefs[ci] && colDefs[ci].allowHtml) ? cellHtml : escapeHtml(cellHtml);
                            return '<td' + (classes.length ? ' class="' + classes.join(' ') + '"' : '') + '>' + cellContent + '</td>';
                        }).join('') + '</tr>';
                    }).join('');
                } else {
                    body = '<tr><td colspan="' + columns.length + '" style="text-align:center;color:var(--gray-500);">No data available.</td></tr>';
                }
                return '<div class="gr-table-scroll"><table class="gr-table"><thead>' + head + '</thead><tbody>' + body + '</tbody></table></div>';
            }

            function renderTable(data) {
                var colDefs = data.columns.map(function (c) {
                    var isNumeric = /count|checkouts|amount|collected|copies|borrowed|days overdue/i.test(c);
                    var isShort = /^(status|type|year|pub\. year|gender|role|campus|call number|isbn|issn)$/i.test(c);
                    return { label: c, numeric: isNumeric, wrap: !isNumeric && !isShort, allowHtml: (c === 'Cover') };
                });
                var rows = data.rows.map(function (r) { return r.map(function (c) { return c; }); });
                return buildExcelTable(colDefs, rows);
            }

            function renderResourcesBorrowedTable(resources) {
                var columns = [
                    { label: 'Cover', allowHtml: true },
                    { label: 'Title', wrap: true, allowHtml: true },
                    { label: 'Author', wrap: true },
                    { label: 'Genre' },
                    { label: 'Call Number' },
                    { label: 'Times Borrowed', numeric: true }
                ];
                var rows = resources.map(function (r) {
                    var coverHtml = r.coverUrl ? '<img class="gr-resource-thumb" src="' + escapeHtml(r.coverUrl) + '" alt="" />' : '';
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

                return '<div class="gr-profile">' +
                    '<img class="gr-profile-photo" src="' + escapeHtml(p.photoUrl) + '" alt="Photo of ' + escapeHtml(p.fullName) + '" />' +
                    '<div class="gr-profile-info">' +
                    '<p class="gr-profile-name">' + escapeHtml(p.fullName) + '</p>' +
                    '<dl class="gr-profile-grid">' +
                    '<dt>Role</dt><dd>' + escapeHtml(p.role) + '</dd>' +
                    '<dt>Gender</dt><dd>' + escapeHtml(p.gender) + '</dd>' +
                    '<dt>Contact No.</dt><dd>' + escapeHtml(p.contact) + '</dd>' +
                    '<dt>Email</dt><dd>' + escapeHtml(p.email) + '</dd>' +
                    '<dt>Institute / Dept.</dt><dd>' + escapeHtml(p.institute) + '</dd>' +
                    '<dt>Course / Section</dt><dd>' + escapeHtml(p.courseSection) + '</dd>' +
                    '<dt>Registered On</dt><dd>' + escapeHtml(p.recordedOn) + '</dd>' +
                    '</dl>' +
                    '<div class="gr-profile-stats">' +
                    '<div class="gr-profile-stat"><div class="num">' + escapeHtml(p.loanCount) + '</div><div class="lbl">Total Checkouts</div></div>' +
                    '<div class="gr-profile-stat"><div class="num">&#8369;' + escapeHtml(p.totalFinesPaid) + '</div><div class="lbl">Fines Paid</div></div>' +
                    '<div class="gr-profile-stat"><div class="num">' + escapeHtml(p.lastBorrowDate) + '</div><div class="lbl">Last Borrow Date</div></div>' +
                    '</div>' +
                    '</div>' +
                    '</div>' +
                    '<p style="font-size:11px; color:var(--gray-500); margin:12px 0 6px;"><i class="fas fa-calendar-alt"></i> ' + dateRangeText + '</p>' +
                    '<h4 style="font-size:12px; margin:8px 0 4px;"><i class="fas fa-book"></i> Resources Borrowed</h4>' +
                    renderResourcesBorrowedTable(p.resourcesBorrowed || []) +
                    '<h4 style="font-size:12px; margin:12px 0 4px;"><i class="fas fa-receipt"></i> Transaction Records</h4>' +
                    renderTransactionRecordsTable(p.transactionRecords || []);
            }

            function generate() {
                hideError();
                if (included.length === 0) {
                    showError("Add at least one query or borrower to the report before generating a preview.");
                    return;
                }
                els.btnGenerate.disabled = true;
                els.btnGenerate.textContent = "Generating…";
                els.emptyState.style.display = "none";
                els.resultsBody.innerHTML = '<div class="gr-skeleton"></div>';

                var order = included.slice();
                Promise.all(order.map(function (item) {
                    if (item.type === "borrower") return api("borrower_detail", { id: item.borrowerId, statuses: item.statuses.join(","), dateFrom: item.dateFrom, dateTo: item.dateTo });
                    if (item.type === "resource") return api("resource_detail", { id: item.resourceId });
                    return api("data", { query: item.key });
                }))
                    .then(function (results) {
                        var title = els.inpTitle.value || "My Report";
                        var generatedAt = results.length ? results[0].generatedAt : "";
                        els.resultsTitle.textContent = title;
                        els.resultsMeta.textContent = els.chkTimestamp.checked
                            ? "Showing library-wide circulation and catalog data · Generated on " + generatedAt
                            : "Showing library-wide circulation and catalog data.";

                        var html = "";
                        order.forEach(function (item, i) {
                            var isBorrower = item.type === "borrower";
                            var isResource = item.type === "resource";
                            var heading = isBorrower ? "Borrower Profile" : (isResource ? "Resource Details" : escapeHtml(item.label));
                            html += '<div class="gr-section-card">' +
                                '<div class="gr-section-card-head">' + heading + '</div>' +
                                '<div class="gr-section-card-body">' +
                                (isBorrower
                                    ? renderProfile(results[i])
                                    : (isResource
                                        ? renderResourceProfile(results[i])
                                        : (((item.mode === "chart" || item.mode === "both") && item.chartType !== "none"
                                            ? '<div class="gr-chart-wrap"><canvas id="grChart' + i + '"></canvas></div>' : '') +
                                            ((item.mode === "table" || item.mode === "both")
                                                ? renderTable(results[i]) : '')))) +
                                '</div>' +
                                '</div>';
                        });
                        html += renderSignatureBlock();
                        els.resultsBody.innerHTML = html;

                        order.forEach(function (item, i) {
                            if (item.type !== "borrower" && item.type !== "resource" && (item.mode === "chart" || item.mode === "both") && item.chartType !== "none") {
                                var canvas = document.getElementById("grChart" + i);
                                if (canvas) renderChart(canvas, results[i]);
                            }
                        });

                        lastRun = { title: title, generatedAt: generatedAt, items: order, results: results };
                        els.btnPrint.disabled = false;
                    })
                    .catch(function (err) {
                        showError("Unable to generate report: " + err.message);
                        els.resultsBody.innerHTML = "";
                        els.emptyState.style.display = "block";
                    })
                    .then(function () {
                        els.btnGenerate.disabled = false;
                        els.btnGenerate.textContent = "Generate Preview";
                    });
            }

            function renderResourceCopiesTable(copies) {
                var columns = [
                    { label: 'Accession No.' },
                    { label: 'Campus', wrap: true },
                    { label: 'Location', wrap: true },
                    { label: 'Status' }
                ];
                var rows = (copies || []).map(function (c) {
                    return [
                        escapeHtml(c.accessionNumber),
                        escapeHtml(c.campus),
                        escapeHtml(c.location),
                        '<span class="gr-copy-status ' + copyStatusClass(c.status) + '">' + escapeHtml(c.status) + '</span>'
                    ];
                });
                var colDefsHtml = columns.map(function (c, i) { return Object.assign({}, c, { allowHtml: i === 3 }); });
                return buildExcelTable(colDefsHtml, rows);
            }

            function renderSignatureBlock() {
                return '<div class="gr-signature-block">' +
                    '<div class="gr-signature-col">' +
                    '<div class="gr-signature-space"></div>' +
                    '<div class="gr-signature-line"></div>' +
                    '<div class="gr-signature-label">Made by</div>' +
                    '<div class="gr-signature-name">' + escapeHtml(adminName || '') + '</div>' +
                    '</div>' +
                    '<div class="gr-signature-col">' +
                    '<div class="gr-signature-space"></div>' +
                    '<div class="gr-signature-line"></div>' +
                    '<div class="gr-signature-label">Approved by</div>' +
                    '<div class="gr-signature-name">&nbsp;</div>' +
                    '</div>' +
                    '</div>';
            }

            function renderResourceProfile(r) {
                var imageHtml = r.coverUrl
                    ? '<div class="gr-resource-gallery"><img src="' + escapeHtml(r.coverUrl) + '" alt="Cover image" /></div>'
                    : '<p style="color:var(--gray-500);"><i class="fas fa-image"></i> No cover image available.</p>';

                var descriptionHtml = r.description ? '<p style="margin-top:6px; font-size:12px; color:var(--gray-700);">' + escapeHtml(r.description) + '</p>' : '';

                return '<div class="gr-resource-profile">' +
                    '<div class="gr-resource-grid">' +
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
                    imageHtml +
                    '<h4 style="font-size:12px; margin:12px 0 4px;"><i class="fas fa-barcode"></i> Item Copies</h4>' +
                    renderResourceCopiesTable(r.copies) +
                    '</div>';
            }

            els.btnPrint.addEventListener("click", function () {
                if (!lastRun) return;
                var config = {
                    title: lastRun.title,
                    palette: els.selChartColor.value,
                    showTimestamp: els.chkTimestamp.checked,
                    adminName: adminName,
                    adminEmail: adminEmail,
                    items: lastRun.items.map(function (it) {
                        return {
                            type: it.type || "query", key: it.key, borrowerId: it.borrowerId,
                            resourceId: it.resourceId,
                            label: it.label, chartType: it.chartType, mode: it.mode,
                            statuses: it.statuses, dateFrom: it.dateFrom, dateTo: it.dateTo
                        };
                    })
                };
                try {
                    sessionStorage.setItem("grReportConfig", JSON.stringify(config));
                } catch (e) {
                    showError("Could not prepare the report for printing: " + e.message);
                    return;
                }
                window.location.href = "PrintReports.aspx";
            });

            els.btnAddQueries.addEventListener("click", addSelected);
            els.btnAddBorrower.addEventListener("click", addBorrowerProfile);
            els.btnAddResource.addEventListener("click", addResourceReport);
            els.btnGenerate.addEventListener("click", generate);

            loadCatalog();
            loadBorrowers();
            loadResources();
        })();
    </script>

</asp:Content>