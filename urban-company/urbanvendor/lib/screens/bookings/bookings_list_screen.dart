import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class BookingsListScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  const BookingsListScreen({super.key, this.isEmbedded = false, this.onBack});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedFilterIndex = 1;
  int _activeNavIndex = 1; // Bookings tab
  bool _isHistoryView = false; // Toggle for Operations Center vs History Archive on desktop

  final List<String> _filters = ["All", "Pending", "Accepted", "Completed", "Rejected"];

  // Desktop Live Booking State
  String _selectedDesktopTab = "All Bookings";
  String _desktopSearchQuery = "";
  // Desktop operations table data — still used for vendor desktop view
  final List<Map<String, dynamic>> _desktopBookings = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildDesktopStitchUI();
          }
          return _buildMobileStitchUI();
        },
      ),
      bottomNavigationBar: (!widget.isEmbedded && MediaQuery.of(context).size.width < 1024)
          ? _buildMobileBottomNav()
          : null,
    );
  }

  // ==========================================
  // MOBILE STITCH APPROVED UI
  // ==========================================
  Widget _buildMobileStitchUI() {
    return SafeArea(
      child: Column(
        children: [
          // 1. Top App Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.maybePop(context);
                    }
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  "Requests",
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF0F172A), size: 24),
                  onPressed: () {},
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: VendorTheme.textPrimary, size: 24),
                          onPressed: () => Navigator.pushNamed(context, '/notifications'),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage("https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('vendorId', isEqualTo: user?.uid ?? 'vendor_01')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Tab counts from live data
                  final reqCount = docs.where((doc) {
                    final status = ((doc.data() as Map<String, dynamic>?)?['status'] ?? '').toString().toLowerCase();
                    return status == 'assigned' || status == 'pending';
                  }).length;

                  final pendingCount = docs.where((doc) {
                    final status = ((doc.data() as Map<String, dynamic>?)?['status'] ?? '').toString().toLowerCase();
                    return status == 'accepted' || status == 'en_route' || status == 'arrived' || status == 'work_started' || status == 'working';
                  }).length;

                  final completedCount = docs.where((doc) {
                    final status = ((doc.data() as Map<String, dynamic>?)?['status'] ?? '').toString().toLowerCase();
                    return status == 'completed' || status == 'waiting_for_verification';
                  }).length;

                  // Filtered docs by selected tab
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? '').toString().toLowerCase();
                    if (_selectedFilterIndex == 1) return status == 'assigned' || status == 'pending';
                    if (_selectedFilterIndex == 2) return status == 'accepted' || status == 'en_route' || status == 'arrived' || status == 'work_started' || status == 'working';
                    if (_selectedFilterIndex == 3) return status == 'completed' || status == 'waiting_for_verification';
                    return true;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Segmented Tab Bar
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _buildSegTab("Requests", reqCount, 1),
                            _buildSegTab("Pending", pendingCount, 2),
                            _buildSegTab("Complete", completedCount, 3),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (filteredDocs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.assignment_turned_in_rounded, size: 48, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No Bookings Here",
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "You have no ${_selectedFilterIndex == 1 ? 'new requests' : _selectedFilterIndex == 2 ? 'active jobs' : 'completed bookings'} at the moment.",
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                      ...filteredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = (data['status'] ?? 'pending').toString().toLowerCase();
                        final services = List<Map<String, dynamic>>.from(
                          (data['services'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map? ?? {})),
                        );
                        final firstService = services.isNotEmpty
                            ? (services.first['name'] ?? 'General Service').toString()
                            : (data['shopName'] ?? 'General Service').toString();
                        final firstSubService = services.isNotEmpty
                            ? (services.first['description'] ?? 'Standard service').toString()
                            : 'Standard service';

                        // Badge styling
                        Color badgeBg = const Color(0xFFEFF6FF);
                        Color badgeText = const Color(0xFF1D4ED8);
                        String badgeLabel = status.toUpperCase();
                        if (status == 'completed' || status == 'waiting_for_verification') {
                          badgeBg = const Color(0xFFDCFCE7);
                          badgeText = const Color(0xFF16A34A);
                        } else if (status == 'rejected') {
                          badgeBg = const Color(0xFFFEE2E2);
                          badgeText = const Color(0xFFDC2626);
                        } else if (status == 'assigned' || status == 'pending') {
                          badgeBg = const Color(0xFFFEF3C7);
                          badgeText = const Color(0xFFD97706);
                          badgeLabel = 'NEW';
                        } else if (status == 'accepted' || status == 'en_route' || status == 'working') {
                          badgeBg = const Color(0xFFEFF6FF);
                          badgeText = const Color(0xFF1D4ED8);
                          badgeLabel = 'ACTIVE';
                        }

                        return _buildLiveBookingCard(
                          doc: doc,
                          data: data,
                          status: status,
                          firstService: firstService,
                          firstSubService: firstSubService,
                          badgeBg: badgeBg,
                          badgeText: badgeText,
                          badgeLabel: badgeLabel,
                        );
                      }),

                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single tab in the segmented tab navigation bar.
  Widget _buildSegTab(String label, int count, int tabIndex) {
    final isActive = _selectedFilterIndex == tabIndex;

    Color activeBg, activeText, badgeBg, badgeText;
    if (tabIndex == 1) {
      activeBg = const Color(0xFF0256D0);
      activeText = Colors.white;
      badgeBg = Colors.white.withOpacity(0.25);
      badgeText = Colors.white;
    } else if (tabIndex == 2) {
      activeBg = const Color(0xFFF59E0B);
      activeText = Colors.white;
      badgeBg = Colors.white.withOpacity(0.25);
      badgeText = Colors.white;
    } else {
      activeBg = const Color(0xFF16A34A);
      activeText = Colors.white;
      badgeBg = Colors.white.withOpacity(0.25);
      badgeText = Colors.white;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = tabIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [BoxShadow(color: activeBg.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isActive ? activeText : const Color(0xFF64748B),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? badgeBg : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    color: isActive ? badgeText : const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBookingCard({
    required QueryDocumentSnapshot doc,
    required Map<String, dynamic> data,
    required String status,
    required String firstService,
    required String firstSubService,
    required Color badgeBg,
    required Color badgeText,
    required String badgeLabel,
  }) {
    final String docId = doc.id;
    final String customerEmail = data['userEmail'] ?? 'customer@nexora.com';
    final String customerName = customerEmail.split('@').first.replaceAll('.', ' ');
    final String date = data['date'] ?? 'Today';
    final String time = data['time'] ?? '10:00 AM';

    // Service image from name
    String imageUrl = "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500";
    if (firstService.toLowerCase().contains("plumb")) {
      imageUrl = "https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=500";
    } else if (firstService.toLowerCase().contains("elect")) {
      imageUrl = "https://images.unsplash.com/photo-1621905252507-b354bc25edac?w=500";
    } else if (firstService.toLowerCase().contains("ac") || firstService.toLowerCase().contains("hvac")) {
      imageUrl = "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500";
    } else if (firstService.toLowerCase().contains("clean")) {
      imageUrl = "https://images.unsplash.com/photo-1527515545081-5db817172677?w=500";
    } else if (firstService.toLowerCase().contains("paint")) {
      imageUrl = "https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=500";
    }

    final bool isNew = status == 'assigned' || status == 'pending';
    final bool isActive = status == 'accepted' || status == 'en_route' || status == 'working' || status == 'arrived';
    final bool isDone = status == 'completed' || status == 'waiting_for_verification';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFF6FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(height: 150, color: const Color(0xFFE2E8F0))),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Customer name overlay
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        customerName.isNotEmpty ? customerName : 'Customer',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstService,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  firstSubService,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(date, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(time, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons based on status
                if (isNew)
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'rejected'});
                            await FirebaseFirestore.instance.collection('booking_timeline').add({
                              'bookingId': docId,
                              'status': 'rejected',
                              'title': 'Booking Rejected',
                              'description': 'Vendor has rejected this assignment.',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) AppSnackbar.show(context, "Request Declined");
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: Color(0xFFFEE2E2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text("Decline", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFDC2626), fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                              'status': 'accepted',
                              'acceptedAt': FieldValue.serverTimestamp(),
                            });
                            await FirebaseFirestore.instance.collection('booking_timeline').add({
                              'bookingId': docId,
                              'status': 'accepted',
                              'title': 'Booking Accepted',
                              'description': 'Vendor has accepted the booking.',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            await FirebaseFirestore.instance.collection('notifications').add({
                              'title': 'Booking Confirmed!',
                              'body': 'Your vendor has accepted the booking and will arrive as scheduled.',
                              'userId': data['userId'] ?? 'guest_user',
                              'type': 'booking',
                              'bookingId': docId,
                              'read': false,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) AppSnackbar.show(context, "Booking Accepted!");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text("Accept Request", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),

                if (isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/bookings/active_dashboard', arguments: {
                          'bookingId': docId,
                          'customerName': customerName,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                      label: Text("Continue Job", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ),
                  ),

                if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Text("Service Completed", style: GoogleFonts.inter(color: const Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),

                if (status == 'rejected')
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Text("Request Rejected", style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMobileStitchBookingCard({
    required String id,
    required String customerName,
    required String serviceName,
    required String price,
    required String priceBadge,
    required Color priceBadgeColor,
    required Color priceBadgeTextColor,
    required String distance,
    required String time,
    required String avatarUrl,
    required IconData icon,
    required bool isVerified,
  }) {
    // Map service name to actual high-quality service image from Unsplash
    String imageUrl = "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500";
    if (serviceName.toLowerCase().contains("plumb")) {
      imageUrl = "https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=500";
    } else if (serviceName.toLowerCase().contains("elect")) {
      imageUrl = "https://images.unsplash.com/photo-1621905252507-b354bc25edac?w=500";
    } else if (serviceName.toLowerCase().contains("hvac") || serviceName.toLowerCase().contains("ac")) {
      imageUrl = "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500";
    }

    final bool isUrgent = serviceName.toLowerCase().contains("plumb") || priceBadge == "NEW";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFF6FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Header with overlays
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Gradient Overlay at bottom
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      ),
                    ),
                  ),
                ),
                // Urgent Status Pill
                if (isUrgent)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "Urgent",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Customer details overlay
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        customerName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isVerified)
                        const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Info section below image
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      price,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "124 Oakwood Dr, $distance away",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Tags
                Wrap(
                  spacing: 6,
                  children: [
                    "Central AC",
                    "Diagnostic"
                  ].map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
                
                const SizedBox(height: 16),

                // Decline & Accept actions
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          AppSnackbar.show(context, "Request Declined");
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFF1F5F9)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          "Decline",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/bookings/active_dashboard', arguments: {'bookingId': id, 'customerName': customerName});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          "Accept Request",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return BottomNavigationBar(
      currentIndex: _activeNavIndex > 3 ? 1 : _activeNavIndex,
      onTap: (idx) {
        if (idx == 0) {
          Navigator.pushReplacementNamed(context, '/expert_dashboard');
        } else if (idx == 2) {
          Navigator.pushNamed(context, '/my_services');
        } else if (idx == 3) {
          Navigator.pushReplacementNamed(context, '/partner_profile');
        } else {
          setState(() => _activeNavIndex = idx);
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1D4ED8),
      unselectedItemColor: VendorTheme.textSecondary,
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: "Bookings"),
        BottomNavigationBarItem(icon: Icon(Icons.layers_outlined), label: "Services"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profile"),
      ],
    );
  }

  // ==========================================
  // DESKTOP STITCH APPROVED OPERATIONS CENTER
  // ==========================================
  Widget _buildDesktopStitchUI() {
    if (widget.isEmbedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle between Operations Center & Archive
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHistoryView ? "ARCHIVE" : "OPERATIONS CENTER",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isHistoryView ? "Booking History" : "Booking Management",
                      style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary),
                    ),
                    Text(
                      _isHistoryView
                          ? "A comprehensive record of your past service engagements."
                          : "Real-time control over your service schedule. Streamline customer intake.",
                      style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => _isHistoryView = !_isHistoryView),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_isHistoryView ? "Show Live Operations" : "Show Booking Archive", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text("Export CSV"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isHistoryView) ...[
              // Archive KPI Cards Row
              _buildArchiveKPIRow(),
              const SizedBox(height: 28),
              _buildArchiveTable(),
            ] else ...[
              // Operations Table & Filters
              _buildOperationsTable(),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 240,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.hexagon_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text("Nexora", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildDesktopSidebarItem(Icons.grid_view_rounded, "Dashboard", false, () => Navigator.pushReplacementNamed(context, '/expert_dashboard')),
              _buildDesktopSidebarItem(Icons.confirmation_number_outlined, "Bookings", true, () {}),
              _buildDesktopSidebarItem(Icons.calendar_month_outlined, "Calendar", false, () {}),
              _buildDesktopSidebarItem(Icons.handyman_rounded, "Services", false, () => Navigator.pushNamed(context, '/my_services')),
              _buildDesktopSidebarItem(Icons.account_balance_wallet_outlined, "Wallet", false, () {}),
              _buildDesktopSidebarItem(Icons.insights_rounded, "Analytics", false, () {}),
              _buildDesktopSidebarItem(Icons.star_outline_rounded, "Reviews", false, () {}),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text("ORGANIZATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
              ),
              _buildDesktopSidebarItem(Icons.notifications_none_rounded, "Notifications", false, () => Navigator.pushNamed(context, '/notifications')),
              _buildDesktopSidebarItem(Icons.folder_open_rounded, "Documents", false, () {}),
              _buildDesktopSidebarItem(Icons.support_agent_rounded, "Support", false, () {}),
              _buildDesktopSidebarItem(Icons.settings_outlined, "Settings", false, () {}),
            ],
          ),
        ),

        // Main Desktop Body
        Expanded(
          child: Column(
            children: [
              // Top Bar Header
              Container(
                height: 70,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: VendorTheme.textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search anything...",
                                  hintStyle: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                     IconButton(icon: const Icon(Icons.notifications_none_rounded, color: VendorTheme.textSecondary), onPressed: () => Navigator.pushNamed(context, '/notifications')),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Alex Sterling", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VendorTheme.textPrimary)),
                            Text("Elite Vendor", style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Operations / History Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle between Operations Center & Archive
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHistoryView ? "ARCHIVE" : "OPERATIONS CENTER",
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isHistoryView ? "Booking History" : "Booking Management",
                                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary),
                              ),
                              Text(
                                _isHistoryView
                                    ? "A comprehensive record of your past service engagements."
                                    : "Real-time control over your service schedule. Streamline customer intake.",
                                style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => setState(() => _isHistoryView = !_isHistoryView),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(_isHistoryView ? "Show Live Operations" : "Show Booking Archive", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text("Export CSV"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_isHistoryView) ...[
                        // Archive KPI Cards Row
                        _buildArchiveKPIRow(),
                        const SizedBox(height: 28),
                        _buildArchiveTable(),
                      ] else ...[
                        // Operations Table & Filters
                        _buildOperationsTable(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebarItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? Colors.white : VendorTheme.textSecondary, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.white : VendorTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsTable() {
    final filtered = _desktopBookings.where((bk) {
      if (_selectedDesktopTab != "All Bookings" && bk['status'] != _selectedDesktopTab) {
        return false;
      }
      if (_desktopSearchQuery.isNotEmpty) {
        final q = _desktopSearchQuery.toLowerCase();
        final name = bk['name'].toString().toLowerCase();
        final id = bk['id'].toString().toLowerCase();
        final service = bk['service'].toString().toLowerCase();
        return name.contains(q) || id.contains(q) || service.contains(q);
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          // Filter Tabs Bar
          Row(
            children: [
              _buildFilterTab("All Bookings", _selectedDesktopTab == "All Bookings", onTap: () => setState(() => _selectedDesktopTab = "All Bookings")),
              _buildFilterTab("Confirmed", _selectedDesktopTab == "Confirmed", onTap: () => setState(() => _selectedDesktopTab = "Confirmed")),
              _buildFilterTab("Pending", _selectedDesktopTab == "Pending", onTap: () => setState(() => _selectedDesktopTab = "Pending")),
              _buildFilterTab("Completed", _selectedDesktopTab == "Completed", onTap: () => setState(() => _selectedDesktopTab = "Completed")),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 38,
                child: TextField(
                  onChanged: (v) => setState(() => _desktopSearchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search by ID or customer...",
                    hintStyle: GoogleFonts.inter(fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Booking Table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2.5),
              3: FlexColumnWidth(2.5),
              4: FlexColumnWidth(1.8),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  _buildTableHeader("BOOKING ID"),
                  _buildTableHeader("CUSTOMER"),
                  _buildTableHeader("SERVICE"),
                  _buildTableHeader("DATE & TIME"),
                  _buildTableHeader("STATUS"),
                ],
              ),
              ...filtered.map((bk) => _buildTableRow(
                bk['id'],
                bk['name'],
                bk['email'],
                bk['service'],
                bk['dateTime'],
                bk['status'],
                bk['color'],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveKPIRow() {
    return Row(
      children: [
        _buildArchiveKPICard("COMPLETION RATE", "94.2%", "+2.4%", const Color(0xFF16A34A)),
        const SizedBox(width: 16),
        _buildArchiveKPICard("AVG. RATING", "4.92 ★", "1,240 reviews", const Color(0xFF2563EB)),
        const SizedBox(width: 16),
        _buildArchiveKPICard("TOTAL REVENUE", "\$142.8k", "Lifetime", const Color(0xFF8B5CF6)),
        const SizedBox(width: 16),
        _buildArchiveKPICard("CANCELLATIONS", "12", "This quarter", const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _buildArchiveKPICard(String label, String value, String subtext, Color subColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(subtext, style: GoogleFonts.inter(fontSize: 11, color: subColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          _buildArchiveRow("Dominic West", "#BK-88291 • Residential HVAC", "Oct 24, 2023", "\$450.00", "Completed", const Color(0xFF16A34A)),
          const Divider(),
          _buildArchiveRow("Sarah Jenkins", "#BK-88285 • Emergency Plumbing", "Oct 22, 2023", "\$25.00 Penalty", "Cancelled", const Color(0xFFDC2626)),
          const Divider(),
          _buildArchiveRow("Arthur Miller", "#BK-88274 • Electrical Audit", "Oct 20, 2023", "\$1,280.00", "Completed", const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildArchiveRow(String name, String sub, String date, String amount, String statusText, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150")),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary)),
                Text(sub, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(date, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary))),
          Expanded(flex: 2, child: Text(amount, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(statusText, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isActive, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : VendorTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary)),
    );
  }

  TableRow _buildTableRow(String id, String name, String email, String service, String date, String status, Color statusColor) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(id, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
              Text(email, style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Text(service, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(date, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ),
      ],
    );
  }
}
