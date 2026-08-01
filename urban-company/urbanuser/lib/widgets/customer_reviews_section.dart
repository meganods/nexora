import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

class CustomerReviewsSection extends StatefulWidget {
  const CustomerReviewsSection({super.key});

  @override
  State<CustomerReviewsSection> createState() => _CustomerReviewsSectionState();
}

class _CustomerReviewsSectionState extends State<CustomerReviewsSection> {
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
                  Text('What Our Customers Say',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Trusted by thousands of happy customers',
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

        // ── List ───────────────────────────────────────────────────────────
        SizedBox(
          height: 195,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .orderBy('createdAt', descending: true)
                .limit(10)
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

              final docs = snap.data?.docs ?? [];
              final reviews = docs.isEmpty ? List.from(_fallback) : docs.map((d) {
                return {'id': d.id, ...(d.data() as Map<String, dynamic>)};
              }).toList();

              if (reviews.isEmpty) {
                return Center(
                  child: Text('No reviews available yet.',
                      style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, idx) => _ReviewCard(
                  data: reviews[idx],
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

// ─── Fallback ─────────────────────────────────────────────────────────────────
final _fallback = [
  {
    'id': 'w1',
    'customerName': 'Vishal Malhotra',
    'customerPhoto': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
    'city': 'Mumbai',
    'rating': 5,
    'comment': 'The electrician arrived on time and completed the work professionally. Very clean service.',
    'serviceCategory': 'ELECTRICIAN SERVICE',
    'timeAgo': '2 weeks ago',
    'likes': 142,
  },
  {
    'id': 'w2',
    'customerName': 'Neha Kapoor',
    'customerPhoto': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop',
    'city': 'Delhi',
    'rating': 4,
    'comment': 'Absolutely loved the salon-at-home experience. The therapist was exceptionally skilled.',
    'serviceCategory': 'SALON AT HOME',
    'timeAgo': '1 month ago',
    'likes': 98,
  },
];

// ─── Skeleton Card ────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 100, height: 10, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 6),
              Container(width: 60, height: 8, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4))),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(width: 200, height: 10, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(5))),
          const SizedBox(height: 8),
          Container(width: 150, height: 10, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(5))),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0));
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────
class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int animIndex;

  const _ReviewCard({required this.data, required this.animIndex});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isLiked = false;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = (widget.data['likes'] ?? 0) as int;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['customerName'] ?? 'Customer';
    final photo = widget.data['customerPhoto'] ?? '';
    final city = widget.data['city'] ?? '';
    final rating = (widget.data['rating'] ?? 5) as int;
    final comment = widget.data['comment'] ?? '';
    final category = widget.data['serviceCategory'] ?? '';
    final timeAgo = widget.data['timeAgo'] ?? '';

    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _blue.withValues(alpha: 0.1),
                child: photo.isNotEmpty
                    ? ClipOval(child: Image.network(photo, fit: BoxFit.cover))
                    : Text(name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.bold, color: _blue)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _dark)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                      ],
                    ),
                    if (city.isNotEmpty)
                      Text(city, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating Row
          Row(
            children: [
              Row(
                children: List.generate(
                    5,
                    (idx) => Icon(
                          idx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 14,
                        )),
              ),
              const SizedBox(width: 6),
              Text('$rating',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
            ],
          ),
          const SizedBox(height: 10),

          // Comment (Max 4 lines)
          Expanded(
            child: Text(
              comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: _dark, height: 1.4),
            ),
          ),

          // Footer info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category.isNotEmpty)
                      Text(category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _blue)),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo, style: GoogleFonts.inter(fontSize: 9, color: _gray)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border)),
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isLiked ? Colors.red : _gray,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text('$_likeCount',
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.bold, color: _gray)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
}
