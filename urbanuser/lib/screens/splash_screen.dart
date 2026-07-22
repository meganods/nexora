import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final email = prefs.getString('userEmail');
    
    if (isLoggedIn && email != null && email.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(email).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          await prefs.setString('userName', data['name'] ?? '');
          await prefs.setString('userMobile', data['phone'] ?? '');
          
          if (data.containsKey('userAddress') && data['userAddress'] != null) {
            await prefs.setString('userAddress', data['userAddress'] ?? '');
            await prefs.setString('userAddressHouse', data['userAddressHouse'] ?? '');
            await prefs.setString('userAddressBuilding', data['userAddressBuilding'] ?? '');
            await prefs.setString('userAddressStreet', data['userAddressStreet'] ?? '');
            await prefs.setString('userAddressLandmark', data['userAddressLandmark'] ?? '');
            await prefs.setString('userCity', data['userCity'] ?? '');
            await prefs.setString('userState', data['userState'] ?? '');
            await prefs.setString('userPincode', data['userPincode'] ?? '');
            await prefs.setString('userAddressType', data['userAddressType'] ?? 'Home');
          }
        }
      } catch (e) {
        debugPrint("Error loading profile on splash: $e");
      }
    }

    final savedAddress = prefs.getString('userAddress');
    final savedName = prefs.getString('userName');

    if (mounted) {
      if (isLoggedIn) {
        if ((savedName != null && savedName.isNotEmpty) || (savedAddress != null && savedAddress.trim().isNotEmpty)) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/address_setup');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 200,
              width: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              "NEXORA",
              style: TextStyle(
                color: Color(0xFF0C1A30),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }
}
