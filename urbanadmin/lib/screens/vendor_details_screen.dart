import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          // Ensure ID is preserved if Firestore doc doesn't have it explicitly
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
                  Expanded(flex: 10, child: _buildRightColumn(data)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftColumn(isWide, data),
                  const SizedBox(height: 32),
                  _buildRightColumn(data),
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
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Text(
            'Vendors',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blueGrey[400],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(LucideIcons.chevronRight, size: 14, color: Colors.blueGrey[300]),
        const SizedBox(width: 8),
        Text(
          'Partner Onboarding',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey[400]),
        ),
        const SizedBox(width: 8),
        Icon(LucideIcons.chevronRight, size: 14, color: Colors.blueGrey[300]),
        const SizedBox(width: 8),
        Text(
          'Application #${data['id'] ?? 'VP-8829'}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4C1D95),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isWide, Map<String, dynamic> data) {
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
                data['name'] ?? 'Arjun Malhotra',
                style: GoogleFonts.poppins(
                  fontSize: isWide ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  height: 1.2,
                ),
              ),
              Text(
                data['category'] ?? 'Premium Urban Maintenance Partner',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blueGrey[400],
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
              child: Text('Reject Application', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4C1D95),
                side: const BorderSide(color: Color(0xFFC4B5FD)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Request Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C1D95),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Approve Vendor', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                      child: Icon(LucideIcons.user, size: 40, color: Color(0xFF4C1D95)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF67E8F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['status'] ?? 'VERIFIED',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF134E4A),
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
                        data['email'] ?? 'arjun.malhotra@urbanpro.com',
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: _buildInfoItem('PHONE NUMBER', data['phone'] ?? '+91 98765 43210'),
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
                        data['registrationDate'] ?? 'Oct 24, 2023',
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: _buildInfoItem('EXPERIENCE', data['experience'] ?? '12 Years'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoItem(
                  'OFFICE ADDRESS',
                  data['address'] ?? 'Suite 402, Skyline Business Park, Koramangala 5th Block,\nBengaluru, KA 560095',
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
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[300],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
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
          colors: [Colors.green[100]!.withValues(alpha: 0.4), Colors.grey[200]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Simulated Map Graphic
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 100,
              color: Colors.green[800]!.withValues(alpha: 0.1),
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
                    color: Color(0xFF4C1D95),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Operational Radius: 15km (Bengaluru Central)',
                    style: GoogleFonts.poppins(
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
    return Container(
      height: 200,
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(
                LucideIcons.penTool,
                color: Color(0xFF4C1D95),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildServiceRow('Standard Pipe Repair', '₹850'),
              _buildServiceRow('Whole Room Revamp', ' '),
              _buildServiceRow('Emergency Leak Control', '₹1,200'),
            ],
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
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4C1D95),
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
        color: const Color(0xFFF3E8FF), // Light purple
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Commission',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF4C1D95),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '12%',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4C1D95),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PREMIUM TIER RATE',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7E22CE),
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Text(
            'Rewards program based on historical certificate validation.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF6B21A8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildComplianceDocs(data),
        const SizedBox(height: 24),
        _buildProjectedEarnings(data),
        const SizedBox(height: 24),
        _buildReviewerConfidence(data),
      ],
    );
  }

  Widget _buildComplianceDocs(Map<String, dynamic> data) {
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
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildDocItem(
            'Aadhaar Card',
            'Verified • 1.2MB',
            LucideIcons.creditCard,
            true,
          ),
          const SizedBox(height: 12),
          _buildDocItem(
            'PAN Registration',
            'Verified • 0.8MB',
            LucideIcons.creditCard,
            true,
          ),
          const SizedBox(height: 12),
          _buildDocItem(
            'ISO Certificate',
            'Action Required • 2.4MB',
            LucideIcons.award,
            false,
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
                      style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.teal[900],
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Background check via '),
                      TextSpan(
                        text: 'ThirdPartyAudit Co.',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            ' cleared on Oct 28. No criminal record found in regional jurisdiction.',
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
    String title,
    String subtitle,
    IconData icon,
    bool verified,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4C1D95), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ],
            ),
          ),
          if (verified)
            Icon(LucideIcons.eye, color: Colors.blueGrey[400], size: 20)
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
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[300],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹45,000',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '+14% vs avg.',
                  style: GoogleFonts.poppins(
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
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF10B981),
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
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[300],
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
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
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
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
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
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
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
                color: Color(0xFF4C1D95),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Generate Dossier',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4C1D95),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
