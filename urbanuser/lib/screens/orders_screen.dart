import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrdersScreen extends StatefulWidget {
  static const routeName = '/orders';

  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  final List<Map<String, dynamic>> _upcomingOrders = [
    {
      'id': 'UC-829402',
      'title': 'Deep Home Cleaning',
      'pro_name': 'Assigning Professional...',
      'date': '15 Oct, 2026',
      'time': '09:00 AM',
      'status': 'Confirmed',
      'img': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500',
    }
  ];

  final List<Map<String, dynamic>> _completedOrders = [
    {
      'id': 'UC-119302',
      'title': 'AC Servicing',
      'pro_name': 'Rahul Sharma',
      'date': '02 Sep, 2026',
      'time': '11:00 AM',
      'status': 'Completed',
      'img': 'https://images.unsplash.com/photo-1617066914620-80491d91cdde?w=500',
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Bookings', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(_upcomingOrders, true),
          _buildOrderList(_completedOrders, false),
          _buildEmptyState('No cancelled bookings', Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, bool isUpcoming) {
    if (orders.isEmpty) {
      return _buildEmptyState('No bookings found', Icons.calendar_today_outlined);
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isUpcoming);
      },
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isUpcoming) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: order['img'],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(color: Colors.grey.shade200),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUpcoming ? Colors.orange.shade50 : accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order['status'],
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isUpcoming ? Colors.orange.shade800 : accentColor),
                            ),
                          ),
                          Text(order['id'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(order['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                      const SizedBox(height: 4),
                      Text(order['pro_name'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                if (!isUpcoming)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/checkout'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Rebook', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/order_details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn();
  }
}
