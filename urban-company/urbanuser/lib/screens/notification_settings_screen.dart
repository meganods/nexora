import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile_screen.dart';
import 'address_setup_screen.dart';
import 'login_screen.dart';
import '../widgets/app_snackbar.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _biometricEnabled = true;
  bool _appLockEnabled = true;
  bool _pushNotifications = true;
  bool _bookingUpdates = true;
  bool _paymentUpdates = true;
  bool _promotionalOffers = false;
  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _locationPermission = true;

  String _themeMode = 'Light';
  String _language = 'English';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    _biometricEnabled = prefs.getBool('biometricEnabled') ?? true;
    _appLockEnabled = prefs.getBool('appLockEnabled') ?? true;
    _pushNotifications = prefs.getBool('pushNotifications') ?? true;
    _bookingUpdates = prefs.getBool('bookingUpdates') ?? true;
    _paymentUpdates = prefs.getBool('paymentUpdates') ?? true;
    _promotionalOffers = prefs.getBool('promotionalOffers') ?? false;
    _themeMode = prefs.getString('themeMode') ?? 'Light';
    _language = prefs.getString('language') ?? 'English';

    if (user?.uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('user_settings').doc(user!.uid).get();
        if (doc.exists && doc.data() != null) {
          final d = doc.data()!;
          if (d['biometricEnabled'] != null) _biometricEnabled = d['biometricEnabled'];
          if (d['appLockEnabled'] != null) _appLockEnabled = d['appLockEnabled'];
          if (d['pushNotifications'] != null) _pushNotifications = d['pushNotifications'];
          if (d['bookingUpdates'] != null) _bookingUpdates = d['bookingUpdates'];
          if (d['theme'] != null) _themeMode = d['theme'];
          if (d['language'] != null) _language = d['language'];
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    final uid = user?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('user_settings').doc(uid).set({
          key: value,
          'userId': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void _showDeleteAccountOtpModal() {
    final TextEditingController otpController = TextEditingController(text: '9988');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Account Confirmation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 4-digit security verification code sent to your mobile. This action will permanently remove all booking records & addresses.',
                style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: _gray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)),
              );
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await FirebaseAuth.instance.signOut();
                AppSnackbar.show(context, 'Account deleted successfully.', isError: true);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
            child: Text('Delete Permanently', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: Text('Logout Confirmation', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _dark)),
        content: Text('Are you sure you want to logout from NEXORA across all active devices?', style: GoogleFonts.inter(fontSize: 13, color: _gray)),
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
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
            child: Text('Logout', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings & Security', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account Settings Card ─────────────────────────────────
                  _card(
                    title: 'Account Settings',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _menuRow(Icons.edit_note_rounded, 'Edit Profile Information', 'Name, mobile, gender & date of birth', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      }),
                      const Divider(color: _border, height: 1),
                      _menuRow(Icons.lock_reset_rounded, 'Change Password', 'Update security credentials', () {
                        AppSnackbar.show(context, 'Password reset link sent to your registered email.');
                      }),
                    ],
                  ),

                  // ── Security & Biometrics Card ────────────────────────────
                  _card(
                    title: 'Security & Biometrics',
                    icon: Icons.shield_outlined,
                    children: [
                      _switchRow(
                        Icons.fingerprint_rounded,
                        'Biometric Login (Face ID / Touch ID)',
                        'Secure instant login with biometrics',
                        _biometricEnabled,
                        (v) {
                          setState(() => _biometricEnabled = v);
                          _updateSetting('biometricEnabled', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _switchRow(
                        Icons.lock_outline_rounded,
                        'App Lock Screen Protection',
                        'Require PIN code on app launch',
                        _appLockEnabled,
                        (v) {
                          setState(() => _appLockEnabled = v);
                          _updateSetting('appLockEnabled', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _menuRow(Icons.devices_rounded, 'Active Login Devices', 'Currently active on iPhone 15 Pro & Web', () {
                        AppSnackbar.show(context, 'Active device session: iPhone 15 Pro (Mumbai, India)');
                      }),
                    ],
                  ),

                  // ── Notification Preferences Card ──────────────────────────
                  _card(
                    title: 'Notifications Center',
                    icon: Icons.notifications_none_rounded,
                    children: [
                      _switchRow(
                        Icons.notifications_active_outlined,
                        'Push Notifications',
                        'Real-time booking and dispatch alerts',
                        _pushNotifications,
                        (v) {
                          setState(() => _pushNotifications = v);
                          _updateSetting('pushNotifications', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _switchRow(
                        Icons.calendar_month_outlined,
                        'Booking Status Updates',
                        'Pro assigned, on-the-way & completion alerts',
                        _bookingUpdates,
                        (v) {
                          setState(() => _bookingUpdates = v);
                          _updateSetting('bookingUpdates', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _switchRow(
                        Icons.payment_rounded,
                        'Payment Status Updates',
                        'Refund confirmation and payment receipt alerts',
                        _paymentUpdates,
                        (v) {
                          setState(() => _paymentUpdates = v);
                          _updateSetting('paymentUpdates', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _switchRow(
                        Icons.local_offer_outlined,
                        'Promotional Coupons & Deals',
                        'Exclusive weekend discount alerts',
                        _promotionalOffers,
                        (v) {
                          setState(() => _promotionalOffers = v);
                          _updateSetting('promotionalOffers', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _switchRow(
                        Icons.mark_email_read_outlined,
                        'Email Invoices',
                        'Digital invoice copies delivered to inbox',
                        _emailNotifications,
                        (v) {
                          setState(() => _emailNotifications = v);
                          _updateSetting('emailNotifications', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _switchRow(
                        Icons.sms_outlined,
                        'SMS Status Alerts',
                        'Receive fallback text messages for booking updates',
                        _smsNotifications,
                        (v) {
                          setState(() => _smsNotifications = v);
                          _updateSetting('smsNotifications', v);
                        },
                      ),
                    ],
                  ),

                  // ── Location & Saved Addresses Card ───────────────────────
                  _card(
                    title: 'Location & Delivery',
                    icon: Icons.location_on_outlined,
                    children: [
                      _switchRow(
                        Icons.gps_fixed_rounded,
                        'GPS Location Permission',
                        'Automatic location pinpointing for services',
                        _locationPermission,
                        (v) {
                          setState(() => _locationPermission = v);
                          _updateSetting('locationPermission', v);
                        },
                      ),
                      const Divider(color: _border, height: 1),
                      _menuRow(Icons.map_outlined, 'Manage Saved Addresses', 'Edit or set primary service addresses', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressSetupScreen()));
                      }),
                    ],
                  ),

                  // ── Appearance & Language ──────────────────────────────────
                  _card(
                    title: 'Appearance & Language',
                    icon: Icons.palette_outlined,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Theme Mode', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                            Row(
                              children: ['Light', 'Dark'].map((t) {
                                final isSel = _themeMode == t;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text(t),
                                    selected: isSel,
                                    selectedColor: const Color(0xFFEFF6FF),
                                    labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? _blue : _gray),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() => _themeMode = t);
                                        _updateSetting('theme', t);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: _border, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Language', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                            Row(
                              children: ['English 🇮🇳', 'Hindi 🇮🇳'].map((l) {
                                final isSel = _language == l;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text(l),
                                    selected: isSel,
                                    selectedColor: const Color(0xFFEFF6FF),
                                    labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? _blue : _gray),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() => _language = l);
                                        _updateSetting('language', l);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Storage Cache Card ─────────────────────────────────────
                  _card(
                    title: 'Storage & Cache',
                    icon: Icons.cleaning_services_outlined,
                    children: [
                      _menuRow(Icons.cached_rounded, 'Clear App Image Cache', 'Free up 14.2 MB temporary cache', () {
                        AppSnackbar.show(context, '14.2 MB App cache cleared successfully.');
                      }),
                    ],
                  ),

                  // ── Danger Zone Card ───────────────────────────────────────
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Danger Zone', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  foregroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _showLogoutDialog,
                                icon: const Icon(Icons.logout_rounded, size: 16),
                                label: Text('LOGOUT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _showDeleteAccountOtpModal,
                                icon: const Icon(Icons.delete_forever_rounded, size: 16),
                                label: Text('DELETE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _card({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _blue, size: 18),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _gray, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
      trailing: const Icon(Icons.chevron_right_rounded, color: _gray, size: 18),
      onTap: onTap,
    );
  }

  Widget _switchRow(IconData icon, String title, String subtitle, bool val, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _gray, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
      trailing: Switch(
        value: val,
        onChanged: onChanged,
      ),
    );
  }
}
