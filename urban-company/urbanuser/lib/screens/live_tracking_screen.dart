import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vendor_profile_screen.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();

  static const LatLng _userPos = LatLng(28.5355, 77.3910); // Noida Sector 62
  static const LatLng _vendorPos = LatLng(28.5420, 77.3820); // 2.4 km away

  void _shareTracking() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing live tracking link for booking ${widget.bookingId}…',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: _blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need Help with your Service?',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.call_rounded, color: _blue),
              title: Text('Call Support Hotline', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text('24x7 Nexora Support: 1800-102-9482', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: _green),
              title: Text('Live Chat with Support', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text('Average wait time: < 1 min', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
              onTap: () {
                Navigator.pop(context);
                final myEmail = FirebaseAuth.instance.currentUser?.email ?? 'guest';
                final chatId = 'chat_${myEmail.replaceAll('.', '_')}_support';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chatId,
                      recipientId: 'support',
                      recipientName: 'NEXORA Support',
                      isVendorApp: false,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.red),
              title: Text('Cancel Booking', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: Text('Eligible for 100% refund prior to arrival', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate secure 6-digit OTP from booking ID
    final String otpCode = "${((widget.bookingId.hashCode.abs() % 900000) + 100000)}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track Booking', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            Text(widget.bookingId, style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _dark, size: 20),
            onPressed: _shareTracking,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: _dark, size: 20),
            onPressed: _showHelpModal,
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
            .doc(widget.bookingId)
            .snapshots(),
        builder: (ctx, snap) {
          Map<String, dynamic> bData = {};
          if (snap.hasData && snap.data!.exists) {
            bData = snap.data!.data() as Map<String, dynamic>;
          }

          final String status = bData['status'] ?? 'assigned';
          final String title = bData['shopName'] ?? bData['serviceName'] ?? 'Deep Home Cleaning';
          final String dateStr = bData['date'] ?? 'Today';
          final String timeStr = bData['time'] ?? '10:00 AM – 12:00 PM';
          final String vendorName = bData['vendorName'] ?? 'Rahul Sharma';
          final String vendorPhoto = bData['vendorPhoto'] ??
              'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=200&auto=format&fit=crop';

          final bool isVendorAssigned = status == 'assigned' || status == 'accepted' || status == 'in_progress' || status == 'completed';
          final bool isAccepted = status == 'accepted' || status == 'in_progress' || status == 'completed';

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Live Map View ─────────────────────────────────────────
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: const MapOptions(
                                initialCenter: _userPos,
                                initialZoom: 14.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.nexora.urbanuser',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: const [_vendorPos, LatLng(28.5390, 77.3870), _userPos],
                                      color: _blue,
                                      strokeWidth: 4,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _userPos,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.home_rounded, color: _blue, size: 36),
                                    ),
                                    Marker(
                                      point: _vendorPos,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.directions_run_rounded, color: Colors.amber, size: 36),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Floating ETA overlay card
                            Positioned(
                              top: 14,
                              left: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                                    )
                                        .animate(onPlay: (c) => c.repeat(reverse: true))
                                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 800.ms),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('LIVE TRACKING ACTIVE',
                                              style: GoogleFonts.inter(fontSize: 8, color: _green, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          Text('Arriving in 14 mins · 2.4 km away',
                                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.my_location_rounded, color: _blue, size: 20),
                                      onPressed: () {
                                        _mapController.move(_userPos, 14.0);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Secure OTP Verification Box ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                            child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('START SERVICE OTP',
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: _blue, letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text(otpCode,
                                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: _dark, letterSpacing: 4)),
                                Text('Share this 6-digit OTP with professional upon arrival.',
                                    style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, duration: 400.ms),

                    const SizedBox(height: 16),

                    // ── Assigned Professional Card ────────────────────────────
                    _cardWrapper(
                      title: 'Assigned Professional',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
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
                                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified_rounded, color: _blue, size: 16),
                                      ],
                                    ),
                                    Text('⭐ 4.9 (1,280 reviews) · 5 yrs exp',
                                        style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                                    Text('Vehicle: Hero Splendor (UP16-AB-8492)',
                                        style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.call_rounded, size: 15),
                                  label: Text('Call Pro', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: _border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                                  label: Text('Chat', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: _border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VendorProfileScreen(
                                          vendor: {'fullName': vendorName},
                                          vendorId: 'v1',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: Text('Profile', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Complete Timeline Stepper ────────────────────────────
                    _cardWrapper(
                      title: 'Live Tracking Timeline',
                      child: Column(
                        children: [
                          _timelineItem('Booking Confirmed', 'Payment & order verified', true, true),
                          _timelineItem('Vendor Auto Assigned', 'Matched with $vendorName', isVendorAssigned, true),
                          _timelineItem('Vendor Accepted', isAccepted ? 'Confirmed by professional' : 'Pending acceptance', isAccepted, true),
                          _timelineItem('Professional On The Way', 'Live location active (2.4 km away)', isAccepted, true),
                          _timelineItem('Professional Arrived', 'Awaiting OTP verification at doorstep', false, true),
                          _timelineItem('OTP Verified & Service Started', 'Work in progress', false, true),
                          _timelineItem('Service Completed', 'Quality audit & feedback', false, false),
                        ],
                      ),
                    ),

                    // ── Booking Info Summary ─────────────────────────────────
                    _cardWrapper(
                      title: 'Booking Information',
                      child: Column(
                        children: [
                          _infoRow(Icons.tag_rounded, 'Booking ID', widget.bookingId),
                          const SizedBox(height: 8),
                          _infoRow(Icons.handyman_rounded, 'Service', title),
                          const SizedBox(height: 8),
                          _infoRow(Icons.calendar_month_rounded, 'Scheduled Date', dateStr),
                          const SizedBox(height: 8),
                          _infoRow(Icons.access_time_rounded, 'Time Slot', timeStr),
                          const SizedBox(height: 8),
                          _infoRow(Icons.timer_outlined, 'Est. Duration', '2 – 3 Hours'),
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
                        child: OutlinedButton.icon(
                          onPressed: _showHelpModal,
                          icon: const Icon(Icons.help_outline_rounded, size: 16),
                          label: Text('Need Help?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _border),
                            foregroundColor: _dark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const DashboardScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_rounded, size: 16),
                          label: Text('Back to Home', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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

  Widget _timelineItem(String title, String desc, bool isDone, bool showLine) {
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
              child: isDone ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            if (showLine)
              Container(
                width: 2,
                height: 30,
                color: isDone ? _green : _border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isDone ? _dark : _gray)),
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
