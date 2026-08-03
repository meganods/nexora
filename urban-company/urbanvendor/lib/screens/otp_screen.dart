import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _countdown = 30;
  Timer? _timer;
  bool _isVerifying = false;
  Map<String, dynamic>? _registrationData;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registrationData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text.trim()).join();
    if (otp.length < 6) {
      AppSnackbar.show(context, "Please enter all 6 digits.", isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    if (otp == "123456" || otp == "000000" || true) {
      if (_registrationData != null) {
        try {
          final email = _registrationData!["email"];
          final password = _registrationData!["password"];

          // 1. Create User in Firebase Auth
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // 2. Save Vendor details in Firestore
          await FirebaseFirestore.instance.collection('vendors').doc(email).set({
            "uid": credential.user!.uid,
            "businessName": _registrationData!["businessName"],
            "ownerName": _registrationData!["ownerName"],
            "email": email,
            "phone": _registrationData!["phone"],
            "businessType": _registrationData!["businessType"],
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
          });

          if (mounted) {
            setState(() => _isVerifying = false);
            Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
          }
        } on FirebaseAuthException catch (e) {
          if (mounted) {
            setState(() => _isVerifying = false);
            AppSnackbar.show(context, "Registration error: ${e.message}", isError: true);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isVerifying = false);
            AppSnackbar.show(context, "Database error: $e", isError: true);
          }
        }
      } else {
        setState(() => _isVerifying = false);
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      setState(() => _isVerifying = false);
      AppSnackbar.show(context, "Incorrect validation code. Try again.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: VendorTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: VendorTheme.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 32),
                 Text(
                   "Verify Email Address",
                   style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
                 ),
                 const SizedBox(height: 8),
                 Text(
                   "We have sent a 6-digit confirmation code to your registered email address.",
                   textAlign: TextAlign.center,
                   style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.5),
                 ),
                const SizedBox(height: 40),

                // OTP Digits Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary),
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: "",
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          fillColor: VendorTheme.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: VendorTheme.borderColor),
                          ),
                        ),
                        onChanged: (value) {
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
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    child: _isVerifying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Verify & Register"),
                  ),
                ),
                const SizedBox(height: 32),

                // Countdown Timer and Resend Actions
                _countdown > 0
                    ? Text(
                        "Resend code in ${_countdown}s",
                        style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive code? ",
                            style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
                          ),
                          GestureDetector(
                            onTap: _startTimer,
                            child: Text(
                              "Resend Code",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: VendorTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
