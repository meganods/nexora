import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  final List<Map<String, dynamic>> _todayNotifications = [
    {
      'id': 1,
      'title': 'Booking Confirmed!',
      'desc': 'Your deep home cleaning is scheduled for tomorrow at 09:00 AM.',
      'time': '10 mins ago',
      'icon': Icons.check_circle_outline,
      'color': Colors.green,
      'isRead': false,
    },
    {
      'id': 2,
      'title': '50% OFF on AC Repair â„ï¸',
      'desc': 'Use code COOL50 and get flat 50% off on your next AC servicing.',
      'time': '2 hours ago',
      'icon': Icons.local_offer_outlined,
      'color': Colors.orange,
      'isRead': false,
    },
  ];

  final List<Map<String, dynamic>> _earlierNotifications = [
    {
      'id': 3,
      'title': 'Payment Successful',
      'desc': 'Payment of â‚¹1,448 for Booking UC-829402 was successful.',
      'time': 'Yesterday',
      'icon': Icons.payment_outlined,
      'color': Colors.blue,
      'isRead': true,
    },
    {
      'id': 4,
      'title': 'How was your experience?',
      'desc': 'Rate your recent Plumbing service by Amit Kumar.',
      'time': 'Oct 12',
      'icon': Icons.star_border,
      'color': Colors.amber,
      'isRead': true,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _todayNotifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read'), backgroundColor: primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _todayNotifications.isEmpty && _earlierNotifications.isEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
        actions: [
          if (!isEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: accentColor),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_todayNotifications.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text('Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                    ..._todayNotifications.map((n) => _buildNotificationCard(n)),
                    const SizedBox(height: 16),
                  ],
                  if (_earlierNotifications.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text('Earlier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                    ..._earlierNotifications.map((n) => _buildNotificationCard(n)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'];

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          setState(() => notification['isRead'] = true);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.blue.shade50.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: isRead ? Border.all(color: Colors.grey.shade200) : Border.all(color: Colors.blue.shade200),
          boxShadow: [
            if (!isRead) BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (notification['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(notification['icon'], color: notification['color'], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(fontSize: 16, fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, color: primaryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(notification['time'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification['desc'],
                    style: TextStyle(fontSize: 14, color: isRead ? Colors.grey.shade600 : Colors.black87, height: 1.4),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(left: 12, top: 6),
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.2, duration: 800.ms),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.05),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('We will notify you when something arrives.', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    ).animate().fadeIn();
  }
}
