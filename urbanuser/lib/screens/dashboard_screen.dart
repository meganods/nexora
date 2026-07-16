import 'package:flutter/material.dart';
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
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  String _userAddress = "4517 Washington Ave";

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('userAddress');
    if (savedAddress != null && savedAddress.trim().isNotEmpty) {
      setState(() {
        _userAddress = savedAddress.replaceAll(RegExp(r'^,\s*'), '').trim();
      });
    }
  }

  final List<BannerData> _banners = [
    BannerData(
      title: "Best Professional\nHome Cleaning",
      subtitle: "Kitchen & House",
      discount: "40% OFF",
      image: "assets/images/banner1.png",
    ),
    BannerData(
      title: "Expert Repair\n& Maintenance",
      subtitle: "Plumbing & Electrical",
      discount: "20% OFF",
      image:
          "assets/images/onboarding_2_home_cleaning_illustration_retry_1774853265369.png",
    ),
    BannerData(
      title: "Deep Car Wash\n& Detailing",
      subtitle: "Auto Care",
      discount: "30% OFF",
      image: "assets/images/car_wash_banner_illustration_1774854072344.png",
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
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBannerCarousel(),
              _buildPageIndicator(),
              _buildSectionHeader("All Categories", "See All"),
              _buildCategoryGrid(),
              const SizedBox(height: 32),

              // NEW SECTION 1: Best In Your City (Carousel)
              _buildSectionHeader("Best In Your City", "Explore"),
              _buildServiceCarousel(),

              const SizedBox(height: 24),
              _buildSectionHeader("Service Stories", ""),
              _buildVideoStories(),

              // NEW SECTION 2: Top Vendors (Carousel)
              const SizedBox(height: 24),
              _buildSectionHeader("Top Rated Vendors", "View All"),
              _buildVendorCarousel(),

              // NEW SECTION 3: New & Noteworthy (Carousel)
              const SizedBox(height: 24),
              _buildSectionHeader("New & Noteworthy", ""),
              _buildNewServicesCarousel(),

              const SizedBox(height: 32),
              _buildSectionHeader("Special Offers", ""),
              _buildSpecialOffers(),

              const SizedBox(height: 32),
              _buildSectionHeader("Trending Services", ""),
              _buildTrendingServices(),

              const SizedBox(height: 32),
              _buildSectionHeader("Recommended", ""),
              _buildRecommendedList(),

              _buildSectionHeader("What Users Say", ""),
              _buildCustomerReviews(),

              _buildWhyChooseUs(),

              const SizedBox(height: 32),
              _buildSectionHeader("Exclusive Offers For You", ""),
              _buildOffersCarousel(),

              _buildReferAndEarn(),

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
          const Spacer(),
          Expanded(
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
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
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
          const Spacer(),
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
    final displayBanners = _banners;

    return SizedBox(
      height: 240,
      child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemCount: displayBanners.length,
            itemBuilder: (context, index) {
              final banner = displayBanners[index];
              return GestureDetector(
                onTap: () {
                  String cat = "Cleaning";
                  if (banner.subtitle.contains("Plumbing")) cat = "Plumbing";
                  if (banner.subtitle.contains("Auto Care")) cat = "Car Wash";
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryDetailScreen(categoryName: cat)));
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    image: banner.isNetwork
                        ? null
                        : DecorationImage(
                            image: AssetImage(banner.image),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: Stack(
                    children: [
                      if (banner.isNetwork)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.network(
                              banner.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner.discount,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              banner.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
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
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _banners.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: _currentBannerIndex == index
                ? AppTheme.accentColor
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
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
    final news = DummyData.newServices;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: news.length,
        itemBuilder: (context, index) {
          final service = news[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(categoryName: service['title']),
                ),
              );
            },
            child: Container(
              width: 260,
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(service['color']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.new_releases, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      service['title'],
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildCategoryGrid() {
    final categories = DummyData.homeCategories;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 15,
        childAspectRatio: 0.7,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final item = categories[index];
        final String name = item.title;
        final String imageUrl = item.imagePath;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(categoryName: name),
            ),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.category_outlined, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
    final offers = DummyData.specialOffers;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Color(offer["color"]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.local_offer,
                    size: 100,
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      offer["title"],
                      style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      offer["subtitle"],
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          RewardsData.claimedCoupons.add({
                            "id": DateTime.now().toString(),
                            "code": offer["title"].toString().toUpperCase().replaceAll(' ', ''),
                            "title": offer["title"],
                            "description": offer["subtitle"],
                            "expiry": "Expires soon",
                            "color": Color(offer["color"]),
                            "icon": Icons.local_offer,
                            "discountPercent": 10.0,
                            "discountAmount": null,
                          });
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Offer Claimed Successfully! Check your rewards."),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A), // Dark blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        "Claim Now",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingServices() {
    final trending = DummyData.trendingServices;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: trending.map((item) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailScreen(categoryName: item['title']),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(right: item == trending.last ? 0 : 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(item['color']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'], color: AppTheme.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['title'],
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendedList() {
    final recs = DummyData.getBySection("Recommended");

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recs.length,
      itemBuilder: (context, index) {
        final service = recs[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailScreen(service: service),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    service.image,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 85,
                      height: 85,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.price,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700], // Updated price color
                        ),
                      ),
                      if (service.discountPercent > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${service.discountPercent}% Off",
                            style: GoogleFonts.outfit(
                              color: Colors.red[400],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
    }).toList();

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
