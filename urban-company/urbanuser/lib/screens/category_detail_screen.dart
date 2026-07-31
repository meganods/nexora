import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../data/dummy_data.dart';
import 'service_detail_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/app_snackbar.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  String _searchQuery = "";
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _fetchCategoryId();
  }

  Future<void> _fetchCategoryId() async {
    final snap = await FirebaseFirestore.instance
        .collection('categories')
        .where('categoryName', isEqualTo: widget.categoryName)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      if (mounted) {
        setState(() => _categoryId = snap.docs.first.id);
      }
    }
  }
  String _selectedSubCat = "All";
  String _sortBy = "All";
  bool _isWishlistOnly = false;
  final Set<String> _wishlistedIds = {};

  final List<String> _filterChips = [
    "All",
    "Popular",
    "Emergency",
    "Installation",
    "Repair",
    "Maintenance",
    "Leakage",
    "Bathroom",
    "Kitchen",
  ];

  // Specific high-quality services for Plumbing Category (Stitch list)
  final List<Map<String, dynamic>> _plumbingServices = [
    {
      "id": "pl-1",
      "title": "Leakage Repair",
      "startingPrice": "₹199",
      "duration": "45 mins",
      "rating": "4.9",
      "jobs": "12K Jobs",
      "desc": "Detect and fix leaks in pipelines, joints, basin wastes, toilets, and concealed wall pipes.",
      "image": "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400",
      "tag": "Leakage",
    },
    {
      "id": "pl-2",
      "title": "Tap & Faucet Installation",
      "startingPrice": "₹249",
      "duration": "30 mins",
      "rating": "4.8",
      "jobs": "9K Jobs",
      "desc": "Installation or replacement of bathroom taps, kitchen mixers, and shower nozzles.",
      "image": "https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=400",
      "tag": "Installation",
    },
    {
      "id": "pl-3",
      "title": "Bathroom Plumbing",
      "startingPrice": "₹399",
      "duration": "60 mins",
      "rating": "4.9",
      "jobs": "8K Jobs",
      "desc": "Full checking and repair of commode, toilet flush, shower controls, and drain traps.",
      "image": "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400",
      "tag": "Bathroom",
    },
    {
      "id": "pl-4",
      "title": "Kitchen Sink Repair",
      "startingPrice": "₹299",
      "duration": "45 mins",
      "rating": "4.8",
      "jobs": "10K Jobs",
      "desc": "Clogged sinks waste pipe clearance, coupling replacement, and dishwater connection setups.",
      "image": "https://images.unsplash.com/photo-1556912173-3bb406ef7e77?w=400",
      "tag": "Kitchen",
    },
    {
      "id": "pl-5",
      "title": "Drain Blockage Removal",
      "startingPrice": "₹349",
      "duration": "60 mins",
      "rating": "4.9",
      "jobs": "15K Jobs",
      "desc": "High pressure mechanical spring clearance for choked bathroom drains and floor traps.",
      "image": "https://images.unsplash.com/photo-1605718667512-4ebdfef76f5c?w=400",
      "tag": "Repair",
    },
    {
      "id": "pl-6",
      "title": "Water Tank Pipe Repair",
      "startingPrice": "₹499",
      "duration": "90 mins",
      "rating": "4.9",
      "jobs": "5K Jobs",
      "desc": "Repairs for overhead tank pipelines, ball valve setups, and pressure regulator checkup.",
      "image": "https://images.unsplash.com/photo-1542013936693-8848e5740a9a?w=400",
      "tag": "Maintenance",
    },
    {
      "id": "pl-7",
      "title": "Motor Installation",
      "startingPrice": "₹799",
      "duration": "120 mins",
      "rating": "4.8",
      "jobs": "3K Jobs",
      "desc": "Fixing or installing booster pump systems, automatic water level controller systems.",
      "image": "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400",
      "tag": "Installation",
    },
    {
      "id": "pl-8",
      "title": "Complete Plumbing Inspection",
      "startingPrice": "₹599",
      "duration": "90 mins",
      "rating": "4.9",
      "jobs": "4K Jobs",
      "desc": "Whole house inspection to diagnose water pressure issues, hidden wall leaks, and tap health.",
      "image": "https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400",
      "tag": "Maintenance",
    },
  ];

  // Dummy categories fallback mapper (if categoryName is not Plumbing)
  List<Map<String, dynamic>> _getCategoryServices() {
    if (widget.categoryName.toLowerCase().contains("plumb")) {
      return _plumbingServices;
    }
    // Dynamic fallbacks matching other categories using DummyData list
    final dummyServices = DummyData.getByCategory(widget.categoryName);
    return dummyServices.map((s) => {
      "id": s.id,
      "title": s.title,
      "startingPrice": s.price,
      "duration": s.duration,
      "rating": s.rating.toString(),
      "jobs": "${s.totalReviews * 4} Jobs",
      "desc": s.shortDescription,
      "image": s.image,
      "tag": "Popular",
    }).toList();
  }

  // Why choose NEXORA
  final List<Map<String, dynamic>> _whyChooseUs = [
    {"title": "Verified Pros", "desc": "Background Checked", "icon": Icons.verified_user_rounded},
    {"title": "30-Day Warranty", "desc": "Free Re-work cover", "icon": Icons.security_rounded},
    {"title": "Transparent Pricing", "desc": "No hidden fees", "icon": Icons.payments_rounded},
    {"title": "Instant Support", "desc": "Resolves in 2 hours", "icon": Icons.support_agent_rounded},
  ];

  // Customer Reviews
  final List<Map<String, dynamic>> _reviews = [
    {"name": "Amit R.", "rating": 5, "comment": "The plumber was highly skilled. Fixed the bathroom sink leak in 20 minutes cleanly.", "date": "Yesterday"},
    {"name": "Priyanka S.", "rating": 5, "comment": "Great experience. On-time delivery and clean setup. Very transparent pricing.", "date": "3 days ago"},
    {"name": "Rohan D.", "rating": 4, "comment": "Satisfied with motor install. The controller operates smoothly.", "date": "1 week ago"},
  ];

  void _navigateToDetails(Map<String, dynamic> s) {
    // Map to ServiceModel format
    final service = ServiceModel(
      id: s["id"] ?? "pl-1",
      title: s["title"] ?? "",
      category: widget.categoryName,
      subCategory: s["tag"] ?? "Popular",
      price: s["startingPrice"] ?? "₹199",
      discountPercent: 0,
      rating: double.tryParse(s["rating"] ?? "4.8") ?? 4.8,
      totalReviews: 120,
      vendorName: "NEXORA Certified Plumber",
      image: s["image"] ?? "",
      images: [s["image"] ?? ""],
      shortDescription: s["desc"] ?? "",
      description: s["desc"] ?? "",
      longDescription: s["desc"] ?? "",
      duration: s["duration"] ?? "45 mins",
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

  @override
  Widget build(BuildContext context) {
    final rawServicesList = _getCategoryServices();
    
    // Live filter search query + tags
    var filteredList = rawServicesList.where((s) {
      final nameMatch = s["title"].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatch = s["desc"].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final bool tagMatch = _selectedSubCat == "All" ||
          s["tag"].toString().toLowerCase() == _selectedSubCat.toLowerCase() ||
          (_selectedSubCat == "Popular" && double.tryParse(s["rating"].toString())! >= 4.9);

      final bool wishlistMatch = !_isWishlistOnly || _wishlistedIds.contains(s["id"]);

      return (nameMatch || descMatch) && tagMatch && wishlistMatch;
    }).toList();

    // Sort order
    if (_sortBy == "Price Low to High") {
      filteredList.sort((a, b) {
        final valA = int.tryParse(a["startingPrice"].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final valB = int.tryParse(b["startingPrice"].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return valA.compareTo(valB);
      });
    } else if (_sortBy == "Price High to Low") {
      filteredList.sort((a, b) {
        final valA = int.tryParse(a["startingPrice"].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final valB = int.tryParse(b["startingPrice"].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return valB.compareTo(valA);
      });
    } else if (_sortBy == "Highest Rated") {
      filteredList.sort((a, b) => b["rating"].toString().compareTo(a["rating"].toString()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.categoryName} Services",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── STICKY HERO BANNER (FIRST) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                  image: const DecorationImage(
                    image: NetworkImage("https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=800"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.2)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Verified Experts",
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Professional ${widget.categoryName} Services",
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Starting ₹199 • 100% Satisfaction Guarantee",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => AppSnackbar.show(context, "Explore lowest rates below!"),
                        child: Text("Book Today", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── SEARCH BAR (SECOND - REMOVED MIC ICON) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search ${widget.categoryName.toLowerCase()} services...",
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() {
                          _searchController.clear();
                          _searchQuery = "";
                        }),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                      ),
                  ],
                ),
              ),
            ),

            // ─── QUICK FILTER CHIPS (THIRD) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _filterChips.map((chip) {
                    final bool isSelected = _selectedSubCat == chip;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSubCat = chip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            chip,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ─── SORT OPTION DROPDOWN ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Available Services", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                  DropdownButton<String>(
                    value: _sortBy,
                    elevation: 1,
                    underline: Container(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                    items: [
                      "All",
                      "Most Popular",
                      "Price Low to High",
                      "Price High to Low",
                      "Highest Rated",
                    ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  ),
                ],
              ),
            ),

            // ─── SERVICES LIST ───────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .where('categoryId', isEqualTo: _categoryId)
                  .where('status', isEqualTo: 'Approved')
                  .snapshots(),
              builder: (context, snapshot) {
                final List<Map<String, dynamic>> liveServices = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    liveServices.add({
                      "id": doc.id,
                      "title": data["serviceName"] ?? "",
                      "startingPrice": "₹399",
                      "duration": "45 Mins",
                      "rating": "4.9",
                      "jobs": "New",
                      "desc": data["shortDescription"] ?? data["description"] ?? "",
                      "image": data["coverImage"] ?? "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400",
                      "tag": "Popular",
                    });
                  }
                }

                final finalServices = liveServices.isNotEmpty ? liveServices : filteredList;

                if (finalServices.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: finalServices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, idx) {
                    final s = finalServices[idx];
                    final bool isWishlisted = _wishlistedIds.contains(s["id"]);
                    return _buildServiceCard(s, isWishlisted);
                  },
                );
              },
            ),
            if (filteredList.isEmpty)
              // Empty State
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 16),
                      Text("No Plumbing Services Found", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 6),
                      Text("Try clearing filters to search again.", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = "";
                            _selectedSubCat = "All";
                            _isWishlistOnly = false;
                          });
                        },
                        child: Text("Browse Categories", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── EMERGENCY SERVICE CARD ──────────────────────────────────
            if (widget.categoryName.toLowerCase().contains("plumb"))
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.campaign_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🚨 Emergency Plumbing", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text("Available within 30 Minutes • 24x7 Support", style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.95))),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => AppSnackbar.show(context, "Connecting with nearest emergency plumber..."),
                              child: Text("Book Emergency Service", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ─── WHY CHOOSE US SECTION ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text("Why Choose NEXORA", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
            ),
            SizedBox(
              height: 110,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _whyChooseUs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final item = _whyChooseUs[idx];
                  return Container(
                    width: 170,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(item["icon"] as IconData, color: const Color(0xFF2563EB), size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item["title"] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                              const SizedBox(height: 2),
                              Text(item["desc"] as String, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ─── CUSTOMER REVIEWS ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text("Customer Reviews", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final r = _reviews[idx];
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r["name"], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                          Text(r["date"], style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: i < (r["rating"] as int) ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r["comment"],
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),

    );
  }

  Widget _buildServiceCard(Map<String, dynamic> s, bool isWishlisted) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: s["image"].toString().startsWith("assets/")
                    ? Image.asset(
                        s["image"],
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        s["image"],
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/images/categories/plumber.png",
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Verified Expert",
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isWishlisted) {
                        _wishlistedIds.remove(s["id"]);
                      } else {
                        _wishlistedIds.add(s["id"]);
                      }
                    });
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: isWishlisted ? Colors.red : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      "${s['rating']}  •  ${s['jobs']}",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      s["duration"],
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s["title"],
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  s["desc"],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Starting from",
                          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8)),
                        ),
                        Text(
                          s["startingPrice"],
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => _navigateToDetails(s),
                      child: Text(
                        "Book Now",
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
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
  }
}
