import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';
import '../screens/service_detail_screen.dart';
import '../screens/all_recommendations_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

class RecommendedSection extends StatefulWidget {
  const RecommendedSection({super.key});

  @override
  State<RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<RecommendedSection> {
  List<String>? _userCategories;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      final cats = snap.docs
          .map((d) => (d.data()['category'] ?? '').toString())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      if (mounted) setState(() => _userCategories = cats);
    } catch (_) {}
  }

  Stream<QuerySnapshot> _buildStream() {
    return FirebaseFirestore.instance.collection('services').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended For You',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _dark,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(
                        'Personalized services based on your location, booking history and interests.',
                        style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AllRecommendationsScreen(
                          preferredCategories: _userCategories)),
                ),
                child: Row(children: [
                  Text('See All',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.bold, color: _blue)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, color: _blue, size: 16),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Horizontal Cards Scroll ──────────────────────────────────────────
        SizedBox(
          height: 345,
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildStream(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, __) => const _SkeletonCard(),
                );
              }

              final allDocs = snap.data?.docs ?? [];
              final filteredDocs = allDocs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return d['isRecommended'] == true ||
                    d['isRecommendedForYou'] == true ||
                    d['featured'] == true ||
                    d['status'] == 'Approved' ||
                    d['status'] == 'approved';
              }).toList();

              final services = filteredDocs.isEmpty ? List.from(_fallback) : _mapDocs(filteredDocs);

              if (services.isEmpty) {
                return Center(
                  child: Text('No recommendations yet.',
                      style: GoogleFonts.inter(color: _gray, fontSize: 13)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: services.length > 10 ? 10 : services.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, idx) => _RecommendedCard(
                  data: services[idx],
                  animIndex: idx,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
List<Map<String, dynamic>> _mapDocs(List<QueryDocumentSnapshot> docs) {
  return docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList()
    ..sort((a, b) => ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num));
}

String _getServiceImage(String category, String originalImage) {
  if (originalImage.startsWith('http')) return originalImage;
  final cat = category.toLowerCase();
  if (cat.contains('clean')) {
    return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop';
  } else if (cat.contains('ac') || cat.contains('repair') || cat.contains('plumb') || cat.contains('electrical')) {
    return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop';
  } else if (cat.contains('salon') || cat.contains('beauty') || cat.contains('spa')) {
    return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=300&auto=format&fit=crop';
  }
  return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop';
}

ServiceModel _toModel(Map<String, dynamic> d) {
  final cat = d['category'] ?? '';
  final img = d['coverImage'] ?? d['image'] ?? '';
  return ServiceModel(
      id: d['id'] ?? '',
      title: d['name'] ?? d['title'] ?? d['serviceName'] ?? 'Service',
      price: ((d['startingPrice'] ?? d['price'] ?? 0) as num).toDouble(),
      image: _getServiceImage(cat, img),
      rating: ((d['rating'] ?? d['averageRating'] ?? 5.0) as num).toDouble(),
      category: cat,
      totalReviews: (d['totalReviews'] ?? d['reviews'] ?? 0) as int,
      vendorName: d['vendorName'] ?? d['vendor'] ?? '',
      duration: d['duration'] ?? '',
  );
}

// ─── Fallback data ────────────────────────────────────────────────────────────
const _fallback = [
  {
    'id': 'r1',
    'name': 'Full Home Deep Clean',
    'category': 'Cleaning',
    'vendorName': 'CleanPro Services',
    'vendorPhoto': 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop',
    'coverImage': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
    'startingPrice': 799,
    'rating': 4.9,
    'totalReviews': 1284,
    'completedJobs': 2400,
    'distance': '2.3 km',
    'duration': '3–4 hrs',
    'featured': true,
  },
  {
    'id': 'r2',
    'name': 'AC Service & Gas Refill',
    'category': 'AC Repair',
    'vendorName': 'CoolTech Experts',
    'vendorPhoto': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
    'coverImage': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
    'startingPrice': 499,
    'rating': 4.8,
    'totalReviews': 862,
    'completedJobs': 1100,
    'distance': '3.5 km',
    'duration': '1–2 hrs',
    'featured': true,
  },
  {
    'id': 'r3',
    'name': 'Salon at Home',
    'category': 'Beauty',
    'vendorName': 'Priya Mehta',
    'vendorPhoto': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
    'coverImage': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=300&auto=format&fit=crop',
    'startingPrice': 349,
    'rating': 4.7,
    'totalReviews': 502,
    'completedJobs': 950,
    'distance': '1.8 km',
    'duration': '1 hr',
    'featured': true,
  },
];

// ─── Skeleton card ────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: double.infinity,
              height: 157, // 16:9 for 280 width
              decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(80, 10),
              const SizedBox(height: 8),
              _box(180, 14),
              const SizedBox(height: 12),
              Row(children: [
                _box(24, 24, radius: 12),
                const SizedBox(width: 8),
                _box(100, 10),
              ]),
              const SizedBox(height: 12),
              _box(150, 10),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _box(60, 16),
                  _box(80, 32, radius: 10),
                ],
              ),
            ]),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0));
  }

  Widget _box(double w, double h, {double radius = 6}) => Container(
        width: w == double.infinity ? null : w,
        height: h,
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(radius)),
      );
}

