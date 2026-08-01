import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/notifications/offer_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashOffersSection extends StatelessWidget {
  const FlashOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coupon_redemptions')
          .where('userId', isEqualTo: user?.uid ?? 'guest_user')
          .snapshots(),
      builder: (ctx1, redemptionsSnap) {
        final redemptionDocs = redemptionsSnap.data?.docs ?? [];
        final Map<String, int> userUsageMap = {};
        for (var doc in redemptionDocs) {
          final code = (doc.data() as Map<String, dynamic>)['couponCode'] as String?;
          if (code != null) {
            userUsageMap[code] = (userUsageMap[code] ?? 0) + 1;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('coupons')
              .where('status', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final now = DateTime.now();
            final docs = snapshot.data?.docs ?? [];
            final List<CouponData> offers = [];

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final code = data['code'] ?? id;

              DateTime? startDate;
              DateTime? endDate;
              if (data['startDate'] != null) {
                startDate = (data['startDate'] as Timestamp).toDate();
              }
              if (data['endDate'] != null) {
                endDate = (data['endDate'] as Timestamp).toDate();
              }

              // Filter by active dates
              if (startDate != null && startDate.isAfter(now)) continue;
              if (endDate != null && endDate.isBefore(now)) continue;

              // Limits validation
              final totalUsed = data['totalUsed'] ?? 0;
              final usageLimit = data['usageLimit'] ?? 999999;
              final usagePerUser = data['usagePerUser'] ?? 999999;
              final userUsed = userUsageMap[code] ?? 0;

              if (totalUsed >= usageLimit) continue;
              if (userUsed >= usagePerUser) continue;

              final String discountType = data['discountType'] ?? 'Flat';
              final double discountValue = (data['discountValue'] ?? 0.0) as double;
              final String discountText = discountType == 'Flat'
                  ? '₹${discountValue.toStringAsFixed(0)} OFF'
                  : '${discountValue.toStringAsFixed(0)}% OFF';

              final List<Color> gradient = id.hashCode % 2 == 0 
                  ? const [Color(0xFF2E5BFF), Color(0xFF1B40C4)]
                  : const [Color(0xFF2D80B9), Color(0xFF1B557A)];

              offers.add(
                CouponData(
                  id: id,
                  category: (data['applicableType'] ?? 'ALL').toString().toUpperCase(),
                  discount: discountText,
                  description: data['description'] ?? data['title'] ?? 'Special Deal',
                  gradient: gradient,
                  buttonTextColor: gradient.last,
                ),
              );
            }

            if (offers.isEmpty) {
              offers.addAll([
                CouponData(
                  id: 'salon500',
                  category: 'SALON',
                  discount: '₹500 OFF',
                  description: "On Men's Grooming",
                  gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  buttonTextColor: const Color(0xFF1D4ED8),
                ),
                CouponData(
                  id: 'clean20',
                  category: 'CLEANING',
                  discount: '20% OFF',
                  description: 'On Full Home Deep Cleaning',
                  gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                  buttonTextColor: const Color(0xFF0369A1),
                ),
                CouponData(
                  id: 'ac300',
                  category: 'AC REPAIR',
                  discount: '₹300 OFF',
                  description: 'On AC Service & Maintenance',
                  gradient: const [Color(0xFF4F46E5), Color(0xFF4338CA)],
                  buttonTextColor: const Color(0xFF4338CA),
                ),
              ]);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Flash Offers",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Limited time deals for you",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Horizontal Carousel
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    itemCount: offers.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: CouponCard(coupon: offers[index]),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CouponCard extends StatelessWidget {
  final CouponData coupon;

  const CouponCard({super.key, required this.coupon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfferDetailsScreen(couponId: coupon.id),
          ),
        );
      },
      child: Container(
        width: 320,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: coupon.gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: coupon.gradient.first.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Translucent bubble decoration
            Positioned(
              bottom: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.category,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    coupon.discount,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coupon.description,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "CLAIM",
                      style: GoogleFonts.inter(
                        color: coupon.buttonTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CouponData {
  final String id;
  final String category;
  final String discount;
  final String description;
  final List<Color> gradient;
  final Color buttonTextColor;

  CouponData({
    required this.id,
    required this.category,
    required this.discount,
    required this.description,
    required this.gradient,
    required this.buttonTextColor,
  });
}
