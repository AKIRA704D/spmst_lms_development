<%@ Page Title="" Language="C#" MasterPageFile="~/Users/MasterPage/admin.Master" AutoEventWireup="true" CodeBehind="TransactionImport.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Import.TransactionImport" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

        <div class="container-fluid py-4">
        <div class="card border-0 shadow-sm mb-4">
            <div class="card-body p-4">
                <h4 class="mb-3">Batch Import Transactions</h4>
                <p class="text-muted">
                    Upload a CSV file to bulk add borrow/return transactions.
                    Penalty columns (<code>fine_amount</code>, <code>amount_paid</code>, <code>balance</code>,
                    <code>fine_status</code>, <code>paid_date</code>, <code>penalty_type</code>, <code>reason</code>)
                    are optional and, when present, will also create a row in <strong>Penalties</strong>.
                </p>

                <div id="alertPlaceholder" runat="server"></div>

                <div class="row g-3 align-items-end">
                    <div class="col-12 col-md-7 col-lg-8">
                        <label class="form-label fw-semibold small text-uppercase mb-1">Select CSV File</label>
                        <asp:FileUpload ID="fuCSVImport" runat="server" CssClass="form-control form-control-sm" accept=".csv" />
                        <small class="text-muted">
                            <i class="fas fa-info-circle"></i> Required: <strong>user_id</strong>, <strong>accession_number</strong>,
                            <strong>borrow_date</strong>, <strong>due_date</strong>. All other fields are optional.
                            &nbsp;–&nbsp;
                            <a href="#" onclick="downloadSampleCSV(); return false;" class="text-primary">
                                <i class="fas fa-download"></i> Download Sample CSV
                            </a>
                        </small>
                    </div>
                    <div class="col-12 col-md-5 col-lg-4">
                        <asp:Button ID="btnImport" runat="server" Text="Start Import"
                            OnClick="btnImport_Click" CssClass="btn btn-primary btn-sm px-4" />
                    </div>
                </div>
            </div>
        </div>

        <asp:Panel ID="pnlResults" runat="server" Visible="false">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white py-3 border-0 border-bottom d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <h6 class="mb-0 fw-bold text-success">
                        <i class="fas fa-check-circle me-2"></i>Import Results
                    </h6>

                    <div class="d-flex align-items-center gap-3">
                        <asp:Label ID="lblImportSummary" runat="server" CssClass="fw-semibold" />
                        <div class="progress" style="width: 160px; height: 8px;">
                            <asp:Literal ID="litProgressBar" runat="server" />
                        </div>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive" style="max-height: 450px; overflow-y: auto;">
                        <asp:GridView ID="gvResults" runat="server" AutoGenerateColumns="false"
                            CssClass="table table-hover align-middle mb-0" GridLines="None"
                            EmptyDataText="No rows were processed.">
                            <HeaderStyle CssClass="text-uppercase small text-muted" />
                            <Columns>
                                <asp:BoundField DataField="user_id" HeaderText="USER ID" />
                                <asp:BoundField DataField="accession_number" HeaderText="ACCESSION NO." />
                                <asp:BoundField DataField="borrow_date" HeaderText="BORROW DATE" />
                                <asp:BoundField DataField="due_date" HeaderText="DUE DATE" />
                                <asp:BoundField DataField="return_date" HeaderText="RETURN DATE" />
                                <asp:BoundField DataField="status" HeaderText="LOAN STATUS" />
                                <asp:TemplateField HeaderText="RESULT">
                                    <ItemTemplate>
                                        <span class='badge <%# GetStatusBadgeClass(Eval("result").ToString()) %>'>
                                            <%# Eval("result") %>
                                        </span>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </div>
        </asp:Panel>
    </div>

    <script>
        document.getElementById('<%= btnImport.ClientID %>').addEventListener('click', function (e) {
            var fileInput = document.getElementById('<%= fuCSVImport.ClientID %>');
            if (!fileInput.files || fileInput.files.length === 0) {
                Swal.fire({
                    icon: 'warning',
                    title: 'No File Selected',
                    text: 'Please select a CSV file to import.',
                    confirmButtonColor: '#002447'
                });
                e.preventDefault();
                return false;
            }
        });

        function downloadSampleCSV() {
            // Matches SPAMAST_LMSv2 schema:
            //   Transactions: user_id, accession_number, borrow_date, due_date, return_date,
            //                 status, is_damaged, is_lost, remarks
            //   Penalties:    penalty_type, reason, fine_amount, amount_paid, balance,
            //                 fine_status, paid_date   (optional — creates a Penalties row)
            var headers = [
                'user_id', 'accession_number', 'borrow_date', 'due_date', 'return_date',
                'status', 'is_damaged', 'is_lost', 'remarks',
                'penalty_type', 'reason', 'fine_amount', 'amount_paid', 'balance',
                'fine_status', 'paid_date'
            ];

            var sampleRows = [
                // Simple borrow, no penalty
                ['2024-0001', 'C001', '2024-01-15', '2024-02-14', '',
                    'Borrowed', 0, 0, 'Regular borrowing',
                    '', '', '', '', '', '', ''],

                // Returned on time, no penalty
                ['FAC-001', 'N001', '2024-02-01', '2024-02-15', '2024-02-10',
                    'Returned', 0, 0, 'Returned on time',
                    '', '', '', '', '', '', ''],

                // Overdue with partial payment — creates a Penalties row
                ['2024-0002', 'DVD001', '2024-03-01', '2024-03-08', '',
                    'Borrowed', 0, 0, 'Partial payment received',
                    'Overdue', 'Late return fine', 25.00, 10.00, 15.00,
                    'Partial', '2024-03-20'],

                // Lost item — penalty fully paid
                ['2024-0003', 'C002', '2024-01-05', '2024-01-19', '2024-02-01',
                    'Returned', 0, 1, 'Item reported lost and paid',
                    'Lost', 'Lost book replacement', 500.00, 500.00, 0.00,
                    'Paid', '2024-02-01']
            ];

            var csvContent = headers.join(',') + '\n';
            sampleRows.forEach(function (row) {
                var quotedRow = row.map(function (field) {
                    if (typeof field === 'string' && (field.indexOf(',') > -1 || field.indexOf('"') > -1)) {
                        return '"' + field.replace(/"/g, '""') + '"';
                    }
                    return field;
                });
                csvContent += quotedRow.join(',') + '\n';
            });

            var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            var link = document.createElement('a');
            var url = URL.createObjectURL(blob);
            link.href = url;
            link.setAttribute('download', 'sample_transaction_import.csv');
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        }
    </script>
</asp:Content>
