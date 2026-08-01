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

class ServiceCompletedScreen extends StatefulWidget {
  final String bookingId;

  const ServiceCompletedScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<ServiceCompletedScreen> createState() => _ServiceCompletedScreenState();
}

class _ServiceCompletedScreenState extends State<ServiceCompletedScreen> {
  int _userRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;
  bool _reviewSubmitted = false;

  final List<String> _beforePhotos = [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=300&auto=format&fit=crop',
  ];

  final List<String> _afterPhotos = [
    'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?q=80&w=300&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
  ];

  void _showImageDialog(String imgUrl, String label) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imgUrl, fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                  child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
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

  void _downloadInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Digital PDF Invoice for ${widget.bookingId} downloaded!',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitReview(String vendorId, String serviceTitle) async {
    if (_reviewController.text.trim().isEmpty) return;

    setState(() => _isSubmittingReview = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('reviews').add({
        'bookingId': widget.bookingId,
        'vendorId': vendorId,
        'serviceTitle': serviceTitle,
        'userId': user?.uid ?? 'guest_user',
        'customerName': user?.displayName ?? 'Verified Customer',
        'rating': _userRating,
        'comment': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmittingReview = false;
        _reviewSubmitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you! Your review has been submitted successfully.',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bId = widget.bookingId;
    final txnId = 'TXN-${100000 + (bId.hashCode % 899999).abs()}';
    final invId = 'INV-2026-${(bId.hashCode % 8999).abs()}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service Completed', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            Text(bId, style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: _dark, size: 20),
            onPressed: _downloadInvoice,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bId)
            .snapshots(),
        builder: (context, snap) {
          Map<String, dynamic> bData = {};
          if (snap.hasData && snap.data!.exists) {
            bData = snap.data!.data() as Map<String, dynamic>;
          }

          final String title = bData['shopName'] ?? bData['serviceName'] ?? 'Deep Home Cleaning';
          final String dateStr = bData['date'] ?? 'Today';
          final String timeStr = bData['time'] ?? '10:00 AM – 12:00 PM';
          final String vendorName = bData['vendorName'] ?? 'Rahul Sharma';
          final String vendorId = bData['vendorId'] ?? 'v1';
          final double rawAmount = ((bData['rawAmount'] ?? 799.0) as num).toDouble();

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                child: Column(
                  children: [
                    // ── Success Checkmark Animation Banner ───────────────────
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_green, Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 48),
                    )
                        .animate()
                        .scale(duration: 450.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),
                    Text('Service Completed Successfully!',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
                    const SizedBox(height: 4),
                    Text('Thank you for choosing Nexora. Your service has been verified.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.4)),

                    const SizedBox(height: 24),

                    // ── Booking Summary Card ─────────────────────────────────
                    _cardWrapper(
                      title: 'Booking Summary',
                      child: Column(
                        children: [
                          _infoRow(Icons.tag_rounded, 'Booking ID', bId),
                          const SizedBox(height: 8),
                          _infoRow(Icons.handyman_rounded, 'Service Delivered', title),
                          const SizedBox(height: 8),
                          _infoRow(Icons.person_outline_rounded, 'Assigned Professional', vendorName),
                          const SizedBox(height: 8),
                          _infoRow(Icons.calendar_month_rounded, 'Completed Date', dateStr),
                          const SizedBox(height: 8),
                          _infoRow(Icons.access_time_rounded, 'Slot', timeStr),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: _green),
                              const SizedBox(width: 8),
                              Text('Status: ', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                child: Text('COMPLETED',
                                    style: GoogleFonts.inter(fontSize: 9, color: _green, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Before & After Work Gallery ──────────────────────────
                    _cardWrapper(
                      title: 'Service Verification Photos',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BEFORE SERVICE',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _gray, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _beforePhotos.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (ctx, i) => GestureDetector(
                                onTap: () => _showImageDialog(_beforePhotos[i], 'Before Photo ${i + 1}'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_beforePhotos[i], width: 100, height: 80, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text('AFTER SERVICE (COMPLETED)',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _green, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _afterPhotos.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (ctx, i) => GestureDetector(
                                onTap: () => _showImageDialog(_afterPhotos[i], 'After Photo ${i + 1}'),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_afterPhotos[i], width: 100, height: 80, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Digital Invoice & Payment Summary ─────────────────────
                    _cardWrapper(
                      title: 'Digital Invoice & Payment Details',
                      child: Column(
                        children: [
                          _infoRow(Icons.receipt_rounded, 'Invoice Number', invId),
                          const SizedBox(height: 8),
                          _infoRow(Icons.tag_rounded, 'Transaction ID', txnId),
                          const SizedBox(height: 8),
                          _infoRow(Icons.payment_rounded, 'Payment Method', 'Online (Paid)'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: _border),
                          ),
                          _priceRow('Service Base Amount', '₹${rawAmount.toStringAsFixed(0)}'),
                          const SizedBox(height: 6),
                          _priceRow('Platform & Safety Fee', '₹29'),
                          const SizedBox(height: 6),
                          _priceRow('Taxes & GST (18%)', '₹52'),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Paid', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                              Text('₹${(rawAmount + 81).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: _blue)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _downloadInvoice,
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.red),
                              label: Text('Download Digital PDF Invoice',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
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

                    // ── Settlement Status Notice Card ────────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ADMIN VERIFICATION & SETTLEMENT PENDING',
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFB45309), letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text('Service payout to $vendorName remains safely held in Nexora Escrow until quality audit completes.',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), height: 1.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Rate & Review Card ────────────────────────────────────
                    _cardWrapper(
                      title: 'Rate & Review Your Experience',
                      child: _reviewSubmitted
                          ? Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: _green, size: 20),
                                  const SizedBox(width: 10),
                                  Text('Review submitted! Thank you for your feedback.',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    5,
                                    (idx) => IconButton(
                                      icon: Icon(
                                        idx < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: Colors.amber,
                                        size: 32,
                                      ),
                                      onPressed: () => setState(() => _userRating = idx + 1),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _reviewController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Share your feedback about $vendorName…',
                                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                                    fillColor: const Color(0xFFF8FAFC),
                                    filled: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmittingReview ? null : () => _submitReview(vendorId, title),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _blue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: _isSubmittingReview
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text('Submit Review', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              // ── Sticky Bottom Action Bar ────────────────────────────────────
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
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _border),
                            foregroundColor: _dark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Booking History', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Book Again', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardWrapper({required String title, required Widget child}) {
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
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _gray),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
        Expanded(
          child: Text(val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
        Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
      ],
    );
  }
}
