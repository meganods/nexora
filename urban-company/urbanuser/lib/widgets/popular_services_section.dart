import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../screens/service_detail_screen.dart';

class PopularServicesSection extends StatelessWidget {
  const PopularServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const textDark = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);
    const borderGray = Color(0xFFE2E8F0);



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
                    'Popular Services',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Most booked services this week',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textGray,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/popular_services'),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: primaryBlue, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Horizontal list of services
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final List<ServiceModel> services = docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return ServiceModel(
                id: doc.id,
                title: d['categoryName'] ?? d['name'] ?? d['serviceName'] ?? 'Service Item',
                price: ((d['startingPrice'] ?? d['price'] ?? 199) as num).toDouble(),
                rating: ((d['rating'] ?? 5.0) as num).toDouble(),
                totalReviews: d['reviewsCount'] ?? d['totalReviews'] ?? 0,
                duration: d['duration'] ?? '1 Hour',
                image: d['categoryImageUrl'] ?? d['coverImage'] ?? d['image'] ?? '',
                category: d['categoryName'] ?? d['category'] ?? '',
              );
            }).toList();

            return SizedBox(
              height: 290,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final s = services[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailScreen(service: s),
                        ),
                      );
                    },
                    child: Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderGray),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cover Image with verified badge
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                                child: s.image.startsWith('http')
                                    ? Image.network(s.image, height: 150, width: double.infinity, fit: BoxFit.cover)
                                    : Image.asset(s.image, height: 150, width: double.infinity, fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Container(
                                          height: 150,
                                          color: primaryBlue.withValues(alpha: 0.1),
                                          child: const Icon(Icons.handyman_rounded, color: primaryBlue, size: 48),
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${s.rating}',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textDark),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Text Content & Pricing Row
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.category.toUpperCase(),
                                        style: GoogleFonts.inter(fontSize: 10, color: primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        s.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${s.duration} • Starting from ₹${s.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(fontSize: 11, color: textGray, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ServiceDetailScreen(service: s),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text('Book'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
