import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Live promo banner — reads approved vendor campaigns targeting 'promo_banner'
/// and approved admin campaigns from Firestore. Falls back to static design.
class SinglePromoBanner extends StatelessWidget {
  const SinglePromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendor_campaigns')
          .where('status', isEqualTo: 'approved')
          .where('feePaid', isEqualTo: true)
          .snapshots(),
      builder: (ctx, snap) {
        // Filter to promo_banner placement
        final now = DateTime.now();
        final liveCampaigns = (snap.data?.docs ?? []).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final placements = List<String>.from(d['placements'] ?? []);
          final end = d['endDate'] != null ? (d['endDate'] as dynamic).toDate() : null;
          return placements.contains('promo_banner') && (end == null || end.isAfter(now));
        }).toList();

        if (liveCampaigns.isNotEmpty) {
          final d = liveCampaigns.first.data() as Map<String, dynamic>;
          return _buildDynamic(context, d);
        }

        // Default static fallback
        return _buildStatic(context);
      },
    );
  }

  Widget _buildDynamic(BuildContext context, Map<String, dynamic> d) {
    final end = d['endDate'] != null ? (d['endDate'] as dynamic).toDate() as DateTime : null;
    final daysLeft = end != null ? end.difference(DateTime.now()).inDays : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [_typeColor(d['type'] ?? ''), _typeColor(d['type'] ?? '').withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _typeColor(d['type'] ?? '').withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (d['type'] ?? 'PROMO').toUpperCase(),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                        if (daysLeft != null && daysLeft >= 0) ...[
                          const SizedBox(width: 6),
                          Text('${daysLeft}d left', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d['name'] ?? 'Special Offer',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d['description'] ?? 'Tap to explore this promotion',
                      style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text('by ${d['businessName'] ?? d['vendorName'] ?? ''}',
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(_typeIcon(d['type'] ?? ''), color: Colors.white, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatic(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800",
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: const Color(0xFFF1F5F9)),
                errorWidget: (context, url, error) => Container(color: const Color(0xFFF1F5F9)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.black.withValues(alpha: 0.75), Colors.black.withValues(alpha: 0.15)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
                      child: Text("SEASON SALE",
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    Text("AC & Appliance Repair",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text("Certified experts at your doorstep within 2 hours",
                        style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Festival': return const Color(0xFFF59E0B);
      case 'Flash Sale': return const Color(0xFFEF4444);
      case 'Referral': return const Color(0xFF10B981);
      case 'Seasonal': return const Color(0xFF06B6D4);
      default: return const Color(0xFF6366F1);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Festival': return Icons.celebration_outlined;
      case 'Flash Sale': return Icons.bolt_outlined;
      case 'Referral': return Icons.group_outlined;
      case 'Seasonal': return Icons.ac_unit_outlined;
      default: return Icons.campaign_outlined;
    }
  }
}
