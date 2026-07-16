import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  bool _isOnline = true;

  final List<Map<String, dynamic>> _newRequests = [
    {
      'id': 'REQ-1002',
      'service': 'AC Repair',
      'customer': 'Anil Kumar',
      'address': 'B-102, Galaxy Apts, Sec 62',
      'time': 'Today, 02:00 PM',
      'price': 'â‚¹599',
    },
    {
      'id': 'REQ-1003',
      'service': 'Deep Home Cleaning',
      'customer': 'Sneha Sharma',
      'address': 'Villa 4, Palm Groves',
      'time': 'Tomorrow, 09:00 AM',
      'price': 'â‚¹1,299',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSummaryGrid(),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildNewRequests(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: const CachedNetworkImageProvider('https://randomuser.me/api/portraits/men/32.jpg'),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hello, Rahul! ðŸ‘‹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: _isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(_isOnline ? 'Online - Accepting Jobs' : 'Offline', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _isOnline,
            activeThumbColor: accentColor,
            onChanged: (val) {
              setState(() => _isOnline = val);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'You are now online' : 'You are now offline')));
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildSummaryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard('Today\'s Earnings', 'â‚¹2,450', Icons.account_balance_wallet, Colors.blue),
          _buildStatCard('Upcoming Bookings', '4', Icons.calendar_today, Colors.orange),
          _buildStatCard('Profile Rating', '4.9', Icons.star, Colors.amber),
          _buildStatCard('Jobs Completed', '128', Icons.check_circle, Colors.green),
        ],
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.account_balance, color: Colors.white),
              label: const Text('Withdraw Funds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/inventory'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.inventory_2, color: primaryColor),
              label: const Text('Inventory', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildNewRequests() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Service Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 16),
          if (_newRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: const Text('No new requests right now', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _newRequests.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final req = _newRequests[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.home_repair_service, color: accentColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(req['service'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                                      Text(req['price'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(req['customer'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(req['address'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(req['time'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() => _newRequests.removeAt(index));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Rejected')));
                              },
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.redAccent),
                              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Container(width: 1, height: 24, color: Colors.grey.shade300),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() => _newRequests.removeAt(index));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Accepted!'), backgroundColor: accentColor));
                              },
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: accentColor),
                              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}
