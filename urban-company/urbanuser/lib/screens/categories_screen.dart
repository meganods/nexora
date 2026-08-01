import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/hero_banner_carousel.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Home Cleaning', 'Electrical', 'Plumbing'];

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Plumber',
      'image': 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?q=80&w=400&auto=format&fit=crop',
      'price': 199,
      'servicesCount': 4,
      'filter': 'Plumbing',
    },
    {
      'title': 'Carpenter',
      'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?q=80&w=400&auto=format&fit=crop',
      'price': 199,
      'servicesCount': 4,
      'filter': 'Home Cleaning',
    },
    {
      'title': 'Welder',
      'image': 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?q=80&w=400&auto=format&fit=crop',
      'price': 199,
      'servicesCount': 4,
      'filter': 'Electrical',
    },
    {
      'title': 'Contactor',
      'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400&auto=format&fit=crop',
      'price': 199,
      'servicesCount': 4,
      'filter': 'Home Cleaning',
    },
    {
      'title': 'Electrician',
      'image': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=400&auto=format&fit=crop',
      'price': 199,
      'servicesCount': 4,
      'filter': 'Electrical',
    },
    {
      'title': 'Painter',
      'image': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?q=80&w=400&auto=format&fit=crop',
      'price': 199,
      'servicesCount': 4,
      'filter': 'Home Cleaning',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);
    const lightBlue = Color(0xFFEFF6FF);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderGray = Color(0xFFE2E8F0);

    final filteredCategories = _categories.where((cat) {
      final matchesFilter = _selectedFilter == 'All' || cat['filter'] == _selectedFilter;
      final matchesSearch = cat['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        title: Text(
          'All Categories',
          style: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Filter Row
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? brandBlue : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? brandBlue : borderGray,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Search Bar under filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGray),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: textSecondary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search categories...",
                          hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),
            const HeroBannerCarousel(),
            const SizedBox(height: 12),

            // Categories Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.76,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                final title = cat['title'] as String;
                final image = cat['image'] as String;
                final price = cat['price'] as int;
                final count = cat['servicesCount'] as int;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailScreen(categoryName: title),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderGray),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(
                              image,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: lightBlue,
                                child: const Icon(Icons.handyman_rounded, color: brandBlue, size: 36),
                              ),
                            ),
                          ),
                        ),
                        // Label Details
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Starting ₹$price',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '$count Services',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow button
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: lightBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: brandBlue,
                                  size: 16,
                                ),
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
          ],
        ),
      ),
    );
  }
}
