import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../widgets/custom_bottom_nav.dart';
import '../widgets/app_snackbar.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'address_setup_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'notification_screen.dart';
import 'privacy_policy_screen.dart';
import 'operations_desk_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Vishal Ratan";
  String _userMobile = "+91 98765 43210";
  String _userEmail = "vishal.ratan@nexora.com";
  String _userAddress = "";
  String? _userPhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    String name = prefs.getString('userName') ?? '';
    String mobile = prefs.getString('userMobile') ?? '';
    String email = prefs.getString('userEmail') ?? user?.email ?? '';
    String photoUrl = prefs.getString('userPhotoUrl') ?? user?.photoURL ?? '';
    String address = prefs.getString('userAddress') ?? '';

    if (name.isEmpty && user?.displayName != null && user!.displayName!.isNotEmpty) {
      name = user.displayName!;
    }
    if (mobile.isEmpty && user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      mobile = user.phoneNumber!;
    }

    if (email.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (name.isEmpty && data['name'] != null) name = data['name'].toString();
          if (mobile.isEmpty && data['phone'] != null) mobile = data['phone'].toString();
          if (photoUrl.isEmpty && data['photoUrl'] != null) photoUrl = data['photoUrl'].toString();
          if (address.isEmpty && data['userAddress'] != null) address = data['userAddress'].toString();
        }
      } catch (e) {
        debugPrint("Profile fetch note: $e");
      }
    }

    if (name.trim().isEmpty) name = "Vishal Ratan";
    if (mobile.trim().isEmpty) mobile = "+91 98765 43210";
    if (email.trim().isEmpty) email = "vishal.ratan@nexora.com";

    if (mounted) {
      setState(() {
        _userName = name;
        _userMobile = mobile;
        _userEmail = email;
        _userAddress = address;
        _userPhotoUrl = photoUrl.isNotEmpty ? photoUrl : null;
        _isLoading = false;
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout Confirmation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _dark)),
        content: Text('Are you sure you want to logout from NEXORA?', style: GoogleFonts.inter(fontSize: 13, color: _gray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: _gray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              }
            },
            child: Text('Logout', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTransactionsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Recent Payment Receipts', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _txnTile('TXN-849201', 'Deep Home Cleaning', '₹799.00', 'Success'),
            const Divider(color: _border),
            _txnTile('TXN-529104', 'AC Service Repair', '₹599.00', 'Success'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: GoogleFonts.inter(color: _blue))),
        ],
      ),
    );
  }

  Widget _txnTile(String id, String title, String price, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
              Text(id, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
              Text(status, style: GoogleFonts.inter(fontSize: 10, color: _green, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showInviteBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Invite Friends to Nexora", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
              const SizedBox(height: 6),
              Text("Earn ₹500 discount coupon when your friend books their first home service!",
                  textAlign: TextAlign.center, style: GoogleFonts.inter(color: _gray, fontSize: 12)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareItem(Icons.message_rounded, "WhatsApp", Colors.green, "https://nexora.app/refer/NEXORA500"),
                  _shareItem(Icons.copy_rounded, "Copy Code", _blue, "NEXORA500"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shareItem(IconData icon, String label, Color col, String textToCopy) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: textToCopy));
        Navigator.pop(context);
        AppSnackbar.show(context, "Referral code copied to clipboard!");
      },
      child: Column(
        children: [
          CircleAvatar(radius: 24, backgroundColor: col.withValues(alpha: 0.1), child: Icon(icon, color: col, size: 22)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        title: Text("User Profile & Account", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: _dark, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _border, height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),

                  // ── Account Overview Statistics Row ──────────────────────
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('userId', isEqualTo: user?.uid ?? 'guest_user')
                        .snapshots(),
                    builder: (ctx, bSnap) {
                      final docs = bSnap.data?.docs ?? [];
                      final completedCount = docs.where((d) => (d.data() as Map)['status'] == 'completed').length;
                      final upcomingCount = docs.where((d) => (d.data() as Map)['status'] != 'completed' && (d.data() as Map)['status'] != 'canceled').length;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _overviewItem('$completedCount', 'Completed', _green),
                            _vDivider(),
                            _overviewItem('$upcomingCount', 'Upcoming', _blue),
                            _vDivider(),
                            _overviewItem('1', 'Addresses', const Color(0xFFD97706)),
                          ],
                        ),
                      );
                    },
                  ),

                  // ── Comprehensive Profile Menu ─────────────────────────────
                  _wrapper(
                    title: 'Profile Menu',
                    child: Column(
                      children: [
                        _menuTile(Icons.person_outline_rounded, "Personal Information", "Edit photo, name, email & phone", () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                          _loadUserProfile();
                        }),
                        const Divider(color: _border),
                        _menuTile(Icons.location_on_outlined, "Manage Addresses", "Add or update service locations", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressSetupScreen()));
                        }),
                        const Divider(color: _border),
                        _menuTile(Icons.calendar_month_rounded, "My Bookings", "Track active & view past bookings", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
                        }),
                        const Divider(color: _border),
                        _menuTile(Icons.notifications_outlined, "Notifications", "Real-time updates & offers", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                        }),
                        const Divider(color: _border),
                        _menuTile(Icons.receipt_long_rounded, "Transactions & Receipts", "View payment receipts", _showTransactionsDialog),
                        const Divider(color: _border),
                        _menuTile(Icons.card_giftcard_rounded, "Refer & Earn", "Invite friends & earn ₹500", _showInviteBottomSheet),
                      ],
                    ),
                  ),

                  _buildSavedAddresses(),
                  _wrapper(
                    title: 'Support & Settings',
                    child: Column(
                      children: [
                        _menuTile(Icons.help_outline_rounded, "Help & Support Desk", "FAQs and 24x7 helpline", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                        }),
                        const Divider(color: _border),
                        _menuTile(Icons.policy_outlined, "Legal & Policies", "Privacy policy, Terms of use & Refunds", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                        }),
                        const Divider(color: _border),
                        _menuTile(Icons.info_outline_rounded, "About Nexora", "Platform release version 2.4.0", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                        }),
                        const Divider(color: _border),
                        _menuTile(Icons.dashboard_customize_rounded, "Operations Control Desk", "Platform launch metrics & controls", () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsDeskScreen()));
                        }),
                      ],
                    ),
                  ),

                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 4),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [_blue, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) as ImageProvider : null,
                    child: _userPhotoUrl == null
                        ? Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : "V",
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt_rounded, size: 11, color: _blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _userName,
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_userMobile, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    Text(_userEmail, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    _loadUserProfile();
                  },
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: Text("Edit Profile", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _showInviteBottomSheet,
                  icon: const Icon(Icons.share_rounded, size: 14),
                  label: Text("Invite Friends", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddresses() {
    return _wrapper(
      title: 'Primary Service Address',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _blue.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.home_rounded, color: _blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home Address', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                Text(
                  _userAddress.isNotEmpty ? _userAddress : '102, Green Meadows, Malad West, Mumbai',
                  style: GoogleFonts.inter(fontSize: 12, color: _gray),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressSetupScreen())).then((_) => _loadUserProfile());
            },
            child: Text('Edit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text("LOGOUT ACCOUNT", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _wrapper({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _blue, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
      trailing: const Icon(Icons.chevron_right_rounded, color: _gray, size: 18),
      onTap: onTap,
    );
  }

  Widget _overviewItem(String val, String label, Color col) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: col)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: _gray, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 24, color: _border);
}
