import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController(text: '14 Jan 1996');

  String _gender = 'Male';
  String _photoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    String name = prefs.getString('userName') ?? user?.displayName ?? 'Vishal Ratan';
    String phone = prefs.getString('userMobile') ?? user?.phoneNumber ?? '+91 98765 43210';
    String email = prefs.getString('userEmail') ?? user?.email ?? 'vishal.ratan@nexora.com';
    String photo = prefs.getString('userPhotoUrl') ?? user?.photoURL ?? _photoUrl;

    if (email.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
        if (doc.exists && doc.data() != null) {
          final d = doc.data()!;
          if (d['name'] != null && d['name'].toString().isNotEmpty) name = d['name'].toString();
          if (d['phone'] != null && d['phone'].toString().isNotEmpty) phone = d['phone'].toString();
          if (d['gender'] != null) _gender = d['gender'].toString();
          if (d['dob'] != null) _dobController.text = d['dob'].toString();
          if (d['photoUrl'] != null && d['photoUrl'].toString().isNotEmpty) photo = d['photoUrl'].toString();
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _nameController.text = name;
        _phoneController.text = phone;
        _emailController.text = email;
        _photoUrl = photo.isNotEmpty ? photo : _photoUrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (user?.email ?? 'vishal.ratan@nexora.com');

    final updatedData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': email,
      'gender': _gender,
      'dob': _dobController.text.trim(),
      'photoUrl': _photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(email).set(updatedData, SetOptions(merge: true));

      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('userMobile', _phoneController.text.trim());
      await prefs.setString('userEmail', email);
      await prefs.setString('userPhotoUrl', _photoUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Profile updated successfully!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAvatarPicker() {
    final avatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Profile Photo Avatar',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: avatars.map((url) {
                final isSelected = _photoUrl == url;
                return GestureDetector(
                  onTap: () {
                    setState(() => _photoUrl = url);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? _blue : Colors.transparent, width: 3),
                    ),
                    child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(url)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Personal Information',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                  child: Column(
                    children: [
                      // ── Profile Photo Avatar ──────────────────────────────
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _blue, width: 3),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                              ),
                              child: ClipOval(
                                child: Image.network(_photoUrl, fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showAvatarPicker,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Input Fields ──────────────────────────────────────
                      _card(
                        title: 'Basic Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Full Name'),
                            _inputField(_nameController, 'Enter your full name', Icons.person_outline_rounded),
                            const SizedBox(height: 14),

                            _label('Email Address (Verified)'),
                            _inputField(_emailController, 'Enter email address', Icons.email_outlined, isReadOnly: true),
                            const SizedBox(height: 14),

                            _label('Phone Number'),
                            _inputField(_phoneController, 'Enter mobile number', Icons.phone_outlined, isPhone: true),
                          ],
                        ),
                      ),

                      _card(
                        title: 'Personal Attributes',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Gender'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _gender,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _gray),
                                  items: ['Male', 'Female', 'Other'].map((g) {
                                    return DropdownMenuItem(
                                      value: g,
                                      child: Text(g, style: GoogleFonts.inter(fontSize: 13, color: _dark, fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _gender = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            _label('Date of Birth'),
                            _inputField(_dobController, 'DD/MM/YYYY', Icons.cake_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Sticky Save Button ────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border.all(color: _border),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfileChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text('Save Changes', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData icon,
      {bool isReadOnly = false, bool isPhone = false}) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 13, color: _dark, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: _gray),
        suffixIcon: isReadOnly
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                child: Text('VERIFIED', style: GoogleFonts.inter(fontSize: 8, color: _green, fontWeight: FontWeight.bold)),
              )
            : null,
        fillColor: isReadOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue)),
      ),
    );
  }
}
