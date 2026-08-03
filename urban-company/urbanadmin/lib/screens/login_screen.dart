import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<_ShakeWidgetState>();

  // State
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _buttonScaleAnim;

  // Colors
  static const _primaryBlue = Color(0xFF2563EB);
  static const _bg = Color(0xFFF8FAFC);
  static const _dark = Color(0xFF0F172A);
  static const _grey = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadRememberMe();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _buttonController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _logoScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut));

    // Staggered start
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('admin_remember_me') ?? false;
    final email = prefs.getString('admin_email') ?? '';
    if (remembered && email.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _emailController.text = email;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _shakeKey.currentState?.shake();
      _showError('Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firebase Auth
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = cred.user?.uid ?? '';

      // Firestore role check
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!adminDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _shakeKey.currentState?.shake();
        _showError('Unauthorized Access. You are not an admin.');
        setState(() => _isLoading = false);
        return;
      }

      final data = adminDoc.data()!;
      final role = data['role'] ?? '';
      final isActive = data['isActive'] ?? false;

      if (role != 'admin' && role != 'superadmin') {
        await FirebaseAuth.instance.signOut();
        _shakeKey.currentState?.shake();
        _showError('Access Denied. Insufficient admin privileges.');
        setState(() => _isLoading = false);
        return;
      }

      if (!isActive) {
        await FirebaseAuth.instance.signOut();
        _shakeKey.currentState?.shake();
        _showError('Account Disabled. Contact your system administrator.');
        setState(() => _isLoading = false);
        return;
      }

      // Update last login
      await FirebaseFirestore.instance.collection('admins').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Remember Me
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('admin_remember_me', true);
        await prefs.setString('admin_email', email);
      } else {
        await prefs.remove('admin_remember_me');
        await prefs.remove('admin_email');
      }

      if (mounted) {
        _showSuccessAndNavigate();
      }
    } on FirebaseAuthException catch (e) {
      _shakeKey.currentState?.shake();
      String msg = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') msg = 'No admin account found with this email.';
      else if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'Incorrect password. Please try again.';
      else if (e.code == 'user-disabled') msg = 'Account has been disabled. Contact support.';
      else if (e.code == 'invalid-email') msg = 'Invalid email address format.';
      else if (e.code == 'too-many-requests') msg = 'Too many attempts. Please wait a moment.';
      _showError(msg);
      setState(() => _isLoading = false);
    } catch (e) {
      _shakeKey.currentState?.shake();
      _showError('An unexpected error occurred. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessDialog(),
    );
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context).pop(); // pop dialog
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 850;
          
          if (isDesktop) {
            return Row(
              children: [
                // Left 50% Colorful Brand Panel
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -100,
                          left: -100,
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _NexoraShieldLogo(),
                                const SizedBox(height: 32),
                                Text(
                                  'NEXORA EXECUTIVE',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF93C5FD),
                                    letterSpacing: 3.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Marketplace Control Center',
                                  style: GoogleFonts.outfit(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Access administrative tools to configure categories, review service bookings, moderate users, manage coupon promotions, and securely track platform activity in real-time.',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: const Color(0xFFE2E8F0),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Color(0xFF34D399), size: 18),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Enterprise Level Encryption Active',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFFF8FAFC),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right 50% Login Screen (No Scroll)
                Expanded(
                  child: Container(
                    color: _bg,
                    child: Stack(
                      children: [
                        const _BackgroundBlobs(),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: SlideTransition(
                                position: _slideAnim,
                                child: _ShakeWidget(
                                  key: _shakeKey,
                                  child: _buildLoginCard(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Fallback Mobile/Tablet centered layout (No Scroll)
          return Stack(
            children: [
              const _BackgroundBlobs(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _ShakeWidget(
                        key: _shakeKey,
                        child: _buildLoginCard(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: 420,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 60,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildWelcomeText(),
            const SizedBox(height: 18),
            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 12),
            ],
            _buildEmailField(),
            const SizedBox(height: 12),
            _buildPasswordField(),
            const SizedBox(height: 12),
            _buildRememberRow(),
            const SizedBox(height: 16),
            _buildLoginButton(),
            const SizedBox(height: 16),
            _buildOrDivider(),
            const SizedBox(height: 16),
            _buildSecurityCard(),
            const SizedBox(height: 16),
            _buildVersionBadge(),
          ],
        ),
      ),
    );
  }


  // ─────────────── LOGO HEADER ───────────────
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          ScaleTransition(
            scale: _logoScaleAnim,
            child: _NexoraShieldLogo(),
          ),
          const SizedBox(height: 12),
          Text(
            'NEXORA',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _dark,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'ADMIN PORTAL',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
              letterSpacing: 2.8,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── WELCOME TEXT ───────────────
  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _dark,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Manage your marketplace securely.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _grey,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─────────────── ERROR BANNER ───────────────
  Widget _buildErrorBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFB91C1C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFFEF4444), size: 16),
          ),
        ],
      ),
    );
  }

  // ─────────────── EMAIL FIELD ───────────────
  Widget _buildEmailField() {
    return _InputField(
      controller: _emailController,
      label: 'Email Address',
      placeholder: 'Enter admin email',
      prefixIcon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
    );
  }

  // ─────────────── PASSWORD FIELD ───────────────
  Widget _buildPasswordField() {
    return _InputField(
      controller: _passwordController,
      label: 'Password',
      placeholder: 'Enter password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      suffixWidget: IconButton(
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20,
          color: _grey,
        ),
        splashRadius: 20,
      ),
    );
  }

  // ─────────────── REMEMBER ME ROW ───────────────
  Widget _buildRememberRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Checkbox
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  activeColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Forgot
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/forgot_password'),
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────── LOGIN BUTTON ───────────────
  Widget _buildLoginButton() {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        _handleLogin();
      },
      onTapCancel: () => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScaleAnim,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Secure Login',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─────────────── OR DIVIDER ───────────────
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ],
    );
  }

  // ─────────────── SECURITY CARD ───────────────
  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Only authorized administrators can access this dashboard.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF1E40AF),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All activities are monitored and logged for security.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── VERSION BADGE ───────────────
  Widget _buildVersionBadge() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Version 1.0.0  •  Build 2026.08.03  ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Secure',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEXORA SHIELD LOGO
