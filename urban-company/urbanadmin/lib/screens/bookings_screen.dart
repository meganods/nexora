import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/smart_assignment_service.dart';
import 'dart:js' as js;

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  // Filters State
  String _selectedStatus = 'All Statuses';
  String _selectedCategory = 'All Categories';
  String _selectedService = 'All Services';
  String _selectedVendor = 'All Vendors';
  String _selectedDateText = '30 Jul 2025';
  DateTimeRange? _selectedDateRange;
  List<QueryDocumentSnapshot> _lastFilteredDocs = [];

  // KPI calculations
  int _totalBookings = 1284;
  int _assignedCount = 426;
  int _inProgressCount = 318;
  int _completedCount = 412;
  int _cancelledCount = 128;

  // Custom Overlay toast notification on top-right side
  void _showTopRightToast(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B3DF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.bell, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 28.0, right: 28.0, bottom: 28.0, top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPixelHeader(),
          const SizedBox(height: 28),
          _buildKpiGrid(),
          const SizedBox(height: 28),
          _buildFilterPanel(),
          const SizedBox(height: 28),
          _buildMainTable(),
          const SizedBox(height: 28),
          _buildBottomAnalyticsGrid(),
        ],
      ),
    );
  }

  // 1. Pixel-Perfect Header
  Widget _buildPixelHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Management',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage and monitor all service bookings in real-time',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Export CSV button
        OutlinedButton.icon(
          onPressed: () {
            if (_lastFilteredDocs.isEmpty) {
              _showTopRightToast('No bookings available to export!');
              return;
            }
            _exportToCsvWeb(_lastFilteredDocs);
          },
          icon: const Icon(LucideIcons.download, size: 16),
          label: Text(
            'Export CSV',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5B3DF5),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 12),
        // Date badge with picker
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2025, 7, 30),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 520,
                    ),
                    child: child,
                  ),
                );
              },
            );
            if (date != null) {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              setState(() {
                _selectedDateText = "${date.day} ${months[date.month - 1]} ${date.year}";
              });
            }
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: Color(0xFF6B7280), size: 18),
                const SizedBox(width: 8),
                Text(
                  _selectedDateText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Real-time CSV generation and browser downloader
  void _exportToCsvWeb(List<QueryDocumentSnapshot> docs) {
    try {
      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Booking ID,Customer,Service,Category,Date,Time,Vendor,Price,Payment,Status');

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = data['id'] ?? doc.id;
        final userEmail = data['userEmail'] ?? 'vishal@gmail.com';
        final customerName = userEmail.split('@')[0];
        final service = data['serviceName'] ?? data['serviceType'] ?? 'Service';
        final category = data['categoryName'] ?? data['category'] ?? 'Category';
        final date = data['date'] ?? '31 Jul 2025';
        final time = data['time'] ?? '10:00 AM - 12:00 PM';
        final vendor = data['shopName'] ?? data['vendorName'] ?? 'Unassigned';
        final price = (data['price'] ?? '₹0').toString().replaceAll('₹', '').replaceAll(',', '').trim();
        final payment = data['paymentStatus'] ?? 'paid';
        final status = data['status'] ?? 'pending';

        csvBuffer.writeln('"$id","$customerName","$service","$category","$date","$time","$vendor","$price","$payment","$status"');
      }

      final bytes = csvBuffer.toString();
      final blobUrl = "data:text/csv;charset=utf-8," + Uri.encodeComponent(bytes);
      
      js.context.callMethod('open', [blobUrl, '_self']);
      _showTopRightToast('CSV file downloaded successfully!');
    } catch (e) {
      _showTopRightToast('Failed to export CSV: $e');
    }
  }

  // 2. Five Responsive KPI Cards
  Widget _buildKpiGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final double cardWidth = (width - (16 * 4)) / 5;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildKpiCard(
            'Total Bookings',
            '1,284',
            '▲ 12.5% vs last month',
            const Color(0xFF5B3DF5),
            LucideIcons.receipt,
            cardWidth,
            isTrend: true,
          ),
          _buildKpiCard(
            'Assigned',
            '426',
            '33.2% of total bookings',
            const Color(0xFF3B82F6),
            LucideIcons.checkSquare,
            cardWidth,
          ),
          _buildKpiCard(
            'In Progress',
            '318',
            '24.8% of total bookings',
            const Color(0xFFF59E0B),
            LucideIcons.clock,
            cardWidth,
          ),
          _buildKpiCard(
            'Completed',
            '412',
            '32.1% of total bookings',
            const Color(0xFF22C55E),
            LucideIcons.checkCircle,
            cardWidth,
          ),
          _buildKpiCard(
            'Cancelled',
            '128',
            '9.9% of total bookings',
            const Color(0xFFEF4444),
            LucideIcons.xCircle,
            cardWidth,
          ),
        ],
      );
    });
  }

  Widget _buildKpiCard(
    String title,
    String count,
    String sub,
    Color color,
    IconData icon,
    double width, {
    bool isTrend = false,
  }) {
    return Container(
      width: width.clamp(200.0, 450.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isTrend ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
                    fontWeight: isTrend ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 3. Filter Section
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: _selectedDateRange,
                      builder: (context, child) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 400,
                              maxHeight: 520,
                            ),
                            child: child,
                          ),
                        );
                      },
                    );
                    if (range != null) {
                      setState(() {
                        _selectedDateRange = range;
                      });
                    }
                  },
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDateRange == null
                                ? 'Select Date Range...'
                                : "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}",
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedDateRange != null)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF6B7280)),
                            onPressed: () {
                              setState(() {
                                _selectedDateRange = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status Dropdown
          _buildDropdown('Status', _selectedStatus, ['All Statuses', 'Pending', 'Assigned', 'In Progress', 'Completed', 'Cancelled'], (v) {
            setState(() => _selectedStatus = v!);
          }),
          const SizedBox(width: 12),
          // Category Dropdown
          _buildDropdown('Category', _selectedCategory, ['All Categories', 'AC Repair', 'Cleaning', 'Plumbing', 'Electrical'], (v) {
            setState(() => _selectedCategory = v!);
          }),
          const SizedBox(width: 12),
          // Service Dropdown
          _buildDropdown('Service', _selectedService, ['All Services', 'Premium AC Repair', 'Deep Home Cleaning', 'Leakage Repair', 'Electrical Work'], (v) {
            setState(() => _selectedService = v!);
          }),
          const SizedBox(width: 12),
          // Vendor Dropdown
          _buildDropdown('Vendor', _selectedVendor, ['All Vendors', 'CoolTech Services', 'CleanPro Experts', 'FixIt Plumbers', 'PowerFix Electricians'], (v) {
            setState(() => _selectedVendor = v!);
          }),
          const SizedBox(width: 16),
          // Filter submit button
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.sliders, size: 16),
              label: Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B3DF5),
                side: const BorderSide(color: Color(0xFF5B3DF5)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Clear All text button
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = 'All Statuses';
                  _selectedCategory = 'All Categories';
                  _selectedService = 'All Services';
                  _selectedVendor = 'All Vendors';
                  _selectedDateRange = null;
                });
              },
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  color: const Color(0xFF5B3DF5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String currentValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)),
                icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF6B7280)),
                items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Booking Table
  Widget _buildMainTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('BOOKING ID', style: _tableHeaderStyle())),
                Expanded(flex: 3, child: Text('CUSTOMER', style: _tableHeaderStyle())),
                Expanded(flex: 3, child: Text('SERVICE', style: _tableHeaderStyle())),
                Expanded(flex: 3, child: Text('DATE & TIME', style: _tableHeaderStyle())),
                Expanded(flex: 3, child: Text('VENDOR', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('AMOUNT', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('STATUS', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('PAYMENT', style: _tableHeaderStyle())),
                Expanded(flex: 1, child: Text('ACTIONS', style: _tableHeaderStyle(), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Live Firestore bookings builder
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF5B3DF5))),
                );
              }
              final rawDocs = snapshot.data?.docs ?? [];
              
              // Dynamic filters in memory
              var docs = rawDocs;
              if (_selectedDateRange != null) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['createdAt'] as Timestamp?;
                  if (timestamp != null) {
                    final date = timestamp.toDate();
                    return date.isAfter(_selectedDateRange!.start) &&
                           date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                  }
                  return false;
                }).toList();
              }
              if (_selectedStatus != 'All Statuses') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final s = (data['status'] ?? '').toString().toLowerCase();
                  if (_selectedStatus == 'In Progress') {
                    return s == 'in_progress' || s == 'work_started' || s == 'arrived' || s == 'en_route';
                  }
                  return s == _selectedStatus.toLowerCase();
                }).toList();
              }
              if (_selectedCategory != 'All Categories') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cat = (data['categoryName'] ?? data['category'] ?? '').toString().toLowerCase();
                  return cat == _selectedCategory.toLowerCase();
                }).toList();
              }
              if (_selectedService != 'All Services') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final srv = (data['serviceName'] ?? data['serviceType'] ?? '').toString().toLowerCase();
                  return srv == _selectedService.toLowerCase();
                }).toList();
              }
              if (_selectedVendor != 'All Vendors') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final vnd = (data['shopName'] ?? data['vendorName'] ?? '').toString().toLowerCase();
                  return vnd == _selectedVendor.toLowerCase();
                }).toList();
              }

              if (docs.isEmpty) {
                _lastFilteredDocs = [];
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Text(
                      'No matching bookings found.',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              _lastFilteredDocs = docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, idx) {
                  final doc = docs[idx];
                  final data = doc.data() as Map<String, dynamic>;
                  final String bookingId = data['id'] ?? doc.id;
                  final String userEmail = data['userEmail'] ?? 'vishal@gmail.com';
                  final String customerName = userEmail.split('@')[0];
                  final String initials = customerName.isNotEmpty ? customerName.substring(0, 2).toUpperCase() : 'US';
                  final String status = data['status'] ?? 'pending';

                  return InkWell(
                    onTap: () => _showBookingDetailsDialog(context, doc.id, data),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        children: [
                          // 1. BOOKING ID
                          Expanded(
                            flex: 2,
                            child: Text(
                              bookingId,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5B3DF5),
                              ),
                            ),
                          ),
                          // 2. CUSTOMER
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFDBEAFE),
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                      ),
                                      Text(
                                        '+91 98765 43210',
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 3. SERVICE
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['serviceName'] ?? data['serviceType'] ?? 'Service').toString(),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  (data['categoryName'] ?? data['category'] ?? 'Category').toString(),
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // 4. DATE & TIME
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 4),
                                    Text(
                                      data['date'] ?? '31 Jul 2025',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF111827)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, size: 12, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 4),
                                    Text(
                                      data['time'] ?? '10:00 AM - 12:00 PM',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // 5. VENDOR
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (data['shopName'] ?? data['vendorName'] ?? 'Awaiting Assignment').toString(),
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 12),
                                          const SizedBox(width: 2),
                                          Text(
                                            '4.8 (126) • 2.4 km',
                                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 6. AMOUNT
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['price'] ?? '₹499',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vendor: ₹299',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280)),
                                ),
                                Text(
                                  'Profit: ₹200',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          // 7. STATUS
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatusPill(status),
                                const SizedBox(height: 4),
                                Text(
                                  'Just now',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          // 8. PAYMENT
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPaymentBadge(data['paymentStatus'] ?? 'paid'),
                                const SizedBox(height: 4),
                                Text(
                                  'Online',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          // 9. ACTIONS
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: PopupMenuButton<String>(
                                icon: const Icon(LucideIcons.moreHorizontal, color: Color(0xFF6B7280), size: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                onSelected: (action) {
                                  if (action == 'view') {
                                    _showBookingDetailsDialog(context, doc.id, data);
                                  } else {
                                    _showTopRightToast('Triggered Action: $action');
                                  }
                                },
                                itemBuilder: (c) => [
                                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                                  const PopupMenuItem(value: 'assign', child: Text('Assign Vendor')),
                                  const PopupMenuItem(value: 'cancel', child: Text('Cancel Booking')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    String txt = status.toLowerCase();

    if (txt == 'assigned') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF3B82F6);
    } else if (txt == 'in progress' || txt == 'work_started' || txt == 'arrived' || txt == 'en_route') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFF59E0B);
      txt = 'In Progress';
    } else if (txt == 'completed') {
      bg = const Color(0xFFF0FDF4);
      fg = const Color(0xFF22C55E);
    } else if (txt == 'cancelled') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        txt.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildPaymentBadge(String pay) {
    Color bg = const Color(0xFFF0FDF4);
    Color fg = const Color(0xFF22C55E);
    String txt = 'Paid';

    if (pay.toLowerCase() == 'refunded') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFEF4444);
      txt = 'Refunded';
    } else if (pay.toLowerCase() == 'pending') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFF59E0B);
      txt = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        txt,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  TextStyle _tableHeaderStyle() => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
        letterSpacing: 0.5,
      );

  // 5. Five Bottom Analytics Cards with Custom Sparklines
  Widget _buildBottomAnalyticsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final double cardWidth = (width - (16 * 4)) / 5;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildAnalyticsCard('Total Revenue', '₹6,41,200', '▲ 18.6% vs last month', const Color(0xFF5B3DF5), cardWidth, [5, 12, 8, 16, 10, 22, 18, 30]),
          _buildAnalyticsCard('Vendor Payout', '₹4,21,850', '▲ 16.4% vs last month', const Color(0xFF3B82F6), cardWidth, [4, 8, 12, 10, 15, 14, 20, 25]),
          _buildAnalyticsCard('Platform Profit', '₹2,19,350', '▲ 23.7% vs last month', const Color(0xFFF59E0B), cardWidth, [2, 6, 4, 10, 8, 15, 12, 22]),
          _buildAnalyticsCard('Avg. Order Value', '₹499', '▲ 8.2% vs last month', const Color(0xFF22C55E), cardWidth, [15, 18, 14, 20, 16, 22, 19, 26]),
          _buildAnalyticsCard('Completion Rate', '89.2%', '▲ 5.4% vs last month', const Color(0xFFEF4444), cardWidth, [22, 24, 20, 28, 25, 30, 27, 32]),
        ],
      );
    });
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    String change,
    Color color,
    double width,
    List<double> sparkData,
  ) {
    return Container(
      width: width.clamp(200.0, 450.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          // Custom sparkline chart
          SizedBox(
            height: 38,
            width: double.infinity,
            child: CustomPaint(
              painter: _SimpleSparklinePainter(sparkData, color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            change,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Booking Details Modal Sheet Dialog
  void _showBookingDetailsDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        String currentStatus = data['status'] ?? 'pending';
        String paymentStatus = data['paymentStatus'] ?? 'paid';
        String? selectedVendorId = data['vendorId'];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking Details',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: Color(0xFFE5E7EB)),

                      _detailRow('Booking ID', docId),
                      _detailRow('Customer Email', data['userEmail'] ?? 'N/A'),
                      _detailRow('Shop Name', data['shopName'] ?? 'Urban Service Pro'),
                      _detailRow('Selected Slot', '${data['date'] ?? "Today"} at ${data['time'] ?? "10:00 AM"}'),
                      _detailRow('Paid Amount', data['price'] ?? '₹0'),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Booking Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280))),
                                const SizedBox(height: 6),
                                _buildStatusPill(currentStatus),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280))),
                                const SizedBox(height: 6),
                                _buildPaymentBadge(paymentStatus),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 16),

                      // Booking Timeline Logs (Read from Firestore)
                      Text('Booking Timeline', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('booking_timeline')
                            .where('bookingId', isEqualTo: docId)
                            .snapshots(),
                        builder: (ctx, timelineSnap) {
                          if (!timelineSnap.hasData) {
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B3DF5)),
                              ),
                            );
                          }
                          final rawDocs = timelineSnap.data!.docs;
                          final steps = List<QueryDocumentSnapshot>.from(rawDocs);
                          steps.sort((a, b) {
                            final tsA = (a.data() as Map)['timestamp'] as Timestamp?;
                            final tsB = (b.data() as Map)['timestamp'] as Timestamp?;
                            if (tsA == null) return 1;
                            if (tsB == null) return -1;
                            return tsA.compareTo(tsB);
                          });
                          if (steps.isEmpty) {
                            return Text('No timeline entries yet.', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey));
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: steps.map((sDoc) {
                              final sData = sDoc.data() as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF5B3DF5)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "${sData['title'] ?? 'Updated'}: ${sData['description'] ?? ''}",
                                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 16),

                      // Before Photos
                      if (data['beforePhotos'] != null && (data['beforePhotos'] as List).isNotEmpty) ...[
                        Text('Before Photos', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: (data['beforePhotos'] as List).map((photoUrl) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photoUrl.toString(),
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 120,
                                  height: 100,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                      ],

                      // After Photos
                      if (data['afterPhotos'] != null && (data['afterPhotos'] as List).isNotEmpty) ...[
                        Text('After Photos', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: (data['afterPhotos'] as List).map((photoUrl) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photoUrl.toString(),
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 120,
                                  height: 100,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                      ],

                      // Settlement Ledger (Phase 7)
                      if (currentStatus == 'COMPLETED') ...[
                        Text('Settlement Ledger', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                        const SizedBox(height: 12),
                        _detailRow('Settlement Amount', '₹${(data['settlementAmount'] ?? (double.tryParse((data['price'] ?? '').replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0) * 0.85).toStringAsFixed(2)}'),
                        _detailRow('Settlement Status', (data['settlementStatus'] ?? 'pending').toString().toUpperCase()),
                        _detailRow('Transfer Date', data['settlementTransferDate'] != null ? (data['settlementTransferDate'] as Timestamp).toDate().toString() : 'N/A'),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                      ],

                      Text('Assign Vendor', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                      const SizedBox(height: 12),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('vendors').where('status', isEqualTo: 'APPROVED').snapshots(),
                        builder: (ctx, vendorSnap) {
                          if (!vendorSnap.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final vendors = vendorSnap.data!.docs;
                          final vendorIds = vendors.map((v) => v.id).toList();
                          final String? resolvedVendorId = vendorIds.contains(selectedVendorId) ? selectedVendorId : null;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: resolvedVendorId,
                                isExpanded: true,
                                hint: Text('Select Vendor manually...', style: GoogleFonts.inter(fontSize: 13)),
                                items: vendors.map((vDoc) {
                                  final vData = vDoc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: vDoc.id,
                                    child: Text(
                                      vData['businessName'] ?? vData['name'] ?? 'Vendor Pro',
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  setModalState(() {
                                    selectedVendorId = newVal;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (currentStatus == 'waiting_for_verification') ...[
                            // Verify Button
                            ElevatedButton(
                              onPressed: () async {
                                final double amount = (double.tryParse((data['price'] ?? '').replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0) * 0.85;
                                await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                                  'status': 'COMPLETED',
                                  'settlementStatus': 'pending',
                                  'settlementAmount': amount,
                                });
                                await FirebaseFirestore.instance.collection('booking_timeline').add({
                                  'bookingId': docId,
                                  'status': 'completed',
                                  'title': 'Completed & Verified',
                                  'description': 'Admin verified and finalized the service.',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showTopRightToast('Booking Verified & Completed!');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Verify'),
                            ),
                            const SizedBox(width: 8),
                          ],

                          if (currentStatus == 'COMPLETED') ...[
                            if ((data['settlementStatus'] ?? 'pending') == 'pending')
                              ElevatedButton(
                                onPressed: () async {
                                  final double amount = (data['settlementAmount'] ?? (double.tryParse((data['price'] ?? '').replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0) * 0.85);
                                  await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                                    'settlementStatus': 'approved',
                                    'settlementAmount': amount,
                                  });
                                  await FirebaseFirestore.instance.collection('booking_timeline').add({
                                    'bookingId': docId,
                                    'status': 'settlement_approved',
                                    'title': 'Settlement Approved',
                                    'description': 'Vendor settlement of ₹${amount.toStringAsFixed(2)} has been approved by admin.',
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _showTopRightToast('Settlement Approved!');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Approve Settlement'),
                              ),
                            if ((data['settlementStatus'] ?? 'pending') == 'approved')
                              ElevatedButton(
                                onPressed: () async {
                                  final double amount = (data['settlementAmount'] ?? (double.tryParse((data['price'] ?? '').replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0) * 0.85);
                                  
                                  await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                                    'settlementStatus': 'transferred',
                                    'settlementTransferDate': FieldValue.serverTimestamp(),
                                  });

                                  final String vId = data['vendorId'] ?? 'vendor_01';
                                  await FirebaseFirestore.instance.collection('vendors').doc(vId).update({
                                    'walletBalance': FieldValue.increment(amount),
                                  });

                                  await FirebaseFirestore.instance.collection('booking_timeline').add({
                                    'bookingId': docId,
                                    'status': 'settlement_transferred',
                                    'title': 'Settlement Transferred',
                                    'description': 'Settlement amount of ₹${amount.toStringAsFixed(2)} transferred to vendor wallet successfully.',
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _showTopRightToast('Settlement Transferred successfully!');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Transfer Settlement'),
                              ),
                            const SizedBox(width: 8),
                          ],

                          if (paymentStatus != 'refunded')
                            OutlinedButton.icon(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                                  'paymentStatus': 'refunded',
                                  'status': 'CANCELLED',
                                });
                                await FirebaseFirestore.instance.collection('booking_timeline').add({
                                  'bookingId': docId,
                                  'status': 'cancelled',
                                  'title': 'Booking Refunded',
                                  'description': 'Admin processed a full refund for this booking.',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showTopRightToast('Refund processed successfully');
                                }
                              },
                              icon: const Icon(Icons.currency_rupee_rounded, size: 14),
                              label: const Text('Refund'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          const SizedBox(width: 8),

                          if (currentStatus != 'CANCELLED')
                            OutlinedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                                  'status': 'CANCELLED',
                                });
                                await FirebaseFirestore.instance.collection('booking_timeline').add({
                                  'bookingId': docId,
                                  'status': 'cancelled',
                                  'title': 'Booking Cancelled',
                                  'description': 'Booking has been cancelled by Nexora Admin.',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showTopRightToast('Booking Cancelled');
                                }
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[700]),
                              child: const Text('Cancel'),
                            ),
                          const SizedBox(width: 8),

                          if (currentStatus == 'pending')
                            ElevatedButton(
                              onPressed: () async {
                                final priceString = (data['price'] ?? '0').toString();
                                final priceVal = double.tryParse(priceString.replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
                                
                                final bestVendor = await SmartAssignmentService.assignBestVendor(
                                  categoryName: data['categoryName'] ?? data['category'] ?? '',
                                  userCity: data['city'] ?? data['address']?.toString().split(',').last.trim() ?? '',
                                  bookingPrice: priceVal,
                                  subServiceId: data['subServiceId'],
                                );

                                if (bestVendor == null) {
                                  if (context.mounted) {
                                    _showTopRightToast('No eligible vendors found matching criteria!');
                                  }
                                  return;
                                }

                                final String vId = bestVendor['id'] ?? '';
                                final String shopName = bestVendor['businessName'] ?? bestVendor['name'] ?? 'Urban Service Pro';

                                await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                                  'vendorId': vId,
                                  'shopName': shopName,
                                  'status': 'assigned',
                                  'assignmentMethod': 'AUTO',
                                  'assignmentTime': FieldValue.serverTimestamp(),
                                });

                                await FirebaseFirestore.instance.collection('booking_timeline').add({
                                  'bookingId': docId,
                                  'status': 'assigned',
                                  'title': 'Auto Assigned',
                                  'description': 'System auto-assigned this booking to $shopName.',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showTopRightToast('Auto assigned to $shopName');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Auto Assign'),
                            ),
                          const SizedBox(width: 8),

                          ElevatedButton(
                            onPressed: selectedVendorId == null
                                ? null
                                : () async {
                                    final vDoc = await FirebaseFirestore.instance
                                        .collection('vendors')
                                        .doc(selectedVendorId)
                                        .get();
                                    final vData = vDoc.data();
                                    final shopName = vData?['businessName'] ?? vData?['name'] ?? 'Urban Service Pro';

                                    await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                                      'vendorId': selectedVendorId,
                                      'shopName': shopName,
                                      'status': 'assigned',
                                    });

                                    await FirebaseFirestore.instance.collection('booking_timeline').add({
                                      'bookingId': docId,
                                      'status': 'assigned',
                                      'title': 'Manual Assigned',
                                      'description': 'Admin manually assigned this booking to $shopName.',
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      _showTopRightToast('Manually assigned to $shopName');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B3DF5),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Manual Assign'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
          Text(val, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontSize: 13)),
        ],
      ),
    );
  }
}

// 6. Custom Sparkline Graph Painter
class _SimpleSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SimpleSparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      // Map to size.height with 4px padding
      final double y = size.height - 4 - ((data[i] - minVal) / range) * (size.height - 8);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
