import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vendor_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildDesktopLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Column: Brand Hero Banner
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFFEFF6FF), // Light slate / Soft Blue panel
            padding: const EdgeInsets.all(64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: VendorTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "NEXORA",
                      style: GoogleFonts.outfit(color: VendorTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Text(
                  "Empowering Service\nProfessionals Globally",
                  style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary, height: 1.2),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.1),
                const SizedBox(height: 24),
                Text(
                  "Manage client bookings, configure service custom rates, track earnings, and coordinate with clients seamlessly.",
                  style: GoogleFonts.inter(fontSize: 16, color: VendorTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        // Right Column: Auth Cards Container
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                height: 580,
                padding: const EdgeInsets.all(40),
                child: _buildWelcomeCardContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handyman_rounded, color: VendorTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  "NEXORA",
                  style: GoogleFonts.outfit(color: VendorTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Expanded(
              child: _buildWelcomeCardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCardContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: VendorTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VendorTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Nexora Partner Platform",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: VendorTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Access daily home service bookings, control your hours, set custom pricing rates, and receive instant payouts directly to your account.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: VendorTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Become a Partner"),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Already Registered"),
          ),
        ),
      ],
    );
  }
}
