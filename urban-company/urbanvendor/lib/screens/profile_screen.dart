import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class VendorProfileScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;

  const VendorProfileScreen({
    super.key,
    this.isTab = false,
    this.onBack,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // Real-time streams cache
  Stream<DocumentSnapshot>? _vendorStream;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _vendorStream = FirebaseFirestore.instance
          .collection('vendors')
          .doc(user!.email)
          .snapshots();
    }
  }

  // Toggle status inside Firestore
  Future<void> _updateWorkingStatus(String field, bool value) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(user!.email)
          .update({field: value});
      if (mounted) {
        AppSnackbar.show(context, "Status updated successfully!");
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, "Error updating status: $e");
      }
    }
  }

  // Logout action
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Logout",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to log out from Nexora?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Delete Account confirmation
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Account",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          "This action is permanent and cannot be undone. All your business, wallet, and KYC profiles will be permanently erased. Proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              // In production, trigger Firestore document deletion first, then auth delete
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('vendors')
                      .doc(user!.email)
                      .delete();
                  await user!.delete();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    AppSnackbar.show(context, "Account permanently deleted.");
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackbar.show(context, "Authentication re-login required to complete deletion: $e");
                  }
                }
              }
            },
            child: const Text("Permanently Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Edit profile bottom sheet
  void _showEditProfileBottomSheet(Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['ownerName'] ?? '');
    final bizCtrl = TextEditingController(text: data['businessName'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final bioCtrl = TextEditingController(text: data['bio'] ?? '');
    final addressCtrl = TextEditingController(text: data['city'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Profile Details",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: VendorTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Owner Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bizCtrl,
                decoration: const InputDecoration(
                  labelText: "Business Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: "City Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Business Bio",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('vendors')
                          .doc(user!.email)
                          .update({
                        'ownerName': nameCtrl.text.trim(),
                        'businessName': bizCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'bio': bioCtrl.text.trim(),
                        'city': addressCtrl.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        AppSnackbar.show(context, "Profile details updated!");
                      }
                    }
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Access Denied. Please login.")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _vendorStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        // Derived calculations
        final String ownerName = data['ownerName'] ?? 'Rahul Sharma';
        final String businessName = data['businessName'] ?? 'RS Electrical Services';
        final String vendorId = data['vendorId'] ?? 'NX-VND-20341';
        final double rating = ((data['rating'] ?? 4.9) as num).toDouble();
        final int reviewsCount = data['reviewsCount'] ?? 1248;
        final int completedJobs = data['completedJobs'] ?? 2580;
        final String memberSince = data['memberSince'] ?? 'Jan 2025';
        final bool isOnline = data['isOnline'] ?? true;
        final bool isBusy = data['isBusy'] ?? false;
        final bool autoAssign = data['autoAssignment'] ?? true;

        // Profile strength progress
        final int completionPercent = data['completionPercent'] ?? 92;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: widget.isTab ? null : _buildAppBar(),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Premium Vendor Header Card
                  _buildVendorHeaderCard(
                    ownerName,
                    businessName,
                    vendorId,
                    rating,
                    reviewsCount,
                    completedJobs,
                    memberSince,
                    isOnline,
                    data,
                  ),
                  const SizedBox(height: 20),

                  // 2. Profile Completion Card
                  _buildCompletionProgressCard(completionPercent),
                  const SizedBox(height: 20),

                  // 3. Performance Dashboard Row (4 Cards)
                  _buildPerformanceDashboard(completedJobs),
                  const SizedBox(height: 24),

                  // 4. Working Status Controls (Toggles)
                  _buildWorkingStatusCard(isOnline, isBusy, autoAssign),
                  const SizedBox(height: 24),

                  // 5. Wallet Summary Card
                  _buildWalletSummaryCard(),
                  const SizedBox(height: 24),

                  // 6. Verification Status Badges
                  _buildVerificationCard(data),
                  const SizedBox(height: 24),

                  // 7. Services Categories Card
                  _buildServicesCategoriesCard(data),
                  const SizedBox(height: 24),

                  // 8. Ratings & Reviews Card
                  _buildRatingsCard(rating, reviewsCount),
                  const SizedBox(height: 24),

                  // 9. Referral Banner Card
                  _buildReferralCard(),
                  const SizedBox(height: 24),

                  // 10. Account Menu Items Section
                  _buildAccountSection(),
                  const SizedBox(height: 24),

                  // 11. Support Center Card
                  _buildSupportSection(),
                  const SizedBox(height: 24),

                  // 12. Danger Zone Card
                  _buildDangerZoneCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
        onPressed: widget.onBack ?? () => Navigator.maybePop(context),
      ),
      title: Text(
        "Profile",
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: VendorTheme.textPrimary,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildVendorHeaderCard(
    String ownerName,
    String businessName,
    String vendorId,
    double rating,
    int reviewsCount,
    int completedJobs,
    String memberSince,
    bool isOnline,
    Map<String, dynamic> rawData,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.2),
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
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: const NetworkImage(
                    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
                  ),
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ownerName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF38BDF8),
                          size: 16,
                        ),
                      ],
                    ),
                    Text(
                      businessName,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Vendor ID: $vendorId",
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOnline ? "🟢 Online" : "🔴 Offline",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStatItem("★ $rating", "($reviewsCount Reviews)"),
              _headerStatItem("$completedJobs", "Jobs Completed"),
              _headerStatItem(memberSince, "Member Since"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(
                "Edit Profile Details",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _showEditProfileBottomSheet(rawData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStatItem(String main, String sub) {
    return Column(
      children: [
        Text(
          main,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionProgressCard(int pct) {
    final bool isComplete = pct >= 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Profile Completion",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: VendorTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              isComplete
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Verified Professional",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF16A34A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      "$pct%",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isComplete
                ? "Your vendor profile is completely configured to receive smart assignment bookings."
                : "Complete your profile information to receive high priority bookings in your operational radius.",
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDashboard(int totalJobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Performance Dashboard",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: VendorTheme.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _dashboardStatCard("Today's Earnings", "₹1,850", Icons.payments_rounded, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
            _dashboardStatCard("This Month", "₹48,900", Icons.analytics_rounded, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
            _dashboardStatCard("Completed Jobs", "$totalJobs", Icons.assignment_turned_in_rounded, const Color(0xFFECFDF5), const Color(0xFF10B981)),
            _dashboardStatCard("Cancellation Rate", "0.8%", Icons.cancel_presentation_rounded, const Color(0xFFFEF2F2), Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _dashboardStatCard(String label, String value, IconData icon, Color bg, Color col) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: bg,
            child: Icon(icon, color: col, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: VendorTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingStatusCard(bool isOnline, bool isBusy, bool autoAssign) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Working Status Configurations",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: VendorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _statusToggleRow(
            "Accept New Bookings (Online)",
            "Toggles profile visibility to customers",
            isOnline,
            (val) => _updateWorkingStatus('isOnline', val),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _statusToggleRow(
            "Busy Mode",
            "Temporarily block assignment schedules",
            isBusy,
            (val) => _updateWorkingStatus('isBusy', val),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _statusToggleRow(
            "Auto Assignment Engine",
            "Auto match nearby bookings directly",
            autoAssign,
            (val) => _updateWorkingStatus('autoAssignment', val),
          ),
        ],
      ),
    );
  }

  Widget _statusToggleRow(String title, String sub, bool val, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: VendorTheme.textPrimary,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Switch(
          value: val,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF2563EB),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildWalletSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Balance",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹24,500",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: VendorTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/withdrawals'),
                child: const Text("Withdraw"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _walletSummaryInfo("₹4,200", "Pending Settlement"),
              _walletSummaryInfo("Tomorrow", "Next Settlement Date"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletSummaryInfo(String main, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          main,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: VendorTheme.textPrimary,
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> data) {
    final bool aadhaar = data['aadhaarVerified'] ?? true;
    final bool pan = data['panVerified'] ?? true;
    final bool gst = data['gstVerified'] ?? true;
    final bool bank = data['bankVerified'] ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "KYC Verification Status",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: VendorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kycBadge(aadhaar, "Aadhaar"),
              _kycBadge(pan, "PAN"),
              _kycBadge(gst, "GST"),
              _kycBadge(bank, "Bank Account"),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Last verified on 02-08-2026. Approved by Admin Executive.",
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _kycBadge(bool done, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: done ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
          child: Icon(
            done ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: done ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: VendorTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCategoriesCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Services",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: VendorTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/my_services'),
                child: const Text("View All"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _serviceChip("Electrician"),
              _serviceChip("AC Repair"),
              _serviceChip("Fan Installation"),
              _serviceChip("Switch Repair"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: VendorTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRatingsCard(double rating, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ratings & Reviews Summary",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: VendorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Text(
                    "$rating",
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: VendorTheme.textPrimary,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$count reviews",
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _ratingProgressRow("5★", 0.85),
                    _ratingProgressRow("4★", 0.10),
                    _ratingProgressRow("3★", 0.03),
                    _ratingProgressRow("2★", 0.01),
                    _ratingProgressRow("1★", 0.01),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratingProgressRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: val,
                minHeight: 4,
                backgroundColor: const Color(0xFFF1F5F9),
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text("${(val * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReferralCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Refer & Earn ₹500",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Invite other service professionals to register on Nexora.",
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0284C7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => AppSnackbar.show(context, "Referral link copied!"),
            child: const Text("Invite Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _accountTile(Icons.person_outline_rounded, "Personal Information", () => _showEditProfileBottomSheet({})),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _accountTile(Icons.business_center_outlined, "Business Information", () => Navigator.pushNamed(context, '/settings')),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _accountTile(Icons.account_balance_outlined, "Bank Details & Payouts", () => Navigator.pushNamed(context, '/wallet')),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _accountTile(Icons.folder_shared_outlined, "KYC Documents Locker", () => Navigator.pushNamed(context, '/settings')),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _accountTile(Icons.calendar_month_outlined, "Working Hours Scheduler", () => Navigator.pushNamed(context, '/calendar')),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _accountTile(Icons.map_outlined, "Operational Service Area", () => Navigator.pushNamed(context, '/work_location')),
        ],
      ),
    );
  }

  Widget _accountTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: VendorTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _accountTile(Icons.help_center_outlined, "Help Center & FAQs", () => Navigator.pushNamed(context, '/help_center')),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _accountTile(Icons.support_agent_outlined, "Chat with Nexora Admin", () => Navigator.pushNamed(context, '/support')),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _accountTile(Icons.call_outlined, "Call Helpline Support", () => AppSnackbar.show(context, "Dialing helpline...")),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: Text(
              "Logout Account",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: _showLogoutConfirmation,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: Text(
              "Permanently Delete Account",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onTap: _showDeleteAccountConfirmation,
          ),
        ],
      ),
    );
  }
}
