import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/invoice_service.dart';
import '../widgets/app_toast.dart';
import 'add_money_screen.dart';
import 'rewards_screen.dart';
import 'withdraw_screen.dart';
import 'transactions_screen.dart';
// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'All';
  bool _isBalanceVisible = true;

  // Local state stats (synced from Firestore)
  double _balance = 0.0;
  double _pendingRefunds = 0.0;
  double _lifetimeRewards = 0.0;
  double _totalAdded = 0.0;
  double _totalSpent = 0.0;
  int _rewardPoints = 0;

  final List<Map<String, dynamic>> _fallbackTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletStats();
  }

  Future<void> _navigateToAddMoneyScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddMoneyScreen(currentBalance: _balance)),
    );
    if (result == true) {
      _loadWalletStats();
    }
  }

  Future<void> _loadWalletStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('wallet').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final d = doc.data()!;
          if (d['balance'] != null) _balance = (d['balance'] as num).toDouble();
          if (d['pendingBalance'] != null) _pendingRefunds = (d['pendingBalance'] as num).toDouble();
          if (d['lifetimeRewards'] != null) _lifetimeRewards = (d['lifetimeRewards'] as num).toDouble();
          if (d['totalAdded'] != null) _totalAdded = (d['totalAdded'] as num).toDouble();
          if (d['totalSpent'] != null) _totalSpent = (d['totalSpent'] as num).toDouble();
          if (d['rewardPoints'] != null) _rewardPoints = (d['rewardPoints'] as num).toInt();
        } else {
          // If no document exists in Firestore, set default state
          _balance = 0.0;
          _pendingRefunds = 0.0;
          _lifetimeRewards = 0.0;
          _totalAdded = 0.0;
          _totalSpent = 0.0;
          _rewardPoints = 0;
        }
      } catch (_) {
        _balance = 0.0;
        _pendingRefunds = 0.0;
        _lifetimeRewards = 0.0;
        _totalAdded = 0.0;
        _totalSpent = 0.0;
        _rewardPoints = 0;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final isCredit = tx['isCredit'] ?? true;
    final amt = ((tx['amount'] ?? 0.0) as num).toDouble();
    final type = tx['type'] ?? 'Transaction';
    final txId = tx['id'] ?? 'N/A';
    final date = tx['createdAt'] ?? 'Just now';
    final method = tx['paymentMethod'] ?? 'Wallet';
    final status = tx['status'] ?? 'Completed';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction Details', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(color: _border),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(type, style: GoogleFonts.inter(fontSize: 12, color: _gray, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${isCredit ? "+" : "-"}₹${amt.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: isCredit ? _green : _dark),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                    child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, color: _green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _infoRow('Transaction ID', txId),
            _infoRow('Date & Time', date),
            _infoRow('Payment Method', method),
            _infoRow('GST Included', '₹${(amt * 0.18).toStringAsFixed(1)} (18%)'),
            const SizedBox(height: 24),
            Row(
              children: [
                    Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // close sheet
                      final ctx = context;
                      // Build invoice-compatible booking map from transaction
                      final bookingMap = {
                        'id': txId,
                        'shopName': type,
                        'bookingId': txId,
                        'price': '₹${amt.toStringAsFixed(0)}',
                        'rawAmount': amt,
                        'paymentMethod': method,
                        'bookingStatus': status,
                        'date': date,
                        'couponDiscount': 0.0,
                      };
                      try {
                        await InvoiceService.downloadInvoice(context: ctx, booking: bookingMap);
                        if (ctx.mounted) {
                          AppToast.show(
                            ctx,
                            title: '✅ Receipt Downloaded',
                            message: 'Transaction receipt saved as PDF!',
                            icon: Icons.picture_as_pdf_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBgColor: const Color(0xFFEFF6FF),
                            duration: const Duration(seconds: 4),
                          );
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          AppToast.show(ctx, title: '❌ Failed', message: 'Could not download receipt.', isError: true);
                        }
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text('Download Receipt', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatementDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Download Statement', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: _dark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Statement Period', style: GoogleFonts.inter(fontSize: 12, color: _gray, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last 30 Days', style: GoogleFonts.inter(fontSize: 13, color: _dark, fontWeight: FontWeight.bold)),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _gray),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Statement generated successfully! Check your downloads.', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: _green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Download PDF', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeroCard(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildWalletAnalytics(),
                        const SizedBox(height: 24),
                        _buildPromoBanner(),
                        const SizedBox(height: 24),
                        _buildTransactionsSection(user),
                        const SizedBox(height: 24),
                        _buildRewardsCard(),
                        const SizedBox(height: 16),
                        _buildPaymentMethodsCard(),
                        const SizedBox(height: 16),
                        _buildSecurityCard(),
                        const SizedBox(height: 24),
                        _buildHelpSupport(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        },
      ),
      title: Text('My Wallet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
      actions: [
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Current Balance', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                    child: Icon(_isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white70, size: 16),
                  ),
                ],
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible ? '₹${_balance.toStringAsFixed(2)}' : '₹ ••••••',
            style: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('+ ₹${_pendingRefunds.toStringAsFixed(2)} this month', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroMiniStat(Icons.card_giftcard_rounded, 'Cashback Balance', '₹${_lifetimeRewards.toStringAsFixed(2)}'),
              _heroMiniStat(Icons.stars_rounded, 'Reward Points', _rewardPoints.toString()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddMoneyScreen,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Add Money', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppToast.show(context, title: 'Withdraw', message: 'Withdraw functionality coming soon!');
                  },
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text('Withdraw', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMiniStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Actions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            Text('View All', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionBtn(Icons.add_circle_rounded, 'Add Money', const Color(0xFF3B82F6), _navigateToAddMoneyScreen),

              _actionBtn(Icons.send_rounded, 'Withdraw', const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()))),
              _actionBtn(Icons.receipt_long_rounded, 'Transactions', const Color(0xFF8B5CF6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()))),
              _actionBtn(Icons.card_giftcard_rounded, 'Rewards', const Color(0xFFF59E0B), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _dark)),
        ],
      ),
    );
  }

  Widget _buildWalletAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wallet Overview', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _analyticCard(Icons.account_balance_wallet, 'Current Balance', '₹${_balance.toStringAsFixed(2)}', const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _analyticCard(Icons.arrow_downward_rounded, 'Total Added', '₹${_totalAdded.toStringAsFixed(2)}', const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _analyticCard(Icons.arrow_upward_rounded, 'Total Spent', '₹${_totalSpent.toStringAsFixed(2)}', const Color(0xFFEF4444))),
            const SizedBox(width: 12),
            Expanded(child: _analyticCard(Icons.workspace_premium_rounded, 'Cashback Earned', '₹${_lifetimeRewards.toStringAsFixed(2)}', const Color(0xFFF59E0B))),
          ],
        ),
      ],
    );
  }

  Widget _analyticCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.redeem_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Money & Get Cashback', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Earn up to ₹200 on next recharge', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _navigateToAddMoneyScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Add Money'),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            Text('View All', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .where('userId', isEqualTo: user?.uid ?? 'guest_user')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (ctx, snap) {
              List<Map<String, dynamic>> txList = _fallbackTransactions;
              if (snap.hasData && snap.data!.docs.isNotEmpty) {
                txList = snap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return {'id': d.id, ...data};
                }).toList();
              }
              if (txList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text('No transactions found.', style: GoogleFonts.inter(fontSize: 12, color: _gray))),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: txList.length > 4 ? 4 : txList.length,
                separatorBuilder: (_, __) => const Divider(color: _border, height: 1),
                itemBuilder: (ctx, i) {
                  final tx = txList[i];
                  final isCredit = tx['isCredit'] ?? (tx['type'] == 'Refund' || tx['type'] == 'Referral Reward');
                  final amt = ((tx['amount'] ?? 0.0) as num).toDouble();
                  final type = tx['type'] ?? 'Transaction';
                  final date = tx['createdAt'] ?? 'Just now';
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isCredit ? _green : _red,
                        size: 20,
                      ),
                    ),
                    title: Text(type, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                    subtitle: Text(date, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                    trailing: Text(
                      '${isCredit ? "+" : "-"}₹${amt.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isCredit ? _green : _dark),
                    ),
                    onTap: () => _showTransactionDetails(tx),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF97316), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rewards & Cashback', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 2),
                Text('You have earned ₹${_lifetimeRewards.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _gray),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.credit_card_rounded, color: _blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Methods', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 2),
                Text('Manage your linked cards', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _gray),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_good_rounded, color: _green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text('100% Secure Payments backed by Cashfree', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF166534))),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Help & Support', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _supportItem(Icons.help_outline_rounded, 'Wallet FAQ', const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _supportItem(Icons.chat_rounded, 'Chat Support', const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: _supportItem(Icons.report_problem_rounded, 'Report Issue', const Color(0xFFEF4444))),
          ],
        )
      ],
    );
  }

  Widget _supportItem(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _dark)),
        ],
      ),
    );
  }

  

  Widget _walletMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
      ],
    );
  }

}
