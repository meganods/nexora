import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/vendor_theme.dart';

class PasswordSuccessScreen extends StatelessWidget {
  const PasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7), // Soft premium green circle
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: VendorTheme.accentColor,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  "Success!",
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  "Password instructions sent. Check your inbox and click the security link to proceed.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                    child: const Text("Return to Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
