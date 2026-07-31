import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class BusinessSettingsScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;
  const BusinessSettingsScreen({super.key, this.isTab = false, this.onBack});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Active Category Index (12 sub-sections)
  // 0: Profile, 1: Business Info, 2: Schedule Planner, 3: Document Locker,
  // 4: Security, 5: Notification Prefs, 6: Payment Settings, 7: Privacy,
  // 8: Language & Region, 9: Appearance, 10: Support center, 11: About
  int _activeCategoryIndex = 0;

  // Profile Form Controllers
  final _businessNameCtrl = TextEditingController(text: "Patel Services");
  final _ownerNameCtrl = TextEditingController(text: "Vishal Patel");
  final _phoneCtrl = TextEditingController(text: "9876543210");
  final _bioCtrl = TextEditingController(text: "Professional AC repair and maintenance vendor.");
  
  // Business Info Form
  final _gstCtrl = TextEditingController(text: "27AAAAA1111A1Z1");
  final _panCtrl = TextEditingController(text: "ABCDE1234F");
  double _workingRadius = 15.0;

  // Working Schedule State
  bool _isVacationMode = false;
  final Map<String, bool> _workingDays = {
    "Monday": true,
    "Tuesday": true,
    "Wednesday": true,
    "Thursday": true,
    "Friday": true,
    "Saturday": true,
    "Sunday": false,
  };

  // Document Locker State
  final Map<String, Map<String, dynamic>> _documents = {
    "Aadhaar": {"status": "Verified", "fileName": "aadhaar_front.pdf"},
    "PAN Card": {"status": "Verified", "fileName": "pan_card.jpg"},
    "GST License": {"status": "Pending Verification", "fileName": "gst_cert.pdf"},
    "Trade License": {"status": "Not Uploaded", "fileName": null},
  };

  // Security State
  bool _biometricLogin = false;
  bool _twoFactorAuth = true;
  final List<String> _activeDevices = [
    "Chrome Web (Mumbai, India) - Active Now",
    "OnePlus 11 (Pune, India)",
    "iPad Pro (Mumbai, India)"
  ];

  // Notification preferences
  bool _pushBookings = true;
  bool _pushPayments = true;
  bool _smsAlerts = false;
  bool _emailPromos = false;

  // Appearance
  String _themeMode = "System Mode";

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: isDesktop ? null : _buildMobileAppBar(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    final titles = [
      "Vendor Profile",
      "Business Information",
      "Working Schedule",
      "Document Locker",
      "Security Configurations",
      "Notifications Preferences",
      "Payment Settings",
      "Privacy Options",
      "Language & Region",
      "Appearance Configuration",
      "Help & Policies",
      "About Nexora",
    ];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
        onPressed: () {
          if (_activeCategoryIndex > 0) {
            setState(() => _activeCategoryIndex = 0);
          } else if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      title: Text(
        titles[_activeCategoryIndex],
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: VendorTheme.textPrimary),
      ),
    );
  }

  Widget _buildMobileLayout() {
    Widget body;
    switch (_activeCategoryIndex) {
      case 1:
        body = _buildBusinessInfoView();
        break;
      case 2:
        body = _buildSchedulePlannerView();
        break;
      case 3:
        body = _buildDocumentLockerView();
        break;
      case 4:
        body = _buildSecurityView();
        break;
      case 5:
        body = _buildNotificationsView();
        break;
      case 6:
        body = _buildPaymentSettingsView();
        break;
      case 7:
        body = _buildPrivacyView();
        break;
      case 8:
        body = _buildLanguageRegionView();
        break;
      case 9:
        body = _buildAppearanceView();
        break;
      case 10:
        body = _buildHelpPoliciesView();
        break;
      case 11:
        body = _buildAboutView();
        break;
      default:
        body = _buildProfileView();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_activeCategoryIndex), child: body),
    );
  }

  Widget _buildDesktopLayout() {
    final categories = [
      {"title": "Vendor Profile", "icon": Icons.person_outline_rounded, "idx": 0},
      {"title": "Business Information", "icon": Icons.business_center_outlined, "idx": 1},
      {"title": "Working Schedule", "icon": Icons.calendar_month_outlined, "idx": 2},
      {"title": "Document Locker", "icon": Icons.folder_shared_outlined, "idx": 3},
      {"title": "Security & Sessions", "icon": Icons.lock_outline_rounded, "idx": 4},
      {"title": "Notification Preference", "icon": Icons.notifications_none_outlined, "idx": 5},
      {"title": "Payment Settings", "icon": Icons.payment_outlined, "idx": 6},
      {"title": "Privacy Settings", "icon": Icons.privacy_tip_outlined, "idx": 7},
      {"title": "Language & Region", "icon": Icons.language_rounded, "idx": 8},
      {"title": "Appearance UI", "icon": Icons.color_lens_outlined, "idx": 9},
      {"title": "Terms & Policies", "icon": Icons.policy_outlined, "idx": 10},
      {"title": "About Version", "icon": Icons.info_outline_rounded, "idx": 11},
    ];

    Widget body;
    switch (_activeCategoryIndex) {
      case 1:
        body = _buildBusinessInfoView();
        break;
      case 2:
        body = _buildSchedulePlannerView();
        break;
      case 3:
        body = _buildDocumentLockerView();
        break;
      case 4:
        body = _buildSecurityView();
        break;
      case 5:
        body = _buildNotificationsView();
        break;
      case 6:
        body = _buildPaymentSettingsView();
        break;
      case 7:
        body = _buildPrivacyView();
        break;
      case 8:
        body = _buildLanguageRegionView();
        break;
      case 9:
        body = _buildAppearanceView();
        break;
      case 10:
        body = _buildHelpPoliciesView();
        break;
      case 11:
        body = _buildAboutView();
        break;
      default:
        body = _buildProfileView();
    }

    return Row(
      children: [
        // Settings Categories Sidebar
        Container(
          width: 250,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
                        onPressed: widget.onBack,
                      ),
                    Text("SETTINGS HUB", style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF2563EB), fontSize: 15, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isSel = _activeCategoryIndex == cat['idx'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => setState(() => _activeCategoryIndex = cat['idx'] as int),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: isSel ? const Color(0xFF2563EB) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(cat['icon'] as IconData, color: isSel ? Colors.white : VendorTheme.textSecondary, size: 20),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  cat['title'] as String,
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : VendorTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Active Content body
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(key: ValueKey(_activeCategoryIndex), child: body),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 1: VENDOR PROFILE VIEW
  // ==========================================
  bool _isEditing = false;
  String _profileImageUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150";

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _profileImageUrl = picked.path;
        });
        if (mounted) {
          AppSnackbar.show(context, "Profile image updated successfully!");
        }
      }
    } catch (e) {
      debugPrint("Error picking profile image: $e");
    }
  }

  Widget _buildProfileView() {
    final imageProvider = _profileImageUrl.startsWith('http')
        ? NetworkImage(_profileImageUrl)
        : FileImage(io.File(_profileImageUrl)) as ImageProvider;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar Upload section
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2563EB), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: imageProvider,
                ),
              ),
              GestureDetector(
                onTap: _pickProfileImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _ownerNameCtrl.text,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: VendorTheme.textPrimary),
          ),
          Text(
            _businessNameCtrl.text,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // Profile Strength / Progress card (compact)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 40, height: 40, child: CircularProgressIndicator(value: 0.85, strokeWidth: 3.5, color: Color(0xFF2563EB))),
                    Text("85%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Profile Completion Strength", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("Add cover image to reach 100%", style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Conditional Edit vs Read Mode
          if (!_isEditing) ...[
            // Read-Only Info List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildReadOnlyRow("Business Name", _businessNameCtrl.text),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildReadOnlyRow("Owner Name", _ownerNameCtrl.text),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildReadOnlyRow("Primary Mobile", _phoneCtrl.text),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildReadOnlyRow("Business Bio", _bioCtrl.text),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text("Edit Profile Details"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ] else ...[
            // Editable Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Personal Configurations", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessNameCtrl,
                    decoration: const InputDecoration(labelText: "Business Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ownerNameCtrl,
                    decoration: const InputDecoration(labelText: "Owner Full Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Primary Mobile", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Business Bio", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Color(0xFF475569))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        AppSnackbar.show(context, "Profile configurations saved successfully!");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text("Save Details"),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),
          // Additional Settings / Utilities list (About & Logout)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
                  title: Text("About Nexora", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => setState(() => _activeCategoryIndex = 11),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: Text("Log Out Account", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      AppSnackbar.show(context, "Logged out successfully!");
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 2: BUSINESS INFORMATION VIEW
  // ==========================================
  Widget _buildBusinessInfoView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tax & Registration Details", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(controller: _gstCtrl, decoration: const InputDecoration(labelText: "GSTIN Number")),
          const SizedBox(height: 12),
          TextFormField(controller: _panCtrl, decoration: const InputDecoration(labelText: "PAN Card Number")),
          const SizedBox(height: 24),

          Text("Operational Radius", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Service Coverage Limit", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              Text("${_workingRadius.toInt()} km", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
            ],
          ),
          Slider(
            value: _workingRadius,
            min: 5.0,
            max: 50.0,
            onChanged: (val) => setState(() => _workingRadius = val),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                AppSnackbar.show(context, "Business Details updated!");
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text("Save Configurations"),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 3: WORKING SCHEDULE PLANNER
  // ==========================================
  Widget _buildSchedulePlannerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vacation Mode Toggle Switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE))),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF2563EB), child: Icon(Icons.beach_access, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Vacation Mode", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      Text("Instantly locks and hides new booking slots", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: _isVacationMode,
                  onChanged: (val) => setState(() => _isVacationMode = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text("Operational Days", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Column(
            children: _workingDays.keys.map((day) {
              return CheckboxListTile(
                title: Text(day, style: GoogleFonts.inter(fontSize: 13)),
                value: _workingDays[day],
                onChanged: (val) => setState(() => _workingDays[day] = val ?? false),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 4: DOCUMENT LOCKER VIEW
  // ==========================================
  Widget _buildDocumentLockerView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _documents.length,
      itemBuilder: (context, idx) {
        final key = _documents.keys.elementAt(idx);
        final doc = _documents[key]!;
        final verified = doc['status'] == "Verified";
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: verified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                child: Icon(verified ? Icons.verified : Icons.lock_clock, color: verified ? Colors.green : Colors.amber),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(key, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(doc['fileName'] ?? "No Document Uploaded", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => AppSnackbar.show(context, "Upload dialog initiated"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: const Text("Replace"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION 5: SECURITY CONFIGURATIONS
  // ==========================================
  Widget _buildSecurityView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text("Biometric Authentication", style: GoogleFonts.inter(fontSize: 13)),
            subtitle: Text("Use FaceID/Fingerprint for withdrawals", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            value: _biometricLogin,
            onChanged: (val) => setState(() => _biometricLogin = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text("Two-Factor Email Payout Auth", style: GoogleFonts.inter(fontSize: 13)),
            subtitle: Text("Requires email OTP for ledger transfers", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            value: _twoFactorAuth,
            onChanged: (val) => setState(() => _twoFactorAuth = val),
          ),
          const SizedBox(height: 24),

          Text("Active Devices & Login Sessions", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Column(
            children: _activeDevices.map((dev) {
              return ListTile(
                leading: const Icon(Icons.devices),
                title: Text(dev, style: GoogleFonts.inter(fontSize: 13)),
                trailing: TextButton(
                  onPressed: () => AppSnackbar.show(context, "Revoking session..."),
                  child: const Text("Revoke"),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 6: NOTIFICATIONS PREFERENCES
  // ==========================================
  Widget _buildNotificationsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text("New Booking Push Notifications", style: GoogleFonts.inter(fontSize: 13)),
            value: _pushBookings,
            onChanged: (val) => setState(() => _pushBookings = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text("Payout Settlement Alerts", style: GoogleFonts.inter(fontSize: 13)),
            value: _pushPayments,
            onChanged: (val) => setState(() => _pushPayments = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text("SMS Support Triggers", style: GoogleFonts.inter(fontSize: 13)),
            value: _smsAlerts,
            onChanged: (val) => setState(() => _smsAlerts = val),
          ),
          const Divider(),
          SwitchListTile(
            title: Text("Weekly Earnings Statement Email", style: GoogleFonts.inter(fontSize: 13)),
            value: _emailPromos,
            onChanged: (val) => setState(() => _emailPromos = val),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 7: PAYMENT SETTLEMENT FREQUENCY
  // ==========================================
  Widget _buildPaymentSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Settlement Payout Frequency", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPaymentSelectRow("Daily Settlement Payouts", "Clears wallet balance every 24 hours"),
          _buildPaymentSelectRow("Weekly Settlement (Recommended)", "Every Friday payouts cleared"),
          _buildPaymentSelectRow("Monthly Account Ledger Payouts", "Clears first day of next calendar month"),
        ],
      ),
    );
  }

  Widget _buildPaymentSelectRow(String label, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold)),
                Text(desc, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Colors.green),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 8: PRIVACY SETTINGS
  // ==========================================
  Widget _buildPrivacyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text("Public Account Visibility", style: GoogleFonts.inter(fontSize: 13)),
            subtitle: Text("Hide listing from local customer maps", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            value: true,
            onChanged: (val) {},
          ),
          const Divider(),
          SwitchListTile(
            title: Text("Display Support phone on Profile", style: GoogleFonts.inter(fontSize: 13)),
            value: false,
            onChanged: (val) {},
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => AppSnackbar.show(context, "Initiating full ledger database download link..."),
              icon: const Icon(Icons.download),
              label: const Text("Request All Financial Data Logs"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 9: LANGUAGE & REGION
  // ==========================================
  Widget _buildLanguageRegionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: "India (GMT+5:30)",
            items: ["India (GMT+5:30)", "USA (GMT-5:00)", "UK (GMT+0:00)"].map((reg) {
              return DropdownMenuItem(value: reg, child: Text(reg));
            }).toList(),
            onChanged: (val) {},
            decoration: const InputDecoration(labelText: "Select Regional Timezone"),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: "English (US)",
            items: ["English (US)", "Hindi", "Marathi"].map((reg) {
              return DropdownMenuItem(value: reg, child: Text(reg));
            }).toList(),
            onChanged: (val) {},
            decoration: const InputDecoration(labelText: "Display System Language"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 10: APPEARANCE Configuration
  // ==========================================
  Widget _buildAppearanceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _themeMode,
            items: ["Light Mode", "Dark Mode", "System Mode"].map((mode) {
              return DropdownMenuItem(value: mode, child: Text(mode));
            }).toList(),
            onChanged: (val) => setState(() => _themeMode = val ?? _themeMode),
            decoration: const InputDecoration(labelText: "Theme Select Mode"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 11: TERMS & POLICIES HELP
  // ==========================================
  Widget _buildHelpPoliciesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpDocRow("Nexora Partner Terms of Service", () {}),
          _buildHelpDocRow("Legal Privacy Statement Document", () {}),
          _buildHelpDocRow("Vendor Commission Agreement Policy", () {}),
        ],
      ),
    );
  }

  Widget _buildHelpDocRow(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  // ==========================================
  // SECTION 12: ABOUT SYSTEM VERSION
  // ==========================================
  Widget _buildAboutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              radius: 40,
              child: Icon(Icons.hexagon_rounded, color: Color(0xFF2563EB), size: 48),
            ),
            const SizedBox(height: 20),
            Text("Nexora Vendor Platform", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Production Version v2.4.10", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Text("© 2026 Nexora Technologies Private Limited. All legal licenses active.", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
