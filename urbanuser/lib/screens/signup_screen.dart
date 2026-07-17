import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;

  String? _nameError;
  String? _emailError;
  String? _mobileError;
  String? _passwordError;
  String? _confirmError;

  void _signup() async {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? "Full Name is required" : null;
      _emailError = _emailController.text.trim().isEmpty ? "Email is required" : null;
      _mobileError = _mobileController.text.trim().isEmpty ? "Phone Number is required" : null;
      _passwordError = _passwordController.text.trim().isEmpty ? "Password is required" : null;
      _confirmError = _confirmController.text.trim().isEmpty ? "Confirm Password is required" : null;
    });

    if (_nameError != null ||
        _emailError != null ||
        _mobileError != null ||
        _passwordError != null ||
        _confirmError != null) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _confirmError = "Passwords do not match";
      });
      return;
    }
    
    String fullMobile = _mobileController.text.trim();
    if (fullMobile.isNotEmpty && !fullMobile.startsWith('+91')) {
      if (fullMobile.startsWith('0')) {
        fullMobile = fullMobile.substring(1);
      }
      fullMobile = '+91$fullMobile';
    }
    
    // Save details to Firestore
    final emailLower = _emailController.text.trim().toLowerCase();
    try {
      await FirebaseFirestore.instance.collection('users').doc(emailLower).set({
        'name': _nameController.text.trim(),
        'phone': fullMobile,
        'email': emailLower,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error writing user to Firestore on signup: $e");
    }

    // Save details to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());
    await prefs.setString('userMobile', fullMobile);
    await prefs.setString('userEmail', emailLower);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account Created Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back to login
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0A59C8);
    const darkSlate = Color(0xFF0C1A30);
    const textGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);
    const bgLight = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Top Toolbox Icon
              const Icon(
                Icons.business_center_rounded,
                color: primaryBlue,
                size: 54,
              ),
              const SizedBox(height: 12),
              
              // NEXORA Brand title
              Text(
                "NEXORA",
                style: GoogleFonts.outfit(
                  color: primaryBlue,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                "Create your account",
                style: GoogleFonts.outfit(
                  color: darkSlate,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Form Card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name Field
                    _buildFieldLabel("Full Name"),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nameController,
                      hint: "John Doe",
                      prefixIcon: Icons.person_outline_rounded,
                      errorText: _nameError,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Number Field
                    _buildFieldLabel("Phone Number"),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _mobileController,
                      hint: "+1 (555) 000-0000",
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      errorText: _mobileError,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Field
                    _buildFieldLabel("Email"),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _emailController,
                      hint: "john@example.com",
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    _buildFieldLabel("Password"),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _passwordController,
                      hint: "••••••••",
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: textGrey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Re-enter Password Field
                    _buildFieldLabel("Re-enter Password"),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _confirmController,
                      hint: "••••••••",
                      prefixIcon: Icons.refresh_rounded,
                      obscureText: _obscureConfirm,
                      errorText: _confirmError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: textGrey,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Terms and Conditions checkbox row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (val) => setState(() => _agreeToTerms = val!),
                            activeColor: primaryBlue,
                            side: const BorderSide(color: borderGrey, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: "By signing up, you agree to our ",
                              style: GoogleFonts.outfit(color: darkSlate, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: "Terms of Service",
                                  style: GoogleFonts.outfit(color: primaryBlue, fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: GoogleFonts.outfit(color: primaryBlue, fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: "."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Join NEXORA button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Join NEXORA ",
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Already have an account row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.outfit(color: textGrey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Log in",
                      style: GoogleFonts.outfit(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: const Color(0xFF0C1A30),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    const borderGrey = Color(0xFFE2E8F0);
    const primaryBlue = Color(0xFF0A59C8);
    const bgLight = Color(0xFFF8FAFC);
    const darkSlate = Color(0xFF0C1A30);
    const textGrey = Color(0xFF64748B);

    bool isPhone = keyboardType == TextInputType.phone;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: darkSlate),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: textGrey.withValues(alpha: 0.6)),
        errorText: errorText,
        prefixIcon: isPhone
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🇮🇳", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      "+91",
                      style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 18,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              )
            : Icon(prefixIcon, color: textGrey, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
