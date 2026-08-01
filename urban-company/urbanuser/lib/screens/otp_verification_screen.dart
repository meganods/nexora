import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;
  bool _verificationSuccess = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _getOtpString() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtpString();
    if (otp.length < 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate/Trigger SMS verification
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _verificationSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        final prefs = await SharedPreferences.getInstance();
        String savedAddr = prefs.getString('userAddress') ?? '';

        if (user != null && savedAddr.trim().isEmpty) {
          try {
            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            if (doc.exists && doc.data() != null) {
              savedAddr = doc.data()?['userAddress'] ?? doc.data()?['address'] ?? '';
            }
          } catch (_) {}
        }

        if (mounted) {
          if (savedAddr.trim().isEmpty) {
            Navigator.pushReplacementNamed(context, '/address_setup');
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp(); // Auto-verify when last digit is filled
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
    const borderGray = Color(0xFFE2E8F0);
    const textDark = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundSlant,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Nexora Logo
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
              const SizedBox(height: 36),

              // Title
              Text(
                'Verify Your Phone Number',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Enter the 6-digit verification code sent to your mobile number.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF991B1B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_verificationSuccess) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
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

              // 6 OTP Fields Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      enabled: !_isLoading && !_verificationSuccess,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderGray),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: borderGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryBlue, width: 2.0),
                        ),
                      ),
                      onChanged: (val) => _onOtpDigitChanged(index, val),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Countdown / Resend UI
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _secondsRemaining > 0
                        ? 'Resend code in ${_secondsRemaining}s'
                        : "Didn't receive the code? ",
                    style: GoogleFonts.inter(fontSize: 14, color: textGray, fontWeight: FontWeight.w500),
                  ),
                  if (_secondsRemaining == 0)
                    GestureDetector(
                      onTap: _startTimer,
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.inter(fontSize: 14, color: primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 36),

              // Verify OTP Primary button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading || _getOtpString().length < 6 ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Verify OTP',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
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
}
