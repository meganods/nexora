import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)), title: Text("My Coupons", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCouponsHeader(),
            _buildCouponsList(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("CREATE COUPON", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCouponsHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_offer, color: Colors.amber, size: 24),
              const SizedBox(width: 10),
              Text("Promote Your Business", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text("Increase your bookings by up to 40% with targeted coupons and rewards.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCouponsList() {
    final list = [
      {"code": "CLEAN50", "desc": "Flat ₹50 OFF on house cleaning services", "status": "Active", "expiry": "12 Oct"},
      {"code": "ACDEAL", "desc": "Extra 10% OFF on AC Repair tasks", "status": "Inactive", "expiry": "Finished"},
      {"code": "SALON100", "desc": "₹100 OFF on Salon services above ₹999", "status": "Active", "expiry": "15 Oct"},
    ];
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("YOUR ACTIVE PROMOTIONS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
          const SizedBox(height: 25),
          ...list.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[100]!), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: c["status"] == "Active" ? Colors.green[50] : Colors.grey[50], borderRadius: BorderRadius.circular(10)), child: Text(c["code"]!, style: GoogleFonts.outfit(color: c["status"] == "Active" ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c["desc"]!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentColor)),
                          Text("Expiry: ${c["expiry"]}", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
