import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class StoreSettingsPage extends StatelessWidget {
  const StoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text("Store Settings", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStoreProfile(),
            _buildSettingsSection("ACCOUNT", [
              _settingsItem(Icons.store_outlined, "Shop Identity"),
              _settingsItem(Icons.location_on_outlined, "Location & Area"),
              _settingsItem(Icons.lock_outline, "Account Security"),
            ]),
            _buildSettingsSection("PREFERENCES", [
              _settingsItem(Icons.notifications_none, "Notification Settings"),
              _settingsItem(Icons.language_outlined, "App Language"),
            ]),
            _buildSettingsSection("INFO & HELP", [
              _settingsItem(Icons.help_outline, "Help & Support"),
              _settingsItem(Icons.description_outlined, "Privacy & Policy"),
            ]),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red[100]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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

  Widget _buildStoreProfile() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        children: [
          CircleAvatar(radius: 35, backgroundColor: Colors.grey[100], child: Icon(Icons.store, color: AppTheme.primaryColor, size: 30)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("City Cleaners", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                const SizedBox(height: 4),
                Text("+91 888 888 8888", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(25, 30, 25, 15), child: Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2))),
        ...items,
      ],
    );
  }

  Widget _settingsItem(IconData icon, String label) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(icon, color: Colors.grey[600], size: 22),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.accentColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: () {},
    );
  }
}
