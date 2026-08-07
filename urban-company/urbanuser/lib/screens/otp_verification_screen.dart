import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Base URL for the Nexora backend.
final String _kBackendAuthUrl = ApiConfig.baseUrl + '/api/v1/auth';

/// Countdown before user may resend — matches backend's cooldown window.
const _kResendCooldownSeconds = 30;

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  // ── Timer state ─────────────────────────────────────────────────────────────
  // _secondsRemaining counts down the resend cooldown (30 s by default).
  // When it reaches 0 the Resend button is enabled.
  int _secondsRemaining = _kResendCooldownSeconds;
  Timer? _timer;

  // ── Screen state ─────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isSendingOtp = false;
  String? _errorMessage;
  bool _verificationSuccess = false;
  String _maskedEmail = '';

  // ── Shake animation ──────────────────────────────────────────────────────────
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Shake animation for error feedback
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _loadMaskedEmailAndStartCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    super.dispose();
  }

  // ── Read masked email stored by login_screen and start 30-second cooldown ───
  Future<void> _loadMaskedEmailAndStartCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _maskedEmail = prefs.getString('_otpMaskedEmail') ?? '');
      _startCooldown();
    }
  }

  // ── 30-second resend cooldown ────────────────────────────────────────────────
  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _kResendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  // ── Get Firebase ID Token ────────────────────────────────────────────────────
  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(true);
    } catch (_) {
      return null;
    }
  }

  // ── Trigger shake animation on error ────────────────────────────────────────
  void _shake() {
    _shakeController.reset();
    _shakeController.forward();
  }

  // ── Resend OTP — calls backend, re-starts 30-second cooldown ────────────────
  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0 || _isSendingOtp) return;

    for (final c in _controllers) c.clear();
    setState(() {
      _errorMessage = null;
      _verificationSuccess = false;
      _isSendingOtp = true;
    });

    final idToken = await _getIdToken();
    if (idToken == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_kBackendAuthUrl/send-login-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final maskedEmail = body['email']?.toString() ?? _maskedEmail;
        await prefs.setString('_otpMaskedEmail', maskedEmail);

        if (mounted) {
          setState(() {
            _maskedEmail = maskedEmail;
            _isSendingOtp = false;
          });
          // Restart the resend cooldown after successful resend
          _startCooldown();
        }
      } else {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
            _errorMessage = body['message']?.toString() ??
                'Could not resend OTP. Please try again.';
          });
          _shake();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _errorMessage = 'Network error. Please check your connection.';
        });
        _shake();
      }
    }
  }

  // ── Verify OTP — calls backend /verify-login-otp ────────────────────────────
  Future<void> _verifyOtp() async {
    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.length < 6) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    final idToken = await _getIdToken();
    if (idToken == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_kBackendAuthUrl/verify-login-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken, 'otp': enteredOtp}),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        // ✅ OTP verified — persist session data
        final user = body['user'] as Map<String, dynamic>? ?? {};
        final prefs = await SharedPreferences.getInstance();

        final name    = user['name']?.toString()        ?? '';
        final phone   = user['phone']?.toString()       ?? '';
        final address = user['userAddress']?.toString() ?? '';
        final addrType = user['userAddressType']?.toString() ?? 'Home';
        final accessToken = body['accessToken']?.toString() ?? '';

        if (name.isNotEmpty)    await prefs.setString('userName', name);
        if (phone.isNotEmpty)   await prefs.setString('userMobile', phone);
        if (address.isNotEmpty) {
          await prefs.setString('userAddress', address);
          await prefs.setString('userAddressType', addrType);
        }
        if (accessToken.isNotEmpty) await prefs.setString('nexoraAccessToken', accessToken);
        await prefs.setBool('isLoggedIn', true);
        await prefs.remove('_otpMaskedEmail');

        if (mounted) {
          setState(() { _verificationSuccess = true; _isLoading = false; });
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = body['message']?.toString() ?? 'Incorrect code. Please try again.';
          });
          for (final c in _controllers) c.clear();
          _focusNodes[0].requestFocus();
          _shake();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network error. Please check your connection.';
        });
        _shake();
      }
    }
  }

  // ── OTP digit navigation ─────────────────────────────────────────────────────
  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (_errorMessage != null) setState(() => _errorMessage = null);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }
  }

  String _formatCountdown(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    const primaryBlue  = Color(0xFF2563EB);
    const bgGray       = Color(0xFFF8FAFC);
    const textDark     = Color(0xFF0F172A);
    const textGray     = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: SafeArea(
        child: _isSendingOtp
            ? _buildSendingIndicator(textGray)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // ── Wordmark ──────────────────────────────────────────────
                    Text(
                      'NEXORA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Icon badge ────────────────────────────────────────────
                    Center(
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (_, child) {
                          final offset = (_shakeAnimation.value * 10 * (1 - _shakeAnimation.value) * 2) *
                              (_shakeController.status == AnimationStatus.forward ? 1 : -1);
                          return Transform.translate(offset: Offset(offset, 0), child: child);
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: _errorMessage != null
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _errorMessage != null
                                  ? const Color(0xFFFCA5A5)
                                  : primaryBlue.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_errorMessage != null
                                        ? Colors.red
                                        : primaryBlue)
                                    .withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _verificationSuccess
                                ? Icons.check_circle_rounded
                                : Icons.mark_email_unread_rounded,
                            color: _verificationSuccess
                                ? const Color(0xFF10B981)
                                : _errorMessage != null
                                    ? const Color(0xFFEF4444)
                                    : primaryBlue,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Title ─────────────────────────────────────────────────
                    Text(
                      _verificationSuccess ? 'Verification Successful!' : 'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _verificationSuccess ? const Color(0xFF065F46) : textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Subtitle ──────────────────────────────────────────────
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 14, color: textGray, height: 1.6),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to\n'),
                          TextSpan(
                            text: _maskedEmail.isNotEmpty ? _maskedEmail : 'your registered email',
                            style: GoogleFonts.inter(fontSize: 14, color: textDark, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '\nEnter the code below to continue.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Error Banner ──────────────────────────────────────────
                    if (_errorMessage != null) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(Icons.error_outline_rounded, color: Color(0xFF991B1B), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF991B1B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── 6 OTP Digit Boxes ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (i) => _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          isDisabled: _isLoading || _verificationSuccess,
                          hasError: _errorMessage != null,
                          onChanged: (v) => _onDigitChanged(i, v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Resend section ────────────────────────────────────────
                    _buildResendSection(primaryBlue, textGray),
                    const SizedBox(height: 28),

                    // ── Verify & Continue ─────────────────────────────────────
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isLoading ||
                                _verificationSuccess ||
                                _controllers.map((c) => c.text).join().length < 6)
                            ? null
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primaryBlue.withValues(alpha: 0.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Verify & Continue',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Switch Account ────────────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Use a different account',
                          style: GoogleFonts.inter(fontSize: 13, color: textGray, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Resend section: shows countdown or the Resend button ────────────────────
  Widget _buildResendSection(Color primaryBlue, Color textGray) {
    final canResend = _secondsRemaining == 0 && !_isSendingOtp;

    if (_secondsRemaining > 0) {
      return Column(
        children: [
          Text(
            "Didn't receive the code?",
            style: GoogleFonts.inter(fontSize: 13, color: textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Circular countdown badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(
                  'Resend in ${_formatCountdown(_secondsRemaining)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.inter(fontSize: 13, color: textGray),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: canResend ? _resendOtp : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: canResend ? primaryBlue : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 16, color: canResend ? Colors.white : textGray),
                const SizedBox(width: 8),
                Text(
                  'Resend OTP',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: canResend ? Colors.white : textGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendingIndicator(Color textGray) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 20),
          Text(
            'Sending verification code\nto your email…',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: textGray, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Single OTP Digit Input Box ───────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDisabled;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDisabled,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const borderGray  = Color(0xFFE2E8F0);
    const errorRed    = Color(0xFFFCA5A5);

    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        enabled: !isDisabled,
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          counterText: '',
          fillColor: Colors.white,
          filled: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: hasError ? errorRed : borderGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: hasError ? errorRed : borderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: hasError ? errorRed : primaryBlue, width: 2.0),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
