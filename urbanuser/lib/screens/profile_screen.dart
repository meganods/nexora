import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

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
        actions: [IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.grey), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(),
            _buildMembershipCard(),
            _buildQuickActions(),
            _buildMenuSection("ACCOUNT SETTINGS", [
              _menuItem(Icons.location_on_outlined, "Manage Addresses"),
              _menuItem(Icons.payment_outlined, "Payment Methods"),
              _menuItem(Icons.notifications_none, "Notification Settings"),
            ]),
            _buildMenuSection("SUPPORT", [
              _menuItem(Icons.help_outline, "Help Center"),
              _menuItem(Icons.description_outlined, "Privacy Policy"),
              _menuItem(Icons.info_outline, "About Urban Company"),
            ]),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {},
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

  Widget _buildUserHeader() {
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
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor), onPressed: () {}),
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _quickActionItem(Icons.account_balance_wallet_outlined, "Wallet"),
          _quickActionItem(Icons.card_giftcard, "Rewards"),
          _quickActionItem(Icons.share_outlined, "Refer"),
          _quickActionItem(Icons.support_agent, "Help"),
        ],
      ),
    );
  }

  Widget _quickActionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: Icon(icon, color: AppTheme.primaryColor, size: 24)),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentColor)),
      ],
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

  Widget _menuItem(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(icon, color: Colors.grey[600], size: 22),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.accentColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: () {},
    );
  }
}
