import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);

class ReferEarnSection extends StatefulWidget {
  const ReferEarnSection({super.key});

  @override
  State<ReferEarnSection> createState() => _ReferEarnSectionState();
}

class _ReferEarnSectionState extends State<ReferEarnSection> {
  final String _referralCode = 'NEXORA500';

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Referral code copied successfully.',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Refer & Earn',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Invite friends and earn exciting rewards together.',
                      style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Row(children: [
                  Text('View All',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.bold, color: _blue)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: _blue, size: 16),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Premium Card ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: _blue.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('LIMITED REFERRAL REWARD',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ),
                    const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 16),

                // Heading
                Text('Refer Friends',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Earn ₹500 for every successful referral.',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 8),
                Text(
                    'Invite your friends to NEXORA. When they complete their first booking, both of you receive rewards automatically.',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.4)),
                const SizedBox(height: 20),

                // Referral code card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR REFERRAL CODE',
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(_referralCode,
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyToClipboard,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.copy_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Primary button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _blue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Invite Friends',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Share Referral Link',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, duration: 400.ms),
      ],
    );
  }
}
