import 'package:urbanadmin/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _darkMode = false;
  final String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildSettingsContent(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portal Settings',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          'Configure global preferences and account security.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.blueGrey[400]),
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        children: [
          _buildAccountSection(),
          const SizedBox(height: 24),
          _buildNotificationSection(),
          const SizedBox(height: 24),
          _buildPreferencesSection(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildCard(
      title: 'Account Security',
      icon: Icons.shield_rounded,
      children: [
        _buildSettingItem(
          title: 'Admin Email',
          subtitle: 'admin@admin.co',
          trailing: const Icon(Icons.edit_rounded, size: 20),
          onTap: () {},
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        _buildSettingItem(
          title: 'Password',
          subtitle: 'Last changed 3 months ago',
          trailing: Text(
            'Change',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () => _showChangePasswordDialog(),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        _buildSettingItem(
          title: 'Two-Factor Authentication',
          subtitle: 'Enhance your portal security',
          trailing: Switch(
            value: true,
            activeThumbColor: const Color(0xFF6366F1),
            onChanged: (val) {},
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return _buildCard(
      title: 'Global Notifications',
      icon: Icons.notifications_rounded,
      children: [
        _buildSettingItem(
          title: 'Email Alerts',
          subtitle: 'Receive daily system reports',
          trailing: Switch(
            value: _emailNotifications,
            activeThumbColor: const Color(0xFF6366F1),
            onChanged: (val) => setState(() => _emailNotifications = val),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        _buildSettingItem(
          title: 'SMS Alerts',
          subtitle: 'Critical system failures only',
          trailing: Switch(
            value: _smsNotifications,
            activeThumbColor: const Color(0xFF6366F1),
            onChanged: (val) => setState(() => _smsNotifications = val),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildCard(
      title: 'System Preferences',
      icon: Icons.settings_rounded,
      children: [
        _buildSettingItem(
          title: 'Dark Mode',
          subtitle: 'Experimental feature',
          trailing: Switch(
            value: _darkMode,
            activeThumbColor: const Color(0xFF6366F1),
            onChanged: (val) => setState(() => _darkMode = val),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        _buildSettingItem(
          title: 'Portal Language',
          subtitle: _selectedLanguage,
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6366F1), size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueGrey[400]),
      ),
      trailing: trailing,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Text(
            'Reset to Defaults',
            style: GoogleFonts.poppins(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            AppSnackbar.show(context, 'Settings saved successfully!');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Save Changes',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Current Password',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm New Password',
                hintStyle: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: Text(
              'Update',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
