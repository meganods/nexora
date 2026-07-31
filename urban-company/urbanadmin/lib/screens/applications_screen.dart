import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:js' as js;

class ApplicationsScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onViewDetails;

  const ApplicationsScreen({super.key, this.onViewDetails});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  // Filters State
  String _selectedStatusTab = 'All';
  String _selectedStatus = 'All Statuses';
  String _selectedCategory = 'All Services';
  String _selectedCity = 'All Cities';
  DateTimeRange? _selectedDateRange;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination State
  int _rowsPerPage = 10;
  int _currentPage = 1;

  // Header date state
  String _selectedDateText = '30 Jul 2025';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                    color: Color(0xFF2563EB),
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
          _buildApplicationsTable(),
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
              'Vendor Applications',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '14 pending review',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '•   Priority Queue: High',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 28),
        _buildStatusToggle(),
        const Spacer(),
        // Notification Badge Icon
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(LucideIcons.bell, color: Color(0xFF64748B), size: 20),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '8',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Date badge
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
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.calendar, color: Color(0xFF64748B), size: 18),
                const SizedBox(width: 8),
                Text(
                  _selectedDateText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('All'),
          const SizedBox(width: 4),
          _buildToggleOption('Pending'),
          const SizedBox(width: 4),
          _buildToggleOption('Archived'),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label) {
    final isActive = _selectedStatusTab == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatusTab = label;
          _currentPage = 1;
        });
        _showTopRightToast('Viewing $label applications');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // 2. Five Responsive KPI Cards with Sparklines
  Widget _buildKpiGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final double cardWidth = (width - (16 * 4)) / 5;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildKpiCard('TOTAL APPLICATIONS', '1,284', '▲ 12.5% vs last month', const Color(0xFF2563EB), LucideIcons.fileText, cardWidth, [4, 8, 5, 10, 7, 14, 11, 18]),
          _buildKpiCard('PENDING REVIEW', '42', '▲ 8.2% vs last month', const Color(0xFFF59E0B), LucideIcons.clock, cardWidth, [2, 4, 3, 6, 5, 8, 6, 10]),
          _buildKpiCard('APPROVED', '896', '▲ 18.7% vs last month', const Color(0xFF10B981), LucideIcons.checkCircle, cardWidth, [5, 10, 9, 14, 11, 18, 15, 22]),
          _buildKpiCard('REJECTED', '214', '▼ 5.1% vs last month', const Color(0xFFEF4444), LucideIcons.xCircle, cardWidth, [8, 7, 6, 5, 4, 3, 2, 1], isDown: true),
          _buildKpiCard('CHANGES REQUESTED', '132', '▲ 2.4% vs last month', const Color(0xFF38BDF8), LucideIcons.edit, cardWidth, [10, 12, 11, 14, 13, 16, 15, 20]),
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
    double width,
    List<double> sparkData, {
    bool isDown = false,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: GoogleFonts.inter(fontSize: 11, color: isDown ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Mini sparkline graph
          SizedBox(
            width: 48,
            height: 32,
            child: CustomPaint(
              painter: _MiniSparkPainter(sparkData, color),
            ),
          )
        ],
      ),
    );
  }

  // 3. Filter Section
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // Status Dropdown
          _buildDropdown('Status', _selectedStatus, ['All Statuses', 'PENDING', 'APPROVED', 'REJECTED'], (v) {
            setState(() => _selectedStatus = v!);
          }),
          const SizedBox(width: 12),
          // Category Dropdown
          _buildDropdown('Category', _selectedCategory, ['All Services', 'AC Repair', 'Cleaning', 'Plumbing', 'Electrical'], (v) {
            setState(() => _selectedCategory = v!);
          }),
          const SizedBox(width: 12),
          // City Dropdown
          _buildDropdown('City', _selectedCity, ['All Cities', 'Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Chennai'], (v) {
            setState(() => _selectedCity = v!);
          }),
          const SizedBox(width: 12),
          // Date Range picker
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Range',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
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
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDateRange == null
                                ? 'Select Date Range...'
                                : "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}",
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedDateRange != null)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(LucideIcons.x, size: 14, color: Color(0xFF64748B)),
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
          // Search box
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Vendor',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Search vendor name, ID, phone...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(top: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Outlined filters button (Blue Accent)
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.sliders, size: 16),
              label: Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reset all text button
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = 'All Statuses';
                  _selectedCategory = 'All Services';
                  _selectedCity = 'All Cities';
                  _selectedDateRange = null;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: Text(
                'Reset All',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2563EB),
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
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
                items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Vendor Applications Table
  Widget _buildApplicationsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Headers row
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
                Expanded(flex: 3, child: Text('APPLICATION ID', style: _tableHeaderStyle())),
                Expanded(flex: 3, child: Text('VENDOR', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('CATEGORY', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('CITY', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('APPLIED DATE', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('STATUS', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('KYC STATUS', style: _tableHeaderStyle())),
                Expanded(flex: 4, child: Text('QUICK ACTIONS', style: _tableHeaderStyle(), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Applications Stream builder
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
                );
              }
              final rawDocs = snapshot.data?.docs ?? [];

              // Apply Filters in memory
              var docs = rawDocs;

              // Filter based on selected Tab (All, Pending, Archived)
              if (_selectedStatusTab == 'Pending') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final s = (data['status'] ?? '').toString().toUpperCase();
                  return s == 'PENDING' || s == 'PENDING REVIEW' || s == '';
                }).toList();
              } else if (_selectedStatusTab == 'Archived') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final s = (data['status'] ?? '').toString().toUpperCase();
                  return s == 'APPROVED' || s == 'REJECTED' || s == 'BLOCKED';
                }).toList();
              }

              // Dropdown Status filter
              if (_selectedStatus != 'All Statuses') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final s = (data['status'] ?? '').toString().toUpperCase();
                  return s == _selectedStatus;
                }).toList();
              }
              // Category filter
              if (_selectedCategory != 'All Services') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cat = (data['mainCategory'] ?? data['category'] ?? '').toString().toLowerCase();
                  return cat == _selectedCategory.toLowerCase();
                }).toList();
              }
              // City filter
              if (_selectedCity != 'All Cities') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final city = (data['city'] ?? '').toString().toLowerCase();
                  return city == _selectedCity.toLowerCase();
                }).toList();
              }
              // Date Range filter
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
              // Search query filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? data['businessName'] ?? '').toString().toLowerCase();
                  final id = doc.id.toLowerCase();
                  final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || id.contains(_searchQuery) || phone.contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Text(
                      'No matching applications found.',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              // Compute slice for pagination
              final totalItems = docs.length;
              final startIndex = (_currentPage - 1) * _rowsPerPage;
              final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
              final paginatedDocs = docs.sublist(startIndex, endIndex);

              return Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paginatedDocs.length,
                    separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (context, idx) {
                      final doc = paginatedDocs[idx];
                      final data = doc.data() as Map<String, dynamic>;
                      final String vendorId = doc.id;
                      final String name = (data['name'] ?? data['businessName'] ?? 'N/A').toString();
                      final String email = (data['email'] ?? 'N/A').toString();
                      final String phone = (data['phone'] ?? data['phoneNumber'] ?? 'N/A').toString();
                      final String category = (data['mainCategory'] ?? data['category'] ?? 'N/A').toString();
                      final String city = (data['city'] ?? 'N/A').toString();
                      final String status = (data['status'] ?? 'pending').toString();
                      final String kycStatus = (data['kycStatus'] ?? 'Processed').toString();

                      // Handle date formatting
                      String formattedDate = '24 Jun 2025';
                      String formattedTime = '10:30 AM';
                      if (data['createdAt'] != null) {
                        try {
                          final dt = (data['createdAt'] is Timestamp)
                              ? (data['createdAt'] as Timestamp).toDate()
                              : DateTime.parse(data['createdAt'].toString());
                          formattedDate = DateFormat('dd MMM yyyy').format(dt);
                          formattedTime = DateFormat('hh:mm a').format(dt);
                        } catch (e) {
                          // use fallback defaults
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            // 1. APPLICATION ID
                            Expanded(
                              flex: 3,
                              child: Text(
                                'APP-2025-${vendorId.toUpperCase().substring(0, 5)}',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                              ),
                            ),
                            // 2. VENDOR NAME & CONTACTS
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          email,
                                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          phone,
                                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 3. CATEGORY PILL
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                  ),
                                ),
                              ),
                            ),
                            // 4. CITY
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(city, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                            // 5. APPLIED DATE
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(formattedDate, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.clock, size: 12, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(formattedTime, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // 6. STATUS
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildStatusBadge(status),
                              ),
                            ),
                            // 7. KYC STATUS
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Icon(
                                    kycStatus.toLowerCase() == 'processed' ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                                    size: 14,
                                    color: kycStatus.toLowerCase() == 'processed' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    kycStatus,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kycStatus.toLowerCase() == 'processed' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 8. QUICK ACTIONS (DETAILS, APPROVE/REJECT, MORE)
                            Expanded(
                              flex: 4,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Details button (Blue border outline)
                                  OutlinedButton(
                                    onPressed: () {
                                      final Map<String, dynamic> appWithId = Map.from(data);
                                      appWithId['id'] = vendorId;
                                      widget.onViewDetails?.call(appWithId);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(color: Color(0xFF2563EB)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  // Action Approve or Reject
                                  status.toUpperCase() == 'APPROVED'
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Approved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                        )
                                      : status.toUpperCase() == 'REJECTED'
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEE2E2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text('Rejected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                                            )
                                          : ElevatedButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance.collection('vendors').doc(vendorId).update({
                                                  'status': 'APPROVED',
                                                });
                                                _showTopRightToast('$name approved successfully!');
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                elevation: 0,
                                              ),
                                              child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                  const SizedBox(width: 6),
                                  // Three-dots menu button
                                  InkWell(
                                    onTap: () {
                                      _showTopRightToast('More actions opened for $name');
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(LucideIcons.moreHorizontal, size: 14, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Pagination Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${startIndex + 1} to $endIndex of $totalItems applications',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                        const Spacer(),
                        // Pagination buttons
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.chevronLeft, size: 16),
                              onPressed: _currentPage > 1
                                  ? () => setState(() => _currentPage--)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            _buildPageNum(1),
                            if (totalItems > _rowsPerPage * 3) ...[
                              _buildPageNum(2),
                              _buildPageNum(3),
                              Text('...', style: GoogleFonts.inter(color: Colors.grey)),
                              _buildPageNum((totalItems / _rowsPerPage).ceil()),
                            ],
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(LucideIcons.chevronRight, size: 16),
                              onPressed: _currentPage < (totalItems / _rowsPerPage).ceil()
                                  ? () => setState(() => _currentPage++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Rows per page dropdown
                        Text('Rows per page: ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: DropdownButton<int>(
                            value: _rowsPerPage,
                            underline: const SizedBox(),
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
                            items: [5, 10, 20].map((val) => DropdownMenuItem(value: val, child: Text(val.toString()))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _rowsPerPage = val!;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    String txt = status.toUpperCase();

    if (txt == 'APPROVED' || txt == 'ACTIVE') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF10B981);
      txt = 'Approved';
    } else if (txt == 'PENDING' || txt == 'PENDING REVIEW') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFF59E0B);
      txt = 'Pending Review';
    } else if (txt == 'REJECTED' || txt == 'BLOCKED') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFEF4444);
      txt = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            txt,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNum(int page) {
    final isActive = page == _currentPage;
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        height: 28,
        width: 28,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          page.toString(),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle() => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      );
}

// Custom Painter to render mini KPI sparklines
class _MiniSparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _MiniSparkPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
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
      final double y = size.height - 2 - ((data[i] - minVal) / range) * (size.height - 4);

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
