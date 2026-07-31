import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vendor_theme.dart';

class ApprovalSuccessScreen extends StatelessWidget {
  const ApprovalSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: VendorTheme.accentColor,
                    size: 72,
                  ),
                )
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                .then()
                .shake(duration: 500.ms),
                const SizedBox(height: 36),
                Text(
                  "Congratulations!",
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your Nexora Partner Account has been approved. All system workflows have been successfully activated.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureBullet("✓ Receive Booking Requests"),
                        const SizedBox(height: 12),
                        _buildFeatureBullet("✓ Toggle Online status to accept jobs"),
                        const SizedBox(height: 12),
                        _buildFeatureBullet("✓ Access instant Wallet cashouts"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/expert_dashboard', (route) => false);
                    },
                    child: const Text("Start Working"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: VendorTheme.accentColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VendorTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
