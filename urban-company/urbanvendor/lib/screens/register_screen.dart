import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vendor_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedBusinessType = "Individual";
  String _selectedGender = "Male";
  bool _acceptTerms = true; // Auto-accept for developer ease
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();

  void _handleRegister() {
    setState(() => _isSubmitting = true);

    final String name = _ownerNameController.text.trim();
    final String email = _emailController.text.trim().toLowerCase();
    final String phoneNum = _phoneController.text.trim();

    final businessData = {
      "businessName": _businessNameController.text.trim().isNotEmpty ? _businessNameController.text.trim() : "N/A",
      "ownerName": name.isNotEmpty ? name : "Test Partner",
      "email": email.isNotEmpty ? email : "testpartner@example.com",
      "phone": phoneNum.isNotEmpty ? "+91$phoneNum" : "+919876543210",
      "password": _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : "123456",
      "businessType": _selectedBusinessType,
      "gender": _selectedGender,
    };

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pushNamed(
          context, 
          '/otp',
          arguments: businessData,
        );
      }
    });
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
                  "Become a Nexora\nCertified Partner Today",
                  style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary, height: 1.2),
                )
                .animate()
                .fadeIn(duration: 700.ms)
                .slideY(begin: 0.1),
                const SizedBox(height: 16),
                Text(
                  "Reach thousand of customers, set your baseline hourly rates, and secure weekly direct payouts.",
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
                constraints: const BoxConstraints(maxWidth: 440),
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
            "Create Partner Account",
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "Register to get started on your onboarding steps.",
            style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary),
          ),
          const SizedBox(height: 36),

          // Business Type Dropdown
          Text(
            "BUSINESS ENTITY TYPE",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("Individual")),
                  selected: _selectedBusinessType == "Individual",
                  selectedColor: VendorTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: VendorTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: _selectedBusinessType == "Individual" ? VendorTheme.primaryColor : VendorTheme.textPrimary,
                    fontWeight: _selectedBusinessType == "Individual" ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedBusinessType = "Individual");
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("Agency / Company")),
                  selected: _selectedBusinessType == "Agency",
                  selectedColor: VendorTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: VendorTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: _selectedBusinessType == "Agency" ? VendorTheme.primaryColor : VendorTheme.textPrimary,
                    fontWeight: _selectedBusinessType == "Agency" ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedBusinessType = "Agency");
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gender Selection Dropdown
          Text(
            "GENDER",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.people_outline_rounded, color: VendorTheme.textSecondary),
            ),
            dropdownColor: Colors.white,
            items: ["Male", "Female", "Other"]
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedGender = val);
              }
            },
          ),
          const SizedBox(height: 20),

          // Business Name
          Text(
            "BUSINESS / AGENCY DISPLAY NAME",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _businessNameController,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "e.g. Apex Appliance Repairs (Optional)",
              prefixIcon: Icon(Icons.storefront_rounded, color: VendorTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Owner Name
          Text(
            "FULL NAME (OWNER)",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ownerNameController,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "e.g. Amit Kumar (Optional)",
              prefixIcon: Icon(Icons.person_outline_rounded, color: VendorTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Email
          Text(
            "EMAIL ADDRESS",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "name@company.com (Optional)",
              prefixIcon: Icon(Icons.email_outlined, color: VendorTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Phone
          Text(
            "PHONE NUMBER",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: VendorTheme.surfaceColor,
                  border: Border.all(color: VendorTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('🇮🇳', style: GoogleFonts.inter(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('+91', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.inter(color: VendorTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: "98765 43210 (Optional)",
                    counterText: "",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Password
          Text(
            "PASSWORD",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "•••••••• (Optional)",
              prefixIcon: Icon(Icons.lock_outline_rounded, color: VendorTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Password
          Text(
            "CONFIRM PASSWORD",
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: GoogleFonts.inter(color: VendorTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "•••••••• (Optional)",
              prefixIcon: Icon(Icons.lock_reset_rounded, color: VendorTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Terms Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                  activeColor: VendorTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "I accept Nexora's Terms of Business Service and Privacy Policy.",
                  style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleRegister,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Continue to Verification"),
            ),
          ),
          const SizedBox(height: 24),

          // Navigation Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already registered? ",
                style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: Text(
                  "Log In",
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: VendorTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
