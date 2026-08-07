import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'wallet_payment_success_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _bg = Color(0xFFF8FAFC);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _green = Color(0xFF10B981);

class WalletPaymentProcessingScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final double currentBalance;

  const WalletPaymentProcessingScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.currentBalance,
  }) : super(key: key);

  @override
  State<WalletPaymentProcessingScreen> createState() => _WalletPaymentProcessingScreenState();
}

class _WalletPaymentProcessingScreenState extends State<WalletPaymentProcessingScreen> {
  int _currentStep = 0; // 0: Initiated, 1: Verifying, 2: Updating, 3: Finalizing, 4: Done
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _startProcessingFlow();
  }

  Future<void> _startProcessingFlow() async {
    // Step 0 -> 1
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _currentStep = 1);

    // Call verify API
    bool verifySuccess = await _verifyRechargeOnServer(widget.orderId);

    if (verifySuccess) {
      if (!mounted) return;
      setState(() => _currentStep = 2);
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      setState(() => _currentStep = 3);
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      setState(() => _currentStep = 4);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WalletPaymentSuccessScreen(
            amount: widget.amount,
            newBalance: widget.currentBalance + widget.amount,
            transactionId: widget.orderId, // using orderId as fallback
            date: DateTime.now(),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<bool> _verifyRechargeOnServer(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      String url = ApiConfig.baseUrl + '/api/v1/payments/cashfree/verify';
      

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
          return true;
        } else {
          _errorMsg = 'Payment verification pending.';
          return false;
        }
      } else {
        _errorMsg = 'Failed to verify payment.';
        return false;
      }
    } catch (e) {
      _errorMsg = 'Network error during verification.';
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildPulsingWallet(),
              const SizedBox(height: 32),
              Text(
                _hasError ? 'Payment Failed' : 'Processing Payment...',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _dark),
              ),
              const SizedBox(height: 8),
              Text(
                _hasError ? _errorMsg : 'Please don\'t close this screen.',
                style: GoogleFonts.inter(fontSize: 14, color: _gray),
              ),
              const SizedBox(height: 48),
              _buildStepItem('Payment Initiated', 0),
              const SizedBox(height: 24),
              _buildStepItem('Verifying Payment', 1),
              const SizedBox(height: 24),
              _buildStepItem('Updating Wallet', 2),
              const SizedBox(height: 24),
              _buildStepItem('Finalizing', 3),
              const Spacer(),
              if (_hasError)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Go Back', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              else
                _buildSecurityBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingWallet() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primary.withOpacity(0.2)),
            strokeWidth: 2,
          ),
        ),
        if (!_hasError)
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              strokeWidth: 2,
              value: (_currentStep + 1) / 5.0,
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Icon(
            _hasError ? Icons.error_outline_rounded : Icons.account_balance_wallet_rounded,
            color: _hasError ? Colors.red : _primary,
            size: 48,
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String title, int stepIndex) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex && !_hasError;

    IconData iconData = Icons.circle_outlined;
    Color iconColor = Colors.grey.shade300;

    if (isCompleted) {
      iconData = Icons.check_circle_rounded;
      iconColor = _green;
    } else if (isActive) {
      iconData = Icons.radio_button_checked_rounded;
      iconColor = _primary;
    }

    if (_hasError && stepIndex == _currentStep) {
      iconData = Icons.cancel_rounded;
      iconColor = Colors.red;
    }

    return Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: isCompleted || isActive ? FontWeight.bold : FontWeight.normal, color: isCompleted || isActive ? _dark : _gray)),
        const Spacer(),
        if (isActive)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          )
        else
          Icon(iconData, color: iconColor, size: 24),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.security_rounded, color: _primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure & Encrypted', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                Text('Your transaction is 100% secure with Cashfree.', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
