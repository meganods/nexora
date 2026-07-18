import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
import 'screens/vendors_screen.dart';
import 'screens/vendor_details_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/services_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/users_screen.dart';
import 'screens/system_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/coupons_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedMenu = 'Dashboard';
  bool _showingVendorDetails = false;
  Map<String, dynamic>? _selectedVendor;
  final TextEditingController _searchController = TextEditingController();
  String _selectedChartFilter = 'Last 6 Months';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          drawer: isMobile ? Drawer(child: _buildSidebar()) : null,
          body: Row(
            children: [
              // Sidebar (only on desktop)
              if (!isMobile) _buildSidebar(),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(isMobile),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: _buildMainContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    if (_showingVendorDetails && _selectedVendor != null) {
      return VendorDetailsScreen(
        vendorData: _selectedVendor!,
        onBack: () => setState(() {
          _showingVendorDetails = false;
          _selectedVendor = null;
        }),
        onApprove: () async {
          if (_selectedVendor != null) {
            String? vid = _selectedVendor!['id'];
            if (vid != null) {
              await Provider.of<AdminProvider>(context, listen: false)
                  .approveVendor(vid);
            }
          }
          setState(() {
            _showingVendorDetails = false;
            _selectedVendor = null;
          });
        },
        onReject: () async {
          if (_selectedVendor != null) {
            String? vid = _selectedVendor!['id'];
            if (vid != null) {
              await Provider.of<AdminProvider>(context, listen: false)
                  .rejectVendor(vid);
            }
          }
          setState(() {
            _showingVendorDetails = false;
            _selectedVendor = null;
          });
        },
      );
    }

    switch (_selectedMenu) {
      case 'Users':
        return const UsersScreen();
      case 'System':
        return const SystemScreen();
      case 'Bookings':
        return const BookingsScreen();
      case 'Earnings':
        return const EarningsScreen();
      case 'Services':
        return const ServicesScreen();
      case 'Applications':
        return ApplicationsScreen(
          onViewDetails: (vendor) => setState(() {
            _selectedVendor = vendor;
            _showingVendorDetails = true;
          }),
        );
      case 'Vendors':
        return VendorsScreen(
          onVendorSelected: (vendor) => setState(() {
            _selectedVendor = vendor;
            _showingVendorDetails = true;
          }),
        );
      case 'Settings':
        return const SettingsScreen();
      case 'Coupons':
        return const CouponsScreen();
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildRevenueChart()),
                const SizedBox(width: 24),
                Expanded(child: _buildRecentSignups()),
              ],
            ),
            const SizedBox(height: 32),
            _buildTransactionalHistory(),
          ],
        );
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildMenuItem('Dashboard', Icons.dashboard_rounded),
                  _buildMenuItem('Vendors', Icons.store_rounded),
                  _buildMenuItem('Applications', Icons.assignment_rounded),
                  _buildMenuItem('Services', Icons.handyman_rounded),
                  _buildMenuItem('Bookings', Icons.calendar_month_rounded),
                  _buildMenuItem('Users', Icons.people_rounded),
                  _buildMenuItem('Earnings', Icons.payments_rounded),
                  _buildMenuItem('System', Icons.settings_rounded),
                  _buildMenuItem('Coupons', Icons.local_offer_rounded),
                  const SizedBox(height: 24),
                  _buildMenuItem('Settings', Icons.settings_applications_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAdminProfile(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(
            Icons.shield_rounded,
            color: Color(0xFF6366F1),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin Executive',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'MANAGEMENT SUITE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon) {
    bool isActive = _selectedMenu == title;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMenu = title;
        _showingVendorDetails = false;
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool showPadding = constraints.maxWidth > 60;
            return Row(
              children: [
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C1D95),
                      borderRadius: BorderRadius.circular(4),
                    ), // Deep purple
                    margin: const EdgeInsets.only(right: 12),
                  )
                else if (showPadding)
                  const SizedBox(width: 16),
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF4C1D95) : Colors.blueGrey[400],
                  size: 20,
                ),
                if (showPadding) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF4C1D95)
                          : Colors.blueGrey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdminProfile() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool showDetails = constraints.maxWidth > 80;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.person_rounded, size: 18, color: Color(0xFF4C1D95)),
              ),
              if (showDetails) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin User',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'SENIOR AUDITOR',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[400],
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.blueGrey[300],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Searching for: $value')),
                        );
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 24),
            _buildHeaderIcon(Icons.notifications_rounded, 'Notifications'),
            const SizedBox(width: 12),
            _buildHeaderIcon(Icons.help_outline_rounded, 'Help'),
            const SizedBox(width: 24),
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEEF2FF),
                  child:
                      Icon(Icons.person_rounded, size: 20, color: Color(0xFF4C1D95)),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Master Superadmin',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.blueGrey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFEEF2FF),
              child: Icon(Icons.person_rounded, size: 18, color: Color(0xFF4C1D95)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $label...')),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blueGrey[600], size: 18),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Systems Overview',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          'Manage your service ecosystem and partner performance from a single atrium.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.blueGrey[400]),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: Provider.of<AdminProvider>(context).vendorApplicationsStream,
      builder: (context, snapshot) {
        int totalVendors = 0;
        int pendingApps = 0;

        if (snapshot.hasData) {
          totalVendors = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'APPROVED';
          }).length;

          pendingApps = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'PENDING';
          }).length;
        }

         return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildStatCard(
                'Active Vendors',
                totalVendors.toString(),
                Icons.storefront_rounded,
                const Color(0xFF818CF8),
                '+${totalVendors > 0 ? "Live" : "0"}',
                onTap: () => setState(() => _selectedMenu = 'Vendors'),
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'Pending Apps',
                pendingApps.toString(),
                Icons.person_add_rounded,
                const Color(0xFFFFB01F),
                'Review',
                onTap: () => setState(() => _selectedMenu = 'Applications'),
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'Total Bookings',
                '8,421',
                Icons.calendar_month_rounded,
                const Color(0xFF2DD4BF),
                '+8%',
                onTap: () => setState(() => _selectedMenu = 'Bookings'),
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'Revenue',
                '₹248.5k',
                Icons.payments_rounded,
                const Color(0xFF6366F1),
                'Monthly',
                isPrimary: true,
                onTap: () => setState(() => _selectedMenu = 'Earnings'),
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                'Approvals',
                '42',
                Icons.warning_amber_rounded,
                const Color(0xFFF87171),
                'REQ.',
                onTap: () => setState(() => _selectedMenu = 'Applications'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String val,
    IconData icon,
    Color color,
    String growth, {
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    final Color lighterColor = HSLColor.fromColor(color).withLightness(
      (HSLColor.fromColor(color).lightness + 0.1).clamp(0.0, 1.0)
    ).toColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, lighterColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Flexible(
                  child: Text(
                    growth,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                val,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Revenue Growth',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Analytics for the current fiscal quarter',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              _buildDropdown(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey[800]!,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toInt()}k',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12);
                        String text = '';
                        if (_selectedChartFilter == 'Last 12 Months') {
                          const labels = ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < labels.length) text = labels[value.toInt()];
                        } else {
                          const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < labels.length) text = labels[value.toInt()];
                        }
                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(text, style: style));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '₹${value.toInt()}k',
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2), 
                    strokeWidth: 1, 
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getChartData(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getChartData() {
    if (_selectedChartFilter == 'Last 12 Months') {
      return [
        _buildBarGroup(0, 30), _buildBarGroup(1, 40), _buildBarGroup(2, 35),
        _buildBarGroup(3, 50), _buildBarGroup(4, 45), _buildBarGroup(5, 60),
        _buildBarGroup(6, 55), _buildBarGroup(7, 70), _buildBarGroup(8, 65),
        _buildBarGroup(9, 85, isHighlight: true), _buildBarGroup(10, 80), _buildBarGroup(11, 95),
      ];
    } else if (_selectedChartFilter == 'This Year') {
      return [
        _buildBarGroup(0, 20), _buildBarGroup(1, 25), _buildBarGroup(2, 30),
        _buildBarGroup(3, 35), _buildBarGroup(4, 40), _buildBarGroup(5, 45, isHighlight: true),
      ];
    }
    return [
      _buildBarGroup(0, 40),
      _buildBarGroup(1, 65, isSpecial: true),
      _buildBarGroup(2, 45, isSpecial: true),
      _buildBarGroup(3, 90, isHighlight: true),
      _buildBarGroup(4, 55, isSpecial: true),
      _buildBarGroup(5, 75, isSpecial: true),
    ];
  }

  BarChartGroupData _buildBarGroup(
    int x,
    double y, {
    bool isHighlight = false,
    bool isSpecial = false,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isHighlight
              ? const Color(0xFF6366F1)
              : (isSpecial ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
          width: _selectedChartFilter == 'Last 12 Months' ? 30 : 60,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _buildRecentSignups() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Signups',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildSignupItem(
            'Elena Rossi',
            'Boutique Catering',
            'NEW',
            const Color(0xFF10B981),
          ),
          _buildSignupItem(
            'Marcus Thorne',
            'Logistics Solutions',
            'NEW',
            const Color(0xFF10B981),
          ),
          _buildSignupItem(
            'Sarah Jenkins',
            'Wellness & Spa',
            'PENDING',
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedMenu = 'Applications'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'View All Applications',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupItem(String name, String cat, String tag, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(Icons.person, color: Colors.blueGrey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  cat,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionalHistory() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactional History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening transaction filters...')),
                      );
                    },
                    icon: Icon(
                      Icons.tune_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting transaction history...')),
                      );
                    },
                    icon: Icon(Icons.file_download_rounded, color: Colors.grey[400], size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.2),
              5: FixedColumnWidth(40),
            },
            children: [
              _buildTableHeader(),
              _buildTableRow(
                '#BK-9281',
                'BT',
                'Bespoke Travels',
                'Oct 24, 2023',
                '₹1,240.00',
                'CONFIRMED',
                const Color(0xFF10B981),
              ),
              _buildTableRow(
                '#BK-9282',
                'UA',
                'Urban Architects',
                'Oct 24, 2023',
                '₹3,500.00',
                'CONFIRMED',
                const Color(0xFF10B981),
              ),
              _buildTableRow(
                '#BK-9283',
                'GS',
                'Gourmet Studio',
                'Oct 23, 2023',
                '₹890.00',
                'PROCESSING',
                const Color(0xFF6366F1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      children: ['BOOKING ID', 'VENDOR', 'DATE', 'AMOUNT', 'STATUS', 'ACTION']
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                e,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _buildTableRow(
    String id,
    String prefix,
    String vendor,
    String date,
    String amt,
    String status,
    Color statusColor,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            id,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  prefix,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                vendor,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            date,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            amt,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const Icon(Icons.more_vert_rounded, size: 16, color: Colors.grey),
      ],
    );
  }

  Widget _buildDropdown() {
    return PopupMenuButton<String>(
      initialValue: _selectedChartFilter,
      onSelected: (String value) {
        setState(() {
          _selectedChartFilter = value;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'Last 6 Months', child: Text('Last 6 Months')),
        const PopupMenuItem<String>(value: 'Last 12 Months', child: Text('Last 12 Months')),
        const PopupMenuItem<String>(value: 'This Year', child: Text('This Year')),
      ],
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              _selectedChartFilter,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
          ],
        ),
      ),
    );
  }
}
