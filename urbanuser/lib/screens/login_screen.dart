import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:urbanuser/screens/signup_screen.dart';
import 'package:urbanuser/screens/mock_google_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  static bool _isGoogleInitialized = false;
  
  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty ? "Email is required" : null;
      _passwordError = _passwordController.text.trim().isEmpty ? "Password is required" : null;
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }
    
    final email = _emailController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    
    // Clear old user details from cache to prevent mixing user sessions
    await prefs.remove('userName');
    await prefs.remove('userMobile');
    await prefs.remove('userAddress');
    await prefs.remove('userAddressHouse');
    await prefs.remove('userAddressBuilding');
    await prefs.remove('userAddressStreet');
    await prefs.remove('userAddressLandmark');
    await prefs.remove('userCity');
    await prefs.remove('userState');
    await prefs.remove('userPincode');
    await prefs.remove('userAddressType');

    // Check if user already exists in Firestore
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        await prefs.setString('userName', data['name'] ?? '');
        await prefs.setString('userMobile', data['phone'] ?? '');
        
        if (data.containsKey('userAddress') && data['userAddress'] != null && data['userAddress'].toString().trim().isNotEmpty) {
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
      debugPrint("Error fetching profile on login: $e");
    }

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);
    
    final savedAddress = prefs.getString('userAddress');
    
    if (mounted) {
      // Direct to dashboard ONLY if the user has already filled out their address details
      if (savedAddress != null && savedAddress.trim().isNotEmpty) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/address_setup', (route) => false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // On Web, use FirebaseAuth's popup sign-in
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // On Mobile/Native, we use GoogleSignIn and then authenticate with Firebase
        try {
          await GoogleSignIn.instance.initialize(
            clientId: 'YOUR_WEB_CLIENT_ID',
          );
        } catch (_) {}
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
        if (googleUser == null) return; // User cancelled
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      final User? user = userCredential.user;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Clear old user details from cache to prevent mixing user sessions
      await prefs.remove('userName');
      await prefs.remove('userMobile');
      await prefs.remove('userAddress');
      await prefs.remove('userAddressHouse');
      await prefs.remove('userAddressBuilding');
      await prefs.remove('userAddressStreet');
      await prefs.remove('userAddressLandmark');
      await prefs.remove('userCity');
      await prefs.remove('userState');
      await prefs.remove('userPincode');
      await prefs.remove('userAddressType');

      final email = user.email ?? '';
      
      // Check if user already exists in Firestore
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(email).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          await prefs.setString('userName', data['name'] ?? '');
          await prefs.setString('userMobile', data['phone'] ?? '');
          
          if (data.containsKey('userAddress') && data['userAddress'] != null && data['userAddress'].toString().trim().isNotEmpty) {
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
        } else {
          // If not in Firestore, save basic details
          await prefs.setString('userName', user.displayName ?? 'Google User');
        }
      } catch (e) {
        debugPrint("Error fetching Google profile on login: $e");
        await prefs.setString('userName', user.displayName ?? 'Google User');
      }

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      
      final savedAddress = prefs.getString('userAddress');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.displayName ?? 'User'}!'),
            backgroundColor: Colors.green,
          ),
        );
        if (savedAddress != null && savedAddress.trim().isNotEmpty) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/address_setup', (route) => false);
        }
      }
    } catch (e) {
      // Fallback to Mock Google Login if standard Sign-In fails in dev/unconfigured environment
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In error ($e). Launching Mock Account Picker...'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MockGoogleLoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0A59C8);
    const darkSlate = Color(0xFF0C1A30);
    const textGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);
    const bgLight = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              // NEXORA Brand Header
              Text(
                "NEXORA",
                style: GoogleFonts.outfit(
                  color: primaryBlue,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title and Tagline
              Text(
                "Welcome back to NEXORA",
                style: GoogleFonts.outfit(
                  color: darkSlate,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Log in with your email and password to manage your home services.",
                style: GoogleFonts.outfit(
                  color: textGrey,
                  fontSize: 15,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Email Address Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "EMAIL ADDRESS",
                  style: GoogleFonts.outfit(
                    color: darkSlate,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.outfit(color: darkSlate),
                decoration: InputDecoration(
                  hintText: "name@example.com",
                  hintStyle: GoogleFonts.outfit(color: textGrey.withValues(alpha: 0.7)),
                  errorText: _emailError,
                  filled: true,
                  fillColor: bgLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Password Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PASSWORD",
                    style: GoogleFonts.outfit(
                      color: darkSlate,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot_password');
                    },
                    child: Text(
                      "Forgot?",
                      style: GoogleFonts.outfit(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.outfit(color: darkSlate),
                decoration: InputDecoration(
                  hintText: "••••••••",
                  hintStyle: GoogleFonts.outfit(color: textGrey.withValues(alpha: 0.7)),
                  errorText: _passwordError,
                  filled: true,
                  fillColor: bgLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: textGrey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Log In Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Log In ",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // OR CONTINUE WITH Separator
              Row(
                children: [
                  const Expanded(child: Divider(color: borderGrey)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "OR CONTINUE WITH",
                      style: GoogleFonts.outfit(
                        color: textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: borderGrey)),
                ],
              ),
              const SizedBox(height: 24),

              // Social Login Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: borderGrey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: bgLight,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              "https://img.icons8.com/color/48/google-logo.png",
                              height: 20,
                              width: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Google",
                              style: GoogleFonts.outfit(
                                color: darkSlate,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Apple Login is simulated. Please use Google Login.')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: borderGrey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: bgLight,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apple, color: darkSlate, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              "Apple",
                              style: GoogleFonts.outfit(
                                color: darkSlate,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Sign Up Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "New to NEXORA? ",
                    style: GoogleFonts.outfit(color: textGrey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: Text(
                      "Sign up",
                      style: GoogleFonts.outfit(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bottom Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _bottomLink("Privacy"),
                  _dotSeparator(),
                  _bottomLink("Terms"),
                  _dotSeparator(),
                  _bottomLink("Help"),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomLink(String title) {
    return GestureDetector(
      onTap: () {
        if (title == "Privacy") {
          Navigator.pushNamed(context, '/privacy_policy');
        } else if (title == "Terms") {
          Navigator.pushNamed(context, '/terms_conditions');
        } else {
          Navigator.pushNamed(context, '/help_support');
        }
      },
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _dotSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
