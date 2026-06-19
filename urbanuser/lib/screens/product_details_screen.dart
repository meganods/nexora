import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  static const routeName = '/product_details';

  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  bool _isFavorite = false;
  int _currentImageIndex = 0;

  final List<String> _images = [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.redAccent : Colors.white),
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isFavorite ? 'Added to Wishlist' : 'Removed from Wishlist'), backgroundColor: accentColor),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: _images.length,
                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: _images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index ? accentColor : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    height: 100,
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Info
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Deep Home Cleaning', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: const [
                                Icon(Icons.star, color: accentColor, size: 16),
                                SizedBox(width: 4),
                                Text('4.8', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('â‚¹1,299', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(width: 12),
                          Text('â‚¹1,599', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text('20% OFF', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('3 hrs', style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 24),
                          const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Includes Equipment', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 8),

                // Description
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      const SizedBox(height: 12),
                      Text(
                        'Intensive cleaning of the entire house including deep cleaning of kitchen, bathrooms, bedrooms and living areas. '
                        'Our professionals bring their own specialized cleaning equipment and eco-friendly chemicals.',
                        style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 8),

                // Included Services
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What is included?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      const SizedBox(height: 16),
                      _buildCheckListItem('Floor Scrubbing & Mopping'),
                      _buildCheckListItem('Kitchen Deep Cleaning (Chimney & Cabinets)'),
                      _buildCheckListItem('Bathroom Deep Cleaning'),
                      _buildCheckListItem('Dry dusting of walls & ceiling'),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 8),

                // Reviews
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: accentColor))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReviewCard('Anjali Singh', '4.9', 'Very professional and thorough cleaning. Highly recommended!'),
                      const Divider(height: 32),
                      _buildReviewCard('Rahul Sharma', '4.5', 'Good service, but arrived 10 mins late. Cleaning was perfect though.'),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 100), // padding for bottom bar
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart'), backgroundColor: primaryColor));
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add to Cart', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String rating, String review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: Text(name[0], style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(review, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
      ],
    );
  }
}
