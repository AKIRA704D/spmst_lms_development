<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="termsServices.aspx.cs" Inherits="spmst_lms_development.Login.termsServices" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Terms &amp; Services – SPAMAST Library</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" rel="stylesheet" />

    <style>
        /* ============================================
           1. Base – lock viewport, no page scroll
           ============================================ */
        html, body {
            height: 100vh;
            overflow: hidden;
        }

        body {
            background: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.3)), url('../Assests/img/lmsa_bg.jpg') no-repeat center center fixed;
            background-size: cover;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
        }

        /* ============================================
           2. Sticky Header (fixed height)
           ============================================ */
        .sticky-header {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            z-index: 1030;
            height: 70px;
            padding: 15px 30px;
            background: rgba(0, 0, 0, 0.4);
            backdrop-filter: blur(5px);
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-sizing: border-box;
        }

        .header-logo {
            height: 35px;
            width: auto;
            object-fit: contain;
            filter: drop-shadow(0 2px 4px rgba(0,0,0,0.15));
            transition: transform 0.3s ease;
        }
        .header-brand:hover .header-logo {
            transform: scale(1.08);
        }
        .header-brand {
            color: #ffffff;
            font-size: 0.95rem;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        .header-brand span {
            display: block;
            font-size: 0.75rem;
            font-weight: 400;
            color: #ced4da;
        }

        .btn-back {
            background-color: #4b51ac;
            color: #ffffff;
            border: none;
            padding: 8px 20px;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 500;
            text-decoration: none;
            transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .btn-back:hover {
            background-color: #3b408c;
            color: #ffffff;
            transform: translateX(-3px);
            box-shadow: 0 4px 12px rgba(75, 81, 172, 0.4);
        }
        .btn-back i {
            transition: transform 0.3s ease;
        }
        .btn-back:hover i {
            transform: translateX(-2px);
        }

        /* ============================================
           3. Content Wrapper – fill remaining space, center card
           ============================================ */
        .content-wrapper {
            height: 100vh;
            padding-top: 70px;          /* offset fixed header */
            box-sizing: border-box;
            display: flex;
            align-items: center;        /* vertical center */
            justify-content: center;    /* horizontal center */
        }

        /* ============================================
           4. Uniform Card – stretches to fit, no overflow
           ============================================ */
        .uniform-card {
            background-color: #ffffff;
            border-radius: 16px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.4);
            overflow: hidden;
            width: 100%;
            max-width: 1050px;
            height: calc(100vh - 100px);  /* fit nicely below header */
            max-height: 850px;            /* optional cap for very tall screens */
            min-height: 500px;            /* safe minimum */
            display: flex;
            border: none;
            flex-shrink: 0;
        }

        /* ============================================
           5. Left Sidebar – fill height
           ============================================ */
        .sidebar-brand {
            background-color: #1a56db;
            width: 45%;
            padding: 40px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            gap: 35px;
            height: 100%;               /* stretch to card height */
        }
        .sidebar-logo {
            width: 175px;
            height: 175px;
            object-fit: contain;
            filter: drop-shadow(0 8px 16px rgba(0, 0, 0, 0.2));
            transition: transform 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }
        .sidebar-logo:hover {
            transform: scale(1.06) rotate(2deg);
        }

        /* ============================================
           6. Right Content Area – flex column, fill height
           ============================================ */
        .content-area {
            width: 55%;
            padding: 30px 35px;          /* slightly tighter padding */
            display: flex;
            flex-direction: column;
            height: 100%;               /* fill card */
            overflow: hidden;           /* prevent content from spilling */
        }

        .content-title {
            color: #111827;
            font-weight: 700;
            font-size: 1.65rem;          /* slightly smaller to save space */
            margin-bottom: 2px;
            flex-shrink: 0;
        }
        .content-subtitle {
            color: #6b7280;
            font-size: 0.85rem;
            margin-bottom: 15px;
            flex-shrink: 0;
        }

        /* ---- PDF iframe takes all remaining space ---- */
        .pdf-iframe {
            width: 100%;
            flex: 1;
            min-width: 0;          /* prevents flex overflow */
            max-width: 100%;       /* ensures it never exceeds the container */
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            background: #f8fafc;
            height: auto;          /* let flex decide the height */
        }

        #pnlPdf {
            display: flex;
            flex: 1;
            min-width: 0;
            overflow: hidden;
        }

        .fallback-box {
            text-align: center;
            padding: 40px 20px;
            background: #f8fafc;
            border-radius: 8px;
            border: 1px dashed #d1d5db;
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .fallback-box i {
            font-size: 3.5rem;
            color: #9ca3af;
            margin-bottom: 15px;
        }
        .fallback-box h5 {
            color: #374151;
            font-weight: 600;
        }
        .fallback-box p {
            color: #6b7280;
            font-size: 0.9rem;
            margin: 0;
        }

        .admin-upload-link {
            margin-top: 12px;
            text-align: right;
            flex-shrink: 0;
        }

        /* ============================================
           7. Responsive – keep card fitting
           ============================================ */
        @media (max-width: 991.98px) {
            .uniform-card { max-width: 720px; height: auto; max-height: 90vh; min-height: auto; }
            .sidebar-brand { width: 40%; padding: 30px; gap: 25px; }
            .sidebar-logo { width: 130px; height: 130px; }
            .content-area { width: 60%; padding: 25px 28px; }
        }
        @media (max-width: 767.98px) {
            .content-wrapper { padding-top: 65px; }
            .uniform-card { flex-direction: column; max-width: 480px; height: auto; max-height: 92vh; }
            .sidebar-brand { width: 100%; padding: 25px 20px; flex-direction: row; gap: 30px; height: auto; }
            .sidebar-logo { width: 80px; height: 80px; }
            .content-area { width: 100%; padding: 20px; height: auto; flex: 1; }
            .pdf-iframe { min-height: 300px; flex: 1; }
            .sticky-header { padding: 10px 18px; height: 60px; }
            .content-title { font-size: 1.3rem; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <!-- Sticky Header -->
        <header class="sticky-header">
            <div class="header-brand d-flex align-items-center">
                <img src="../Assests/img/lmsa_logo.png" alt="LMSA Logo" class="header-logo me-2" />
                <div>
                    <strong>SPAMAST LIBRARY</strong>
                    <span>LMSA v2.0 Platform</span>
                </div>
            </div>
            <a href="login.aspx" class="btn-back">
                <i class="fa-solid fa-arrow-left"></i><span>Back to Login</span>
            </a>
        </header>

        <div class="content-wrapper">
            <div class="uniform-card">
                <!-- Left Brand Sidebar -->
                <div class="sidebar-brand">
                    <img src="../Assests/img/lib_logo_wbg.png" alt="LMSA Logo" class="sidebar-logo" />
                    <img src="../Assests/img/spmst_logo_wbg.png" alt="SPAMAST Logo" class="sidebar-logo" />
                </div>

                <!-- Right Content Area -->
                <div class="content-area">
                    <h1 class="content-title"><i class="fas fa-file-pdf text-danger me-2"></i>Terms &amp; Services</h1>
                    <p class="content-subtitle">Review the library's terms and conditions.</p>

                    <!-- PDF Viewer Panel (shown if PDF exists) -->
                    <asp:Panel ID="pnlPdf" runat="server" Visible="true" style="display: flex; flex: 1; min-height: 0;">
                        <iframe id="pdfFrame" runat="server" class="pdf-iframe" src=""></iframe>
                    </asp:Panel>

                    <!-- Fallback Panel (shown if PDF is missing) -->
                    <asp:Panel ID="pnlFallback" runat="server" Visible="false" CssClass="fallback-box">
                        <i class="fas fa-file-pdf"></i>
                        <h5>Terms & Services PDF Not Available</h5>
                        <p>Please contact the library administrator.</p>
                    </asp:Panel>

                    <!-- Admin upload link (visible only to admin) -->
                    <div class="admin-upload-link">
                        <asp:HyperLink ID="lnkUpload" runat="server" NavigateUrl="UploadTerms.aspx" CssClass="btn btn-outline-primary btn-sm" Visible="false">
                            <i class="fas fa-upload me-1"></i> Update PDF
                        </asp:HyperLink>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>