import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'You must agree to the Terms of Service and Privacy Policy';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create user in Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Save temp details for address setup pre-fill
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_signup_name', _nameController.text.trim());
        await prefs.setString('temp_signup_phone', _phoneController.text.trim());

        // 2. Set up user document profile in Cloud Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _nameController.text.trim(),
          'phoneNumber': '+91${_phoneController.text.trim()}',
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': true,
        });

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/address_setup');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during registration.';
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

  Future<void> _signUpWithGoogle() async {
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
      final User? user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_signup_name', user.displayName ?? '');
        await prefs.setString('temp_signup_phone', user.phoneNumber ?? '');

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/address_setup');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                        const SizedBox(height: 16),
                        
                        // Briefcase Icon / Circle Header
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.work_outline_rounded,
                              color: primaryBlue,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // NEXORA Logo
                        Text(
                          'NEXORA',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: primaryBlue,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

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

                        // Full Name
                        Text(
                          'FULL NAME',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: _inputDecoration('Enter your full name'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Phone Number
                        Text(
                          'PHONE NUMBER',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: borderGray),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+91',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: _inputDecoration('Enter 10-digit number').copyWith(
                                  counterText: '',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  if (value.length < 10) {
                                    return 'Enter a valid 10-digit phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Email
                        Text(
                          'EMAIL ADDRESS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: _inputDecoration('name@example.com'),
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
                        const SizedBox(height: 18),

                        // Password
                        Text(
                          'PASSWORD',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: _inputDecoration('••••••••').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: textGray,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                        const SizedBox(height: 18),

                        // Confirm Password
                        Text(
                          'CONFIRM PASSWORD',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: _inputDecoration('••••••••').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: textGray,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Terms and Conditions Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              activeColor: primaryBlue,
                              onChanged: (val) {
                                setState(() {
                                  _agreeToTerms = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'I agree to the Terms of Service and Privacy Policy',
                                  style: GoogleFonts.inter(
                                    color: textGray,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Join Button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
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
                                : Text(
                                    'Join NEXORA',
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

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
                        const SizedBox(height: 20),

                        // Google Sign In Button
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _signUpWithGoogle,
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

                        // Login redirect suggestion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.inter(fontSize: 14, color: textGray, fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                              child: Text(
                                'Login',
                                style: GoogleFonts.inter(fontSize: 14, color: primaryBlue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
  }

  InputDecoration _inputDecoration(String hint) {
    const borderGray = Color(0xFFE2E8F0);
    const primaryBlue = Color(0xFF2563EB);
    
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
    );
  }
}
