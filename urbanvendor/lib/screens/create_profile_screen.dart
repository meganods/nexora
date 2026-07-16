import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/registration_provider.dart';
import '../services/cloudinary_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  File? _profileImage;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingData());
  }

  Future<void> _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Populate RegistrationProvider
        final provider = Provider.of<RegistrationProvider>(context, listen: false);
        provider.fromMap(data);

        // Populate Controllers
        setState(() {
          _nameController.text = provider.name;
          _emailController.text = provider.email;
          _businessNameController.text = provider.businessName;
          _experienceController.text = provider.experience;
          _bioController.text = provider.businessBio;
          _phoneController.text = provider.phoneNumber;
          _passwordController.text = data['password'] ?? '';
          _confirmPasswordController.text = data['password'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
        if (!kIsWeb) _profileImage = File(pickedFile.path);
      });

      // Upload to Cloudinary
      String? uploadedUrl;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        uploadedUrl = await CloudinaryService.uploadImageBytes(
          bytes: bytes,
          fileName: pickedFile.name,
          folder: 'urban_company/vendor_profiles',
        );
      } else {
        uploadedUrl = await CloudinaryService.uploadImage(
          filePath: pickedFile.path,
          folder: 'urban_company/vendor_profiles',
        );
      }

      if (!mounted) return;

      if (uploadedUrl != null) {
        setState(() {
          _profileImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });

        // Save URL immediately to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(user.uid)
              .set({'profileImageUrl': uploadedUrl}, SetOptions(merge: true));
        }

        // Update provider so later steps carry the URL
        if (mounted) {
          final provider = Provider.of<RegistrationProvider>(context, listen: false);
          provider.profileImageUrl = uploadedUrl;
        }
      } else {
        setState(() => _isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open gallery. Restart app if this persists.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED); // Matching the button blue
    const bgColor = Color(0xFFFCFBFF);
    const inputBgColor = Color(0xFFF6F6FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Partner Registration',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                'Step 2/8',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              // 1. Form Validation
              // if (!_formKey.currentState!.validate()) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     const SnackBar(content: Text('Please correct errors in the form')),
              //   );
              //   return;
              // }

              // 2. Register/Create Account
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                User? user = FirebaseAuth.instance.currentUser;
                String uid;

                if (user == null) {
                  // Create NEW Firebase User
                  String em = _emailController.text.trim();
                  String pw = _passwordController.text.trim();
                  if (em.isEmpty) em = 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
                  if (pw.isEmpty) pw = '123456';

                  final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: em,
                    password: pw,
                  );
                  uid = userCredential.user!.uid;
                } else {
                  uid = user.uid;
                }

                // Update provider state
                if (!context.mounted) return;
                final provider = Provider.of<RegistrationProvider>(context, listen: false);
                provider.name = _nameController.text.trim();
                provider.email = _emailController.text.trim();
                provider.phoneNumber = _phoneController.text.trim();
                provider.businessName = _businessNameController.text.trim();
                provider.experience = _experienceController.text.trim();
                provider.businessBio = _bioController.text.trim();
                provider.password = _passwordController.text.trim();
                provider.currentStep = '/work_location';

                // Initial Firestore record with basic info and status
                await FirebaseFirestore.instance.collection('vendors').doc(uid).set({
                  ...provider.toMap(),
                  'password': _passwordController.text.trim(), // Storing temporarily during onboarding
                }, SetOptions(merge: true));

                if (context.mounted) {
                  Navigator.pop(context); // Close loading indicator
                  Navigator.pushNamed(context, '/work_location');
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  String msg = 'Registration failed';
                  if (e.code == 'email-already-in-use') msg = 'This email is already registered';
                  if (e.code == 'weak-password') msg = 'Password is too weak';
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Create Your Profile',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tell us a bit about yourself. This information\nwill be visible to your potential clients.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blueGrey[800],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Profile Picture Widget
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8E5FF),
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF7A8FA6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _isUploadingImage
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : _profileImageUrl != null
                              ? Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.person, color: Colors.white, size: 40),
                                )
                              : _profileImage != null && !kIsWeb
                                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                                  : null,
                    ),
                    if (!_isUploadingImage && _profileImageUrl == null && _profileImage == null)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD3D8E8),
                        ),
                        child: const Icon(Icons.person, color: primaryBlue, size: 30),
                      ),
                    Positioned(
                      bottom: 10,
                      right: 15,
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isUploadingImage ? Colors.grey[300] : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Icon(
                            _isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
                            color: primaryBlue,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Input Fields
              _buildInputField(
                label: 'BUSINESS NAME',
                icon: Icons.business,
                hint: 'Enter shop or business name',
                color: inputBgColor,
                primaryBlue: primaryBlue,
                controller: _businessNameController,
                validator: (v) => v!.isEmpty ? 'Business name required' : null,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'FULL NAME',
                icon: Icons.badge_outlined,
                hint: 'John Doe',
                color: inputBgColor,
                primaryBlue: primaryBlue,
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Full name required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildInputField(
                label: 'EMAIL ADDRESS',
                icon: Icons.alternate_email,
                hint: 'john@example.com',
                color: inputBgColor,
                primaryBlue: primaryBlue,
                controller: _emailController,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v)) return 'Please enter a valid email (missing @ or .)';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildInputField(
                label: 'YEARS OF EXPERIENCE',
                icon: Icons.work_outline,
                hint: 'e.g. 5',
                color: inputBgColor,
                primaryBlue: primaryBlue,
                controller: _experienceController,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter a digit';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PHONE NUMBER',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '*',
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Phone number is required';
                              if (v.length != 10) return 'Enter a valid 10-digit number';
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              prefixIcon: Icon(Icons.sim_card_outlined, color: Colors.grey[600], size: 20),
                              prefixIconConstraints: const BoxConstraints(minWidth: 40),
                              prefixText: '+91 ',
                              prefixStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              hintText: '1234567890',
                              hintStyle: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.normal),
                              border: InputBorder.none,
                              errorStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7F0F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'VERIFIED',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D7B91),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'An OTP will be sent to this number for verification later.',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 24),

              _buildInputField(
                label: 'BUSINESS BIO',
                icon: Icons.info_outline,
                hint: 'Tell customers more about your skills...',
                color: inputBgColor,
                primaryBlue: primaryBlue,
                controller: _bioController,
                isMultiline: true,
                validator: (v) => v!.isEmpty ? 'Please enter a bio' : null,
              ),
              const SizedBox(height: 24),

              _buildInputField(
                label: 'CREATE PASSWORD',
                icon: Icons.lock_outline,
                hint: '••••••••',
                color: inputBgColor,
                primaryBlue: primaryBlue,
                isPassword: true,
                controller: _passwordController,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Password must be at least 6 characters long';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'CONFIRM PASSWORD',
                icon: Icons.lock_reset,
                hint: '••••••••',
                color: inputBgColor,
                primaryBlue: primaryBlue,
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (v) {
                  if (v != _passwordController.text) return 'Mismatch';
                  return null;
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    required Color color,
    required Color primaryBlue,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            maxLines: isMultiline ? 3 : 1,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[400]),
              icon: Icon(icon, color: Colors.grey[600], size: 20),
              border: InputBorder.none,
              errorStyle: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              suffixIcon: isPassword 
                  ? Icon(Icons.visibility_off_outlined, color: Colors.grey[400], size: 20)
                  : null,
              suffixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
            ),
          ),
        ],
      ),
    );
  }
}
