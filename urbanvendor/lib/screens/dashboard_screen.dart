import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

// ─────────────────────────────────────────────
// Brand colors
// ─────────────────────────────────────────────
const _orange = Color(0xFFE8521A);
const _dark = Color(0xFF111827);
const _surface = Color(0xFFF8F8F8);
const _cardWhite = Colors.white;
const _muted = Color(0xFF9CA3AF);
const _border = Color(0xFFF3F4F6);

// ─────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<_BookingReq> _bookings = const [
    _BookingReq('Deep Home Cleaning', '₹1,299', '12 Oct, 10:00 AM', 'UC-7601'),
    _BookingReq('AC Full Service', '₹2,499', '13 Oct, 12:30 PM', 'UC-7602'),
    _BookingReq('Salon for Men', '₹599', '14 Oct, 04:00 PM', 'UC-7603'),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _bookings.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Greeting ──────────────────────────────
                            _buildGreeting(),
                            const SizedBox(height: 36),

                            // ── Main 2-column layout ──────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT PANEL (450px)
                                SizedBox(width: 450, child: _buildLeftPanel()),
                                const SizedBox(width: 36),

                                // RIGHT PANEL (flexible)
                                Expanded(child: _buildRightPanel()),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  // ── SIDEBAR ─────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 114,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          _sidebarIcon(Icons.widgets_rounded, active: true),
          const SizedBox(height: 36),
          _sidebarIcon(Icons.calendar_today_rounded),
          const SizedBox(height: 36),
          _sidebarIcon(Icons.chat_bubble_outline_rounded),
          const SizedBox(height: 36),
          _sidebarIcon(Icons.map_outlined),
          const SizedBox(height: 36),
          _sidebarIcon(Icons.people_outline_rounded),
          const SizedBox(height: 36),
          _sidebarIcon(Icons.inventory_2_outlined),
          const SizedBox(height: 36),
          _sidebarIcon(Icons.settings_outlined),
          const Spacer(),
          _sidebarIcon(Icons.help_outline_rounded),
          const SizedBox(height: 36),
          _sidebarIcon(Icons.logout_rounded),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: active ? _dark : Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        boxShadow: active
            ? [
                BoxShadow(
                  color: _dark.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Icon(icon, color: active ? Colors.white : _muted, size: 36),
    );
  }

  // ── TOP BAR ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: _cardWhite,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
      child: Row(
        children: [
          // Logo pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _dark,
              borderRadius: BorderRadius.circular(45),
            ),
            child: Row(
              children: [
                Container(
                  width: 33,
                  height: 33,
                  decoration: const BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'VendorApp',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Nav pills
          ...[
            ('Overview', true),
            ('Activity', false),
            ('Manage', false),
            ('Program', false),
            ('Account', false),
            ('Reports', false),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _NavPill(label: item.$1, active: item.$2),
            ),
          ),

          const Spacer(),

          // Icon buttons
          _iconBtn(Icons.search_rounded),
          const SizedBox(width: 12),
          _iconBtn(Icons.notifications_none_rounded, badge: true),
          const SizedBox(width: 12),
          _iconBtn(Icons.info_outline_rounded),
          const SizedBox(width: 21),

          // Avatar + info
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: _orange,
                child: Text(
                  'RK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ravi Kumar',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _dark,
                    ),
                  ),
                  Text(
                    'ravi@vendor.com',
                    style: GoogleFonts.outfit(fontSize: 15, color: _muted),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _muted,
                size: 27,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {bool badge = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: Icon(icon, size: 25, color: _dark),
        ),
        if (badge)
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.2),
              ),
            ),
          ),
      ],
    );
  }

  // ── GREETING ─────────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Row(
      children: [
        const Text('☀️', style: TextStyle(fontSize: 33)),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, Ravi',
              style: GoogleFonts.outfit(
                fontSize: 39,
                fontWeight: FontWeight.bold,
                color: _dark,
              ),
            ),
            Text(
              'Stay on top of your tasks, monitor progress, and track status.',
              style: GoogleFonts.outfit(fontSize: 19, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  // ── LEFT PANEL ───────────────────────────────────────────────────────────────
  Widget _buildLeftPanel() {
    return Column(
      children: [
        _buildBalanceCard(),
        const SizedBox(height: 14),
        _buildSpendingLimit(),
        const SizedBox(height: 14),
        _buildMyCards(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🇮🇳 INR ▾',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹6,89,372.00',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '↑ 5%  than last month',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: '⇄  Transfer',
                  filled: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  label: '⇌  Request',
                  filled: false,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Wallets  |  Total 3 wallets',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                child: _WalletItem(
                  flag: '🇮🇳',
                  currency: 'INR',
                  amount: '₹22,678',
                  active: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _WalletItem(
                  flag: '🇪🇺',
                  currency: 'EUR',
                  amount: '€18,345',
                  active: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _WalletItem(
                  flag: '🇬🇧',
                  currency: 'GBP',
                  amount: '£15,000',
                  active: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingLimit() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Spending Limit',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.25,
              minHeight: 8,
              backgroundColor: _border,
              valueColor: const AlwaysStoppedAnimation<Color>(_orange),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹1,400 spent out of',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _dark,
                ),
              ),
              Text(
                '₹5,500.00',
                style: GoogleFonts.outfit(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyCards() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💳  My Cards',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              Text(
                '+ Add new',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildCardItem(dark: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildCardItem(dark: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem({required bool dark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? _dark : _orange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '● Active',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            dark ? '•••• •••• •••• 6782' : '•••• •••• •••• 4356',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dark ? '09/29   611' : 'Vendor Pro Card',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── RIGHT PANEL ──────────────────────────────────────────────────────────────
  Widget _buildRightPanel() {
    return Column(
      children: [
        // Row: Carousel | Stat Cards | Chart
        SizedBox(
          height: 420,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Booking Carousel
              SizedBox(width: 375, child: _buildBookingCarousel()),
              const SizedBox(width: 30),

              // Stat Cards 2x2
              SizedBox(width: 360, child: _buildStatGrid()),
              const SizedBox(width: 30),

              // Profit & Loss chart
              Expanded(child: _ProfitLossChart()),
            ],
          ),
        ),
        const SizedBox(height: 48),

        // Recent Activities
        _RecentActivity(),
        const SizedBox(height: 48),

        // KPI Metrics
        _buildMetricsRow(),
        const SizedBox(height: 72),
      ],
    );
  }

  Widget _buildBookingCarousel() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _bookings.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _BookingCard(booking: _bookings[i]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bookings.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i ? _orange : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: const [
              Expanded(
                child: _StatCard(
                  label: 'Total Earnings',
                  value: '₹950',
                  sub: '↑ 7%  This month',
                  highlighted: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total Spending',
                  value: '₹700',
                  sub: '↓ 5%  This month',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: const [
              Expanded(
                child: _StatCard(
                  label: 'Total Income',
                  value: '₹1,050',
                  sub: '↑ 8%  This month',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total Revenue',
                  value: '₹850',
                  sub: '↑ 4%  This month',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Bookings',
            value: '12 New',
            icon: Icons.calendar_today_rounded,
            bg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _KpiCard(
            label: 'Rating',
            value: '4.95 ★',
            icon: Icons.star_rounded,
            bg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _KpiCard(
            label: 'Success Rate',
            value: '98%',
            icon: Icons.verified_rounded,
            bg: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// NAV PILL
// ─────────────────────────────────────────────
class _NavPill extends StatelessWidget {
  final String label;
  final bool active;

  const _NavPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 10),
      decoration: BoxDecoration(
        color: active ? _dark : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : _muted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTION BUTTON (Transfer / Request)
// ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? _dark : _cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: filled ? _dark : _border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : _dark,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WALLET ITEM
// ─────────────────────────────────────────────
class _WalletItem extends StatelessWidget {
  final String flag, currency, amount;
  final bool active;

  const _WalletItem({
    required this.flag,
    required this.currency,
    required this.amount,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(flag, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            currency,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          Text(
            active ? 'Active' : 'Inactive',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF10B981) : _muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOOKING REQUEST CARD
// ─────────────────────────────────────────────
class _BookingReq {
  final String title, price, time, id;

  const _BookingReq(this.title, this.price, this.time, this.id);
}

class _BookingCard extends StatelessWidget {
  final _BookingReq booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8521A), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _orange.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Booking Request!',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                      ),
                    ),
                    Text(
                      'ID: ${booking.id}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  booking.price,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            booking.title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                booking.time,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                  ),
                  child: Text(
                    'ACCEPT',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'REJECT',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
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
}

// ─────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final bool highlighted;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? _orange : _cardWhite;
    final labelColor = highlighted ? Colors.white.withOpacity(0.75) : _muted;
    final valColor = highlighted ? Colors.white : _dark;
    final subColor = highlighted ? Colors.white.withOpacity(0.65) : _muted;

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(27),
        border: highlighted ? null : Border.all(color: _border),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _orange.withOpacity(0.3),
                  blurRadius: 21,
                  offset: const Offset(0, 9),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.show_chart_rounded,
                size: 22,
                color: highlighted ? Colors.white70 : _muted,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: valColor,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.outfit(fontSize: 15, color: subColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROFIT & LOSS BAR CHART
// ─────────────────────────────────────────────
class _ProfitLossChart extends StatelessWidget {
  _ProfitLossChart();

  final List<String> _months = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
  ];
  final List<double> _profit = const [25, 30, 18, 32, 28, 40, 35, 45];
  final List<double> _loss = const [10, 15, 22, 12, 18, 10, 14, 8];

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Income',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                  Text(
                    'View income over time',
                    style: GoogleFonts.outfit(fontSize: 11, color: _muted),
                  ),
                ],
              ),
              Row(
                children: [
                  _legendDot(_orange, 'Profit'),
                  const SizedBox(width: 12),
                  _legendDot(_dark, 'Loss'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _months[val.toInt()],
                          style: const TextStyle(fontSize: 9, color: _muted),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}k',
                        style: const TextStyle(fontSize: 9, color: _muted),
                      ),
                      interval: 10,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFF0F0F0), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  _months.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: _profit[i],
                        color: _orange,
                        width: 9,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: _loss[i],
                        color: _dark,
                        width: 9,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: _muted)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// RECENT ACTIVITY TABLE
// ─────────────────────────────────────────────
class _ActivityData {
  final String id, title, price, status, date;
  final Color statusColor;
  final IconData icon;

  const _ActivityData(
    this.id,
    this.title,
    this.price,
    this.status,
    this.statusColor,
    this.date,
    this.icon,
  );
}

final _activityList = const [
  _ActivityData(
    'UC-00076',
    'Deep Home Cleaning',
    '₹1,299',
    'Completed',
    Color(0xFF10B981),
    '17 Apr · 03:45 PM',
    Icons.cleaning_services_rounded,
  ),
  _ActivityData(
    'UC-00075',
    'AC Full Servicing',
    '₹2,499',
    'Pending',
    Color(0xFFF59E0B),
    '15 Apr · 11:30 AM',
    Icons.ac_unit_rounded,
  ),
  _ActivityData(
    'UC-00074',
    'Salon for Men',
    '₹599',
    'Completed',
    Color(0xFF10B981),
    '15 Apr · 12:00 PM',
    Icons.content_cut_rounded,
  ),
  _ActivityData(
    'UC-00073',
    'Pest Control Service',
    '₹1,799',
    'In Progress',
    Color(0xFF3B82F6),
    '14 Apr · 09:15 PM',
    Icons.pest_control_rounded,
  ),
  _ActivityData(
    'UC-00072',
    'Bathroom Sanitization',
    '₹899',
    'Completed',
    Color(0xFF10B981),
    '10 Apr · 06:00 AM',
    Icons.water_drop_rounded,
  ),
];

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Recent Activities',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              const Spacer(),
              _PillButton(label: '🔍  Search'),
              const SizedBox(width: 12),
              _PillButton(label: 'Filter  ⚙️'),
            ],
          ),
          const SizedBox(height: 21),

          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 33),
            child: Row(
              children: [
                _th('Order ID', flex: 3),
                _th('Activity', flex: 5),
                _th('Price', flex: 2),
                _th('Status', flex: 3),
                _th('Date', flex: 4),
                const SizedBox(width: 30),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Rows
          ..._activityList.map((a) => _ActivityRow(a: a)),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: _muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityData a;

  const _ActivityRow({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              a.id,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: _dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(a.icon, size: 13, color: _orange),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    a.title,
                    style: GoogleFonts.outfit(fontSize: 11, color: _dark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              a.price,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _dark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: a.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '● ${a.status}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: a.statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              a.date,
              style: GoogleFonts.outfit(fontSize: 10, color: _muted),
            ),
          ),
          const Icon(Icons.more_horiz, size: 16, color: _muted),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// KPI CARD
// ─────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color bg, iconColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: _muted.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED: Card wrapper
// ─────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// SHARED: Pill button (Search / Filter)
// ─────────────────────────────────────────────
class _PillButton extends StatelessWidget {
  final String label;

  const _PillButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _border),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 18, color: _muted),
      ),
    );
  }
}
