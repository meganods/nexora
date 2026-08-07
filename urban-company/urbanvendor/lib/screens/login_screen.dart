import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    try {
      // Firebase Sign-In
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify vendor details in Firestore
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(email).get();
      if (doc.exists) {
        final data = doc.data();
        final String status = data?['status'] ?? 'pending';

        if (mounted) {
          setState(() => _isSubmitting = false);
          AppSnackbar.show(context, "Welcome back, ${data?['ownerName'] ?? 'Partner'}!");
          
          Navigator.pushNamedAndRemoveUntil(context, '/expert_dashboard', (route) => false);
        }
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String msg = "Authentication failed";
        if (e.code == 'user-not-found') msg = "No user registered with this email.";
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = "Incorrect email or password.";
        AppSnackbar.show(context, msg, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.show(context, "An error occurred: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildDesktopLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Panel: Banner Features
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFFEFF6FF), // Soft Blue panel
            padding: const EdgeInsets.all(64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: VendorTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "NEXORA",
                      style: GoogleFonts.outfit(color: VendorTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Text(
                  "Manage Orders &\nOptimize Daily Payouts",
                  style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary, height: 1.2),
                )
                .animate()
                .fadeIn(duration: 700.ms)
                .slideY(begin: 0.1),
                const SizedBox(height: 16),
                Text(
                  "Log in to inspect active requests, respond to client chats, and view your settlements overview.",
                  style: GoogleFonts.inter(fontSize: 15, color: VendorTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        // Right Panel: Form
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildFormContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: _buildFormContent(),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome Back",
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "Access your services portal and manage client bookings.",
            style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary),
          ),
          const SizedBox(height: 36),

          // Email Field
          Text(
            "EMAIL ADDRESS",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary),
            validator: (v) {
              if (v == null || v.isEmpty) return "Email is required";
              if (!v.contains("@")) return "Enter a valid email address";
              return null;
            },
            decoration: const InputDecoration(
              hintText: "name@company.com",
              prefixIcon: Icon(Icons.email_outlined, color: VendorTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 24),

          // Password Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PASSWORD",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/forgot_password'),
                child: Text(
                  "Forgot?",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary),
            validator: (v) {
              if (v == null || v.isEmpty) return "Password is required";
              if (v.length < 6) return "Password must be at least 6 characters";
              return null;
            },
            decoration: InputDecoration(
              hintText: "••••••••",
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: VendorTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: VendorTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remember Me Checkbox
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                activeColor: VendorTheme.primaryColor,
              ),
              Text(
                "Keep me logged in",
                style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleLogin,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Log In"),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // OR divider
          Row(
            children: [
              const Expanded(child: Divider(color: VendorTheme.borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "OR SIGN IN WITH",
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary, letterSpacing: 1.2),
                ),
              ),
              const Expanded(child: Divider(color: VendorTheme.borderColor)),
            ],
          ),
          const SizedBox(height: 24),

          // Google Placeholder Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                AppSnackbar.show(context, "Google authentication hook active. Ready for API keys.");
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    "https://img.icons8.com/color/48/google-logo.png",
                    height: 20,
                    width: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text("Continue with Google"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Go to Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "New to Nexora Partner? ",
                style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Text(
                  "Register Here",
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: VendorTheme.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
