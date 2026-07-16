import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../data/dummy_data.dart';
import 'service_detail_screen.dart';
import '../theme/app_theme.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}
class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedSubCatIndex = 0;
  final List<String> _subCats = ["All", "Top Rated", "Lowest Price", "Near Me", "Express", "Certified"];
  String _searchQuery = "";
  Future<List<ServiceModel>>? _servicesFuture;
  String _selectedSortBy = "Popularity";
  String _selectedPriceRange = "";

  @override
  void initState() {
    super.initState();
    _servicesFuture = _fetchVendorServices();
  }

  Future<List<ServiceModel>> _fetchVendorServices() async {
    List<ServiceModel> combinedServices = [];
    try {
      // 1. Fetch all global services for this category
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('categoryName', isEqualTo: widget.categoryName)
          .get();

      if (servicesSnapshot.docs.isEmpty) return DummyData.getByCategory(widget.categoryName);

      // 2. Fetch all approved vendors
      final vendorsSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('status', isEqualTo: 'APPROVED')
          .get();

      // 3. Cross-reference
      for (var vendorDoc in vendorsSnapshot.docs) {
        final vendorData = vendorDoc.data();
        final enabledServices = vendorData['enabledServices'] as List<dynamic>? ?? [];

        for (var serviceDoc in servicesSnapshot.docs) {
          if (enabledServices.contains(serviceDoc.id)) {
            final serviceData = serviceDoc.data();
            final fallbackImg = DummyData.allServices.first.image;
            
            combinedServices.add(
              ServiceModel(
                id: serviceDoc.id,
                title: (serviceData['title'] as String?) ?? '',
                category: (serviceData['categoryName'] as String?) ?? widget.categoryName,
                subCategory: 'Certified',
                price: serviceData['price'] != null ? '₹${serviceData['price']}' : '₹0',
                discountPercent: 0,
                rating: (vendorData['rating'] as num?)?.toDouble() ?? 4.5,
                totalReviews: (vendorData['reviewsCount'] as num?)?.toInt() ?? 0,
                vendorName: (vendorData['brandName'] as String?) ?? (vendorData['businessName'] as String?) ?? 'Vendor',
                image: (serviceData['imageUrl'] as String?) ?? fallbackImg,
                images: <String>[(serviceData['imageUrl'] as String?) ?? fallbackImg],
                shortDescription: (serviceData['description'] as String?) ?? '',
                description: (serviceData['description'] as String?) ?? '',
                longDescription: (serviceData['description'] as String?) ?? '',
                duration: (serviceData['duration'] as String?) ?? '1 hour',
                isAvailable: true,
                location: 'Local',
                tags: const [],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching vendor services: $e");
    }
    
    // Fallback to dummy data if DB fetch comes up totally empty
    if (combinedServices.isEmpty) {
      combinedServices = DummyData.getByCategory(widget.categoryName);
    }
    
    return combinedServices;
  }

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
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 20),
        itemCount: _subCats.length, itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubCatIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: index == _selectedSubCatIndex ? AppTheme.accentColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: index == _selectedSubCatIndex ? AppTheme.accentColor : Colors.grey[200]!),
            ),
            alignment: Alignment.center,
            child: Text(
              _subCats[index],
              style: GoogleFonts.outfit(color: index == _selectedSubCatIndex ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopList() {
    return FutureBuilder<List<ServiceModel>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<ServiceModel> services = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          services = services.where((s) => s.title.toLowerCase().contains(_searchQuery)).toList();
        }

        // 1. Apply Price Range Filter
        if (_selectedPriceRange == "₹0 - ₹500") {
          services = services.where((s) {
            final price = int.tryParse(s.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return price <= 500;
          }).toList();
        } else if (_selectedPriceRange == "₹500 - ₹2000") {
          services = services.where((s) {
            final price = int.tryParse(s.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return price >= 500 && price <= 2000;
          }).toList();
        } else if (_selectedPriceRange == "₹2000+") {
          services = services.where((s) {
            final price = int.tryParse(s.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return price >= 2000;
          }).toList();
        }

        // 2. Apply Sort By Filter from Sidebar
        if (_selectedSortBy == "Price Low to High") {
          services.sort((a, b) {
            final priceA = int.tryParse(a.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final priceB = int.tryParse(b.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return priceA.compareTo(priceB);
          });
        } else if (_selectedSortBy == "Price High to Low") {
          services.sort((a, b) {
            final priceA = int.tryParse(a.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final priceB = int.tryParse(b.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return priceB.compareTo(priceA);
          });
        } else if (_selectedSortBy == "Ratings") {
          services.sort((a, b) => b.rating.compareTo(a.rating));
        } else if (_selectedSortBy == "Popularity") {
          services.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
        }

        // 3. Apply Sub-category Pill Filter (All, Top Rated, Lowest Price, Near Me, Express, Certified)
        final subCat = _subCats[_selectedSubCatIndex];
        if (subCat == "Top Rated") {
          services.sort((a, b) => b.rating.compareTo(a.rating));
        } else if (subCat == "Lowest Price") {
          services.sort((a, b) {
            final priceA = int.tryParse(a.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final priceB = int.tryParse(b.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return priceA.compareTo(priceB);
          });
        } else if (subCat == "Certified") {
          services = services.where((s) => s.subCategory == "Certified").toList();
        } else if (subCat == "Express") {
          services = services.where((s) => s.duration.toLowerCase().contains("min") || s.duration.toLowerCase().contains("30") || s.duration.toLowerCase().contains("45")).toList();
        }

        Widget mainContent;
        if (services.isEmpty) {
          mainContent = Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No services found in ${widget.categoryName}",
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        } else {
          mainContent = ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                                if (service.tags.contains("Package"))
                                  Row(
                                    children: [
                                      const Icon(Icons.bookmark, color: Colors.teal, size: 14),
                                      const SizedBox(width: 4),
                                      Text("PACKAGE",
                                          style: GoogleFonts.outfit(
                                              color: Colors.teal,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0)),
                                    ],
                                  ),
                                const SizedBox(height: 5),
                                Text(service.title,
                                    style: GoogleFonts.outfit(
                                        fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFF1E2432), size: 14),
                                    const SizedBox(width: 4),
                                    Text("${service.rating} (${service.totalReviews} reviews)",
                                        style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(service.price,
                                        style: GoogleFonts.outfit(
                                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                    const SizedBox(width: 8),
                                    if (service.discountPercent > 0)
                                      Text("₹${(int.tryParse(service.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) + 200}",
                                          style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              decoration: TextDecoration.lineThrough)),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                const SizedBox(height: 15),
                                Text(
                                  service.description,
                                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceDetailScreen(service: service),
                                    ),
                                  ),
                                  child: Text("View details",
                                      style: GoogleFonts.outfit(
                                          color: const Color(0xFF673AB7),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          decoration: TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            children: [
                              Container(
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                    image: service.image.startsWith("assets")
                                        ? AssetImage(service.image) as ImageProvider
                                        : NetworkImage(service.image),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceDetailScreen(service: service),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on, size: 16, color: AppTheme.accentColor),
                                    const SizedBox(width: 5),
                                    Text("BOOK NOW",
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accentColor)),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.categoryName} Shops",
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                  ),
                  Text(
                    "${services.length} found",
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            mainContent,
          ],
        );
      },
    );
  }

  Widget _buildFilterSidebar() {
    String tempSortBy = _selectedSortBy;
    String tempPriceRange = _selectedPriceRange;

    return Drawer(
      width: 300,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setDrawerState) {
          return SafeArea(
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
                  _buildFilterSection(
                    "Sort By",
                    ["Popularity", "Price Low to High", "Price High to Low", "Ratings"],
                    tempSortBy,
                    (val) {
                      setDrawerState(() {
                        if (tempSortBy == val) {
                          tempSortBy = ""; // Toggle selection off
                        } else {
                          tempSortBy = val;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 25),
                  _buildFilterSection(
                    "Price Range",
                    ["₹0 - ₹500", "₹500 - ₹2000", "₹2000+"],
                    tempPriceRange,
                    (val) {
                      setDrawerState(() {
                        if (tempPriceRange == val) {
                          tempPriceRange = ""; // Toggle selection
                        } else {
                          tempPriceRange = val;
                        }
                      });
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filters to main state
                        setState(() {
                          _selectedSortBy = tempSortBy;
                          _selectedPriceRange = tempPriceRange;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text("APPLY FILTERS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String selectedValue, Function(String) onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 10,
          children: options.map((opt) {
            bool isSelected = selectedValue == opt;
            return GestureDetector(
              onTap: () => onTap(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppTheme.accentColor : Colors.grey[200]!),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
