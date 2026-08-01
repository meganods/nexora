import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isNetworkError = false;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initializeApp();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNetworkError = false;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Check internet connection
      bool hasConnection = false;
      if (kIsWeb) {
        hasConnection = true; // Avoid dart:io socket lookup on web
      } else {
        try {
          final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            hasConnection = true;
          }
        } catch (_) {
          hasConnection = false;
        }
      }

      if (!hasConnection) {
        setState(() {
          _isLoading = false;
          _isNetworkError = true;
          _errorMessage = "No internet connection detected. Please check your network and try again.";
        });
        return;
      }

      // 2. Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
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
      }

      // 3. Check onboarding completion
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // 4. Restore Authentication session and pre-fetch user profile
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get()
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint("Failed to load user profile: $e");
        }
      }

      // Ensure minimum splash screen display time for animations (2.5 seconds)
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      final remaining = 2500 - elapsed;
      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }

      if (!mounted) return;

      // 5. Navigate based on status
      if (!onboardingCompleted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else if (currentUser == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNetworkError = false;
          _errorMessage = "System initialization failed. Please try again later.\nDetails: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background Custom Painter
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: PremiumBackgroundPainter(animationValue: _bgAnimationController.value),
                child: Container(),
              );
            },
          ),
          // Subtle Light Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Logo and Branding
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Logo Icon inside premium circular design
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.handyman_rounded,
                            color: Color(0xFF2563EB),
                            size: 60,
                          ),
                        )
                            .animate()
                            .fade(duration: 800.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1.0, 1.0),
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(height: 24),
                        // Wordmark
                        Text(
                          'NEXORA',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF131B2E),
                            letterSpacing: 3.0,
                          ),
                        )
                            .animate()
                            .fade(delay: 300.ms, duration: 600.ms)
                            .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),
                        const SizedBox(height: 8),
                        // Premium tagline
                        Text(
                          'Your Service Partner. Reimagined.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF434655),
                            letterSpacing: 0.5,
                          ),
                        )
                            .animate()
                            .fade(delay: 500.ms, duration: 600.ms),
                      ],
                    ),
                    const Spacer(),
                    // Bottom State Handlers (Loading / Error Screen)
                    SizedBox(
                      height: 160,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading) ...[
                            // Premium Loading indicator matching style
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                              strokeWidth: 3,
                            ).animate().fade(duration: 300.ms),
                            const SizedBox(height: 20),
                            Text(
                              'Initializing services...',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF737686),
                              ),
                            ).animate().fade(duration: 300.ms),
                          ] else if (_errorMessage != null) ...[
                            // Error message
                            Text(
                              _isNetworkError ? 'Network Error' : 'Initialization Error',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF131B2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF434655),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Retry Button
                            ElevatedButton.icon(
                              onPressed: _initializeApp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(
                                'Retry',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                              ),
                            ).animate().scale(curve: Curves.easeOutBack, duration: 300.ms),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Premium Background Painter that draws smooth, organic flowing blobs
/// in shades of Blue (#2563EB) and Light Blue (#38BDF8)
class PremiumBackgroundPainter extends CustomPainter {
  final double animationValue;

  PremiumBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw main premium light background gradient matching Nexora Vercel app
    final bgGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        const Color(0xFFF8FAFC), // Light off-white (#F8FAFC)
        const Color(0xFFEEF6FF), // Light soft blue (#EEF6FF)
      ],
    );
    paint.shader = bgGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Bubble 1: Main Nexora Blue blob
    final double cx1 = size.width * 0.3 + 40 * math.cos(animationValue * 2 * math.pi);
    final double cy1 = size.height * 0.3 + 50 * math.sin(animationValue * 2 * math.pi);
    final double r1 = size.width * 0.65;

    final blob1Gradient = RadialGradient(
      colors: [
        const Color(0xFF2563EB).withValues(alpha: 0.15),
        const Color(0xFF2563EB).withValues(alpha: 0.0),
      ],
    );
    paint.shader = blob1Gradient.createShader(Rect.fromCircle(center: Offset(cx1, cy1), radius: r1));
    canvas.drawCircle(Offset(cx1, cy1), r1, paint);

    // Bubble 2: Sky Blue blob
    final double cx2 = size.width * 0.8 + 30 * math.sin((animationValue + 0.25) * 2 * math.pi);
    final double cy2 = size.height * 0.7 + 60 * math.cos((animationValue + 0.25) * 2 * math.pi);
    final double r2 = size.width * 0.75;

    final blob2Gradient = RadialGradient(
      colors: [
        const Color(0xFF38BDF8).withValues(alpha: 0.18),
        const Color(0xFF38BDF8).withValues(alpha: 0.0),
      ],
    );
    paint.shader = blob2Gradient.createShader(Rect.fromCircle(center: Offset(cx2, cy2), radius: r2));
    canvas.drawCircle(Offset(cx2, cy2), r2, paint);

    // Bubble 3: Accent Emerald blob (very subtle green hue matching design language accent)
    final double cx3 = size.width * 0.1 + 25 * math.sin((animationValue + 0.5) * 2 * math.pi);
    final double cy3 = size.height * 0.8 + 40 * math.cos((animationValue + 0.5) * 2 * math.pi);
    final double r3 = size.width * 0.45;

    final blob3Gradient = RadialGradient(
      colors: [
        const Color(0xFF10B981).withValues(alpha: 0.06),
        const Color(0xFF10B981).withValues(alpha: 0.0),
      ],
    );
    paint.shader = blob3Gradient.createShader(Rect.fromCircle(center: Offset(cx3, cy3), radius: r3));
    canvas.drawCircle(Offset(cx3, cy3), r3, paint);
  }

  @override
  bool shouldRepaint(covariant PremiumBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
