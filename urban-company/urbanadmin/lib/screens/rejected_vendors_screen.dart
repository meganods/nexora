import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RejectedVendorsScreen extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onVendorSelected;

  const RejectedVendorsScreen({super.key, this.onVendorSelected});

  @override
  State<RejectedVendorsScreen> createState() => _RejectedVendorsScreenState();
}

class _RejectedVendorsScreenState extends State<RejectedVendorsScreen> {
  // Filters State
  String _selectedCategory = 'All Categories';
  String _selectedCity = 'All Cities';
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
              'Rejected Partners',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review partner applications that were rejected or suspended.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Simple KPI Card showing total rejected
  Widget _buildKpiGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
      builder: (context, snapshot) {
        int rejectedCount = 0;
        if (snapshot.hasData) {
          rejectedCount = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toUpperCase();
            return status == 'REJECTED';
          }).length;
        }

        return Container(
          width: 320,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.xCircle, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REJECTED PARTNERS',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280), fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rejectedCount.toString(),
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deactivated profile history',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          _buildDropdown('Category', _selectedCategory, ['All Categories', 'AC Repair', 'Cleaning', 'Plumbing', 'Electrical'], (v) {
            setState(() => _selectedCategory = v!);
          }),
          const SizedBox(width: 12),
          _buildDropdown('City', _selectedCity, ['All Cities', 'Mumbai', 'Delhi', 'Bangalore', 'Pune', 'Chennai'], (v) {
            setState(() => _selectedCity = v!);
          }),
          const SizedBox(width: 12),
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
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All Categories';
                  _selectedCity = 'All Cities';
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: Text(
                'Clear Filters',
                style: GoogleFonts.inter(
                  color: const Color(0xFFEF4444),
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

  Widget _buildVendorTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
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
                Expanded(flex: 2, child: Text('REJECTED DATE', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('STATUS', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('COMPLETED JOBS', style: _tableHeaderStyle())),
                Expanded(flex: 2, child: Text('ACTIONS', style: _tableHeaderStyle(), textAlign: TextAlign.right)),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFEF4444))),
                );
              }
              final rawDocs = snapshot.data?.docs ?? [];

              var docs = rawDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] ?? '').toString().toUpperCase();
                return status == 'REJECTED';
              }).toList();

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
                      'No rejected partners found.',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

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
                      
                      String formattedDate = 'N/A';
                      if (data['updatedAt'] != null || data['createdAt'] != null) {
                        try {
                          final ts = data['updatedAt'] ?? data['createdAt'];
                          final dt = (ts is Timestamp) ? ts.toDate() : DateTime.parse(ts.toString());
                          formattedDate = DateFormat('dd MMM yyyy').format(dt);
                        } catch (_) {}
                      }

                      final int jobs = (data['completedJobs'] ?? data['jobsCompleted'] ?? 0) as int;

                      return InkWell(
                        onTap: () => widget.onVendorSelected?.call(data),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Color(0xFFFEE2E2),
                                      child: Icon(LucideIcons.user, size: 16, color: Color(0xFFEF4444)),
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
                                            phone,
                                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(category, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827))),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(formattedDate, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827))),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                                  child: Text('REJECTED', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(jobs.toString(), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827))),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.eye, color: Color(0xFFEF4444), size: 18),
                                      onPressed: () => widget.onVendorSelected?.call(data),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF475569),
      letterSpacing: 0.5,
    );
  }
}
