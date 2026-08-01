import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/all_professionals_screen.dart';
import '../screens/vendor_profile_screen.dart';

// ─── Color constants ─────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class TopRatedProfessionalsSection extends StatefulWidget {
  const TopRatedProfessionalsSection({super.key});

  @override
  State<TopRatedProfessionalsSection> createState() =>
      _TopRatedProfessionalsSectionState();
}

class _TopRatedProfessionalsSectionState
    extends State<TopRatedProfessionalsSection> {
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchUserPosition();
  }

  Future<void> _fetchUserPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  String _distanceLabel(Map<String, dynamic> v) {
    if (_userPosition == null) return '';
    final lat = (v['lat'] ?? v['latitude'] ?? v['location']?['lat']) as num?;
    final lng = (v['lng'] ?? v['longitude'] ?? v['location']?['lng']) as num?;
    if (lat == null || lng == null) return '';
    final dist = Geolocator.distanceBetween(
        _userPosition!.latitude, _userPosition!.longitude,
        lat.toDouble(), lng.toDouble());
    if (dist < 1000) return '${dist.toStringAsFixed(0)} m';
    return '${(dist / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top Rated Professionals',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _dark)),
                  const SizedBox(height: 3),
                  Text('Verified experts near your location',
                      style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AllProfessionalsScreen())),
                child: Row(
                  children: [
                    Text('See All',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _blue)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: _blue, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Cards list ──────────────────────────────────────────────────────
        SizedBox(
          height: 230,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vendors')
                .where('isApproved', isEqualTo: true)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snap) {
              // ── Loading state: shimmer skeletons ──────────────────────────
              if (snap.connectionState == ConnectionState.waiting) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, __) => const _SkeletonCard(),
                );
              }

              // ── Error state ───────────────────────────────────────────────
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: _gray, size: 36),
                      const SizedBox(height: 8),
                      Text('Could not load professionals',
                          style: GoogleFonts.inter(
                              color: _gray, fontSize: 13)),
                      TextButton(
                          onPressed: () => setState(() {}),
                          child: Text('Retry',
                              style: GoogleFonts.inter(
                                  color: _blue,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              }

              final docs = snap.data?.docs ?? [];
              final List<Map<String, dynamic>> vendors = docs.isEmpty
                  ? List.from(_fallback)
                  : docs.map((d) {
                      return {'id': d.id, ...(d.data() as Map<String, dynamic>)};
                    }).toList();

              vendors.sort((a, b) =>
                  ((b['averageRating'] ?? 0) as num)
                      .compareTo((a['averageRating'] ?? 0) as num));

              // ── Empty state ───────────────────────────────────────────────
              if (vendors.isEmpty) {
                return _EmptyState(
                  message: 'No professionals found\nin your area.',
                  onRetry: () => setState(() {}),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: vendors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, idx) => _VendorCard(
                  vendor: vendors[idx],
                  distanceLabel: _distanceLabel(vendors[idx]),
                  animIndex: idx,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Fallback demo data ───────────────────────────────────────────────────────
const _fallback = [
  {
    'id': 'v1',
    'fullName': 'Rahul Sharma',
    'businessName': 'CleanPro Services',
    'profilePhoto': 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop',
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
    'profilePhoto': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
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
    'profilePhoto': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
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

// ─── Skeleton card (shimmer-like) ─────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(46, 46, radius: 23),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(80, 12),
                const SizedBox(height: 6),
                _box(55, 10),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          _box(100, 10),
          const SizedBox(height: 8),
          _box(70, 10),
          const SizedBox(height: 8),
          _box(60, 10),
          const Spacer(),
          _box(double.infinity, 30, radius: 8),
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
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─── Empty state widget ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded,
                color: _blue, size: 32),
          ),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: _gray, height: 1.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text('Refresh',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _blue,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, duration: 400.ms);
  }
}

// ─── Vendor card ──────────────────────────────────────────────────────────────
class _VendorCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final String distanceLabel;
  final int animIndex;

  const _VendorCard({
    required this.vendor,
    required this.distanceLabel,
    required this.animIndex,
  });

  @override
  Widget build(BuildContext context) {
    final vId = vendor['id'] ?? '';
    final vName = vendor['fullName'] ?? vendor['name'] ?? 'Professional';
    final vPhoto = vendor['profilePhoto'] ?? vendor['photo'] ?? '';
    final vRating = ((vendor['averageRating'] ?? 5.0) as num).toDouble();
    final vReviews = (vendor['totalReviews'] ?? 0) as int;
    final vJobs = (vendor['completedBookings'] ?? 0) as int;
    final vExp = (vendor['yearsExperience'] ?? 1) as int;
    final vResponse = vendor['responseTime'] ?? '';
    final List<dynamic> vCats = vendor['categories'] ?? [];

    return StreamBuilder<DocumentSnapshot>(
      stream: vId.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('vendors')
              .doc(vId)
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
              builder: (_) =>
                  VendorProfileScreen(vendor: vendor, vendorId: vId),
            ),
          ),
          child: Container(
            width: 210,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar + name ───────────────────────────────────────────
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _border, width: 2)),
                          child: ClipOval(
                            child: vPhoto.startsWith('http')
                                ? Image.network(vPhoto,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _avatarPlaceholder(vName))
                                : _avatarPlaceholder(vName),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: _green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(vName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _dark)),
                            ),
                            const Icon(Icons.verified_rounded,
                                color: Colors.blue, size: 13),
                          ]),
                          if (vCats.isNotEmpty)
                            Text(vCats.first.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: _blue,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Rating ──────────────────────────────────────────────────
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 13),
                  const SizedBox(width: 3),
                  Text('$vRating',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _dark)),
                  Text('  ($vReviews reviews)',
                      style:
                          GoogleFonts.inter(fontSize: 10, color: _gray)),
                ]),
                const SizedBox(height: 4),

                // ── Experience ────────────────────────────────────────
                Row(children: [
                  const Icon(Icons.work_outline_rounded,
                      size: 11, color: _blue),
                  const SizedBox(width: 3),
                  Text('${vExp} years experience',
                      style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                ]),

                // ── Distance ─────────────────────────────────────────────────
                if (distanceLabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 11, color: _gray),
                    const SizedBox(width: 3),
                    Text(distanceLabel,
                        style:
                            GoogleFonts.inter(fontSize: 10, color: _gray)),
                  ]),
                ],

                const SizedBox(height: 6),

                // ── Available today badge ─────────────────────────────────────
                if (isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(7)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: _green, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Available Today',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: _green,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),

                const Spacer(),

                // ── View Profile button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VendorProfileScreen(
                              vendor: vendor, vendorId: vId)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                    child: Text('View Profile',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _blue)),
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
            .slideX(
                begin: 0.15,
                duration: 350.ms,
                delay: Duration(milliseconds: 60 * animIndex));
      },
    );
  }

  Widget _avatarPlaceholder(String name) => Container(
        color: _blue.withValues(alpha: 0.1),
        child: Center(
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _blue),
          ),
        ),
      );
}
