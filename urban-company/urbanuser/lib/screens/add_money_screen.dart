import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/app_toast.dart';
import 'wallet_payment_processing_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _secondary = Color(0xFF3B82F6);
const _accent = Color(0xFF60A5FA);
const _bg = Color(0xFFF8FAFC);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _green = Color(0xFF10B981);

class AddMoneyScreen extends StatefulWidget {
  final double currentBalance;
  
  const AddMoneyScreen({Key? key, required this.currentBalance}) : super(key: key);

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController(text: '1000');
  double _enteredAmount = 1000.0;
  String _selectedMethod = 'UPI';
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;


  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {
        _enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
      });
    });

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onQuickChipTapped(String amount) {
    _amountController.text = amount;
    _amountController.selection = TextSelection.fromPosition(TextPosition(offset: amount.length));
  }

  Future<void> _handlePayment() async {
    if (_enteredAmount < 1) {
      AppToast.show(context, title: 'Invalid Amount', message: 'Please enter a valid amount', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    await _initiateWalletRecharge(_enteredAmount);
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _initiateWalletRecharge(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final token = await user.getIdToken();
    String url = ApiConfig.baseUrl + '/api/v1/payments/cashfree/order';
    

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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletPaymentProcessingScreen(
                    orderId: orderId,
                    amount: _enteredAmount,
                    currentBalance: widget.currentBalance,
                  ),
                ),
              );
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

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Money', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: _dark),
            onPressed: () {
               AppToast.show(context, title: 'Help', message: 'Wallet support opening soon.');
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBalanceCard(),
                      const SizedBox(height: 24),
                      _buildEnterAmountSection(),
                      const SizedBox(height: 16),
                      _buildQuickChips(),
                      const SizedBox(height: 24),
                      _buildPromoCard(),
                      const SizedBox(height: 24),
                      _buildPaymentMethods(),
                      const SizedBox(height: 24),
                      _buildSecurityBadge(),
                      const SizedBox(height: 24),
                      _buildPaymentSummary(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildBottomStickyBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wallet Balance', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.currentBalance.toStringAsFixed(2)}',
            style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text('Available Balance', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEnterAmountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter Amount', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (val) {
              if (val.startsWith('0') && val.length > 1) {
                _amountController.text = val.replaceFirst(RegExp(r'^0+'), '');
                _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
              }
            },
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: _dark),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('₹', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: _gray)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: '1000',
              hintStyle: GoogleFonts.inter(color: _gray.withOpacity(0.3)),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Balance after adding', style: GoogleFonts.inter(fontSize: 13, color: _gray)),
              Text(
                '₹${(widget.currentBalance + _enteredAmount).toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    final amounts = ['500', '1000', '2000', '5000', '10000'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: amounts.map((amt) {
          final isSelected = _amountController.text == amt;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _onQuickChipTapped(amt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [_primary, _secondary])
                      : const LinearGradient(colors: [Colors.white, Colors.white]),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Text(
                  '₹$amt',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : _dark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Payment Method', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _paymentMethodTile('UPI', 'Pay using any UPI app', Icons.qr_code_scanner_rounded, isBest: true),
              _divider(),
              _paymentMethodTile('Google Pay', 'Pay using Google Pay', Icons.g_mobiledata_rounded),
              _divider(),
              _paymentMethodTile('Cards', 'Credit or Debit Card', Icons.credit_card_rounded),
              _divider(),
              _paymentMethodTile('Net Banking', 'All Indian Banks', Icons.account_balance_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Divider(color: Colors.grey.shade100, height: 1, indent: 64);

  Widget _paymentMethodTile(String title, String subtitle, IconData icon, {bool isBest = false}) {
    final isSelected = _selectedMethod == title;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = title),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _dark)),
                      if (isBest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                          child: Text('BEST', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                ],
              ),
            ),
            Radio<String>(
              value: title,
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
              activeColor: _primary,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add ₹1000, Get ₹50 Cashback', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                Text('Offer auto-applied on checkout', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user_rounded, color: _green, size: 16),
        const SizedBox(width: 8),
        Text('100% Secure Payment by Cashfree', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 16),
          _summaryRow('Amount', '₹${_enteredAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('Convenience Fee', '₹0.00', isGreen: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _bg, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Payable', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: _dark)),
              Text('₹${_enteredAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: _dark)),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: _gray)),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isGreen ? _green : _dark)),
      ],
    );
  }

  Widget _buildBottomStickyBar() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting || _enteredAmount <= 0 ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue to Pay', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Powered by Cashfree Payments', style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
