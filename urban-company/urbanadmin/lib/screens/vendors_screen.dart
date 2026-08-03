import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VendorsScreen extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onVendorSelected;

  const VendorsScreen({super.key, this.onVendorSelected});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  // Filters State
  String _selectedStatus = 'All Statuses';
  String _selectedCategory = 'All Categories';
  String _selectedCity = 'All Cities';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination State
  int _rowsPerPage = 10;
  int _currentPage = 1;

  // Header date state
  String _selectedDateText = '30 Jul 2025';

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
                    color: Color(0xFF5B21B6),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPixelHeader(),
          const SizedBox(height: 28),
          _buildKpiGrid(),
          const SizedBox(height: 28),
          _buildFilterPanel(),
          const SizedBox(height: 28),
          _buildVendorTable(),
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
              'Partner Ecosystem',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage, verify, and monitor your service partners at scale.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Notification Badge Icon
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(LucideIcons.bell, color: Color(0xFF6B7280), size: 20),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '12',
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

  // 2. Five Responsive KPI Cards with Sparklines
  Widget _buildKpiGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final double cardWidth = (width - (16 * 4)) / 5;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildKpiCard('TOTAL PARTNERS', '1,284', '▲ 4.2% vs last month', const Color(0xFF5B21B6), Icons.storefront_rounded, cardWidth, [4, 8, 5, 10, 7, 14, 11, 18]),
          _buildKpiCard('ACTIVE PARTNERS', '1,102', '▲ 12% vs last month', const Color(0xFF10B981), Icons.verified_user_rounded, cardWidth, [5, 10, 9, 14, 11, 18, 15, 22]),
          _buildKpiCard('PENDING REVIEW', '42', '▲ 8 vs last month', const Color(0xFFF59E0B), Icons.pending_actions_rounded, cardWidth, [2, 4, 3, 6, 5, 8, 6, 10]),
          _buildKpiCard('BLOCKED', '14', '▼ 2 vs last month', const Color(0xFFEF4444), Icons.block_rounded, cardWidth, [8, 7, 6, 5, 4, 3, 2, 1], isDown: true),
          _buildKpiCard('TOP RATED', '85', '▲ 5 vs last month', const Color(0xFFEC4899), Icons.star_rounded, cardWidth, [10, 12, 11, 14, 13, 16, 15, 20]),
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
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280), fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: GoogleFonts.inter(fontSize: 11, color: isDown ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Mini sparkline graph on right
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
          _buildDropdown('Status', _selectedStatus, ['All Statuses', 'Active', 'Pending Review', 'Blocked'], (v) {
            setState(() => _selectedStatus = v!);
          }),
          const SizedBox(width: 12),
          // Category Dropdown
          _buildDropdown('Category', _selectedCategory, ['All Categories', 'AC Repair', 'Cleaning', 'Plumbing', 'Electrical'], (v) {
            setState(() => _selectedCategory = v!);
          }),
          const SizedBox(width: 12),
          // City Dropdown
          _buildDropdown('City', _selectedCity, ['All Cities', 'Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Chennai'], (v) {
            setState(() => _selectedCity = v!);
          }),
          const SizedBox(width: 12),
          // Search box
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Partner',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Search partner name, ID, phone...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF6B7280)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(top: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Outlined filters action button
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.sliders, size: 16),
              label: Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B21B6),
                side: const BorderSide(color: Color(0xFF5B21B6)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Clear filter button
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = 'All Statuses';
                  _selectedCategory = 'All Categories';
                  _selectedCity = 'All Cities';
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: Text(
                'Clear Filters',
                style: GoogleFonts.inter(
                  color: const Color(0xFF5B21B6),
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

  // 4. Vendor Table Data List View
  Widget _buildVendorTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                Expanded(flex: 3, child: Text('SERVICE PARTNER', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('CATEGORY', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('ONBOARDED DATE', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('STATUS', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('RATING', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('COMPLETED JOBS', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('ACTIONS', style: _tableHeaderStyle(), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Vendor Stream builder
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF5B21B6))),
                );
              }
              final rawDocs = snapshot.data?.docs ?? [];

              // Apply Filters in memory
              var docs = rawDocs;
              if (_selectedStatus != 'All Statuses') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  if (_selectedStatus == 'Active') return status == 'approved' || status == 'active';
                  if (_selectedStatus == 'Pending Review') return status == 'pending' || status == 'pending review';
                  return status == _selectedStatus.toLowerCase();
                }).toList();
              }
              if (_selectedCategory != 'All Categories') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cat = (data['mainCategory'] ?? data['category'] ?? '').toString().toLowerCase();
                  return cat == _selectedCategory.toLowerCase();
                }).toList();
              }
              if (_selectedCity != 'All Cities') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final city = (data['city'] ?? '').toString().toLowerCase();
                  return city == _selectedCity.toLowerCase();
                }).toList();
              }
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
                      'No matching partners found.',
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
                    separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, idx) {
                      final doc = paginatedDocs[idx];
                      final data = doc.data() as Map<String, dynamic>;
                      final String vendorId = doc.id;
                      final String name = (data['name'] ?? data['businessName'] ?? 'N/A').toString();
                      final String phone = (data['phone'] ?? data['phoneNumber'] ?? '+91 98765 43210').toString();
                      final String category = (data['mainCategory'] ?? data['category'] ?? 'N/A').toString();
                      final String status = (data['status'] ?? 'pending').toString();

                      // Rating
                      final double rating = ((data['rating'] ?? 4.5) as num).toDouble();
                      final int reviews = (data['reviewsCount'] ?? data['totalReviews'] ?? 128) as int;

                      // Completed jobs
                      final int jobs = (data['completedJobs'] ?? data['jobsCompleted'] ?? 245) as int;
                      final int completionVal = (data['completionRate'] ?? 98) as int;

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

                      return InkWell(
                        onTap: () => widget.onVendorSelected?.call(data),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              // 1. VENDOR PROFILE INFO
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFF3E8FF),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF5B21B6)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ID: ${vendorId.toUpperCase().substring(0, 8)}',
                                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                          ),
                                          Text(
                                            phone,
                                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 2. CATEGORY BADGE
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category,
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5B21B6)),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Home Services',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                              // 3. JOINED DATE
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 4),
                                        Text(formattedDate, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF111827))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock, size: 12, color: Color(0xFF6B7280)),
                                        const SizedBox(width: 4),
                                        Text(formattedTime, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // 4. STATUS PILL
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildStatusBadge(status),
                                ),
                              ),
                              // 5. RATING
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '($reviews)',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                              // 6. COMPLETED JOBS
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      jobs.toString(),
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                                    ),
                                    Text(
                                      '$completionVal% Completion',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              // 7. ACTIONS (VIEW, EDIT, MORE)
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildActionIcon(LucideIcons.eye, () {
                                      _showTopRightToast('View Details of $name');
                                    }),
                                    const SizedBox(width: 6),
                                    _buildActionIcon(LucideIcons.edit2, () {
                                      _showTopRightToast('Edit Partner $name');
                                    }),
                                    const SizedBox(width: 6),
                                    _buildActionIcon(LucideIcons.moreHorizontal, () {
                                      _showTopRightToast('More actions for $name');
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                          'Showing ${startIndex + 1} to $endIndex of $totalItems partners',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                        const Spacer(),
                        // Pagination selectors
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
                        // Rows per page
                        Text('Rows per page: ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: DropdownButton<int>(
                            value: _rowsPerPage,
                            underline: const SizedBox(),
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF111827)),
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
      txt = 'Active';
    } else if (txt == 'PENDING' || txt == 'PENDING REVIEW') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFF59E0B);
      txt = 'Pending Review';
    } else if (txt == 'BLOCKED') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFEF4444);
      txt = 'Blocked';
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

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF6B7280)),
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
          color: isActive ? const Color(0xFF5B21B6) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          page.toString(),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF6B7280)),
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle() => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
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
