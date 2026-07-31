import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int? currentIndex;
  final int? selectedIndex;
  final Function(int)? onTap;

  const CustomBottomNav({
    super.key,
    this.currentIndex,
    this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex ?? currentIndex ?? 0,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
