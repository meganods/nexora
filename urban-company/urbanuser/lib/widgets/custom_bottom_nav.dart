import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const textGray = Color(0xFF64748B);

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': 'Home', 'route': '/dashboard'},
      {'icon': Icons.grid_view_rounded, 'label': 'Categories', 'route': '/categories'},
      {'icon': Icons.calendar_today_rounded, 'label': 'Bookings', 'route': '/my_bookings'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Wallet', 'route': '/rewards'},
      {'icon': Icons.person_rounded, 'label': 'Profile', 'route': '/profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index != selectedIndex) {
            Navigator.pushReplacementNamed(context, items[index]['route']);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGray,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: items.map((item) {
          return BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Icon(item['icon']),
            ),
            label: item['label'],
          );
        }).toList(),
      ),
    );
  }
}
