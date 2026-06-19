import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/cart_screen.dart';
import '../screens/all_reviews_screen.dart';
import '../models/service_model.dart';

class ShopDetailSheet extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ShopDetailSheet({super.key, required this.shop});

  @override
  State<ShopDetailSheet> createState() => _ShopDetailSheetState();

  static void show(BuildContext context, Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShopDetailSheet(shop: shop),
    );
  }
}

class _ShopDetailSheetState extends State<ShopDetailSheet> {
  int _currentGalleryIndex = 0;
  int _cartCount = 0;
  double _totalPrice = 0.0;

  void _addToCart(double price) {
    setState(() {
      _cartCount++;
      _totalPrice += price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 10),
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 15),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildGallery(),
                    _buildShopHeader(),
                    const Divider(height: 40, thickness: 1, color: Color(0xFFF5F5F5)),
                    _buildServicesSection(),
                    const SizedBox(height: 25),
                    _buildAboutSection(),
                    const SizedBox(height: 25),
                    _buildAddOns(),
                    const SizedBox(height: 25),
                    _buildOffersSection(),
                    const SizedBox(height: 25),
                    _buildReviewsSection(),
                    const SizedBox(height: 80), // Space for bottom bar
                  ],
                ),
              ),
              _buildBottomActionBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGallery() {
    final images = [widget.shop["img"], "assets/images/banner1.png", "assets/images/house_cleaning_demo_1774854111518.png"];
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            onPageChanged: (i) => setState(() => _currentGalleryIndex = i),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(images[index] as String, fit: BoxFit.cover),
                ),
              );
            },
          ),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) => Container(
                width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: _currentGalleryIndex == index ? Colors.white : Colors.white54, shape: BoxShape.circle),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.shop["name"]!, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Row(children: [const Icon(Icons.star, color: AppTheme.primaryColor, size: 14), const SizedBox(width: 4), Text(widget.shop["rating"]!, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))])),
              const SizedBox(width: 10),
              Text("${widget.shop["reviews"]} Ratings", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text("4517 Washington Ave. Manchester, Kentucky", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = [
      {"name": "Step Cut", "price": "₹499", "img": "assets/images/banner1.png", "options": "2 options"},
      {"name": "Face Spa", "price": "₹799", "img": "assets/images/house_cleaning_demo_1774854111518.png", "options": "3 options"},
      {"name": "Waxing", "price": "₹299", "img": "assets/images/kitchen_cleaning_demo_1774854091381.png", "options": "4 options"},
      {"name": "Thread", "price": "₹199", "img": "assets/images/car_wash_banner_illustration_1774854072344.png", "options": "1 option"},
      {"name": "Polish", "price": "₹599", "img": "assets/images/onboarding_3_convenient_service_illustration_1774853244833.png", "options": "2 options"},
      {"name": "Bridal", "price": "₹2499", "img": "assets/images/onboarding_1_handyman_illustration_1774853199914.png", "options": "5 options"},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Services Portfolio", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("View All", style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 25, // More space for labels below
              childAspectRatio: 0.65,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              return Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Square Image
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(s["img"]!, fit: BoxFit.cover),
                        ),
                      ),
                      // ADD Overlay Pill
                      Positioned(
                        bottom: -15,
                        child: InkWell(
                          onTap: () => _addToCart(double.parse(s["price"]!.replaceAll("₹", "").replaceAll(",", ""))),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 80,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            alignment: Alignment.center,
                            child: Text("ADD", style: GoogleFonts.outfit(color: const Color(0xFF673AB7), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(s["name"]!, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(s["options"]!, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("About the Shop", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            "Experience premium quality services with our certified professionals. We use high-end products and ensure 100% hygiene and customer satisfaction. All our experts are background-verified.",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection() {
    final offers = [
      {"title": "20% OFF", "desc": "All above ₹999", "color": Colors.orange[50]},
      {"title": "Free Tip", "desc": "On first booking", "color": Colors.blue[50]},
      {"title": "₹100 CB", "desc": "Using UrbanPay", "color": Colors.green[50]},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Shop Offers", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 20),
            itemCount: offers.length, itemBuilder: (context, index) => Container(
              width: 250, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: offers[index]["color"] as Color, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(offers[index]["title"] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)), Text(offers[index]["desc"] as String, style: const TextStyle(fontSize: 12, color: Colors.black54))]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddOns() {
    return Column(
      children: [
        _buildAddOnSection("Common Add-ons", "₹199"),
        const SizedBox(height: 25),
        _buildAddOnSection("Top Rated Add-ons", "₹249"),
        const SizedBox(height: 25),
        _buildAddOnSection("Quick Services", "₹99"),
      ],
    );
  }

  Widget _buildAddOnSection(String title, String price) {
    final addons = [
      {"name": "Quick Shine", "img": "assets/images/banner1.png", "options": "1 option", "price": price},
      {"name": "Mini Wash", "img": "assets/images/house_cleaning_demo_1774854111518.png", "options": "2 options", "price": price},
      {"name": "Polish", "img": "assets/images/kitchen_cleaning_demo_1774854091381.png", "options": "3 options", "price": price},
      {"name": "Care Kit", "img": "assets/images/car_wash_banner_illustration_1774854072344.png", "options": "1 option", "price": price},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold))),
        const SizedBox(height: 15),
        SizedBox(
          height: 205,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 20),
            itemCount: addons.length, itemBuilder: (context, index) {
              final a = addons[index];
              return Container(
                width: 105, margin: const EdgeInsets.only(right: 15),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(a["img"]!, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          bottom: -15,
                          child: InkWell(
                          onTap: () => _addToCart(double.parse(a["price"]!.replaceAll("₹", "").replaceAll(",", ""))),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 70, height: 30,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEEEEEE)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]),
                            alignment: Alignment.center,
                            child: Text("ADD", style: GoogleFonts.outfit(color: const Color(0xFF673AB7), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(a["name"]!, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(a["price"]!, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    Text(a["options"]!, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("User Reviews", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("15.3K Reviews", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          ... List.generate(4, (index) => Container(
            margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [const CircleAvatar(radius: 15, child: Icon(Icons.person, size: 18)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Client Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)), Row(children: List.generate(5, (_) => Icon(Icons.star, color: Colors.amber, size: 12)))])]),
                    const Text("Today", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 15),
                Text("\"Really satisfied with the work. The expert was on time and did a perfect job. Highly recommended for monthly maintenance.\"", style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87, height: 1.4)),
              ],
            ),
          )),
          const SizedBox(height: 10),
          Center(child: TextButton(onPressed: () {
            final mockService = ServiceModel(
              id: "mock-id",
              title: widget.shop["name"] ?? "Shop",
              category: "General",
              subCategory: "General",
              price: "0",
              discountPercent: 0,
              rating: double.tryParse(widget.shop["rating"]?.toString() ?? "0") ?? 0.0,
              totalReviews: int.tryParse(widget.shop["reviews"]?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? "0") ?? 0,
              vendorName: widget.shop["name"] ?? "Vendor",
              image: widget.shop["img"] ?? "",
              images: [],
              shortDescription: "",
              description: "",
              longDescription: "",
              duration: "",
              isAvailable: true,
              location: "",
              tags: [],
            );
            Navigator.push(context, MaterialPageRoute(builder: (context) => AllReviewsScreen(service: mockService)));
          }, child: Text("READ ALL REVIEWS", style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)))),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    if (_cartCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F5F5)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$_cartCount items added", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text("₹${_totalPrice.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(
                  shop: widget.shop,
                  cartCount: _cartCount,
                  totalPrice: _totalPrice,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text("VIEW CART", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
