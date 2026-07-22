import 'package:urbanuser/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/dummy_data.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';
import 'service_detail_screen.dart';
import 'category_detail_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final String sectionTitle;
  const ServiceListScreen({super.key, required this.sectionTitle});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  String _currentSort = 'rating'; // 'rating', 'price_asc', 'price_desc'

  double _parsePrice(String priceStr) {
    // Remove ₹ and non-numeric chars
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _sortServices(List<ServiceModel> services) {
    if (_currentSort == 'rating') {
      services.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_currentSort == 'price_asc') {
      services.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
    } else if (_currentSort == 'price_desc') {
      services.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sort & Filter Services",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.orange),
                    title: const Text("Rating: High to Low"),
                    trailing: _currentSort == 'rating' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                    onTap: () {
                      setState(() => _currentSort = 'rating');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.trending_down, color: Colors.green),
                    title: const Text("Price: Low to High"),
                    trailing: _currentSort == 'price_asc' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                    onTap: () {
                      setState(() => _currentSort = 'price_asc');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.trending_up, color: Colors.red),
                    title: const Text("Price: High to Low"),
                    trailing: _currentSort == 'price_desc' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                    onTap: () {
                      setState(() => _currentSort = 'price_desc');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  ServiceModel _mapDocToService(DocumentSnapshot doc, List<DocumentSnapshot> reviewsDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final String serviceId = data['id'] ?? doc.id;
    final String serviceTitle = data['title'] ?? data['categoryName'] ?? 'Service';
    final String vendorId = data['vendorId'] ?? '';

    // Find matching reviews
    final matchingReviews = reviewsDocs.where((r) {
      final rData = r.data() as Map<String, dynamic>;
      return rData['serviceId'] == serviceId || 
             rData['serviceTitle'] == serviceTitle ||
             rData['title'] == serviceTitle ||
             (vendorId.isNotEmpty && rData['vendorId'] == vendorId);
    }).toList();

    double computedRating = 4.5;
    int reviewsCount = 0;
    if (matchingReviews.isNotEmpty) {
      double total = 0.0;
      for (var r in matchingReviews) {
        final rData = r.data() as Map<String, dynamic>;
        total += ((rData['rating'] ?? 5.0) as num).toDouble();
      }
      computedRating = total / matchingReviews.length;
      reviewsCount = matchingReviews.length;
    } else {
      computedRating = ((data['rating'] ?? 4.5) as num).toDouble();
      reviewsCount = data['totalReviews'] ?? 12;
    }

    var rawPrice = data['price'] ?? 299;
    String priceStr = rawPrice.toString().startsWith('₹') ? rawPrice.toString() : '₹$rawPrice';

    final String imageVal = data['imageUrl'] ?? data['categoryImageUrl'] ?? 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=720&auto=format&fit=crop';

    return ServiceModel(
      id: serviceId,
      title: serviceTitle,
      category: data['categoryName'] ?? 'Cleaning',
      subCategory: data['categoryName'] ?? 'Cleaning',
      price: priceStr,
      rating: computedRating,
      totalReviews: reviewsCount,
      image: imageVal,
      discountPercent: data['discountPercent'] ?? 0,
      vendorName: data['vendorName'] ?? 'Verified Partner',
      images: List<String>.from(data['images'] ?? [imageVal]),
      shortDescription: data['shortDescription'] ?? data['description'] ?? 'Professional services at your doorstep.',
      description: data['description'] ?? 'Professional services at your doorstep.',
      longDescription: data['longDescription'] ?? data['description'] ?? 'Professional services at your doorstep.',
      duration: data['duration'] ?? '1.5 hrs',
      isAvailable: data['isAvailable'] ?? true,
      location: data['location'] ?? 'Indirapuram',
      tags: List<String>.from(data['tags'] ?? ['Popular']),
      vendorId: vendorId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sectionTitle == "New Services") {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.sectionTitle,
            style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['categoryName'] ?? data['title'] ?? 'Service';
                final imageUrl = data['categoryImageUrl'] ?? data['imageUrl'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800';
                final desc = data['description'] ?? 'Professional services at your doorstep.';
                final subSvcs = List.from(data['subServices'] ?? []);

                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[100]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[100],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                      title: Text(
                        title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accentColor),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${subSvcs.length} Options available",
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00A884)),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(categoryName: title),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    if (widget.sectionTitle == "Best in Your City") {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.sectionTitle,
            style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune, color: AppTheme.accentColor),
              onPressed: _showFilterBottomSheet,
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, servicesSnapshot) {
            if (servicesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!servicesSnapshot.hasData || servicesSnapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final serviceDocs = servicesSnapshot.data!.docs;

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('reviews').get(),
              builder: (context, reviewsSnapshot) {
                if (reviewsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviewsDocs = reviewsSnapshot.data?.docs ?? [];
                final List<ServiceModel> services = [];

                for (var doc in serviceDocs) {
                  services.add(_mapDocToService(doc, reviewsDocs));
                }

                _sortServices(services);

                if (services.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: services.length,
                  itemBuilder: (context, index) => _buildServiceListItem(context, services[index]),
                );
              },
            );
          },
        ),
      );
    }

    final List<ServiceModel> services = DummyData.getBySection(widget.sectionTitle);
    _sortServices(services);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sectionTitle,
          style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.accentColor),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: services.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: services.length,
              itemBuilder: (context, index) => _buildServiceListItem(context, services[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "No services found",
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceListItem(BuildContext context, ServiceModel service) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(service: service)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: service.image.startsWith('http')
                        ? Image.network(
                            service.image,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 110,
                              height: 110,
                              color: AppTheme.lightGray,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: Colors.grey),
                            ),
                          )
                        : Image.asset(
                            service.image,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 110,
                              height: 110,
                              color: AppTheme.lightGray,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: Colors.grey),
                            ),
                          ),
                    ),
                    if (service.discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${service.discountPercent}% OFF",
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.accentColor),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${service.rating}",
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            " (${service.totalReviews})",
                            style: GoogleFonts.outfit(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            service.price,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF008060),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGray,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              service.subCategory,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentColor),
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
        ),
      ),
    );
  }
}
