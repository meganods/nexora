import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../widgets/app_toast.dart';
import '../services/invoice_service.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _secondary = Color(0xFF3B82F6);
const _bg = Color(0xFFF8FAFC);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _green = Color(0xFF10B981);
const _border = Color(0xFFE2E8F0);

class WithdrawScreen extends StatefulWidget {
  final double availableBalance;

  const WithdrawScreen({Key? key, required this.availableBalance}) : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  int _currentStep = 1; // 1: Enter details, 2: Confirm, 3: OTP, 4: Success
  final TextEditingController _amountController = TextEditingController(text: '1000');
  final TextEditingController _otpController = TextEditingController();
  
  double _amount = 1000.0;
  String _selectedMethod = 'Bank Account'; // 'Bank Account' or 'UPI'
  
  // Bank details
  String _bankName = 'HDFC Bank';
  String _accountNumber = 'XXXX2458';
  String _upiId = 'vishal@okhdfcbank';

  bool _isSubmitting = false;
  String _withdrawId = '';

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {
        _amount = double.tryParse(_amountController.text) ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal() async {
    setState(() => _isSubmitting = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/customer-payouts/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': _amount,
          'bankAccount': _selectedMethod == 'Bank Account' ? '$_bankName $_accountNumber' : _upiId,
          'upiId': _selectedMethod == 'UPI' ? _upiId : null,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        setState(() {
          _withdrawId = data['withdrawId'] ?? 'WD${10000 + math.Random().nextInt(90000)}';
          _currentStep = 4; // success
        });
      } else {
        AppToast.show(context, title: 'Error', message: data['message'] ?? 'Withdrawal failed.', isError: true);
        setState(() => _currentStep = 1);
      }
    } catch (e) {
      AppToast.show(context, title: 'Error', message: 'Connection failed.', isError: true);
      setState(() => _currentStep = 1);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _downloadReceipt() async {
    final bookingMap = {
      'id': _withdrawId,
      'shopName': 'Wallet Withdrawal',
      'bookingId': _withdrawId,
      'price': '₹${_amount.toStringAsFixed(0)}',
      'rawAmount': _amount,
      'paymentMethod': _selectedMethod == 'Bank Account' ? '$_bankName ($_accountNumber)' : 'UPI',
      'bookingStatus': 'Completed',
      'date': 'Today',
      'couponDiscount': 0.0,
    };
    try {
      await InvoiceService.downloadInvoice(context: context, booking: bookingMap);
      if (mounted) {
        AppToast.show(
          context,
          title: '✅ Receipt Saved',
          message: 'Withdrawal receipt saved as PDF!',
          icon: Icons.picture_as_pdf_rounded,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep == 4
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
                onPressed: () {
                  if (_currentStep > 1) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
        title: Text(
          _currentStep == 4 ? 'Status' : 'Withdraw Funds',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Details();
      case 2:
        return _buildStep2Confirmation();
      case 3:
        return _buildStep3OTP();
      case 4:
        return _buildStep4Success();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Balance', style: GoogleFonts.inter(fontSize: 13, color: _gray)),
                    const SizedBox(height: 4),
                    Text('₹${widget.availableBalance.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: _dark)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: _primary, size: 24),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Enter Amount Section
          Text('Enter Amount', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _dark),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('₹', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _gray)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Destination options
          Text('Choose Destination', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Bank Account'),
                  selected: _selectedMethod == 'Bank Account',
                  onSelected: (val) {
                    if (val) setState(() => _selectedMethod = 'Bank Account');
                  },
                  selectedColor: _primary.withOpacity(0.15),
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.inter(color: _selectedMethod == 'Bank Account' ? _primary : _dark, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('UPI ID'),
                  selected: _selectedMethod == 'UPI',
                  onSelected: (val) {
                    if (val) setState(() => _selectedMethod = 'UPI');
                  },
                  selectedColor: _primary.withOpacity(0.15),
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.inter(color: _selectedMethod == 'UPI' ? _primary : _dark, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Conditional Details
          if (_selectedMethod == 'Bank Account') ...[
            _detailRow('Bank Name', _bankName, (val) => setState(() => _bankName = val)),
            const SizedBox(height: 12),
            _detailRow('Account Number', _accountNumber, (val) => setState(() => _accountNumber = val)),
          ] else ...[
            _detailRow('UPI ID', _upiId, (val) => setState(() => _upiId = val)),
          ],
          const SizedBox(height: 32),

          // Summary Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border, width: 0.5)),
            child: Column(
              children: [
                _summaryLine('Convenience Fee', '₹0.00', isGreen: true),
                const Divider(height: 24, color: _bg),
                _summaryLine('Expected Settlement', 'Instant (within 24 Hours)', isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (_amount <= 0 || _amount > widget.availableBalance) {
                  AppToast.show(context, title: 'Invalid Amount', message: 'Please enter a valid amount within your withdrawable balance.', isError: true);
                  return;
                }
                setState(() => _currentStep = 2);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: Text('Continue', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep2Confirmation() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.security_rounded, color: _primary, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Review Withdrawal Request', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border, width: 0.5)),
            child: Column(
              children: [
                _summaryLine('Withdrawal Amount', '₹${_amount.toStringAsFixed(2)}', isBold: true),
                const Divider(height: 24),
                _summaryLine('Transfer To', _selectedMethod == 'Bank Account' ? '$_bankName ($_accountNumber)' : _upiId),
                const Divider(height: 24),
                _summaryLine('Settlement Mode', 'Instant Payout'),
              ],
            ),
          ),
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 3),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: Text('Confirm & Verify', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep3OTP() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), shape: BoxShape.circle),
            child: const Icon(Icons.phonelink_lock_rounded, color: Color(0xFFD97706), size: 48),
          ),
          const SizedBox(height: 24),
          Text('Security Verification', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 8),
          Text('Enter the 6-digit simulation code below to authenticate the withdrawal.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: _gray)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _border.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: Text('OTP Simulation Code: 647281', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: _primary)),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8, color: _dark),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade300, letterSpacing: 8),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primary, width: 2)),
            ),
          ),
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_otpController.text == '647281') {
                        _submitWithdrawal();
                      } else {
                        AppToast.show(context, title: 'Verification Failed', message: 'Invalid OTP code. Please enter 647281.', isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Verify & Submit', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep4Success() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: _green, size: 64),
          ),
          const SizedBox(height: 24),
          Text('Withdrawal Successful', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 8),
          Text('₹${_amount.toStringAsFixed(2)} is being transferred to your account.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: _gray)),
          const SizedBox(height: 28),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border, width: 0.5)),
            child: Column(
              children: [
                _summaryLine('Transaction ID', _withdrawId),
                const Divider(height: 24),
                _summaryLine('Target Account', _selectedMethod == 'Bank Account' ? '$_bankName ($_accountNumber)' : _upiId),
                const Divider(height: 24),
                _summaryLine('Settlement Mode', 'Instant'),
              ],
            ),
          ),
          const Spacer(),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadReceipt,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: Text('Receipt', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: _gray)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _dark),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border, width: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _summaryLine(String label, String value, {bool isGreen = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: _gray)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isGreen ? _green : _dark,
          ),
        ),
      ],
    );
  }
}
