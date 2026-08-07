import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:js' as js;

class VendorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> vendorData;
  final VoidCallback onBack;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const VendorDetailsScreen({
    super.key,
    required this.vendorData,
    required this.onBack,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final String vendorId = vendorData['id'] ?? '';
    if (vendorId.isEmpty) {
      return _buildContent(context, vendorData);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> liveData = vendorData;
        if (snapshot.hasData && snapshot.data!.data() != null) {
          liveData = snapshot.data!.data() as Map<String, dynamic>;
          liveData['id'] = vendorId;
        }

        return _buildContent(context, liveData);
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 1200;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumbs(data),
            const SizedBox(height: 16),
            _buildHeader(isWide, data),
            const SizedBox(height: 32),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 20, child: _buildLeftColumn(isWide, data)),
                  const SizedBox(width: 32),
                  Expanded(flex: 10, child: _buildRightColumn(context, data)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftColumn(isWide, data),
                  const SizedBox(height: 32),
                  _buildRightColumn(context, data),
                ],
              ),
            const SizedBox(height: 32),
            _buildFloatingActionbar(data),
          ],
        );
      },
    );
  }

  Widget _buildBreadcrumbs(Map<String, dynamic> data) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 16,
          width: 1,
          color: const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Text(
                  'Vendors',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFCBD5E1)),
              const SizedBox(width: 8),
              Text(
                'Partner Onboarding',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFCBD5E1)),
              const SizedBox(width: 8),
              Text(
                'Application #${data['id'] ?? 'VP-8829'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isWide, Map<String, dynamic> data) {
    final String vendorName = data['name'] ?? data['ownerName'] ?? data['businessName'] ?? 'Vendor';
    final String categoryName = data['mainCategory'] ?? (data['selectedCategoryIds'] is List && (data['selectedCategoryIds'] as List).isNotEmpty ? (data['selectedCategoryIds'] as List).join(', ') : 'Premium Service Partner');

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isWide ? 400 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendorName,
                style: GoogleFonts.inter(
                  fontSize: isWide ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              Text(
                categoryName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Reject Application', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Approve Vendor', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeftColumn(bool isWide, Map<String, dynamic> data) {
    return Column(
      children: [
        _buildProfileInfo(isWide, data),
        const SizedBox(height: 24),
        _buildMapSection(data),
        const SizedBox(height: 24),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildActiveServices(data)),
              const SizedBox(width: 24),
              Expanded(child: _buildCommission(data)),
            ],
          )
        else
          Column(
            children: [
              _buildActiveServices(data),
              const SizedBox(height: 24),
              _buildCommission(data),
            ],
          ),
      ],
    );
  }

  Widget _buildProfileInfo(bool isWide, Map<String, dynamic> data) {
    final String statusStr = (data['status'] ?? (data['verification'] is Map ? (data['verification'] as Map)['status'] : null) ?? 'PENDING').toString().toUpperCase().trim();
    final String emailStr = (data['email'] ?? 'N/A').toString();
    final String phoneStr = (data['phoneNumber'] ?? data['phone'] ?? 'N/A').toString();
    final String experienceStr = data['experience'] != null ? '${data['experience']} Years' : 'N/A';
    
    String addressStr = 'N/A';
    if (data['address'] != null) {
      if (data['address'] is Map) {
        final m = data['address'] as Map;
        final parts = [
          m['streetAddress'] ?? m['street'] ?? '',
          m['city'] ?? '',
          m['state'] ?? '',
          m['zipCode'] ?? m['postalCode'] ?? ''
        ].where((e) => e.toString().trim().isNotEmpty).toList();
        addressStr = parts.isNotEmpty ? parts.join(', ') : 'N/A';
      } else {
        addressStr = data['address'].toString();
      }
    }

    String registrationDate = 'N/A';
    if (data['createdAt'] != null) {
      try {
        final dt = data['createdAt'] is Timestamp 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.parse(data['createdAt'].toString());
        registrationDate = DateFormat('MMM dd, yyyy').format(dt);
      } catch (_) {
        registrationDate = data['createdAt'].toString();
      }
    }

    return Container(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF1F5F9),
                ),
                child: const Center(
                  child: Icon(LucideIcons.user, size: 40, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0369A1),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (isWide) const SizedBox(width: 24),
          SizedBox(
            width: isWide ? 400 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    SizedBox(
                      width: 180,
                      child: _buildInfoItem(
                        'EMAIL ADDRESS',
                        emailStr,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: _buildInfoItem('PHONE NUMBER', phoneStr),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    SizedBox(
                      width: 180,
                      child: _buildInfoItem(
                        'REGISTRATION DATE',
                        registrationDate,
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: _buildInfoItem('EXPERIENCE', experienceStr),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoItem(
                  'OFFICE ADDRESS',
                  addressStr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(Map<String, dynamic> data) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.blue[50]!.withValues(alpha: 0.4), Colors.grey[200]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 100,
              color: Colors.blue[800]!.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Operational Radius: 15km (Bengaluru Central)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveServices(Map<String, dynamic> data) {
    final List<dynamic> services = data['services'] ?? [];
    final List<dynamic> serviceNames = data['enabledServiceNames'] ?? [];

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Services',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(
                LucideIcons.penTool,
                color: Color(0xFF2563EB),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: services.isNotEmpty 
                ? ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final s = services[index];
                      return _buildServiceRow(s['name'] ?? 'Service Option', '₹${s['price'] ?? s['rate'] ?? '0'}');
                    },
                  )
                : serviceNames.isNotEmpty 
                    ? ListView.builder(
                        itemCount: serviceNames.length,
                        itemBuilder: (context, index) {
                          return _buildServiceRow(serviceNames[index].toString(), 'Enabled');
                        },
                      )
                    : Center(
                        child: Text(
                          'No active services listed',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String name, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommission(Map<String, dynamic> data) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Commission',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '12%',
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PREMIUM TIER RATE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF38BDF8),
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Text(
            'Rewards program based on historical certificate validation.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context, Map<String, dynamic> data) {
    return Column(
      children: [
        _buildComplianceDocs(context, data),
        const SizedBox(height: 24),
        _buildProjectedEarnings(data),
        const SizedBox(height: 24),
        _buildReviewerConfidence(data),
      ],
    );
  }

  Widget _buildComplianceDocs(BuildContext context, Map<String, dynamic> data) {
    final Map<String, dynamic> verification = data['verification'] is Map ? Map<String, dynamic>.from(data['verification'] as Map) : {};
    final Map<String, dynamic> gst = verification['gst'] is Map 
        ? Map<String, dynamic>.from(verification['gst'] as Map) 
        : (data['gst'] is Map ? Map<String, dynamic>.from(data['gst'] as Map) : {});

    final String? aadhaarNumber = verification['aadhaarNumber'] ?? data['aadhaarNumber'];
    final String? aadhaarUrl = verification['aadhaarCardUrl'] ?? data['aadhaarCardUrl'] ?? data['aadhaarUrl'];
    final String? panNumber = verification['panNumber'] ?? data['panNumber'];
    final String? panHolderName = verification['panHolderName'] ?? data['panHolderName'];
    final String? panUrl = verification['panCardUrl'] ?? data['panCardUrl'] ?? data['panUrl'];

    final bool isGstApplicable = gst['applicable'] ?? data['gstApplicable'] ?? false;
    final String? gstNumber = gst['gstNumber'] ?? data['gstNumber'];
    final String? gstBusinessName = gst['businessName'] ?? data['gstBusinessName'];
    final String? gstUrl = gst['certificateUrl'] ?? data['gstCertificateUrl'] ?? gst['gstUrl'] ?? data['gstUrl'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Docs',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildDocItem(
            context,
            'Aadhaar Verification',
            aadhaarNumber != null ? 'Aadhaar: $aadhaarNumber' : 'No Aadhaar details provided',
            LucideIcons.creditCard,
            aadhaarNumber != null,
            url: aadhaarUrl,
          ),
          const SizedBox(height: 12),
          _buildDocItem(
            context,
            'PAN Registration',
            panNumber != null 
                ? 'PAN: $panNumber\nHolder: ${panHolderName ?? "N/A"}' 
                : 'No PAN details provided',
            LucideIcons.creditCard,
            panNumber != null,
            url: panUrl,
          ),
          const SizedBox(height: 12),
          if (isGstApplicable)
            _buildDocItem(
              context,
              'GST Certificate',
              gstNumber != null 
                  ? 'GSTIN: $gstNumber\nBusiness: ${gstBusinessName ?? "N/A"}' 
                  : 'No GST details provided',
              LucideIcons.award,
              gstNumber != null,
              url: gstUrl,
            )
          else
            _buildDocItem(
              context,
              'GST Registration',
              'Not registered under GST (Unregistered)',
              LucideIcons.xCircle,
              true,
              url: null,
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFF86EFAC)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      color: Colors.teal[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vetting Status',
                      style: GoogleFonts.inter(
                        color: Colors.teal[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.teal[900],
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Application status is '),
                      TextSpan(
                        text: (data['status'] ?? 'PENDING').toString().toUpperCase(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            ' and under active compliance review. Background validation checks are ongoing.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool verified, {
    String? url,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (url != null && url.isNotEmpty)
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.eye, color: Color(0xFF2563EB), size: 18),
                  onPressed: () {
                    _showDocumentPreview(context, title, url);
                  },
                  tooltip: 'View Document',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.download, color: Color(0xFF2563EB), size: 18),
                  onPressed: () {
                    js.context.callMethod('open', [url, '_blank']);
                  },
                  tooltip: 'Download Document',
                ),
              ],
            )
          else if (verified)
            const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 20)
          else
            const Icon(
              LucideIcons.alertTriangle,
              color: Color(0xFFEF4444),
              size: 20,
            ),
        ],
      ),
    );
  }

  void _showDocumentPreview(BuildContext context, String docTitle, String url) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                docTitle,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 450),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.fileText, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'Document Preview Unavailable',
                                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        js.context.callMethod('open', [url, '_blank']);
                      },
                      icon: const Icon(LucideIcons.download, size: 16),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectedEarnings(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJECTED EARNINGS (M1)',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹45,000',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '+14% vs avg.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Color(0xFFF1F5F9),
              color: Color(0xFF10B981),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewerConfidence(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REVIEWER CONFIDENCE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
              Icon(Icons.star_half, color: Colors.grey[300], size: 18),
              const SizedBox(width: 12),
              Text(
                '4.2 / 5.0',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionbar(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.history, color: Colors.blueGrey[400], size: 18),
              const SizedBox(width: 8),
              Text(
                'Revision History (3)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),
          Row(
            children: [
              Icon(
                LucideIcons.messageSquare,
                color: Colors.blueGrey[400],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Internal Notes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),
          Row(
            children: [
              const Icon(
                LucideIcons.fileBox,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Generate Dossier',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
