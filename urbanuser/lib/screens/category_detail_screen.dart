import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_detail_sheet.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildFilterSidebar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilterHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubCategoryCarousel(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${widget.categoryName} Shops",
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                          ),
                          Text(
                            "24 found",
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildShopList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search for ${widget.categoryName}...",
                        hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Container(
              height: 50, width: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
              child: const Icon(Icons.tune, color: AppTheme.accentColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryCarousel() {
    final subCats = ["All", "Top Rated", "Lowest Price", "Near Me", "Express", "Certified"];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 20),
        itemCount: subCats.length, itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: index == 0 ? AppTheme.accentColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: index == 0 ? AppTheme.accentColor : Colors.grey[200]!),
          ),
          alignment: Alignment.center,
          child: Text(
            subCats[index],
            style: GoogleFonts.outfit(color: index == 0 ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildShopList() {
    final shops = [
      {
        "name": "Sparkle Beauty Studio",
        "rating": "4.83",
        "reviews": "153K",
        "price": "598",
        "oldPrice": "848",
        "time": "1 hr 5 mins",
        "services": ["Hair trim: Classic", "Styling: Blowdry / Out-curl"],
        "img": "assets/images/banner1.png",
        "isPackage": true
      },
      {
        "name": "Pro Handyman Hub",
        "rating": "4.66",
        "reviews": "721",
        "price": "1,199",
        "oldPrice": "1,499",
        "time": "2 hrs",
        "services": ["General Repair", "Electrical Checkup", "Furniture Fixing"],
        "img": "assets/images/onboarding_1_handyman_illustration_1774853199914.png",
        "isPackage": false
      },
      {
        "name": "Elite Car Detailers",
        "rating": "4.81",
        "reviews": "66K",
        "price": "1,548",
        "oldPrice": "1,748",
        "time": "1 hr 20 mins",
        "services": ["Full Interior Cleaning", "Exterior Waxing"],
        "img": "assets/images/car_wash_banner_illustration_1774854072344.png",
        "isPackage": true
      },
    ];
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      itemCount: shops.length, itemBuilder: (context, index) {
        final shop = shops[index];
        return GestureDetector(
          onTap: () => ShopDetailSheet.show(context, shop),
          child: Container(
            margin: const EdgeInsets.only(bottom: 25),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (shop["isPackage"] as bool)
                          Row(
                            children: [
                              const Icon(Icons.bookmark, color: Colors.teal, size: 14),
                              const SizedBox(width: 4),
                              Text("PACKAGE", style: GoogleFonts.outfit(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            ],
                          ),
                        const SizedBox(height: 5),
                        Text(shop["name"] as String, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFF1E2432), size: 14),
                            const SizedBox(width: 4),
                            Text("${shop["rating"]} (${shop["reviews"]} reviews)", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text("₹${shop["price"]}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            const SizedBox(width: 8),
                            Text("₹${shop["oldPrice"]}", style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            const Text("•", style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text(shop["time"] as String, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 15),
                        ... (shop["services"] as List<String>).map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 4, color: Colors.grey)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700]))),
                            ],
                          ),
                        )),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {},
                          child: Text("See all services", style: GoogleFonts.outfit(color: const Color(0xFF673AB7), fontWeight: FontWeight.bold, fontSize: 15, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    children: [
                      Container(
                        height: 110, width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(image: AssetImage(shop["img"] as String), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ShopDetailSheet.show(context, shop),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEEEEEE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, size: 16, color: AppTheme.accentColor),
                            const SizedBox(width: 5),
                            Text("VIEW SHOP", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Divider(height: 1, color: Color(0xFFF5F5F5), thickness: 1),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildFilterSidebar() {
    return Drawer(
      width: 300,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Filters", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 30),
              _buildFilterSection("Sort By", ["Popularity", "Price Low to High", "Price High to Low", "Ratings"]),
              const SizedBox(height: 25),
              _buildFilterSection("Price Range", ["₹0 - ₹500", "₹500 - ₹2000", "₹2000+"]),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text("APPLY FILTERS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 10,
          children: options.map((opt) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
            child: Text(opt, style: GoogleFonts.outfit(fontSize: 12, color: Colors.black87)),
          )).toList(),
        ),
      ],
    );
  }
}
