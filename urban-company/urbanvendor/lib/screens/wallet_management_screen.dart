import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class WalletManagementScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;
  const WalletManagementScreen({super.key, this.isTab = false, this.onBack});

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  // Sub-view index:
  // 0: Wallet Dashboard
  // 1: Earnings Dashboard
  // 2: Transaction History
  // 3: Withdrawal Form
  // 4: Withdrawal History
  // 5: Bank Accounts Management
  // 6: UPI Management
  // 7: Tax Dashboard
  // 8: Settlement Reports
  // 9: Commission Dashboard
  // 10: Invoices List
  // 11: Financial Analytics
  int _activeViewIndex = 0;

  // Earnings View Tab
  String _earningsTab = "Weekly"; // Weekly, Monthly, Yearly

  // Transactions Search & Filters
  String _txSearchQuery = "";
  String _txTypeFilter = "All"; // All, Earned, Withdrawn, Tax, Fee
  String _txStatusFilter = "All"; // All, Completed, Pending, Failed

  // Withdrawal form inputs
  final _withdrawController = TextEditingController(text: "5000");
  String _selectedWithdrawMethod = "Bank Account"; // Bank Account, UPI

  // Bank Accounts Management State
  List<Map<String, dynamic>> _bankAccounts = [
    {
      "id": "bank_1",
      "bankName": "HDFC Bank",
      "accountNo": "•••• •••• 9824",
      "holderName": "Vishal Patel",
      "ifsc": "HDFC0000124",
      "isPrimary": true,
      "status": "Verified",
    },
    {
      "id": "bank_2",
      "bankName": "ICICI Bank",
      "accountNo": "•••• •••• 4512",
      "holderName": "Vishal Patel",
      "ifsc": "ICIC0000045",
      "isPrimary": false,
      "status": "Pending Verification",
    }
  ];

  // UPI Accounts Management State
  List<Map<String, dynamic>> _upiAccounts = [
    {
      "id": "upi_1",
      "upiId": "vishalpatel@okaxis",
      "isPrimary": true,
      "status": "Verified",
    },
    {
      "id": "upi_2",
      "upiId": "9876543210@paytm",
      "isPrimary": false,
      "status": "Verified",
    }
  ];

  // Dummy Transaction Data
  final List<Map<String, dynamic>> _transactions = [
    {
      "id": "TXN_7824109",
      "bookingId": "BK_9082",
      "customerName": "Rohan Sharma",
      "type": "Earned",
      "method": "Online (UPI)",
      "amount": 2450.0,
      "commission": 245.0,
      "tax": 122.5,
      "net": 2082.5,
      "date": "2026-07-28 09:15 AM",
      "status": "Completed",
    },
    {
      "id": "TXN_7824108",
      "bookingId": "BK_9081",
      "customerName": "Priyanka Sen",
      "type": "Earned",
      "method": "Card",
      "amount": 1800.0,
      "commission": 180.0,
      "tax": 90.0,
      "net": 1530.0,
      "date": "2026-07-27 06:30 PM",
      "status": "Completed",
    },
    {
      "id": "TXN_WTH8910",
      "bookingId": "-",
      "customerName": "Withdrawal to HDFC",
      "type": "Withdrawn",
      "method": "Bank Transfer",
      "amount": 10000.0,
      "commission": 0.0,
      "tax": 0.0,
      "net": 10000.0,
      "date": "2026-07-25 11:00 AM",
      "status": "Completed",
    },
    {
      "id": "TXN_7824107",
      "bookingId": "BK_9075",
      "customerName": "Aman Gupta",
      "type": "Earned",
      "method": "Online (UPI)",
      "amount": 3200.0,
      "commission": 320.0,
      "tax": 160.0,
      "net": 2720.0,
      "date": "2026-07-24 02:45 PM",
      "status": "Completed",
    },
    {
      "id": "TXN_WTH8909",
      "bookingId": "-",
      "customerName": "Withdrawal to UPI",
      "type": "Withdrawn",
      "method": "UPI Transfer",
      "amount": 5000.0,
      "commission": 0.0,
      "tax": 0.0,
      "net": 5000.0,
      "date": "2026-07-22 04:20 PM",
      "status": "Failed",
    }
  ];

  // Dummy Settlements List
  final List<Map<String, dynamic>> _settlements = [
    {
      "id": "SETTL_908124",
      "amount": 15240.0,
      "date": "2026-07-27",
      "bank": "HDFC Bank (•••• 9824)",
      "ref": "UTR_9082410925",
      "status": "Settled",
    },
    {
      "id": "SETTL_908123",
      "amount": 8420.0,
      "date": "2026-07-24",
      "bank": "HDFC Bank (•••• 9824)",
      "ref": "UTR_8902410110",
      "status": "Settled",
    },
    {
      "id": "SETTL_908122",
      "amount": 11800.0,
      "date": "2026-07-21",
      "bank": "UPI (vishalpatel@okaxis)",
      "ref": "UTR_7812409090",
      "status": "Settled",
    }
  ];

  // Dummy Withdrawal Requests List
  final List<Map<String, dynamic>> _withdrawals = [
    {
      "id": "REQ_901124",
      "amount": 5000.0,
      "method": "HDFC Bank (•••• 9824)",
      "fee": 15.0,
      "estArrival": "24-48 hours",
      "status": "Pending",
      "date": "2026-07-28 10:00 AM",
    },
    {
      "id": "REQ_901120",
      "amount": 10000.0,
      "method": "HDFC Bank (•••• 9824)",
      "fee": 15.0,
      "estArrival": "24-48 hours",
      "status": "Completed",
      "date": "2026-07-25 11:00 AM",
    },
    {
      "id": "REQ_901115",
      "amount": 5000.0,
      "method": "UPI (vishalpatel@okaxis)",
      "fee": 0.0,
      "estArrival": "Instant",
      "status": "Failed",
      "date": "2026-07-22 04:20 PM",
    }
  ];

  // Financial Metrics
  double get _availableBalance => 28540.0;
  double get _pendingBalance => 14310.0;
  double get _todayEarnings => 8420.0;
  double get _weeklyEarnings => 42850.0;
  double get _monthlyEarnings => 164200.0;
  double get _lifetimeEarnings => 842500.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: isDesktop ? null : _buildMobileAppBar(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  // ==========================================
  // MOBILE APPBAR
  // ==========================================
  PreferredSizeWidget _buildMobileAppBar() {
    final List<String> viewTitles = [
      "Wallet Dashboard",
      "Earnings Dashboard",
      "Transaction History",
      "Request Withdrawal",
      "Withdrawal History",
      "Linked Bank Accounts",
      "UPI Management",
      "Tax Dashboard",
      "Settlement Reports",
      "Commission Dashboard",
      "Invoices List",
      "Financial Analytics",
    ];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
        onPressed: () {
          if (_activeViewIndex > 0) {
            setState(() => _activeViewIndex = 0);
          } else if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      title: Text(
        viewTitles[_activeViewIndex],
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: VendorTheme.textPrimary),
      ),
      actions: [
        if (_activeViewIndex == 0)
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Color(0xFF2563EB)),
            onPressed: () => setState(() => _activeViewIndex = 11),
          ),
      ],
    );
  }

  // ==========================================
  // MOBILE LAYOUT
  // ==========================================
  Widget _buildMobileLayout() {
    Widget currentWidget;
    switch (_activeViewIndex) {
      case 1:
        currentWidget = _buildEarningsView();
        break;
      case 2:
        currentWidget = _buildTransactionsView();
        break;
      case 3:
        currentWidget = _buildWithdrawalFormView();
        break;
      case 4:
        currentWidget = _buildWithdrawalHistoryView();
        break;
      case 5:
        currentWidget = _buildBankAccountsView();
        break;
      case 6:
        currentWidget = _buildUPIView();
        break;
      case 7:
        currentWidget = _buildTaxDashboardView();
        break;
      case 8:
        currentWidget = _buildSettlementReportsView();
        break;
      case 9:
        currentWidget = _buildCommissionDashboardView();
        break;
      case 10:
        currentWidget = _buildInvoicesView();
        break;
      case 11:
        currentWidget = _buildFinancialAnalyticsView();
        break;
      default:
        currentWidget = _buildWalletDashboardView();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_activeViewIndex), child: currentWidget),
    );
  }

  // ==========================================
  // DESKTOP LAYOUT
  // ==========================================
  Widget _buildDesktopLayout() {
    final List<Map<String, dynamic>> menuItems = [
      {"title": "Wallet Dashboard", "icon": Icons.account_balance_wallet_rounded, "index": 0},
      {"title": "Earnings & Revenue", "icon": Icons.trending_up_rounded, "index": 1},
      {"title": "Transaction History", "icon": Icons.history_rounded, "index": 2},
      {"title": "Request Withdrawal", "icon": Icons.monetization_on_outlined, "index": 3},
      {"title": "Withdrawal Timeline", "icon": Icons.hourglass_empty_rounded, "index": 4},
      {"title": "Bank Accounts", "icon": Icons.account_balance_rounded, "index": 5},
      {"title": "UPI Configuration", "icon": Icons.qr_code_2_rounded, "index": 6},
      {"title": "Tax Dashboard", "icon": Icons.receipt_long_rounded, "index": 7},
      {"title": "Settlements Hub", "icon": Icons.payments_rounded, "index": 8},
      {"title": "Commission Summary", "icon": Icons.percent_rounded, "index": 9},
      {"title": "Invoices Ledger", "icon": Icons.inventory_2_outlined, "index": 10},
      {"title": "Financial Analytics", "icon": Icons.query_stats_rounded, "index": 11},
    ];

    Widget currentWidget;
    switch (_activeViewIndex) {
      case 1:
        currentWidget = _buildEarningsView();
        break;
      case 2:
        currentWidget = _buildTransactionsView();
        break;
      case 3:
        currentWidget = _buildWithdrawalFormView();
        break;
      case 4:
        currentWidget = _buildWithdrawalHistoryView();
        break;
      case 5:
        currentWidget = _buildBankAccountsView();
        break;
      case 6:
        currentWidget = _buildUPIView();
        break;
      case 7:
        currentWidget = _buildTaxDashboardView();
        break;
      case 8:
        currentWidget = _buildSettlementReportsView();
        break;
      case 9:
        currentWidget = _buildCommissionDashboardView();
        break;
      case 10:
        currentWidget = _buildInvoicesView();
        break;
      case 11:
        currentWidget = _buildFinancialAnalyticsView();
        break;
      default:
        currentWidget = _buildWalletDashboardView();
    }

    return Row(
      children: [
        // Sidebar panel
        Container(
          width: 260,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
                        onPressed: widget.onBack,
                      ),
                    Text(
                      "FINANCE PORTAL",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF2563EB), letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: menuItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, idx) {
                    final item = menuItems[idx];
                    final isSelected = _activeViewIndex == item['index'];
                    return InkWell(
                      onTap: () => setState(() => _activeViewIndex = item['index']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(item['icon'], color: isSelected ? Colors.white : VendorTheme.textSecondary, size: 20),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item['title'],
                                style: GoogleFonts.inter(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : VendorTheme.textPrimary,
                                  fontSize: 13.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Content Area
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(key: ValueKey(_activeViewIndex), child: currentWidget),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 1: WALLET DASHBOARD VIEW
  // ==========================================
  Widget _buildWalletDashboardView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(user?.uid ?? 'vendor_01').snapshots(),
      builder: (context, snapshot) {
        double liveBalance = _availableBalance;
        if (snapshot.hasData && snapshot.data!.exists) {
          final vData = snapshot.data!.data() as Map<String, dynamic>?;
          if (vData != null && vData['walletBalance'] != null) {
            liveBalance = (vData['walletBalance'] as num).toDouble();
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Balance Summary Card (Glossy modern UI)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("NEXORA WALLET LEDGER", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const Icon(Icons.wifi_tethering_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text("Available Balance", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      "₹${liveBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pending Settlement", style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text("₹${_pendingBalance.toStringAsFixed(2)}", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Lifetime Earnings", style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text("₹${_lifetimeEarnings.toStringAsFixed(0)}", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Quick Actions
              Text("Quick Actions", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildActionItem(
                      icon: Icons.monetization_on_rounded,
                      label: "Withdraw",
                      color: const Color(0xFF2563EB),
                      onTap: () => setState(() => _activeViewIndex = 3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionItem(
                      icon: Icons.history_rounded,
                      label: "Ledger",
                      color: Colors.teal,
                      onTap: () => setState(() => _activeViewIndex = 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionItem(
                      icon: Icons.receipt_long_rounded,
                      label: "Invoices",
                      color: Colors.purple,
                      onTap: () => setState(() => _activeViewIndex = 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Weekly Metrics Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Financial Summary", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  GestureDetector(
                    onTap: () => setState(() => _activeViewIndex = 1),
                    child: Text("Detailed Charts", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMiniSummaryCard("Today's Net", "₹${_todayEarnings.toInt()}", "+12% vs yesterday", Colors.blue),
                  _buildMiniSummaryCard("Weekly Revenue", "₹${_weeklyEarnings.toInt()}", "+8% vs last week", Colors.green),
                  _buildMiniSummaryCard("Monthly Net", "₹${_monthlyEarnings.toInt()}", "Steady margin", Colors.orange),
                  _buildMiniSummaryCard("Tax Deductions", "₹8,420", "TDS + GST summary", Colors.red),
                ],
              ),
              const SizedBox(height: 28),

              // Recent Activity Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Transactions", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  GestureDetector(
                    onTap: () => setState(() => _activeViewIndex = 2),
                    child: Text("See All History", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: _transactions.take(3).map((tx) => _buildTransactionRow(tx)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniSummaryCard(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 2: EARNINGS DASHBOARD VIEW
  // ==========================================
  Widget _buildEarningsView() {
    final List<double> weeklyData = [12000, 18000, 15000, 28000, 22000, 35000, 42000];
    final List<String> weeklyLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    final List<double> monthlyData = [45000, 62000, 50000, 78000];
    final List<String> monthlyLabels = ["Wk 1", "Wk 2", "Wk 3", "Wk 4"];

    final List<double> yearlyData = [120000, 145000, 180000, 210000, 190000, 245000];
    final List<String> yearlyLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];

    final List<double> chartData = _earningsTab == "Weekly"
        ? weeklyData
        : _earningsTab == "Monthly"
            ? monthlyData
            : yearlyData;

    final List<String> chartLabels = _earningsTab == "Weekly"
        ? weeklyLabels
        : _earningsTab == "Monthly"
            ? monthlyLabels
            : yearlyLabels;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Tab selector
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: ["Weekly", "Monthly", "Yearly"].map((tab) {
                final isSel = _earningsTab == tab;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _earningsTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSel ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: isSel ? const Color(0xFF2563EB) : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Main Chart Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Revenue Breakdown", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _DoubleChartPainter(chartData, chartLabels, const Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Secondary metrics
          Text("Averages & Metrics", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
          const SizedBox(height: 12),
          _buildDetailRowMetric("Average Job Value", "₹2,450.00"),
          _buildDetailRowMetric("Peak Daily Earnings", "₹42,000.00"),
          _buildDetailRowMetric("Revenue Growth", "+14.8% vs last cycle"),
        ],
      ),
    );
  }

  Widget _buildDetailRowMetric(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 3: TRANSACTION HISTORY VIEW
  // ==========================================
  Widget _buildTransactionsView() {
    final filteredTx = _transactions.where((tx) {
      final matchesSearch = tx['bookingId'].toString().toLowerCase().contains(_txSearchQuery.toLowerCase()) ||
          tx['customerName'].toString().toLowerCase().contains(_txSearchQuery.toLowerCase()) ||
          tx['id'].toString().toLowerCase().contains(_txSearchQuery.toLowerCase());
      final matchesType = _txTypeFilter == "All" || tx['type'] == _txTypeFilter;
      final matchesStatus = _txStatusFilter == "All" || tx['status'] == _txStatusFilter;
      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Top filters bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _txSearchQuery = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: "Search Transactions...",
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Type filter pills
        Container(
          height: 38,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: ["All", "Earned", "Withdrawn"].map((type) {
              final isSel = _txTypeFilter == type;
              return GestureDetector(
                onTap: () => setState(() => _txTypeFilter = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: isSel ? Colors.white : const Color(0xFF2563EB)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // List
        Expanded(
          child: filteredTx.isEmpty
              ? _buildEmptyState("No Transactions Found", "Try refining your search terms or filters.")
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTx.length,
                  itemBuilder: (context, idx) {
                    return _buildTransactionRow(filteredTx[idx]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> tx) {
    final isEarned = tx['type'] == 'Earned';
    return InkWell(
      onTap: () => _showTransactionDetailsModal(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isEarned ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              radius: 20,
              child: Icon(
                isEarned ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                color: isEarned ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx['customerName'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(tx['date'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isEarned ? '+' : '-'}₹${tx['amount'].toInt()}",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: isEarned ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                ),
                const SizedBox(height: 2),
                Text(tx['status'], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: tx['status'] == 'Completed' ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailsModal(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Transaction Details", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              _buildDetailModalRow("Transaction ID", tx['id']),
              _buildDetailModalRow("Booking ID", tx['bookingId']),
              _buildDetailModalRow("Method", tx['method']),
              _buildDetailModalRow("Base Amount", "₹${tx['amount']}"),
              _buildDetailModalRow("Commission Fee", "₹${tx['commission']}"),
              _buildDetailModalRow("GST / TDS Tax", "₹${tx['tax']}"),
              _buildDetailModalRow("Net payout", "₹${tx['net']}"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    AppSnackbar.show(context, "Invoice PDF download triggered");
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Download PDF Invoice"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 4: REQUEST WITHDRAWAL VIEW
  // ==========================================
  Widget _buildWithdrawalFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("WITHDRAWABLE BALANCE", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("₹${_availableBalance.toStringAsFixed(2)}", style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text("Minimum Cashout: ₹500 • Estimated Payout: instant (UPI) or 24h (Bank)", style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text("Enter Withdrawal Amount", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _withdrawController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "₹ ",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          Text("Select Payment Gateway", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildPaymentGatewaySelector("Bank Account", "Instant settlement (24h limit)", Icons.account_balance_rounded),
          _buildPaymentGatewaySelector("UPI", "Instant payout directly to address", Icons.qr_code_rounded),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(_withdrawController.text);
                if (amt == null || amt < 500) {
                  AppSnackbar.show(context, "Minimum withdrawal limit is ₹500", isError: true);
                  return;
                }
                if (amt > _availableBalance) {
                  AppSnackbar.show(context, "Insufficient withdrawable funds", isError: true);
                  return;
                }
                AppSnackbar.show(context, "Withdrawal Request Submitted Successfully!");
                setState(() => _activeViewIndex = 4);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text("Request Payout"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentGatewaySelector(String method, String sub, IconData icon) {
    final isSelected = _selectedWithdrawMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedWithdrawMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: isSelected ? 2.0 : 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text(sub, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 5: WITHDRAWAL HISTORY VIEW
  // ==========================================
  Widget _buildWithdrawalHistoryView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _withdrawals.length,
      itemBuilder: (context, idx) {
        final req = _withdrawals[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Payout: ₹${req['amount'].toInt()}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: req['status'] == "Completed"
                          ? const Color(0xFFDCFCE7)
                          : req['status'] == "Pending"
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      req['status'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: req['status'] == "Completed"
                            ? const Color(0xFF15803D)
                            : req['status'] == "Pending"
                                ? const Color(0xFFD97706)
                                : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("Reference Request: ${req['id']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              Text("Gateway: ${req['method']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              Text("Date: ${req['date']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 6: BANK ACCOUNTS VIEW
  // ==========================================
  Widget _buildBankAccountsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Bank Configurations", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddBankSheet(),
                icon: const Icon(Icons.add, size: 14),
                label: const Text("Link Bank"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: _bankAccounts.map((bank) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), radius: 22, child: Icon(Icons.account_balance_rounded, color: Color(0xFF2563EB))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bank['bankName'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(bank['accountNo'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                            child: Text(bank['status'], style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                          ),
                        ],
                      ),
                    ),
                    if (bank['isPrimary'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                        child: Text("PRIMARY", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF15803D))),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddBankSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Link Bank Account", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: "Bank Name")),
              const SizedBox(height: 10),
              TextFormField(decoration: const InputDecoration(labelText: "Account Number")),
              const SizedBox(height: 10),
              TextFormField(decoration: const InputDecoration(labelText: "IFSC Code")),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppSnackbar.show(context, "Bank Account verification initiated!");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: const Text("Initiate Verification"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 7: UPI MANAGEMENT VIEW
  // ==========================================
  Widget _buildUPIView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Linked UPI VPA Handles", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  AppSnackbar.show(context, "UPI address added!");
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text("Link UPI"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: _upiAccounts.map((upi) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFF5F3FF), radius: 22, child: Icon(Icons.qr_code_rounded, color: Color(0xFF7C3AED))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(upi['upiId'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(upi['status'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (upi['isPrimary'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                        child: Text("PRIMARY", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF15803D))),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 8: TAX DASHBOARD VIEW
  // ==========================================
  Widget _buildTaxDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Quarterly Tax Deductions", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 24),
                _buildTaxRowItem("GST Platform Tax (18%)", "₹14,520.00"),
                _buildTaxRowItem("TDS Withholding (1%)", "₹824.00"),
                _buildTaxRowItem("Total Tax Deductions", "₹15,344.00"),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Tax Document Downloads", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTaxDownloadRow("GST Tax Report Q2 (2026)", "Download Excel"),
          _buildTaxDownloadRow("TDS Withholding Statement", "Download PDF"),
          _buildTaxDownloadRow("Annual Audit Financial Statement", "Download PDF"),
        ],
      ),
    );
  }

  Widget _buildTaxRowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTaxDownloadRow(String label, String btnLabel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () => AppSnackbar.show(context, "Starting download..."),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: Text(btnLabel),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 9: SETTLEMENT REPORTS VIEW
  // ==========================================
  Widget _buildSettlementReportsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _settlements.length,
      itemBuilder: (context, idx) {
        final set = _settlements[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(set['id'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2563EB))),
                  Text("₹${set['amount'].toInt()}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const Divider(height: 20),
              _buildDetailModalRow("Date Settled", set['date']),
              _buildDetailModalRow("Settled to", set['bank']),
              _buildDetailModalRow("Bank UTR Ref", set['ref']),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 10: COMMISSION DASHBOARD VIEW
  // ==========================================
  Widget _buildCommissionDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PLATFORM DEDUCTION SUMMARY", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Fixed Rate: 10%", style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Lower than average competitor commission index matrix.", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Platform Commission Ledger", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDetailRowMetric("Average Commission per Booking", "₹245.00"),
          _buildDetailRowMetric("Total Commission Deducted YTD", "₹14,210.00"),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 11: INVOICES VIEW
  // ==========================================
  Widget _buildInvoicesView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, idx) {
        final id = "INV-2026-090${4 - idx}";
        final amt = 2450.0 + idx * 800;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Total Payout: ₹${amt.toInt()}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Color(0xFF2563EB)),
                onPressed: () => AppSnackbar.show(context, "Invoice $id downloaded"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 12: FINANCIAL ANALYTICS VIEW
  // ==========================================
  Widget _buildFinancialAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMiniSummaryCard("Expenses Hub", "₹4,250", "-15% compared YTD", Colors.blue),
              _buildMiniSummaryCard("Taxes Reserved", "₹12,420", "Next filing Oct 1", Colors.green),
              _buildMiniSummaryCard("Commission Offset", "₹1,240", "Steady performance", Colors.orange),
              _buildMiniSummaryCard("Projected Cashflow", "₹38,200", "Estimated Q3", Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          Text("Financial Performance Ratio", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ClipRect(
            child: Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFakeBar("Jan", 55),
                  _buildFakeBar("Feb", 72),
                  _buildFakeBar("Mar", 63),
                  _buildFakeBar("Apr", 88),
                  _buildFakeBar("May", 45),
                  _buildFakeBar("Jun", 78),
                  _buildFakeBar("Jul", 100, isAccent: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFakeBar(String label, double height, {bool isAccent = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: height,
          decoration: BoxDecoration(color: isAccent ? const Color(0xFF2563EB) : const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DoubleChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color color;

  _DoubleChartPainter(this.data, this.labels, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftPadding = 45.0;
    const double bottomPadding = 30.0;
    const double rightPadding = 15.0;
    const double topPadding = 20.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = 0.0;
    final double range = maxVal == 0 ? 1.0 : maxVal;

    // Y-axis grid
    final int ticks = 4;
    final gridLinePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= ticks; i++) {
      final double ratio = i / ticks;
      final double y = topPadding + chartHeight * (1 - ratio);
      canvas.drawLine(Offset(leftPadding, y), Offset(leftPadding + chartWidth, y), gridLinePaint);

      final double val = minVal + range * ratio;
      final String text = val >= 1000 ? "${(val / 1000).toStringAsFixed(0)}k" : val.toStringAsFixed(0);
      final valPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      valPainter.layout();
      valPainter.paint(canvas, Offset(leftPadding - valPainter.width - 6, y - valPainter.height / 2));
    }

    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = leftPadding + (i / (data.length - 1)) * chartWidth;
      final double y = topPadding + chartHeight * (1 - ((data[i] - minVal) / range));
      points.add(Offset(x, y));
    }

    // Line Path
    if (points.isNotEmpty) {
      final fillPath = Path()
        ..moveTo(points.first.dx, topPadding + chartHeight)
        ..lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final ctrlX = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
      }

      fillPath.lineTo(points.last.dx, topPadding + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final ctrlX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
      }

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Dots and Labels
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.5, dotPaint);
      canvas.drawCircle(points[i], 3.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(points[i].dx - labelPainter.width / 2, topPadding + chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(_DoubleChartPainter old) => old.data != data || old.labels != labels || old.color != color;
}
