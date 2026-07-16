import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  const CustomBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, "Home", "/dashboard"),
              _buildNavItem(context, 1, Icons.calendar_today_rounded, "Bookings", "/my_bookings"),
              _buildNavItem(context, 2, Icons.grid_view_rounded, "Categories", "/categories"),
              _buildNavItem(context, 3, Icons.card_giftcard_rounded, "Rewards", "/rewards"),
              _buildNavItem(context, 4, Icons.person_outline_rounded, "Profile", "/profile"),
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
          Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.accentColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppTheme.primaryColor : AppTheme.accentColor)),
        ],
      ),
    );
  }
}
