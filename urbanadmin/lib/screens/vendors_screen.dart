import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'package:intl/intl.dart';

class VendorsScreen extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onVendorSelected;

  const VendorsScreen({super.key, this.onVendorSelected});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  // Mock data removed in favor of Firestore stream

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildStatSummary(),
        const SizedBox(height: 32),
        _buildFilters(),
        const SizedBox(height: 32),
        _buildVendorTable(),
      ],
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendor Ecosystem',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage, verify, and monitor your service partners at scale.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.blueGrey[400],
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.plus, size: 18),
          label: Text(
            'Register New Vendor',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4C1D95), // Deep purple as shown
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatSummary() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard(
            'TOTAL VENDORS',
            '1,284',
            '+4.2%',
            Icons.storefront_rounded,
            const Color(0xFF6366F1),
            const Color(0xFF10B981),
          ),
          const SizedBox(width: 20),
          _buildStatCard(
            'ACTIVE PARTNERS',
            '1,102',
            '+12%',
            Icons.verified_user_rounded,
            const Color(0xFF10B981),
            const Color(0xFF10B981),
          ),
          const SizedBox(width: 20),
          _buildStatCard(
            'PENDING REVIEW',
            '42',
            '+8',
            Icons.pending_rounded,
            const Color(0xFFF59E0B),
            const Color(0xFFEF4444),
          ),
          const SizedBox(width: 20),
          _buildStatCard(
            'BLOCKED',
            '14',
            '-2',
            Icons.block_rounded,
            const Color(0xFFEF4444),
            Colors.blueGrey[400]!,
          ),
          const SizedBox(width: 20),
          _buildStatCard(
            'TOP RATED',
            '85',
            '+5',
            Icons.star_rounded,
            const Color(0xFFEC4899),
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String trend,
    IconData icon,
    Color iconColor,
    Color trendColor,
  ) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[300],
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trend,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light grey background
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDropdownBtn('All Statuses', LucideIcons.listFilter),
            const SizedBox(width: 16),
            _buildDropdownBtn('All Categories', LucideIcons.shapes),
            const SizedBox(width: 24),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filters cleared')),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                'Clear Filters',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4C1D95),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownBtn(String label, IconData icon) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filtering by $label...')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blueGrey[400]),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 24),
            Icon(LucideIcons.chevronDown, size: 16, color: Colors.blueGrey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1000,
          child: Column(
            children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 32,
              right: 32,
              top: 32,
              bottom: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('VENDOR NAME', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('CATEGORY', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('ONBOARDED DATE', style: _headerStyle()),
                ),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle())),
                Expanded(
                  flex: 1,
                  child: Text(
                    'ACTIONS',
                    textAlign: TextAlign.right,
                    style: _headerStyle(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          StreamBuilder<QuerySnapshot>(
            stream: Provider.of<AdminProvider>(context).vendorApplicationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Text(
                      'No active vendors found',
                      style: GoogleFonts.poppins(color: Colors.blueGrey[400]),
                    ),
                  ),
                );
              }

              // Filter for APPROVED vendors
              final activeVendors = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'APPROVED';
              }).toList();

              if (activeVendors.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Text(
                      'No active vendors found',
                      style: GoogleFonts.poppins(color: Colors.blueGrey[400]),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeVendors.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final doc = activeVendors[index];
                  final vendor = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;
                  
                  // Handle date formatting
                  String formattedDate = 'N/A';
                  if (vendor['createdAt'] != null) {
                    try {
                      final dt = DateTime.parse(vendor['createdAt']);
                      formattedDate = DateFormat('MMM dd, yyyy').format(dt);
                    } catch (e) {
                      formattedDate = vendor['createdAt'].toString();
                    }
                  }

                  return InkWell(
                    onTap: () => widget.onVendorSelected?.call(vendor),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF0F172A),
                                  child: Text(
                                    vendor['name'] != null && vendor['name'].isNotEmpty ? vendor['name'][0] : '?',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendor['name'] ?? 'N/A',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: ${docId.substring(0, 8).toUpperCase()}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.blueGrey[400],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  vendor['mainCategory'] ?? 'N/A',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF334155),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formattedDate,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Active',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF059669),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                LucideIcons.moreHorizontal,
                                size: 18,
                                color: Colors.blueGrey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    ),
  ),
);
}

  TextStyle _headerStyle() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.blueGrey[300],
    letterSpacing: 1.0,
  );




}
