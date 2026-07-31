import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/app_snackbar.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Offers & Coupons',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            _buildHeroBanner(),
            const SizedBox(height: 8),

            // Live Coupons from Firestore
            _buildSectionHeader('🎫 Available Coupons'),
            _buildLiveCoupons(context),

            // Active Campaigns
            _buildSectionHeader('🚀 Active Campaigns'),
            _buildLiveCampaigns(context),

            // Static Deals
            _buildSectionHeader('⚡ Flash Deals'),
            _buildFlashDeals(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('EXCLUSIVE OFFERS', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                ),
                const SizedBox(height: 10),
                Text('Save Big on\nEvery Service!', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
                const SizedBox(height: 6),
                Text('Use coupons & deals to get\namazing discounts on bookings.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
    );
  }

  Widget _buildLiveCoupons(BuildContext context) {
    final now = DateTime.now();
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
              .where('status', isEqualTo: 'Active')
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }

            final docs = (snap.data?.docs ?? []).where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final end = d['expiryDate'] != null ? (d['expiryDate'] as Timestamp).toDate() : null;
              final code = d['code'] ?? doc.id;
              
              // Date validation
              if (end != null && end.isBefore(now)) return false;

              // Limits validation
              final totalUsed = d['totalUsed'] ?? 0;
              final usageLimit = d['usageLimit'] ?? 999999;
              final usagePerUser = d['usagePerUser'] ?? 999999;
              final userUsed = userUsageMap[code] ?? 0;

              if (totalUsed >= usageLimit) return false;
              if (userUsed >= usagePerUser) return false;

              return true;
            }).toList();

            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Text('No active coupons right now.\nCheck back soon!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.5)),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: docs.length,
              itemBuilder: (ctx2, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return _couponCard(context, d);
              },
            );
          },
        );
      },
    );
  }

  Widget _couponCard(BuildContext context, Map<String, dynamic> d) {
    final code = d['code'] ?? 'NEXORA';
    final discount = d['discountType'] == 'Percentage'
        ? '${d['discountValue']}% OFF'
        : '₹${d['discountValue']} OFF';
    final minOrder = d['minOrderValue'] ?? 0;
    final expiry = d['expiryDate'] != null
        ? DateFormat('dd MMM yyyy').format((d['expiryDate'] as Timestamp).toDate())
        : 'No expiry';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          // Left colored strip
          Container(
            width: 6,
            height: 100,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(d['title'] ?? 'Special Offer', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF1E293B))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: Text(discount, style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(d['description'] ?? '', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text('Valid till $expiry', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                      const SizedBox(width: 10),
                      if (minOrder > 0)
                        Text('Min ₹$minOrder', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Copy button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                AppSnackbar.show(context, '✅ Coupon "$code" copied!');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary.withValues(alpha: 0.3), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Text(code, style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text('TAP TO COPY', style: GoogleFonts.inter(color: _primary.withValues(alpha: 0.6), fontSize: 7, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCampaigns(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final docs = (snap.data?.docs ?? []).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final end = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
          return end == null || end.isAfter(now);
        }).toList();

        // Also get vendor campaigns
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vendor_campaigns')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (ctx2, vendorSnap) {
            final vendorDocs = (vendorSnap.data?.docs ?? []).where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final end = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
              final adminFee = ((d['adminFee'] ?? 0) as num).toDouble();
              final feePaid = d['feePaid'] == true;
              return (end == null || end.isAfter(now)) && (adminFee == 0 || feePaid);
            }).toList();

            if (docs.isEmpty && vendorDocs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Text('No active campaigns right now.', textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12)),
                ),
              );
            }

            return SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _campaignTile(d, isAdmin: true);
                  }),
                  ...vendorDocs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _campaignTile(d, isAdmin: false);
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _campaignTile(Map<String, dynamic> d, {required bool isAdmin}) {
    final Color bg = _typeColor(d['type'] ?? '');
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(6)),
                child: Text((d['type'] ?? 'PROMO').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('NEXORA', style: TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d['name'] ?? d['title'] ?? 'Campaign', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(d['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlashDeals(BuildContext context) {
    final deals = [
      {
        'title': 'First Booking Offer',
        'desc': 'Get 20% off on your very first booking with NEXORA',
        'code': 'WELCOME20',
        'discount': '20% OFF',
        'color': const Color(0xFF7C3AED),
        'icon': Icons.stars_rounded,
      },
      {
        'title': 'Weekend Special',
        'desc': 'Book any home service on weekends and save flat ₹200',
        'code': 'WEEKEND200',
        'discount': '₹200 OFF',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.weekend_outlined,
      },
      {
        'title': 'Home Cleaning Deal',
        'desc': 'Special discount on all deep cleaning services this month',
        'code': 'CLEAN15',
        'discount': '15% OFF',
        'color': const Color(0xFF10B981),
        'icon': Icons.cleaning_services_outlined,
      },
      {
        'title': 'AC Service Offer',
        'desc': 'Get ₹150 off on AC service and maintenance today',
        'code': 'AC150',
        'discount': '₹150 OFF',
        'color': const Color(0xFF06B6D4),
        'icon': Icons.ac_unit_outlined,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: deals.length,
      itemBuilder: (ctx, i) {
        final deal = deals[i];
        final color = deal['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 95,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(deal['icon'] as IconData, color: color, size: 22),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(deal['title'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(deal['discount'] as String, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(deal['desc'] as String, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10), maxLines: 2),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: deal['code'] as String));
                        AppSnackbar.show(context, '✅ Code "${deal['code']}" copied!');
                      },
                      child: Text(
                        '🏷️ ${deal['code']}  •  TAP TO COPY',
                        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 10, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Festival':    return const Color(0xFFF59E0B);
      case 'Flash Sale':  return const Color(0xFFEF4444);
      case 'Referral':    return const Color(0xFF10B981);
      case 'Seasonal':    return const Color(0xFF06B6D4);
      default:            return const Color(0xFF6366F1);
    }
  }
}
