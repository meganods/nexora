import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _shakeKey = GlobalKey<_ShakeWidgetState>();

  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _bg = Color(0xFFF8FAFC);
  static const _dark = Color(0xFF0F172A);
  static const _grey = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _initAnimations();
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
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  Future<void> _handleResetPassword() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _shakeKey.currentState?.shake();
      setState(() => _errorMessage = 'Please enter your admin email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      _shakeKey.currentState?.shake();
      String msg = 'Failed to send reset link.';
      if (e.code == 'user-not-found') {
        msg = 'No admin account found with this email.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address format.';
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    } catch (e) {
      _shakeKey.currentState?.shake();
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    _buttonController.dispose();
    _emailController.dispose();
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
                                  'NEXORA SECURITY',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF93C5FD),
                                    letterSpacing: 3.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Account Recovery Gateway',
                                  style: GoogleFonts.outfit(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Verify your identities, request password recovery link, and return back to logging in. System sessions are heavily audited.',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: const Color(0xFFE2E8F0),
                                    height: 1.6,
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
                
                // Right 50% Forgot Password Screen (No Scroll)
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
                                  child: Container(
                                    width: 420,
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(color: _border.withValues(alpha: 0.6)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                                          blurRadius: 60,
                                          offset: const Offset(0, 20),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _isSent ? _buildSuccessView() : _buildRequestView(),
                                  ),
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
                        child: Container(
                          width: 420,
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _border.withValues(alpha: 0.6)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                                blurRadius: 60,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isSent ? _buildSuccessView() : _buildRequestView(),
                        ),
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



  Widget _buildRequestView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Reset Password',
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
          'Enter your admin email and we\'ll send a secure password reset link.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _grey,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null) ...[
          _buildErrorBanner(),
          const SizedBox(height: 16),
        ],
        _buildEmailField(),
        const SizedBox(height: 20),
        _buildSendButton(),
        const SizedBox(height: 24),
        _buildBackToLoginLink(),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF22C55E),
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Check your inbox',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _dark,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We have sent a secure password reset link to:\n${_emailController.text.trim()}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _grey,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        _buildBackToLoginButton(),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return _InputField(
      controller: _emailController,
      label: 'Email Address',
      placeholder: 'Enter admin email',
      prefixIcon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        _handleResetPassword();
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
                      const Icon(Icons.send_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        'Send Reset Link',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushReplacementNamed(context, '/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_rounded, color: _primaryBlue, size: 16),
            const SizedBox(width: 8),
            Text(
              'Back to Login',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return ElevatedButton(
      onPressed: () => Navigator.pushReplacementNamed(context, '/'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Text(
        'Return to Login',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NexoraShieldLogo extends StatelessWidget {
  const _NexoraShieldLogo();

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

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData prefixIcon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.prefixIcon,
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
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: _isFocused ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused ? _primaryBlue : _border,
                width: _isFocused ? 1.8 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
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
                border: InputBorder.none,
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

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
      ],
    );
  }
}

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
