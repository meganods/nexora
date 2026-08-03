import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/app_snackbar.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _filterStatus = 'All'; // 'All', 'Active', 'Blocked'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(String docId, bool currentBlocked) async {
    try {
      await _firestore.collection('users').doc(docId).set({
        'blocked': !currentBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        AppSnackbar.show(
          context, 
          currentBlocked ? 'User successfully unblocked!' : 'User successfully blocked!'
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Error updating status: $e', isError: true);
      }
    }
  }

  void _showUserDetailsModal(Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: userData['photoUrl'] != null 
                  ? NetworkImage(userData['photoUrl']) 
                  : null,
              child: userData['photoUrl'] == null
                  ? Text(
                      (userData['fullName'] ?? userData['email'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userData['fullName'] ?? 'Customer Account',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'ID: $userId',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 24),
                _detailRow('Email Address', userData['email'] ?? 'Not specified'),
                _detailRow('Phone Number', userData['phone'] ?? 'Not specified'),
                _detailRow(
                  'Account Status', 
                  userData['blocked'] == true ? '🔴 Blocked' : '🟢 Active',
                  isBold: true
                ),
                _detailRow(
                  'Created At', 
                  userData['createdAt'] != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format((userData['createdAt'] as Timestamp).toDate())
                      : 'Unknown'
                ),
                const SizedBox(height: 16),
                Text(
                  'Location & Address',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['userAddress'] ?? userData['location']?['address'] ?? 'No address registered',
                        style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: const Color(0xFF334155)),
                      ),
                      if (userData['location'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'City: ${userData['location']?['city'] ?? "N/A"} · State: ${userData['location']?['state'] ?? "N/A"}',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleUserStatus(userId, userData['blocked'] == true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: userData['blocked'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            child: Text(
              userData['blocked'] == true ? 'UNBLOCK USER' : 'BLOCK USER',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data?.docs ?? [];
        
        // Count Stats
        final totalCount = allUsers.length;
        final blockedCount = allUsers.where((u) {
          final data = u.data() as Map<String, dynamic>;
          return data['blocked'] == true;
        }).length;
        final activeCount = totalCount - blockedCount;

        // Filter and Search logic
        final filteredUsers = allUsers.where((u) {
          final data = u.data() as Map<String, dynamic>;
          final name = (data['fullName'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final phone = (data['phone'] ?? '').toString().toLowerCase();
          final isBlocked = data['blocked'] == true;

          final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase()) ||
              phone.contains(_searchQuery.toLowerCase());

          final matchesStatus = _filterStatus == 'All' ||
              (_filterStatus == 'Active' && !isBlocked) ||
              (_filterStatus == 'Blocked' && isBlocked);

          return matchesSearch && matchesStatus;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Text(
              'Users',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            Text(
              'Manage client database, inspect registered addresses, and enforce security policies.',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),

            // KPI stats cards
            Row(
              children: [
                _kpiCard('Total Clients', '$totalCount', Icons.people_rounded, const Color(0xFF6366F1)),
                const SizedBox(width: 16),
                _kpiCard('Active Accounts', '$activeCount', Icons.check_circle_rounded, const Color(0xFF10B981)),
                const SizedBox(width: 16),
                _kpiCard('Blocked Clients', '$blockedCount', Icons.block_flipped, const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 24),

            // Control Bar (Search + Filter Dropdown)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search by client name, email, or contact number...',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        items: ['All', 'Active', 'Blocked'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              '$status Status',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _filterStatus = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Users Table Container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: filteredUsers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text('No registered users found matching the query.', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isMobile = screenWidth < 850;
                        final availableWidth = screenWidth - (isMobile ? 64 : 324);
                        
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: availableWidth > 0 ? availableWidth : 0,
                            ),
                            child: DataTable(
                              columnSpacing: 32,
                              columns: [
                                DataColumn(label: Text('Client Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Contact details', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Default Address', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Registration', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredUsers.map((u) {
                                final data = u.data() as Map<String, dynamic>;
                                final String docId = u.id;
                                final String name = data['fullName'] ?? 'No Name';
                                final String email = data['email'] ?? 'Not specified';
                                final String phone = data['phone'] ?? 'Not specified';
                                final String address = data['userAddress'] ?? data['location']?['address'] ?? 'No address registered';
                                final bool isBlocked = data['blocked'] == true;
                                
                                String joined = '—';
                                if (data['createdAt'] != null) {
                                  joined = DateFormat('dd MMM yyyy').format((data['createdAt'] as Timestamp).toDate());
                                }

                                return DataRow(cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFFEEF2FF),
                                          backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                                          child: data['photoUrl'] == null
                                              ? Text(
                                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF4F46E5)),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          name,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(email, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: const Color(0xFF1E293B))),
                                        Text(phone, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 220,
                                      child: Text(
                                        address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      joined,
                                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isBlocked ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isBlocked ? 'Blocked' : 'Active',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 18),
                                          tooltip: 'Inspect account details',
                                          onPressed: () => _showUserDetailsModal(data, docId),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isBlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, 
                                            color: isBlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            size: 18
                                          ),
                                          tooltip: isBlocked ? 'Unblock user' : 'Block user',
                                          onPressed: () => _toggleUserStatus(docId, isBlocked),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    val,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
