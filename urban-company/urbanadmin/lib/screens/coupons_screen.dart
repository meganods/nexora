import 'package:urbanadmin/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class CouponsScreen extends StatefulWidget {
  final int initialIndex;
  const CouponsScreen({super.key, this.initialIndex = 0});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> with SingleTickerProviderStateMixin {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF6366F1);
  static const bgColor = Color(0xFFF8FAFC);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: accentColor,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: accentColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
            tabs: const [
              Tab(text: '🎟️  Coupons'),
              Tab(text: '🚀  Campaigns'),
              Tab(text: '📊  Analytics'),
              Tab(text: '🗄️  Archive'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCouponsTab(),
              _buildCampaignsTab(),
              _buildAnalyticsTab(),
              _buildArchiveTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 1 – COUPONS (existing logic wrapped)
  // ═══════════════════════════════════════════════════
  Widget _buildCouponsTab() {
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
                      child: SizedBox(
                        width: 1400,
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

  // ═══════════════════════════════════════════════════
  // TAB 2 – CAMPAIGN MANAGEMENT (Admin Approval Portal)
  // ═══════════════════════════════════════════════════
  Widget _buildCampaignsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: accentColor,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: accentColor,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: '🏪 Vendor Requests'),
                Tab(text: '📢 Admin Campaigns'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVendorCampaignRequests(),
                _buildAdminOwnCampaigns(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCampaignRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('vendor_campaigns').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyState('No vendor campaign requests yet.', Icons.campaign_outlined);

        final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
        final approved = docs.where((d) => (d.data() as Map)['status'] == 'approved').length;
        final rejected = docs.where((d) => (d.data() as Map)['status'] == 'rejected').length;
        final pendingPay = docs.where((d) => (d.data() as Map)['status'] == 'pending_payment').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary chips
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _campaignChip('Pending Review', pending, const Color(0xFF6366F1)),
                  _campaignChip('Pending Payment', pendingPay, const Color(0xFFF59E0B)),
                  _campaignChip('Approved', approved, const Color(0xFF10B981)),
                  _campaignChip('Rejected', rejected, const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 20),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return _vendorCampaignRequestCard(d, doc.id);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _campaignChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _vendorCampaignRequestCard(Map<String, dynamic> d, String docId) {
    final status = d['status'] ?? 'pending';
    final Color statusColor;
    final String statusLabel;

    switch (status) {
      case 'approved': statusColor = const Color(0xFF10B981); statusLabel = '✅ Approved & Live'; break;
      case 'rejected': statusColor = const Color(0xFFEF4444); statusLabel = '❌ Rejected'; break;
      case 'pending_payment': statusColor = const Color(0xFFF59E0B); statusLabel = '💳 Awaiting Payment'; break;
      default: statusColor = const Color(0xFF6366F1); statusLabel = '🕐 Pending Review';
    }

    final placements = List<String>.from(d['placements'] ?? []);
    final adminFee = ((d['adminFee'] ?? 0) as num).toDouble();
    final feePaid = d['feePaid'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['vendorName'] ?? 'Vendor', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor)),
                      Text(d['businessName'] ?? d['vendorEmail'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel, style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _campaignColor(d['type'] ?? '').withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(d['type'] ?? '', style: GoogleFonts.inter(color: _campaignColor(d['type'] ?? ''), fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(d['name'] ?? 'Campaign', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(d['description'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(height: 12),
                if (d['imageUrl'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      d['imageUrl'],
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Placements
                if (placements.isNotEmpty) ...[
                  Text('Requested Display Locations:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: placements.map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                      child: Text(p.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Dates + estimated fee
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('${_fmtDate(d['startDate'])} → ${_fmtDate(d['endDate'])}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    const Spacer(),
                    Text('Est. fee: ₹${((d['estimatedFee'] ?? 0) as num).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),

                if (adminFee > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 13, color: Color(0xFF10B981)),
                      Text('Admin Fee Set: ₹${adminFee.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                      const SizedBox(width: 10),
                      if (feePaid)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                          child: Text('PAID', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],

                if (d['rejectionReason'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                    child: Text('Reason: ${d['rejectionReason']}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444))),
                  ),
                ],

                // Action buttons (only for pending)
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveWithFeeDialog(docId, d),
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                          label: Text('Approve & Set Fee', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectCampaignDialog(docId),
                          icon: const Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
                          label: Text('Reject', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'approved' || status == 'pending_payment') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectCampaignDialog(docId),
                      icon: const Icon(Icons.block_outlined, size: 16, color: Color(0xFFEF4444)),
                      label: Text('Revoke Approval', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveWithFeeDialog(String docId, Map<String, dynamic> d) {
    final feeCtrl = TextEditingController(text: '${((d['estimatedFee'] ?? 0) as num).toStringAsFixed(0)}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve Campaign & Set Fee', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Campaign: ${d['name']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              Text('Vendor: ${d['vendorName'] ?? d['vendorEmail']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 16),
              Text('Set Promotion Fee (₹)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount in ₹',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'After approval, the vendor will be notified to pay this fee. Once paid, their campaign will go live on the User App.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final fee = double.tryParse(feeCtrl.text) ?? 0.0;
              await _firestore.collection('vendor_campaigns').doc(docId).update({
                'status': fee > 0 ? 'pending_payment' : 'approved',
                'adminFee': fee,
                'approvedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) AppSnackbar.show(context, fee > 0 ? 'Approved! Vendor notified to pay ₹${fee.toStringAsFixed(0)}' : 'Campaign approved & live!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('CONFIRM APPROVAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRejectCampaignDialog(String docId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject / Revoke Campaign', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for rejection (shown to vendor)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('vendor_campaigns').doc(docId).update({
                'status': 'rejected',
                'rejectionReason': reasonCtrl.text.trim().isEmpty ? 'Does not meet campaign guidelines' : reasonCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) AppSnackbar.show(context, 'Campaign rejected.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('REJECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Admin's own promotional campaigns (separate from vendor requests)
  Widget _buildAdminOwnCampaigns() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('campaigns').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Admin Campaigns', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateCampaignDialog(null),
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: Text('New', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Platform-wide campaigns displayed in the User App.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (docs.isEmpty)
                _emptyState('No admin campaigns yet.', Icons.campaign_outlined)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 230,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    final Color tagColor = _campaignColor(d['type'] ?? '');
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(d['type'] ?? 'Campaign', style: GoogleFonts.inter(color: tagColor, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: d['active'] == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(d['active'] == true ? 'Active' : 'Inactive',
                                    style: GoogleFonts.inter(
                                        color: d['active'] == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                        fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(d['name'] ?? 'Campaign', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor)),
                          const SizedBox(height: 4),
                          Text(d['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text('${_fmtDate(d['startDate'])} → ${_fmtDate(d['endDate'])}',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6366F1)),
                                onPressed: () => _showCreateCampaignDialog({...d, 'id': docId}),
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                onPressed: () => _deleteCampaign(docId),
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Color _campaignColor(String type) {
    switch (type) {
      case 'Festival': return const Color(0xFFF59E0B);
      case 'Flash Sale': return const Color(0xFFEF4444);
      case 'Referral': return const Color(0xFF10B981);
      case 'Seasonal': return const Color(0xFF06B6D4);
      default: return accentColor;
    }
  }


  String _fmtDate(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) return DateFormat('dd MMM yy').format(ts.toDate());
    return '—';
  }

  void _showCreateCampaignDialog(Map<String, dynamic>? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: isEdit ? existing['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? existing['description'] : '');
    String type = isEdit ? (existing['type'] ?? 'Festival') : 'Festival';
    bool active = isEdit ? (existing['active'] ?? true) : true;
    DateTime start = isEdit && existing['startDate'] != null ? (existing['startDate'] as Timestamp).toDate() : DateTime.now();
    DateTime end = isEdit && existing['endDate'] != null ? (existing['endDate'] as Timestamp).toDate() : DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: Text(isEdit ? 'Edit Campaign' : 'New Campaign', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Campaign Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Campaign Type', border: OutlineInputBorder()),
                    items: ['Festival', 'Flash Sale', 'Referral', 'Seasonal', 'Limited Time'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setSt(() => type = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          dense: true,
                          title: const Text('Start Date', style: TextStyle(fontSize: 12)),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(start)),
                          trailing: const Icon(Icons.calendar_today, size: 16),
                          onTap: () async {
                            final p = await showDatePicker(context: ctx2, initialDate: start, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setSt(() => start = p);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          dense: true,
                          title: const Text('End Date', style: TextStyle(fontSize: 12)),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(end)),
                          trailing: const Icon(Icons.calendar_today, size: 16),
                          onTap: () async {
                            final p = await showDatePicker(context: ctx2, initialDate: end, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (p != null) setSt(() => end = p);
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Active', style: TextStyle(fontSize: 13)),
                    value: active,
                    onChanged: (val) => setSt(() => active = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'type': type,
                  'active': active,
                  'startDate': Timestamp.fromDate(start),
                  'endDate': Timestamp.fromDate(end),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (isEdit) {
                  await _firestore.collection('campaigns').doc(existing['id']).update(data);
                } else {
                  await _firestore.collection('campaigns').add({...data, 'createdAt': FieldValue.serverTimestamp()});
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: Text(isEdit ? 'SAVE' : 'CREATE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCampaign(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Campaign?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('DELETE', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('campaigns').doc(docId).delete();
      if (mounted) AppSnackbar.show(context, 'Campaign deleted');
    }
  }

  // ═══════════════════════════════════════════════════
  // TAB 3 – ANALYTICS
  // ═══════════════════════════════════════════════════
  Widget _buildAnalyticsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('coupons').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final coupons = docs.map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id}).toList();

        // Compute stats
        int totalRedemptions = 0;
        double totalDiscount = 0;
        final Map<String, int> couponUsage = {};
        final Map<String, double> couponRevenue = {};

        for (final c in coupons) {
          final used = (c['usedCount'] ?? 0) as int;
          final val = ((c['discountValue'] ?? 0.0) as num).toDouble();
          final code = c['code'] ?? 'Unknown';
          totalRedemptions += used;
          totalDiscount += used * val;
          couponUsage[code] = used;
          couponRevenue[code] = used * val;
        }

        final sortedCoupons = coupons.toList()
          ..sort((a, b) => ((b['usedCount'] ?? 0) as int).compareTo((a['usedCount'] ?? 0) as int));
        final top5 = sortedCoupons.take(5).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coupon Analytics', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
              const SizedBox(height: 4),
              Text('Real-time performance overview from your Firestore coupon data.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 24),

              // Summary KPI Cards
              Row(
                children: [
                  _analyticsKpi('Total Redemptions', '$totalRedemptions', Icons.confirmation_num_outlined, const Color(0xFF6366F1)),
                  const SizedBox(width: 16),
                  _analyticsKpi('Total Discount Given', '₹${totalDiscount.toStringAsFixed(0)}', Icons.savings_outlined, const Color(0xFF10B981)),
                  const SizedBox(width: 16),
                  _analyticsKpi('Total Coupons', '${coupons.length}', Icons.local_offer_outlined, const Color(0xFFF59E0B)),
                  const SizedBox(width: 16),
                  _analyticsKpi('Active Campaigns', '', Icons.campaign_outlined, const Color(0xFF06B6D4), fromStream: true),
                ],
              ),
              const SizedBox(height: 28),

              // Charts row
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 750;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildBarChart(top5)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildPieChart(couponUsage)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildBarChart(top5),
                            const SizedBox(height: 20),
                            _buildPieChart(couponUsage),
                          ],
                        );
                },
              ),
              const SizedBox(height: 28),

              // Top coupons table
              _buildTopCouponsTable(sortedCoupons),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticsKpi(String label, String value, IconData icon, Color color, {bool fromStream = false}) {
    Widget valueWidget = Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 22, color: primaryColor));
    if (fromStream) {
      valueWidget = StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('campaigns').where('active', isEqualTo: true).snapshots(),
        builder: (ctx, snap) => Text('${snap.data?.docs.length ?? 0}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 22, color: primaryColor)),
      );
    }
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  valueWidget,
                  const SizedBox(height: 4),
                  Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> top5) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Coupon Usage', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
          const SizedBox(height: 4),
          Text('Most redeemed coupons', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: top5.isEmpty
                ? _emptyState('No coupon data yet', Icons.bar_chart_outlined)
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: top5.map((c) => (c['usedCount'] ?? 0) as int).fold(0, (a, b) => a > b ? a : b).toDouble() + 5,
                      barGroups: top5.asMap().entries.map((e) {
                        final used = ((e.value['usedCount'] ?? 0) as int).toDouble();
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [BarChartRodData(toY: used, color: accentColor, width: 28, borderRadius: BorderRadius.circular(6))],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              if (val.toInt() < top5.length) {
                                final code = top5[val.toInt()]['code'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(code, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold)),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                            getTitlesWidget: (val, _) => Text('${val.toInt()}', style: GoogleFonts.inter(fontSize: 10)))),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> couponUsage) {
    final entries = couponUsage.entries.take(5).toList();
    final colors = [accentColor, const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF06B6D4)];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discount Type Distribution', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
          const SizedBox(height: 4),
          Text('Coupon share by redemption count', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: entries.isEmpty
                ? _emptyState('No data yet', Icons.pie_chart_outline)
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: entries.asMap().entries.map((e) {
                              final total = couponUsage.values.fold(0, (a, b) => a + b);
                              final pct = total == 0 ? 0.0 : e.value.value / total * 100;
                              return PieChartSectionData(
                                color: colors[e.key % colors.length],
                                value: e.value.value.toDouble(),
                                title: '${pct.toStringAsFixed(0)}%',
                                radius: 70,
                                titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entries.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 6),
                              Text(e.value.key, style: GoogleFonts.inter(fontSize: 11, color: primaryColor)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCouponsTable(List<Map<String, dynamic>> coupons) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All Coupons Performance', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: [
                DataColumn(label: Text('Code', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Title', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Type', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Value', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Redemptions', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Discount Given', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
              ],
              rows: coupons.map((c) {
                final used = (c['usedCount'] ?? 0) as int;
                final val = ((c['discountValue'] ?? 0.0) as num).toDouble();
                final discount = used * val;
                final isActive = c['status'] == true;
                return DataRow(cells: [
                  DataCell(Text(c['code'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: accentColor))),
                  DataCell(Text(c['title'] ?? '', style: GoogleFonts.inter())),
                  DataCell(Text(c['discountType'] ?? '', style: GoogleFonts.inter())),
                  DataCell(Text(c['discountType'] == 'Flat' ? '₹${val.toStringAsFixed(0)}' : '${val.toStringAsFixed(0)}%', style: GoogleFonts.inter())),
                  DataCell(Text('$used', style: GoogleFonts.inter(color: accentColor, fontWeight: FontWeight.bold))),
                  DataCell(Text('₹${discount.toStringAsFixed(0)}', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B))),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 4 – ARCHIVE
  // ═══════════════════════════════════════════════════
  Widget _buildArchiveTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('coupons')
          .where('status', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final now = DateTime.now();
        // Separate expired vs manually deactivated
        final expired = <QueryDocumentSnapshot>[];
        final inactive = <QueryDocumentSnapshot>[];
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final endDate = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
          if (endDate != null && endDate.isBefore(now)) {
            expired.add(doc);
          } else {
            inactive.add(doc);
          }
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coupon Archive', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
              const SizedBox(height: 4),
              Text('Expired and disabled coupons. Restore any coupon to make it active again.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 24),

              // Summary chips
              Row(
                children: [
                  _archiveChip('Expired', expired.length, const Color(0xFFEF4444)),
                  const SizedBox(width: 12),
                  _archiveChip('Deactivated', inactive.length, const Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  _archiveChip('Total Archived', docs.length, accentColor),
                ],
              ),
              const SizedBox(height: 24),

              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (docs.isEmpty)
                _emptyState('No archived coupons.', Icons.archive_outlined)
              else
                _buildArchiveSection('Expired Coupons', expired, const Color(0xFFEF4444))
              ,
              if (inactive.isNotEmpty) ...[  
                const SizedBox(height: 20),
                _buildArchiveSection('Deactivated Coupons', inactive, const Color(0xFF64748B)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _archiveChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildArchiveSection(String title, List<QueryDocumentSnapshot> docs, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 12),
        ...docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final endDate = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
          final val = ((d['discountValue'] ?? 0.0) as num).toDouble();
          final discountText = d['discountType'] == 'Flat' ? '₹${val.toStringAsFixed(0)} OFF' : '${val.toStringAsFixed(0)}% OFF';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.local_offer_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['code'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15)),
                      Text('${d['title'] ?? ''} · $discountText', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      if (endDate != null)
                        Text('Expired: ${DateFormat('dd MMM yyyy').format(endDate)}',
                            style: GoogleFonts.inter(fontSize: 11, color: color)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('Used: ${d['usedCount'] ?? 0}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _firestore.collection('coupons').doc(doc.id).update({
                      'status': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (mounted) AppSnackbar.show(context, 'Coupon ${d['code']} restored!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Restore', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined, color: Color(0xFFEF4444), size: 20),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Permanently Delete?'),
                        content: Text('Delete coupon ${d['code']}? This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('DELETE', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await _firestore.collection('coupons').doc(doc.id).delete();
                      if (mounted) AppSnackbar.show(context, 'Coupon deleted permanently');
                    }
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Shared empty state widget
  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(message, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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
                  builder: (context, child) {
                    return Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
                        child: child,
                      ),
                    );
                  },
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
        AppSnackbar.show(context, "Coupon status ${!currentStatus ? 'activated' : 'deactivated'} successfully");
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, "Error: $e", isError: true);
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
                  AppSnackbar.show(context, "Coupon deleted successfully");
                }
              } catch (e) {
                if (mounted) {
                  AppSnackbar.show(context, "Error: $e", isError: true);
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
                      AppSnackbar.show(context, "Code and Title are required", isError: true);
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
