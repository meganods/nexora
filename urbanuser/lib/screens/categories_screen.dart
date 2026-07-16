import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_detail_screen.dart';
import 'service_detail_screen.dart';
import '../theme/app_theme.dart';
import '../data/dummy_data.dart';
import '../widgets/custom_bottom_nav.dart';

class CategoriesScreen extends StatefulWidget {
  final bool autoFocusSearch;
  const CategoriesScreen({super.key, this.autoFocusSearch = false});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final categories = DummyData.allCategories;
    
    // Get all services matching the query
    final allServices = DummyData.allServices;
    final searchResults = _searchQuery.isEmpty 
        ? [] 
        : allServices.where((s) => 
            s.title.toLowerCase().contains(_searchQuery) ||
            s.subCategory.toLowerCase().contains(_searchQuery)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Custom Beautiful AppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.accentColor, size: 20),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _searchQuery.isEmpty ? "All Categories" : "Search Results",
                style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              centerTitle: true,
            ),
          ),

          // Search Bar Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 55,
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        autofocus: widget.autoFocusSearch,
                        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Search for services...",
                          hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() => _searchQuery = "");
                          FocusScope.of(context).unfocus();
                        },
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (_searchQuery.isEmpty)
            // Categories Grid
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 25,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = categories[index];
                    final String imageUrl = item.imagePath;
                    final String title = item.title;

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryDetailScreen(categoryName: title))),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Image.asset(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.category_outlined, size: 40, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
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
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            )
          else if (searchResults.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("No services found for '$_searchQuery'", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            )
          else
            // Search Results List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        service.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60, height: 60, color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    title: Text(service.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                    subtitle: Text("${service.subCategory} • ${service.price}", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailScreen(service: service))),
                  );
                },
                childCount: searchResults.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }
}
