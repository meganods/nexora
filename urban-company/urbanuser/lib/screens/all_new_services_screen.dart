import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';
import 'schedule_booking_screen.dart';

const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class AllNewServicesScreen extends StatefulWidget {
  const AllNewServicesScreen({super.key});

  @override
  State<AllNewServicesScreen> createState() => _AllNewServicesScreenState();
}

class _AllNewServicesScreenState extends State<AllNewServicesScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _sort = 'Newest';
  String _filterCategory = 'All';

  final _sorts = ['Newest', 'Highest Rated', 'Lowest Price'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showFilters(List<String> cats) {
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
              Text('Filter New Services',
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
              if (cats.length > 1) ...[
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
                  children: ['All', ...cats].map((cat) {
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
                        _sort = 'Newest';
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
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, color: _gray)),
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
    final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 30)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text('New Services',
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration:
                  BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
              child: Text('NEW',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ),
          ],
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('status', isEqualTo: 'Approved')
            .where('createdAt', isGreaterThanOrEqualTo: cutoff)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, __) => _skeleton(),
            );
          }
          if (snap.hasError) {
            return _error(() => setState(() {}));
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

          // Apply filters
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            services = services.where((s) {
              return (s['name'] ?? s['title'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['category'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['vendorName'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
          }
          if (_filterCategory != 'All') {
            services =
                services.where((s) => s['category'] == _filterCategory).toList();
          }

          // Sort
          switch (_sort) {
            case 'Highest Rated':
              services.sort((a, b) => ((b['rating'] ?? 0) as num)
                  .compareTo((a['rating'] ?? 0) as num));
              break;
            case 'Lowest Price':
              services.sort((a, b) =>
                  ((a['startingPrice'] ?? a['price'] ?? 0) as num).compareTo(
                      (b['startingPrice'] ?? b['price'] ?? 0) as num));
              break;
            default: // Newest — already ordered by createdAt
              break;
          }

          if (services.isEmpty) return _empty();

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _search,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: _gray, size: 22),
                    suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (_query.isNotEmpty)
                        IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: _gray, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            }),
                      IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: _dark, size: 20),
                          onPressed: () => _showFilters(cats)),
                    ]),
                    hintText: 'Search new services…',
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
                        borderSide:
                            const BorderSide(color: _blue, width: 1.5)),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) =>
                      _NewServiceListCard(data: services[idx], index: idx),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _skeleton() => Container(
        height: 110,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border)),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0));

  Widget _error(VoidCallback onRetry) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _gray, size: 48),
            const SizedBox(height: 12),
            Text('Network error',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.fiber_new_rounded,
                  color: _green, size: 40),
            ),
            const SizedBox(height: 16),
            Text('No New Services Available',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 8),
            Text('Check back soon for the latest services.',
                style: GoogleFonts.inter(fontSize: 12, color: _gray)),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, duration: 400.ms);
}

// ─── Fallback ─────────────────────────────────────────────────────────────────
final _fallback = [
  {
    'id': 'n1',
    'name': 'Kitchen Deep Cleaning',
    'category': 'Cleaning',
    'vendorName': 'CleanPro Services',
    'startingPrice': 699,
    'rating': 4.6,
    'totalReviews': 42,
    'duration': '2–3 hrs',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
  },
  {
    'id': 'n2',
    'name': 'Sofa Steam Cleaning',
    'category': 'Cleaning',
    'vendorName': 'HomeShine',
    'startingPrice': 449,
    'rating': 4.5,
    'totalReviews': 18,
    'duration': '1–2 hrs',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
  },
  {
    'id': 'n3',
    'name': 'Geyser Installation',
    'category': 'Plumbing',
    'vendorName': 'Expert Plumbing',
    'startingPrice': 599,
    'rating': 4.7,
    'totalReviews': 27,
    'duration': '1 hr',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 8))),
  },
];

String _timeAgo(dynamic createdAt) {
  if (createdAt == null) return '';
  if (createdAt is! Timestamp) return '';
  final dt = createdAt.toDate();
  final diff = DateTime.now().difference(dt);
  if (diff.inDays == 0) return 'Added Today';
  if (diff.inDays == 1) return 'Added Yesterday';
  if (diff.inDays < 7) return 'Added ${diff.inDays} Days Ago';
  return 'Added ${DateFormat('d MMM').format(dt)}';
}

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) {
    final cleaned = v.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

ServiceModel _toModel(Map<String, dynamic> d) => ServiceModel(
      id: d['id'] ?? '',
      title: d['name'] ?? d['title'] ?? d['serviceName'] ?? 'Service',
      price: _parseDouble(d['startingPrice'] ?? d['price']),
      image: d['coverImage'] ?? d['image'] ?? '',
      rating: _parseDouble(d['rating'] ?? d['averageRating'] ?? 5.0),
      category: d['category'] ?? '',
      totalReviews: (d['totalReviews'] ?? d['reviews'] ?? 0) as int,
      vendorName: d['vendorName'] ?? d['vendor'] ?? '',
      duration: d['duration'] ?? '',
    );

// ─── List card ────────────────────────────────────────────────────────────────
class _NewServiceListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _NewServiceListCard({required this.data, required this.index});

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
    final timeLabel = _timeAgo(data['createdAt']);

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
            // Thumbnail
            Stack(
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
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(5)),
                    child: Text('NEW',
                        style: GoogleFonts.inter(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
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
                    if (timeLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(timeLabel,
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: _green,
                              fontWeight: FontWeight.w600)),
                    ],
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
                  const SizedBox(height: 5),
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
                        onPressed: () {
                          final service = _toModel(data);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScheduleBookingScreen(
                                service: service,
                                selectedItems: [
                                  {
                                    'name': service.title,
                                    'price': service.price,
                                    'quantity': 1,
                                  }
                                ],
                                totalPrice: service.price,
                              ),
                            ),
                          );
                        },
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
            duration: 350.ms, delay: Duration(milliseconds: 50 * index))
        .slideY(
            begin: 0.1,
            duration: 350.ms,
            delay: Duration(milliseconds: 50 * index));
  }

  Widget _placeholder() => Container(
        width: 80,
        height: 80,
        color: _green.withValues(alpha: 0.08),
        child: const Icon(Icons.fiber_new_rounded, color: _green, size: 32),
      );
}
