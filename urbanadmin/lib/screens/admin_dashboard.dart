import 'package:urbanadmin/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class AdminDashboard extends StatefulWidget {
  static const routeName = '/dashboard';

  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF1F5F9);

  int _selectedNavIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'route': '/dashboard'},
    {'title': 'Users', 'icon': Icons.people, 'route': '/users'},
    {'title': 'Vendors', 'icon': Icons.store, 'route': '/vendors'},
    {'title': 'Categories', 'icon': Icons.category, 'route': '/categories'},
    {'title': 'Bookings', 'icon': Icons.calendar_today, 'route': '/bookings'},
    {'title': 'Coupons', 'icon': Icons.local_offer, 'route': '/coupons'},
    {'title': 'Settings', 'icon': Icons.settings, 'route': '/settings'},
  ];

  final List<Map<String, dynamic>> _recentTransactions = [
    {'id': 'TXN-001', 'user': 'Anjali Singh', 'vendor': 'Rahul Sharma', 'amount': 'â‚¹1,448', 'status': 'Completed', 'date': '15 Oct'},
    {'id': 'TXN-002', 'user': 'Mohit Jain', 'vendor': 'Amit Plumbers', 'amount': 'â‚¹899', 'status': 'Pending', 'date': '15 Oct'},
    {'id': 'TXN-003', 'user': 'Sneha Rao', 'vendor': 'Urban Cleaners', 'amount': 'â‚¹2,499', 'status': 'Completed', 'date': '14 Oct'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Persistent Sidebar
          _buildSidebar(),
          // Main Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildKPICards(),
                      const SizedBox(height: 32),
                      _buildChartSection(),
                      const SizedBox(height: 32),
                      _buildTransactionsTable(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: primaryColor,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('NEXORA Admin', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedNavIndex == index;
                return ListTile(
                  leading: Icon(item['icon'], color: isSelected ? accentColor : Colors.white70),
                  title: Text(item['title'], style: TextStyle(color: isSelected ? accentColor : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedTileColor: accentColor.withValues(alpha: 0.1),
                  onTap: () {
                    setState(() => _selectedNavIndex = index);
                    if (item['route'] != '/dashboard') {
                      Navigator.pushNamed(context, item['route']);
                    }
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: -0.1);
              },
            ),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool _isUploadingImage = false;
  String? _adminAvatarUrl;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final url = await CloudinaryService.uploadImageBytes(bytes: bytes, fileName: pickedFile.name);
        if (url != null) {
          setState(() => _adminAvatarUrl = url);
          if (mounted) AppSnackbar.show(context, 'Admin avatar updated!');
        }
      } catch (e) {
        if (mounted) AppSnackbar.show(context, 'Upload failed: $e');
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      pinned: true,
      title: const Text('Dashboard Overview', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none, color: primaryColor), onPressed: () {}),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                backgroundColor: accentColor,
                backgroundImage: _adminAvatarUrl != null ? NetworkImage(_adminAvatarUrl!) : null,
                child: _adminAvatarUrl == null ? const Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
              ),
              if (_isUploadingImage)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ],
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildKPICards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard('Total Users', '12,450', Icons.people_outline, Colors.blue),
            _buildStatCard('Active Vendors', '842', Icons.store_mall_directory_outlined, Colors.green),
            _buildStatCard('Today\'s Revenue', 'â‚¹84,500', Icons.account_balance_wallet_outlined, accentColor),
            _buildStatCard('Pending Tickets', '24', Icons.support_agent, Colors.orange),
          ],
        ).animate().fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20000, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[value.toInt()], style: TextStyle(color: Colors.grey.shade600)));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 20000), FlSpot(1, 40000), FlSpot(2, 35000), FlSpot(3, 60000), FlSpot(4, 55000), FlSpot(5, 80000), FlSpot(6, 84500)],
                    isCurved: true,
                    color: accentColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: accentColor.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildTransactionsTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: accentColor))),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              columns: const [
                DataColumn(label: Text('Txn ID')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Vendor')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
              ],
              rows: _recentTransactions.map((txn) {
                return DataRow(
                  cells: [
                    DataCell(Text(txn['id'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(txn['user'])),
                    DataCell(Text(txn['vendor'])),
                    DataCell(Text(txn['amount'])),
                    DataCell(Text(txn['date'])),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: txn['status'] == 'Completed' ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(txn['status'], style: TextStyle(color: txn['status'] == 'Completed' ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}
