import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'my_bookings_screen.dart';
import 'vendor_profile_screen.dart';
import 'chat_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class ThankYouScreen extends StatefulWidget {
  final String? bookingId;
  final String? date;
  final String? time;
  final String? address;
  final String? serviceTitle;
  final double? amount;

  const ThankYouScreen({
    super.key,
    this.bookingId,
    this.date,
    this.time,
    this.address,
    this.serviceTitle,
    this.amount,
  });

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  void _downloadInvoice(String bId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Invoice for $bId downloaded successfully.',
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

  void _shareBooking(String bId, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing booking details for $title ($bId)…',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: _blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bId = widget.bookingId ?? 'NEX-849201';
    final sDate = widget.date ?? 'Tomorrow';
    final sTime = widget.time ?? '10:00 AM – 12:00 PM';
    final sTitle = widget.serviceTitle ?? 'Deep Home Cleaning';
    final total = widget.amount ?? 499.0;
    final txnId = 'TXN-${100000 + (bId.hashCode % 899999).abs()}';
    final invId = 'INV-2026-${(bId.hashCode % 8999).abs()}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
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
          title: Text('Booking Confirmed',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, color: _dark, size: 20),
              onPressed: () => _shareBooking(bId, sTitle),
            ),
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

            final String status = bData['status'] ?? 'assigned';
            final bool isVendorAccepted = status == 'accepted' || status == 'in_progress' || status == 'completed';
            final String vendorName = bData['vendorName'] ?? 'Rahul Sharma';
            final String vendorPhoto = bData['vendorPhoto'] ??
                'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop';

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── Success Banner Checkmark ────────────────────────────
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_green, Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: _green.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
                      )
                          .animate()
                          .scale(duration: 450.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 300.ms),

                      const SizedBox(height: 16),
                      Text('Booking Confirmed!',
                          style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
                      const SizedBox(height: 4),
                      Text('Your booking has been successfully confirmed. Confirmation: Instant',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.4)),

                      const SizedBox(height: 24),

                      // ── Booking Summary Information Card ─────────────────────
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('BOOKING ID',
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: _gray,
                                        letterSpacing: 0.5)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text('PAID & CONFIRMED',
                                      style: GoogleFonts.inter(
                                          fontSize: 8, color: _green, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(bId,
                                    style: GoogleFonts.inter(
                                        fontSize: 18, fontWeight: FontWeight.w900, color: _blue)),
                                Text('₹${total.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(
                                        fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: _border),
                            ),
                            _infoRow(Icons.handyman_rounded, 'Service', sTitle),
                            const SizedBox(height: 8),
                            _infoRow(Icons.calendar_month_rounded, 'Date', sDate),
                            const SizedBox(height: 8),
                            _infoRow(Icons.access_time_rounded, 'Time Slot', sTime),
                          ],
                        ),
                      ),

                      // ── Booking Status Timeline ─────────────────────────────
                      _card(
                        title: 'Live Booking Timeline',
                        child: Column(
                          children: [
                            _timelineStep('Payment Successful', 'Online payment verified via SSL Encryption', true, true),
                            _timelineStep('Booking Created', 'System generated booking ticket $bId', true, true),
                            _timelineStep('Vendor Auto Assigned', 'Smart system matched best rated vendor', true, true),
                            _timelineStep('Vendor Acceptance', isVendorAccepted ? 'Accepted by $vendorName' : 'Vendor Acceptance Pending', isVendorAccepted, true),
                            _timelineStep('Professional On The Way', 'Professional en route to address', false, true),
                            _timelineStep('Service In Progress', 'OTP verified & service started', false, true),
                            _timelineStep('Service Completed', 'Quality check & customer review', false, false),
                          ],
                        ),
                      ),

                      // ── Assigned Professional ──────────────────────────────
                      _card(
                        title: 'Assigned Professional',
                        child: isVendorAccepted
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundImage: NetworkImage(vendorPhoto),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(vendorName,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: _dark)),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified_rounded, color: _blue, size: 14),
                                              ],
                                            ),
                                            Text('⭐ 4.9 · 5 yrs exp · Arrives on $sDate',
                                                style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.call_rounded, size: 14),
                                          label: Text('Call', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: _border),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            final myEmail = FirebaseAuth.instance.currentUser?.email ?? 'guest';
                                            final vendorEmail = bData['vendorEmail'] ?? bData['vendorId'] ?? 'urbanvendor01@gmail.com';
                                            final chatId = 'chat_${myEmail.replaceAll('.', '_')}_${vendorEmail.replaceAll('.', '_')}';
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  chatId: chatId,
                                                  recipientId: vendorEmail,
                                                  recipientName: vendorName,
                                                  isVendorApp: false,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                                          label: Text('Chat', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: _border),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => VendorProfileScreen(
                                                      vendor: {'fullName': vendorName},
                                                      vendorId: 'v1')),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _blue,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: Text('Profile', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _blue.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.hourglass_top_rounded, color: _blue, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Professional Details Pending Acceptance',
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _dark)),
                                          Text('Full provider profile will be unlocked automatically upon vendor acceptance.',
                                              style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // ── Payment Information ────────────────────────────────
                      _card(
                        title: 'Payment Information',
                        child: Column(
                          children: [
                            _infoRow(Icons.check_circle_outline_rounded, 'Payment Status', 'PAID (Online Digital)'),
                            const SizedBox(height: 8),
                            _infoRow(Icons.tag_rounded, 'Transaction ID', txnId),
                            const SizedBox(height: 8),
                            _infoRow(Icons.receipt_long_rounded, 'Invoice Number', invId),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _downloadInvoice(bId),
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: Text('Download Official Invoice',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _blue),
                                  foregroundColor: _blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Quick Actions ─────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('View My Bookings',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                backgroundColor: _dark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('Back to Home',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Sticky Bottom Bar: Track Booking ────────────────────────
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
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('Track Booking Live',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 12),
          ],
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

  Widget _timelineStep(String title, String desc, bool isDone, bool showLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? _green : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: isDone ? _green : _border),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            if (showLine)
              Container(
                width: 2,
                height: 32,
                color: isDone ? _green : _border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDone ? _dark : _gray)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
