import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  static const routeName = '/search';

  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _recentSearches = ['AC Repair', 'Sofa Cleaning', 'Men Haircut', 'Plumber'];
  final List<String> _trending = ['Deep Home Cleaning', 'Pest Control', 'Electrician', 'RO Water Purifier'];
  final List<Map<String, dynamic>> _searchResults = [
    {'title': 'AC Servicing', 'price': 'â‚¹599', 'rating': '4.8', 'img': 'https://images.unsplash.com/photo-1617066914620-80491d91cdde?w=500'},
    {'title': 'AC Gas Charge', 'price': 'â‚¹2499', 'rating': '4.6', 'img': 'https://images.unsplash.com/photo-1617066914620-80491d91cdde?w=500'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = value.trim().isNotEmpty;
    });
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filter by', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 24),
            const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('4.5 & above'), selected: true, onSelected: (v) {}, selectedColor: accentColor.withValues(alpha: 0.2)),
                FilterChip(label: const Text('4.0 & above'), selected: false, onSelected: (v) {}),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('Under â‚¹500'), selected: false, onSelected: (v) {}),
                FilterChip(label: const Text('â‚¹500 - â‚¹1000'), selected: true, onSelected: (v) {}, selectedColor: accentColor.withValues(alpha: 0.2)),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
        iconTheme: const IconThemeData(color: primaryColor),
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search for services...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildSearchSuggestions(),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
              TextButton(
                onPressed: () => setState(() => _recentSearches.clear()),
                child: const Text('Clear', style: TextStyle(color: accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _recentSearches.map((tag) => _buildChip(tag, isRecent: true)).toList(),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 32),
          const Text('Trending Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _trending.map((tag) => _buildChip(tag, isTrending: true)).toList(),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Top Rated'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Under â‚¹999'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Next Available'),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 12)),
              GestureDetector(
                onTap: _openFilters,
                child: Row(
                  children: const [
                    Icon(Icons.tune, color: primaryColor, size: 20),
                    SizedBox(width: 4),
                    Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = _searchResults[index];
              return _buildResultCard(item);
            },
          ).animate().fadeIn().slideY(begin: 0.1),
        ),
      ],
    );
  }

  Widget _buildChip(String label, {bool isRecent = false, bool isTrending = false}) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _onSearchChanged(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecent) Icon(Icons.history, size: 16, color: Colors.grey.shade500),
            if (isTrending) const Icon(Icons.trending_up, size: 16, color: accentColor),
            if (isRecent || isTrending) const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label, style: const TextStyle(color: primaryColor)),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_details'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: item['img'],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(item['rating'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['price'], style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Add', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
