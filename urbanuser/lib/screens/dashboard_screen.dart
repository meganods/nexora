import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urbanuser/widgets/custom_bottom_nav.dart';
import 'category_detail_screen.dart';
import '../theme/app_theme.dart';
import 'categories_screen.dart';
import '../data/dummy_data.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';
import 'service_list_screen.dart';
import '../data/rewards_data.dart';
import 'refer_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_bookings_screen.dart';
import 'wallet_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _bannerController = PageController(initialPage: 0);
  int _currentBannerIndex = 0;
  String _userAddress = "4517 Washington Ave";
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients) {
        int nextPage = _bannerController.page!.round() + 1;
        if (nextPage >= _banners.length) {
          nextPage = 0;
        }
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('userAddress');
    if (savedAddress != null && savedAddress.trim().isNotEmpty) {
      final parts = savedAddress.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      setState(() {
        if (parts.length >= 2) {
          _userAddress = "${parts[0]}, ${parts[1]}";
        } else {
          _userAddress = parts.join(', ');
        }
      });
    }
  }

  final List<BannerData> _banners = [
    BannerData(
      title: "Best Professional\nHome Cleaning",
      subtitle: "Kitchen & House",
      discount: "40% OFF",
      image: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800",
    ),
    BannerData(
      title: "Expert Repair\n& Maintenance",
      subtitle: "Plumbing & Electrical",
      discount: "20% OFF",
      image: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800",
    ),
    BannerData(
      title: "Deep Car Wash\n& Detailing",
      subtitle: "Auto Care",
      discount: "30% OFF",
      image: "https://images.unsplash.com/photo-1601362840469-51e4d8d59085?w=800",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBannerCarousel(),
              const SizedBox(height: 24),
              _buildWhatDoYouNeedHeader(),
              _buildCategoryGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader("New Services", "View All"),
              _buildNewServicesCarousel(),
              const SizedBox(height: 24),
              _buildSectionHeader("Service Stories", "View All"),
              _buildVideoStories(),
              const SizedBox(height: 24),
              _buildSectionHeader("Best in Your City", "View All"),
              _buildBestInYourCityVerticalList(),
              const SizedBox(height: 24),
              _buildHealthSafetyBanner(),
              const SizedBox(height: 24),
              _buildSectionHeader("Special Deals", ""),
              _buildSpecialOffers(),
              const SizedBox(height: 24),
              _buildSectionHeader("Trending Services", ""),
              _buildTrendingServices(),
              const SizedBox(height: 24),
              _buildSectionHeader("Recommended for You", ""),
              _buildRecommendedList(),
              const SizedBox(height: 24),
              _buildSectionHeader("Offers that will make you smile", ""),
              _buildSmileOffersCarousel(),
              const SizedBox(height: 24),
              _buildSectionHeader("Top Rated Vendors", "View All"),
              _buildVendorCarousel(),
              const SizedBox(height: 24),
              _buildSectionHeader("What our customers say", ""),
              _buildCustomerReviews(),
              const SizedBox(height: 24),
              _buildHowItWorks(),
              const SizedBox(height: 24),
              _buildCommonQuestions(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.lightGray,
            child: IconButton(
              icon: const Icon(
                Icons.grid_view_sharp,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => _showTopCategoryMenu(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/address_setup');
              },
              child: Column(
                children: [
                  Text(
                    "Address",
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _userAddress,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen(autoFocusSearch: true)));
            },
            child: CircleAvatar(
              backgroundColor: AppTheme.lightGray,
              child: const Icon(Icons.search, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: banner.image.startsWith("http")
                          ? Image.network(banner.image, fit: BoxFit.cover)
                          : Image.asset(banner.image, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.leftCenter,
                            end: Alignment.rightCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              banner.discount.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.subtitle,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: ElevatedButton(
                        onPressed: () {
                          String targetCategory = "Cleaning";
                          if (banner.title.contains("Repair") || banner.title.contains("Maintenance")) {
                            targetCategory = "Plumber";
                          } else if (banner.title.contains("Car")) {
                            targetCategory = "Car Wash";
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailScreen(categoryName: targetCategory),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF673AB7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Details",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF673AB7)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentBannerIndex == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentBannerIndex == index ? const Color(0xFF673AB7) : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return const SizedBox.shrink(); // Replaced by a single clean promo banner card
  }

  Widget _buildWhatDoYouNeedHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "What do you need?",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                },
                child: Text(
                  "See All >",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Choose from our premium services",
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // --- CAROUSEL 1: Best In Your City (Now Live) ---
  Widget _buildServiceCarousel() {
    final List<ServiceModel> services = DummyData.getBySection("Best In Your City");

    return SizedBox(
      height: 220,
      child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailScreen(service: service),
                  ),
                ),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey[100]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                          child: service.image.startsWith('assets')
                              ? Image.asset(
                                  service.image,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppTheme.lightGray,
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                                )
                              : Image.network(
                                  service.image,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppTheme.lightGray,
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  service.price,
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.orange, size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${service.rating}",
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
          ),
        );
  }

  // --- CAROUSEL 2: Top Vendors (Now Live) ---
  Widget _buildVendorCarousel() {
    final vendors = DummyData.topVendors;

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: vendors.length,
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return GestureDetector(
            onTap: () {
              String cat = "Cleaning";
              if (vendor['name'].toString().contains("Repairs")) cat = "Plumbing";
              if (vendor['name'].toString().contains("Mechanic")) cat = "Car Wash";
              if (vendor['name'].toString().contains("Painters")) cat = "Painting";
              Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryDetailScreen(categoryName: cat)));
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(vendor['color']),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vendor['name'],
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor['tasks'],
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewServicesCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.take(10).toList();
        if (docs.isEmpty) {
          return const Center(child: Text("No new services available."));
        }

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['categoryName'] ?? data['title'] ?? 'Service';
              final subSvcs = List.from(data['subServices'] ?? []);

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
                  width: 160,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF00796B),
                        const Color(0xFF00796B).withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${subSvcs.length} Options',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final List<Map<String, dynamic>> items = [
      {"title": "Cleaning", "image": "assets/images/categories/cleaner_icon_1774853550305.png"},
      {"title": "Plumbing", "image": "assets/images/categories/plumber_icon_1774853426358.png"},
      {"title": "Electrician", "image": "assets/images/categories/electrician_icon_1774853479339.png"},
      {"title": "Carpenter", "image": "assets/images/categories/carpenter_icon_1774853442272.png"},
      {"title": "Painter", "image": "assets/images/categories/painter_icon_1774853496361.png"},
      {"title": "Pest Control", "image": "assets/images/categories/pest_control.png"},
      {"title": "Appliance", "image": "assets/images/categories/ac_repair.png"},
      {"title": "Others", "image": "others"},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String title = item["title"]!;
        final String image = item["image"]!;

        return GestureDetector(
          onTap: () {
            if (title == "Others") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(categoryName: title),
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F9), // Light grey/blue premium tint
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: image == "others"
                      ? const Icon(Icons.more_horiz_rounded, size: 28, color: AppTheme.accentColor)
                      : Image.asset(
                          image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.category_outlined, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialOffers() {
    return SizedBox(
      height: 125,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        children: [
          Container(
            width: 280,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4), // Soft yellow background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFF59D)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Free Inspection",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Valid till 22th",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey[750],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A), // Dark slate blue button
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Book Now",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.confirmation_num_outlined,
                  size: 55,
                  color: Color(0xFFFFD54F),
                ),
              ],
            ),
          ),
          Container(
            width: 280,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD), // Soft blue background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Get ₹200 Referral",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Valid for limited time",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey[750],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A), // Dark slate blue button
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Refer Now",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.card_giftcard_outlined,
                  size: 55,
                  color: Color(0xFF90CAF9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTrendingServices() {
    final List<Map<String, dynamic>> items = [
      {"title": "Sofa Cleaning", "color": 0xFFE3F2FD, "icon": Icons.weekend_outlined},
      {"title": "Carpet Cleaning", "color": 0xFFFFF3E0, "icon": Icons.layers_outlined},
      {"title": "AC Repair/Service", "color": 0xFFF3E5F5, "icon": Icons.ac_unit_outlined},
      {"title": "Gas Service", "color": 0xFFE8F5E9, "icon": Icons.local_fire_department_outlined},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 2.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryDetailScreen(categoryName: "Cleaning"),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(item["color"]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(item["icon"], color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item["title"],
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendedList() {
    final List<Map<String, dynamic>> recs = [
      {
        "title": "Kitchen Cleaning",
        "price": "₹150",
        "discount": "20% OFF",
        "image": "https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=720&auto=format&fit=crop"
      },
      {
        "title": "House Cleaning",
        "price": "₹150",
        "discount": "20% OFF",
        "image": "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=720&auto=format&fit=crop"
      }
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recs.length,
      itemBuilder: (context, index) {
        final item = recs[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryDetailScreen(categoryName: "Cleaning"),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item["image"],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            item["price"],
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item["discount"],
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmileOffersCarousel() {
    final List<Map<String, dynamic>> items = [
      {
        "title": "Sofa Cleaning starting at 999",
        "rating": "4.8",
        "price": "₹999",
        "image": "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=720&auto=format&fit=crop"
      },
      {
        "title": "Car Wash Premium Deep Clean",
        "rating": "4.9",
        "price": "₹499",
        "image": "https://images.unsplash.com/photo-1619642751056-25f4fb49e8eb?q=80&w=720&auto=format&fit=crop"
      }
    ];

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryDetailScreen(categoryName: "Cleaning"),
                ),
              );
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      item["image"],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              item["rating"],
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item["price"],
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
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
      ),
    );
  }

  Widget _buildHealthSafetyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEFA), // Soft lavender background
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("•", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text(
                      "SAFETY FIRST PROTOCOLS",
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5E35B1),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Your health is our\ntop priority.",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                _healthPoint(Icons.masks_outlined, "Double Masking", "Mandatory for all experts during visits"),
                const SizedBox(height: 16),
                _healthPoint(Icons.clean_hands_outlined, "Daily Sanitization", "Equipment sanitized before every job"),
                const SizedBox(height: 16),
                _healthPoint(Icons.vaccines_outlined, "Fully Vaccinated", "100% of our pros are fully vaccinated"),
                const SizedBox(height: 16),
                _healthPoint(Icons.thermostat_outlined, "Health Tracking", "Real-time body temp tracking daily"),
              ],
            ),
          ),
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
                child: Image.network(
                  "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=720&auto=format&fit=crop",
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      color: Colors.white.withValues(alpha: 0.8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Verified & Safe Expert",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                          Text(
                            "Learn More",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5E35B1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthPoint(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF5E35B1), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestInYourCityVerticalList() {
    final List<Map<String, dynamic>> items = [
      {
        "title": "Classic Bathroom Cleaning",
        "rating": "4.8 (1.2k reviews)",
        "price": "₹249",
        "image": "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=720&auto=format&fit=crop",
        "tag": "POPULAR",
      },
      {
        "title": "Salon for Women",
        "rating": "4.7 (850 reviews)",
        "price": "₹399",
        "image": "https://images.unsplash.com/photo-1562322140-8baeececf3df?q=80&w=720&auto=format&fit=crop",
        "tag": "RECOMMENDED",
      },
      {
        "title": "AC Service & Repair",
        "rating": "4.9 (1.5k reviews)",
        "price": "₹599",
        "image": "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=720&auto=format&fit=crop",
        "tag": "TOP RATED",
      }
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryDetailScreen(categoryName: "Cleaning"),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        item["image"],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item["tag"],
                          style: GoogleFonts.outfit(
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"],
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            item["rating"],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Verified Partner Assured",
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item["price"],
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Book",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
          ),
        );
      },
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How it works",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 20),
          _stepRow("1", "Details", "Choose service, date, and preferred time slot."),
          const SizedBox(height: 18),
          _stepRow("2", "Relax", "We send our certified expert to your doorstep."),
          const SizedBox(height: 18),
          _stepRow("3", "Enjoy", "Pay after service is completed to your satisfaction."),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            num,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommonQuestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Common Questions",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 12),
          _faqItem("Are partners background verified?", "Yes, 100% of our service professionals undergo thorough background checks, criminal record verification, and professional skill assessments before onboarding."),
          _faqItem("How do you select partners?", "We hold rigorous technical interviews, practical exams, and mock service test runs to filter and select only the top 10% of applicants."),
          _faqItem("What if something gets damaged?", "NEXORA provides structural insurance and guaranteed cover for any accidental damages caused during the service session."),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
          ),
        ),
        iconColor: AppTheme.primaryColor,
        collapsedIconColor: Colors.grey,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.grey[750],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReviews() {
    final reviews = DummyData.reviews;

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: reviews.length,
        itemBuilder: (context, index) => Container(
          width: 250,
          margin: const EdgeInsets.only(right: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    color: i < (reviews[index]['rating'] ?? 5) ? Colors.amber : Colors.grey[300],
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "\"${reviews[index]['comment']}\"",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                "- ${reviews[index]['userName']}",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhyChooseUs() {
    final features = [
      {"icon": Icons.verified_user, "text": "Verified Pro"},
      {"icon": Icons.access_time, "text": "Instant Booking"},
      {"icon": Icons.monetization_on, "text": "Fair Pricing"},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: features
            .map(
              (f) => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(f["icon"] as IconData, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    f["text"] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildReferAndEarn() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDC830), Color(0xFFF37335)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Refer & Earn",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Invite friends and get ₹500 wallet balance",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReferScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    "Share Now",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.people, size: 60, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: NetworkImage(
                "https://img.freepik.com/free-photo/portrait-man-smiling-camera_23-2148201201.jpg",
              ),
            ),
            accountName: Text(
              "Jakob",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              "jakob@example.com",
              style: GoogleFonts.outfit(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text("Booking History", style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.wallet),
            title: Text("Wallet", style: GoogleFonts.outfit()),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: GoogleFonts.outfit(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (title == "All Categories") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceListScreen(sectionTitle: title),
                    ),
                  );
                }
              },
              child: Text(
                action,
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTopCategoryMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Categories",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "All Services",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.8,
                      children: [
                        _topMenuCard(
                          context,
                          "Salon",
                          "assets/images/banner1.png",
                        ),
                        _topMenuCard(
                          context,
                          "Cleaning",
                          "assets/images/house_cleaning_demo_1774854111518.png",
                        ),
                        _topMenuCard(
                          context,
                          "Plumbing",
                          "assets/images/onboarding_2_home_cleaning_illustration_retry_1774853265369.png",
                        ),
                        _topMenuCard(
                          context,
                          "AC Repair",
                          "assets/images/kitchen_cleaning_demo_1774854091381.png",
                        ),
                        _topMenuCard(
                          context,
                          "Painting",
                          "assets/images/car_wash_banner_illustration_1774854072344.png",
                        ),
                        _topMenuCard(
                          context,
                          "Electrical",
                          "assets/images/onboarding_1_handyman_illustration_1774853199914.png",
                        ),
                        _topMenuCard(
                          context,
                          "Carpenter",
                          "assets/images/carpenter_icon_1774853442272.png",
                        ),
                        _topMenuCard(
                          context,
                          "Laundry",
                          "assets/images/laundry_icon_1774853512710.png",
                        ),
                        _topMenuCard(
                          context,
                          "Pest Control",
                          "assets/images/cleaner_icon_1774853550305.png",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutQuart)),
          child: child,
        );
      },
    );
  }

  Widget _topMenuCard(BuildContext context, String label, String img) {
    return GestureDetector(
      onTap: () {
        final nav = Navigator.of(context);
        nav.pop();
        nav.push(
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(categoryName: label),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: AssetImage(img),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStories() {
    final List<Map<String, dynamic>> stories = DummyData.getBySection("Service Stories").map((s) => {
        'title': s.title,
        'rating': s.rating.toString(),
        'videoUrl': null, // Fallback to asset
        'imageUrl': s.image,
    }).take(5).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceListScreen(sectionTitle: story['title']),
                    ),
                  );
                },
                child: _VideoStoryCard(
                  title: story['title'],
                  rating: story['rating'],
                  videoPath: story['videoUrl'] ?? "assets/videos/pinsnap-48765608461538391.mp4",
                  isNetwork: story['videoUrl'] != null,
                  imageUrl: story['imageUrl'],
                ),
              );
            },
          ),
        );
  }

  Widget _buildOffersCarousel() {
    final offers = [
      {
        "title": "Get 50% OFF",
        "subtitle": "On your first Salon booking today!",
        "color": 0xFF673AB7,
      },
      {
        "title": "Refer & Win",
        "subtitle": "Get ₹200 for every friend you refer",
        "color": 0xFFFF9800,
      },
      {
        "title": "Flash Sale",
        "subtitle": "Deep Cleaning starting at just ₹999",
        "color": 0xFFE91E63,
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return _offerCard(
                offer["title"] as String,
                offer["subtitle"] as String,
                Color(offer["color"] as int? ?? 0xFF673AB7),
              );
            },
          ),
        );
  }

  Widget _offerCard(String title, String subtitle, Color color) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoStoryCard extends StatelessWidget {
  final String title, rating, videoPath;
  final String? imageUrl;
  final bool isNetwork;
  
  const _VideoStoryCard({
    required this.title,
    required this.rating,
    required this.videoPath,
    this.imageUrl,
    this.isNetwork = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: imageUrl != null
                        ? (imageUrl!.startsWith('assets')
                            ? Image.asset(imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[800]))
                            : Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[800])))
                        : Container(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.accentColor,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
              const SizedBox(width: 4),
              Text(
                rating,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BannerData {
  final String title, subtitle, discount, image;
  final bool isNetwork;
  BannerData({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.image,
    this.isNetwork = false,
  });
}
