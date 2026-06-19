import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: "Alex Jordan");
  final _emailController = TextEditingController(text: "alex@example.com");
  final _phoneController = TextEditingController(text: "+91 888 888 8888");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Edit Profile", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text("SAVE CHANGES", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isUploadingImage = false;
  String? _profileImageUrl;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        // Dynamic import logic since we copied CloudinaryService to services/
        final url = await CloudinaryService.uploadImageBytes(bytes: bytes, fileName: pickedFile.name);
        if (url != null) {
          setState(() => _profileImageUrl = url);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image updated!')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  Widget _buildProfilePic() {
    return Center(
      child: GestureDetector(
        onTap: _pickAndUploadImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50, 
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _profileImageUrl != null 
                ? NetworkImage(_profileImageUrl!) 
                : const AssetImage("assets/images/onboarding_1_handyman_illustration_1774853199914.png") as ImageProvider,
            ),
            if (_isUploadingImage)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
            ),
          ],
        ),
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
