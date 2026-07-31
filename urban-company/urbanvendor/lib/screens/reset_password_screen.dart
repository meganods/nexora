import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.show(context, "Password configured successfully.");
        Navigator.pushReplacementNamed(context, '/password_success');
      }
    });
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
                        Icons.lock_reset_rounded,
                        color: VendorTheme.primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      "Reset Password",
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Set your new credentials to securely log back into your Nexora Partner portal.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // New Password Input
                  Text(
                    "NEW PASSWORD",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                    validator: (v) => (v == null || v.length < 6) ? "Password must be at least 6 characters" : null,
                    decoration: const InputDecoration(
                      hintText: "••••••••",
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: VendorTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Input
                  Text(
                    "CONFIRM NEW PASSWORD",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                    validator: (v) => (v != _passwordController.text) ? "Passwords do not match" : null,
                    decoration: const InputDecoration(
                      hintText: "••••••••",
                      prefixIcon: Icon(Icons.lock_reset_rounded, color: VendorTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleReset,
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save & Update Password"),
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
