import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urbanuser/widgets/custom_bottom_nav.dart';
import 'category_detail_screen.dart';
import '../theme/app_theme.dart';
import 'categories_screen.dart';
import 'package:video_player/video_player.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

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
          physics: const BouncingScrollPhysics(),
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
          Column(
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
                children: [
                  Text(
                    "4517 Washington Ave",
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
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
          const Spacer(),
          CircleAvatar(
            backgroundColor: AppTheme.lightGray,
            child: const Icon(Icons.search, color: Colors.black, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (index) => setState(() => _currentBannerIndex = index),
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              image: DecorationImage(
                image: AssetImage(banner.image),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
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
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      "BOOK NOW",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

  // --- CAROUSEL 1: Best In Your City ---
  Widget _buildServiceCarousel() {
    final services = [
      {
        "name": "Luxury Sofa Spa",
        "price": "\$120",
        "rating": "4.9",
        "img": "assets/images/banner1.png",
      },
      {
        "name": "Full Home Paint",
        "price": "\$999",
        "rating": "4.8",
        "img":
            "assets/images/onboarding_1_handyman_illustration_1774853199914.png",
      },
      {
        "name": "Express Car Wash",
        "price": "\$45",
        "rating": "4.9",
        "img": "assets/images/car_wash_banner_illustration_1774854072344.png",
      },
    ];
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: services.length,
        itemBuilder: (context, index) => Container(
          width: 220,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.asset(
                  services[index]["img"]!,
                  height: 120,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      services[index]["name"]!,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          services[index]["price"]!,
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(
                              services[index]["rating"]!,
                              style: const TextStyle(fontSize: 12),
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
      ),
    );
  }

  // --- CAROUSEL 2: Top Vendors ---
  Widget _buildVendorCarousel() {
    final vendors = [
      {
        "name": "Apex Cleaners",
        "rating": "4.9",
        "tasks": "1.2k Tasks",
        "image": "assets/images/vendors/vendor_1.jpg",
      },
      {
        "name": "Elite Repairs",
        "rating": "4.8",
        "tasks": "850 Tasks",
        "image": "assets/images/vendors/vendor_2.jpg",
      },
      {
        "name": "Swift Mechanic",
        "rating": "4.9",
        "tasks": "2k Tasks",
        "image": "assets/images/vendors/vendor_3.jpg",
      },
      {
        "name": "Alpha Painters",
        "rating": "4.7",
        "tasks": "1.5k Tasks",
        "image": "assets/images/vendors/vendor_4.jpg",
      },
      {
        "name": "Rapid Plumbers",
        "rating": "4.9",
        "tasks": "1.1k Tasks",
        "image": "assets/images/vendors/vendor_1.jpg",
      },
    ];
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: vendors.length,
        itemBuilder: (context, index) => Container(
          width: 150,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(vendors[index]["image"] as String),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendors[index]["name"] as String,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  vendors[index]["tasks"] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CAROUSEL 3: New & Noteworthy ---
  Widget _buildNewServicesCarousel() {
    final news = [
      {
        "name": "Gutter Cleaning",
        "img": "assets/images/promotions/new_noteworthy_1.jpg",
      },
      {
        "name": "Garden Grooming",
        "img": "assets/images/promotions/new_noteworthy_2.jpg",
      },
      {
        "name": "Pet Sanitization",
        "img": "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?q=80&w=720&auto=format&fit=crop",
      },
    ];
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: news.length,
        itemBuilder: (context, index) => Container(
          width: 250,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            image: DecorationImage(
              image: news[index]["img"]!.startsWith("assets") 
                ? AssetImage(news[index]["img"]!) as ImageProvider
                : NetworkImage(news[index]["img"]!),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  news[index]["name"]!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {"name": "InstaHelp", "image": "assets/images/categories/insta_help.png"},
      {
        "name": "Women's Salon",
        "image": "assets/images/categories/womens_salon.png",
      },
      {
        "name": "Men's Salon",
        "image": "assets/images/categories/mens_salon.png",
      },
      {"name": "Cleaning", "image": "assets/images/categories/cleaning.png"},
      {"name": "AC Repair", "image": "assets/images/categories/ac_repair.png"},
      {
        "name": "Water Purifier",
        "image": "assets/images/categories/water_purifier.png",
      },
      {"name": "Electrician", "image": "assets/images/categories/handyman.png"},
      {"name": "Painting", "image": "assets/images/categories/painting.png"},
      {"name": "Carpenter", "image": "assets/images/categories/carpenter.png"},
      {
        "name": "Pest Control",
        "image": "assets/images/categories/pest_control.png",
      },
    ];
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 18,
        mainAxisSpacing: 25,
        childAspectRatio: 0.76,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CategoryDetailScreen(categoryName: categories[index]["name"]!),
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[100]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  categories[index]["image"]!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              categories[index]["name"]!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialOffers() {
    final offers = [
      {
        "title": "Free Inspection",
        "desc": "Premium Home Checkup",
        "img": "assets/images/promotions/special_offer_1.jpg",
      },
      {
        "title": "Coupon Applied",
        "desc": "Flat ₹200 Cashback",
        "img": "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?q=80&w=720&auto=format&fit=crop",
      },
      {
        "title": "Weekend Deal",
        "desc": "Extra 15% Savings",
        "img": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=720&auto=format&fit=crop",
      },
    ];
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: offers.length,
        itemBuilder: (context, index) => Container(
          width: 310,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(
              image: offers[index]["img"]!.startsWith("assets")
                ? AssetImage(offers[index]["img"]!) as ImageProvider
                : NetworkImage(offers[index]["img"]!),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  offers[index]["title"]!,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  offers[index]["desc"]!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: StadiumBorder(),
                    elevation: 0,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildTrendingCard(
              "Sofa Cleaning",
              "https://images.unsplash.com/photo-1563298723-dcfebaa392e3?q=80&w=720&auto=format&fit=crop",
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildTrendingCard(
              "Deep Repair",
              "assets/images/promotions/deep_repair.jpg",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(String name, String img) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: DecorationImage(
          image: img.startsWith("assets") 
            ? AssetImage(img) as ImageProvider
            : NetworkImage(img),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedList() {
    final recs = [
      {
        "name": "Kitchen Cleaning",
        "image": "assets/images/kitchen_cleaning_demo_1774854091381.png",
      },
      {
        "name": "House Cleaning",
        "image": "assets/images/house_cleaning_demo_1774854111518.png",
      },
    ];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recs.length,
      itemBuilder: (context, index) => Container(
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
              child: Image.asset(
                recs[index]["image"]!,
                width: 85,
                height: 85,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recs[index]["name"]!,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$150",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
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
                      "20% Off",
                      style: GoogleFonts.outfit(
                        color: Colors.red[400],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerReviews() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 250,
          margin: const EdgeInsets.only(right: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[100]!),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (_) => Icon(Icons.star, color: Colors.amber, size: 16),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "\"Excellent service and very professional handyman. Saved me a lot of time!\"",
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
                "- User ${index + 1}",
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
                  "Invite friends and get \$50 wallet balance",
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {},
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
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.wallet),
            title: Text("Wallet", style: GoogleFonts.outfit()),
            onTap: () {},
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: GoogleFonts.outfit(color: Colors.red)),
            onTap: () {},
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              ),
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
        Navigator.pop(context);
        Navigator.push(
          context,
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
    final stories = [
      {
        "name": "Expert Glass Washing",
        "rating": "4.9",
        "video": "assets/videos/pinsnap-48765608461538391.mp4",
      },
      {
        "name": "Premium Deep Clean",
        "rating": "4.8",
        "video": "assets/videos/pinsnap-34480753393968040.mp4",
      },
      {
        "name": "Professional Service",
        "rating": "4.7",
        "video": "assets/videos/pinsnap-170925748355218436-story1.mp4",
      },
    ];
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: stories.length,
        itemBuilder: (context, index) => _VideoStoryCard(
          title: stories[index]["name"]!,
          rating: stories[index]["rating"]!,
          videoPath: stories[index]["video"]!,
        ),
      ),
    );
  }

  Widget _buildOffersCarousel() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        children: [
          _offerCard(
            "Get 50% OFF",
            "On your first Salon booking today!",
            const Color(0xFF673AB7),
          ),
          _offerCard(
            "Refer & Win",
            "Get ₹200 for every friend you refer",
            const Color(0xFFFF9800),
          ),
          _offerCard(
            "Flash Sale",
            "Deep Cleaning starting at just ₹999",
            const Color(0xFFE91E63),
          ),
        ],
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

class _VideoStoryCard extends StatefulWidget {
  final String title, rating, videoPath;
  const _VideoStoryCard({
    required this.title,
    required this.rating,
    required this.videoPath,
  });

  @override
  State<_VideoStoryCard> createState() => _VideoStoryCardState();
}

class _VideoStoryCardState extends State<_VideoStoryCard> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {});
        _controller.setVolume(0);
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _controller.value.isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
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
                widget.rating,
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
  BannerData({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.image,
  });
}
