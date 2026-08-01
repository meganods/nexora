import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';
import 'dashboard_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final List<Map<String, dynamic>> _fallbackFavorites = [
    {
      'id': 'fav1',
      'serviceId': 's1',
      'name': 'Deep Home Cleaning',
      'category': 'Cleaning',
      'startingPrice': 799.0,
      'duration': '3–4 hrs',
      'rating': 4.9,
      'totalReviews': 1280,
      'coverImage': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400&auto=format&fit=crop',
    },
    {
      'id': 'fav2',
      'serviceId': 's2',
      'name': 'AC Service & Anti-Rust Coating',
      'category': 'Appliance',
      'startingPrice': 599.0,
      'duration': '1–2 hrs',
      'rating': 4.8,
      'totalReviews': 950,
      'coverImage': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=400&auto=format&fit=crop',
    },
  ];

  Future<void> _removeFromWishlist(String favDocId) async {
    try {
      await FirebaseFirestore.instance.collection('favorites').doc(favDocId).delete();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from Favorites.', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          backgroundColor: _dark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Favorites (Wishlist)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user?.uid ?? 'guest_user')
            .snapshots(),
        builder: (ctx, snap) {
          List<Map<String, dynamic>> favList = _fallbackFavorites;
          if (snap.hasData && snap.data!.docs.isNotEmpty) {
            favList = snap.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {'id': d.id, ...data};
            }).toList();
          }

          if (favList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border_rounded, size: 54, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  Text('No Favorite Services Saved',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 4),
                  Text('Tap the heart icon on any service card to save it here!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Explore Services', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: favList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, idx) {
              final f = favList[idx];
              final docId = f['id'] ?? '';
              final title = f['name'] ?? f['serviceName'] ?? 'Service';
              final category = f['category'] ?? 'Home Service';
              final price = ((f['startingPrice'] ?? f['price'] ?? 499) as num).toDouble();
              final duration = f['duration'] ?? '1–2 hrs';
              final rating = ((f['rating'] ?? 4.9) as num).toDouble();
              final img = f['coverImage'] ?? f['image'] ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: img.startsWith('http')
                              ? Image.network(img, width: 80, height: 80, fit: BoxFit.cover)
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: _blue.withValues(alpha: 0.1),
                                  child: const Icon(Icons.handyman_rounded, color: _blue),
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                            child: Text(category.toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                          const SizedBox(height: 3),
                          Text('⭐ $rating · $duration', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                          const SizedBox(height: 3),
                          Text('₹${price.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _blue)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                          onPressed: () => _removeFromWishlist(docId),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final model = ServiceModel(
                              id: f['serviceId'] ?? docId,
                              title: title,
                              price: price,
                              image: img,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: model)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          ),
                          child: Text('Book', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
