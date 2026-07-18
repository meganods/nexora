import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/vendor_provider.dart';

class PartnerProfileScreen extends StatefulWidget {
  final bool isTab;
  const PartnerProfileScreen({super.key, this.isTab = false});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final vendor = vendorProvider.vendorData;
    
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        title: Padding(
          padding: EdgeInsets.only(left: widget.isTab ? 16.0 : 24.0),
          child: Text(
            'Partner Profile',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: widget.isTab ? null : SafeArea(
        child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavIcon(Icons.grid_view_rounded, 'Home', false, () {
               Navigator.pushReplacementNamed(context, '/expert_dashboard');
            }),
            _buildBottomNavIcon(Icons.layers_outlined, 'Services', false, () {
              Navigator.pushReplacementNamed(context, '/my_services');
            }),
             _buildBottomNavIcon(Icons.calendar_month_outlined, 'Bookings', false, () {
               Navigator.pushReplacementNamed(context, '/expert_dashboard', arguments: {'initialTab': 1});
             }),
            _buildBottomNavIcon(Icons.person_rounded, 'Account', true, () {}),
          ],
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF6B74F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            (vendor?['name']?.isNotEmpty == true ? vendor!['name'] : 'P').substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _editField(context, 'businessName', 'Business Name', vendor?['businessName'] ?? ''),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, color: primaryBlue, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    vendor?['businessName'] ?? 'No Business Name',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vendor?['status'] ?? 'PENDING'} Partner',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProfileBadge('4.9 ★ Rating'),
                      const SizedBox(width: 12),
                      _buildProfileBadge('${(vendor?['enabledServices'] as List?)?.length ?? 0} Services'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Personal Info Section
            Text('Owner Information', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                   _buildPersonalInfoRow(Icons.person, 'Owner Name', vendor?['name'] ?? 'Not Set', () => _editField(context, 'name', 'Owner Name', vendor?['name'] ?? '')),
                   const SizedBox(height: 20),
                   _buildPersonalInfoRow(Icons.phone, 'Support Phone', vendor?['phone'] ?? 'Not Set', () => _editField(context, 'phone', 'Support Phone', vendor?['phone'] ?? '')),
                   const SizedBox(height: 20),
                   _buildPersonalInfoRow(Icons.email, 'Contact Email', vendor?['email'] ?? 'Not Set', null),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Store Settings Section
            Text('Store Management', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FDFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE6FFFA)),
              ),
              child: Column(
                children: [
                   _buildPersonalInfoRow(Icons.currency_rupee, 'Base Hourly Rate', '₹${vendor?['baseRate'] ?? '0'}', () => _editField(context, 'baseRate', 'Base Hourly Rate', vendor?['baseRate']?.toString() ?? '45', isNumber: true)),
                   const SizedBox(height: 20),
                   _buildPersonalInfoRow(Icons.location_on, 'Store City', vendor?['city'] ?? 'Not Set', () => _editField(context, 'city', 'City', vendor?['city'] ?? '')),
                   const SizedBox(height: 20),
                   _buildPersonalInfoRow(Icons.map, 'Operational Address', vendor?['address'] ?? 'Not Set', () => _editField(context, 'address', 'Address', vendor?['address'] ?? '')),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Document Center
            Text('Security & Verification', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            _buildDocumentCard('Account Status', 'Your account is currently ${vendor?['status'] ?? 'UNDER REVIEW'}', Icons.verified_user_outlined, vendor?['status'] == 'APPROVED'),
            const SizedBox(height: 16),
            _buildDocumentCard('Bank Details', 'Verified for payouts', Icons.account_balance_outlined, true),
            
            const SizedBox(height: 30),
            
            // Account Settings
            Text('Account Settings', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildSettingRow(Icons.lock_outline, 'Change Password', primaryBlue, () => _showChangePasswordDialog(context)),
                  const Divider(height: 1, indent: 60),
                  _buildSettingRow(Icons.logout_rounded, 'Logout', const Color(0xFFC53030), () => _showLogoutDialog(context)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length >= 6) {
                try {
                  await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _editField(BuildContext context, String key, String label, String currentValue, {bool isNumber = false}) {
    final isPhone = key == 'phone';
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: (isNumber || isPhone) ? TextInputType.number : TextInputType.text,
          inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : null,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            prefixText: isPhone ? '+91 ' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                dynamic value = controller.text.trim();
                if (isNumber) {
                  value = double.tryParse(value) ?? value;
                }
                await Provider.of<VendorProvider>(context, listen: false).updateVendorProfile({key: value});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  Widget _buildPersonalInfoRow(IconData icon, String label, String value, VoidCallback? onEdit) {
    const pBlue = Color(0xFF4A55ED);
    return Row(
      children: [
        Icon(icon, color: pBlue, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            onPressed: onEdit,
          ),
      ],
    );
  }

  Widget _buildDocumentCard(String title, String subtitle, IconData icon, bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFE2F6F9), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF0C6B8B), size: 20),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE6FFFA), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: Color(0xFF2C7A7B)),
                      const SizedBox(width: 4),
                      Text('VERIFIED', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF2C7A7B))),
                    ],
                  ),
                )
              else
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 12, color: Color(0xFFD69E2E)),
                      const SizedBox(width: 4),
                      Text('REVIEWING', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFFD69E2E))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: iconColor.withValues(alpha: 0.7), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            Icon(Icons.chevron_right, color: iconColor == const Color(0xFFC53030) ? iconColor : Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, bool isActive, VoidCallback onTap) {
    const bBlue = Color(0xFF4A55ED);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? bBlue : Colors.blueGrey[400], size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isActive ? bBlue : Colors.blueGrey[400],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
