import 'package:urbanadmin/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UsersScreen extends StatefulWidget {
  static const routeName = '/users';

  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF1F5F9);

  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Banned', 'Unverified'];

  final List<Map<String, dynamic>> _allUsers = [
    {'id': 'USR-101', 'name': 'Rahul Sharma', 'email': 'rahul@example.com', 'phone': '+91 9876543210', 'joined': '12 Oct 2026', 'status': 'Active'},
    {'id': 'USR-102', 'name': 'Sneha Rao', 'email': 'sneha@example.com', 'phone': '+91 9876543211', 'joined': '10 Oct 2026', 'status': 'Active'},
    {'id': 'USR-103', 'name': 'Amit Verma', 'email': 'amit@example.com', 'phone': '+91 9876543212', 'joined': '05 Oct 2026', 'status': 'Banned'},
    {'id': 'USR-104', 'name': 'Priya Singh', 'email': 'priya@example.com', 'phone': '+91 9876543213', 'joined': '14 Oct 2026', 'status': 'Unverified'},
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    return _allUsers.where((user) {
      final matchesSearch = user['name'].toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            user['email'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || user['status'] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _handleAction(String action, Map<String, dynamic> user) {
    if (action == 'Ban') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ban User?'),
          content: Text('Are you sure you want to ban ${user['name']}? They will not be able to log in.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() => user['status'] = 'Banned');
                Navigator.pop(ctx);
                AppSnackbar.show(context, '${user['name']} has been banned', isError: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Ban User', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      AppSnackbar.show(context, 'Action "$action" on ${user['name']} initiated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('User Management', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Controls
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by Name or Email...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Export CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedFilter = filter),
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : primaryColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        backgroundColor: bgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 32),

            // Data Table
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(bgColor),
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(label: Text('User ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Contact Details')),
                    DataColumn(label: Text('Joined Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _filteredUsers.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(Text(user['id'], style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(radius: 16, backgroundColor: accentColor.withValues(alpha: 0.2), child: Text(user['name'][0], style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 12),
                              Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(user['email'], style: const TextStyle(fontSize: 13)),
                              Text(user['phone'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        DataCell(Text(user['joined'])),
                        DataCell(_buildStatusChip(user['status'])),
                        DataCell(
                          PopupMenuButton<String>(
                            onSelected: (val) => _handleAction(val, user),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'View', child: Text('View Details')),
                              const PopupMenuItem(value: 'Message', child: Text('Send Message')),
                              if (user['status'] != 'Banned') const PopupMenuItem(value: 'Ban', child: Text('Ban User', style: TextStyle(color: Colors.redAccent))),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Active': color = Colors.green; break;
      case 'Banned': color = Colors.redAccent; break;
      case 'Unverified': color = Colors.orange; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
