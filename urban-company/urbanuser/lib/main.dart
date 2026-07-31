import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/wallet_screen.dart';
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
import 'screens/notification_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/search_screen.dart';
import 'screens/category_details_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/payment_success_screen.dart';
import 'screens/payment_failed_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/offers_screen.dart';
import 'screens/refer_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
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
  } catch (e) {
    debugPrint("Firebase init note: $e");
  }

  runApp(const NexoraApp());
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXORA',
      theme: AppTheme.lightTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/address_setup': (context) => const AddressSetupScreen(),
        '/address_management': (context) => const AddressManagementScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/order_details': (context) => const OrderDetailsScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/my_bookings': (context) => const MyBookingsScreen(),
        '/wishlist': (context) => const WishlistScreen(),
        '/rewards': (context) => const WalletScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help_support': (context) => const HelpSupportScreen(),
        '/thank_you': (context) => const ThankYouScreen(),
        '/search': (context) => const SearchScreen(),
        '/offers': (context) => const OffersScreen(),
        '/refer': (context) => const ReferScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/category_details') {
          return MaterialPageRoute(
            builder: (context) => const CategoryDetailsScreen(),
          );
        }
        if (settings.name == '/product_details') {
          return MaterialPageRoute(
            builder: (context) => const ProductDetailsScreen(),
          );
        }
        if (settings.name == '/payment_success') {
          return MaterialPageRoute(
            builder: (context) => const PaymentSuccessScreen(),
          );
        }
        if (settings.name == '/payment_failed') {
          return MaterialPageRoute(
            builder: (context) => const PaymentFailedScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (context) => const NotFoundScreen(),
        );
      },
    );
  }
}
