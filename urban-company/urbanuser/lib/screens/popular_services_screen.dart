import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';

class PopularServicesScreen extends StatefulWidget {
  const PopularServicesScreen({super.key});

  @override
  State<PopularServicesScreen> createState() => _PopularServicesScreenState();
}

class _PopularServicesScreenState extends State<PopularServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Most Popular';
  String _selectedCategory = 'All';
  double _priceLimit = 5000.0;

  final List<String> _sortOptions = [
    'Most Popular',
    'Highest Rated',
    'Lowest Price',
    'Highest Price',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Services',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Sort By Section
                  Text(
                    'SORT BY',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((opt) {
                      final isSel = _selectedSort == opt;
                      return ChoiceChip(
                        label: Text(
                          opt,
                          style: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _selectedSort = opt);
                            setState(() => _selectedSort = opt);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Max Price Limit Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MAX PRICE',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      Text(
                        '₹${_priceLimit.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _priceLimit,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      setModalState(() => _priceLimit = val);
                      setState(() => _priceLimit = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Actions Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedSort = 'Most Popular';
                              _priceLimit = 5000.0;
                              _selectedCategory = 'All';
                            });
                            setState(() {
                              _selectedSort = 'Most Popular';
                              _priceLimit = 5000.0;
                              _selectedCategory = 'All';
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Reset', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Text('Apply Filters', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const borderGray = Color(0xFFE2E8F0);
    const textDark = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);

    final List<ServiceModel> fallbackServices = [
      ServiceModel(
        id: 'p1',
        title: 'Deep Home Cleaning',
        price: 1899,
        rating: 4.8,
        totalReviews: 842,
        duration: '2-3 Hours',
        image: 'assets/hero section img/image.png',
        category: 'Cleaning',
      ),
      ServiceModel(
        id: 'p2',
        title: 'Premium Appliance Repair',
        price: 399,
        rating: 4.9,
        totalReviews: 531,
        duration: '1-1.5 Hours',
        image: 'assets/hero section img/image copy.png',
        category: 'Appliance',
      )
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Popular Services',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: textDark),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Search Field Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: textGray, size: 22),
                hintText: 'Search services...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: borderGray),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: textGray),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Main List Builder Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .where('status', isEqualTo: 'Approved')
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                
                // Construct models from database or fall back to assets
                List<ServiceModel> services = docs.isEmpty
                    ? fallbackServices
                    : docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return ServiceModel(
                          id: doc.id,
                          title: d['name'] ?? d['serviceName'] ?? 'Service Item',
                          price: ((d['startingPrice'] ?? d['price'] ?? 0) as num).toDouble(),
                          rating: ((d['rating'] ?? 5.0) as num).toDouble(),
                          totalReviews: d['reviewsCount'] ?? d['totalReviews'] ?? 0,
                          duration: d['duration'] ?? '1 Hour',
                          image: d['coverImage'] ?? d['image'] ?? '',
                          category: d['category'] ?? '',
                        );
                      }).toList();

                // Apply Search query filter
                if (_searchQuery.isNotEmpty) {
                  services = services.where((s) => s.title.toLowerCase().contains(_searchQuery) || s.category.toLowerCase().contains(_searchQuery)).toList();
                }

                // Apply Price limit filter
                services = services.where((s) => s.price <= _priceLimit).toList();

                // Apply Sorting rules
                if (_selectedSort == 'Lowest Price') {
                  services.sort((a, b) => a.price.compareTo(b.price));
                } else if (_selectedSort == 'Highest Price') {
                  services.sort((a, b) => b.price.compareTo(a.price));
                } else if (_selectedSort == 'Highest Rated') {
                  services.sort((a, b) => b.rating.compareTo(a.rating));
                }

                if (services.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 64, color: textGray),
                          const SizedBox(height: 16),
                          Text(
                            'No Popular Services Found',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please adjust your filter parameters or search queries and try again.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: textGray),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: services.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) {
                    final s = services[idx];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceDetailScreen(service: s),
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
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cover Image with rating
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                                  child: s.image.startsWith('http')
                                      ? Image.network(s.image, height: 160, width: double.infinity, fit: BoxFit.cover)
                                      : Image.asset(s.image, height: 160, width: double.infinity, fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Container(
                                            height: 160,
                                            color: primaryBlue.withValues(alpha: 0.1),
                                            child: const Icon(Icons.handyman_rounded, color: primaryBlue, size: 48),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${s.rating}',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Name & Pricing Footer
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.category.toUpperCase(),
                                          style: GoogleFonts.inter(fontSize: 10, color: primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          s.title,
                                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${s.duration} • Starting from ₹${s.price.toStringAsFixed(0)}',
                                          style: GoogleFonts.inter(fontSize: 12, color: textGray, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ServiceDetailScreen(service: s),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    child: const Text('Book Now'),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
