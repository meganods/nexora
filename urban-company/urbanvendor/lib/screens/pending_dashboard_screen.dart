import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class PendingDashboardScreen extends StatefulWidget {
  const PendingDashboardScreen({super.key});

  @override
  State<PendingDashboardScreen> createState() => _PendingDashboardScreenState();
}

class _PendingDashboardScreenState extends State<PendingDashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isOnline = false;

  // Form Controllers for editing
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _descController = TextEditingController();

  final _bankHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accNoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Logged In")));
    }

    final String docId = (user?.email != null && user!.email!.isNotEmpty) ? user!.email! : user!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(docId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Fallback to UID document if email doc doesn't exist
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('vendors').doc(user!.uid).snapshots(),
            builder: (context, uidSnapshot) {
              if (uidSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (!uidSnapshot.hasData || !uidSnapshot.data!.exists) {
                return const Scaffold(body: Center(child: Text("Registration details not found.")));
              }
              return _buildPendingContent(context, uidSnapshot.data!.data() as Map<String, dynamic>);
            },
          );
        }

        return _buildPendingContent(context, snapshot.data!.data() as Map<String, dynamic>);
      },
    );
  }

  Widget _buildPendingContent(BuildContext context, Map<String, dynamic> data) {
    final verification = data['verification'] as Map<String, dynamic>? ?? {};
    final String rawStatus = (data['status'] ?? verification['status'] ?? 'pending').toString().toLowerCase().trim();

    // Auto-redirect success check: If status turns to approved, navigate to success splash!
    if (rawStatus == 'approved') {
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/approval_success');
        }
      });
    }

        final String ownerName = data['ownerName'] ?? 'Partner';
        final String businessName = data['businessName'] ?? 'My Business';
        final List<dynamic> services = data['services'] ?? [];

        // Prepopulate text controllers
        _businessNameController.text = businessName;
        _ownerNameController.text = ownerName;
        _descController.text = data['description'] ?? '';

        final bank = data['bank'] as Map<String, dynamic>? ?? {};
        _bankHolderController.text = bank['holder'] ?? '';
        _bankNameController.text = bank['bankName'] ?? '';
        _accNoController.text = bank['accountNo'] ?? '';

        return Scaffold(
          backgroundColor: VendorTheme.bgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: VendorTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.handyman_rounded, color: VendorTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    "NEXORA Partner",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: VendorTheme.textPrimary, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Online Switch (LOCKED)
              Row(
                children: [
                  Text(
                    _isOnline ? "Online" : "Offline",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.lock_outline_rounded, color: VendorTheme.warningColor, size: 20),
                    onPressed: () => _showLockedFeatureDialog("Go Online", "Your account must be verified by administrators before you can go online to receive client booking alerts."),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: VendorTheme.errorColor),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/welcome');
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Testing Bypass Banner Button (Temporary for testing)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/expert_dashboard', arguments: {'isTestBypass': true});
                        },
                        icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                        label: Text(
                          "⚡ Open Home Dashboard (Test Bypass)",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VendorTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),

                    // Review Status Banner
                    _buildReviewBanner(data),
                    const SizedBox(height: 24),

                    // Title Header
                    Text(
                      "Good Morning 👋 $ownerName",
                      style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary),
                    ),
                    const SizedBox(height: 20),

                    // Verification Timeline
                    _buildVerificationTimeline(data),
                    const SizedBox(height: 24),

                    // Profile Completion Config Cards
                    _buildProfileSection(data),
                    const SizedBox(height: 24),

                    // Learning Center
                    _buildLearningCenter(),
                    const SizedBox(height: 24),

                    // Help & FAQ
                    _buildHelpSection(),
                  ],
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildReviewBanner(Map<String, dynamic> data) {
    final verification = data['verification'] as Map<String, dynamic>? ?? {};
    final status = verification['status'] ?? 'NotStarted';
    final adminReview = data['adminReview'] as Map<String, dynamic>? ?? {};
    
    Color bg = const Color(0xFFFEF3C7);
    Color border = const Color(0xFFFBBF24);
    Color iconC = VendorTheme.warningColor;
    Color textThemeColor = const Color(0xFF78350F);
    Color descColor = const Color(0xFF92400E);
    String titleText = "Account Under Review";
    String descText = "Our compliance team is verifying your profile files. Estimated approval: 1-2 business days.";
    IconData icon = Icons.info_outline_rounded;

    if (status == 'Approved') {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF86EFAC);
      iconC = const Color(0xFF16A34A);
      textThemeColor = const Color(0xFF14532D);
      descColor = const Color(0xFF166534);
      titleText = "Account Activated";
      descText = "Your profile is verified. You can now go online to accept client bookings.";
      icon = Icons.check_circle_outline_rounded;
    } else if (status == 'Rejected') {
      bg = const Color(0xFFFEE2E2);
      border = const Color(0xFFFCA5A5);
      iconC = const Color(0xFFDC2626);
      textThemeColor = const Color(0xFF7F1D1D);
      descColor = const Color(0xFF991B1B);
      titleText = "Verification Rejected";
      descText = "Reason: ${adminReview['rejectionReason'] ?? 'Documents did not meet criteria.'} Tap 'Uploaded Verification Documents' below to restart.";
      icon = Icons.cancel_outlined;
    } else if (status == 'RequestChanges') {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFF93C5FD);
      iconC = const Color(0xFF2563EB);
      textThemeColor = const Color(0xFF1E3A8A);
      descColor = const Color(0xFF1E40AF);
      titleText = "Corrections Needed";
      descText = "Reason: ${adminReview['requestChangesReason'] ?? 'Please correct documents.'} Tap 'Uploaded Verification Documents' below to update.";
      icon = Icons.assignment_late_outlined;
    } else if (status == 'NotStarted' || status == 'InProgress') {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFCBD5E1);
      iconC = Colors.grey;
      textThemeColor = const Color(0xFF1E293B);
      descColor = const Color(0xFF475569);
      titleText = "Verification Incomplete";
      descText = "Please complete your business verification documents to unlock your dashboard.";
      icon = Icons.shield_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconC, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: textThemeColor),
                ),
                const SizedBox(height: 4),
                Text(
                  descText,
                  style: GoogleFonts.inter(fontSize: 12, color: descColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTimeline(Map<String, dynamic> data) {
    final verification = data['verification'] as Map<String, dynamic>? ?? {};
    final status = verification['status'] ?? 'NotStarted';
    
    final bool docsUploaded = verification['submittedAt'] != null || status == 'Submitted' || status == 'Approved';
    final bool isApproved = status == 'Approved';
    final bool inProgress = status == 'Submitted' || status == 'PendingApproval';
    final bool requestChanges = status == 'RequestChanges';
    final bool isRejected = status == 'Rejected';

    final steps = [
      {"title": "Account Created", "done": true, "active": false, "alert": false},
      {"title": "Business Profile Completed", "done": true, "active": false, "alert": false},
      {
        "title": docsUploaded ? "Documents Uploaded" : "Documents Upload Pending",
        "done": docsUploaded,
        "active": !docsUploaded && status != 'NotStarted',
        "alert": requestChanges || isRejected,
      },
      {
        "title": isApproved 
            ? "Verification Completed" 
            : requestChanges 
                ? "Corrections Requested" 
                : isRejected 
                    ? "Verification Rejected" 
                    : "Verification in Progress",
        "done": isApproved,
        "active": inProgress || requestChanges,
        "alert": isRejected || requestChanges,
      },
      {"title": "Activated", "done": isApproved, "active": false, "alert": false},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Verification Progress Timeline", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary)),
            const SizedBox(height: 20),
            Column(
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final done = step["done"] as bool;
                final active = step["active"] == true;
                final alert = step["alert"] == true;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: alert 
                              ? Colors.redAccent
                              : done
                                  ? (active ? VendorTheme.warningColor : VendorTheme.accentColor)
                                  : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: done && !active
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : active
                                  ? const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 14)
                                  : alert
                                      ? const Icon(Icons.priority_high_rounded, color: Colors.white, size: 14)
                                      : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        step["title"] as String,
                        style: GoogleFonts.inter(
                          fontWeight: active || done || alert ? FontWeight.bold : FontWeight.normal,
                          color: alert
                              ? Colors.redAccent
                              : active
                                  ? VendorTheme.warningColor
                                  : done
                                      ? VendorTheme.textPrimary
                                      : VendorTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Business Profile Settings",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: VendorTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("100% Complete", style: GoogleFonts.inter(color: VendorTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEditFieldTile("Owner & Business Details", "Edit business description, displays, and metadata.", () => _showEditBusinessDialog()),
            const Divider(),
            _buildEditFieldTile("Uploaded Verification Documents", "Aadhaar, PAN, Trade Licenses, and Certificates.", () {
              Navigator.pushNamed(context, '/kyc_onboarding');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEditFieldTile(String title, String desc, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary)),
      subtitle: Text(desc, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: VendorTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildServicesSection(List<dynamic> services) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "My Offered Services",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddServiceDialog(services),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add New"),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: services.map((s) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.home_repair_service_rounded, color: VendorTheme.primaryColor)),
                  title: Text(s["name"] ?? 'Service Option', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${s["duration"] ?? '60 Min'} • Flat ₹${s["price"]}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: VendorTheme.errorColor, size: 20),
                    onPressed: () => _deleteService(services, s),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Wallet Earnings", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text("₹0.00", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 24, color: VendorTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text("Wallet balance settlements locked until account review completes.", style: GoogleFonts.inter(fontSize: 11, color: VendorTheme.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.lock_outline_rounded, color: VendorTheme.warningColor),
              onPressed: () => _showLockedFeatureDialog("Wallet Withdrawal", "You cannot withdraw funds or execute ledger actions before your partner account is approved."),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCenter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Partner Learning Center", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary)),
            const SizedBox(height: 16),
            _buildGuideTile("How Nexora Partner Works", "Read our complete guide to scheduling and commission structures."),
            const Divider(),
            _buildGuideTile("Safety Guidelines & Compliances", "Procedures to follow at client sites for premium ratings."),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideTile(String title, String desc) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber[50], shape: BoxShape.circle), child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber)),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(desc, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
      onTap: () {},
    );
  }

  Widget _buildHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildHelpButton(Icons.chat_bubble_outline_rounded, "Live Chat", () {}),
            _buildHelpButton(Icons.phone_in_talk_outlined, "Call Support", () {}),
            _buildHelpButton(Icons.support_rounded, "FAQs", () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: VendorTheme.primaryColor), onPressed: onTap),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
      ],
    );
  }

  void _showLockedFeatureDialog(String featureName, String description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: VendorTheme.warningColor),
              const SizedBox(width: 12),
              Text(featureName, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(description, style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Understood"),
            ),
          ],
        );
      },
    );
  }

  void _showEditBusinessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Business Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _ownerNameController, decoration: const InputDecoration(labelText: "Owner Name")),
              const SizedBox(height: 12),
              TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: "Business Name")),
              const SizedBox(height: 12),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: "Description")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('vendors').doc(user!.email).update({
                  "ownerName": _ownerNameController.text.trim(),
                  "businessName": _businessNameController.text.trim(),
                  "description": _descController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
                AppSnackbar.show(context, "Business Details updated successfully.");
              },
              child: const Text("Save Details"),
            ),
          ],
        );
      },
    );
  }

  void _showEditBankDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Bank Details", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _bankHolderController, decoration: const InputDecoration(labelText: "Account Holder")),
              const SizedBox(height: 12),
              TextField(controller: _bankNameController, decoration: const InputDecoration(labelText: "Bank Name")),
              const SizedBox(height: 12),
              TextField(controller: _accNoController, decoration: const InputDecoration(labelText: "Account Number")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('vendors').doc(user!.email).update({
                  "bank": {
                    "holder": _bankHolderController.text.trim(),
                    "bankName": _bankNameController.text.trim(),
                    "accountNo": _accNoController.text.trim(),
                  }
                });
                if (context.mounted) Navigator.pop(context);
                AppSnackbar.show(context, "Bank coordinates updated successfully.");
              },
              child: const Text("Save Coordinates"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddServiceDialog(List<dynamic> services) async {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final durC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Custom Service", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: "Service Name")),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: priceC, decoration: const InputDecoration(labelText: "Price (₹)"), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: durC, decoration: const InputDecoration(labelText: "Duration (e.g. 90 Min)"))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameC.text.isNotEmpty && priceC.text.isNotEmpty) {
                  final list = List.from(services);
                  list.add({
                    "name": nameC.text.trim(),
                    "price": priceC.text.trim(),
                    "duration": durC.text.trim().isEmpty ? "60 Min" : durC.text.trim(),
                  });

                  await FirebaseFirestore.instance.collection('vendors').doc(user!.email).update({
                    "services": list,
                  });
                  if (context.mounted) Navigator.pop(context);
                  AppSnackbar.show(context, "Service added to active menu list.");
                }
              },
              child: const Text("Add Option"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteService(List<dynamic> services, Map<String, dynamic> item) async {
    final list = List.from(services);
    list.removeWhere((element) => element["name"] == item["name"]);
    await FirebaseFirestore.instance.collection('vendors').doc(user!.email).update({
      "services": list,
    });
    AppSnackbar.show(context, "Service option removed.");
  }
}
