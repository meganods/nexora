import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/vendor_theme.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  String _selectedStatusFilter = 'All'; // All, Pending, Approved, Rejected, RequestChanges
  String _selectedDateFilter = 'All Time'; // All Time, Today, This Week
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _statusFilters = ['All', 'Pending', 'Approved', 'Rejected', 'RequestChanges'];
  final List<String> _dateFilters = ['All Time', 'Today', 'This Week'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _applyFilters(Map<String, dynamic> data, String docId) {
    final verification = data['verification'] as Map<String, dynamic>? ?? {};
    final status = verification['status'] ?? 'NotStarted';
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    final personalInfo = data['personalInfo'] as Map<String, dynamic>? ?? {};

    // Status Filter
    if (_selectedStatusFilter != 'All') {
      if (_selectedStatusFilter == 'Pending' && status != 'Submitted' && status != 'PendingApproval') {
        return false;
      }
      if (_selectedStatusFilter == 'Approved' && status != 'Approved') {
        return false;
      }
      if (_selectedStatusFilter == 'Rejected' && status != 'Rejected') {
        return false;
      }
      if (_selectedStatusFilter == 'RequestChanges' && status != 'RequestChanges') {
        return false;
      }
    }

    // Date Filter
    final submittedAtTs = verification['submittedAt'] as Timestamp?;
    if (submittedAtTs != null && _selectedDateFilter != 'All Time') {
      final date = submittedAtTs.toDate();
      final now = DateTime.now();
      if (_selectedDateFilter == 'Today') {
        final today = DateTime(now.year, now.month, now.day);
        if (date.isBefore(today)) return false;
      } else if (_selectedDateFilter == 'This Week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        if (date.isBefore(weekAgo)) return false;
      }
    }

    // Search Query (Vendor Name, Business Name, Phone)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final ownerName = (profile['ownerName'] ?? personalInfo['ownerName'] ?? data['ownerName'] ?? '').toString().toLowerCase();
      final businessName = (profile['businessName'] ?? personalInfo['businessName'] ?? data['businessName'] ?? '').toString().toLowerCase();
      final phone = (profile['phone'] ?? personalInfo['phone'] ?? data['phone'] ?? '').toString().toLowerCase();
      
      if (!ownerName.contains(query) && !businessName.contains(query) && !phone.contains(query)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Vendor KYC Dashboard",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Vendor Name, Business, or Mobile...",
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),

          // 2. Filter Chips Row
          Container(
            color: Colors.white,
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                ..._statusFilters.map((filter) {
                  final isSel = _selectedStatusFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStatusFilter = filter);
                        }
                      },
                    ),
                  );
                }),
                const VerticalDivider(width: 16, thickness: 1),
                ..._dateFilters.map((filter) {
                  final isSel = _selectedDateFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDateFilter = filter);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. Request Lists Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                
                // Filter locally
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) return false;
                  return _applyFilters(data, doc.id);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text("No KYC Requests Found", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final verification = data['verification'] as Map<String, dynamic>? ?? {};
                    final profile = data['profile'] as Map<String, dynamic>? ?? {};
                    final personalInfo = data['personalInfo'] as Map<String, dynamic>? ?? {};
                    
                    final status = verification['status'] ?? 'NotStarted';
                    final ownerName = profile['ownerName'] ?? personalInfo['ownerName'] ?? data['ownerName'] ?? 'Unnamed Vendor';
                    final businessName = profile['businessName'] ?? personalInfo['businessName'] ?? data['businessName'] ?? 'No Business Name';
                    final phone = profile['phone'] ?? personalInfo['phone'] ?? data['phone'] ?? 'No Mobile';
                    
                    final submittedAt = verification['submittedAt'] as Timestamp?;
                    final timeString = submittedAt != null
                        ? "${submittedAt.toDate().day}/${submittedAt.toDate().month} ${submittedAt.toDate().hour}:${submittedAt.toDate().minute}"
                        : "Not Submitted";

                    Color statusColor = const Color(0xFFF59E0B);
                    if (status == 'Approved') statusColor = const Color(0xFF16A34A);
                    else if (status == 'Rejected') statusColor = const Color(0xFFDC2626);
                    else if (status == 'RequestChanges') statusColor = const Color(0xFF3B82F6);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ownerName,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Business: $businessName", style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[700])),
                            Text("Phone: $phone", style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[700])),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Pending Since: $timeString", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/admin_detail',
                                        arguments: {'vendorId': doc.id},
                                      );
                                    },
                                    child: const Text("Open Details", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
