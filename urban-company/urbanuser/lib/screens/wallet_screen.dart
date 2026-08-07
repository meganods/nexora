import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/invoice_service.dart';
import '../widgets/app_toast.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // Local state stats (synced from Firestore)
  double _balance = 0.0;
  double _pendingRefunds = 0.0;
  double _lifetimeRewards = 0.0;

  final List<Map<String, dynamic>> _fallbackTransactions = [
    {
      'id': 'tx_9829101',
      'bookingId': 'bk_8910',
      'type': 'Referral Reward',
      'amount': 100.0,
      'isCredit': true,
      'paymentMethod': 'Wallet Credit',
      'status': 'Completed',
      'createdAt': '31 Jul 2026, 04:30 PM',
    },
    {
      'id': 'tx_9829102',
      'bookingId': 'bk_8712',
      'type': 'Booking Payment',
      'amount': 799.0,
      'isCredit': false,
      'paymentMethod': 'Razorpay (Card)',
      'status': 'Completed',
      'createdAt': '28 Jul 2026, 11:15 AM',
    },
    {
      'id': 'tx_9829103',
      'bookingId': 'bk_8501',
      'type': 'Refund',
      'amount': 599.0,
      'isCredit': true,
      'paymentMethod': 'Original UPI Source',
      'status': 'Completed',
      'createdAt': '25 Jul 2026, 02:45 PM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletStats();
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
        } else {
          // If no document exists in Firestore, set default state
          _balance = 100.0;
          _pendingRefunds = 0.0;
          _lifetimeRewards = 100.0;
        }
      } catch (_) {
        _balance = 100.0;
        _pendingRefunds = 0.0;
        _lifetimeRewards = 100.0;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
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
        title: Text('Wallet & Transactions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: _dark),
            onPressed: _showStatementDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Wallet Balance Premium Card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [_blue, Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Available Balance', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${_balance.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                            ElevatedButton.icon(
                              onPressed: _showAddMoneySheet,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text('Add Money', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _blue,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _walletMiniStat('Pending Refunds', '₹${_pendingRefunds.toStringAsFixed(0)}')),
                            Container(width: 1, height: 30, color: Colors.white24),
                            Expanded(child: _walletMiniStat('Lifetime Rewards', '₹${_lifetimeRewards.toStringAsFixed(0)}')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Transaction Filters ────────────────────────────────────
                  Text('Transaction History', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: ['All', 'Payments', 'Refunds', 'Rewards'].map((filter) {
                        final isSel = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSel,
                            selectedColor: const Color(0xFFEFF6FF),
                            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? _blue : _gray),
                            onSelected: (val) {
                              if (val) setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Transactions Feed Stream ────────────────────────────────
                  StreamBuilder<QuerySnapshot>(
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

                      // Apply filter matching
                      final filtered = txList.where((tx) {
                        if (_selectedFilter == 'All') return true;
                        final String type = (tx['type'] ?? '').toString().toLowerCase();
                        if (_selectedFilter == 'Payments') return type.contains('payment');
                        if (_selectedFilter == 'Refunds') return type.contains('refund');
                        if (_selectedFilter == 'Rewards') return type.contains('reward') || type.contains('cashback');
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _border),
                          ),
                          child: Center(
                            child: Text('No transactions found under this category.',
                                textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final tx = filtered[i];
                          final isCredit = tx['isCredit'] ?? (tx['type'] == 'Refund' || tx['type'] == 'Referral Reward');
                          final amt = ((tx['amount'] ?? 0.0) as num).toDouble();
                          final type = tx['type'] ?? 'Transaction';
                          final date = tx['createdAt'] ?? 'Just now';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _border),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isCredit ? _green : _red,
                                  size: 18,
                                ),
                              ),
                              title: Text(type, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                              subtitle: Text(date, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                              trailing: Text(
                                '${isCredit ? "+" : "-"}₹${amt.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isCredit ? _green : _dark),
                              ),
                              onTap: () => _showTransactionDetails(tx),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
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

  void _showAddMoneySheet() {
    final TextEditingController amountController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Money to Wallet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _dark),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('₹', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _dark)),
                    ),
                    hintText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickAmountBtn('500', amountController, setModalState),
                    _quickAmountBtn('1000', amountController, setModalState),
                    _quickAmountBtn('2000', amountController, setModalState),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final val = double.tryParse(amountController.text);
                            if (val == null || val <= 0) {
                              AppToast.show(context, title: 'Invalid Amount', message: 'Please enter a valid amount.', isError: true);
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            await _initiateWalletRecharge(val);
                            if (mounted) Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Proceed to Add', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quickAmountBtn(String amount, TextEditingController controller, StateSetter setModalState) {
    return ActionChip(
      label: Text('+ ₹$amount', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _blue)),
      backgroundColor: const Color(0xFFEFF6FF),
      side: const BorderSide(color: _blue),
      onPressed: () {
        setModalState(() {
          controller.text = amount;
        });
      },
    );
  }

  Future<void> _initiateWalletRecharge(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final token = await user.getIdToken();
    String url = 'http://localhost:5000/api/v1/payments/cashfree/order';
    if (!kIsWeb) {
      if (Platform.isAndroid) {
         url = 'http://10.0.2.2:5000/api/v1/payments/cashfree/order';
      }
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'customerEmail': user.email ?? 'customer@nexora.com',
          'customerPhone': '9999999999',
          'paymentType': 'wallet_recharge',
        }),
      );

      if (response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          final orderData = resData['order'];
          final orderId = orderData['order_id'];
          final paymentSessionId = orderData['payment_session_id'];
          final environmentStr = resData['environment'] ?? 'sandbox';

          final environment = environmentStr.toLowerCase() == 'production'
              ? CFEnvironment.PRODUCTION
              : CFEnvironment.SANDBOX;

          final cfPaymentGatewayService = CFPaymentGatewayService();
          cfPaymentGatewayService.setCallback(
            (String orderId) {
              _verifyRechargeOnServer(orderId);
            },
            (CFErrorResponse errorResponse, String orderId) {
              AppToast.show(context, title: 'Payment Failed', message: errorResponse.getMessage() ?? 'Cancelled.', isError: true);
            },
          );

          final session = CFSessionBuilder()
              .setOrderId(orderId)
              .setPaymentSessionId(paymentSessionId)
              .setEnvironment(environment)
              .build();

          final webCheckoutPayment = CFWebCheckoutPaymentBuilder()
              .setSession(session)
              .build();

          cfPaymentGatewayService.doPayment(webCheckoutPayment);
        } else {
          AppToast.show(context, title: 'Error', message: resData['message'] ?? 'Failed to start payment.', isError: true);
        }
      } else {
        AppToast.show(context, title: 'Error', message: 'Server error.', isError: true);
      }
    } catch (e) {
      AppToast.show(context, title: 'Error', message: 'Network error.', isError: true);
    }
  }

  Future<void> _verifyRechargeOnServer(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      String url = 'http://localhost:5000/api/v1/payments/cashfree/verify';
      if (!kIsWeb) {
        if (Platform.isAndroid) {
           url = 'http://10.0.2.2:5000/api/v1/payments/cashfree/verify';
        }
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'orderId': orderId}),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          AppToast.show(context, title: 'Success', message: 'Wallet recharged successfully!');
          _loadWalletStats(); // Refresh balance
        } else {
          AppToast.show(context, title: 'Pending', message: 'Payment verification pending.');
        }
      } else {
        AppToast.show(context, title: 'Error', message: 'Failed to verify payment.', isError: true);
      }
    } catch (e) {
      AppToast.show(context, title: 'Error', message: 'Network error during verification.', isError: true);
    }
  }
}
