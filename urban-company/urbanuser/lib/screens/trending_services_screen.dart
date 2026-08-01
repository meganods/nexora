import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';

class TrendingServicesScreen extends StatefulWidget {
  const TrendingServicesScreen({super.key});

  @override
  State<TrendingServicesScreen> createState() => _TrendingServicesScreenState();
}

class _TrendingServicesScreenState extends State<TrendingServicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Cleaning', 'Appliance Repair', 'Plumbing', 'Electrical', 'Carpentry', 'Salon'];

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderGray = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '🔥 Trending Services',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: Column(
        children: [
          // Category filter list
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? brandBlue : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Live Services Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Filter documents by rating (trending threshold >= 4.7) and selected category
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rating = ((data['rating'] ?? 0.0) as num).toDouble();
                  final category = (data['categoryName'] ?? 'General').toString();
                  
                  final isTrending = rating >= 4.7;
                  final matchesCategory = _selectedCategory == 'All' || category.toLowerCase().contains(_selectedCategory.toLowerCase());

                  return isTrending && matchesCategory;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text('No trending services at the moment.', style: GoogleFonts.inter(color: textSecondary)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final service = ServiceModel(
                      id: doc.id,
                      title: data['title'] ?? 'Special Service',
                      category: data['categoryName'] ?? 'General',
                      subCategory: 'Popular',
                      price: ((data['price'] ?? 299.0) as num).toDouble(),
                      discountPercent: 0,
                      rating: ((data['rating'] ?? 4.8) as num).toDouble(),
                      totalReviews: (data['totalReviews'] ?? 100) as int,
                      vendorName: 'NEXORA Certified Partner',
                      image: data['imageUrl'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
                      images: [data['imageUrl'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop'],
                      shortDescription: data['description'] ?? '',
                      description: data['description'] ?? '',
                      longDescription: data['description'] ?? '',
                      duration: data['duration'] ?? '45 mins',
                      isAvailable: true,
                      location: 'Verified Expert',
                      tags: const [],
                    );

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ServiceDetailScreen(service: service)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderGray),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      child: Image.network(
                                        service.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFFF1F5F9),
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${service.rating}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.category.toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: brandBlue),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service.title,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${service.price.toInt()}',
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: brandBlue),
                                      ),
                                      Text(
                                        service.duration,
                                        style: GoogleFonts.inter(fontSize: 10, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
