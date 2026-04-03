import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  const CustomBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[100]!)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.dashboard_outlined, "Home", "/dashboard"),
              _buildNavItem(context, 1, Icons.calendar_today_outlined, "Bookings", "/bookings"),
              _buildNavItem(context, 2, Icons.account_balance_wallet_outlined, "Wallet", "/wallet"),
              _buildNavItem(context, 3, Icons.people_outline, "Customers", "/customers"),
              _buildNavItem(context, 4, Icons.storefront_outlined, "Store", "/store_settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, String route) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (route.isNotEmpty && !isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey[400], size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppTheme.primaryColor : Colors.grey[400])),
        ],
      ),
    );
  }
}
