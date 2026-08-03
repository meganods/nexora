import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/registration_provider.dart';
import 'providers/vendor_provider.dart';
import 'theme/vendor_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_flow_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/select_category_screen.dart';
import 'screens/select_services_screen.dart';
import 'screens/work_location_screen.dart';
import 'screens/upload_documents_screen.dart';
import 'screens/pricing_availability_screen.dart';
import 'screens/review_details_screen.dart';
import 'screens/application_submitted_screen.dart';
import 'screens/application_status_screen.dart';
import 'screens/my_services_screen.dart';
import 'screens/expert_portal_dashboard.dart';
import 'screens/business_settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_management_screen.dart';
import 'screens/business_growth_screen.dart';
import 'screens/support_center_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/password_success_screen.dart';
import 'screens/pending_dashboard_screen.dart';
import 'screens/approval_success_screen.dart';
import 'screens/root_gatekeeper.dart';
import 'screens/store_setup_screen.dart';
import 'screens/vendor_store_page.dart';
import 'screens/dashboard_screen.dart';
import 'screens/store_profile_screen.dart';
import 'screens/edit_store_screen.dart';
import 'screens/products_list_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/bookings/bookings_list_screen.dart';
import 'screens/bookings/booking_details_screen.dart';
import 'screens/bookings/booking_navigation_screen.dart';
import 'screens/bookings/booking_otp_screen.dart';
import 'screens/bookings/booking_checklist_screen.dart';
import 'screens/bookings/booking_photos_screen.dart';
import 'screens/bookings/booking_invoice_screen.dart';
import 'screens/bookings/booking_summary_screen.dart';
import 'screens/bookings/active_job_dashboard_screen.dart';
import 'screens/bookings/booking_requests_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/order_details_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/coupons_screen.dart';
import 'screens/vendor_campaigns_screen.dart';
import 'screens/withdrawals_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/kyc/kyc_onboarding_flow_screen.dart';
import 'screens/kyc/kyc_status_screen.dart';
import 'screens/admin/admin_requests_screen.dart';
import 'screens/admin/admin_detail_screen.dart';
import 'screens/calendar_leave_screen.dart';
import 'screens/chat_list_screen.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
      ],
      child: const NexoraVendorApp(),
    ),
  );
}

class NexoraVendorApp extends StatelessWidget {
  const NexoraVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXORA Partner',
      theme: VendorTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/not_found': (context) => const NotFoundScreen(),
        '/help_center': (context) => const HelpCenterScreen(),
        '/settings': (context) => const BusinessSettingsScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/withdrawals': (context) => const WithdrawalsScreen(),
        '/wallet': (context) => const WalletManagementScreen(),
        '/growth': (context) => const BusinessGrowthScreen(),
        '/support': (context) => const SupportCenterScreen(),
        '/coupons': (context) => const CouponsScreen(),
        '/campaigns': (context) => const VendorCampaignsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/reviews': (context) => const ReviewsScreen(),
        '/customers': (context) => const CustomersScreen(),
        '/order_details': (context) => const OrderDetailsScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/edit_product': (context) => const EditProductScreen(),
        '/add_product': (context) => const AddProductScreen(),
        '/products_list': (context) => const ProductsListScreen(),
        '/edit_store': (context) => const EditStoreScreen(),
        '/store_profile': (context) => const StoreProfileScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegisterScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/otp': (context) => const OtpScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/password_success': (context) => const PasswordSuccessScreen(),
        '/pending_dashboard': (context) => const PendingDashboardScreen(),
        '/approval_success': (context) => const ApprovalSuccessScreen(),
        '/': (context) => const SplashScreen(),
        '/gatekeeper': (context) => const RootGatekeeper(),
        '/onboarding': (context) => const OnboardingFlowScreen(),
        '/create_profile': (context) => const CreateProfileScreen(),
        '/work_location': (context) => const WorkLocationScreen(),
        '/select_category': (context) => const SelectCategoryScreen(),
        '/select_services': (context) => const SelectServicesScreen(),
        '/upload_documents': (context) => const UploadDocumentsScreen(),
        '/pricing_availability': (context) => const PricingAvailabilityScreen(),
        '/review_details': (context) => const ReviewDetailsScreen(),
        '/application_submitted': (context) => const ApplicationSubmittedScreen(),
        '/application_status': (context) => const ApplicationStatusScreen(),
        '/my_services': (context) => const MyServicesScreen(),
        '/expert_dashboard': (context) => const ExpertPortalDashboard(),
        '/partner_profile': (context) => const VendorProfileScreen(),
        '/login': (context) => const LoginScreen(),
        '/store_setup': (context) => const StoreSetupScreen(),
        '/vendor_store': (context) => const VendorStorePage(),
        '/bookings': (context) => const BookingsListScreen(),
        '/bookings/requests': (context) => const BookingRequestsScreen(),
        '/bookings/details': (context) => const BookingDetailsScreen(),
        '/bookings/active_dashboard': (context) => const ActiveJobDashboardScreen(),
        '/bookings/navigation': (context) => const BookingNavigationScreen(),
        '/bookings/otp': (context) => const BookingOtpScreen(),
        '/bookings/checklist': (context) => const BookingChecklistScreen(),
        '/bookings/photos': (context) => const BookingPhotosScreen(),
        '/bookings/invoice': (context) => const BookingInvoiceScreen(),
        '/bookings/summary': (context) => const BookingSummaryScreen(),
        '/kyc_onboarding': (context) => const KycOnboardingFlowScreen(),
        '/kyc_status': (context) => const KycStatusScreen(),
        '/admin_requests': (context) => const AdminRequestsScreen(),
        '/admin_detail': (context) => const AdminDetailScreen(),
        '/calendar': (context) => const CalendarLeaveScreen(),
        '/chats': (context) => const ChatListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          );
        }
        return null;
      },
    );
  }
}
