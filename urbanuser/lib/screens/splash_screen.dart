import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  AnimationController? _logoController;
  AnimationController? _fadeController;
  AnimationController? _shimmerController;

  Animation<double>? _logoScale;
  Animation<double>? _logoGlow;
  Animation<double>? _shimmerProgress;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkLoginStatus();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController!,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(
        parent: _logoController!,
        curve: Curves.easeInOut,
      ),
    );

    _shimmerProgress = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController!,
        curve: Curves.linear,
      ),
    );

    _logoController!.forward();
    
    // Start text fade-in after a short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _fadeController != null) {
        _fadeController!.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController?.dispose();
    _fadeController?.dispose();
    _shimmerController?.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    // Show splash for 3.5 seconds to showcase animations
    await Future.delayed(const Duration(milliseconds: 3500));
    
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
    if (_logoController == null || _fadeController == null || _shimmerController == null) {
      return const Scaffold(backgroundColor: Color(0xFFF8FAFC));
    }

    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Soft Gradient Background with subtle vignette
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFFEEF6FF), // Soft sky blue center
                  Color(0xFFF8FAFC), // Off-white edges
                ],
              ),
            ),
          ),
          
          // 2. Animated Glow Sphere in the center
          Center(
            child: AnimatedBuilder(
              animation: _logoController!,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoGlow?.value ?? 0.6,
                  child: Container(
                    width: isTablet ? 400 : 300,
                    height: isTablet ? 400 : 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.15),
                          const Color(0xFF38BDF8).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Scaled Logo
                ScaleTransition(
                  scale: _logoScale!,
                  child: Container(
                    width: isTablet ? 180 : 130,
                    height: isTablet ? 180 : 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: Image.asset(
                      "assets/images/logo.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 40 : 30),

                // Fade-in App Name & Tagline
                FadeTransition(
                  opacity: _fadeController!,
                  child: Column(
                    children: [
                      Text(
                        "NEXORA",
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 40 : 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                          color: const Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Professional Home Services",
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 18 : 15,
                          color: const Color(0xFF434655),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 60 : 45),

                // Animated Custom Shimmer Progress Indicator
                FadeTransition(
                  opacity: _fadeController!,
                  child: Container(
                    width: isTablet ? 240 : 180,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF004AC6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnimatedBuilder(
                      animation: _shimmerController!,
                      builder: (context, child) {
                        return FractionalTranslation(
                          translation: Offset(_shimmerProgress?.value ?? 0.0, 0.0),
                          child: Container(
                            width: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF2563EB).withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Staggered Minimal Footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeController!,
              child: Center(
                child: Text(
                  "POWERED BY NEXORA",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: const Color(0xFF737686),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
