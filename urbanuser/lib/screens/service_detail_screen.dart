import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_model.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';
import 'vendor_profile_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;
  final ValueNotifier<bool> isFavorite = ValueNotifier(false);

  ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 25),
                  _buildVendorCard(context),
                  const SizedBox(height: 25),
                  _buildSectionTitle("About this service"),
                  const SizedBox(height: 10),
                  Text(
                    service.longDescription,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Service Photos"),
                  const SizedBox(height: 15),
                  _buildPhotoGrid(),
                  const SizedBox(height: 30),
                  _buildKeyPoints(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActionBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: CircleAvatar(
        backgroundColor: Colors.black26,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: isFavorite,
          builder: (context, fav, child) {
            return CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  isFavorite.value = !isFavorite.value;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFavorite.value ? "Added to Wishlist" : "Removed from Wishlist"),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 800),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(width: 15),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          service.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.lightGray,
            child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                service.category.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  "${service.rating}",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  " (${service.totalReviews} reviews)",
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          service.title,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              service.price,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            if (service.discountPercent > 0)
              Text(
                "Save ${service.discountPercent}%",
                style: GoogleFonts.outfit(
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.vendorName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  "Professional Partner",
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorProfileScreen(service: service),
                ),
              );
            },
            child: Text(
              "View Profile",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: service.images.length,
        itemBuilder: (context, index) => Container(
          width: 120,
          margin: const EdgeInsets.only(right: 15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              service.images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppTheme.lightGray,
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPoints() {
    final points = [
      {"icon": Icons.verified, "text": "Quality Guaranteed"},
      {"icon": Icons.timer_outlined, "text": "Duration: ${service.duration}"},
      {"icon": Icons.security_outlined, "text": "Insurance covered service"},
    ];
    return Column(
      children: points.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Icon(p['icon'] as IconData, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(p['text'] as String, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[800])),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TOTAL PRICE", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(service.price, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(
            height: 55,
            width: 180,
            child: ElevatedButton(
              onPressed: () {
                final double parsedPrice = double.tryParse(service.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      shop: {
                        "name": service.vendorName,
                        "img": service.image,
                        "rating": service.rating.toString(),
                      },
                      cartCount: 1,
                      totalPrice: parsedPrice,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                "BOOK NOW",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