// ─── Premium Recommended card ────────────────────────────────────────────────
class _RecommendedCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int animIndex;

  const _RecommendedCard({required this.data, required this.animIndex});

  @override
  State<_RecommendedCard> createState() => _RecommendedCardState();
}

class _RecommendedCardState extends State<_RecommendedCard> {

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? widget.data['title'] ?? 'Service';
    final category = widget.data['category'] ?? '';
    final vendor = widget.data['vendorName'] ?? widget.data['vendor'] ?? '';
    final vendorPhoto = widget.data['vendorPhoto'] ?? '';
    final price = ((widget.data['startingPrice'] ?? widget.data['price'] ?? 0) as num).toDouble();
    final rating = ((widget.data['rating'] ?? 5.0) as num).toDouble();
    final reviews = (widget.data['totalReviews'] ?? 0) as int;
    final jobs = (widget.data['completedJobs'] ?? widget.data['completedBookings'] ?? 150) as int;
    final distance = widget.data['distance'] ?? '2.5 km';
    final duration = widget.data['duration'] ?? '';
    final image = _getServiceImage(category, widget.data['coverImage'] ?? widget.data['image'] ?? '');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: _toModel(widget.data))),
      ),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image + Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: image.startsWith('http')
                      ? Image.network(image,
                          width: double.infinity,
                          height: 157, // 16:9 ratio
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPlaceholder())
                      : _imgPlaceholder(),
                ),
                // Category badge top-left
                if (category.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),

              ],
            ),

            // Content body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Title
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 8),

                    // Vendor row
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _border),
                          ),
                          child: ClipOval(
                            child: vendorPhoto.isNotEmpty
                                ? Image.network(vendorPhoto, fit: BoxFit.cover)
                                : Container(
                                    color: _blue.withValues(alpha: 0.1),
                                    child: Center(
                                      child: Text(
                                        vendor.isNotEmpty ? vendor.substring(0, 1).toUpperCase() : 'V',
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _blue),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vendor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _dark,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: _blue, size: 13),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Stats details (Rating, Reviews, Completed Jobs)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text('$rating',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _dark)),
                        Text(' ($reviews reviews)',
                            style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Distance and Duration
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: _gray),
                        const SizedBox(width: 2),
                        Text(distance, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                        if (duration.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.timer_outlined, size: 12, color: _gray),
                          const SizedBox(width: 2),
                          Text(duration, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Price & Book Button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STARTING FROM',
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: _gray,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3)),
                            Text('₹${price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: _blue)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ServiceDetailScreen(
                                    service: _toModel(widget.data))),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Book Now',
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 350.ms,
            delay: Duration(milliseconds: 60 * widget.animIndex))
        .slideX(
            begin: 0.15,
            duration: 350.ms,
            delay: Duration(milliseconds: 60 * widget.animIndex));
  }

  Widget _imgPlaceholder() => Container(
        width: double.infinity,
        height: 157,
        color: _blue.withValues(alpha: 0.08),
        child: const Icon(Icons.home_repair_service_rounded,
            color: _blue, size: 40),
      );
}
