import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final String _kBackendAuthUrl = ApiConfig.baseUrl + '/api/v1/auth';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();

      // Check if user exists in Firestore first
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Account does not exist. Please create an account.';
          _isLoading = false;
        });
        return;
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // ─ Credentials valid: trigger backend to send OTP email ─
      final otpSent = await _sendLoginOtpViaBackend(credential.user!);
      if (!otpSent) return; // error already set in setState

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/otp_verification');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'user-not-found'
            ? 'Account does not exist. Please create an account.'
            : (_humanizeFirebaseError(e.code) ?? e.message ?? 'An error occurred during log in.');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Call backend to generate, hash, store, and email the OTP ─────────────
  Future<bool> _sendLoginOtpViaBackend(User user) async {
    try {
      final idToken = await user.getIdToken(true);
      final response = await http
          .post(
            Uri.parse('$_kBackendAuthUrl/send-login-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        // Store masked email so OTP screen can display it
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          '_otpMaskedEmail',
          body['email']?.toString() ?? '',
        );
        return true;
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = body['message']?.toString() ??
                'Could not send verification code. Please try again.';
          });
        }
        return false;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network error. Could not reach the server. Please check your connection.';
        });
      }
      return false;
    }
  }

  // ── Map Firebase error codes to user-friendly messages ───────────────────
  String? _humanizeFirebaseError(String code) {
    const map = {
      'user-not-found': 'Account does not exist. Please create an account.',
      'wrong-password': 'Incorrect password. Please try again.',
      'invalid-credential': 'Invalid email or password.',
      'user-disabled': 'This account has been disabled. Please contact support.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'network-request-failed': 'Network error. Please check your connection.',
    };
    return map[code];
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Flutter Web requires signInWithPopup — GoogleSignIn().signIn() is mobile-only
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      final User? user = userCredential.user;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google Sign-In failed. No user returned.';
        });
        return;
      }

      // Save user profile to Firestore (upsert so existing users aren't overwritten)
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnap = await userDoc.get();
      
      bool hasAddress = false;
      String existingAddress = '';
      String existingAddressType = 'Home';

      if (!docSnap.exists) {
        await userDoc.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'photoUrl': user.photoURL ?? '',
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'loginMethod': 'google',
          'hasCompletedAddressSetup': false,
        });
      } else {
        final data = docSnap.data()!;
        hasAddress = data['hasCompletedAddressSetup'] == true || 
            (data['userAddress'] != null && (data['userAddress'] as String).isNotEmpty);
        existingAddress = data['userAddress'] ?? '';
        existingAddressType = data['userAddressType'] ?? 'Home';

        // Update photo/name in case they changed in Google
        await userDoc.update({
          'name': user.displayName ?? docSnap['name'] ?? '',
          'photoUrl': user.photoURL ?? docSnap['photoUrl'] ?? '',
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      // Persist to SharedPreferences for offline profile display
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', user.displayName ?? '');
      await prefs.setString('userEmail', user.email ?? '');
      await prefs.setString('userPhotoUrl', user.photoURL ?? '');
      await prefs.setString('userMobile', user.phoneNumber ?? '');
      await prefs.setBool('isLoggedIn', true);
      
      if (hasAddress && existingAddress.isNotEmpty) {
        await prefs.setString('userAddress', existingAddress);
        await prefs.setString('userAddressType', existingAddressType);
      }

      // ─ Credentials valid: trigger backend to send OTP email ─
      final otpSent = await _sendLoginOtpViaBackend(user);
      if (!otpSent) return;

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/otp_verification');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Google Sign-In failed. Please try again.';
      if (e.code == 'popup-closed-by-user') {
        message = 'Sign-In popup was closed. Please try again.';
      } else if (e.code == 'popup-blocked') {
        message = 'Popup was blocked by your browser. Please allow popups for this site.';
      } else if (e.code == 'account-exists-with-different-credential') {
        message = 'An account already exists with the same email. Please log in with email/password.';
      } else if (e.message != null) {
        message = e.message!;
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const backgroundSlant = Color(0xFFF8FAFC);
    const borderGray = Color(0xFFE2E8F0);
    const textDark = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundSlant,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),
                        // NEXORA Logo
                        Text(
                          'NEXORA',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: primaryBlue,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Title
                        Text(
                          'Welcome back to NEXORA',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          'Log in with your email and password to manage your home services.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textGray,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF991B1B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Address Field Label
                        Text(
                          'EMAIL ADDRESS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'name@example.com',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderGray),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderGray),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegExp.hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Password Field Label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PASSWORD',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/forgot_password');
                              },
                              child: Text(
                                'Forgot?',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: textGray,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderGray),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: borderGray),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Log In Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginWithEmailPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Log In',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.login_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // OR CONTINUE WITH Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: borderGray, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: textGray,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: borderGray, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Google Login Button
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: borderGray),
                              backgroundColor: Colors.white,
                              foregroundColor: textDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                  height: 18,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign up suggestion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New to NEXORA? ',
                              style: GoogleFonts.inter(fontSize: 14, color: textGray, fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                              child: Text(
                                'Sign up',
                                style: GoogleFonts.inter(fontSize: 14, color: primaryBlue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Footer links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Privacy',
                              style: GoogleFonts.inter(fontSize: 12, color: textGray, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.circle, size: 4, color: textGray),
                            const SizedBox(width: 8),
                            Text(
                              'Terms',
                              style: GoogleFonts.inter(fontSize: 12, color: textGray, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.circle, size: 4, color: textGray),
                            const SizedBox(width: 8),
                            Text(
                              'Help',
                              style: GoogleFonts.inter(fontSize: 12, color: textGray, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
