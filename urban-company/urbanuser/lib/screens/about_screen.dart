import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('About Nexora', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_blue, Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: const Icon(Icons.home_repair_service_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 16),
            Text('NEXORA', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: _blue, letterSpacing: 1)),
            Text('Managed Home Services Marketplace', style: GoogleFonts.inter(fontSize: 12, color: _gray, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Version 2.4.0 (Production Build)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _row('Platform', 'Nexora Managed Marketplace'),
                  const Divider(color: _border, height: 20),
                  _row('Operating System', 'Android & iOS'),
                  const Divider(color: _border, height: 20),
                  _row('Service Guarantee', '30-Day Free Revisit'),
                  const Divider(color: _border, height: 20),
                  _row('Security Standard', '256-bit SSL Encryption'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('© 2026 Nexora Technologies Inc. All rights reserved.', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
        Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
      ],
    );
  }
}
