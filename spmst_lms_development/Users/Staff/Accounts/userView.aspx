<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="userView.aspx.cs" Inherits="spmst_lms_development.Users.Staff.Accounts.userView" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>User Details</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" />
    <style>
    [v-cloak] { display: none; }

    .loading-shimmer {
        background: linear-gradient(90deg, #f0f0f0 25%, #f7f7f7 50%, #f0f0f0 75%);
        background-size: 200% 100%;
        animation: shimmer 1.5s infinite;
    }
    @keyframes shimmer {
        0%   { background-position: 200% 0; }
        100% { background-position: -200% 0; }
    }

    .status-badge {
        font-size: 9px;
        font-weight: 700;
        padding: 0.25rem 0.5rem;
        border-radius: 0.25rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .status-returned { background-color: #d1fae5; color: #065f46; }
    .status-overdue  { background-color: #fee2e2; color: #991b1b; }
    .status-borrowed { background-color: #dbeafe; color: #1e40af; }
    .status-default  { background-color: #f3f4f6; color: #374151; }
</style>
    <script>
        function getStatusClass(status) {
            if (!status) return 'status-default';
            switch (status.toLowerCase()) {
                case 'returned': return 'status-returned';
                case 'overdue': return 'status-overdue';
                case 'borrowed': return 'status-borrowed';
                default: return 'status-default';
            }
        }
    </script>
</head>
<body class="bg-gray-100/50 overflow-hidden">
    <div id="loader" class="fixed inset-0 z-50 bg-white flex flex-col items-center justify-center">
        <div class="w-12 h-12 border-4 border-blue-100 border-t-blue-600 rounded-full animate-spin"></div>
        <p class="mt-4 text-xs font-bold text-gray-400 uppercase tracking-widest">Fetching Profile...</p>
    </div>

    <form id="form1" runat="server" class="w-full flex flex-col">
        <div class="px-6 py-5 bg-[#002447] text-white flex justify-between items-center sticky top-0 z-10">
            <div>
                <h2 class="text-lg font-bold uppercase tracking-tight">Patron Profile</h2>
                <p class="text-[10px] text-blue-200 uppercase tracking-widest font-semibold">View authenticated user details</p>
            </div>
            <button type="button" onclick="window.parent.closeUniversalModal()" class="text-white hover:text-gray-300">
                <i class="fa-solid fa-xmark text-xl"></i>
            </button>
        </div>

        <div class="p-6 flex-grow space-y-6 opacity-0 transition-opacity duration-500" id="mainContent">
            <!-- User Profile -->
            <div class="flex items-center gap-5 pb-6 border-b border-gray-100">
                <div class="w-20 h-20 bg-blue-50 rounded-full overflow-hidden flex items-center justify-center text-[#002447] text-3xl font-bold ring-4 ring-blue-50">
                    <asp:Literal ID="litAvatar" runat="server"></asp:Literal>
                </div>
                <div>
                    <h2 class="text-2xl font-bold text-gray-800 uppercase leading-tight">
                        <asp:Literal ID="litFullName" runat="server"></asp:Literal>
                    </h2>
                    <div class="flex items-center gap-2 mt-2">
                        <span class="text-[10px] font-bold px-2 py-0.5 bg-slate-100 text-slate-600 rounded uppercase tracking-wider">
                            <asp:Literal ID="litRole" runat="server"></asp:Literal>
                        </span>
                        <span id="statusBadge" runat="server" class="text-[10px] font-bold px-2 py-0.5 rounded-full uppercase">
                            <asp:Literal ID="litStatus" runat="server"></asp:Literal>
                        </span>
                    </div>
                </div>
            </div>

            <!-- User Identity & Affiliation -->
            <label class="block text-[11px] font-bold text-blue-900 uppercase tracking-widest border-b border-gray-100 pb-2">Identity & Affiliation</label>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
                <div class="flex flex-col">
                    <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">ID Number</span>
                    <span class="text-gray-700 font-semibold tracking-wide text-sm">
                        <asp:Literal ID="litUserID" runat="server"></asp:Literal></span>
                </div>

                <asp:PlaceHolder ID="phAcademicInfo" runat="server" Visible="false">
                    <div class="flex flex-col">
                        <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Institute</span>
                        <span class="text-gray-700 font-semibold uppercase text-sm">
                            <asp:Literal ID="litInstitute" runat="server"></asp:Literal></span>
                    </div>
                    <div class="flex flex-col">
                        <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Course & Section</span>
                        <span class="text-gray-700 font-semibold uppercase text-sm">
                            <asp:Literal ID="litCourse" runat="server"></asp:Literal>
                            -
                            <asp:Literal ID="litSection" runat="server"></asp:Literal>
                        </span>
                    </div>
                    <div class="flex flex-col">
                        <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Year Level</span>
                        <span class="text-gray-700 font-semibold uppercase text-sm">
                            <asp:Literal ID="litYear" runat="server"></asp:Literal></span>
                    </div>
                </asp:PlaceHolder>

                <asp:PlaceHolder ID="phStaffHeader" runat="server" Visible="false">
                    <div class="flex flex-col col-span-3">
                        <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Office / Department</span>
                        <span class="text-gray-700 font-semibold uppercase text-sm">
                            <asp:Literal ID="litDept" runat="server"></asp:Literal></span>
                    </div>
                </asp:PlaceHolder>
            </div>

            <!-- User Contact Information -->
            <label class="block text-[11px] font-bold text-blue-900 uppercase tracking-widest border-b border-gray-100 pb-2">Contact Information</label>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 pt-2">
                <div class="flex flex-col">
                    <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Gender</span>
                    <span class="text-gray-700 font-medium capitalize text-sm">
                        <asp:Literal ID="litGender" runat="server"></asp:Literal></span>
                </div>
                <div class="flex flex-col">
                    <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Mobile Number</span>
                    <span class="text-gray-700 font-medium text-sm">
                        <asp:Literal ID="litContact" runat="server"></asp:Literal></span>
                </div>
                <div class="flex flex-col">
                    <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Institutional Email</span>
                    <span class="text-[#002447] font-medium text-sm underline underline-offset-4">
                        <asp:Literal ID="litEmail" runat="server"></asp:Literal></span>
                </div>
                <div class="flex flex-col md:col-span-3">
                    <span class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Address</span>
                    <span class="text-gray-700 font-medium text-sm">
                        <asp:Literal ID="litAddress" runat="server"></asp:Literal></span>
                </div>
            </div>

            <!-- User Recent Borrowing History -->
            <label class="block text-[11px] font-bold text-blue-900 uppercase tracking-widest border-b border-gray-100 pb-2 mt-8">Recent Borrowing History</label>

            <div class="overflow-x-auto mt-4 rounded-xl border border-gray-100">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-gray-50 border-b border-gray-100">
                            <th class="px-4 py-3 text-[10px] font-bold text-gray-400 uppercase tracking-widest">Book Title</th>
                            <th class="px-4 py-3 text-[10px] font-bold text-gray-400 uppercase tracking-widest text-center">Borrowed</th>
                            <th class="px-4 py-3 text-[10px] font-bold text-gray-400 uppercase tracking-widest text-center">Due Date</th>
                            <th class="px-4 py-3 text-[10px] font-bold text-gray-400 uppercase tracking-widest text-center">Status</th>
                        </tr>
                    </thead>
                    <tbody class="text-sm">
                        <asp:Repeater ID="rptHistory" runat="server">
                            <ItemTemplate>
                                <tr class="border-b border-gray-50 hover:bg-blue-50/30 transition-colors">
                                    <td class="px-4 py-3">
                                        <p class="font-bold text-gray-700 uppercase leading-tight"><%# Eval("BookTitle") %></p>
                                        <p class="text-[10px] text-gray-400 italic font-medium"><%# Eval("ISBN") %></p>
                                    </td>
                                    <td class="px-4 py-3 text-center text-gray-600 font-medium">
                                        <%# Convert.ToDateTime(Eval("DateBorrowed")).ToString("MMM dd, yyyy") %>
                                    </td>
                                    <td class="px-4 py-3 text-center text-gray-600 font-medium">
                                        <%# Convert.ToDateTime(Eval("DueDate")).ToString("MMM dd, yyyy") %>
                                    </td>
                                    <td class="px-4 py-3 text-center">
                                        <span class='status-badge' data-status='<%# Eval("Status") %>'>
                                            <%# Eval("Status") %>
                                        </span>
                                    </td>
                                </tr>
                            </ItemTemplate>
                        </asp:Repeater>
                    </tbody>
                </table>
            </div>

            <asp:PlaceHolder ID="phNoHistory" runat="server" Visible="false">
                <div class="p-10 text-center flex flex-col items-center">
                    <i class="fa-solid fa-book-open text-gray-200 text-4xl mb-3"></i>
                    <p class="text-xs font-bold text-gray-400 uppercase tracking-widest">No transaction records found</p>
                </div>
            </asp:PlaceHolder>
        </div>

        <div class="px-6 py-4 bg-gray-50 border-t border-gray-100 flex items-center justify-between sticky bottom-0">
            <div class="flex items-center text-green-600 italic text-[10px] tracking-tight">
                <i class="fas fa-shield-alt mr-2"></i>
                AUTHENTICATED PROFILE &bull; LMSA SYSTEM
            </div>
            <div class="flex gap-2">
                <button type="button" onclick="window.parent.closeUniversalModal()"
                    class="px-8 py-2.5 bg-[#002447] text-white rounded-lg text-xs font-bold uppercase tracking-widest cursor-pointer hover:bg-slate-800 transition-colors">
                    Close View
                </button>
            </div>
        </div>
    </form>

    <script>
        // Apply status badge classes after repeater binding
        function applyStatusBadges() {
            document.querySelectorAll('.status-badge').forEach(function (el) {
                el.classList.add(getStatusClass(el.getAttribute('data-status')));
            });
        }

        function notifyParentResize() {
            try {
                if (window.parent && window.parent !== window &&
                    typeof window.parent.resizeModalIframe === 'function') {
                    window.parent.resizeModalIframe();
                }
            } catch (e) { /* cross-origin – ignore */ }
        }

        window.addEventListener('load', function () {
            setTimeout(function () {
                var loader = document.getElementById('loader');
                var main = document.getElementById('mainContent');
                if (loader) loader.classList.add('hidden');
                if (main) main.classList.remove('opacity-0');
                applyStatusBadges();
                notifyParentResize();   // re-measure once content is actually painted
            }, 300);
        });

        // Re-measure if fonts/layout shift after paint
        window.addEventListener('resize', notifyParentResize);

        var prm = Sys.WebForms.PageRequestManager.getInstance();
        if (prm) {
            prm.add_endRequest(function () {
                applyStatusBadges();
                notifyParentResize();
            });
        }
    </script>
</body>
</html>
