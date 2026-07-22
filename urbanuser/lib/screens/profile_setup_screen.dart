import 'package:urbanuser/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create Your Profile", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            const SizedBox(height: 10),
            Text("Help us know you better to provide the best service experience.", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 40),
            _buildProfilePic(),
            const SizedBox(height: 40),
            _buildInputField("Full Name", "John Doe", Icons.person_outline, _nameController),
            const SizedBox(height: 20),
            _buildInputField("Email Address", "john@example.com", Icons.email_outlined, _emailController),
            const SizedBox(height: 20),
            _buildInputField("Phone Number", "+91 8888 888 888", Icons.phone_android_outlined, _phoneController),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                    try {
                      await FirebaseFirestore.instance.collection('users').add({
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'phone': _phoneController.text,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        Navigator.pushNamed(context, '/address_setup');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.show(context, 'Error saving profile: $e', isError: true);
                      }
                    }
                  } else {
                    AppSnackbar.show(context, 'Please enter name and phone number');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text("CONTINUE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePic() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(radius: 50, backgroundColor: Colors.grey[100], child: Icon(Icons.person, size: 50, color: Colors.grey[300])),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
