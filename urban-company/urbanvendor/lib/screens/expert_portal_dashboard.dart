import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';
import 'bookings/bookings_list_screen.dart';
import 'business_settings_screen.dart';
import 'my_services_screen.dart';
import 'wallet_management_screen.dart';
import 'business_growth_screen.dart';
import 'support_center_screen.dart';

class ExpertPortalDashboard extends StatefulWidget {
  const ExpertPortalDashboard({super.key});

  @override
  State<ExpertPortalDashboard> createState() => _ExpertPortalDashboardState();
}

class _ExpertPortalDashboardState extends State<ExpertPortalDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  Stream<DocumentSnapshot>? _vendorStreamCache;
  Stream<DocumentSnapshot> get _vendorStream {
    _vendorStreamCache ??= FirebaseFirestore.instance.collection('vendors').doc(user!.email).snapshots();
    return _vendorStreamCache!;
  }
  bool _isOnline = true;
  bool _isBusyMode = false;
  bool _isVacationMode = false;
  int _activeMenuIndex = 0; // 0: Dashboard, 1: Bookings, 2: Services, 3: Analytics, 4: Support, 5: Settings/Profile
  String _revenuePeriod = "Weekly"; // Weekly vs Monthly

  final List<String> _sidebarItems = [
    "Dashboard",
    "Bookings",
    "Services",
    "Analytics",
    "Support"
  ];

  final List<IconData> _sidebarIcons = [
    Icons.grid_view_rounded,
    Icons.calendar_month_rounded,
    Icons.handyman_rounded,
    Icons.insights_rounded,
    Icons.support_agent_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isTestBypass = args?['isTestBypass'] == true;

    return StreamBuilder<DocumentSnapshot>(
      stream: _vendorStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final String status = (data['status'] ?? 'pending').toString().toLowerCase();

        // Redirect gate checks (Skip if testing bypass flag is set)
        if (status == 'pending' && !isTestBypass) {
          Future.microtask(() {
            if (mounted) Navigator.pushReplacementNamed(context, '/pending_dashboard');
          });
        }

        final String ownerName = data['ownerName'] ?? 'Vishal';
        final String businessName = data['businessName'] ?? 'Nexora Partner';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1024) {
                return _buildDesktopStitchUI(ownerName, businessName, data);
              }
              return _buildMobileStitchUI(ownerName, businessName, data);
            },
          ),
          bottomNavigationBar: MediaQuery.of(context).size.width < 1024
              ? _buildMobileBottomNav()
              : null,
          floatingActionButton: null,
        );
      },
    );
  }

  // ==========================================
  // MOBILE STITCH APPROVED UI
  // ==========================================
  Widget _buildMobileStitchUI(String ownerName, String businessName, Map<String, dynamic> data) {
    if (_activeMenuIndex == 1) {
      return BookingsListScreen(
        isEmbedded: true,
        onBack: () => setState(() => _activeMenuIndex = 0),
      );
    }
    if (_activeMenuIndex == 2) {
      return MyServicesScreen(
        isTab: true,
        onBack: () => setState(() => _activeMenuIndex = 0),
      );
    }
    if (_activeMenuIndex == 3) {
      return BusinessGrowthScreen(
        isTab: true,
        onBack: () => setState(() => _activeMenuIndex = 0),
      );
    }
    if (_activeMenuIndex == 4) {
      return SupportCenterScreen(
        isTab: true,
        onBack: () => setState(() => _activeMenuIndex = 0),
      );
    }
    if (_activeMenuIndex == 5) {
      return BusinessSettingsScreen(
        isTab: true,
        onBack: () => setState(() => _activeMenuIndex = 0),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mobile Top Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard",
                        style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "Good Morning, $ownerName",
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text("👋", style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: VendorTheme.textPrimary, size: 22),
                  onPressed: () {},
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('recipientId', whereIn: [FirebaseAuth.instance.currentUser?.email ?? '', 'all', 'vendors'])
                      .where('read', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data?.docs.length ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: VendorTheme.textPrimary, size: 24),
                          onPressed: () => Navigator.pushNamed(context, '/notifications'),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 4),
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Online Status Card
            _buildMobileStatusCard(),
            const SizedBox(height: 20),

            // 3. Quick KPI Cards Carousel/Row
            _buildMobileKPICards(),
            const SizedBox(height: 24),

            // 4. Quick Actions (4x2 Grid)
            Text("Quick Actions", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildMobileQuickActionsGrid(),
            const SizedBox(height: 24),

            // 5. Promotional Referral Banner
            _buildMobileReferralBanner(),
            const SizedBox(height: 24),

            // 6. Today's Bookings Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Bookings", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                TextButton(
                  onPressed: () => setState(() => _activeMenuIndex = 1),
                  child: Text("View All", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMobileBookingCard(
              customerName: "Rahul Sharma",
              serviceName: "AC Repair • Standard Service",
              time: "10:30 AM",
              distance: "2.5 km away",
              price: "₹1,200",
              statusText: "Confirmed",
              statusBg: const Color(0xFF047857),
              buttonText: "View Details",
              isPrimaryButton: true,
              avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
            ),
            const SizedBox(height: 12),
            _buildMobileBookingCard(
              customerName: "Priya Kapoor",
              serviceName: "Deep Cleaning • 2BHK",
              time: "01:00 PM",
              distance: "4.1 km away",
              price: "₹2,450",
              statusText: "In Progress",
              statusBg: const Color(0xFF2563EB),
              buttonText: "Navigate",
              isPrimaryButton: false,
              avatarUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
            ),
            const SizedBox(height: 12),
            _buildMobileBookingCard(
              customerName: "Vikram Singh",
              serviceName: "Plumbing • Leakage Repair",
              time: "04:30 PM",
              distance: "1.2 km away",
              price: "₹800",
              statusText: "Scheduled",
              statusBg: const Color(0xFF93C5FD),
              statusTextColor: const Color(0xFF1E3A8A),
              buttonText: "View Details",
              isPrimaryButton: false,
              avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
            ),
            const SizedBox(height: 24),

            // 7. Customer Reviews Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Customer Reviews", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFF047857)),
                          const SizedBox(width: 3),
                          Text("4.9", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                        ],
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text("See All", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMobileReviewCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFF16A34A) : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? "You're Online" : "You're Offline",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary),
                    ),
                    Text(
                      "Today: 09:00 AM - 06:00 PM",
                      style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _isOnline,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF1D4ED8),
                  onChanged: (val) => setState(() => _isOnline = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isBusyMode = !_isBusyMode),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isBusyMode ? const Color(0xFFDBEAFE) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 16, color: const Color(0xFF1E40AF)),
                        const SizedBox(width: 6),
                        Text("Busy Mode", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isVacationMode = !_isVacationMode),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isVacationMode ? const Color(0xFFDBEAFE) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.beach_access_outlined, size: 16, color: const Color(0xFF1E40AF)),
                        const SizedBox(width: 6),
                        Text("Vacation", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileKPICards() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Card 1: Today's Earnings (Blue Gradient)
          Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 16),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text("12%", style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Earnings", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text("₹4,500", style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Card 3: Bookings (Purple Gradient)
          Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 16),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bookings", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text("5 Bookings", style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Card 4: Avg Rating (Emerald Green Gradient)
          Container(
            width: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.star_outline_rounded, color: Colors.white, size: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                      child: Text("Top 5%", style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Avg Rating", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text("4.92 ★", style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuickActionsGrid() {
    final actions = [
      {"label": "Bookings", "icon": Icons.assignment_outlined, "route": "/bookings"},
      {"label": "Services", "icon": Icons.build_outlined, "route": "/my_services"},
      {"label": "Wallet", "icon": Icons.account_balance_wallet_outlined, "route": "/wallet"},
      {"label": "Analytics", "icon": Icons.show_chart_rounded, "route": "/growth"},
      {"label": "Campaigns", "icon": Icons.campaign_outlined, "route": "/campaigns"},
      {"label": "Coupons", "icon": Icons.local_offer_outlined, "route": "/coupons"},
      {"label": "Support", "icon": Icons.headset_mic_outlined, "route": "/support"},
      {"label": "KYC", "icon": Icons.verified_user_outlined, "route": "/kyc_onboarding"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(context, item["route"] as String),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE), // Soft Blue Circle
                  shape: BoxShape.circle,
                ),
                child: Icon(item["icon"] as IconData, color: const Color(0xFF1D4ED8), size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                item["label"] as String,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: VendorTheme.textPrimary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileReferralBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("New Rewards", style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Text("Nexora Referral Program", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Earn ₹500 for every vendor you refer.", style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildMobileBookingCard({
    required String customerName,
    required String serviceName,
    required String time,
    required String distance,
    required String price,
    required String statusText,
    required Color statusBg,
    Color statusTextColor = Colors.white,
    required String buttonText,
    required bool isPrimaryButton,
    required String avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary)),
                    Text(serviceName, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                child: Text(statusText, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusTextColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: VendorTheme.textSecondary),
              const SizedBox(width: 4),
              Text(time, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
              const SizedBox(width: 16),
              const Icon(Icons.navigation_outlined, size: 14, color: VendorTheme.textSecondary),
              const SizedBox(width: 4),
              Text(distance, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary)),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/bookings/details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPrimaryButton ? const Color(0xFF0256D0) : const Color(0xFFEFF6FF),
                  foregroundColor: isPrimaryButton ? Colors.white : const Color(0xFF1D4ED8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonText, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: Color(0xFF16A34A), size: 16)),
              ),
              const SizedBox(width: 8),
              Text("2 hours ago", style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"Rahul did an excellent job with the AC repair. He was punctual, professional, and solved the noise issue instantly."',
            style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textPrimary, fontStyle: FontStyle.italic, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text("— Ananya M.", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    int getDisplayIndex() {
      if (_activeMenuIndex == 0) return 0;
      if (_activeMenuIndex == 1) return 1;
      if (_activeMenuIndex == 2) return 2; // Services
      return 3; // Profile/Settings
    }

    return BottomNavigationBar(
      currentIndex: getDisplayIndex(),
      onTap: (idx) {
        setState(() {
          if (idx == 0) _activeMenuIndex = 0;
          if (idx == 1) _activeMenuIndex = 1;
          if (idx == 2) _activeMenuIndex = 2;
          if (idx == 3) _activeMenuIndex = 5;
        });
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
  // DESKTOP STITCH APPROVED SAAS DASHBOARD UI
  // ==========================================
  Widget _buildDesktopStitchUI(String ownerName, String businessName, Map<String, dynamic> data) {
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

              // Menu Items
              Expanded(
                child: ListView.builder(
                  itemCount: _sidebarItems.length,
                  itemBuilder: (context, idx) {
                    final isActive = _activeMenuIndex == idx;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() => _activeMenuIndex = idx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2563EB) : Colors.transparent, // Active blue pill
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(_sidebarIcons[idx], color: isActive ? Colors.white : VendorTheme.textSecondary, size: 20),
                              const SizedBox(width: 14),
                              Text(
                                _sidebarItems[idx],
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
                  },
                ),
              ),

              InkWell(
                onTap: () => setState(() => _activeMenuIndex = 5),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Alex Rivera", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VendorTheme.textPrimary)),
                            Text("Vendor Admin", style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Desktop Body Panel
        Expanded(
          child: Column(
            children: [
              // Sticky Top Navigation Header
              Container(
                height: 70,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    // Search Bar
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
                                  hintText: "Search bookings, invoices...",
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
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: VendorTheme.textSecondary), onPressed: () => Navigator.pushNamed(context, '/notifications')),
                        IconButton(icon: const Icon(Icons.settings_outlined, color: VendorTheme.textSecondary), onPressed: () {}),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text("System Status • Operational", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/my_services'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("New Service"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dashboard Detail Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey(_activeMenuIndex),
                    child: _activeMenuIndex == 1
                        ? const BookingsListScreen(isEmbedded: true)
                        : _activeMenuIndex == 2
                            ? MyServicesScreen(
                                isTab: true,
                                onBack: () => setState(() => _activeMenuIndex = 0),
                              )
                            : _activeMenuIndex == 3
                                    ? BusinessGrowthScreen(
                                        isTab: true,
                                        onBack: () => setState(() => _activeMenuIndex = 0),
                                      )
                                    : _activeMenuIndex == 4
                                        ? SupportCenterScreen(
                                            isTab: true,
                                            onBack: () => setState(() => _activeMenuIndex = 0),
                                          )
                                        : _activeMenuIndex == 5
                                            ? BusinessSettingsScreen(
                                                isTab: true,
                                                onBack: () => setState(() => _activeMenuIndex = 0),
                                              )
                                    : SingleChildScrollView(
                                        padding: const EdgeInsets.all(32),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                      // Overview Header
                      Text("OVERVIEW", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text("Good Morning, $ownerName 👋", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                      Text("Here's what's happening with your business today, October 24th.", style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary)),
                      const SizedBox(height: 24),

                      // Overview 4 KPI Cards Grid
                      _buildDesktopKPIGrid(),
                      const SizedBox(height: 28),

                      // Accelerator Hero Banner (Bright Animated Gradient)
                      const AnimatedAcceleratorBanner(),
                      const SizedBox(height: 28),

                      // Double Column Main Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Recent Revenue Chart + Booking Requests Table
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: [
                                _buildDesktopRevenueChart(),
                                const SizedBox(height: 28),
                                _buildDesktopBookingRequestsTable(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),

                          // Right Column: Upcoming Schedule + Testimonial
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildDesktopUpcomingSchedule(),
                                const SizedBox(height: 28),
                                _buildDesktopTestimonialCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopKPIGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Today's Earnings (Blue Gradient)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                        child: Text("+12.5%", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Today's Earnings", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  Text("₹8,420", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
  
          // Card 3: Total Bookings (Purple Gradient)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 18),
                      ),
                      Text("14 Left", style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Total Bookings", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  Text("128", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
  
          // Card 4: Avg Rating (Emerald Green Gradient)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.star_outline_rounded, color: Colors.white, size: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                        child: Text("Top 5%", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Avg Rating", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  Text("4.92 / 5.0", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDesktopRevenueChart() {
    final List<double> chartData = _revenuePeriod == "Weekly"
        ? [12000, 18000, 15000, 28000, 22000, 35000, 42000]
        : [45000, 62000, 50000, 78000];
    final List<String> chartLabels = _revenuePeriod == "Weekly"
        ? ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        : ["Week 1", "Week 2", "Week 3", "Week 4"];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recent Revenue", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary)),
                  Text("Daily breakdown of completed jobs", style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _revenuePeriod = "Weekly"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _revenuePeriod == "Weekly" ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                        child: Text("Weekly", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _revenuePeriod = "Monthly"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _revenuePeriod == "Monthly" ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                        child: Text("Monthly", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _RevenueChartPainter(chartData, chartLabels, const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBookingRequestsTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("New Booking Requests", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary)),
              TextButton(onPressed: () => setState(() => _activeMenuIndex = 1), child: Text("View All", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)))),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequestRow("Priya Sharma", "4.8 ★", "Deep AC Cleaning 2 Units", "2.4 km", "₹1,850"),
          const Divider(),
          _buildRequestRow("Rahul Varma", "5.0 ★", "Smart Lock Installation", "4.1 km", "₹450"),
        ],
      ),
    );
  }

  Widget _buildRequestRow(String name, String rating, String service, String distance, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150")),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VendorTheme.textPrimary)),
                Text(rating, style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(flex: 4, child: Text(service, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textPrimary))),
          Expanded(flex: 2, child: Text(distance, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary))),
          Text(price, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary)),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18), onPressed: () {}),
        ],
      ),
    );
  }



  Widget _buildDesktopUpcomingSchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: VendorTheme.textPrimary)),
              const Icon(Icons.calendar_month_outlined, size: 18, color: VendorTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          _buildDesktopScheduleSlot("14:00", "Plumbing Service", "Amit K. • 1.2km away"),
          const SizedBox(height: 12),
          _buildDesktopScheduleSlot("16:30", "Kitchen Cleaning", "Mrs. Chatterjee • 5.0km away"),
        ],
      ),
    );
  }

  Widget _buildDesktopScheduleSlot(String time, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(time, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1D4ED8))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VendorTheme.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTestimonialCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: Color(0xFF16A34A), size: 16))),
          const SizedBox(height: 12),
          Text(
            '"Vishal was extremely professional. He fixed the AC issue in under 30 minutes and even gave some maintenance tips. Highly recommended!"',
            style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: VendorTheme.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(radius: 14, backgroundImage: NetworkImage("https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150")),
              const SizedBox(width: 8),
              Text("Ananya Gupta", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: VendorTheme.textPrimary)),
              const Spacer(),
              Text("2 days ago", style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// Bright Animated Gradient Accelerator Banner (Top Level Class)
class AnimatedAcceleratorBanner extends StatefulWidget {
  const AnimatedAcceleratorBanner({super.key});

  @override
  State<AnimatedAcceleratorBanner> createState() => _AnimatedAcceleratorBannerState();
}

class _AnimatedAcceleratorBannerState extends State<AnimatedAcceleratorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF2563EB), const Color(0xFF0284C7), t)!,
                Color.lerp(const Color(0xFF3B82F6), const Color(0xFF6366F1), t)!,
                Color.lerp(const Color(0xFF06B6D4), const Color(0xFF10B981), t)!,
              ],
              begin: Alignment(-1.0 + (0.4 * t), -1.0),
              end: Alignment(1.0, 1.0 - (0.4 * t)),
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(const Color(0xFF2563EB), const Color(0xFF06B6D4), t)!.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating animated glowing background circles
              Positioned(
                right: -20 + (30 * t),
                top: -30 + (20 * t),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                left: 140 - (40 * t),
                bottom: -40 + (30 * t),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Content Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "ACCELERATOR PROGRAM",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Scale your service business to new heights.",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1E40AF),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: Text(
                                "Start Growing",
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {},
                              child: Row(
                                children: [
                                  Text(
                                    "Learn More",
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 54,
                      backgroundImage: NetworkImage("https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=300"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color color;

  _RevenueChartPainter(this.data, this.labels, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftPadding = 50.0;
    const double bottomPadding = 30.0;
    const double rightPadding = 20.0;
    const double topPadding = 20.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = 0.0; // Start Y axis at 0 for absolute scaling
    final double range = maxVal == 0 ? 1.0 : maxVal;

    // 1. Draw horizontal grid lines and Y-axis labels
    final int gridLinesCount = 4;
    final gridLinePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridLinesCount; i++) {
      final double yRatio = i / gridLinesCount;
      final double y = topPadding + chartHeight * (1 - yRatio);
      
      // Draw grid line
      canvas.drawLine(Offset(leftPadding, y), Offset(leftPadding + chartWidth, y), gridLinePaint);

      // Draw Y-axis label
      final double val = minVal + range * yRatio;
      final labelText = val >= 1000 ? "₹${(val / 1000).toStringAsFixed(0)}k" : "₹${val.toStringAsFixed(0)}";
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2));
    }

    // Calculate chart coordinate points
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = leftPadding + (i / (data.length - 1)) * chartWidth;
      final double y = topPadding + chartHeight * (1 - ((data[i] - minVal) / range));
      points.add(Offset(x, y));
    }

    // 2. Draw gradient fill under the curve
    if (points.isNotEmpty) {
      final fillPath = Path()
        ..moveTo(points.first.dx, topPadding + chartHeight)
        ..lineTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final ctrlX = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
      }
      
      fillPath.lineTo(points.last.dx, topPadding + chartHeight);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      );
      final fillPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight))
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(fillPath, fillPaint);
    }

    // 3. Draw curved stroke line
    if (points.isNotEmpty) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final ctrlX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
      }

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      
      canvas.drawPath(linePath, linePaint);
    }

    // 4. Draw X-axis labels and connection points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];

      // Draw dot
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 4.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);

      // Draw value text above the dot
      final valText = "₹${(data[i] / 1000).toStringAsFixed(1)}k";
      final valPainter = TextPainter(
        text: TextSpan(
          text: valText,
          style: GoogleFonts.inter(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      valPainter.layout();
      valPainter.paint(canvas, Offset(p.dx - valPainter.width / 2, p.dy - valPainter.height - 6));

      // Draw label at the bottom (X-axis)
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(p.dx - labelPainter.width / 2, topPadding + chartHeight + 10));
    }
  }

  @override
  bool shouldRepaint(_RevenueChartPainter old) => old.data != data || old.labels != labels || old.color != color;
}

