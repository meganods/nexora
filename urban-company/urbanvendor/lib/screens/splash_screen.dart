import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/vendor_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('vendors').doc(user.email).get();
        if (doc.exists) {
          final data = doc.data();
          final String status = data?['status'] ?? 'pending';
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/expert_dashboard');
          return;
        }
      } catch (e) {
        debugPrint("Splash auto-route note: $e");
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VendorTheme.bgColor,
              Color(0xFFEFF6FF), // Soft premium light blue gradient
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: VendorTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: VendorTheme.primaryColor.withValues(alpha: 0.2), width: 2),
              ),
              child: const Icon(
                Icons.handyman_rounded,
                color: VendorTheme.primaryColor,
                size: 64,
              ),
            )
            .animate()
            .scale(duration: 1000.ms, curve: Curves.elasticOut)
            .then()
            .shake(duration: 600.ms),
            const SizedBox(height: 24),
            Text(
              "NEXORA",
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: VendorTheme.textPrimary,
                letterSpacing: 3.0,
              ),
            )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(
              "Partner Portal",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VendorTheme.textSecondary,
                letterSpacing: 1.5,
              ),
            )
            .animate()
            .fadeIn(delay: 700.ms, duration: 600.ms),
            const SizedBox(height: 64),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: VendorTheme.primaryColor,
                strokeWidth: 3,
              ),
            )
            .animate()
            .fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
