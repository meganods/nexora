import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/service_model.dart';
import 'schedule_booking_screen.dart';
import 'vendor_profile_screen.dart';
import 'popular_services_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/hero_banner_carousel.dart';
import 'service_detail_screen.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<Map<String, dynamic>> _trending = [
    {
      'title': 'AC Deep Cleaning',
      'rating': 4.8,
      'reviews': '2.3k',
      'price': 499,
      'image': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
    },
    {
      'title': 'Sofa Shampooing',
      'rating': 4.7,
      'reviews': '1.8k',
      'price': 699,
      'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
    },
    {
      'title': 'Electrician Care',
      'rating': 4.9,
      'reviews': '1.2k',
      'price': 199,
      'image': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
    }
  ];

  final List<Map<String, dynamic>> _recent = [
    {
      'title': 'AC Repair',
      'rating': 4.9,
      'reviews': '12 reviews',
      'price': 299,
      'daysAgo': 2,
      'image': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
    },
    {
      'title': 'Home Cleaning',
      'rating': 4.9,
      'reviews': '12 reviews',
      'price': 399,
      'daysAgo': 3,
      'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
    }
  ];

  final List<Map<String, dynamic>> _popularPros = [
    {
      'name': 'Rahul & Team',
      'rating': 4.8,
      'distance': '1.6 km',
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
    },
    {
      'name': 'Amit Sharma',
      'rating': 4.7,
      'distance': '3.2 km',
      'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150&auto=format&fit=crop',
    },
    {
      'name': 'Neha Services',
      'rating': 4.9,
      'distance': '2.1 km',
      'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop',
    }
  ];

  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchUserPosition();
  }

  Future<void> _fetchUserPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  String _distanceLabel(Map<String, dynamic> v) {
    if (_userPosition == null) return '1.5 km';
    final lat = (v['lat'] ?? v['latitude'] ?? v['location']?['lat']) as num?;
    final lng = (v['lng'] ?? v['longitude'] ?? v['location']?['lng']) as num?;
    if (lat == null || lng == null) return '1.8 km';
    final dist = Geolocator.distanceBetween(
        _userPosition!.latitude, _userPosition!.longitude,
        lat.toDouble(), lng.toDouble());
    if (dist < 1000) return '${dist.toStringAsFixed(0)} m';
    return '${(dist / 1000).toStringAsFixed(1)} km';
  }

  void _navigateToBooking(Map<String, dynamic> item) {
    final double price = (item['price'] as num?)?.toDouble() ?? 199.0;
    final String serviceTitle = item['title'] ?? 'Home Service';

    final service = ServiceModel(
      id: 'dynamic_${serviceTitle.hashCode}',
      title: serviceTitle,
      category: 'Home Services',
      subCategory: 'Popular',
      price: price,
      discountPercent: 0,
      rating: (item['rating'] as num?)?.toDouble() ?? 4.8,
      totalReviews: 120,
      vendorName: "NEXORA Certified Professional",
      image: item['image'] ?? "",
      images: [item['image'] ?? ""],
      shortDescription: serviceTitle,
      description: serviceTitle,
      longDescription: serviceTitle,
      duration: '45 mins',
      isAvailable: true,
      location: "Verified Expert",
      tags: const [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleBookingScreen(
          service: service,
          selectedItems: [
            {
              'name': service.title,
              'price': price,
              'quantity': 1,
            }
          ],
          totalPrice: price,
        ),
      ),
    );
  }

  void _navigateToDetails(Map<String, dynamic> item) {
    final double price = (item['price'] as num?)?.toDouble() ?? 199.0;
    final String serviceTitle = item['title'] ?? 'Home Service';

    final service = ServiceModel(
      id: 'dynamic_${serviceTitle.hashCode}',
      title: serviceTitle,
      category: 'Home Services',
      subCategory: 'Popular',
      price: price,
      discountPercent: 0,
      rating: (item['rating'] as num?)?.toDouble() ?? 4.8,
      totalReviews: 120,
      vendorName: "NEXORA Certified Professional",
      image: item['image'] ?? "",
      images: [item['image'] ?? ""],
      shortDescription: serviceTitle,
      description: serviceTitle,
      longDescription: serviceTitle,
      duration: '45 mins',
      isAvailable: true,
      location: "Verified Expert",
      tags: const [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(service: service),
      ),
    );
  }

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
            const SizedBox(height: 20),

            // Trending Services Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🔥 Trending Services',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PopularServicesScreen(),
                      ),
                    ),
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: brandBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Trending List
            SizedBox(
              height: 250,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _trending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = _trending[index];
                  return Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderGray),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                item['image']!,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[800],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Bestseller',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item['rating']} (${item['reviews']})',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${item['price']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: brandBlue,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _navigateToDetails(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: lightBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Book Now',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: brandBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Recently Viewed Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recently Viewed',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // Recently Viewed List
            SizedBox(
              height: 250,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = _recent[index];
                  return Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderGray),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                item['image']!,
                                height: 110,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item['rating']} (${item['reviews']})',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${item['price']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: brandBlue,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _navigateToDetails(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: lightBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Book Now',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: brandBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Popular Near You Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Popular Near You',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            // Popular Near You List
            SizedBox(
              height: 195,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vendors')
                    .where('isApproved', isEqualTo: true)
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  final List<Map<String, dynamic>> vendors = docs.isEmpty
                      ? _popularPros.map((p) => {
                          'id': 'fallback_${p['name'].hashCode}',
                          'fullName': p['name'],
                          'profilePhoto': p['image'],
                          'averageRating': p['rating'],
                          'distance': p['distance'],
                        }).toList()
                      : docs.map((d) {
                          return {'id': d.id, ...(d.data() as Map<String, dynamic>)};
                        }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: vendors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final pro = vendors[index];
                      final name = pro['fullName'] ?? pro['name'] ?? 'Professional';
                      final image = pro['profilePhoto'] ?? pro['photo'] ?? pro['image'] ?? 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop';
                      final rating = ((pro['averageRating'] ?? 4.8) as num).toDouble();
                      final dist = pro['distance'] ?? _distanceLabel(pro);

                      return Container(
                        width: 145,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderGray),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(image),
                              backgroundColor: lightBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '★ $rating  •  $dist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VendorProfileScreen(
                                      vendor: pro,
                                      vendorId: pro['id'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'View',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: brandBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
