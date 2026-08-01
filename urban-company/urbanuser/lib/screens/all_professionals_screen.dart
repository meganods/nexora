import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'vendor_profile_screen.dart';

// ─── Color constants ──────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class AllProfessionalsScreen extends StatefulWidget {
  const AllProfessionalsScreen({super.key});

  @override
  State<AllProfessionalsScreen> createState() =>
      _AllProfessionalsScreenState();
}

class _AllProfessionalsScreenState extends State<AllProfessionalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Highest Rated';
  bool _verifiedOnly = false;
  bool _availableToday = false;
  Position? _userPosition;

  final List<String> _sortOptions = [
    'Highest Rated',
    'Most Reviews',
    'Most Jobs',
    'Most Experience',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low));
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  String _distanceLabel(Map<String, dynamic> v) {
    if (_userPosition == null) return '';
    final lat =
        (v['lat'] ?? v['latitude'] ?? v['location']?['lat']) as num?;
    final lng =
        (v['lng'] ?? v['longitude'] ?? v['location']?['lng']) as num?;
    if (lat == null || lng == null) return '';
    final dist = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        lat.toDouble(),
        lng.toDouble());
    if (dist < 1000) return '${dist.toStringAsFixed(0)} m away';
    return '${(dist / 1000).toStringAsFixed(1)} km away';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Professionals',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _dark)),
                  IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
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
                children: _sortOptions.map((opt) {
                  final sel = _selectedSort == opt;
                  return ChoiceChip(
                    label: Text(opt,
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
                        setModal(() => _selectedSort = opt);
                        setState(() => _selectedSort = opt);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(color: _border),
              SwitchListTile(
                value: _verifiedOnly,
                title: Text('Verified Professionals Only',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: _dark)),
                subtitle: Text('Show only admin-verified pros',
                    style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                activeTrackColor: _blue,
                onChanged: (v) {
                  setModal(() => _verifiedOnly = v);
                  setState(() => _verifiedOnly = v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _availableToday,
                title: Text('Available Today',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: _dark)),
                subtitle: Text('Online right now',
                    style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                activeTrackColor: _green,
                onChanged: (v) {
                  setModal(() => _availableToday = v);
                  setState(() => _availableToday = v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedSort = 'Highest Rated';
                          _verifiedOnly = false;
                          _availableToday = false;
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Apply Filters',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _dark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Top Rated Professionals',
            style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.bold, color: _dark)),
        actions: [
          IconButton(
              icon: const Icon(Icons.tune_rounded, color: _dark),
              onPressed: _showFilterSheet),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _gray, size: 22),
                hintText: 'Search by name, service or area…',
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: _gray),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
              ),
            ),
          ),

          // ── Active filter chips ───────────────────────────────────────────
          if (_verifiedOnly || _availableToday)
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Row(
                children: [
                  if (_verifiedOnly)
                    _filterChip('Verified Only',
                        () => setState(() => _verifiedOnly = false)),
                  if (_availableToday)
                    _filterChip('Available Today',
                        () => setState(() => _availableToday = false)),
                ],
              ),
            ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendors')
                  .where('isApproved', isEqualTo: true)
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, __) => const _SkeletonListCard(),
                  );
                }
                // Error
                if (snapshot.hasError) {
                  return _FullScreenError(onRetry: () => setState(() {}));
                }

                final docs = snapshot.data?.docs ?? [];
                List<Map<String, dynamic>> vendors = docs.isEmpty
                    ? _fallback
                    : docs
                        .map((d) => {
                              'id': d.id,
                              ...(d.data() as Map<String, dynamic>)
                            })
                        .toList();

                // Apply filters
                if (_searchQuery.isNotEmpty) {
                  vendors = vendors.where((v) {
                    final n = (v['fullName'] ?? v['name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final b =
                        (v['businessName'] ?? '').toString().toLowerCase();
                    final cats = (v['categories'] as List? ?? [])
                        .join(' ')
                        .toLowerCase();
                    return n.contains(_searchQuery) ||
                        b.contains(_searchQuery) ||
                        cats.contains(_searchQuery);
                  }).toList();
                }
                if (_verifiedOnly) {
                  vendors = vendors
                      .where((v) => v['isApproved'] == true)
                      .toList();
                }
                if (_availableToday) {
                  vendors = vendors
                      .where((v) => v['isOnline'] == true)
                      .toList();
                }

                // Sort
                switch (_selectedSort) {
                  case 'Most Reviews':
                    vendors.sort((a, b) =>
                        ((b['totalReviews'] ?? 0) as num)
                            .compareTo((a['totalReviews'] ?? 0) as num));
                    break;
                  case 'Most Jobs':
                    vendors.sort((a, b) =>
                        ((b['completedBookings'] ?? 0) as num).compareTo(
                            (a['completedBookings'] ?? 0) as num));
                    break;
                  case 'Most Experience':
                    vendors.sort((a, b) =>
                        ((b['yearsExperience'] ?? 0) as num).compareTo(
                            (a['yearsExperience'] ?? 0) as num));
                    break;
                  default:
                    vendors.sort((a, b) =>
                        ((b['averageRating'] ?? 0) as num).compareTo(
                            (a['averageRating'] ?? 0) as num));
                }

                if (vendors.isEmpty) {
                  return _FullScreenEmpty();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: vendors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) => _ProfessionalListCard(
                    vendor: vendors[idx],
                    vendorId: vendors[idx]['id'] ?? '',
                    distanceLabel: _distanceLabel(vendors[idx]),
                    animIndex: idx,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) => Container(
        margin: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _blue)),
          deleteIcon: const Icon(Icons.close, size: 14, color: _blue),
          onDeleted: onRemove,
          backgroundColor: const Color(0xFFEFF6FF),
          side: const BorderSide(color: _blue, width: 0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
      );
}

