<%@ Page Title="New Book Record" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="bookNew.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Inventory.bookNew" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <link rel="stylesheet" href="../../../Assets/Themes/spmast-theme.css" />
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <style>
        .required-star { color: #dc3545; font-weight: bold; }

        .section-header {
            background-color: var(--sp-paper);
            border-left: 4px solid var(--sp-gold);
            padding: 0.5rem 1rem;
            font-weight: 700;
            text-transform: uppercase;
            font-size: 0.75rem;
            color: var(--sp-green-900);
            margin-bottom: 1.25rem;
            border-radius: 0 var(--sp-radius) var(--sp-radius) 0;
        }

        .form-label {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            color: var(--sp-green-900);
            margin-bottom: 0.25rem;
            letter-spacing: 0.02em;
        }

        .btn-primary-custom {
            background-color: var(--sp-green-700);
            border: 1px solid var(--sp-green-700);
            color: #fff;
        }
        .btn-primary-custom:hover,
        .btn-primary-custom:focus {
            background-color: var(--sp-green-800);
            border-color: var(--sp-green-800);
            color: #fff;
        }
        .btn-outline-secondary {
            border-color: var(--sp-line);
            color: var(--sp-green-900);
        }
        .btn-outline-secondary:hover {
            background-color: var(--sp-green-900);
            border-color: var(--sp-green-900);
            color: #fff;
        }

        .form-control:focus,
        .form-select:focus {
            border-color: var(--sp-gold);
            box-shadow: 0 0 0 0.2rem rgba(212, 160, 23, 0.25);
        }

        .full-width-header {
            background-color: var(--sp-green-900);
            color: #fff;
            padding: 0.75rem 1.5rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .full-width-header h2 { font-family: var(--sp-serif); }

        .form-body-container {
            max-width: var(--sp-wrap);
            margin: 0 auto;
            padding: 1.5rem;
            background: var(--sp-paper);
            min-height: calc(100vh - 70px);
            overflow-y: auto;
            font-family: var(--sp-sans);
            color: var(--sp-ink);
        }

        .cover-card {
            background: #fff;
            border: 1px solid var(--sp-line);
            border-radius: var(--sp-radius);
            padding: 1rem;
            box-shadow: 0 1px 3px rgba(11, 61, 44, 0.06);
            position: sticky;
            top: 1rem;
        }
        .cover-image {
            width: 100%;
            aspect-ratio: 2 / 3;
            object-fit: contain;
            background: #f1f3f1;
            border: 1px solid var(--sp-line);
            border-radius: 4px;
            display: block;
        }
        .cover-caption {
            text-align: center;
            font-size: 0.7rem;
            color: var(--sp-green-900);
            margin-top: 0.5rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-weight: 600;
        }

        @media (max-width: 991.98px) {
            .cover-card { position: static; max-width: 260px; margin: 0 auto 1.5rem; }
        }
        @media (max-width: 575.98px) {
            .form-body-container { padding: 1rem; }
            .cover-card { max-width: 200px; }
            .btn { min-height: 44px; }
            .form-control, .form-select { font-size: 16px; }
        }

        html, body { overflow-x: hidden; }
    </style>

    <script type="text/javascript">
        function showSweetAlert(title, message, icon, isMismatch) {
            const mismatchMode = (isMismatch === true || isMismatch === 'true');
            Swal.fire({
                title: title,
                html: message.replace(/\n/g, '<br>'),
                icon: icon,
                showCancelButton: mismatchMode,
                showConfirmButton: true,
                confirmButtonText: mismatchMode ? 'Update Existing Record' : 'OK',
                cancelButtonText: mismatchMode ? 'Stop & Verify' : '',
                confirmButtonColor: '#14532d',
                cancelButtonColor: '#d33',
                reverseButtons: true,
                allowOutsideClick: !mismatchMode
            }).then((result) => {
                if (mismatchMode && result.isConfirmed) {
                    document.getElementById('<%= hfForceUpdate.ClientID %>').value = "true";
                    document.getElementById('<%= btnSave.ClientID %>').click();
                } else if (mismatchMode && result.dismiss === Swal.DismissReason.cancel) {
                    document.getElementById('<%= hfForceUpdate.ClientID %>').value = "false";
                    document.getElementById('<%= txtISBN.ClientID %>').focus();
                }
            });
        }

        function formatISBN(input) {
            let val = input.value.replace(/[^0-9X]/gi, '').toUpperCase();
            let out = '';
            if (val.length <= 10) {
                for (let i = 0; i < val.length; i++) {
                    if (i === 1 || i === 4 || i === 9) out += '-';
                    out += val[i];
                }
            } else {
                for (let i = 0; i < val.length; i++) {
                    if (i === 3 || i === 4 || i === 7 || i === 12) out += '-';
                    out += val[i];
                }
            }
            input.value = out.substring(0, 17);
        }

        function formatISSN(input) {
            let val = input.value.replace(/[^0-9X]/gi, '').toUpperCase();
            let out = '';
            for (let i = 0; i < val.length; i++) {
                if (i === 4) out += '-';
                out += val[i];
            }
            input.value = out.substring(0, 9);
        }

        function validateAccession() {
            var accessionField = document.getElementById('<%= txtAccession.ClientID %>');
            var accession = accessionField.value.trim();
            if (accession === '') {
                Swal.fire({ icon: 'warning', title: 'Validation Error', text: 'Accession Number is required.', confirmButtonColor: '#14532d' });
                accessionField.focus();
                return false;
            }
            accessionField.value = accession.toUpperCase();
            return true;
        }

        document.addEventListener('DOMContentLoaded', function () {
            var isbnField = document.getElementById('<%= txtISBN.ClientID %>');
            var issnField = document.getElementById('<%= txtISSN.ClientID %>');
            if (isbnField) {
                isbnField.addEventListener('keypress', function (e) {
                    if (e.key === 'Enter') { e.preventDefault(); document.getElementById('<%= btnCheckISBN.ClientID %>').click(); }
                });
            }
            if (issnField) {
                issnField.addEventListener('keypress', function (e) {
                    if (e.key === 'Enter') { e.preventDefault(); document.getElementById('<%= btnCheckISSN.ClientID %>').click(); }
                });
            }
        });
    </script>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <asp:HiddenField ID="hfForceUpdate" runat="server" Value="false" />

    <div class="full-width-header">
        <h2 class="h4 mb-0 fw-bold"><i class="fas fa-book-medical text-warning me-2"></i>New Book Record</h2>
        <asp:LinkButton ID="btnClose" runat="server" OnClick="BtnExit_Click" CssClass="btn-close btn-close-white" />
    </div>

    <div class="form-body-container">
        <div class="row g-4">

            <div class="col-12 col-md-4 col-lg-3">
                <div class="cover-card">
                    <asp:Image ID="imgCover" runat="server"
                               ImageUrl="~/Assets/Covers/default-cover.jpg"
                               AlternateText="Book Cover"
                               CssClass="cover-image" />
                    <div class="cover-caption">Book Cover</div>
                </div>
            </div>

            <div class="col-12 col-md-8 col-lg-9">
                <div class="row g-4">

                    <div class="col-12">
                        <div class="section-header">1. Identification</div>
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Accession Number <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtAccession" runat="server" CssClass="form-control" placeholder="e.g. LIB-2023-001" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Item Type</label>
                        <asp:TextBox ID="txtItemType" runat="server" CssClass="form-control" placeholder="e.g. Book, Journal" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Genre</label>
                        <asp:TextBox ID="txtGenre" runat="server" CssClass="form-control" placeholder="e.g. Fiction" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Call Number <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtCallNumber" runat="server" CssClass="form-control" placeholder="e.g. QA76.73 .C154 2023" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Dewey Decimal <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtDewey" runat="server" CssClass="form-control" placeholder="e.g. 005.133" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">ISBN <span class="required-star">*</span></label>
                        <div class="input-group">
                            <asp:TextBox ID="txtISBN" runat="server" CssClass="form-control" placeholder="0123-4-567-89101-2" onkeyup="formatISBN(this)" />
                            <asp:Button ID="btnCheckISBN" runat="server" Text="Check" OnClick="CheckExistingResource" CssClass="btn btn-outline-secondary" UseSubmitBehavior="false" />
                        </div>
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">ISSN</label>
                        <div class="input-group">
                            <asp:TextBox ID="txtISSN" runat="server" CssClass="form-control" placeholder="1234-5678" onkeyup="formatISSN(this)" />
                            <asp:Button ID="btnCheckISSN" runat="server" Text="Check" OnClick="CheckExistingResource" CssClass="btn btn-outline-secondary" UseSubmitBehavior="false" />
                        </div>
                    </div>

                    <div class="col-12 mt-4">
                        <div class="section-header">2. Bibliographic Details</div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Book Title <span class="required-star">*</span></label>
                        <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Authors</label>
                        <asp:TextBox ID="txtAuthors" runat="server" CssClass="form-control" placeholder="Separate multiple with commas" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Volume No.</label>
                        <asp:TextBox ID="txtVolume" runat="server" CssClass="form-control" placeholder="e.g. Vol. 1" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Issue No.</label>
                        <asp:TextBox ID="txtIssue" runat="server" CssClass="form-control" placeholder="e.g. No. 3" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Series</label>
                        <asp:TextBox ID="txtSeries" runat="server" CssClass="form-control" placeholder="e.g. Springer Series" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Section</label>
                        <asp:DropDownList ID="ddlSection" runat="server" CssClass="form-select mb-2"></asp:DropDownList>
                        <asp:TextBox ID="txtNewSection" runat="server" CssClass="form-control mt-1" placeholder="Or add new section" />
                    </div>

                    <div class="col-12 mt-4">
                        <div class="section-header">3. Publication Details</div>
                    </div>
                    <div class="col-sm-6 col-lg-4">
                        <label class="form-label">Publisher Name</label>
                        <asp:TextBox ID="txtPublisher" runat="server" CssClass="form-control" />
                    </div>
                    <div class="col-sm-6 col-lg-4">
                        <label class="form-label">Place of Publication</label>
                        <asp:TextBox ID="txtPlace" runat="server" CssClass="form-control" placeholder="e.g. New York" />
                    </div>
                    <div class="col-sm-6 col-lg-4">
                        <label class="form-label">Edition</label>
                        <asp:TextBox ID="txtEdition" runat="server" CssClass="form-control" placeholder="e.g. 3rd Edition" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Publication Year</label>
                        <asp:TextBox ID="txtPubYear" runat="server" CssClass="form-control" TextMode="Number" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Copyright Year</label>
                        <asp:TextBox ID="txtCopyright" runat="server" CssClass="form-control" TextMode="Number" />
                    </div>

                    <div class="col-12 mt-4">
                        <div class="section-header">4. Physical Description</div>
                    </div>
                    <div class="col-sm-6 col-lg-4">
                        <label class="form-label">Pages</label>
                        <asp:TextBox ID="txtPages" runat="server" CssClass="form-control" placeholder="e.g. xii, 345" />
                    </div>
                    <div class="col-sm-3 col-lg-2">
                        <label class="form-label">Height (cm)</label>
                        <asp:TextBox ID="txtHeight" runat="server" CssClass="form-control" TextMode="Number" step="0.01" />
                    </div>
                    <div class="col-sm-3 col-lg-2">
                        <label class="form-label">Width (cm)</label>
                        <asp:TextBox ID="txtWidth" runat="server" CssClass="form-control" TextMode="Number" step="0.01" />
                    </div>
                    <div class="col-sm-12 col-lg-4">
                        <label class="form-label">Accompanying Material</label>
                        <asp:TextBox ID="txtMaterial" runat="server" CssClass="form-control" placeholder="e.g. CD-ROM" />
                    </div>
                    <div class="col-12">
                        <label class="form-label">Description</label>
                        <asp:TextBox ID="txtDescription" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Book summary or notes" />
                    </div>

                    <div class="col-12 mt-4">
                        <div class="section-header">5. Copy Information</div>
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Binding Type <span class="required-star">*</span></label>
                        <asp:DropDownList ID="ddlBinding" runat="server" CssClass="form-select mb-2"></asp:DropDownList>
                        <asp:TextBox ID="txtNewBinding" runat="server" CssClass="form-control mt-1" placeholder="Or add new binding" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Campus</label>
                        <asp:DropDownList ID="ddlCampus" runat="server" CssClass="form-select mb-2"></asp:DropDownList>
                        <div class="input-group">
                            <asp:TextBox ID="txtNewCampus" runat="server" CssClass="form-control" placeholder="Or add new campus" />
                            <asp:Button ID="btnAddCampus" runat="server" Text="Add" OnClick="BtnAddCampus_Click"
                                        CssClass="btn btn-outline-secondary" UseSubmitBehavior="false" CausesValidation="false" />
                        </div>
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Specific Location</label>
                        <asp:TextBox ID="txtSpecificLocation" runat="server" CssClass="form-control" placeholder="e.g. Shelf 4" />
                    </div>
                    <div class="col-sm-6 col-lg-3">
                        <label class="form-label">Status Condition <span class="required-star">*</span></label>
                        <asp:DropDownList ID="ddlCondition" runat="server" CssClass="form-select">
                            <asp:ListItem Text="-- Choose --" Value="" />
                            <asp:ListItem Text="Good" Value="Good" />
                            <asp:ListItem Text="Damage" Value="Damage" />
                        </asp:DropDownList>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Remarks</label>
                        <asp:TextBox ID="txtRemarks" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2" />
                    </div>

                    <div class="col-12 mt-4 d-flex flex-wrap justify-content-end gap-3">
                        <asp:LinkButton ID="btnCancel" runat="server" OnClick="BtnExit_Click" CssClass="btn btn-outline-secondary px-4">
                            <i class="fas fa-times me-1"></i> Cancel
                        </asp:LinkButton>
                        <asp:LinkButton ID="btnSave" runat="server" OnClick="BtnSave_Click" OnClientClick="return validateAccession();" CssClass="btn btn-primary-custom px-5">
                            <i class="fas fa-save me-1"></i> Save Record
                        </asp:LinkButton>
                    </div>

                </div>
            </div>

        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
</asp:Content>