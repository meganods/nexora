import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;
  bool _isLoading = true;

  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isLoading = false);
  }

  void _onNavTapped(int index) {
    if (index == _currentIndex) return;
    
    // Switch between bottom nav tabs
    if (index == 1) Navigator.pushNamed(context, '/my_bookings');
    if (index == 2) Navigator.pushNamed(context, '/rewards');
    if (index == 3) Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading ? _buildSkeletonLoader() : _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Location & Header
        SliverAppBar(
          backgroundColor: Colors.white,
          pinned: true,
          elevation: 0,
          toolbarHeight: 70,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Home', style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                      'B-102, Galaxy Apartments, Sector 62...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: primaryColor),
                onPressed: () => Navigator.pushNamed(context, '/address_management'),
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: accentColor),
                        const SizedBox(width: 12),
                        Text('Search for "AC Repair"', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),

                // Promotional Banner
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: index % 2 == 0 
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [const Color(0xFF00A884), const Color(0xFF00896B)],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    index == 0 ? '50% OFF' : 'Free Cleaning',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    index == 0 ? 'On your first AC service' : 'With every deep clean',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                    child: Text('Book Now', style: TextStyle(color: index % 2 == 0 ? primaryColor : accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.ac_unit, color: Colors.white54, size: 60),
                          ],
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
                const SizedBox(height: 32),

                // Categories Grid
                const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildCategoryItem('Cleaning', Icons.cleaning_services, Colors.blue),
                    _buildCategoryItem('Plumbing', Icons.plumbing, Colors.orange),
                    _buildCategoryItem('Electrical', Icons.electrical_services, Colors.amber),
                    _buildCategoryItem('Painting', Icons.format_paint, Colors.purple),
                    _buildCategoryItem('Salon', Icons.face, Colors.pink),
                    _buildCategoryItem('Carpentry', Icons.handyman, Colors.brown),
                    _buildCategoryItem('Appliance', Icons.kitchen, Colors.teal),
                    _buildCategoryItem('More', Icons.more_horiz, Colors.grey),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),

                // Popular Services
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Popular Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                    TextButton(onPressed: () {}, child: const Text('See All', style: TextStyle(color: accentColor))),
                  ],
                ),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return _buildServiceCard('Sofa Cleaning', 'â‚¹499', '4.8', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&q=80');
                    },
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                const SizedBox(height: 32),

                // Recommended Services
                const Text('Recommended for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return _buildServiceCard('AC Servicing', 'â‚¹599', '4.9', 'https://images.unsplash.com/photo-1617066914620-80491d91cdde?w=500&q=80');
                    },
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/category_details'),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primaryColor), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String price, String rating, String imageUrl) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_details'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.error)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 14, color: Colors.grey.shade200),
                      const SizedBox(height: 4),
                      Container(width: double.infinity, height: 12, color: Colors.grey.shade200),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: List.generate(8, (index) => Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)))),
              ),
            )
          ],
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, color: Colors.white54),
      ),
    );
  }
}