// ─── Fallback data ────────────────────────────────────────────────────────────
const _fallback = [
  {
    'id': 'v1',
    'fullName': 'Rahul Sharma',
    'businessName': 'CleanPro Services',
    'averageRating': 4.9,
    'totalReviews': 1284,
    'completedBookings': 2750,
    'yearsExperience': 5,
    'responseTime': '~10 min',
    'categories': ['Cleaning', 'Sanitization'],
    'isApproved': true,
    'isActive': true,
    'isOnline': true,
  },
  {
    'id': 'v2',
    'fullName': 'Priya Mehta',
    'businessName': 'Salon @ Home',
    'averageRating': 4.8,
    'totalReviews': 980,
    'completedBookings': 1900,
    'yearsExperience': 3,
    'responseTime': '~15 min',
    'categories': ['Salon', 'Beauty'],
    'isApproved': true,
    'isActive': true,
    'isOnline': false,
  },
  {
    'id': 'v3',
    'fullName': 'David Wilson',
    'businessName': 'Expert Electrical',
    'averageRating': 4.9,
    'totalReviews': 762,
    'completedBookings': 1540,
    'yearsExperience': 7,
    'responseTime': '~8 min',
    'categories': ['Electrical', 'Repairs'],
    'isApproved': true,
    'isActive': true,
    'isOnline': true,
  },
];

// ─── Skeleton list card ───────────────────────────────────────────────────────
class _SkeletonListCard extends StatelessWidget {
  const _SkeletonListCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(70, 70, radius: 35),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(130, 13),
                const SizedBox(height: 8),
                _box(90, 11),
                const SizedBox(height: 8),
                _box(110, 11),
                const SizedBox(height: 12),
                _box(double.infinity, 32, radius: 10),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: const Color(0xFFE2E8F0));
  }

  Widget _box(double w, double h, {double radius = 6}) => Container(
        width: w == double.infinity ? null : w,
        height: h,
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(radius)),
      );
}

// ─── Full-screen empty ────────────────────────────────────────────────────────
class _FullScreenEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.person_search_rounded,
                  color: _blue, size: 48),
            ),
            const SizedBox(height: 20),
            Text('No Professionals Found',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _dark)),
            const SizedBox(height: 10),
            Text(
                'No verified professionals are available\nin your area right now.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: _gray, height: 1.6)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, duration: 400.ms);
  }
}

