import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/app_infra_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/thank_you_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/address_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/location_permission_screen.dart';
import 'screens/location_selection_screen.dart';
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
import 'screens/popular_services_screen.dart';

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
    return ChangeNotifierProvider(
      create: (_) => AppInfraService(),
      child: Consumer<AppInfraService>(
        builder: (context, infra, _) {
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
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/otp_verification': (context) => const OtpVerificationScreen(),
        '/location_permission': (context) => const LocationPermissionScreen(),
        '/location_selection': (context) => const LocationSelectionScreen(),
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
        '/popular_services': (context) => const PopularServicesScreen(),
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
      builder: (context, child) {
        if (!infra.isOnline) {
          return _buildGlobalOfflineScreen(infra);
        }
        if (infra.isMaintenanceMode) {
          return _buildGlobalMaintenanceScreen();
        }
        if (infra.isForceUpdateRequired) {
          return _buildGlobalUpdateScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  },
),
);
}

  Widget _buildGlobalOfflineScreen(AppInfraService infra) {
    const blue = Color(0xFF2563EB);
    const dark = Color(0xFF0F172A);
    const gray = Color(0xFF64748B);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFFEF2F2),
                  child: Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444), size: 36),
                ),
                const SizedBox(height: 20),
                Text('No Internet Connection', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: dark)),
                const SizedBox(height: 6),
                Text('Please check your network status. We will reconnect automatically.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: gray, height: 1.4)),
                const SizedBox(height: 24),
                SizedBox(
                  width: 180,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => infra.checkConnectivity(),
                    style: ElevatedButton.styleFrom(backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Retry Connection', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalMaintenanceScreen() {
    const blue = Color(0xFF2563EB);
    const dark = Color(0xFF0F172A);
    const gray = Color(0xFF64748B);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.construction_rounded, color: blue, size: 36),
                ),
                const SizedBox(height: 20),
                Text('Scheduled Maintenance', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: dark)),
                const SizedBox(height: 6),
                Text('We are upgrading our servers to improve performance. Nexora will be back online shortly.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: gray, height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalUpdateScreen() {
    const blue = Color(0xFF2563EB);
    const dark = Color(0xFF0F172A);
    const gray = Color(0xFF64748B);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.system_update_rounded, color: blue, size: 36),
                ),
                const SizedBox(height: 20),
                Text('App Update Required', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: dark)),
                const SizedBox(height: 6),
                Text('A newer, secure version of Nexora is available. Please update the application to continue using our marketplace.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: gray, height: 1.4)),
                const SizedBox(height: 24),
                SizedBox(
                  width: 180,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Update Now', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
