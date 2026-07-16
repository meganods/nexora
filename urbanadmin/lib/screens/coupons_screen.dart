import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF6366F1); // Modern violet accent
  static const bgColor = Color(0xFFF8FAFC);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search & Filter state
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _typeFilter = 'All';
  String _serviceFilter = 'All';
  String _categoryFilter = 'All';
  DateTimeRange? _selectedDateRange;

  // Pagination state
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('coupons').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading coupons: ${snapshot.error}",
                    style: GoogleFonts.outfit(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 16),
                  Text(
                    "Connecting to database...",
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        final allCoupons = snapshot.data?.docs ?? [];

        // Process coupon counts and statistics
        final now = DateTime.now();
        int totalCount = allCoupons.length;
        int activeCount = 0;
        int upcomingCount = 0;
        int expiredCount = 0;
        double totalDiscountGiven = 0.0;

        List<Map<String, dynamic>> processedCoupons = [];

        for (var doc in allCoupons) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          // Parse dates
          DateTime? startDate;
          DateTime? endDate;
          if (data['startDate'] != null) {
            startDate = (data['startDate'] as Timestamp).toDate();
          }
          if (data['endDate'] != null) {
            endDate = (data['endDate'] as Timestamp).toDate();
          }

          final isActive = data['status'] == true;
          String calculatedStatus = 'Inactive';

          if (isActive) {
            if (startDate != null && startDate.isAfter(now)) {
              calculatedStatus = 'Upcoming';
              upcomingCount++;
            } else if (endDate != null && endDate.isBefore(now)) {
              calculatedStatus = 'Expired';
              expiredCount++;
            } else {
              calculatedStatus = 'Active';
              activeCount++;
            }
          } else {
            calculatedStatus = 'Inactive';
          }

          final usedCount = data['usedCount'] ?? 0;
          final discountValue = (data['discountValue'] ?? 0.0) as num;
          totalDiscountGiven += (usedCount * discountValue.toDouble());

          data['calculatedStatus'] = calculatedStatus;
          data['startDateObj'] = startDate;
          data['endDateObj'] = endDate;

          // Apply search & dropdown filters
          bool matchesSearch = _searchQuery.isEmpty ||
              (data['code'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (data['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());

          bool matchesStatus = _statusFilter == 'All' || calculatedStatus == _statusFilter;
          bool matchesType = _typeFilter == 'All' || (data['discountType'] ?? '') == _typeFilter;

          bool matchesDate = _selectedDateRange == null ||
              (startDate != null && endDate != null &&
                  startDate.isBefore(_selectedDateRange!.end) &&
                  endDate.isAfter(_selectedDateRange!.start));

          if (matchesSearch && matchesStatus && matchesType && matchesDate) {
            processedCoupons.add(data);
          }
        }

        // Apply pagination
        int totalFiltered = processedCoupons.length;
        int totalPages = (totalFiltered / _pageSize).ceil();
        if (totalPages == 0) totalPages = 1;
        if (_currentPage > totalPages) _currentPage = totalPages;
        int startIndex = (_currentPage - 1) * _pageSize;
        int endIndex = startIndex + _pageSize;
        if (endIndex > totalFiltered) endIndex = totalFiltered;
        List<Map<String, dynamic>> paginatedCoupons = processedCoupons.sublist(startIndex, endIndex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs & Create Button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dashboard > Coupons",
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateEditCouponModal(null),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: Text("Create Coupon", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI cards
            _buildKPICards(totalCount, activeCount, upcomingCount, expiredCount, totalDiscountGiven),
            const SizedBox(height: 32),

            // Search & Filter Panel
            _buildSearchFilterPanel(),
            const SizedBox(height: 24),

            // Table Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Coupon Code', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Title', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Discount', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Min. Order', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Usage Limit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Used', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Per User Limit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Validity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                        ],
                        rows: paginatedCoupons.map((coupon) {
                          return _buildCouponDataRow(coupon);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pagination bar
                    _buildPaginationBar(totalFiltered, startIndex, endIndex, totalPages),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICards(int total, int active, int upcoming, int expired, double discountGiven) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - 48) / 5;
        if (cardWidth < 200) cardWidth = 200; // Safe minimum fallback size

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _kpiCard("Total Coupons", "$total", Icons.local_offer, const Color(0xFFF3E5F5), Colors.purple, cardWidth),
              const SizedBox(width: 12),
              _kpiCard("Active Coupons", "$active", Icons.check_circle_outline, const Color(0xFFE8F5E9), Colors.green, cardWidth),
              const SizedBox(width: 12),
              _kpiCard("Upcoming Coupons", "$upcoming", Icons.watch_later_outlined, const Color(0xFFFFF8E1), Colors.amber, cardWidth),
              const SizedBox(width: 12),
              _kpiCard("Expired Coupons", "$expired", Icons.cancel_outlined, const Color(0xFFFFEBEE), Colors.red, cardWidth),
              const SizedBox(width: 12),
              _kpiCard("Total Discount Given", "₹${discountGiven.toStringAsFixed(0)}", Icons.card_giftcard, const Color(0xFFE3F2FD), Colors.blue, cardWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiCard(String title, String val, IconData icon, Color bg, Color iconColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: bg,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                Text(title, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Search box
            SizedBox(
              width: 200,
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by code or title...',
                  hintStyle: GoogleFonts.outfit(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  filled: true,
                  fillColor: bgColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Status Filter
            _dropdownFilter("All Status", _statusFilter, ['All', 'Active', 'Inactive', 'Expired', 'Upcoming'], (val) {
              setState(() => _statusFilter = val!);
            }),
            const SizedBox(width: 12),

            // Type Filter
            _dropdownFilter("All Types", _typeFilter, ['All', 'Flat', 'Percentage'], (val) {
              setState(() => _typeFilter = val!);
            }),
            const SizedBox(width: 12),

            // Services Filter
            _dropdownFilter("All Services", _serviceFilter, ['All', 'Cleaning', 'Plumbing', 'Barber', 'Salon'], (val) {
              setState(() => _serviceFilter = val!);
            }),
            const SizedBox(width: 12),

            // Categories Filter
            _dropdownFilter("All Categories", _categoryFilter, ['All', 'Home Services', 'Personal Care', 'Repair'], (val) {
              setState(() => _categoryFilter = val!);
            }),
            const SizedBox(width: 12),

            // Date picker filter
            GestureDetector(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDateRange = picked);
                }
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDateRange == null
                          ? "Start Date - End Date"
                          : "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}",
                      style: GoogleFonts.outfit(fontSize: 12, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Clear filters
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchQuery = '';
                  _statusFilter = 'All';
                  _typeFilter = 'All';
                  _serviceFilter = 'All';
                  _categoryFilter = 'All';
                  _selectedDateRange = null;
                });
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text("Clear", style: GoogleFonts.outfit(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownFilter(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((String opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt == 'All' ? label : opt, style: GoogleFonts.outfit(fontSize: 12)),
            );
          }).toList(),
        ),
      ),
    );
  }

  DataRow _buildCouponDataRow(Map<String, dynamic> coupon) {
    final String code = coupon['code'] ?? 'CODE';
    final String title = coupon['title'] ?? 'No Title';
    final String discountType = coupon['discountType'] ?? 'Flat';
    final double discountValue = (coupon['discountValue'] ?? 0.0) as double;
    final double minOrder = (coupon['minimumOrder'] ?? 0.0) as double;
    final int usageLimit = coupon['usageLimit'] ?? 0;
    final int usedCount = coupon['usedCount'] ?? 0;
    final int perUserLimit = coupon['perUserLimit'] ?? 1;
    final DateTime? startDate = coupon['startDateObj'];
    final DateTime? endDate = coupon['endDateObj'];
    final String calculatedStatus = coupon['calculatedStatus'] ?? 'Inactive';

    final String discountText = discountType == 'Flat'
        ? 'Flat ₹${discountValue.toStringAsFixed(0)}'
        : '${discountValue.toStringAsFixed(0)}% OFF';

    final String validityText = startDate != null && endDate != null
        ? "${DateFormat('dd MMM yyyy').format(startDate)}\n${DateFormat('dd MMM yyyy').format(endDate)}"
        : 'Open';

    Color statusBg = const Color(0xFFF1F5F9);
    Color statusTextColor = Colors.grey;

    if (calculatedStatus == 'Active') {
      statusBg = const Color(0xFFE8F5E9);
      statusTextColor = Colors.green;
    } else if (calculatedStatus == 'Upcoming') {
      statusBg = const Color(0xFFFFF8E1);
      statusTextColor = Colors.orange;
    } else if (calculatedStatus == 'Expired') {
      statusBg = const Color(0xFFFFEBEE);
      statusTextColor = Colors.red;
    }

    return DataRow(
      cells: [
        DataCell(Text(code, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: accentColor))),
        DataCell(Text(title, style: GoogleFonts.outfit())),
        DataCell(Text(discountText, style: GoogleFonts.outfit())),
        DataCell(Text('₹${minOrder.toStringAsFixed(0)}', style: GoogleFonts.outfit())),
        DataCell(Text('$usageLimit', style: GoogleFonts.outfit())),
        DataCell(Text('$usedCount', style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.w600))),
        DataCell(Text('$perUserLimit', style: GoogleFonts.outfit())),
        DataCell(Text(validityText, style: GoogleFonts.outfit(fontSize: 11))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
          child: Text(calculatedStatus, style: GoogleFonts.outfit(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.blue),
              onPressed: () => _showCouponDetailsDialog(coupon),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.orange),
              onPressed: () => _showCreateEditCouponModal(coupon),
            ),
            IconButton(
              icon: Icon(
                coupon['status'] == true ? Icons.pause_circle_outline : Icons.play_circle_outline,
                size: 18,
                color: coupon['status'] == true ? Colors.amber : Colors.green,
              ),
              onPressed: () => _toggleCouponStatus(coupon['id'], coupon['status'] ?? false),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _confirmDeleteCoupon(coupon['id'], code),
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildPaginationBar(int totalFiltered, int start, int end, int totalPages) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Showing ${totalFiltered == 0 ? 0 : start + 1} to $end of $totalFiltered entries",
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
          ),
        ),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
              ),
              ...List.generate(totalPages, (index) {
                final pageNum = index + 1;
                final isCurrent = pageNum == _currentPage;
                return GestureDetector(
                  onTap: () => setState(() => _currentPage = pageNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "$pageNum",
                      style: GoogleFonts.outfit(
                        color: isCurrent ? Colors.white : primaryColor,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ACTIONS ---

  void _toggleCouponStatus(String docId, bool currentStatus) async {
    try {
      await _firestore.collection('coupons').doc(docId).update({
        'status': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Coupon status ${!currentStatus ? 'activated' : 'deactivated'} successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _confirmDeleteCoupon(String docId, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Coupon?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete coupon $code? This action cannot be undone.", style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _firestore.collection('coupons').doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Coupon deleted successfully"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("DELETE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCouponDetailsDialog(Map<String, dynamic> coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Coupon Details - ${coupon['code']}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Title", coupon['title'] ?? ''),
              _detailRow("Description", coupon['description'] ?? ''),
              _detailRow("Discount Type", coupon['discountType'] ?? ''),
              _detailRow("Discount Value", "${coupon['discountValue']}"),
              _detailRow("Min Booking Amount", "₹${coupon['minimumOrder']}"),
              if (coupon['discountType'] == 'Percentage')
                _detailRow("Max Discount Limit", "₹${coupon['maxDiscount']}"),
              _detailRow("Usage Limit", "${coupon['usageLimit']}"),
              _detailRow("Used Count", "${coupon['usedCount']}"),
              _detailRow("Per User Limit", "${coupon['perUserLimit']}"),
              _detailRow("Applicable On", coupon['applicableType'] ?? 'All'),
              _detailRow("First Booking Only", coupon['firstBookingOnly'] == true ? 'Yes' : 'No'),
              _detailRow("Auto Apply", coupon['autoApply'] == true ? 'Yes' : 'No'),
              _detailRow("Cities", (coupon['cityIds'] as List?)?.join(', ') ?? 'All Cities'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CLOSE", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              "$label:",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey[750]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // --- CREATE / EDIT MODAL PANEL ---

  void _showCreateEditCouponModal(Map<String, dynamic>? editCoupon) {
    final isEdit = editCoupon != null;
    final codeController = TextEditingController(text: isEdit ? editCoupon['code'] : '');
    final titleController = TextEditingController(text: isEdit ? editCoupon['title'] : '');
    final descController = TextEditingController(text: isEdit ? editCoupon['description'] : '');
    final valueController = TextEditingController(text: isEdit ? "${editCoupon['discountValue']}" : '');
    final minOrderController = TextEditingController(text: isEdit ? "${editCoupon['minimumOrder']}" : '');
    final maxDiscountController = TextEditingController(text: isEdit ? "${editCoupon['maxDiscount'] ?? ''}" : '');
    final usageLimitController = TextEditingController(text: isEdit ? "${editCoupon['usageLimit']}" : '1000');
    final perUserLimitController = TextEditingController(text: isEdit ? "${editCoupon['perUserLimit']}" : '1');

    String discountType = isEdit ? editCoupon['discountType'] : 'Flat';
    String applicableType = isEdit ? editCoupon['applicableType'] : 'All';
    bool firstBookingOnly = isEdit ? editCoupon['firstBookingOnly'] == true : false;
    bool autoApply = isEdit ? editCoupon['autoApply'] == true : false;
    bool status = isEdit ? editCoupon['status'] == true : true;

    DateTime startDate = isEdit && editCoupon['startDateObj'] != null ? editCoupon['startDateObj'] : DateTime.now();
    DateTime endDate = isEdit && editCoupon['endDateObj'] != null ? editCoupon['endDateObj'] : DateTime.now().add(const Duration(days: 30));

    // For multi-select configs
    List<String> cities = isEdit && editCoupon['cityIds'] != null ? List<String>.from(editCoupon['cityIds']) : ['Noida', 'Gurgaon', 'Delhi'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Coupon" : "Create Coupon", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: "Coupon Code (e.g. WELCOME100)", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Coupon Title", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: discountType,
                        decoration: const InputDecoration(labelText: "Discount Type", border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: "Flat", child: Text("Flat Discount")),
                          DropdownMenuItem(value: "Percentage", child: Text("Percentage Discount")),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            discountType = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: valueController,
                        decoration: InputDecoration(
                          labelText: discountType == "Flat" ? "Flat Value (₹)" : "Percentage Value (%)",
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (discountType == "Percentage") ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: maxDiscountController,
                          decoration: const InputDecoration(labelText: "Maximum Discount Value (₹)", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: minOrderController,
                        decoration: const InputDecoration(labelText: "Minimum Booking Amount (₹)", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: usageLimitController,
                              decoration: const InputDecoration(labelText: "Total Usage Limit", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: perUserLimitController,
                              decoration: const InputDecoration(labelText: "Per User Limit", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Date pickers row
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text("Start Date", style: TextStyle(fontSize: 12)),
                              subtitle: Text(DateFormat('dd MMM yyyy').format(startDate)),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (picked != null) {
                                  setModalState(() => startDate = picked);
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text("End Date", style: TextStyle(fontSize: 12)),
                              subtitle: Text(DateFormat('dd MMM yyyy').format(endDate)),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (picked != null) {
                                  setModalState(() => endDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: applicableType,
                        decoration: const InputDecoration(labelText: "Applicable On", border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: "All", child: Text("All Services")),
                          DropdownMenuItem(value: "Categories", child: Text("Selected Categories")),
                          DropdownMenuItem(value: "Services", child: Text("Selected Services")),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            applicableType = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Multi select cities mock list
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Applicable Cities:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Wrap(
                            spacing: 8,
                            children: ['Noida', 'Gurgaon', 'Delhi', 'Mumbai', 'Bangalore'].map((city) {
                              final isSelected = cities.contains(city);
                              return FilterChip(
                                label: Text(city),
                                selected: isSelected,
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      cities.add(city);
                                    } else {
                                      cities.remove(city);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        title: const Text("First Booking Only", style: TextStyle(fontSize: 13)),
                        value: firstBookingOnly,
                        onChanged: (val) => setModalState(() => firstBookingOnly = val),
                      ),
                      SwitchListTile(
                        title: const Text("Auto Apply Coupon", style: TextStyle(fontSize: 13)),
                        value: autoApply,
                        onChanged: (val) => setModalState(() => autoApply = val),
                      ),
                      SwitchListTile(
                        title: const Text("Active Status", style: TextStyle(fontSize: 13)),
                        value: status,
                        onChanged: (val) => setModalState(() => status = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("CANCEL", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (codeController.text.trim().isEmpty || titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code and Title are required"), backgroundColor: Colors.redAccent));
                      return;
                    }

                    final data = {
                      'code': codeController.text.trim().toUpperCase(),
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'createdBy': 'admin',
                      'discountType': discountType,
                      'discountValue': double.tryParse(valueController.text) ?? 0.0,
                      'maxDiscount': double.tryParse(maxDiscountController.text) ?? 0.0,
                      'minimumOrder': double.tryParse(minOrderController.text) ?? 0.0,
                      'usageLimit': int.tryParse(usageLimitController.text) ?? 1000,
                      'perUserLimit': int.tryParse(perUserLimitController.text) ?? 1,
                      'firstBookingOnly': firstBookingOnly,
                      'autoApply': autoApply,
                      'applicableType': applicableType,
                      'cityIds': cities,
                      'startDate': Timestamp.fromDate(startDate),
                      'endDate': Timestamp.fromDate(endDate),
                      'status': status,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    try {
                      if (isEdit) {
                        await _firestore.collection('coupons').doc(editCoupon['id']).update(data);
                      } else {
                        await _firestore.collection('coupons').add({
                          ...data,
                          'usedCount': 0,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      if (context.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                  child: Text(isEdit ? "SAVE" : "CREATE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
