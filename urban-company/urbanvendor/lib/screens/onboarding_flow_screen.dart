import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  int _currentStep = 1;
  final int _totalSteps = 9;

  // Step 1: Business Info
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  String _businessType = "Individual";
  String _experience = "2 Years";
  String _languages = "English, Hindi";
  final _descriptionController = TextEditingController();
  final _gstController = TextEditingController();

  // Step 2: Category
  String _selectedCategory = "Home Cleaning";
  final List<String> _subCategories = ["Deep Cleaning", "Kitchen Spa", "Sofa Cleaning"];
  final List<String> _selectedSubCategories = ["Deep Cleaning"];

  // Step 3: Services List
  final List<Map<String, dynamic>> _customServices = [
    {
      "name": "Standard Deep Cleaning",
      "desc": "Full scrubbing, dusting, vacuuming of all rooms.",
      "price": "1499",
      "duration": "120 Min",
    }
  ];
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

  // Step 6: Bank
  final _holderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  // Step 7: Documents (file path place holders)
  final Map<String, String> _uploadedDocs = {
    "Aadhaar Card": "aadhaar_verified.pdf",
    "PAN Card": "pan_verified.pdf",
    "Trade License": "license_pending.pdf",
    "GST Certificate": "",
    "Profile Photo": "profile_image.jpg",
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

  void _nextStep() {
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

    try {
      await FirebaseFirestore.instance.collection('vendors').doc(email).set({
        "ownerName": _ownerNameController.text.trim(),
        "businessName": _businessNameController.text.trim(),
        "businessType": _businessType,
        "experience": _experience,
        "languages": _languages,
        "description": _descriptionController.text.trim(),
        "gst": _gstController.text.trim(),
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
        "documents": _uploadedDocs,
        "status": "pending",
        "submittedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _currentStep = 9; // Route to Waiting Screen
        });
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
        leading: _currentStep > 1 && _currentStep < 9
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
                onPressed: _prevStep,
              )
            : null,
        title: Text(
          _currentStep == 9 ? "Application Status" : "Onboarding Stage $_currentStep of 8",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary),
        ),
        actions: [
          if (_currentStep < 9)
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
                    itemCount: 8,
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
              child: Padding(
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
        if (_currentStep < 9)
          LinearProgressIndicator(
            value: _currentStep / 8,
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
        return "Category Selection";
      case 3:
        return "Service Management";
      case 4:
        return "Address & Service Area";
      case 5:
        return "Working Schedule";
      case 6:
        return "Bank Details";
      case 7:
        return "Documents Upload";
      case 8:
        return "Review Details";
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
        return _buildStep4();
      case 5:
        return _buildStep5();
      case 6:
        return _buildStep6();
      case 7:
        return _buildStep7();
      case 8:
        return _buildStep8();
      case 9:
        return _buildStep9();
      default:
        return Container();
    }
  }

  // STEP 1: Business Info
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Business Information", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Text("Provide basic administrative and branding information regarding your business.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 32),
        Text("BUSINESS DISPLAY NAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessNameController,
          decoration: const InputDecoration(hintText: "Apex Appliance Care"),
        ),
        const SizedBox(height: 20),
        Text("OWNER FULL NAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ownerNameController,
          decoration: const InputDecoration(hintText: "Amit Kumar"),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("EXPERIENCE LEVEL", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["1 Year", "2 Years", "5+ Years"].map((exp) {
                      final isSel = _experience == exp;
                      return ChoiceChip(
                        label: Text(exp),
                        selected: isSel,
                        selectedColor: VendorTheme.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: VendorTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSel ? VendorTheme.primaryColor : VendorTheme.textPrimary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _experience = exp);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("GST IDENTIFIER (OPTIONAL)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _gstController,
                    decoration: const InputDecoration(hintText: "22AAAAA1111A1Z1"),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text("SHORT PROFILE DESCRIPTION", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Apex Appliance Care provides instant repairs and maintenance services for washing machines, ACs, and refrigerators..."),
        ),
        const SizedBox(height: 40),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 2: Category
  Widget _buildStep2() {
    final categories = ["Home Cleaning", "Appliance Repair", "Electrician", "Plumber", "Salon & Spa"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Category Selection", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Text("Choose the primary business sector you are licensed to provide on the Nexora platform.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 32),
        Text("PRIMARY SERVICE CATEGORY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? VendorTheme.primaryColor : Colors.white,
                  border: Border.all(color: isSelected ? VendorTheme.primaryColor : VendorTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 40),
        _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildStep3() {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;
    final listWidget = _customServices.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cleaning_services_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("No services listed yet.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
              ],
            ),
          )
        : ListView.builder(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? null : const NeverScrollableScrollPhysics(),
            itemCount: _customServices.length,
            itemBuilder: (context, index) {
              final item = _customServices[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.white,
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
                      const SizedBox(width: 16),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Service Management", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
            ElevatedButton.icon(
              onPressed: _showAddServiceDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("New Service"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text("Build your active service pricing menu. Add options with custom flat fees or discounts.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 24),
        isDesktop ? Expanded(child: listWidget) : listWidget,
        const SizedBox(height: 20),
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

  // STEP 4: Address & Radius
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location & Service Radius", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Text("Provide your registration office address and select the traveling geofence radius.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 32),
        Text("STREET / OFFICE ADDRESS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
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
        Text("TRAVELING / WORK RADIUS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
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
        const SizedBox(height: 40),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 5: Schedule
  Widget _buildStep5() {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;
    final listWidget = ListView(
      shrinkWrap: !isDesktop,
      physics: isDesktop ? null : const NeverScrollableScrollPhysics(),
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
        Text("Working Schedule", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Text("Select operational calendar days and default active slots for client appointments.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: Text("Vacation Mode Active", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                subtitle: const Text("Mutes incoming slots immediately"),
                value: _vacationMode,
                activeColor: VendorTheme.primaryColor,
                onChanged: (val) => setState(() => _vacationMode = val ?? false),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: Text("Busy Mode Active", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                subtitle: const Text("Silences alerts temporarily"),
                value: _busyMode,
                activeColor: VendorTheme.primaryColor,
                onChanged: (val) => setState(() => _busyMode = val ?? false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        isDesktop ? Expanded(child: listWidget) : listWidget,
        const SizedBox(height: 20),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 6: Bank Details
  Widget _buildStep6() {
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
        TextFormField(controller: _bankNameController, decoration: const InputDecoration(hintText: "HDFC Bank Ltd")),
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
                  TextFormField(controller: _ifscController, decoration: const InputDecoration(hintText: "HDFC0000047")),
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
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;
    final listWidget = ListView(
      shrinkWrap: !isDesktop,
      physics: isDesktop ? null : const NeverScrollableScrollPhysics(),
      children: _uploadedDocs.keys.map((docType) {
        final isUploaded = _uploadedDocs[docType]!.isNotEmpty;
        return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(docType, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    isUploaded ? "Uploaded: ${_uploadedDocs[docType]}" : "Upload missing",
                    style: GoogleFonts.inter(fontSize: 12, color: isUploaded ? VendorTheme.accentColor : VendorTheme.errorColor),
                  ),
                ],
              ),
              isUploaded
                  ? Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: VendorTheme.accentColor),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: VendorTheme.errorColor),
                          onPressed: () => setState(() => _uploadedDocs[docType] = ""),
                        ),
                      ],
                    )
                  : TextButton.icon(
                      onPressed: () => setState(() => _uploadedDocs[docType] = "${docType.toLowerCase().replaceAll(' ', '_')}_attached.pdf"),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text("Upload"),
                    ),
            ],
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
        isDesktop ? Expanded(child: listWidget) : listWidget,
        const SizedBox(height: 20),
        _buildBottomActionBar(),
      ],
    );
  }

  // STEP 8: Review
  Widget _buildStep8() {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;
    final listWidget = ListView(
      shrinkWrap: !isDesktop,
      physics: isDesktop ? null : const NeverScrollableScrollPhysics(),
      children: [
        ListTile(
          title: const Text("Owner & Business Name"),
          subtitle: Text("${_ownerNameController.text} • ${_businessNameController.text}"),
          leading: const Icon(Icons.person_outline_rounded),
        ),
        ListTile(
          title: const Text("Sector Category"),
          subtitle: Text(_selectedCategory),
          leading: const Icon(Icons.category_outlined),
        ),
        ListTile(
          title: const Text("Active Pricing Options"),
          subtitle: Text("${_customServices.length} options defined in menu catalog"),
          leading: const Icon(Icons.menu_book_rounded),
        ),
        ListTile(
          title: const Text("Base Office Coordinates"),
          subtitle: Text("${_addressController.text}, ${_cityController.text} (Radius: $_serviceRadius)"),
          leading: const Icon(Icons.map_outlined),
        ),
        ListTile(
          title: const Text("Settlement Bank Account"),
          subtitle: Text("${_holderController.text} • ${_bankNameController.text} (${_accNoController.text})"),
          leading: const Icon(Icons.account_balance_outlined),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Review Application Detail Summary", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary)),
        const SizedBox(height: 8),
        Text("Review all verification fields details before submitting to Firestore checks.", style: GoogleFonts.inter(color: VendorTheme.textSecondary)),
        const SizedBox(height: 24),
        isDesktop ? Expanded(child: listWidget) : listWidget,
        const Divider(),
        CheckboxListTile(
          title: Text("I accept the Platform terms of service rules", style: GoogleFonts.inter(fontSize: 12)),
          value: _acceptTerms,
          activeColor: VendorTheme.primaryColor,
          onChanged: (val) => setState(() => _acceptTerms = val ?? false),
        ),
        CheckboxListTile(
          title: Text("I agree to Nexora's privacy policy and data compliance terms", style: GoogleFonts.inter(fontSize: 12)),
          value: _acceptPrivacy,
          activeColor: VendorTheme.primaryColor,
          onChanged: (val) => setState(() => _acceptPrivacy = val ?? false),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitApplication,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Submit Registration Application"),
          ),
        ),
      ],
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
