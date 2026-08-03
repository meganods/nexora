import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';
import 'schedule_booking_screen.dart';
import 'vendor_profile_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    _recordRecentlyViewed();
  }

  void _recordRecentlyViewed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String docId = "${user.uid}_${widget.service.id}";
        await FirebaseFirestore.instance.collection('recently_viewed').doc(docId).set({
          'userId': user.uid,
          'userEmail': user.email,
          'serviceId': widget.service.id,
          'title': widget.service.title,
          'category': widget.service.category,
          'price': widget.service.price,
          'rating': widget.service.rating,
          'totalReviews': widget.service.totalReviews,
          'image': widget.service.image,
          'viewedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error recording recently viewed service: $e");
    }
  }

  final List<Map<String, dynamic>> _selectedSubServices = [];
  final List<Map<String, dynamic>> _selectedAddons = [];
  int _activeImageIndex = 0;

  final List<Map<String, String>> _mockFaqs = [
    {
      'question': 'How long does this service take?',
      'answer': 'Typically the service is completed within 2 to 3 hours depending on the scale and custom client preferences.'
    },
    {
      'question': 'Are the cleaning materials safe for pets?',
      'answer': 'Yes, we only utilize certified, eco-friendly, and non-toxic materials completely safe for pets and children.'
    },
    {
      'question': 'What if I am not satisfied with the quality?',
      'answer': 'Nexora provides a 100% satisfaction guarantee. If anything is missed, we will dispatch a technician to resolve it free of charge.'
    }
  ];

  final List<Map<String, dynamic>> _fallbackSubServices = [
    {
      'id': 'sub1',
      'title': 'Deep Scrubbing & Floor Polishing',
      'price': 299.0,
      'duration': '45 mins',
      'description': 'Heavy scrubbing of floors and polishing to restore natural tiles glow.'
    },
    {
      'id': 'sub2',
      'title': 'Window & Glass Panel Wash',
      'price': 199.0,
      'duration': '30 mins',
      'description': 'Streak-free chemical cleaning of all interior and exterior glass panels.'
    }
  ];

  final List<Map<String, dynamic>> _fallbackAddons = [
    {
      'id': 'add1',
      'title': 'Inside Fridge Cleaning',
      'price': 199.0,
      'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=300&auto=format&fit=crop',
    },
    {
      'id': 'add2',
      'title': 'Balcony & Window Scrubbing',
      'price': 299.0,
      'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
    }
  ];

  final List<Map<String, dynamic>> _fallbackReviews = [
    {
      'id': 'rev1',
      'customerName': 'Vishal Malhotra',
      'customerPhoto': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
      'rating': 5,
      'comment': 'The service was absolutely spotless. The team cleaned all hard-to-reach places professionally.',
      'date': '2 weeks ago',
    },
    {
      'id': 'rev2',
      'customerName': 'Neha Kapoor',
      'customerPhoto': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop',
      'rating': 5,
      'comment': 'Exceptionally skilled professional. Highly recommended for AC Deep Cleaning packages!',
      'date': '1 month ago',
    }
  ];

  String _getServiceImage(String category, String originalImage) {
    if (originalImage.startsWith('http')) return originalImage;
    final cat = category.toLowerCase();
    if (cat.contains('clean')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop';
    } else if (cat.contains('ac') || cat.contains('repair') || cat.contains('plumb') || cat.contains('electrical')) {
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop';
    } else if (cat.contains('salon') || cat.contains('beauty') || cat.contains('spa')) {
      return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=300&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop';
  }

  @override
  Widget build(BuildContext context) {
    final imageList = widget.service.images.isNotEmpty
        ? widget.service.images
        : [widget.service.image];

    final double basePrice = widget.service.price;
    final double subtotal = _selectedSubServices.fold(0.0, (sum, item) => sum + (item['price'] as double));
    final double addonsTotal = _selectedAddons.fold(0.0, (sum, item) => sum + (item['price'] as double));
    final double totalPrice = basePrice + subtotal + addonsTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero Banner Carousel ──────────────────────────────────────
                Stack(
                  children: [
                    SizedBox(
                      height: 280,
                      child: PageView.builder(
                        itemCount: imageList.length,
                        onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                        itemBuilder: (ctx, idx) {
                          final img = _getServiceImage(widget.service.category, imageList[idx]);
                          return Hero(
                            tag: 'service_img_${widget.service.id}',
                            child: Image.network(
                              img,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: Icon(Icons.handyman_rounded, color: _blue, size: 48),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Header Navigation
                    Positioned(
                      top: 48,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 48,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.share_rounded, color: _dark, size: 20),
                          onPressed: () {},
                        ),
                      ),
                    ),
                    // Indicators
                    if (imageList.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            imageList.length,
                            (idx) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _activeImageIndex == idx ? _blue : Colors.white60,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Service Information Details ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(widget.service.category.toUpperCase(),
                                  style: GoogleFonts.inter(
                                      color: _blue, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                children: [
                                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text('Available Today',
                                      style: GoogleFonts.inter(
                                          fontSize: 9, color: _green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(widget.service.title,
                            style: GoogleFonts.inter(
                                fontSize: 20, fontWeight: FontWeight.bold, color: _dark, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 3),
                            Text('${widget.service.rating}',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                            Text(' (${widget.service.totalReviews} reviews)',
                                style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                            const SizedBox(width: 8),
                            Container(width: 1.5, height: 12, color: _border),
                            const SizedBox(width: 8),
                            const Icon(Icons.timer_outlined, size: 12, color: _gray),
                            const SizedBox(width: 3),
                            Text(widget.service.duration.isNotEmpty ? widget.service.duration : '2 hrs',
                                style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── About Service ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About Service',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                        const SizedBox(height: 10),
                        Text(
                          widget.service.description.isNotEmpty
                              ? widget.service.description
                              : 'High-quality professional home deep cleaning service designed to keep your home healthy, sanitized and sparkling clean. Includes all floor cleaning, sanitization, and dust removal.',
                          style: GoogleFonts.inter(fontSize: 13, color: _gray, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('What\'s Included',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                                  const SizedBox(height: 6),
                                  _bullet('✓ All chemical cleaners'),
                                  _bullet('✓ Complete tools & vacuums'),
                                  _bullet('✓ Floor polishing scrubbing'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('What\'s Not Included',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                                  const SizedBox(height: 6),
                                  _bullet('✗ Cleaning of outside walls'),
                                  _bullet('✗ Washing of personal items'),
                                  _bullet('✗ Moving heavy furniture'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Available Sub Services ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Sub Services',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('sub_services')
                            .where('serviceId', isEqualTo: widget.service.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final List<Map<String, dynamic>> subServices = docs.isEmpty
                              ? _fallbackSubServices
                              : docs.map((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  return {
                                    'id': doc.id,
                                    'title': d['name'] ?? d['title'] ?? 'Sub Service Item',
                                    'price': ((d['price'] ?? 0) as num).toDouble(),
                                    'duration': d['duration'] ?? '1 hr',
                                    'description': d['description'] ?? '',
                                  };
                                }).toList();

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: subServices.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final sub = subServices[idx];
                              final isSelected = _selectedSubServices.any((element) => element['id'] == sub['id']);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? _blue : _border, width: isSelected ? 1.5 : 1.0),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(sub['title'],
                                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                                          const SizedBox(height: 4),
                                          Text('${sub['duration']} · ₹${sub['price'].toStringAsFixed(0)}',
                                              style: GoogleFonts.inter(fontSize: 12, color: _blue, fontWeight: FontWeight.bold)),
                                          if (sub['description'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(sub['description'],
                                                style: GoogleFonts.inter(fontSize: 11, color: _gray, height: 1.3)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedSubServices.removeWhere((element) => element['id'] == sub['id']);
                                          } else {
                                            _selectedSubServices.add(sub);
                                          }
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected ? _blue : const Color(0xFFEFF6FF),
                                        foregroundColor: isSelected ? Colors.white : _blue,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      child: Text(isSelected ? 'Selected' : 'Add',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Add-ons ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Optional Add-ons',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _fallbackAddons.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final add = _fallbackAddons[idx];
                          final isSelected = _selectedAddons.any((element) => element['id'] == add['id']);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? _blue : _border),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    add['image'] ?? '',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      width: 50,
                                      height: 50,
                                      color: const Color(0xFFF1F5F9),
                                      child: const Icon(Icons.add_task_rounded, color: _blue, size: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(add['title'],
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                                      const SizedBox(height: 3),
                                      Text('+ ₹${add['price'].toStringAsFixed(0)}',
                                          style: GoogleFonts.inter(fontSize: 12, color: _blue, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: isSelected,
                                  activeColor: _blue,
                                  onChanged: (v) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedAddons.removeWhere((element) => element['id'] == add['id']);
                                      } else {
                                        _selectedAddons.add(add);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Professional Information Details ──────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Professional assigned for service',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _gray)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: const NetworkImage(
                                  'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                          widget.service.vendorName.isNotEmpty
                                              ? widget.service.vendorName
                                              : 'Rahul Sharma',
                                          style: GoogleFonts.inter(
                                              fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('5 Years Experience · English, Hindi',
                                      style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 3),
                                Text('4.9',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                                Text(' (1,280 reviews)', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                              ],
                            ),
                            Text('2,750 Jobs Done',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: _gray, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => VendorProfileScreen(
                                        vendor: {
                                          'fullName': widget.service.vendorName.isNotEmpty
                                              ? widget.service.vendorName
                                              : 'Rahul Sharma',
                                          'businessName': 'CleanPro Services',
                                          'averageRating': 4.9,
                                          'totalReviews': 1280,
                                          'completedBookings': 2750,
                                          'yearsExperience': 5,
                                        },
                                        vendorId: widget.service.vendorId.isNotEmpty
                                            ? widget.service.vendorId
                                            : 'v1')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('View Professional Profile',
                                style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Customer Reviews Section ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Reviews',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('serviceId', isEqualTo: widget.service.id)
                            .snapshots(),
                        builder: (ctx, snap) {
                          final docs = snap.data?.docs ?? [];
                          final List<Map<String, dynamic>> reviews = docs.isEmpty
                              ? _fallbackReviews
                              : docs.map((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  return {
                                    'id': doc.id,
                                    'customerName': d['customerName'] ?? 'Verified Customer',
                                    'customerPhoto': d['customerPhoto'] ?? '',
                                    'rating': d['rating'] ?? 5,
                                    'comment': d['comment'] ?? '',
                                    'date': 'Recently',
                                  };
                                }).toList();

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final rev = reviews[idx];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: rev['customerPhoto'].toString().isNotEmpty
                                              ? NetworkImage(rev['customerPhoto'])
                                              : null,
                                          child: rev['customerPhoto'].toString().isEmpty
                                              ? Text(rev['customerName'].toString().substring(0, 1).toUpperCase())
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(rev['customerName'],
                                                  style: GoogleFonts.inter(
                                                      fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                                              Text(rev['date'],
                                                  style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                              5,
                                              (i) => Icon(
                                                    i < (rev['rating'] as int)
                                                        ? Icons.star_rounded
                                                        : Icons.star_outline_rounded,
                                                    color: Colors.amber,
                                                    size: 12,
                                                  )),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(rev['comment'],
                                        style: GoogleFonts.inter(fontSize: 12, color: _dark, height: 1.4)),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── FAQ Accordion Section ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frequently Asked Questions',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                      const SizedBox(height: 12),
                      Column(
                        children: _mockFaqs.map((faq) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                faq['question']!,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _dark),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(
                                    faq['answer']!,
                                    style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 110),
              ],
            ),
          ),

          // ── Sticky Bottom Bar ───────────────────────────────────────────────
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
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TOTAL PRICE',
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: _gray,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('₹${totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w900, color: _blue)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final List<Map<String, dynamic>> combinedSelectedItems = [
                        ..._selectedSubServices,
                        ..._selectedAddons
                      ];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleBookingScreen(
                            service: widget.service,
                            selectedItems: combinedSelectedItems,
                            totalPrice: totalPrice,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Book Now',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
    );
  }
}
