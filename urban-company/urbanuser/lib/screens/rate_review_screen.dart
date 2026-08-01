import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dashboard_screen.dart';
import 'my_bookings_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class RateReviewScreen extends StatefulWidget {
  final String bookingId;
  final String? vendorId;
  final String? vendorName;
  final String? serviceTitle;
  final String? coverImage;

  const RateReviewScreen({
    super.key,
    required this.bookingId,
    this.vendorId,
    this.vendorName,
    this.serviceTitle,
    this.coverImage,
  });

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _overallRating = 5;
  int _behaviourRating = 5;
  int _qualityRating = 5;
  int _punctualityRating = 5;
  int _communicationRating = 5;
  int _cleanlinessRating = 5;

  final TextEditingController _reviewController = TextEditingController();
  bool _wouldRecommend = true;
  bool _isAnonymous = false;
  String? _selectedIssue;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final List<String> _problemIssues = [
    'None',
    'Wrong Service',
    'Incomplete Work',
    'Poor Behaviour',
    'Damage',
    'Late Arrival',
    'Other',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitFullReview() async {
    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    final String vId = widget.vendorId ?? 'v1';
    final String vName = widget.vendorName ?? 'Rahul Sharma';
    final String sTitle = widget.serviceTitle ?? 'Deep Home Cleaning';

    try {
      // 1. Create Review Document
      await FirebaseFirestore.instance.collection('reviews').add({
        'bookingId': widget.bookingId,
        'vendorId': vId,
        'vendorName': vName,
        'serviceTitle': sTitle,
        'userId': user?.uid ?? 'guest_user',
        'userEmail': user?.email ?? 'guest@nexora.com',
        'customerName': _isAnonymous ? 'Anonymous' : (user?.displayName ?? 'Verified Customer'),
        'overallRating': _overallRating,
        'behaviourRating': _behaviourRating,
        'qualityRating': _qualityRating,
        'punctualityRating': _punctualityRating,
        'communicationRating': _communicationRating,
        'cleanlinessRating': _cleanlinessRating,
        'reviewText': _reviewController.text.trim(),
        'wouldRecommend': _wouldRecommend,
        'isAnonymous': _isAnonymous,
        'reportedIssue': _selectedIssue != 'None' ? _selectedIssue : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Recalculate Vendor Rating
      try {
        final vendorDoc = await FirebaseFirestore.instance.collection('vendors').doc(vId).get();
        if (vendorDoc.exists) {
          final data = vendorDoc.data()!;
          final int currTotal = (data['totalReviews'] ?? 0) as int;
          final double currAvg = ((data['averageRating'] ?? 5.0) as num).toDouble();
          final int newTotal = currTotal + 1;
          final double newAvg = ((currAvg * currTotal) + _overallRating) / newTotal;

          await FirebaseFirestore.instance.collection('vendors').doc(vId).update({
            'totalReviews': newTotal,
            'averageRating': double.parse(newAvg.toStringAsFixed(1)),
          });
        }
      } catch (_) {}

      // 3. Award 50 Reward Points
      try {
        if (user?.email != null) {
          await FirebaseFirestore.instance.collection('users').doc(user!.email).set({
            'rewardPoints': FieldValue.increment(50),
          }, SetOptions(merge: true));

          await FirebaseFirestore.instance.collection('reward_points').add({
            'userId': user.uid,
            'email': user.email,
            'points': 50,
            'type': 'earned',
            'description': 'Submitted review for ${widget.bookingId}',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}

      // 4. Notifications
      try {
        // Customer Notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Review Submitted! +50 Points',
          'body': 'Thank you for rating $vName. 50 Nexora Reward Points have been credited to your wallet.',
          'userId': user?.uid ?? 'guest_user',
          'type': 'reward',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Vendor Notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New ⭐ $_overallRating Star Review',
          'body': 'You received a new rating for $sTitle.',
          'userId': vId,
          'type': 'review',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vName = widget.vendorName ?? 'Rahul Sharma';
    final sTitle = widget.serviceTitle ?? 'Deep Home Cleaning';
    final img = widget.coverImage ??
        'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop';

    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_green, Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 52),
                )
                    .animate()
                    .scale(duration: 450.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 300.ms),

                const SizedBox(height: 24),
                Text('Review Submitted!', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 6),
                Text('Thank you for helping the Nexora community. You earned 50 Reward Points!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: _gray, height: 1.4)),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Text('+50 NEXORA POINTS CREDITED',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Return to Home', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      foregroundColor: _dark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('View Booking History', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Rate Your Experience',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Professional Summary Card ────────────────────────────────
                _cardWrapper(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(img),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(vName,
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: _blue, size: 16),
                              ],
                            ),
                            Text(sTitle, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                            Text('ID: ${widget.bookingId}', style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Overall Rating Selector ─────────────────────────────────
                _cardWrapper(
                  title: 'Overall Rating',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (starIdx) => IconButton(
                            icon: Icon(
                              starIdx < _overallRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 38,
                            ),
                            onPressed: () => setState(() => _overallRating = starIdx + 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _overallRating == 5
                            ? 'Excellent Service! ⭐⭐⭐⭐⭐'
                            : _overallRating == 4
                                ? 'Good Experience ⭐⭐⭐⭐'
                                : _overallRating == 3
                                    ? 'Average Service ⭐⭐⭐'
                                    : 'Needs Improvement ⭐⭐',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _blue),
                      ),
                    ],
                  ),
                ),

                // ── Detailed Category Ratings ────────────────────────────────
                _cardWrapper(
                  title: 'Rate Detailed Categories',
                  child: Column(
                    children: [
                      _starCategoryRow('Professional Behaviour', _behaviourRating, (val) => setState(() => _behaviourRating = val)),
                      _starCategoryRow('Service Quality', _qualityRating, (val) => setState(() => _qualityRating = val)),
                      _starCategoryRow('Punctuality', _punctualityRating, (val) => setState(() => _punctualityRating = val)),
                      _starCategoryRow('Communication', _communicationRating, (val) => setState(() => _communicationRating = val)),
                      _starCategoryRow('Cleanliness', _cleanlinessRating, (val) => setState(() => _cleanlinessRating = val)),
                    ],
                  ),
                ),

                // ── Write Review ─────────────────────────────────────────────
                _cardWrapper(
                  title: 'Write Your Feedback',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _reviewController,
                        maxLength: 1000,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Share your experience to help others make better decisions…',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _blue)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Would Recommend Toggle ───────────────────────────────────
                _cardWrapper(
                  title: 'Would you recommend this professional?',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _wouldRecommend = true),
                          icon: Icon(Icons.thumb_up_rounded, size: 16, color: _wouldRecommend ? Colors.white : _gray),
                          label: Text('Yes, Highly', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _wouldRecommend ? _green : Colors.transparent,
                            foregroundColor: _wouldRecommend ? Colors.white : _dark,
                            side: BorderSide(color: _wouldRecommend ? _green : _border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _wouldRecommend = false),
                          icon: Icon(Icons.thumb_down_rounded, size: 16, color: !_wouldRecommend ? Colors.white : _gray),
                          label: Text('No', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !_wouldRecommend ? Colors.red : Colors.transparent,
                            foregroundColor: !_wouldRecommend ? Colors.white : _dark,
                            side: BorderSide(color: !_wouldRecommend ? Colors.red : _border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Report Issue (Optional) ─────────────────────────────────
                _cardWrapper(
                  title: 'Report Problem (Optional)',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _problemIssues.map((issue) {
                      final bool isSel = _selectedIssue == issue || (_selectedIssue == null && issue == 'None');
                      return ChoiceChip(
                        label: Text(issue),
                        selected: isSel,
                        selectedColor: isSel && issue != 'None' ? Colors.red.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? (issue != 'None' ? Colors.red : _blue) : _gray,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedIssue = issue);
                        },
                      );
                    }).toList(),
                  ),
                ),

                // ── Anonymous Review Switch ─────────────────────────────────
                _cardWrapper(
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_off_rounded, color: _gray, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Post Review Anonymously', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                            Text('Hide customer name from public profile reviews.', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAnonymous,
                        activeTrackColor: _blue,
                        onChanged: (val) => setState(() => _isAnonymous = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Bottom Submit Button ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _border),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFullReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Submit Review & Earn 50 Pts', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardWrapper({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _starCategoryRow(String label, int currentVal, ValueChanged<int> onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: _gray, fontWeight: FontWeight.w600)),
          Row(
            children: List.generate(
              5,
              (idx) => GestureDetector(
                onTap: () => onSelect(idx + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    idx < currentVal ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
