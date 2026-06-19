import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Profile", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(context),
            _buildMembershipCard(),
            _buildQuickActions(context),
            _buildMenuSection("ACCOUNT SETTINGS", [
              _menuItem(Icons.location_on_outlined, "Manage Addresses", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSetupScreen()));
              }),
              _menuItem(Icons.payment_outlined, "Payment Methods", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
              }),
              _menuItem(Icons.notifications_none, "Notification Settings", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
              }),
            ]),
            _buildMenuSection("SUPPORT", [
              _menuItem(Icons.help_outline, "Help Center", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
              }),
              _menuItem(Icons.description_outlined, "Privacy Policy", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
              }),
              _menuItem(Icons.info_outline, "About Urban Company", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
              }),
            ]),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to logout?', style: GoogleFonts.outfit()),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                              }
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey[200]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text("LOGOUT", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 4),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        children: [
          CircleAvatar(radius: 35, backgroundColor: Colors.grey[100], backgroundImage: const AssetImage("assets/images/onboarding_1_handyman_illustration_1774853199914.png")),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Alex Jordan", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                const SizedBox(height: 4),
                Text("+91 888 888 8888", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor), 
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF673AB7), const Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PLUS MEMBERSHIP", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const Icon(Icons.stars, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Text("You have saved ₹4,290", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Valid till 15 Nov, 2026", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _quickActionItem(Icons.account_balance_wallet_outlined, "Wallet", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
          }),
          _quickActionItem(Icons.card_giftcard, "Rewards", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsScreen()));
          }),
          _quickActionItem(Icons.share_outlined, "Refer", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReferScreen()));
          }),
          _quickActionItem(Icons.support_agent, "Help", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
          }),
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: Icon(icon, color: AppTheme.primaryColor, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentColor)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(25, 30, 25, 15), child: Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1))),
        ...items,
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(icon, color: Colors.grey[600], size: 22),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.accentColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}
