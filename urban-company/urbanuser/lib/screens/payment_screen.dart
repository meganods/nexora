import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/thank_you_screen.dart';
import '../services/smart_assignment_service.dart';
import 'address_setup_screen.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class PaymentScreen extends StatefulWidget {
  final double? totalAmount;
  final Map<String, dynamic>? coupon;
  final String? shopName;
  final String? date;
  final String? time;
  final List<Map<String, dynamic>>? selectedItems;
  final String? vendorId;
  final String? imageUrl;

  const PaymentScreen({
    super.key,
    this.totalAmount,
    this.coupon,
    this.shopName,
    this.date,
    this.time,
    this.selectedItems,
    this.vendorId,
    this.imageUrl,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = "UPI / Google Pay";
  bool _isSubmitting = false;
  bool _agreeTerms = false;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponInputController = TextEditingController();

  String _userAddress = '';
  String _userAddressType = 'Home';
  String _userName = '';
  String _userPhone = '';

  double _couponDiscount = 0.0;
  String? _appliedCouponCode;
  bool _isValidatingCoupon = false;

  double _walletBalance = 0.0;

  final double _platformFee = 29.0;
  final double _gstTaxes = 52.0;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
    _loadWalletBalance();
    if (widget.coupon != null) {
      _appliedCouponCode = widget.coupon!['code'];
      _couponDiscount = (widget.coupon!['discount'] ?? 0.0) as double;
    }
  }

  Future<void> _loadWalletBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('wallet').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          if (mounted) {
            setState(() {
              _walletBalance = ((doc.data()!['balance'] ?? 0.0) as num).toDouble();
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _loadUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String addr = prefs.getString('userAddress') ?? prefs.getString('saved_address') ?? '';
    String type = prefs.getString('userAddressType') ?? 'Home';
    String name = prefs.getString('userName') ?? '';
    String phone = prefs.getString('userMobile') ?? prefs.getString('userPhone') ?? '';

    if (addr.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user!.email).get();
          if (doc.exists && doc.data() != null) {
            final d = doc.data()!;
            addr = d['userAddress'] ?? d['address'] ?? '';
            type = d['userAddressType'] ?? 'Home';
            name = d['name'] ?? '';
            phone = d['phone'] ?? '';
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _userAddress = addr.isNotEmpty ? addr : '102, Green Meadows, Malad West, Mumbai';
        _userAddressType = type.isNotEmpty ? type : 'Home';
        _userName = name.isNotEmpty ? name : 'Rahul Sharma';
        _userPhone = phone.isNotEmpty ? phone : '+91 98765 43210';
      });
    }
  }

  double get _basePrice => widget.totalAmount ?? 499.0;

  double get _finalGrandTotal {
    double total = _basePrice + _platformFee + _gstTaxes - _couponDiscount;
    return total < 0 ? 0 : total;
  }

  double get _walletUsed {
    if (_selectedPaymentMethod == 'NEXORA Wallet') {
      return _finalGrandTotal > _walletBalance ? _walletBalance : _finalGrandTotal;
    }
    return 0.0;
  }

  double get _cashfreeAmount => _finalGrandTotal - _walletUsed;

  Future<void> _validateAndApplyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    setState(() => _isValidatingCoupon = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: cleanCode)
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          _showToast('Invalid coupon code.', isError: true);
        }
      } else {
        final d = snap.docs.first.data();
        final disc = ((d['discountAmount'] ?? d['discount'] ?? 100) as num).toDouble();
        if (mounted) {
          setState(() {
            _appliedCouponCode = cleanCode;
            _couponDiscount = disc;
          });
          _showToast('Coupon "$cleanCode" applied! You saved ₹${disc.toStringAsFixed(0)}');
        }
      }
    } catch (_) {
      if (mounted) {
        // Fallback demo coupon
        if (cleanCode == 'NEXORA100' || cleanCode == 'NEXORA500') {
          final disc = cleanCode == 'NEXORA500' ? 500.0 : 100.0;
          setState(() {
            _appliedCouponCode = cleanCode;
            _couponDiscount = disc;
          });
          _showToast('Coupon "$cleanCode" applied! Saved ₹${disc.toStringAsFixed(0)}');
        } else {
          _showToast('Invalid coupon code.', isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => _isValidatingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _couponDiscount = 0.0;
      _couponInputController.clear();
    });
    _showToast('Coupon removed.');
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: isError ? Colors.red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.shopName ?? 'Deep Home Cleaning';
    final dateStr = widget.date ?? 'Tomorrow';
    final timeStr = widget.time ?? '10:00 AM – 12:00 PM';
    final image = widget.imageUrl ??
        'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Booking Summary",
          style: GoogleFonts.inter(color: _dark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Selected Service Summary Card ─────────────────────────────
                _wrapper(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: image.startsWith('http')
                            ? Image.network(image, width: 80, height: 80, fit: BoxFit.cover)
                            : Container(
                                width: 80,
                                height: 80,
                                color: _blue.withValues(alpha: 0.1),
                                child: const Icon(Icons.handyman_rounded, color: _blue, size: 36),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('APPROVED SERVICE',
                                  style: GoogleFonts.inter(
                                      fontSize: 8, color: _blue, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, color: _green, size: 13),
                                const SizedBox(width: 4),
                                Text('Service Partner Reserved Automatically',
                                    style: GoogleFonts.inter(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Booking Date & Time Details ───────────────────────────────
                _wrapper(
                  title: 'Booking Schedule',
                  child: Column(
                    children: [
                      _detailRow(Icons.calendar_month_rounded, 'Date', dateStr),
                      const SizedBox(height: 10),
                      _detailRow(Icons.access_time_rounded, 'Time Slot', timeStr),
                      const SizedBox(height: 10),
                      _detailRow(Icons.timer_outlined, 'Est. Arrival', 'Within 15 mins of slot start'),
                    ],
                  ),
                ),

                // ── Service Address ───────────────────────────────────────────
                _wrapper(
                  title: 'Service Address',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: _blue.withValues(alpha: 0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_rounded, color: _blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_userName,
                                    style: GoogleFonts.inter(
                                        fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(_userAddressType.toUpperCase(),
                                      style: GoogleFonts.inter(
                                          fontSize: 8, color: _gray, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(_userAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.3)),
                            Text(_userPhone,
                                style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddressSetupScreen()),
                          ).then((_) => _loadUserAddress());
                        },
                        child: Text('Edit',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
                      ),
                    ],
                  ),
                ),

                // ── Special Instructions / Notes ──────────────────────────────
                _wrapper(
                  title: 'Special Instructions for Professional',
                  child: Column(
                    children: [
                      TextField(
                        controller: _notesController,
                        maxLength: 300,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Add instructions e.g. Ring bell twice, Call before arrival…',
                          hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13),
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _blue)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Coupon Code Section ───────────────────────────────────────
                _wrapper(
                  title: 'Apply Coupon',
                  child: Column(
                    children: [
                      if (_appliedCouponCode != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: _green, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Coupon "$_appliedCouponCode" Applied',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _dark)),
                                    Text('Discount of ₹${_couponDiscount.toStringAsFixed(0)} subtracted',
                                        style: GoogleFonts.inter(fontSize: 11, color: _green)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                                onPressed: _removeCoupon,
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponInputController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon (e.g. NEXORA100)',
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 13),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _border)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _border)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _blue)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isValidatingCoupon
                                  ? null
                                  : () => _validateAndApplyCoupon(_couponInputController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              child: _isValidatingCoupon
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // ── Price Breakdown ───────────────────────────────────────────
                _wrapper(
                  title: 'Price Breakdown',
                  child: Column(
                    children: [
                      _priceRow('Service Base Price', '₹${_basePrice.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _priceRow('Platform & Safety Fee', '₹${_platformFee.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _priceRow('Taxes & GST (18%)', '₹${_gstTaxes.toStringAsFixed(0)}'),
                      if (_couponDiscount > 0) ...[
                        const SizedBox(height: 8),
                        _priceRow('Coupon Discount', '- ₹${_couponDiscount.toStringAsFixed(0)}', isGreen: true),
                      ],
                      if (_walletUsed > 0) ...[
                        const SizedBox(height: 8),
                        _priceRow('Wallet Amount Used', '- ₹${_walletUsed.toStringAsFixed(0)}', isGreen: true),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: _border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_walletUsed > 0 ? 'Net Cashfree Payable' : 'Grand Total Payable',
                              style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
                          Text('₹${_cashfreeAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                  fontSize: 22, fontWeight: FontWeight.w900, color: _blue)),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Payment Method Selection (Online Only) ───────────────────
                _wrapper(
                  title: 'Select Online Payment Method',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _paymentTile('UPI / Google Pay', 'Instant payment via GPay, PhonePe, Paytm', Icons.account_balance_wallet_rounded),
                      _paymentTile('Credit / Debit Card', 'Visa, Mastercard, RuPay', Icons.credit_card_rounded),
                      _paymentTile('Net Banking', 'All major Indian banks', Icons.account_balance_rounded),
                      _paymentTile('NEXORA Wallet', 'Available balance ₹${_walletBalance.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A))),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cash on Delivery (COD) is disabled to ensure 100% contactless digital transactions.',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Terms & Conditions Checkbox ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border)),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreeTerms,
                          activeColor: _blue,
                          onChanged: (v) => setState(() => _agreeTerms = v == true),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                            child: Text(
                              'I agree to Nexora Cancellation & Refund Terms and Conditions.',
                              style: GoogleFonts.inter(fontSize: 12, color: _dark, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Bottom Bar ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_walletUsed > 0 ? 'CASHFREE PAYABLE' : 'FINAL PAYABLE',
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: _gray,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text('₹${_cashfreeAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w900, color: _blue)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (!_agreeTerms || _isSubmitting) ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agreeTerms ? _blue : const Color(0xFFCBD5E1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            children: [
                              Text('Proceed to Payment',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    final String bookingId = "NEX-${100000 + DateTime.now().millisecond + DateTime.now().second * 1000}";
    String assignedVendorId = widget.vendorId ?? 'v1';
    String assignedShopName = widget.shopName ?? 'CleanPro Services';

    try {
      final bestVendor = await SmartAssignmentService.assignBestVendor(
        categoryName: 'Cleaning',
        userCity: 'Mumbai',
        bookingPrice: _finalGrandTotal,
      );
      if (bestVendor != null) {
        assignedVendorId = bestVendor['id'];
        assignedShopName = bestVendor['businessName'] ?? bestVendor['name'] ?? assignedShopName;
      }
    } catch (_) {}

    final token = await user?.getIdToken();
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
          'amount': _cashfreeAmount,
          'bookingId': bookingId,
          'customerEmail': user?.email ?? 'customer@nexora.com',
          'customerPhone': _userPhone.replaceAll(RegExp(r'[^0-9]'), ''),
          'paymentType': 'booking_payment',
          'walletUsed': _walletUsed,
          'couponCode': _appliedCouponCode ?? '',
          'couponDiscount': _couponDiscount,
          'bookingData': {
            'userEmail': user?.email ?? 'customer@nexora.com',
            'userName': _userName,
            'userPhone': _userPhone,
            'userAddress': _userAddress,
            'shopName': assignedShopName,
            'totalAmount': _finalGrandTotal,
            'date': widget.date ?? 'Tomorrow',
            'time': widget.time ?? '10:00 AM',
            'notes': _notesController.text,
            'vendorId': assignedVendorId,
            'coverImage': widget.imageUrl ?? '',
          }
        }),
      );

      if (response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true) {
          final orderData = resData['order'];
          final orderId = orderData['order_id'];

          if (resData['status'] == 'PAID') {
            // Already paid (e.g. Wallet-only or mock auto-success)
            _navigateToSuccessScreen(bookingId, assignedShopName);
            return;
          }

          final String paymentSessionId = orderData['payment_session_id'];
          final String environmentStr = resData['environment'] ?? 'sandbox';

          final environment = environmentStr.toLowerCase() == 'production'
              ? CFEnvironment.PRODUCTION
              : CFEnvironment.SANDBOX;
          final cfPaymentGatewayService = CFPaymentGatewayService();
          cfPaymentGatewayService.setCallback(
            (String orderId) {
              _verifyOrderPaymentOnServer(orderId, bookingId, assignedVendorId, assignedShopName);
            },
            (CFErrorResponse errorResponse, String orderId) {
              _handlePaymentFailed(errorResponse.getMessage() ?? "Payment failed or cancelled.");
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
          _handlePaymentFailed("Order creation failed: ${resData['message']}");
        }
      } else {
        _handlePaymentFailed("Server error code: ${response.statusCode}");
      }
    } catch (e) {
      _handlePaymentFailed("Failed to connect to payment server: $e");
    }
  }

  Future<void> _verifyOrderPaymentOnServer(
      String orderId, String bookingId, String vendorId, String shopName) async {
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
          _navigateToSuccessScreen(bookingId, shopName);
          return;
        }
      }
      _handlePaymentFailed("Payment verification failed. Please check status.");
    } catch (e) {
      _handlePaymentFailed("Network error during verification: $e");
    }
  }

  void _navigateToSuccessScreen(String bookingId, String shopName) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ThankYouScreen(
            bookingId: bookingId,
            date: widget.date ?? 'Tomorrow',
            time: widget.time ?? '10:00 AM – 12:00 PM',
            address: _userAddress,
            serviceTitle: widget.shopName ?? 'Deep Home Cleaning',
            amount: _finalGrandTotal,
          ),
        ),
      );
    }
  }

  void _handlePaymentFailed(String errorMsg) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      _showToast(errorMsg, isError: true);
    }
  }

  Widget _wrapper({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _gray),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
        Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
      ],
    );
  }

  Widget _priceRow(String label, String val, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
        Text(val,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isGreen ? _green : _dark)),
      ],
    );
  }

  Widget _paymentTile(String title, String subtitle, IconData icon) {
    final bool isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? _blue : _border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _blue : _gray, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? _blue : const Color(0xFFCBD5E1), size: 18),
          ],
        ),
      ),
    );
  }
}
