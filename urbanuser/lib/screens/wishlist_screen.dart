import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WishlistScreen extends StatefulWidget {
  static const routeName = '/wishlist';

  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  final List<Map<String, dynamic>> _wishlist = [
    {
      'id': 1,
      'title': 'Deep Home Cleaning',
      'rating': '4.8',
      'reviews': '12k',
      'price': 'â‚¹1,299',
      'img': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500',
    },
    {
      'id': 2,
      'title': 'Intense Sofa Cleaning',
      'rating': '4.9',
      'reviews': '5k',
      'price': 'â‚¹499',
      'img': 'https://images.unsplash.com/photo-1617066914620-80491d91cdde?w=500', // reused for demo
    },
  ];

  void _removeFromWishlist(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Wishlist?'),
        content: const Text('Are you sure you want to remove this service from your wishlist?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _wishlist.removeWhere((item) => item['id'] == id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist'), backgroundColor: accentColor));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Wishlist', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: _wishlist.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _wishlist.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _wishlist[index];
                return _buildWishlistCard(item);
              },
            ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_details'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: item['img'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(height: 160, color: Colors.grey.shade200),
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: GestureDetector(
                    onTap: () => _removeFromWishlist(item['id']),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      Text(item['price'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${item['rating']} (${item['reviews']} reviews)', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Your wishlist is empty', style: TextStyle(fontSize: 20, color: primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Save services you love to book them later.', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Explore Services', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
