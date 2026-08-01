import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'live_tracking_screen.dart';
import 'dashboard_screen.dart';
import 'rate_review_screen.dart';
import 'service_completed_screen.dart';
import '../widgets/custom_bottom_nav.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  String _selectedFilterStatus = 'All';

  final List<Map<String, dynamic>> _fallbackBookings = [
    {
      'id': 'NEX-849201',
      'shopName': 'Deep Home Cleaning',
      'serviceName': 'Deep Home Cleaning',
      'category': 'Cleaning',
      'date': 'Tomorrow',
      'time': '10:00 AM – 12:00 PM',
      'price': '₹799',
      'status': 'assigned',
      'paymentStatus': 'Paid',
      'vendorName': 'Rahul Sharma',
      'coverImage': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop',
    },
    {
      'id': 'NEX-529104',
      'shopName': 'AC Service & Anti-Rust Coating',
      'serviceName': 'AC Repair',
      'category': 'Appliance',
      'date': '15 Jul 2026',
      'time': '02:00 PM',
      'price': '₹599',
      'status': 'completed',
      'paymentStatus': 'Paid',
      'vendorName': 'Vikram Singh',
      'coverImage': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
    },
    {
      'id': 'NEX-194820',
      'shopName': 'Full Body Swedish Massage',
      'serviceName': 'Spa for Women',
      'category': 'Salon',
      'date': '02 Jun 2026',
      'time': '11:00 AM',
      'price': '₹1299',
      'status': 'canceled',
      'paymentStatus': 'Refunded',
      'vendorName': 'Ananya Verma',
      'coverImage': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=300&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Bookings by Status',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Assigned', 'Confirmed', 'In Progress', 'Completed', 'Canceled'].map((filter) {
                final bool isSelected = _selectedFilterStatus == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEFF6FF),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? _blue : _gray,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedFilterStatus = filter);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Bookings',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _dark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'STATUS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _gray,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: ['All', 'Assigned', 'Confirmed', 'In Progress', 'Completed', 'Canceled'].map((filter) {
                      final bool isSelected = _selectedFilterStatus == filter;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedFilterStatus = filter);
                            Navigator.pop(context); // Close Drawer
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _blue : const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  filter,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? _blue : _dark,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: _blue, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () {
            if (_isSearchVisible) {
              setState(() {
                _isSearchVisible = false;
                _searchController.clear();
              });
            } else {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            }
          },
        ),
        title: _isSearchVisible
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: _gray, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(fontSize: 13, color: _dark),
                        decoration: InputDecoration(
                          hintText: 'Search ID, Service, Vendor…',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                        child: const Icon(Icons.clear_rounded, color: _gray, size: 18),
                      ),
                  ],
                ),
              )
            : Text('My Bookings History',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        actions: [
          if (!_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: _dark, size: 20),
              onPressed: () {
                setState(() {
                  _isSearchVisible = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded, color: _dark, size: 20),
              onPressed: () {
                setState(() {
                  _isSearchVisible = false;
                  _searchController.clear();
                });
              },
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: _dark, size: 20),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _blue,
          unselectedLabelColor: _gray,
          indicatorColor: _blue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Canceled'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user?.uid ?? 'guest_user')
            .snapshots(),
        builder: (context, snap) {
          List<Map<String, dynamic>> allBookings = _fallbackBookings;
          if (snap.hasData && snap.data!.docs.isNotEmpty) {
            allBookings = snap.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {'docId': d.id, ...data};
            }).toList();
          }

          // Search Filter
          final query = _searchController.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            allBookings = allBookings.where((b) {
              final id = (b['id'] ?? b['docId'] ?? '').toString().toLowerCase();
              final title = (b['shopName'] ?? b['serviceName'] ?? '').toString().toLowerCase();
              final vName = (b['vendorName'] ?? '').toString().toLowerCase();
              return id.contains(query) || title.contains(query) || vName.contains(query);
            }).toList();
          }

          // Filter Sheet Status
          if (_selectedFilterStatus != 'All') {
            allBookings = allBookings.where((b) {
              final st = (b['status'] ?? b['bookingStatus'] ?? '').toString().toLowerCase();
              return st == _selectedFilterStatus.toLowerCase();
            }).toList();
          }

          final activeBookings = allBookings.where((b) {
            final st = (b['status'] ?? b['bookingStatus'] ?? '').toString().toLowerCase();
            return st != 'completed' && st != 'canceled';
          }).toList();

          final completedBookings = allBookings.where((b) {
            final st = (b['status'] ?? b['bookingStatus'] ?? '').toString().toLowerCase();
            return st == 'completed';
          }).toList();

          final canceledBookings = allBookings.where((b) {
            final st = (b['status'] ?? b['bookingStatus'] ?? '').toString().toLowerCase();
            return st == 'canceled';
          }).toList();

          return Column(
            children: [
              // ── Statistics Summary Bar ────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statBadge('${allBookings.length}', 'Total Bookings', _blue),
                    _vDivider(),
                    _statBadge('${activeBookings.length}', 'Active', const Color(0xFFD97706)),
                    _vDivider(),
                    _statBadge('${completedBookings.length}', 'Completed', _green),
                    _vDivider(),
                    _statBadge('${canceledBookings.length}', 'Canceled', Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _bookingList(activeBookings, tabType: 'active'),
                    _bookingList(completedBookings, tabType: 'completed'),
                    _bookingList(canceledBookings, tabType: 'canceled'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }

  Widget _bookingList(List<Map<String, dynamic>> bookings, {required String tabType}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 54, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No Bookings Found',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 4),
            Text('Book your first home service with Nexora today!',
                style: GoogleFonts.inter(fontSize: 12, color: _gray)),
            const SizedBox(height: 18),
            ElevatedButton(
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Explore Services', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final b = bookings[i];
        final bId = b['id'] ?? b['docId'] ?? 'NEX-1000';
        final title = b['shopName'] ?? b['serviceName'] ?? 'Service';
        final dateStr = b['date'] ?? 'Scheduled';
        final timeStr = b['time'] ?? '';
        final price = b['price'] ?? '₹499';
        final img = b['coverImage'] ?? b['imageUrl'] ?? '';
        final status = (b['status'] ?? 'assigned').toString().toUpperCase();
        final vName = b['vendorName'] ?? 'Rahul Sharma';

        Color badgeBg = const Color(0xFFEFF6FF);
        Color badgeFg = _blue;
        if (tabType == 'completed') {
          badgeBg = const Color(0xFFECFDF5);
          badgeFg = _green;
        } else if (tabType == 'canceled') {
          badgeBg = const Color(0xFFFEF2F2);
          badgeFg = Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bId, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _blue)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: badgeFg),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: _border),
              ),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: img.startsWith('http')
                        ? Image.network(img, width: 64, height: 64, fit: BoxFit.cover)
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
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                        const SizedBox(height: 3),
                        Text('$dateStr · $timeStr', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(price.toString(), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                            Text('Pro: $vName', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Action Buttons
              if (tabType == 'active')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LiveTrackingScreen(bookingId: bId)),
                          );
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 15),
                        label: Text('Track Live Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                )
              else if (tabType == 'completed')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ServiceCompletedScreen(bookingId: bId)),
                          );
                        },
                        icon: const Icon(Icons.receipt_long_rounded, size: 15),
                        label: Text('Invoice & Summary', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _border),
                          foregroundColor: _dark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateReviewScreen(
                                bookingId: bId,
                                vendorName: vName,
                                serviceTitle: title,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_rounded, size: 15),
                        label: Text('Rate & Review', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Booking Canceled. 100% Refund processed to original payment method.',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
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

  Widget _statBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: _gray, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 24, color: _border);
}
