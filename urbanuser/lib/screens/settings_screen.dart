import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account'),
            _buildListTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => Navigator.pushNamed(context, '/edit_profile'),
            ),
            _buildListTile(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              onTap: () => Navigator.pushNamed(context, '/address_management'),
            ),
            _buildListTile(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Payment Methods')));
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Preferences'),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              value: _isDarkMode,
              onChanged: (val) => setState(() => _isDarkMode = val),
            ),
            _buildListTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: 'English',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Language Selection')));
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Security & Privacy'),
            _buildListTile(
              icon: Icons.security_outlined,
              title: 'Security',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigating to Security Settings')));
              },
            ),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Privacy Policy')));
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Support'),
            _buildListTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () => Navigator.pushNamed(context, '/help_support'),
            ),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ).animate().fadeIn(delay: 500.ms),
            ),
            const SizedBox(height: 40),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 16)),
      activeTrackColor: accentColor.withValues(alpha: 0.5),
      activeThumbColor: accentColor,
      value: value,
      onChanged: onChanged,
    );
  }
}
