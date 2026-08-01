import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';

const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

class AllRecommendationsScreen extends StatefulWidget {
  final List<String>? preferredCategories;
  const AllRecommendationsScreen({super.key, this.preferredCategories});

  @override
  State<AllRecommendationsScreen> createState() =>
      _AllRecommendationsScreenState();
}

class _AllRecommendationsScreenState extends State<AllRecommendationsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _sort = 'Best Match';
  String _filterCategory = 'All';

  final _sorts = ['Best Match', 'Highest Rated', 'Most Booked', 'Lowest Price', 'Nearest'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showFilters(List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              Text('Filter Recommendations',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
              const SizedBox(height: 16),
              Text('SORT BY',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _gray,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sorts.map((s) {
                  final sel = _sort == s;
                  return ChoiceChip(
                    label: Text(s,
                        style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    selected: sel,
                    selectedColor: _blue,
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onSelected: (v) {
                      if (v) {
                        setM(() => _sort = s);
                        setState(() => _sort = s);
                      }
                    },
                  );
                }).toList(),
              ),
              if (categories.length > 1) ...[
                const SizedBox(height: 16),
                Text('CATEGORY',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _gray,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', ...categories].map((cat) {
                    final sel = _filterCategory == cat;
                    return ChoiceChip(
                      label: Text(cat,
                          style: TextStyle(
                              color: sel ? Colors.white : const Color(0xFF475569),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      selected: sel,
                      selectedColor: _blue,
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (v) {
                        if (v) {
                          setM(() => _filterCategory = cat);
                          setState(() => _filterCategory = cat);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _sort = 'Best Match';
                        _filterCategory = 'All';
                      });
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text('Reset',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.bold, color: _gray)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text('Apply',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Recommended For You',
            style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('status', isEqualTo: 'Approved')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList();
          }
          if (snap.hasError) {
            return _buildError(() => setState(() {}));
          }

          final docs = snap.data?.docs ?? [];
          List<Map<String, dynamic>> services = docs.isEmpty
              ? _fallback
              : docs
                  .map((d) =>
                      {'id': d.id, ...(d.data() as Map<String, dynamic>)})
                  .toList();

          // Collect categories
          final cats = services
              .map((s) => (s['category'] ?? '').toString())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();

          // Apply filter
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            services = services.where((s) {
              return (s['name'] ?? s['title'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['category'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['vendorName'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
          }
          if (_filterCategory != 'All') {
            services = services
                .where((s) => s['category'] == _filterCategory)
                .toList();
          }

          // Sort
          switch (_sort) {
            case 'Highest Rated':
              services.sort((a, b) => ((b['rating'] ?? 0) as num)
                  .compareTo((a['rating'] ?? 0) as num));
              break;
            case 'Most Booked':
              services.sort((a, b) => ((b['bookingCount'] ?? 0) as num)
                  .compareTo((a['bookingCount'] ?? 0) as num));
              break;
            case 'Lowest Price':
              services.sort((a, b) =>
                  ((a['startingPrice'] ?? a['price'] ?? 0) as num).compareTo(
                      (b['startingPrice'] ?? b['price'] ?? 0) as num));
              break;
            default:
              // Best Match: featured first, then rating
              services.sort((a, b) {
                final fa = a['featured'] == true ? 1 : 0;
                final fb = b['featured'] == true ? 1 : 0;
                if (fb != fa) return fb - fa;
                return ((b['rating'] ?? 0) as num)
                    .compareTo((a['rating'] ?? 0) as num);
              });
          }

          if (services.isEmpty) return _buildEmpty();

          return Column(
            children: [
              // Search bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: _gray, size: 22),
                    suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (_query.isNotEmpty)
                        IconButton(
                            icon: const Icon(Icons.clear_rounded, color: _gray, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            }),
                      IconButton(
                          icon: const Icon(Icons.tune_rounded, color: _dark, size: 20),
                          onPressed: () => _showFilters(cats)),
                    ]),
                    hintText: 'Search services, categories…',
                    hintStyle: GoogleFonts.inter(
                        color: const Color(0xFFCBD5E1), fontSize: 14),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _blue, width: 1.5)),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) =>
                      _RecommendedListCard(data: services[idx], index: idx),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Container(
          height: 100,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border)),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0)),
      );

  Widget _buildError(VoidCallback onRetry) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _gray, size: 48),
            const SizedBox(height: 12),
            Text('Connection error',
                style: GoogleFonts.inter(color: _dark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Try Again',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: _blue, size: 40),
            ),
            const SizedBox(height: 16),
            Text('No recommendations available yet.',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 8),
            Text('Book a service to personalise your feed.',
                style: GoogleFonts.inter(fontSize: 12, color: _gray)),
          ],
        ),
      );
}

// ─── Fallback ─────────────────────────────────────────────────────────────────
const _fallback = [
  {
    'id': 'r1',
    'name': 'Full Home Deep Clean',
    'category': 'Cleaning',
    'vendorName': 'CleanPro Services',
    'startingPrice': 799,
    'rating': 4.9,
    'totalReviews': 1284,
    'duration': '3–4 hrs',
    'featured': true,
  },
  {
    'id': 'r2',
    'name': 'AC Service & Gas Refill',
    'category': 'AC Repair',
    'vendorName': 'CoolTech Experts',
    'startingPrice': 499,
    'rating': 4.8,
    'totalReviews': 862,
    'duration': '1–2 hrs',
    'featured': true,
  },
  {
    'id': 'r3',
    'name': 'Salon at Home',
    'category': 'Beauty',
    'vendorName': 'Priya Mehta',
    'startingPrice': 349,
    'rating': 4.7,
    'totalReviews': 502,
    'duration': '1 hr',
    'featured': false,
  },
];

ServiceModel _toModel(Map<String, dynamic> d) => ServiceModel(
      id: d['id'] ?? '',
      title: d['name'] ?? d['title'] ?? d['serviceName'] ?? 'Service',
      price: ((d['startingPrice'] ?? d['price'] ?? 0) as num).toDouble(),
      image: d['coverImage'] ?? d['image'] ?? '',
      rating: ((d['rating'] ?? d['averageRating'] ?? 5.0) as num).toDouble(),
      category: d['category'] ?? '',
      totalReviews: (d['totalReviews'] ?? d['reviews'] ?? 0) as int,
      vendorName: d['vendorName'] ?? d['vendor'] ?? '',
      duration: d['duration'] ?? '',
    );

// ─── List card ────────────────────────────────────────────────────────────────
class _RecommendedListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _RecommendedListCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? data['title'] ?? 'Service';
    final category = data['category'] ?? '';
    final vendor = data['vendorName'] ?? data['vendor'] ?? '';
    final price = ((data['startingPrice'] ?? data['price'] ?? 0) as num).toDouble();
    final rating = ((data['rating'] ?? 5.0) as num).toDouble();
    final reviews = (data['totalReviews'] ?? 0) as int;
    final duration = data['duration'] ?? '';
    final image = data['coverImage'] ?? data['image'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(service: _toModel(data))),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image.startsWith('http')
                  ? Image.network(image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(category,
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                color: _blue,
                                fontWeight: FontWeight.bold)),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 9, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('FOR YOU',
                            style: GoogleFonts.inter(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _dark)),
                  if (vendor.isNotEmpty)
                    Text(vendor,
                        style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text('$rating',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _dark)),
                    Text(' ($reviews)',
                        style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.timer_outlined, size: 11, color: _gray),
                      const SizedBox(width: 2),
                      Text(duration,
                          style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _dark)),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                  service: _toModel(data))),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Book Now',
                            style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 350.ms,
            delay: Duration(milliseconds: 50 * index))
        .slideY(
            begin: 0.1,
            duration: 350.ms,
            delay: Duration(milliseconds: 50 * index));
  }

  Widget _placeholder() => Container(
        width: 80,
        height: 80,
        color: _blue.withValues(alpha: 0.08),
        child: const Icon(Icons.home_repair_service_rounded,
            color: _blue, size: 32),
      );
}
