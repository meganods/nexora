import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  final String _email = FirebaseAuth.instance.currentUser?.email ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isRefreshing = false);
      AppSnackbar.show(context, "Status refreshed successfully!");
    }
  }

  Future<void> _handleResubmit(Map<String, dynamic> verification, bool resetAll) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('vendors').doc(_email);
      
      if (resetAll) {
        // Full restart (Keep Aadhaar verified)
        await docRef.set({
          'verification': {
            'status': 'InProgress',
            'currentStep': 'welcome',
          }
        }, SetOptions(merge: true));
      } else {
        // Request Changes resubmit
        await docRef.set({
          'verification': {
            'status': 'InProgress',
            'currentStep': 'pan', // Redirect directly to PAN editing
          }
        }, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/kyc_onboarding');
      }
    } catch (e) {
      AppSnackbar.show(context, "Error updating status: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Verification Status",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('vendors').doc(_email).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile details not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final verification = data['verification'] as Map<String, dynamic>? ?? {};
          final adminReview = data['adminReview'] as Map<String, dynamic>? ?? {};

          final status = verification['status'] ?? 'NotStarted';
          final rejectionReason = adminReview['rejectionReason'] as String?;
          final requestChangesReason = adminReview['requestChangesReason'] as String?;

          Color statusColor = const Color(0xFFF59E0B);
          String statusText = "Pending Approval";

          if (status == 'Approved') {
            statusColor = const Color(0xFF16A34A);
            statusText = "Approved";
          } else if (status == 'Rejected') {
            statusColor = const Color(0xFFDC2626);
            statusText = "Rejected";
          } else if (status == 'RequestChanges') {
            statusColor = const Color(0xFF3B82F6);
            statusText = "Changes Requested";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == 'Rejected'
                          ? Icons.cancel_outlined
                          : status == 'RequestChanges'
                              ? Icons.assignment_late_outlined
                              : Icons.mark_email_read_outlined,
                      color: statusColor,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Your Account is Under Verification",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: statusColor),
                  ),
                ),
                const SizedBox(height: 28),

                // Rejection or Request Changes Banner
                if (status == 'Rejected' && rejectionReason != null) ...[
                  _buildReasonCard("Rejection Reason", rejectionReason, Colors.red[50]!, Colors.red[900]!),
                  const SizedBox(height: 24),
                ],
                if (status == 'RequestChanges' && requestChangesReason != null) ...[
                  _buildReasonCard("Action Needed: Request Changes", requestChangesReason, const Color(0xFFEFF6FF), const Color(0xFF1E40AF)),
                  const SizedBox(height: 24),
                ],

                // Verification Timeline
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Verification Progress", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                ),
                const SizedBox(height: 16),
                _buildTimelineItem("Aadhaar Verification Completed", true, true),
                _buildTimelineItem("PAN Details Submitted", verification['panSubmitted'] == true, true),
                _buildTimelineItem("GST Details Submitted", verification['gstSubmitted'] == true || verification['gstApplicable'] == false, true),
                _buildTimelineItem(
                  status == 'Approved'
                      ? "Admin Review Approved"
                      : status == 'Rejected'
                          ? "Admin Review Rejected"
                          : status == 'RequestChanges'
                              ? "Corrections Required"
                              : "Waiting For Admin Approval",
                  status == 'Approved',
                  false,
                  isAlert: status == 'Rejected' || status == 'RequestChanges',
                ),

                const SizedBox(height: 36),

                // Dynamic buttons based on status
                if (status == 'Rejected') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => _handleResubmit(verification, true),
                      child: const Text("Resubmit Verification", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else if (status == 'RequestChanges') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => _handleResubmit(verification, false),
                      child: const Text("Update Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isRefreshing ? null : _handleRefresh,
                            icon: _isRefreshing
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh, size: 16),
                            label: const Text("Refresh Status"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () => AppSnackbar.show(context, "Support ticket created. We will contact you shortly."),
                            icon: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
                            label: const Text("Contact Support", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReasonCard(String title, String content, Color bg, Color textC) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textC.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: textC)),
          const SizedBox(height: 6),
          Text(content, style: GoogleFonts.inter(fontSize: 12.5, color: textC.withOpacity(0.9), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, bool active, bool hasNext, {bool isAlert = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF16A34A)
                      : isAlert
                          ? const Color(0xFFDC2626)
                          : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  active
                      ? Icons.check
                      : isAlert
                          ? Icons.priority_high
                          : Icons.circle,
                  color: active || isAlert ? Colors.white : Colors.transparent,
                  size: 12,
                ),
              ),
              if (hasNext)
                Expanded(
                  child: Container(
                    width: 2,
                    color: active ? const Color(0xFF16A34A) : Colors.grey[200],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: active || isAlert ? FontWeight.bold : FontWeight.w500,
                  color: active
                      ? const Color(0xFF0F172A)
                      : isAlert
                          ? const Color(0xFFDC2626)
                          : Colors.grey[500],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
