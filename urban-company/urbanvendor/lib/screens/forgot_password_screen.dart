import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim().toLowerCase();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.show(context, "Password recovery link dispatched to your inbox.");
        Navigator.pushReplacementNamed(context, '/password_success');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.show(context, "Error sending reset link: $e", isError: true);
      }
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: VendorTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: VendorTheme.primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      "Recover Password",
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Enter your email to receive a password reset link to access your account.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Input
                  Text(
                    "EMAIL ADDRESS",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                    validator: (v) => (v == null || !v.contains("@")) ? "Enter a valid email address" : null,
                    decoration: const InputDecoration(
                      hintText: "name@company.com",
                      prefixIcon: Icon(Icons.email_outlined, color: VendorTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handlePasswordReset,
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Send Reset Instructions"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
