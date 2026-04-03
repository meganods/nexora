import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Rewards", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.info_outline, color: Colors.grey), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPointsHeader(),
            _buildScratchCardsSection(),
            _buildCouponsSection(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 30),
              const SizedBox(width: 10),
              Text("1,240 Points", style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text("Earn 260 more points for a free haircut!", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 25),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.8,
              child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber, Colors.orange]), borderRadius: BorderRadius.circular(4))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Text("SCRATCH & WIN", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2))),
        const SizedBox(height: 20),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 25),
            children: [
              _scratchCard(const Color(0xFF673AB7), Icons.local_offer, "Win up to ₹500"),
              _scratchCard(const Color(0xFFFFD700), Icons.card_giftcard, "Gift Voucher"),
              _scratchCard(const Color(0xFF00BFA5), Icons.flash_on, "Extra 10% Off"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scratchCard(Color color, IconData icon, String label) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.1, child: Icon(icon, color: Colors.white, size: 80)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsSection() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MY COUPONS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _couponItem("SAVE50", "Flat ₹50 OFF on first house cleaning service", "Exp: 20 Oct"),
          _couponItem("PLUSFREE", "1 Month Plus Membership for FREE", "Exp: 15 Nov"),
          _couponItem("UBERCO", "25% OFF on Uber rides using this code", "Exp: 30 Oct"),
        ],
      ),
    );
  }

  Widget _couponItem(String code, String desc, String expiry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[100]!), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber[200]!, style: BorderStyle.none)), child: Text(code, style: GoogleFonts.outfit(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentColor)),
                const SizedBox(height: 4),
                Text(expiry, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        ],
      ),
    );
  }
}
