import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/address_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/app_theme.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/address_management_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/order_details_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/search_screen.dart';
import 'screens/category_details_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/payment_success_screen.dart';
import 'screens/payment_failed_screen.dart';
import 'screens/not_found_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.get('FIREBASE_API_KEY'),
      authDomain: dotenv.get('FIREBASE_AUTH_DOMAIN'),
      projectId: dotenv.get('FIREBASE_PROJECT_ID'),
      storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
      messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
      appId: dotenv.get('FIREBASE_APP_ID'),
      measurementId: dotenv.get('FIREBASE_MEASUREMENT_ID'),
    ),
  );
  runApp(const UrbanApp());
}

class UrbanApp extends StatelessWidget {
  const UrbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urban Company',
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      initialRoute: '/',
      routes: {
        '/not_found': (context) => const NotFoundScreen(),

        '/payment_failed': (context) => const PaymentFailedScreen(),

        '/payment_success': (context) => const PaymentSuccessScreen(),

        '/product_details': (context) => const ProductDetailsScreen(),

        '/category_details': (context) => const CategoryDetailsScreen(),

        '/search': (context) => const SearchScreen(),

        '/help_support': (context) => const HelpSupportScreen(),

        '/settings': (context) => const SettingsScreen(),

        '/wishlist': (context) => const WishlistScreen(),

        '/notifications': (context) => const NotificationsScreen(),

        '/order_details': (context) => const OrderDetailsScreen(),

        '/orders': (context) => const OrdersScreen(),

        '/checkout': (context) => const CheckoutScreen(),

        '/address_management': (context) => const AddressManagementScreen(),

        '/home': (context) => const HomeScreen(),

        '/forgot_password': (context) => const ForgotPasswordScreen(),

        '/register': (context) => const RegisterScreen(),

        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
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

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
