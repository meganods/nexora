import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryDetailsScreen extends StatefulWidget {
  static const routeName = '/category_details';

  const CategoryDetailsScreen({super.key});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  bool _isLoading = true;

  final List<String> _subcategories = ['All', 'Deep Clean', 'Sofa', 'Bathroom', 'Kitchen'];
  int _selectedSubcategory = 0;

  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Deep Home Cleaning',
      'price': 'â‚¹1,299',
      'old_price': 'â‚¹1,599',
      'rating': '4.8',
      'reviews': '12k',
      'time': '3 hrs',
      'desc': 'Intensive cleaning for every corner of your house.',
      'img': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500',
    },
    {
      'title': 'Sofa Deep Cleaning',
      'price': 'â‚¹499',
      'old_price': 'â‚¹699',
      'rating': '4.9',
      'reviews': '5k',
      'time': '1 hr',
      'desc': 'Dry vacuuming and wet shampooing of sofa.',
      'img': 'https://images.unsplash.com/photo-1617066914620-80491d91cdde?w=500', // placeholder
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  pinned: true,
                  backgroundColor: primaryColor,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Cleaning Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, primaryColor.withValues(alpha: 0.8)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => Navigator.pushNamed(context, '/search'),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _subcategories.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedSubcategory == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSubcategory = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? accentColor : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? accentColor : Colors.grey.shade300),
                              ),
                              child: Text(
                                _subcategories[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : primaryColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _services[index];
                        return _buildServiceCard(service);
                      },
                      childCount: _services.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_details'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(service['rating'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(' (${service['reviews']} reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(service['price'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                        const SizedBox(width: 8),
                        Text(
                          service['old_price'],
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(service['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(service['desc'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: service['img'],
                      width: 100, height: 100, fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart'), backgroundColor: accentColor));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }
}
