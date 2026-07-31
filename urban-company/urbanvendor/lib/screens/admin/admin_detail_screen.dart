import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../services/kyc_service.dart';

class AdminDetailScreen extends StatefulWidget {
  const AdminDetailScreen({super.key});

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  final KycService _kycService = KycService();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(String vendorId) async {
    setState(() => _isSubmitting = true);
    try {
      await _kycService.adminApproveVendor(vendorId, "admin@nexora.com");
      if (mounted) {
        AppSnackbar.show(context, "Vendor KYC approved successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, "Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showReasonDialog(String vendorId, bool isRequestChanges) async {
    _reasonController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isRequestChanges ? "Request Corrections" : "Reject Vendor KYC", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRequestChanges
                    ? "Explain what corrections the vendor needs to make to their documents."
                    : "Provide the reason for rejecting this vendor application.",
                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[600]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isRequestChanges ? "e.g. Please re-upload a clearer image of your PAN card." : "Reason for rejection...",
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRequestChanges ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
              ),
              onPressed: () async {
                final reason = _reasonController.text.trim();
                if (reason.isEmpty) {
                  AppSnackbar.show(context, "Reason is required", isError: true);
                  return;
                }
                Navigator.pop(context);
                
                setState(() => _isSubmitting = true);
                try {
                  if (isRequestChanges) {
                    await _kycService.adminRequestChanges(vendorId, "admin@nexora.com", reason);
                    if (mounted) AppSnackbar.show(context, "Changes requested successfully!");
                  } else {
                    await _kycService.adminRejectVendor(vendorId, "admin@nexora.com", reason);
                    if (mounted) AppSnackbar.show(context, "Vendor application rejected.");
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) AppSnackbar.show(context, "Error: $e", isError: true);
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final vendorId = args['vendorId'] ?? '';

    if (vendorId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Vendor ID not provided")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Request Review",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('vendors').doc(vendorId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Vendor profile details not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final verification = data['verification'] as Map<String, dynamic>? ?? {};
          final profile = data['profile'] as Map<String, dynamic>? ?? {};
          final personalInfo = data['personalInfo'] as Map<String, dynamic>? ?? {};

          final ownerName = profile['ownerName'] ?? personalInfo['ownerName'] ?? data['ownerName'] ?? 'Unnamed Vendor';
          final businessName = profile['businessName'] ?? personalInfo['businessName'] ?? data['businessName'] ?? 'No Business Name';
          final phone = profile['phone'] ?? personalInfo['phone'] ?? data['phone'] ?? 'No Mobile';
          final email = profile['email'] ?? personalInfo['email'] ?? data['email'] ?? 'No Email';

          final status = verification['status'] ?? 'NotStarted';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("KYC Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Vendor Information
                    _buildSectionHeader("Vendor Information"),
                    _buildDetailCard([
                      _buildDetailRow("Full Name", ownerName),
                      _buildDetailRow("Email Address", email),
                      _buildDetailRow("Mobile Phone", phone),
                    ]),
                    const SizedBox(height: 20),

                    // Section 2: Business Information
                    _buildSectionHeader("Business Information"),
                    _buildDetailCard([
                      _buildDetailRow("Business Name", businessName),
                      _buildDetailRow("Operational Coverage", "${data['radius'] ?? '15'} km radius"),
                    ]),
                    const SizedBox(height: 20),

                    // Section 3: Aadhaar Status
                    _buildSectionHeader("Aadhaar Verification"),
                    _buildDetailCard([
                      _buildDetailRow("Aadhaar Number", verification['aadhaarNumber'] ?? 'Not Provided'),
                      _buildDetailRow("Verification Status", verification['aadhaarVerified'] == true ? "OTP Verified" : "Not Verified", isGreen: true),
                    ]),
                    const SizedBox(height: 20),

                    // Section 4: PAN Details
                    _buildSectionHeader("PAN Details"),
                    _buildDetailCard([
                      _buildDetailRow("PAN Number", verification['panNumber'] ?? 'Not Provided'),
                      _buildDetailRow("Holder Name", verification['panHolderName'] ?? 'Not Provided'),
                      const SizedBox(height: 10),
                      if (verification['panCardUrl'] != null) ...[
                        Text("PAN Card Image Upload:", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            verification['panCardUrl'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      ] else
                        Text("No PAN image uploaded", style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                    ]),
                    const SizedBox(height: 20),

                    // Section 5: GST Details
                    _buildSectionHeader("GST Details"),
                    _buildDetailCard([
                      _buildDetailRow("GST Applicable", verification['gstApplicable'] == true ? "Yes" : "No"),
                      if (verification['gstApplicable'] == true) ...[
                        _buildDetailRow("GSTIN Number", verification['gstNumber'] ?? 'Not Provided'),
                        _buildDetailRow("Registered Name", verification['gstBusinessName'] ?? 'Not Provided'),
                        const SizedBox(height: 10),
                        if (verification['gstCertificateUrl'] != null) ...[
                          Text("GST Certificate Image Upload:", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              verification['gstCertificateUrl'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        ] else
                          Text("No GST certificate uploaded", style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                      ],
                    ]),
                    const SizedBox(height: 40),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFDC2626)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showReasonDialog(vendorId, false),
                              child: const Text("Reject", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _showReasonDialog(vendorId, true),
                              child: const Text("Need Changes", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _handleApprove(vendorId),
                              child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (_isSubmitting)
                Container(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isGreen ? const Color(0xFF16A34A) : VendorTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