// ─────────────────────────────────────────────────────────────────────────────
class _NexoraShieldLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _ShieldPainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'N',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer shield gradient
    final gradPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.22);
    path.lineTo(w, h * 0.6);
    path.quadraticBezierTo(w, h * 0.85, w * 0.5, h);
    path.quadraticBezierTo(0, h * 0.85, 0, h * 0.6);
    path.lineTo(0, h * 0.22);
    path.close();

    canvas.drawPath(path, gradPaint);

    // Inner white checkmark / wave
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final innerPath = Path();
    innerPath.moveTo(w * 0.25, h * 0.52);
    innerPath.quadraticBezierTo(w * 0.42, h * 0.35, w * 0.5, h * 0.52);
    innerPath.quadraticBezierTo(w * 0.62, h * 0.7, w * 0.76, h * 0.52);
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT FIELD WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixWidget,
    this.keyboardType,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _isFocused = false;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _border = Color(0xFFE2E8F0);
  static const _grey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),

        // Field
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: _isFocused
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused ? _primaryBlue : _border,
                width: _isFocused ? 1.8 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFCBD5E1),
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _isFocused ? _primaryBlue : _grey,
                ),
                suffixIcon: widget.suffixWidget,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND BLOBS
// ─────────────────────────────────────────────────────────────────────────────
class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right blob
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  const Color(0xFF3B82F6).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom-left blob
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF38BDF8).withValues(alpha: 0.10),
                  const Color(0xFF38BDF8).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Center subtle tint
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFEFF6FF).withValues(alpha: 0.3),
                  const Color(0xFFF8FAFC).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHAKE WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _ShakeWidget extends StatefulWidget {
  final Widget child;
  const _ShakeWidget({super.key, required this.child});

  @override
  _ShakeWidgetState createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final dx = math.sin(_animation.value * math.pi * 6) * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF22C55E), size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Login Successful!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Redirecting to dashboard…',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFDBEAFE),
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


