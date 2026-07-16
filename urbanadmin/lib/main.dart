import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
import 'screens/login_screen.dart';
import 'admin_dashboard.dart';

import 'screens/not_found_screen.dart';
import 'screens/users_screen.dart';
import 'screens/coupons_screen.dart';

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
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const NexoraAdminApp(),
    ),
  );
}


class NexoraAdminApp extends StatelessWidget {
  const NexoraAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXORA Admin Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const AdminDashboard(),
        '/users': (context) => const UsersScreen(),
        '/coupons': (context) => const CouponsScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(builder: (_) => const NotFoundScreen()),
    );
  }
}
