import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/app_snackbar.dart';
import 'package:flutter/services.dart';

// Import screens for navigation
import 'edit_profile_screen.dart';
import 'wallet_screen.dart';
import 'rewards_screen.dart';
import 'refer_screen.dart';
import 'help_center_screen.dart';
import 'address_setup_screen.dart';
import 'payment_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';

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

  // Setting Toggles
  bool _pushNotifications = true;
  bool _darkMode = false;
  bool _faceId = true;
  bool _fingerprint = false;
  bool _appLock = true;

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
          if (name.isEmpty && data['name'] != null && data['name'].toString().isNotEmpty) {
            name = data['name'].toString();
          }
          if (mobile.isEmpty && data['phone'] != null && data['phone'].toString().isNotEmpty) {
            mobile = data['phone'].toString();
          }
          if (photoUrl.isEmpty && data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
            photoUrl = data['photoUrl'].toString();
          }
          if (address.isEmpty && data['userAddress'] != null && data['userAddress'].toString().isNotEmpty) {
            address = data['userAddress'].toString();
          }
        }
      } catch (e) {
        debugPrint("Profile Firestore fetch note: $e");
      }
    }

    if (name.trim().isEmpty) {
      name = "Vishal Ratan"; // Use Vishal Ratan as per premium spec
    }
    if (mobile.trim().isEmpty) {
      mobile = "+91 98765 43210";
    }
    if (email.trim().isEmpty) {
      email = "vishal.ratan@nexora.com";
    }

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

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("My NEXORA QR", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text("Scan to verify profile or pay using wallet", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2_rounded, size: 160, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 20),
            Text(_userName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
            Text("Loyalty Level: Gold Member", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountOtpDialog() {
    final TextEditingController otpController = TextEditingController(text: "9988");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Confirm Account Deletion", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter the 4-digit security code sent to your mobile to delete your account. This action is irreversible.", style: TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 10),
              decoration: InputDecoration(
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.red)),
              );
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                Navigator.pop(context); // close loader
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await FirebaseAuth.instance.signOut();
                AppSnackbar.show(context, "Account Deleted Successfully", isError: true);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              }
            },
            child: const Text("Delete Permanently", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout from NEXORA?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey[500]))),
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
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInviteFriendsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Text("Invite Your Friends", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text("Earn ₹500 for every friend who books a service!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sharePlatformIcon(Icons.message_rounded, "WhatsApp", Colors.green, "https://nexora.app/refer/URBAN200"),
                  _sharePlatformIcon(Icons.facebook_rounded, "Facebook", Colors.blue, "https://nexora.app/refer/URBAN200"),
                  _sharePlatformIcon(Icons.link_rounded, "Copy Link", Colors.orange, "https://nexora.app/refer/URBAN200"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sharePlatformIcon(IconData icon, String label, Color col, String link) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: link));
        Navigator.pop(context);
        AppSnackbar.show(context, "Referral Link copied! Share on $label.");
      },
      child: Column(
        children: [
          CircleAvatar(radius: 26, backgroundColor: col.withValues(alpha: 0.1), child: Icon(icon, color: col, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 22),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        title: Text("My Profile", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserProfileCard(),
                    _buildAccountOverview(),
                    _buildQuickActionsGrid(),
                    _buildSavedAddresses(),
                    _buildHelpAndSupport(),
                    _buildLegal(),
                    _buildLogoutButton(),
                    _buildBottomPromotionalBanner(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 4),
    );
  }

  Widget _buildUserProfileCard() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) as ImageProvider : null,
                  child: _userPhotoUrl == null
                      ? Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : "V",
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _userName,
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: Color(0xFF60A5FA), size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Joined in 2026", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _profileStat("Country", "India 🇮🇳", Colors.white),
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                  _profileStat("Gender", "Male", Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                      _loadUserProfile();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: Text("Edit Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _showInviteFriendsBottomSheet,
                    icon: const Icon(Icons.share_rounded, size: 14),
                    label: Text("Share Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileStat(String label, String value, Color valCol) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: valCol)),
      ],
    );
  }

  Widget _buildAccountOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
      child: Row(
        children: [
          _overviewCard("Bookings", "24", const Color(0xFF2563EB), () => Navigator.pushNamed(context, '/my_bookings')),
          _overviewCard("Wallet", "₹1,245", const Color(0xFF7C3AED), () => Navigator.pushNamed(context, '/rewards')),
          _overviewCard("Points", "1,450", const Color(0xFF059669), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsScreen()))),
          _overviewCard("Addresses", "3", const Color(0xFFD97706), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSetupScreen()))),
        ],
      ),
    );
  }

  Widget _overviewCard(String label, String val, Color col, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: col)),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumMembershipCard() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text("NEXORA Premium", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  Text("Unlock Unlimited Benefits", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text("• Priority Booking  • Free Rescheduling  • 10% Extra Off", style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => AppSnackbar.show(context, "Premium Upgrade Initiated"),
              child: Text("Upgrade", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final List<Map<String, dynamic>> items = [
      {"label": "My Bookings", "desc": "Check booking history", "icon": Icons.calendar_today_rounded, "route": "/my_bookings"},
      {"label": "Wallet", "desc": "View transaction records", "icon": Icons.wallet_rounded, "route": "/rewards"},
      {"label": "Offers", "desc": "Coupons & deals for you", "icon": Icons.local_offer_rounded, "route": "/offers"},
      {"label": "Refer & Earn", "desc": "Invite friends & earn ₹500", "icon": Icons.group_add_rounded, "route": "/refer"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Actions", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final action = items[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, action["route"] as String),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action["icon"] as IconData, color: const Color(0xFF2563EB), size: 20),
                      const SizedBox(height: 8),
                      Text(action["label"] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
                      Text(action["desc"] as String, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Personal Information", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                child: Text("Edit", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2563EB))),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _buildInfoRow("Full Name", _userName),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow("Email Address", _userEmail),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow("Phone Number", _userMobile),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow("Gender", "Male"),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow("Date of Birth", "14th January 1996"),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow("Language", "English, Hindi"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(val, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildSavedAddresses() {
    final List<Map<String, dynamic>> addresses = [];
    if (_userAddress != null && _userAddress.isNotEmpty) {
      addresses.add({"label": "🏠 Home", "address": _userAddress, "default": true});
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Saved Addresses", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSetupScreen())),
                child: Text("+ Add New", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (addresses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Center(
                child: Text(
                  "No saved addresses yet.\nTap '+ Add New' to set up your service address.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5),
                ),
              ),
            )
          else
            ...addresses.map((addr) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(addr["label"] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                                if (addr["default"] as bool) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                    child: Text("DEFAULT", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB))),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(addr["address"] as String, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSetupScreen())),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentMethods() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Saved Payment Methods", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen())),
                child: Text("+ Add Method", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2563EB))),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _buildMethodRow(Icons.account_balance_wallet_rounded, "Google Pay", "Linked UPI"),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildMethodRow(Icons.credit_card_rounded, "Visa ending ****4589", "Expires 08/29"),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildMethodRow(Icons.credit_card_rounded, "MasterCard ending ****9987", "Expires 12/28"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodRow(IconData icon, String name, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
        const Spacer(),
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
      ],
    );
  }

  Widget _buildBookingPreferences() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Booking Preferences", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _buildPreferenceItem(Icons.access_time_rounded, "Preferred Time", "Morning (09:00 AM - 12:00 PM)"),
                const Divider(height: 20),
                _buildPreferenceItem(Icons.person_outline_rounded, "Preferred Professional", "Top-Rated, English Speaking"),
                const Divider(height: 20),
                _buildPreferenceItem(Icons.favorite_border_rounded, "Favorite Service", "AC Service & Repairs"),
                const Divider(height: 20),
                _buildPreferenceItem(Icons.contact_phone_outlined, "Emergency Contact", "+91 99999 88888"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF475569), size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardsAndCashback() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Rewards & Cashback Summary", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _buildRewardRow("NEXORA Points Balance", "1,450 Points", const Color(0xFFD97706)),
                const Divider(height: 20),
                _buildRewardRow("Wallet Cashback", "₹245 Earned", const Color(0xFF10B981)),
                const Divider(height: 20),
                _buildRewardRow("Referral Bonus", "₹500 Pending", const Color(0xFF2563EB)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF), foregroundColor: const Color(0xFF2563EB), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsScreen())),
                    child: Text("View Reward History", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(String label, String val, Color col) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(val, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: col)),
      ],
    );
  }

  Widget _buildAppSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("App Settings", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _settingToggleRow(Icons.notifications_none_rounded, "Push Notifications", "Receive real-time booking status updates", _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _settingToggleRow(Icons.dark_mode_outlined, "Dark Mode", "Sleek dark theme interface", _darkMode, (v) => setState(() => _darkMode = v)),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _settingToggleRow(Icons.fingerprint_rounded, "Biometric Login (Face ID)", "Enable Face ID validation", _faceId, (v) => setState(() => _faceId = v)),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _settingToggleRow(Icons.lock_outline_rounded, "Secure App Lock", "Enable lock screen protection", _appLock, (v) => setState(() => _appLock = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingToggleRow(IconData icon, String title, String subtitle, bool currentVal, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF64748B)),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      trailing: Switch(
        value: currentVal,
        activeColor: const Color(0xFF2563EB),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildHelpAndSupport() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Help & Support Desk", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _menuItem(Icons.help_center_outlined, "General FAQs", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()))),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _menuItem(Icons.contact_support_outlined, "Contact Support", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()))),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _menuItem(Icons.chat_bubble_outline_rounded, "Live Chat Support", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Legal & Policies", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _menuItem(Icons.info_outline_rounded, "About NEXORA", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _showLogoutDialog,
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
          label: Text("LOGOUT", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildBottomPromotionalBanner() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Invite Friends & Earn ₹500", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text("Share your custom referral link today!", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: _showInviteFriendsBottomSheet,
              child: Text("Invite Now", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF64748B), size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }
}