// ─── Full-screen error ────────────────────────────────────────────────────────
class _FullScreenError extends StatelessWidget {
  final VoidCallback onRetry;
  const _FullScreenError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.redAccent, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Connection Error',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _dark)),
            const SizedBox(height: 10),
            Text('Could not load professionals.\nPlease check your internet connection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: _gray, height: 1.6)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try Again',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── Professional list card ───────────────────────────────────────────────────
class _ProfessionalListCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final String vendorId;
  final String distanceLabel;
  final int animIndex;

  const _ProfessionalListCard({
    required this.vendor,
    required this.vendorId,
    required this.distanceLabel,
    required this.animIndex,
  });

  @override
  Widget build(BuildContext context) {
    final vName = vendor['fullName'] ?? vendor['name'] ?? 'Professional';
    final vBiz = vendor['businessName'] ?? '';
    final vPhoto = vendor['profilePhoto'] ?? vendor['photo'] ?? '';
    final vRating = ((vendor['averageRating'] ?? 5.0) as num).toDouble();
    final vReviews = (vendor['totalReviews'] ?? 0) as int;
    final vJobs = (vendor['completedBookings'] ?? 0) as int;
    final vExp = (vendor['yearsExperience'] ?? 1) as int;
    final vResponse = vendor['responseTime'] ?? '';
    final List<dynamic> vCats = vendor['categories'] ?? [];

    return StreamBuilder<DocumentSnapshot>(
      stream: vendorId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .snapshots()
          : null,
      builder: (ctx, liveSnap) {
        bool isOnline = vendor['isOnline'] == true;
        if (liveSnap.hasData && liveSnap.data!.exists) {
          final d = liveSnap.data!.data() as Map<String, dynamic>;
          isOnline = d['isOnline'] == true;
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VendorProfileScreen(
                    vendor: vendor, vendorId: vendorId)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ────────────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _border, width: 2)),
                      child: ClipOval(
                        child: vPhoto.startsWith('http')
                            ? Image.network(vPhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholder(vName))
                            : _placeholder(vName),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // ── Info ──────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badge
                      Row(children: [
                        Expanded(
                          child: Text(vName,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _dark)),
                        ),
                        const Icon(Icons.verified_rounded,
                            color: Colors.blue, size: 16),
                      ]),
                      if (vBiz.isNotEmpty)
                        Text(vBiz,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: _gray)),
                      if (vCats.isNotEmpty)
                        Text(vCats.take(2).join(' • '),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _blue,
                                fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      // Rating
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text('$vRating',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _dark)),
                        const SizedBox(width: 4),
                        Text('($vReviews reviews)',
                            style:
                                GoogleFonts.inter(fontSize: 11, color: _gray)),
                      ]),
                      const SizedBox(height: 6),

                      // Badges row
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        // Available / Offline
                        if (isOnline)
                          _badge(null, 'Available Today',
                              const Color(0xFFECFDF5), _green,
                              dotColor: _green)
                        else
                          _badge(null, 'Offline',
                              const Color(0xFFF1F5F9),
                              const Color(0xFF94A3B8),
                              dotColor: const Color(0xFF94A3B8)),

                        // Experience
                        _badgeIcon(Icons.work_outlined, '${vExp}yr Exp',
                            const Color(0xFFFFFBEB),
                            const Color(0xFFD97706)),

                        // Distance
                        if (distanceLabel.isNotEmpty)
                          _badgeIcon(Icons.location_on_rounded,
                              distanceLabel,
                              const Color(0xFFFFF7ED),
                              const Color(0xFFEA580C)),
                      ]),

                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => VendorProfileScreen(
                                    vendor: vendor, vendorId: vendorId)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _blue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text('View Profile',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _blue)),
                        ),
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
                delay: Duration(milliseconds: 60 * animIndex))
            .slideY(
                begin: 0.12,
                duration: 350.ms,
                delay: Duration(milliseconds: 60 * animIndex));
      },
    );
  }

  Widget _placeholder(String name) => Container(
        color: _blue.withValues(alpha: 0.1),
        child: Center(
          child: Text(name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _blue)),
        ),
      );

  Widget _badge(IconData? icon, String text, Color bg, Color fg,
      {Color? dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dotColor != null)
          Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
      ]),
    );
  }

  Widget _badgeIcon(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: fg),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
      ]),
    );
  }
}
