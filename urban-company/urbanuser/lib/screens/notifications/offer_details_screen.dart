import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OfferDetailsScreen extends StatelessWidget {
  final String couponId;

  const OfferDetailsScreen({super.key, required this.couponId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('coupons').doc(couponId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text("Offer Details")),
            body: const Center(child: Text("Offer details not found.")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String code = data['code'] ?? 'CODE';
        final String title = data['title'] ?? 'Special Offer';
        final String description = data['description'] ?? 'Special discount for you';
        final String discountType = data['discountType'] ?? 'Flat';
        final double discountValue = (data['discountValue'] ?? 0.0) as double;
        final double minOrder = (data['minimumOrder'] ?? 0.0) as double;
        final int usageLimit = data['usageLimit'] ?? 0;
        final int perUserLimit = data['perUserLimit'] ?? 1;

        final String discountText = discountType == 'Flat'
            ? 'Flat ₹${discountValue.toStringAsFixed(0)} OFF'
            : '${discountValue.toStringAsFixed(0)}% OFF';

        String validityText = "Valid for limited time only";
        if (data['endDate'] != null) {
          try {
            final DateTime dt = (data['endDate'] as Timestamp).toDate();
            validityText = "Valid till ${DateFormat('dd MMM yyyy').format(dt)}";
          } catch (_) {}
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Offer Details",
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promo Banner Container
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountText,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Coupon Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "YOUR COUPON CODE",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE), style: BorderStyle.solid),
                        ),
                        child: Text(
                          code,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "Terms & Conditions",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                _buildTermBullet(validityText),
                _buildTermBullet("Minimum order value required: ₹${minOrder.toStringAsFixed(0)}."),
                _buildTermBullet("Max limit per user: $perUserLimit redemption(s)."),
                _buildTermBullet("Total platform usage limit: $usageLimit coupon claims."),
                const SizedBox(height: 36),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Coupon $code applied to your cart!", style: GoogleFonts.inter()),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    "Apply Coupon",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2563EB), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
