import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shop_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bookings_page.dart';
import 'screens/wallet_page.dart';
import 'screens/customers_page.dart';
import 'screens/store_settings_page.dart';
import 'screens/coupons_page.dart';
import 'screens/booking_detail_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UrbanVendorApp());
}

class UrbanVendorApp extends StatelessWidget {
  const UrbanVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Company Vendor',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/shop_setup': (context) => const ShopSetupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/bookings': (context) => const BookingsPage(),
        '/wallet': (context) => const WalletPage(),
        '/customers': (context) => const CustomersPage(),
        '/store_settings': (context) => const StoreSettingsPage(),
        '/coupons': (context) => const CouponsPage(),
        '/booking_detail': (context) => const BookingDetailPage(),
      },
    );
  }
}
