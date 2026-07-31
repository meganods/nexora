import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'dart:async';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../services/kyc_service.dart';
import '../../services/cloudinary_service.dart';

class KycOnboardingFlowScreen extends StatefulWidget {
  const KycOnboardingFlowScreen({super.key});

  @override
  State<KycOnboardingFlowScreen> createState() => _KycOnboardingFlowScreenState();
}

class _KycOnboardingFlowScreenState extends State<KycOnboardingFlowScreen> {
  final KycService _kycService = KycService();
  final String _email = FirebaseAuth.instance.currentUser?.email ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = false;

  // Flow State
  String _currentStep = 'welcome';
  bool _aadhaarVerified = false;
  bool _panSubmitted = false;
  bool _gstSubmitted = false;
  
  // Step 2 & 3: Aadhaar
  final _aadhaarController = TextEditingController();
  bool _aadhaarConsent = false;
  String? _transactionId;
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _otpCountdown = 30;
  Timer? _otpTimer;

  // Step 4: PAN
  final _panNumberController = TextEditingController();
  final _panNameController = TextEditingController();
  String? _panCardUrl;
  double _panUploadProgress = 0.0;
  bool _isPanUploading = false;
  bool _panUploadFailed = false;

  // Step 5: GST
  bool _isGstRegistered = false;
  final _gstNumberController = TextEditingController();
  final _gstBusinessNameController = TextEditingController();
  final _gstAddressController = TextEditingController();
  String? _gstBusinessType;
  String? _gstState;
  String? _gstCertificateUrl;
  double _gstUploadProgress = 0.0;
  bool _isGstUploading = false;
  bool _gstUploadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedKycState();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panNumberController.dispose();
    _panNameController.dispose();
    _gstNumberController.dispose();
    _gstBusinessNameController.dispose();
    _gstAddressController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _otpTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPersistedKycState() async {
    if (_email.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(_email).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final verification = data['verification'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _currentStep = verification['currentStep'] ?? 'welcome';
          _aadhaarVerified = verification['aadhaarVerified'] ?? false;
          _panSubmitted = verification['panSubmitted'] ?? false;
          _gstSubmitted = verification['gstSubmitted'] ?? false;

          // Hydrate fields if they exist
          _aadhaarController.text = verification['aadhaarNumber'] ?? '';
          _panNumberController.text = verification['panNumber'] ?? '';
          _panNameController.text = verification['panHolderName'] ?? '';
          _panCardUrl = verification['panCardUrl'];

          final gstMap = verification['gst'] as Map<String, dynamic>? ?? {};
          _isGstRegistered = gstMap['applicable'] ?? verification['gstApplicable'] ?? false;
          _gstNumberController.text = gstMap['gstin'] ?? verification['gstNumber'] ?? '';
          _gstBusinessNameController.text = gstMap['businessName'] ?? verification['gstBusinessName'] ?? '';
          _gstCertificateUrl = gstMap['certificateUrl'] ?? verification['gstCertificateUrl'];
          _gstBusinessType = gstMap['businessType'];
          _gstAddressController.text = gstMap['registeredAddress'] ?? '';
          _gstState = gstMap['state'];
        });
      }
    } catch (e) {
      debugPrint("Error loading KYC state: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStepProgress(String step, Map<String, dynamic> data) async {
    if (_email.isEmpty) return;
    try {
      await _kycService.saveKycProgress(
        uid: _email,
        currentStep: step,
        stepData: data,
      );
      setState(() {
        _currentStep = step;
      });
    } catch (e) {
      AppSnackbar.show(context, "Failed to save progress: $e", isError: true);
    }
  }

  double _getProgressPercentage() {
    switch (_currentStep) {
      case 'welcome':
        return 0.0;
      case 'aadhaar':
      case 'aadhaar_otp':
        return 0.25;
      case 'pan':
        return 0.50;
      case 'gst':
        return 0.75;
      case 'documents':
        return 0.90;
      case 'review':
        return 0.95;
      case 'submitted':
        return 1.0;
      default:
        return 0.0;
    }
  }

  void _startOtpTimer() {
    _otpCountdown = 30;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_otpCountdown > 0) {
            _otpCountdown--;
          } else {
            _otpTimer?.cancel();
          }
        });
      }
    });
  }

  // ==========================================
  // STEP ACTION IMPLEMENTATIONS
  // ==========================================

  Future<void> _handleAadhaarSendOTP() async {
    final number = _aadhaarController.text.trim();
    if (number.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(number)) {
      AppSnackbar.show(context, "Aadhaar must be exactly 12 numeric digits", isError: true);
      return;
    }
    if (!_aadhaarConsent) {
      AppSnackbar.show(context, "Please check the consent box to continue", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final txn = await _kycService.sendAadhaarOTP(number);
      setState(() {
        _transactionId = txn;
        _currentStep = 'aadhaar_otp';
      });
      _startOtpTimer();
      if (mounted) {
        AppSnackbar.show(context, "OTP Sent successfully to registered mobile number");
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAadhaarVerifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(otp)) {
      AppSnackbar.show(context, "OTP must be 6 digits", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _kycService.verifyAadhaarOTP(_transactionId ?? '', otp);
      if (success) {
        _aadhaarVerified = true;
        await _saveStepProgress('pan', {
          'aadhaarNumber': _aadhaarController.text.trim(),
          'aadhaarVerified': true,
        });

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text("Aadhaar Verified", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("Aadhaar verified successfully. Continue to PAN details.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Continue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePANSubmit() async {
    final panNum = _panNumberController.text.trim().replaceAll(' ', '').toUpperCase();
    final panName = _panNameController.text.trim();

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(panNum)) {
      AppSnackbar.show(context, "Invalid PAN number format (e.g. ABCDE1234F)", isError: true);
      return;
    }
    if (panName.isEmpty) {
      AppSnackbar.show(context, "PAN Holder Name is required", isError: true);
      return;
    }
    if (_panCardUrl == null) {
      AppSnackbar.show(context, "Please upload your PAN Card image", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      _panSubmitted = true;
      await _saveStepProgress('gst', {
        'panNumber': panNum,
        'panHolderName': panName,
        'panCardUrl': _panCardUrl,
        'panSubmitted': true,
      });
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGSTSubmit() async {
    setState(() => _isLoading = true);
    try {
      final String gstin = _isGstRegistered ? _gstNumberController.text.trim().toUpperCase() : '';
      final String businessName = _isGstRegistered ? _gstBusinessNameController.text.trim() : '';
      final String? businessType = _isGstRegistered ? _gstBusinessType : null;
      final String registeredAddress = _isGstRegistered ? _gstAddressController.text.trim() : '';
      final String? state = _isGstRegistered ? _gstState : null;
      final String? certificateUrl = _isGstRegistered ? _gstCertificateUrl : null;

      final Map<String, dynamic> gstData = {
        'gst': {
          'applicable': _isGstRegistered,
          'gstin': gstin,
          'businessName': businessName,
          'businessType': businessType,
          'registeredAddress': registeredAddress,
          'state': state,
          'certificateUrl': certificateUrl,
          'uploadedAt': _isGstRegistered ? FieldValue.serverTimestamp() : null,
        },
        'gstSubmitted': true,
      };

      await _saveStepProgress('review', gstData);
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFinalKycSubmission() async {
    setState(() => _isLoading = true);
    try {
      await _kycService.submitKycVerification(_email);
      setState(() {
        _currentStep = 'submitted';
      });
      if (mounted) {
        AppSnackbar.show(context, "KYC documents submitted successfully!");
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // RENDER STEP CONTENT FUNCTIONS
  // ==========================================

  Widget _buildStepWelcome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PROGRESS",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2563EB),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "Step 1 of 4",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar background & colored line
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.25, // Step 1 of 4 = 25%
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Shield Icon inside circular shape/square
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF2563EB),
                  size: 56,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title: Let's Verify Your Business
          Center(
            child: Text(
              "Let's Verify Your Business",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Complete your business verification to activate your account and start receiving customer bookings.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          
          // List Card (White card, soft shadows, rounded corners)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                _buildStitchStepRow("Aadhaar Verification", true),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _buildStitchStepRow("PAN Details", false),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _buildStitchStepRow("GST Details (Optional)", false),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _buildStitchStepRow("Admin Approval", false),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // "Why Verification?" section container (light blue/grey background, rounded corners)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Why Verification?",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildWhyRow(Icons.check_circle_outline, "Receive bookings instantly after approval"),
                const SizedBox(height: 12),
                _buildWhyRow(Icons.security, "Part of our secure marketplace ecosystem"),
                const SizedBox(height: 12),
                _buildWhyRow(Icons.verified_outlined, "Prevent fraud and build customer trust"),
                const SizedBox(height: 12),
                _buildWhyRow(Icons.speed_outlined, "Fast approval within 24 hours"),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Start Verification Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0256D0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // Update status and step in Firestore before navigating
                _saveStepProgress('aadhaar', {
                  'status': 'InProgress',
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Start Verification",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStitchStepRow(String title, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_off,
          color: isDone ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          size: 22,
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
            color: isDone ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildWhyRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF1E3A8A).withOpacity(0.85),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepAadhaar() {
    final number = _aadhaarController.text.trim();
    final bool isAadhaarValid = number.length == 12 && RegExp(r'^[0-9]+$').hasMatch(number);
    final bool canSubmit = isAadhaarValid && _aadhaarConsent;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "STEP 1 OF 4",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2563EB),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "25% Complete",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.25,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Aadhaar SECURE ID Vector Card
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Aadhaar",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          "SECURE ID",
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                        ),
                      )
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.fingerprint, color: Color(0xFF2563EB), size: 48),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("YOUR NAME", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          const SizedBox(height: 4),
                          Text("XXXX XXXX XXXX", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), letterSpacing: 1.2)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 24,
                      height: 16,
                      decoration: BoxDecoration(color: Colors.orange[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Heading & Subtitle
          Text("Verify Your Aadhaar", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text("Enter your 12-digit Aadhaar number to verify your identity using OTP.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),

          // Premium Input Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Aadhaar Number", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                const SizedBox(height: 8),
                TextField(
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                  decoration: const InputDecoration(
                    hintText: "XXXX XXXX XXXX",
                    border: InputBorder.none,
                    counterText: "",
                    fillColor: Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {}); // Recalculate button disabled state
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Your Aadhaar information is encrypted and securely processed.",
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Consent Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _aadhaarConsent,
                    onChanged: (val) => setState(() => _aadhaarConsent = val ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "I authorize Nexora to verify my Aadhaar through OTP for identity verification.",
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569), fontWeight: FontWeight.w500, height: 1.4),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Timeline Process
          Text("HOW IT WORKS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 1.0)),
          const SizedBox(height: 16),
          _buildTimelineRow("1", "Enter Aadhaar Number", true),
          _buildTimelineLine(),
          _buildTimelineRow("2", "Receive OTP on registered mobile", false),
          _buildTimelineLine(),
          _buildTimelineRow("3", "Enter OTP", false),
          _buildTimelineLine(),
          _buildTimelineRow("4", "Identity Verified", false),
          const SizedBox(height: 32),

          // Bottom Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? const Color(0xFF0256D0) : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: canSubmit ? _handleAadhaarSendOTP : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Send OTP",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String index, String title, bool current) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: current ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF),
          child: Text(index, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: current ? Colors.white : const Color(0xFF2563EB))),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            color: current ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 11.0, top: 4, bottom: 4),
      child: Container(width: 2, height: 16, color: const Color(0xFFE2E8F0)),
    );
  }

  Widget _buildStepAadhaarOTP() {
    final otpStr = _otpControllers.map((c) => c.text).join();
    final bool canSubmit = otpStr.length == 6 && RegExp(r'^[0-9]+$').hasMatch(otpStr);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "STEP 2 OF 4",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2563EB),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "40% Complete",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.40, // 40% Complete
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Phone receiving OTP vector illustration
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF).withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(6),
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 12,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded, color: Color(0xFF2563EB), size: 12),
                          const SizedBox(width: 4),
                          Text("OTP: ****", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Heading & Subtitle
          Text("Verify OTP", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text("We have sent a 6-digit OTP to your Aadhaar linked mobile number ending in ******4321.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 32),

          // 6 Premium OTP input boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 46,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    setState(() {}); // Update button active status
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Resend section
          Center(
            child: Column(
              children: [
                if (_otpCountdown > 0)
                  Text("Resend OTP in 00:${_otpCountdown.toString().padLeft(2, '0')}", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))
                else
                  TextButton(
                    onPressed: _handleAadhaarSendOTP,
                    child: Text("RESEND OTP", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                  ),
                const SizedBox(height: 12),
                Text(
                  "Didn't receive OTP? Check your network or request another OTP.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Sticky Bottom Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? const Color(0xFF0256D0) : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: canSubmit ? _handleAadhaarVerifyOTP : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Verify Aadhaar",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepPAN() {
    final panNum = _panNumberController.text.trim().replaceAll(' ', '').toUpperCase();
    final panName = _panNameController.text.trim();
    final bool isPanValid = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(panNum);
    final bool hasName = panName.isNotEmpty;
    final bool hasImage = _panCardUrl != null;
    final bool canSubmit = isPanValid && hasName && hasImage;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "STEP 3 OF 4",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2563EB),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "65% Complete",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.65, // 65% Complete
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Custom Vector PAN Card Template Widget
          Center(
            child: Container(
              width: 260,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                children: [
                  // Top Row (Income Tax Department / Govt of India)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("आयकर विभाग", style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text("INCOME TAX DEPARTMENT", style: GoogleFonts.inter(fontSize: 6, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                        ],
                      ),
                      const Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF475569)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("भारत सरकार", style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text("GOVT. OF INDIA", style: GoogleFonts.inter(fontSize: 6, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                        ],
                      ),
                    ],
                  ),

                  // Left Side Placeholder lines (representing Name, Father Name, DOB fields)
                  Positioned(
                    left: 0,
                    top: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line 1: Name Placeholder Line
                        Container(
                          width: 120,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Line 2: Father's Name Placeholder Line
                        Container(
                          width: 120,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Line 3: DOB Placeholder Line
                        Container(
                          width: 80,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Typed Name Overlay
                  Positioned(
                    left: 0,
                    top: 24,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        panName.isNotEmpty ? panName.toUpperCase() : "ENTER YOUR NAME",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),

                  // Typed PAN Number Overlay
                  Positioned(
                    left: 0,
                    top: 76,
                    child: Text(
                      panNum.isNotEmpty ? panNum : "ABCDE1234F",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // Bottom signature label
                  Positioned(
                    left: 0,
                    bottom: 4,
                    child: Text(
                      "Signature",
                      style: GoogleFonts.caveat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),

                  // Right Side Hologram logo & Profile placeholder picture
                  Positioned(
                    right: 0,
                    top: 24,
                    child: Column(
                      children: [
                        // Hologram Logo
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white,
                                Colors.grey[300]!,
                                Colors.grey[400]!,
                              ],
                            ),
                            border: Border.all(color: Colors.white70, width: 1),
                          ),
                          child: const Icon(Icons.qr_code, size: 24, color: Colors.black26),
                        ),
                        const SizedBox(height: 10),
                        // Profile picture placeholder box
                        Container(
                          width: 42,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.person, size: 30, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Heading & Subtitle
          Text("PAN Information", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text("Provide your PAN details for business verification. This helps us ensure a secure marketplace.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),

          // PAN inputs
          TextField(
            controller: _panNumberController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              PanTextInputFormatter(),
            ],
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: "PAN Number",
              hintText: "ABCDE1234F",
              helperText: isPanValid ? null : "Example: ABCDE1234F",
              errorText: panNum.isNotEmpty && !isPanValid ? "Please enter a valid PAN number (Example: ABCDE1234F)." : null,
              suffixIcon: isPanValid ? const Icon(Icons.check_circle, color: Colors.green) : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isPanValid ? Colors.green : (panNum.isNotEmpty && !isPanValid ? Colors.red : const Color(0xFFCBD5E1)),
                  width: isPanValid || (panNum.isNotEmpty && !isPanValid) ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isPanValid ? Colors.green : (panNum.isNotEmpty && !isPanValid ? Colors.red : const Color(0xFF2563EB)),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 16),
           TextField(
            controller: _panNameController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(text: newValue.text.toUpperCase());
              }),
            ],
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: "PAN Holder Name",
              hintText: "As printed on card",
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Upload card
          Text("UPLOAD PAN CARD", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF64748B), letterSpacing: 1.0)),
          const SizedBox(height: 12),
          _buildUploadCard(
            url: _panCardUrl,
            isUploading: _isPanUploading,
            uploadProgress: _panUploadProgress,
            failed: _panUploadFailed,
            onPick: (file) => _uploadDocumentFile(file, true),
            onRemove: () => setState(() => _panCardUrl = null),
          ),
          const SizedBox(height: 20),

          // Shield security card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your PAN details are securely stored and will be reviewed by our verification team. We use AES-256 encryption for data protection.",
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E40AF), fontWeight: FontWeight.w500, height: 1.4),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Sticky Bottom Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? const Color(0xFF0256D0) : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: canSubmit ? _handlePANSubmit : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Continue",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepGST() {
    final String gstin = _gstNumberController.text.trim().toUpperCase();
    final String businessName = _gstBusinessNameController.text.trim();
    final String address = _gstAddressController.text.trim();

    final bool isGstinValid = gstin.length == 15;
    final bool isNameValid = businessName.length >= 3;
    final bool isTypeValid = _gstBusinessType != null;
    final bool isAddressValid = address.isNotEmpty;
    final bool isStateValid = _gstState != null;
    final bool isCertUploaded = _gstCertificateUrl != null;

    final bool canSubmit = !_isGstRegistered || 
        (isGstinValid && isNameValid && isTypeValid && isAddressValid && isStateValid && isCertUploaded);

    final List<String> businessTypes = [
      "Proprietorship",
      "Partnership",
      "LLP",
      "Private Limited Company",
      "Public Limited Company",
      "One Person Company",
      "Trust",
      "Society",
      "Other"
    ];

    final List<String> indianStates = [
      "Andaman and Nicobar Islands",
      "Andhra Pradesh",
      "Arunachal Pradesh",
      "Assam",
      "Bihar",
      "Chandigarh",
      "Chhattisgarh",
      "Dadra and Nagar Haveli and Daman and Diu",
      "Delhi",
      "Goa",
      "Gujarat",
      "Haryana",
      "Himachal Pradesh",
      "Jammu and Kashmir",
      "Jharkhand",
      "Karnataka",
      "Kerala",
      "Ladakh",
      "Lakshadweep",
      "Madhya Pradesh",
      "Maharashtra",
      "Manipur",
      "Meghalaya",
      "Mizoram",
      "Nagaland",
      "Odisha",
      "Puducherry",
      "Punjab",
      "Rajasthan",
      "Sikkim",
      "Tamil Nadu",
      "Telangana",
      "Tripura",
      "Uttar Pradesh",
      "Uttarakhand",
      "West Bengal"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Step Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "STEP 4 OF 4",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      "90% Complete",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bar
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.90, // 90% Complete
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Heading & Subtitle
                Text(
                  "GST Registration Details",
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  "Provide your GST registration details if your business is GST registered. These details will be reviewed by our verification team.",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Question Selection
                Text(
                  "Is your business registered under GST?",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGstRegistered = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isGstRegistered ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !_isGstRegistered ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: !_isGstRegistered ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                !_isGstRegistered ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: !_isGstRegistered ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "No",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: !_isGstRegistered ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGstRegistered = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isGstRegistered ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isGstRegistered ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: _isGstRegistered ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isGstRegistered ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _isGstRegistered ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Yes",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: _isGstRegistered ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // GST Fields (Yes option selected)
                if (_isGstRegistered) ...[
                  const SizedBox(height: 24),

                  // 1. GSTIN Field
                  TextField(
                    controller: _gstNumberController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(text: newValue.text.toUpperCase());
                      }),
                    ],
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "GSTIN Number",
                      hintText: "22AAAAA0000A1Z5",
                      helperText: isGstinValid ? null : "Example: 22AAAAA0000A1Z5",
                      errorText: gstin.isNotEmpty && !isGstinValid ? "Please enter a valid 15-character GSTIN number." : null,
                      suffixIcon: isGstinValid ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isGstinValid ? Colors.green : (gstin.isNotEmpty && !isGstinValid ? Colors.red : const Color(0xFFCBD5E1)),
                          width: isGstinValid || (gstin.isNotEmpty && !isGstinValid) ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isGstinValid ? Colors.green : (gstin.isNotEmpty && !isGstinValid ? Colors.red : const Color(0xFF2563EB)),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // 2. Business Name
                  TextField(
                    controller: _gstBusinessNameController,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Registered Business Name",
                      hintText: "ABC Services Private Limited",
                      errorText: businessName.isNotEmpty && !isNameValid ? "Name must be at least 3 characters long." : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // 3. Legal Business Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _gstBusinessType,
                    items: businessTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _gstBusinessType = val),
                    decoration: InputDecoration(
                      labelText: "Legal Business Type",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Address Multi-line TextField
                  TextField(
                    controller: _gstAddressController,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Registered Business Address",
                      hintText: "Enter the address exactly as mentioned in your GST registration.",
                      alignLabelWithHint: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // 5. State / UT Dropdown
                  DropdownButtonFormField<String>(
                    value: _gstState,
                    items: indianStates.map((stateVal) {
                      return DropdownMenuItem<String>(
                        value: stateVal,
                        child: Text(stateVal, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _gstState = val),
                    decoration: InputDecoration(
                      labelText: "State / Union Territory",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Upload certificate card
                  Text("UPLOAD GST REGISTRATION CERTIFICATE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  _buildUploadCard(
                    url: _gstCertificateUrl,
                    isUploading: _isGstUploading,
                    uploadProgress: _gstUploadProgress,
                    failed: _gstUploadFailed,
                    onPick: (file) => _uploadDocumentFile(file, false),
                    onRemove: () => setState(() => _gstCertificateUrl = null),
                  ),
                ],
                const SizedBox(height: 20),

                // Information Secure Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your information is secure",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Your GST information is securely stored and reviewed only for vendor verification purposes. Documents are protected using encrypted cloud storage.",
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E40AF), height: 1.4),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Sticky Bottom Continue Button
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: canSubmit ? _handleGSTSubmit : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Continue", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Document Upload Status", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 6),
        Text("Review and upload all required identity and business verification proofs.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 24),
        _buildDocumentReviewRow("PAN Card Document", _panCardUrl != null),
        const SizedBox(height: 12),
        _buildDocumentReviewRow("GST Certificate Document", !_isGstRegistered || _gstCertificateUrl != null),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => setState(() => _currentStep = 'review'),
            child: const Text("Proceed to Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Review Application", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 6),
        Text("Double check details before final submission.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewSummaryRow("Aadhaar Number", _aadhaarController.text),
              _buildReviewSummaryRow("Aadhaar OTP", "Verified Successfully", isGreen: true),
              const Divider(height: 24),
              _buildReviewSummaryRow("PAN Number", _panNumberController.text),
              _buildReviewSummaryRow("PAN Holder Name", _panNameController.text),
              const Divider(height: 24),
              _buildReviewSummaryRow("GST Status", _isGstRegistered ? "GST Registered" : "Not Registered"),
              if (_isGstRegistered) ...[
                _buildReviewSummaryRow("GSTIN Number", _gstNumberController.text),
                _buildReviewSummaryRow("Business Name", _gstBusinessNameController.text),
              ],
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => setState(() => _currentStep = 'documents'),
                  child: const Text("Back"),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _handleFinalKycSubmission,
                  child: const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStepSubmitted() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 46,
          backgroundColor: Color(0xFFDCFCE7),
          child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 64),
        ),
        const SizedBox(height: 24),
        Text("Verification Submitted", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22, color: VendorTheme.textPrimary)),
        const SizedBox(height: 10),
        Text(
          "Your verification request has been submitted successfully.\nOur admin team is currently reviewing your documents.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text("Estimated Review Time: 24-48 Hours", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/gatekeeper', (route) => false);
            },
            child: const Text("View Status Screen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET HELPER UTILS
  // ==========================================

  Widget _buildChecklistItem(String title, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: checked ? const Color(0xFF16A34A) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 13.5, color: checked ? VendorTheme.textPrimary : Colors.grey[600], fontWeight: checked ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildDocumentReviewRow(String title, bool verified) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: verified ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
            radius: 18,
            child: Icon(verified ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: verified ? const Color(0xFF16A34A) : Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5))),
          Text(verified ? "Uploaded" : "Pending", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: verified ? const Color(0xFF16A34A) : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildReviewSummaryRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isGreen ? const Color(0xFF16A34A) : VendorTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String? url,
    required bool isUploading,
    required double uploadProgress,
    required bool failed,
    required Function(XFile) onPick,
    required VoidCallback onRemove,
  }) {
    if (url != null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.contain),
        ),
        alignment: Alignment.topRight,
        child: IconButton(
          icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18)),
          onPressed: onRemove,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          if (isUploading) ...[
            const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: 12),
            Text("Uploading... ${(uploadProgress * 100).toStringAsFixed(0)}%", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          ] else if (failed) ...[
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
            const SizedBox(height: 8),
            Text("Upload failed. Try again.", style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showImageSourcePicker(onPick),
              child: const Text("Retry Upload"),
            ),
          ] else ...[
            const Icon(Icons.cloud_upload_outlined, color: Colors.grey, size: 36),
            const SizedBox(height: 8),
            Text("Upload Proof Card", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            Text("JPG, PNG up to 5MB", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showImageSourcePicker(onPick),
                  icon: const Icon(Icons.add_a_photo, size: 14),
                  label: const Text("Select File"),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  void _showImageSourcePicker(Function(XFile) onPick) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (file != null) onPick(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (file != null) onPick(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadDocumentFile(XFile file, bool isPan) async {
    setState(() {
      if (isPan) {
        _isPanUploading = true;
        _panUploadProgress = 0.1;
        _panUploadFailed = false;
      } else {
        _isGstUploading = true;
        _gstUploadProgress = 0.1;
        _gstUploadFailed = false;
      }
    });

    // Simulate cropping & compression
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      if (isPan) setState(() => _panUploadProgress = 0.4);
      else setState(() => _gstUploadProgress = 0.4);

      String? url;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        url = await CloudinaryService.uploadImageBytes(
          bytes: bytes,
          fileName: file.name,
          folder: 'urban_company/vendor_profiles',
        );
      } else {
        url = await _kycService.uploadDocument(file.path);
      }
      
      if (isPan) setState(() => _panUploadProgress = 0.8);
      else setState(() => _gstUploadProgress = 0.8);

      if (url != null) {
        setState(() {
          if (isPan) {
            _panCardUrl = url;
            _isPanUploading = false;
            _panUploadProgress = 1.0;
          } else {
            _gstCertificateUrl = url;
            _isGstUploading = false;
            _gstUploadProgress = 1.0;
          }
        });
      } else {
        throw Exception("Cloudinary upload failed");
      }
    } catch (e) {
      debugPrint("Cloudinary upload failed: $e");
      if (mounted) {
        AppSnackbar.show(context, 'Cloudinary upload failed. Please try again.');
      }
      setState(() {
        if (isPan) {
          _isPanUploading = false;
          _panUploadFailed = true;
          _panCardUrl = null;
        } else {
          _isGstUploading = false;
          _gstUploadFailed = true;
          _gstCertificateUrl = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep == 'submitted'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (_currentStep == 'welcome') {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/settings');
                    }
                    return;
                  }
                  setState(() {
                    if (_currentStep == 'aadhaar') _currentStep = 'welcome';
                    else if (_currentStep == 'aadhaar_otp') _currentStep = 'aadhaar';
                    else if (_currentStep == 'pan') _currentStep = 'aadhaar';
                    else if (_currentStep == 'gst') _currentStep = 'pan';
                    else if (_currentStep == 'documents') _currentStep = 'gst';
                    else if (_currentStep == 'review') _currentStep = 'documents';
                  });
                },
              ),
        title: Text(
          "Business Verification",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Bar
            if (_currentStep != 'welcome' && _currentStep != 'submitted') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _getProgressPercentage(),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFEFF6FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
              ),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildCurrentStepWidget(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 'welcome':
        return _buildStepWelcome();
      case 'aadhaar':
        return _buildStepAadhaar();
      case 'aadhaar_otp':
        return _buildStepAadhaarOTP();
      case 'pan':
        return _buildStepPAN();
      case 'gst':
        return _buildStepGST();
      case 'documents':
        return _buildStepDocuments();
      case 'review':
        return _buildStepReview();
      case 'submitted':
        return _buildStepSubmitted();
      default:
        return _buildStepWelcome();
    }
  }
}

class PanTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If characters were deleted, allow changes
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    final text = newValue.text.toUpperCase();
    
    // Enforce max length of 10
    if (text.length > 10) {
      return oldValue;
    }

    // Validate each character against the position-specific rules
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (i < 5) {
        // Positions 1-5 (index 0-4): Letters only (A-Z)
        if (!RegExp(r'^[A-Z]$').hasMatch(char)) {
          return oldValue;
        }
      } else if (i < 9) {
        // Positions 6-9 (index 5-8): Digits only (0-9)
        if (!RegExp(r'^[0-9]$').hasMatch(char)) {
          return oldValue;
        }
      } else {
        // Position 10 (index 9): Letter only (A-Z)
        if (!RegExp(r'^[A-Z]$').hasMatch(char)) {
          return oldValue;
        }
      }
    }

    return newValue.copyWith(
      text: text,
      selection: newValue.selection,
    );
  }
}
