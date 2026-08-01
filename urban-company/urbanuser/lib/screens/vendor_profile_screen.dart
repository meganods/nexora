import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';
import 'chat_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class VendorProfileScreen extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final String vendorId;

  const VendorProfileScreen({
    super.key,
    required this.vendor,
    required this.vendorId,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  bool _isLiked = false;

  final List<String> _portfolioImages = [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=400&auto=format&fit=crop',
  ];

  final List<Map<String, dynamic>> _fallbackServices = [
    {
      'id': 's1',
      'name': 'Deep Home Cleaning',
      'category': 'Cleaning',
      'startingPrice': 799.0,
      'duration': '3–4 hrs',
      'rating': 4.9,
      'totalReviews': 1284,
      'coverImage': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
    },
    {
      'id': 's2',
      'name': 'Kitchen Sanitization & Scrub',
      'category': 'Cleaning',
      'startingPrice': 499.0,
      'duration': '2 hrs',
      'rating': 4.8,
      'totalReviews': 560,
      'coverImage': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=300&auto=format&fit=crop',
    },
  ];

  final List<Map<String, dynamic>> _fallbackReviews = [
    {
      'id': 'r1',
      'customerName': 'Vishal Malhotra',
      'customerPhoto': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
      'rating': 5,
      'comment': 'Outstanding work. Rahul arrived on time and cleaned every corner with extreme care. Highly recommend!',
      'date': '2 weeks ago',
    },
    {
      'id': 'r2',
      'customerName': 'Neha Kapoor',
      'customerPhoto': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop',
      'rating': 5,
      'comment': 'Punctual, professional, and very polite. Left our house sparkling clean.',
      'date': '1 month ago',
    },
  ];

  void _showImageDialog(String imgUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imgUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDisabledNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Direct contact is available after confirming an active booking.',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.vendor['fullName'] ?? widget.vendor['name'] ?? 'Professional';
    final String business = widget.vendor['businessName'] ?? '';
    final String photo = widget.vendor['profilePhoto'] ?? widget.vendor['photo'] ?? '';
    final double rating = ((widget.vendor['averageRating'] ?? widget.vendor['rating'] ?? 5.0) as num).toDouble();
    final int reviews = (widget.vendor['totalReviews'] ?? widget.vendor['reviews'] ?? 1280) as int;
    final int jobs = (widget.vendor['completedBookings'] ?? widget.vendor['completedJobs'] ?? 2750) as int;
    final int experience = (widget.vendor['yearsExperience'] ?? widget.vendor['experience'] ?? 5) as int;
    final String about = widget.vendor['about'] ?? widget.vendor['description'] ??
        'Experienced and verified service expert providing top-notch home cleaning, sanitization, and maintenance solutions with 100% satisfaction guarantee.';
    final List<dynamic> categories = widget.vendor['categories'] ?? ['Home Cleaning', 'Sanitization'];
    final bool isOnline = widget.vendor['isOnline'] == true;

    return StreamBuilder<DocumentSnapshot>(
      stream: widget.vendorId.isNotEmpty
          ? FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).snapshots()
          : null,
      builder: (ctx, snap) {
        bool liveOnline = isOnline;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          liveOnline = d['isOnline'] == true;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Hero App Bar ──────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    backgroundColor: _blue,
                    elevation: 0,
                    leading: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 16),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isLiked ? Colors.red : _dark,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _isLiked = !_isLiked),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: const Icon(Icons.share_rounded, color: _dark, size: 18),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover Gradient Banner
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_blue, Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Avatar & Vendor Details
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                                      ),
                                      child: ClipOval(
                                        child: photo.startsWith('http')
                                            ? Image.network(photo, fit: BoxFit.cover)
                                            : Container(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                child: Center(
                                                  child: Text(
                                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
                                                    style: GoogleFonts.inter(
                                                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (liveOnline)
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: _green,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 18),
                                        ],
                                      ),
                                      if (business.isNotEmpty)
                                        Text(
                                          business,
                                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                                        ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: liveOnline
                                              ? _green.withValues(alpha: 0.9)
                                              : Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          liveOnline ? 'ONLINE NOW' : 'OFFLINE',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Scrollable Body ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Quick Statistics Row ─────────────────────────────
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem('⭐ $rating', '$reviews reviews'),
                              _vDivider(),
                              _statItem('${experience} yrs', 'Experience'),
                              _vDivider(),
                              _statItem('99%', 'Response Rate'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Verification Badges & Achievements ────────────────
                        _cardWrapper(
                          title: 'Verification & Achievements',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _achievementBadge(Icons.verified_user_rounded, 'Background Verified', const Color(0xFFEFF6FF), _blue),
                              _achievementBadge(Icons.workspace_premium_rounded, 'Top Rated Pro', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
                              _achievementBadge(Icons.check_circle_rounded, 'Govt ID Verified', const Color(0xFFECFDF5), _green),
                              _achievementBadge(Icons.shield_rounded, 'Skill Certified', const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
                            ],
                          ),
                        ),

                        // ── Vendor Information ────────────────────────────────
                        _cardWrapper(
                          title: 'About Professional',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(about, style: GoogleFonts.inter(fontSize: 13, color: _gray, height: 1.5)),
                              const SizedBox(height: 14),
                              const Divider(color: _border),
                              const SizedBox(height: 10),
                              _infoRow(Icons.language_rounded, 'Languages', 'English, Hindi'),
                              const SizedBox(height: 8),
                              _infoRow(Icons.access_time_rounded, 'Working Hours', 'Mon - Sat (08:00 AM - 08:00 PM)'),
                              const SizedBox(height: 8),
                              _infoRow(Icons.location_on_outlined, 'Service Areas', 'Noida, Delhi NCR, Ghaziabad, Greater Noida'),
                            ],
                          ),
                        ),

                        // ── Specializations / Categories ─────────────────────
                        if (categories.isNotEmpty)
                          _cardWrapper(
                            title: 'Categories & Specializations',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories
                                  .map((cat) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: _blue.withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          cat.toString(),
                                          style: GoogleFonts.inter(fontSize: 12, color: _blue, fontWeight: FontWeight.bold),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),

                        // ── Services Offered ──────────────────────────────────
                        _cardWrapper(
                          title: 'Services Offered',
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('services')
                                .where('vendorId', isEqualTo: widget.vendorId)
                                .where('status', isEqualTo: 'Approved')
                                .snapshots(),
                            builder: (ctx, sSnap) {
                              final docs = sSnap.data?.docs ?? [];
                              final List<Map<String, dynamic>> services = docs.isEmpty
                                  ? _fallbackServices
                                  : docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: services.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, i) {
                                  final s = services[i];
                                  final sTitle = s['name'] ?? s['serviceName'] ?? 'Service';
                                  final sPrice = ((s['startingPrice'] ?? s['price'] ?? 0) as num).toDouble();
                                  final sDuration = s['duration'] ?? '2 hrs';
                                  final sImg = s['coverImage'] ?? s['image'] ?? '';

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: sImg.startsWith('http')
                                              ? Image.network(sImg, width: 64, height: 64, fit: BoxFit.cover)
                                              : Container(
                                                  width: 64,
                                                  height: 64,
                                                  color: _blue.withValues(alpha: 0.1),
                                                  child: const Icon(Icons.handyman_rounded, color: _blue),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(sTitle,
                                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                                              const SizedBox(height: 3),
                                              Text(sDuration, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                                              const SizedBox(height: 3),
                                              Text('₹${sPrice.toStringAsFixed(0)}',
                                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _blue)),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            final model = ServiceModel(
                                              id: s['id'] ?? '',
                                              title: sTitle,
                                              price: sPrice,
                                              image: sImg,
                                              vendorId: widget.vendorId,
                                              vendorName: name,
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
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: Text('Book', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // ── Portfolio / Completed Work Photos ──────────────────
                        _cardWrapper(
                          title: 'Work Portfolio',
                          child: SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _portfolioImages.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (ctx, idx) {
                                return GestureDetector(
                                  onTap: () => _showImageDialog(_portfolioImages[idx]),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _portfolioImages[idx],
                                      width: 120,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // ── Customer Reviews ──────────────────────────────────
                        _cardWrapper(
                          title: 'Customer Reviews',
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('vendor_reviews')
                                .where('vendorId', isEqualTo: widget.vendorId)
                                .snapshots(),
                            builder: (ctx, rSnap) {
                              final docs = rSnap.data?.docs ?? [];
                              final List<Map<String, dynamic>> reviewsList = docs.isEmpty
                                  ? _fallbackReviews
                                  : docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviewsList.length,
                                separatorBuilder: (_, __) => const Divider(color: _border, height: 24),
                                itemBuilder: (ctx, i) {
                                  final r = reviewsList[i];
                                  final cName = r['customerName'] ?? 'Customer';
                                  final cPhoto = r['customerPhoto'] ?? '';
                                  final rRating = ((r['rating'] ?? 5) as num).toInt();
                                  final rComment = r['comment'] ?? '';
                                  final rDate = r['date'] ?? 'Recently';

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _blue.withValues(alpha: 0.1),
                                        backgroundImage: cPhoto.toString().isNotEmpty ? NetworkImage(cPhoto) : null,
                                        child: cPhoto.toString().isEmpty
                                            ? Text(cName.substring(0, 1).toUpperCase(),
                                                style: GoogleFonts.inter(color: _blue, fontWeight: FontWeight.bold))
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(cName,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                                                const Spacer(),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (starIdx) => Icon(
                                                      starIdx < rRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                                      color: Colors.amber,
                                                      size: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(rDate, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                                            const SizedBox(height: 6),
                                            Text(rComment,
                                                style: GoogleFonts.inter(fontSize: 12, color: _dark, height: 1.4)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // ── Direct Contact Actions ────────────────────────────
                        _cardWrapper(
                          title: 'Contact Professional',
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showContactDisabledNotice,
                                  icon: const Icon(Icons.call_rounded, size: 16),
                                  label: Text('Call', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: _border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final myEmail = FirebaseAuth.instance.currentUser?.email ?? 'guest';
                                    final vendorEmail = widget.vendor['email'] ?? widget.vendor['ownerEmail'] ?? widget.vendorId;
                                    final chatId = 'chat_${myEmail.replaceAll('.', '_')}_${vendorEmail.replaceAll('.', '_')}';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: chatId,
                                          recipientId: vendorEmail,
                                          recipientName: name,
                                          isVendorApp: false,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                  label: Text('Chat', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: _border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Sticky Bottom Bar ───────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: _border),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('VERIFIED EXPERT',
                              style: GoogleFonts.inter(
                                  fontSize: 8, fontWeight: FontWeight.bold, color: _green, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to first available service or service details
                          final model = ServiceModel(
                            id: 's1',
                            title: 'Deep Home Cleaning',
                            price: 799.0,
                            vendorId: widget.vendorId,
                            vendorName: name,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: model)),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: Text('Book Service', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardWrapper({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark, letterSpacing: -0.2)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
      ],
    );
  }

  Widget _achievementBadge(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: fg, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _gray),
        const SizedBox(width: 8),
        Text('$title: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
        Expanded(child: Text(val, style: GoogleFonts.inter(fontSize: 12, color: _gray))),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 32, color: _border);
}
