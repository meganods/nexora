import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;

      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final prefs = await SharedPreferences.getInstance();

        bool hasAddress = prefs.getString('userAddress') != null;
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if ((data['userAddress'] ?? '').toString().isNotEmpty || data['hasCompletedAddressSetup'] == true) {
            hasAddress = true;
          }
        }

        if (mounted) {
          if (hasAddress) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/address_setup');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during log in.';
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

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final prefs = await SharedPreferences.getInstance();

        bool hasAddress = prefs.getString('userAddress') != null;
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if ((data['userAddress'] ?? '').toString().isNotEmpty || data['hasCompletedAddressSetup'] == true) {
            hasAddress = true;
          }
        }

        if (mounted) {
          if (hasAddress) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            await prefs.setString('temp_signup_name', user.displayName ?? '');
            await prefs.setString('temp_signup_phone', user.phoneNumber ?? '');
            Navigator.pushReplacementNamed(context, '/address_setup');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-in failed. Please try again.';
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
                                // Trigger forgot password
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
