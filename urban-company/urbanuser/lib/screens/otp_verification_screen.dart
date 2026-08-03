import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  String? _errorMessage;
  bool _verificationSuccess = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _sendOtpToEmail();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ── Generate a random 6-digit OTP ─────────────────────────────────────────
  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  // ── Send OTP to the user's registered email ────────────────────────────────
  Future<void> _sendOtpToEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    setState(() => _isSendingOtp = true);

    _userEmail = user.email ?? '';
    final otp = _generateOtp();

    // Store OTP in Firestore with expiry (10 minutes)
    final expiresAt =
        DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'otp': otp, 'otpExpiresAt': expiresAt}, SetOptions(merge: true));
    } catch (_) {}

    // Send email via EmailJS (free tier — no backend needed)
    await _sendEmailViaEmailJS(otp, _userEmail!);

    _startTimer();
    if (mounted) setState(() => _isSendingOtp = false);
  }

  // ── EmailJS integration ────────────────────────────────────────────────────
  Future<void> _sendEmailViaEmailJS(String otp, String email) async {
    try {
      // Replace these with your EmailJS credentials:
      // Sign up free at https://www.emailjs.com
      const serviceId = 'service_nexora';
      const templateId = 'template_nexora_otp';
      const publicKey = 'YOUR_EMAILJS_PUBLIC_KEY';

      final response = await http
          .post(
            Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': publicKey,
              'template_params': {
                'to_email': email,
                'otp_code': otp,
                'user_email': email,
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('EmailJS response: ${response.statusCode}');
    } catch (e) {
      // Email delivery failed — OTP still stored in Firestore for verification
      debugPrint('EmailJS error: $e');
    }
  }

  // ── Countdown Timer ────────────────────────────────────────────────────────
  void _startTimer() {
    setState(() => _secondsRemaining = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  // ── Get combined OTP string ────────────────────────────────────────────────
  String _getOtpString() =>
      _controllers.map((c) => c.text).join();

  // ── Verify OTP against Firestore ──────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final enteredOtp = _getOtpString();
    if (enteredOtp.length < 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Fetch stored OTP from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        setState(() => _errorMessage = 'OTP not found. Please request a new one.');
        return;
      }

      final data = doc.data()!;
      final storedOtp = (data['otp'] ?? '').toString();
      final otpExpiresAt = (data['otpExpiresAt'] ?? 0) as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check expiry
      if (now > otpExpiresAt) {
        setState(() => _errorMessage = 'OTP has expired. Please request a new one.');
        return;
      }

      // Check OTP match
      if (enteredOtp != storedOtp) {
        setState(() => _errorMessage = 'Incorrect OTP. Please try again.');
        // Clear entered OTP boxes
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
        return;
      }

      // ✅ OTP is correct — clear it from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'otp': FieldValue.delete(), 'otpExpiresAt': FieldValue.delete()});

      // Cache user profile into SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String name = (data['fullName'] ?? data['name'] ?? '').toString();
      final String phone =
          (data['phoneNumber'] ?? data['phone'] ?? '').toString();
      final String savedAddr =
          (data['userAddress'] ?? data['address'] ?? '').toString();
      final String type = (data['userAddressType'] ?? 'Home').toString();

      if (name.isNotEmpty) await prefs.setString('userName', name);
      if (phone.isNotEmpty) await prefs.setString('userMobile', phone);
      if (savedAddr.isNotEmpty) {
        await prefs.setString('userAddress', savedAddr);
        await prefs.setString('userAddressType', type);
      }

      if (mounted) {
        setState(() => _verificationSuccess = true);
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          // Always go to dashboard — never to address setup on login
          Navigator.pushNamedAndRemoveUntil(
              context, '/dashboard', (route) => false);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    for (var c in _controllers) {
      c.clear();
    }
    setState(() {
      _errorMessage = null;
      _verificationSuccess = false;
    });
    await _sendOtpToEmail();
  }

  // ── Handle digit input ─────────────────────────────────────────────────────
  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const backgroundSlant = Color(0xFFF8FAFC);
    const textDark = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);

    final maskedEmail = _maskEmail(_userEmail ?? '');

    return Scaffold(
      backgroundColor: backgroundSlant,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isSendingOtp
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: primaryBlue),
                    const SizedBox(height: 20),
                    Text(
                      'Sending OTP to your email…',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: textGray),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ──────────────────────────────────────────────
                    Text(
                      'NEXORA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Email icon ────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: primaryBlue.withValues(alpha: 0.2),
                              width: 2),
                        ),
                        child: const Icon(Icons.mark_email_unread_rounded,
                            color: primaryBlue, size: 34),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Subtitle ──────────────────────────────────────────
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 14, color: textGray, height: 1.5),
                        children: [
                          const TextSpan(
                              text: 'We sent a 6-digit OTP to\n'),
                          TextSpan(
                            text: maskedEmail,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                              text: '\nEnter the code below to continue.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Error banner ──────────────────────────────────────
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFF991B1B), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF991B1B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Success banner ────────────────────────────────────
                    if (_verificationSuccess) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Verification Successful!',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF065F46),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── 6 OTP Boxes ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _OtpBox(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          isLoading: _isLoading || _verificationSuccess,
                          hasError: _errorMessage != null,
                          onChanged: (val) =>
                              _onOtpDigitChanged(index, val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Resend Timer ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_secondsRemaining > 0)
                          Text(
                            'Resend OTP in ${_secondsRemaining}s',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textGray,
                                fontWeight: FontWeight.w500),
                          )
                        else ...[
                          Text(
                            "Didn't receive the code? ",
                            style: GoogleFonts.inter(
                                fontSize: 14, color: textGray),
                          ),
                          GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'Resend OTP',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Verify Button ─────────────────────────────────────
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isLoading ||
                                _verificationSuccess ||
                                _getOtpString().length < 6)
                            ? null
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              primaryBlue.withValues(alpha: 0.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Verify & Continue',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Change Email / Back to Login ───────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Use a different account',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textGray,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Mask email for display: v****@gmail.com ────────────────────────────────
  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return '${local[0]}****@$domain';
    return '${local[0]}${local[1]}****@$domain';
  }
}

// ── Individual OTP Input Box ──────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const borderGray = Color(0xFFE2E8F0);
    const errorRed = Color(0xFFFCA5A5);

    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        enabled: !isLoading,
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          counterText: '',
          fillColor: Colors.white,
          filled: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: hasError ? errorRed : borderGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: hasError ? errorRed : borderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: hasError ? errorRed : primaryBlue, width: 2.0),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
