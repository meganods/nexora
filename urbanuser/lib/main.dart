import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/address_setup_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UrbanApp());
}

class UrbanApp extends StatelessWidget {
  const UrbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Company Clone',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/my_bookings': (context) => const MyBookingsScreen(),
        '/thank_you': (context) => const ThankYouScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/rewards': (context) => const RewardsScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/address_setup': (context) => const AddressSetupScreen(),
      },
    );
  }
}
