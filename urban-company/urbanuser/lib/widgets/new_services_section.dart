import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../screens/service_detail_screen.dart';
import '../screens/all_new_services_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class NewServicesSection extends StatelessWidget {
  const NewServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final cutoffTs = Timestamp.fromDate(cutoff);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('New Services',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _dark,
                              letterSpacing: -0.5)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('NEW',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('Recently added services in your area.',
                        style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AllNewServicesScreen()),
                ),
                child: Row(children: [
                  Text('See All',
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

        // ── Horizontal Cards Scroll ──────────────────────────────────────────
        SizedBox(
          height: 345,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('services')
                .snapshots(),
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
                return d['isNewService'] == true ||
                    d['isNew'] == true ||
                    d['status'] == 'Approved' ||
                    d['status'] == 'approved' ||
                    d['createdAt'] != null;
              }).toList();

              final services = filteredDocs.isEmpty ? List.from(_fallback) : _mapDocs(filteredDocs);
              final limitedServices = services.take(10).toList();

              if (limitedServices.isEmpty) {
                return Center(
                  child: Text('No new services available.',
                      style: GoogleFonts.inter(color: _gray, fontSize: 13)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: limitedServices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, idx) => _NewServiceCard(
                  data: limitedServices[idx],
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
  return docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
}

String _timeAgo(dynamic createdAt) {
  if (createdAt == null) return '';
  DateTime dt;
  if (createdAt is Timestamp) {
    dt = createdAt.toDate();
  } else {
    return '';
  }
  final diff = DateTime.now().difference(dt);
  if (diff.inDays == 0) return 'Added Today';
  if (diff.inDays == 1) return 'Added 1 Day Ago';
  if (diff.inDays < 30) return 'Added ${diff.inDays} Days Ago';
  return 'Added ${DateFormat('d MMM').format(dt)}';
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
final _fallback = [
  {
    'id': 'n1',
    'name': 'Kitchen Deep Cleaning',
    'category': 'Cleaning',
    'vendorName': 'CleanPro Services',
    'vendorPhoto': 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop',
    'coverImage': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=300&auto=format&fit=crop',
    'startingPrice': 699,
    'rating': 4.6,
    'totalReviews': 42,
    'completedJobs': 560,
    'duration': '2–3 hrs',
    'area': 'Malad West',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
  },
  {
    'id': 'n2',
    'name': 'Sofa Steam Cleaning',
    'category': 'Cleaning',
    'vendorName': 'HomeShine',
    'vendorPhoto': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
    'coverImage': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=300&auto=format&fit=crop',
    'startingPrice': 449,
    'rating': 4.5,
    'totalReviews': 18,
    'completedJobs': 240,
    'duration': '1–2 hrs',
    'area': 'Andheri West',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
  },
  {
    'id': 'n3',
    'name': 'Geyser Installation',
    'category': 'Plumbing',
    'vendorName': 'Expert Plumbing',
    'vendorPhoto': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
    'coverImage': 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?q=80&w=300&auto=format&fit=crop',
    'startingPrice': 599,
    'rating': 4.7,
    'totalReviews': 27,
    'completedJobs': 310,
    'duration': '1 hr',
    'area': 'Bandra West',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 8))),
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
              height: 157, // 16:9 ratio
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

// ─── New service card ─────────────────────────────────────────────────────────
class _NewServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int animIndex;

  const _NewServiceCard({required this.data, required this.animIndex});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? data['title'] ?? 'Service';
    final category = data['category'] ?? '';
    final vendor = data['vendorName'] ?? data['vendor'] ?? '';
    final vendorPhoto = data['vendorPhoto'] ?? '';
    final price = ((data['startingPrice'] ?? data['price'] ?? 0) as num).toDouble();
    final rating = ((data['rating'] ?? 5.0) as num).toDouble();
    final reviews = (data['totalReviews'] ?? 0) as int;
    final duration = data['duration'] ?? '';
    final area = data['area'] ?? '';
    final image = _getServiceImage(category, data['coverImage'] ?? data['image'] ?? '');
    final timeLabel = _timeAgo(data['createdAt']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(service: _toModel(data))),
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
            // Image + NEW Badge
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
                // NEW label top-left
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('NEW',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                ),
                // Category badge top-right
                if (category.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
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
                    // Title
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

                    // Stats Details
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text('$rating',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _dark)),
                        Text(' ($reviews)',
                            style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                        const Spacer(),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: _green,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Area & Duration
                    Row(
                      children: [
                        if (area.isNotEmpty) ...[
                          const Icon(Icons.location_on_outlined, size: 12, color: _gray),
                          const SizedBox(width: 2),
                          Text(area, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                        ],
                        if (duration.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.timer_outlined, size: 12, color: _gray),
                          const SizedBox(width: 2),
                          Text(duration, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Price & Book Button
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
                                    service: _toModel(data))),
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
            delay: Duration(milliseconds: 60 * animIndex))
        .slideX(
            begin: 0.15,
            duration: 350.ms,
            delay: Duration(milliseconds: 60 * animIndex));
  }

  Widget _imgPlaceholder() => Container(
        width: double.infinity,
        height: 157,
        color: _green.withValues(alpha: 0.08),
        child: const Icon(Icons.fiber_new_rounded, color: _green, size: 40),
      );
}
