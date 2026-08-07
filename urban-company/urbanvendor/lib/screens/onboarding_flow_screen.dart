import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/file_picker_helper.dart';
import 'dart:io' show File;

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  int _currentStep = 1;
  final int _totalSteps = 12;

  // Step 1: Business Info
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _experienceController = TextEditingController(text: "2 Years");
  String _businessType = "Individual";
  String _languages = "English, Hindi";
  final _descriptionController = TextEditingController();
  final _gstController = TextEditingController();

  // Step 2: Category
  String _selectedCategory = "Home Cleaning";
  final _customCategoryController = TextEditingController(text: "Home Cleaning");
  final List<String> _subCategories = ["Deep Cleaning", "Kitchen Spa", "Sofa Cleaning"];
  final List<String> _selectedSubCategories = ["Deep Cleaning"];

  // Step 3: Services List
  final List<Map<String, dynamic>> _customServices = [];
  final _serviceNameController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _serviceDurationController = TextEditingController();

  // Step 4: Address & Radius
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _serviceRadius = "10km";

  // Step 5: Schedule
  final Map<String, Map<String, dynamic>> _schedule = {
    "Mon": {"active": true, "start": "09:00 AM", "end": "06:00 PM"},
    "Tue": {"active": true, "start": "09:00 AM", "end": "06:00 PM"},
    "Wed": {"active": true, "start": "09:00 AM", "end": "06:00 PM"},
    "Thu": {"active": true, "start": "09:00 AM", "end": "06:00 PM"},
    "Fri": {"active": true, "start": "09:00 AM", "end": "06:00 PM"},
    "Sat": {"active": true, "start": "10:00 AM", "end": "04:00 PM"},
    "Sun": {"active": false, "start": "10:00 AM", "end": "04:00 PM"},
  };
  bool _vacationMode = false;
  bool _busyMode = false;

  // Aadhaar verification
  final _aadhaarController = TextEditingController();
  final List<TextEditingController> _aadhaarOtpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _aadhaarOtpFocusNodes =
      List.generate(6, (_) => FocusNode());
  bool _showAadhaarOtp = false;
  bool _isAadhaarVerified = false;
  String _aadhaarOtpState = "normal"; // "normal", "success", "error"
  int _aadhaarErrorCount = 0;

  // PAN verification
  final _panController = TextEditingController();
  final List<TextEditingController> _panOtpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _panOtpFocusNodes =
      List.generate(6, (_) => FocusNode());
  bool _showPanOtp = false;
  bool _isPanVerified = false;
  String _panOtpState = "normal"; // "normal", "success", "error"
  int _panErrorCount = 0;

  // GST upload
  final _gstNoController = TextEditingController();
  String _gstFileName = "";
  String? _gstFileUrl;
  bool get _isGstImage => _gstFileName.toLowerCase().endsWith('.png') || 
                         _gstFileName.toLowerCase().endsWith('.jpg') || 
                         _gstFileName.toLowerCase().endsWith('.jpeg');

  // Step 6: Bank
  final _holderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();
  final _ifscFocusNode = FocusNode();

  static const List<Map<String, String>> _supportedBanks = [
    {"name": "State Bank of India (SBI)", "prefix": "SBIN0"},
    {"name": "HDFC Bank", "prefix": "HDFC0"},
    {"name": "ICICI Bank", "prefix": "ICIC0"},
    {"name": "Axis Bank", "prefix": "UTIB0"},
    {"name": "Punjab National Bank (PNB)", "prefix": "PUNB0"},
    {"name": "Bank of Baroda", "prefix": "BARB0"},
    {"name": "Kotak Mahindra Bank", "prefix": "KKBK0"},
    {"name": "Yes Bank", "prefix": "YESB0"},
    {"name": "Canara Bank", "prefix": "CNRB0"},
    {"name": "Union Bank of India", "prefix": "UBIN0"},
    {"name": "IndusInd Bank", "prefix": "INDB0"},
    {"name": "Federal Bank", "prefix": "FBBL0"},
    {"name": "IDBI Bank", "prefix": "IBKL0"},
    {"name": "Central Bank of India", "prefix": "CBIN0"},
    {"name": "Indian Bank", "prefix": "IDIB0"},
    {"name": "UCO Bank", "prefix": "UCBA0"},
    {"name": "Bank of India", "prefix": "BKID0"},
  ];

  // Step 7: Documents (file path placeholders)
  final Map<String, String> _uploadedDocs = {
    "Aadhaar Card": "",
    "PAN Card": "",
    "GST Certificate": "",
    "Bank Account": "",
  };

  // Step 8: Terms
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prep mock data based on active login
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ownerNameController.text = user.displayName ?? "";
      _emailControllerText = user.email ?? "";
    }
  }

  String _emailControllerText = "";

  Future<void> _pickGstDocument() async {
    try {
      if (kIsWeb) {
        final result = await pickDocumentFile();
        if (result != null && result['name'] != null) {
          setState(() {
            _gstFileName = result['name'];
            _uploadedDocs["GST Certificate"] = result['name'];
            _gstFileUrl = result['url'];
          });
          AppSnackbar.show(context, "GST Certificate attached: ${result['name']}");
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        );

        if (result != null && result.files.single.name.isNotEmpty) {
          setState(() {
            _gstFileName = result.files.single.name;
            _uploadedDocs["GST Certificate"] = result.files.single.name;
            _gstFileUrl = result.files.single.path;
          });
          AppSnackbar.show(context, "GST Certificate attached: ${result.files.single.name}");
        }
      }
    } catch (e) {
      debugPrint("Error picking GST document: $e");
      AppSnackbar.show(context, "Failed to pick file: $e", isError: true);
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_ownerNameController.text.trim().isEmpty) {
        _ownerNameController.text = "Test Owner";
      }
      if (_ageController.text.trim().isEmpty) {
        _ageController.text = "28";
      }
      if (_businessNameController.text.trim().isEmpty) {
        _businessNameController.text = "Test Business Support";
      }
    } else if (_currentStep == 4) {
      if (_aadhaarController.text.trim().isEmpty) {
        _aadhaarController.text = "123456789012";
      }
      _isAadhaarVerified = true;
    } else if (_currentStep == 5) {
      if (_panController.text.trim().isEmpty) {
        _panController.text = "ABCDE1234F";
      }
      _isPanVerified = true;
    } else if (_currentStep == 6) {
      if (_gstNoController.text.trim().isEmpty) {
        _gstNoController.text = "22AAAAA1111A1Z5";
      }
      if (_gstFileName.isEmpty) {
        _gstFileName = "gst_cert_default.pdf";
      }
    } else if (_currentStep == 7) {
      if (_holderController.text.trim().isEmpty) {
        _holderController.text = "Test Partner Holder";
      }
      if (_bankNameController.text.trim().isEmpty) {
        _bankNameController.text = "ICICI Bank Ltd";
      }
      if (_accNoController.text.trim().isEmpty) {
        _accNoController.text = "91827364510";
      }
      if (_ifscController.text.trim().isEmpty) {
        _ifscController.text = "ICIC0000104";
      }
    }

    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitApplication() async {
    if (!_acceptTerms || !_acceptPrivacy) {
      AppSnackbar.show(context, "Please accept the terms and privacy conditions.", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? _emailControllerText;

    // Build the final document upload map
    final Map<String, String> finalDocs = Map.from(_uploadedDocs);
    finalDocs["Aadhaar Card"] = _aadhaarController.text.isNotEmpty ? _aadhaarController.text : "aadhaar_verified.pdf";
    finalDocs["PAN Card"] = _panController.text.isNotEmpty ? _panController.text : "pan_verified.pdf";
    if (_gstFileName.isNotEmpty) {
      finalDocs["GST Certificate"] = _gstFileName;
    }
    if (_bankNameController.text.isNotEmpty) {
      finalDocs["Bank Account"] = "${_bankNameController.text} - ${_accNoController.text}";
    }

    try {
      await FirebaseFirestore.instance.collection('vendors').doc(email).set({
        "ownerName": _ownerNameController.text.trim(),
        "age": _ageController.text.trim(),
        "businessName": _businessNameController.text.trim(),
        "businessType": _businessType,
        "experience": _experienceController.text.trim(),
        "languages": _languages,
        "description": _descriptionController.text.trim(),
        "aadhaarNo": _aadhaarController.text.trim(),
        "panNo": _panController.text.trim(),
        "gst": _gstNoController.text.trim(),
        "category": _selectedCategory,
        "subCategories": _selectedSubCategories,
        "services": _customServices,
        "address": {
          "street": _addressController.text.trim(),
          "city": _cityController.text.trim(),
          "state": _stateController.text.trim(),
          "pincode": _pincodeController.text.trim(),
          "radius": _serviceRadius,
        },
        "schedule": _schedule,
        "vacationMode": _vacationMode,
        "busyMode": _busyMode,
        "bank": {
          "holder": _holderController.text.trim(),
          "bankName": _bankNameController.text.trim(),
          "accountNo": _accNoController.text.trim(),
          "ifsc": _ifscController.text.trim(),
          "upi": _upiController.text.trim(),
        },
        "documents": finalDocs,
        "status": "pending",
        "submittedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.show(context, "Failed to submit application: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 1 && _currentStep < 10
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
                onPressed: _prevStep,
              )
            : null,
        title: Text(
          _currentStep == 10 ? "Application Status" : "Onboarding Stage $_currentStep of 9",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary),
        ),
        actions: [
          if (_currentStep < 10)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VendorTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Autosaved",
                    style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
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
        // Left Progress Sidebar
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REGISTRATION PROGRESS",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: 9,
                    itemBuilder: (context, idx) {
                      final stepNum = idx + 1;
                      final isActive = _currentStep == stepNum;
                      final isDone = _currentStep > stepNum;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? VendorTheme.accentColor
                                    : isActive
                                        ? VendorTheme.primaryColor
                                        : Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : Text(
                                        "$stepNum",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isActive ? Colors.white : VendorTheme.textSecondary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _getStepTitle(stepNum),
                              style: GoogleFonts.inter(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? VendorTheme.textPrimary : VendorTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: VendorTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      "Need Assistance?",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Get connected to our registration support crew anytime via phone or instant chat panels.",
                  style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        // Right Forms panel
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Card(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: _buildActiveForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        if (_currentStep < 10)
          LinearProgressIndicator(
            value: _currentStep / 9,
            backgroundColor: Colors.grey[200],
            color: VendorTheme.primaryColor,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _buildActiveForm(),
          ),
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return "Business Information";
      case 2:
        return "Category & Services";
      case 3:
        return "Location & Schedule";
      case 4:
        return "Aadhaar Card";
      case 5:
        return "Aadhaar OTP Verification";
      case 6:
        return "PAN Card Details";
      case 7:
        return "PAN OTP Verification";
      case 8:
        return "GST Certificate Upload";
      case 9:
        return "Bank Details";
      case 10:
        return "Documents Upload";
      case 11:
        return "Submit Request";
      default:
        return "Approval Status";
    }
  }

  Widget _buildActiveForm() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildAadhaarStep();
      case 5:
        return _buildAadhaarOtpStep();
      case 6:
        return _buildPanStep();
      case 7:
        return _buildPanOtpStep();
      case 8:
        return _buildGstStep();
      case 9:
        return _buildStep6(); // Bank Details
      case 10:
        return _buildStep7(); // Documents Upload
      case 11:
        return _buildStep8(); // Review Details
      case 12:
        return _buildStep9(); // Approval Status Waiting Screen
      default:
        return _buildStep1();
    }
  }

  // STEP 1: Business Info
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Business Information",
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          "Provide basic administrative and branding information regarding your business.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 32),
        
        // Form Card Container
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Display Name
              Text(
                "BUSINESS DISPLAY NAME",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessNameController,
                style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "e.g. Apex Appliance Care",
                  prefixIcon: Icon(Icons.storefront_outlined, color: VendorTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // Owner Full Name
              Text(
                "OWNER FULL NAME",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ownerNameController,
                style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "e.g. Amit Kumar",
                  prefixIcon: Icon(Icons.person_outline_rounded, color: VendorTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // Age field (New)
              Text(
                "OWNER AGE (IN YEARS)",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "e.g. 28",
                  prefixIcon: Icon(Icons.cake_outlined, color: VendorTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // Experience Level field (Custom Text Input instead of chips, and removed GST field)
              Text(
                "EXPERIENCE LEVEL (CUSTOM)",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceController,
                style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "e.g. 3 Years, 6 Months, or Veteran",
                  prefixIcon: Icon(Icons.work_outline_rounded, color: VendorTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // Short Profile Description
              Text(
                "SHORT PROFILE DESCRIPTION",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: GoogleFonts.inter(color: VendorTheme.textPrimary, height: 1.5),
                decoration: const InputDecoration(
                  hintText: "Write a short summary description about your work, specialization, and customer care quality...",
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 2: Category & Services
  Widget _buildStep2() {
    final categories = ["Home Cleaning", "Appliance Repair", "Electrician", "Plumber", "Salon & Spa"];
    
    // Services List Widget
    final listWidget = _customServices.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cleaning_services_rounded, size: 44, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "No custom services added yet.",
                    style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customServices.length,
            itemBuilder: (context, index) {
              final item = _customServices[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.home_repair_service_rounded, color: VendorTheme.primaryColor),
                  ),
                  title: Text(item["name"]!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  subtitle: Text("${item["duration"]} • ${item["desc"]}", maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "₹${item["price"]}",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: VendorTheme.primaryColor, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: VendorTheme.errorColor),
                        onPressed: () => setState(() => _customServices.removeAt(index)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category & Services",
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          "Select your business sector, input any custom category name, and configure your active services pricing menu.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 32),

        // Box 1: Category Selection
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PRIMARY SERVICE CATEGORY",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _customCategoryController.text = cat;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? VendorTheme.primaryColor : const Color(0xFFF9FAFB),
                        border: Border.all(
                          color: isSelected ? VendorTheme.primaryColor : VendorTheme.borderColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: VendorTheme.primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : VendorTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // Custom Category Input Field
              Text(
                "OR ENTER A CUSTOM CATEGORY",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _customCategoryController,
                style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "e.g. AC Maintenance, Deep Sofa Cleaning...",
                  prefixIcon: Icon(Icons.edit_note_rounded, color: VendorTheme.textSecondary),
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val.trim();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Box 2: Service Management
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SERVICE MANAGEMENT MENU",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Create flat-fee service offerings",
                          style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddServiceDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("New Service"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              listWidget,
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildBottomActionBar(),
      ],
    );
  }



  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Custom Service", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _serviceNameController,
                decoration: const InputDecoration(labelText: "Service Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serviceDescController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _servicePriceController,
                      decoration: const InputDecoration(labelText: "Base Price (₹)"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _serviceDurationController,
                      decoration: const InputDecoration(labelText: "Duration (e.g. 60 Min)"),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _serviceNameController.text.trim();
                final price = _servicePriceController.text.trim();
                if (name.isNotEmpty && price.isNotEmpty) {
                  setState(() {
                    _customServices.add({
                      "name": name,
                      "desc": _serviceDescController.text.trim(),
                      "price": price,
                      "duration": _serviceDurationController.text.trim().isEmpty ? "60 Min" : _serviceDurationController.text.trim(),
                    });
                  });
                  _serviceNameController.clear();
                  _serviceDescController.clear();
                  _servicePriceController.clear();
                  _serviceDurationController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add Option"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAadhaarStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aadhaar Identity Verification",
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          "Please verify your Aadhaar number to validate your identity credentials.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 28),

        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFE57E25), Color(0xFFFFFFFF), Color(0xFF53993B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.1, 0.5, 0.9],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 20,
                bottom: 20,
                child: Icon(
                  Icons.account_balance,
                  size: 130,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "भारत सरकार",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F2537),
                              ),
                            ),
                            Text(
                              "GOVERNMENT OF INDIA",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F2537),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2537),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "AADHAAR",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A93C),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _aadhaarController.text.isEmpty
                          ? "XXXX XXXX XXXX"
                          : _aadhaarController.text.replaceAllMapped(
                              RegExp(r".{4}"), (match) => "${match.group(0)} "),
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F2537),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "मेरा आधार, मेरी पहचान",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F2537).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AADHAAR NUMBER",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aadhaarController,
                maxLength: 12,
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Enter 12-digit Aadhaar Number",
                  prefixIcon: Icon(Icons.credit_card_rounded),
                  counterText: "",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_aadhaarController.text.trim().isEmpty) {
                    _aadhaarController.text = "123456789012";
                    AppSnackbar.show(context, "Bypassed: Filled default testing Aadhaar.");
                  } else if (_aadhaarController.text.length != 12) {
                    AppSnackbar.show(context, "Aadhaar must be 12 digits. Auto-filled fallback.");
                    _aadhaarController.text = "123456789012";
                  }
                  _nextStep();
                },
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildAadhaarOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VendorTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: VendorTheme.primaryColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "Aadhaar OTP Verification",
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "We've sent a 6-digit verification code to your Aadhaar-linked mobile number.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // 6-box OTP input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _aadhaarOtpState == "success"
                  ? Colors.green
                  : (_aadhaarOtpState == "error" ? Colors.red : const Color(0xFF9E9E9E)),
              width: _aadhaarOtpState != "normal" ? 2.0 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ENTER 6-DIGIT OTP (Use 123456)",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _aadhaarOtpState == "success"
                      ? Colors.green
                      : (_aadhaarOtpState == "error" ? Colors.red : VendorTheme.primaryColor),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              () {
                var rowWidget = Row(
                  children: List.generate(6, (index) {
                    Color borderColor = const Color(0xFF757575);
                    double borderWidth = 1.5;
                    Color fillColor = const Color(0xFFF8F9FA);

                    if (_aadhaarOtpState == "success") {
                      borderColor = Colors.green;
                      borderWidth = 2.0;
                      fillColor = Colors.green.withValues(alpha: 0.05);
                    } else if (_aadhaarOtpState == "error") {
                      borderColor = Colors.red;
                      borderWidth = 2.0;
                      fillColor = Colors.red.withValues(alpha: 0.05);
                    }

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                        child: TextFormField(
                          controller: _aadhaarOtpControllers[index],
                          focusNode: _aadhaarOtpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: VendorTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            fillColor: fillColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor, width: borderWidth),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor, width: borderWidth),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _aadhaarOtpState == "success"
                                    ? Colors.green
                                    : (_aadhaarOtpState == "error" ? Colors.red : VendorTheme.primaryColor),
                                width: 2.5,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 5) {
                                _aadhaarOtpFocusNodes[index + 1].requestFocus();
                              } else {
                                _aadhaarOtpFocusNodes[index].unfocus();
                                final otp = _aadhaarOtpControllers.map((c) => c.text.trim()).join();
                                if (otp.length == 6) {
                                  if (otp == "123456") {
                                    setState(() {
                                      _aadhaarOtpState = "success";
                                    });
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (mounted) {
                                        setState(() {
                                          _isAadhaarVerified = true;
                                           _uploadedDocs["Aadhaar Card"] = _aadhaarController.text.isNotEmpty ? _aadhaarController.text : "aadhaar_verified.pdf";
                                          _aadhaarOtpState = "normal";
                                        });
                                        AppSnackbar.show(context, "Aadhaar Card successfully verified & auto-saved!");
                                        _nextStep();
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      _aadhaarOtpState = "error";
                                      _aadhaarErrorCount += 1;
                                    });
                                    AppSnackbar.show(context, "Incorrect OTP! Please try again.", isError: true);
                                    Future.delayed(const Duration(milliseconds: 1500), () {
                                      if (mounted) {
                                        setState(() {
                                          _aadhaarOtpState = "normal";
                                          for (var controller in _aadhaarOtpControllers) {
                                            controller.clear();
                                          }
                                        });
                                        _aadhaarOtpFocusNodes[0].requestFocus();
                                      }
                                    });
                                  }
                                }
                              }
                            } else {
                              if (index > 0) {
                                _aadhaarOtpFocusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }),
                );

                if (_aadhaarErrorCount > 0) {
                  return rowWidget.animate(key: ValueKey(_aadhaarErrorCount))
                      .shake(hz: 8, duration: 400.ms, curve: Curves.easeInOut);
                }
                return rowWidget;
              }(),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPanStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PAN Identity Verification",
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          "Please verify your Permanent Account Number (PAN) details to proceed.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 28),

        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F5A67), Color(0xFF138496)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 20,
                bottom: 20,
                child: Icon(
                  Icons.chrome_reader_mode_outlined,
                  size: 130,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "आयकर विभाग",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "INCOME TAX DEPARTMENT",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "PAN CARD",
                          style: GoogleFonts.inter(
                            color: const Color(0xFFE5A93C),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A93C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _panController.text.isEmpty ? "ABCDE1234F" : _panController.text.toUpperCase(),
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "CARDHOLDER PERMANENT ACCOUNT NUMBER",
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PERMANENT ACCOUNT NUMBER (PAN)",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _panController,
                maxLength: 10,
                onChanged: (v) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Enter 10-character PAN",
                  prefixIcon: Icon(Icons.credit_score_rounded),
                  counterText: "",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_panController.text.trim().isEmpty) {
                    _panController.text = "ABCDE1234F";
                    AppSnackbar.show(context, "Bypassed: Filled default testing PAN.");
                  } else if (_panController.text.length != 10) {
                    AppSnackbar.show(context, "PAN must be 10 characters. Auto-filled fallback.");
                    _panController.text = "ABCDE1234F";
                  }
                  _nextStep();
                },
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VendorTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: VendorTheme.primaryColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "PAN OTP Verification",
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "We've sent a 6-digit verification code to your PAN-registered mobile number/email.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // 6-box OTP input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _panOtpState == "success"
                  ? Colors.green
                  : (_panOtpState == "error" ? Colors.red : const Color(0xFF9E9E9E)),
              width: _panOtpState != "normal" ? 2.0 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ENTER 6-DIGIT OTP (Use 123456)",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _panOtpState == "success"
                      ? Colors.green
                      : (_panOtpState == "error" ? Colors.red : VendorTheme.primaryColor),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              () {
                var rowWidget = Row(
                  children: List.generate(6, (index) {
                    Color borderColor = const Color(0xFF757575);
                    double borderWidth = 1.5;
                    Color fillColor = const Color(0xFFF8F9FA);

                    if (_panOtpState == "success") {
                      borderColor = Colors.green;
                      borderWidth = 2.0;
                      fillColor = Colors.green.withValues(alpha: 0.05);
                    } else if (_panOtpState == "error") {
                      borderColor = Colors.red;
                      borderWidth = 2.0;
                      fillColor = Colors.red.withValues(alpha: 0.05);
                    }

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                        child: TextFormField(
                          controller: _panOtpControllers[index],
                          focusNode: _panOtpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: VendorTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            fillColor: fillColor,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor, width: borderWidth),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor, width: borderWidth),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _panOtpState == "success"
                                    ? Colors.green
                                    : (_panOtpState == "error" ? Colors.red : VendorTheme.primaryColor),
                                width: 2.5,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 5) {
                                _panOtpFocusNodes[index + 1].requestFocus();
                              } else {
                                _panOtpFocusNodes[index].unfocus();
                                final otp = _panOtpControllers.map((c) => c.text.trim()).join();
                                if (otp.length == 6) {
                                  if (otp == "123456") {
                                    setState(() {
                                      _panOtpState = "success";
                                    });
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (mounted) {
                                        setState(() {
                                          _isPanVerified = true;
                                           _uploadedDocs["PAN Card"] = _panController.text.isNotEmpty ? _panController.text : "pan_verified.pdf";
                                          _panOtpState = "normal";
                                        });
                                        AppSnackbar.show(context, "PAN Card successfully verified & auto-saved!");
                                        _nextStep();
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      _panOtpState = "error";
                                      _panErrorCount += 1;
                                    });
                                    AppSnackbar.show(context, "Incorrect OTP! Please try again.", isError: true);
                                    Future.delayed(const Duration(milliseconds: 1500), () {
                                      if (mounted) {
                                        setState(() {
                                          _panOtpState = "normal";
                                          for (var controller in _panOtpControllers) {
                                            controller.clear();
                                          }
                                        });
                                        _panOtpFocusNodes[0].requestFocus();
                                      }
                                    });
                                  }
                                }
                              }
                            } else {
                              if (index > 0) {
                                _panOtpFocusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }),
                );

                if (_panErrorCount > 0) {
                  return rowWidget.animate(key: ValueKey(_panErrorCount))
                      .shake(hz: 8, duration: 400.ms, curve: Curves.easeInOut);
                }
                return rowWidget;
              }(),
            ],
          ),
        ),
      ],
    );
  }


  // GST Upload Screen
  Widget _buildGstStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "GST Certificate Filing Details",
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          "Provide your GST identification details and submit your filing certificate.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 28),

        // Upper 50%: GST Themed visual block
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B1E72), Color(0xFF6236B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "GOODS & SERVICES TAX CERTIFICATE",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Icon(Icons.verified_user_rounded, color: Colors.amberAccent, size: 20),
                  ],
                ),
                Text(
                  _gstNoController.text.isEmpty ? "GSTIN: XXAAAAAAAAAXXZX" : "GSTIN: ${_gstNoController.text.toUpperCase()}",
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (_gstFileName.isEmpty || _gstFileName == "gst_cert_default.pdf") ? "No document attached" : "Attached: $_gstFileName",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: (_gstFileName.isEmpty || _gstFileName == "gst_cert_default.pdf") ? Colors.white60 : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.file_copy_rounded, color: Colors.white54, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_gstFileName.isNotEmpty && _gstFileName != "gst_cert_default.pdf") ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VendorTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, color: VendorTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _gstFileName,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.grey.shade100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: _buildGstPreview(),
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.15),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "DOCUMENT PREVIEW",
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Lower 50%: Form Controls
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GSTIN IDENTIFIER NUMBER",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gstNoController,
                maxLength: 15,
                onChanged: (v) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Enter 15-character GSTIN",
                  prefixIcon: Icon(Icons.business_rounded),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "GST CERTIFICATE UPLOAD",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _pickGstDocument,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text((_gstFileName.isEmpty || _gstFileName == "gst_cert_default.pdf") ? "Upload PDF Document" : "Change Document"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_gstNoController.text.length != 15 && _gstNoController.text.isNotEmpty) {
                    AppSnackbar.show(context, "Please enter a valid 15-character GSTIN number.", isError: true);
                    return;
                  }
                  _nextStep();
                },
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGstPreview() {
    if (_gstFileName.isEmpty) {
      return Container(
        color: Colors.grey.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              "No Document Uploaded",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    if (_isGstImage) {
      if (_gstFileUrl == null) {
        return Image.network(
          'https://images.unsplash.com/photo-1606857521015-7f9fcf423740?w=500&auto=format&fit=crop&q=60',
          fit: BoxFit.cover,
        );
      }
      if (kIsWeb) {
        return Image.network(
          _gstFileUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        );
      } else {
        return Image.file(
          File(_gstFileUrl!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        );
      }
    } else {
      return Container(
        color: Colors.red.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              "PDF Document Attached",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade900),
            )
          ],
        ),
      );
    }
  }

  // STEP 3: Location & Schedule
  Widget _buildStep3() {
    // Schedule Switch ListView
    final listWidget = ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _schedule.keys.map((day) {
        final active = _schedule[day]!["active"] as bool;
        return SwitchListTile(
          title: Text(day, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
          subtitle: Text(active ? "Hours: ${_schedule[day]!["start"]} - ${_schedule[day]!["end"]}" : "Off-duty"),
          value: active,
          activeColor: VendorTheme.primaryColor,
          onChanged: (val) => setState(() => _schedule[day]!["active"] = val),
        );
      }).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Location & Schedule",
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          "Set up your geographic coverage area and define weekly operation slots.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 32),

        // Box 1: Geographic Address Details
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "STREET / OFFICE ADDRESS",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(hintText: "102, Blue Heights, Link Road"),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CITY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(controller: _cityController, decoration: const InputDecoration(hintText: "Mumbai")),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PINCODE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                        const SizedBox(height: 8),
                        TextFormField(controller: _pincodeController, decoration: const InputDecoration(hintText: "400053")),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "TRAVELING / WORK RADIUS",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  {"val": "5km", "label": "5 km (Locality)"},
                  {"val": "10km", "label": "10 km (Standard)"},
                  {"val": "25km", "label": "25 km (Regional)"},
                  {"val": "50km", "label": "50 km (Wide)"},
                ].map((item) {
                  final isSel = _serviceRadius == item["val"];
                  return ChoiceChip(
                    label: Text(item["label"]!),
                    selected: isSel,
                    selectedColor: VendorTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: VendorTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSel ? VendorTheme.primaryColor : VendorTheme.textPrimary,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _serviceRadius = item["val"]!);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Box 2: Working Calendar Schedule
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "OPERATIONAL CALENDAR SCHEDULE",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Vacation Mode", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: const Text("Mutes bookings", style: TextStyle(fontSize: 11)),
                      value: _vacationMode,
                      activeColor: VendorTheme.primaryColor,
                      onChanged: (val) => setState(() => _vacationMode = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Busy Mode", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: const Text("Mutes alerts", style: TextStyle(fontSize: 11)),
                      value: _busyMode,
                      activeColor: VendorTheme.primaryColor,
                      onChanged: (val) => setState(() => _busyMode = val ?? false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              listWidget,
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 6: Bank Details
  void _showBankSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBanks = _supportedBanks
                .where((bank) =>
                    bank["name"]!.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: VendorTheme.borderColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Select Your Bank",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: VendorTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search bank...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: VendorTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: VendorTheme.borderColor.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: VendorTheme.primaryColor),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: filteredBanks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                "No banks found matching \"$searchQuery\"",
                                style: GoogleFonts.inter(color: VendorTheme.textSecondary),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredBanks.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final bank = filteredBanks[index];
                              final name = bank["name"]!;
                              final prefix = bank["prefix"]!;
                              final initials = name.split(" ").take(2).map((s) => s.isNotEmpty ? s[0] : "").join("");
                              
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: VendorTheme.primaryColor.withValues(alpha: 0.1),
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.inter(
                                      color: VendorTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: VendorTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  "IFSC Prefix: $prefix",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: VendorTheme.textSecondary,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  setState(() {
                                    _bankNameController.text = name;
                                    _ifscController.text = prefix;
                                  });
                                  Navigator.pop(context);
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      _ifscFocusNode.requestFocus();
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStep6() {
    if (_holderController.text.isEmpty && _ownerNameController.text.isNotEmpty) {
      _holderController.text = _ownerNameController.text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bank & Payment Details", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Text("Provide settlement coordinates for automated platform direct payments.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 32),
        Text("ACCOUNT HOLDER FULL NAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(controller: _holderController, decoration: const InputDecoration(hintText: "Amit Kumar")),
        const SizedBox(height: 20),
        Text("BANK NAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bankNameController,
          readOnly: true,
          onTap: _showBankSelectionBottomSheet,
          decoration: const InputDecoration(
            hintText: "Select Bank",
            suffixIcon: Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ACCOUNT NUMBER", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(controller: _accNoController, decoration: const InputDecoration(hintText: "50100293847")),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("IFSC BANK CODE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ifscController,
                    focusNode: _ifscFocusNode,
                    decoration: const InputDecoration(hintText: "HDFC0000047"),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text("UPI ID FOR SETTLEMENTS (OPTIONAL)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(controller: _upiController, decoration: const InputDecoration(hintText: "amitkumar@okhdfc")),
        const SizedBox(height: 40),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 7: Document Uploads
  Widget _buildStep7() {
    final listWidget = ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _uploadedDocs.keys.map((docType) {
        final bool isUploaded;
        if (docType == "Bank Account") {
          isUploaded = _bankNameController.text.isNotEmpty && _accNoController.text.isNotEmpty;
        } else {
          isUploaded = _uploadedDocs[docType]!.isNotEmpty;
        }

        final int targetStep;
        if (docType == "Aadhaar Card") {
          targetStep = 4;
        } else if (docType == "PAN Card") {
          targetStep = 6;
        } else if (docType == "GST Certificate") {
          targetStep = 8;
        } else if (docType == "Bank Account") {
          targetStep = 9;
        } else {
          targetStep = 10;
        }

        return GestureDetector(
          onTap: () => setState(() => _currentStep = targetStep),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VendorTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(docType, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        isUploaded 
                            ? (docType == "Aadhaar Card" && _aadhaarController.text.isNotEmpty 
                                ? "Aadhaar Number: ${_aadhaarController.text}"
                                : (docType == "PAN Card" && _panController.text.isNotEmpty
                                    ? "PAN Number: ${_panController.text}"
                                    : (docType == "Bank Account"
                                        ? "Bank: ${_bankNameController.text} • A/C: ${_accNoController.text}"
                                        : "Attached File: ${_uploadedDocs[docType]}")))
                            : "Upload missing",
                        style: GoogleFonts.inter(fontSize: 12, color: isUploaded ? VendorTheme.accentColor : VendorTheme.errorColor),
                      ),
                    ],
                  ),
                ),
                isUploaded
                    ? Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: VendorTheme.accentColor),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: VendorTheme.errorColor),
                            onPressed: () {
                              setState(() {
                                if (docType == "Bank Account") {
                                  _bankNameController.clear();
                                  _accNoController.clear();
                                  _ifscController.clear();
                                  _holderController.clear();
                                  _upiController.clear();
                                  _currentStep = 9; // Reset to Bank details screen
                                } else {
                                  _uploadedDocs[docType] = "";
                                  if (docType == "Aadhaar Card") {
                                    _isAadhaarVerified = false;
                                    _aadhaarController.clear();
                                    for (final c in _aadhaarOtpControllers) c.clear();
                                    _currentStep = 4; // Reset to Aadhaar screen
                                  } else if (docType == "PAN Card") {
                                    _isPanVerified = false;
                                    _panController.clear();
                                    for (final c in _panOtpControllers) c.clear();
                                    _currentStep = 6; // Reset to PAN screen
                                  } else if (docType == "GST Certificate") {
                                    _gstFileName = "";
                                    _currentStep = 8; // Reset to GST screen
                                  }
                                }
                              });
                              AppSnackbar.show(
                                context, 
                                "Verification reset: $docType deleted. Please verify again.", 
                                isError: true
                              );
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        );
      }).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Document Verification Uploads", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Text("Upload required verification credentials for official admin approval checks.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 24),
        listWidget,
        const SizedBox(height: 20),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 8: Review
  Widget _buildStep8() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: VendorTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_turned_in_rounded,
              color: VendorTheme.primaryColor,
              size: 72,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Submit Request",
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: VendorTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Your information is complete. Please accept the platform terms below to submit your registration request.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: VendorTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VendorTheme.borderColor.withValues(alpha: 0.8)),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "I accept the Platform terms of service rules",
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: VendorTheme.textPrimary),
                  ),
                  value: _acceptTerms,
                  activeColor: VendorTheme.primaryColor,
                  onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                ),
                const Divider(),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "I agree to Nexora's privacy policy and compliance terms",
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: VendorTheme.textPrimary),
                  ),
                  value: _acceptPrivacy,
                  activeColor: VendorTheme.primaryColor,
                  onChanged: (val) => setState(() => _acceptPrivacy = val ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Submit Request"),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // STEP 9: Waiting Approval
  Widget _buildStep9() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: VendorTheme.accentColor,
            size: 64,
          ),
        )
        .animate()
        .scale(duration: 800.ms, curve: Curves.elasticOut),
        const SizedBox(height: 32),
        Text(
          "Application Submitted!",
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          "Our verification team is reviewing your uploaded documents. Expected verification approval time is 24-48 hours.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              AppSnackbar.show(context, "Redirecting to chat support helpdesks...");
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text("Contact Partner Support"),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            child: const Text("Logout & Exit"),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Row(
      children: [
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              child: const Text("Back"),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _nextStep,
            child: const Text("Continue"),
          ),
        ),
      ],
    );
  }
}
