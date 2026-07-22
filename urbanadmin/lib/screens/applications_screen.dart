import 'package:urbanadmin/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class ApplicationsScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onViewDetails;

  const ApplicationsScreen({super.key, this.onViewDetails});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  // Mock data removed in favor of Firestore stream

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildFilters(),
        const SizedBox(height: 24),
        _buildTable(),
        const SizedBox(height: 32),
        _buildBottomStats(),
      ],
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendor Applications',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D9488),
                      shape: BoxShape.circle,
                    ),
                  ), // Teal dot
                  const SizedBox(width: 8),
                  Text(
                    '14 pending review',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '•   Priority Queue: High',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildStatusToggle(),
      ],
    );
  }

  String _selectedStatus = 'All';

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('All'),
          _buildToggleOption('Pending'),
          _buildToggleOption('Archived'),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label) {
    final isActive = _selectedStatus == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = label;
        });
        AppSnackbar.show(context, 'Viewing $label applications');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
              : [],
          border: isActive
              ? Border.all(color: const Color(0xFFE2E8F0), width: 0.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF4C1D95) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        if (isMobile) {
          return Column(
            children: [
              _buildFilterItem('CATEGORY', 'All Services', LucideIcons.triangle),
              const SizedBox(height: 16),
              _buildFilterItem('CITY', 'Global Locations', LucideIcons.mapPin),
              const SizedBox(height: 16),
              _buildAdvancedFilterItem(),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildFilterItem('CATEGORY', 'All Services', LucideIcons.triangle)),
            const SizedBox(width: 16),
            Expanded(child: _buildFilterItem('CITY', 'Global Locations', LucideIcons.mapPin)),
            const SizedBox(width: 16),
            Expanded(child: _buildAdvancedFilterItem()),
          ],
        );
      },
    );
  }

  Widget _buildFilterItem(String label, String value, IconData icon) {
    return InkWell(
      onTap: () {
        AppSnackbar.show(context, 'Filtering applications by $label...');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6D28D9),
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: Colors.blueGrey[300],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilterItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
               AppSnackbar.show(context, 'Opening advanced filters...');
            },
            icon: const Icon(
              LucideIcons.listFilter,
              color: Color(0xFF6D28D9),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Advanced Filters',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              AppSnackbar.show(context, 'All filters reset');
            },
            child: Text(
              'RESET ALL',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6D28D9),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1100,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('APPLICANT NAME', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('CATEGORY', style: _headerStyle()),
                ),
                Expanded(
                  flex: 2,
                  child: Text('LOCATION', style: _headerStyle()),
                ),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle())),
                Expanded(
                  flex: 3,
                  child: Text(
                    'QUICK ACTIONS',
                    textAlign: TextAlign.right,
                    style: _headerStyle(),
                  ),
                ),
              ],
            ),
          ),
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

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Text(
                      'No applications found',
                      style: GoogleFonts.poppins(color: Colors.blueGrey[400]),
                    ),
                  ),
                );
              }

              // Filter based on selected tab
              final apps = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String rawStatus = data['status'] ?? '';
                String status = rawStatus.toUpperCase().trim();
                
                if (_selectedStatus == 'Pending') {
                  return status == 'PENDING';
                } else if (_selectedStatus == 'Archived') {
                  return status == 'APPROVED' || status == 'REJECTED';
                } else {
                  // 'All' tab shows everything
                  return status.isNotEmpty;
                }
              }).toList();

              if (apps.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Text(
                      'No $_selectedStatus applications',
                      style: GoogleFonts.poppins(color: Colors.blueGrey[400]),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: apps.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final doc = apps[index];
                  final app = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFEEF2FF),
                                child: Text(
                                  app['name'] != null && app['name'].isNotEmpty ? app['name'][0] : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4C1D95),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app['name'] ?? 'N/A',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        app['email'] ?? 'N/A',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
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
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                app['mainCategory'] ?? 'N/A',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6D28D9),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            app['address'] != null ? 
                              (app['address'].toString().length > 20 ? 
                                '${app['address'].toString().substring(0, 20)}...' : 
                                app['address']) : 'N/A',
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
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6B7280),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    app['status'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6B7280),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => widget.onViewDetails?.call(app),
                                child: Icon(
                                  LucideIcons.eye,
                                  color: Colors.blueGrey[400],
                                  size: 20,
                                ),
                              ),
                              if (app['status'] == 'PENDING') ...[
                                const SizedBox(width: 24),
                                InkWell(
                                    onTap: () async {
                                      final success = await Provider.of<AdminProvider>(context, listen: false).approveVendor(docId);
                                      if (!context.mounted) return;
                                      AppSnackbar.show(context, success ? 'Vendor Approved Successfully' : 'Failed to Approve Vendor', isError: true);
                                    },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488), // Teal
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF0D9488,
                                          ).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Approve',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    final success = await Provider.of<AdminProvider>(context, listen: false).rejectVendor(docId);
                                    if (!context.mounted) return;
                                    AppSnackbar.show(context, success ? 'Vendor Rejected' : 'Failed to Reject Vendor', isError: true);
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626), // Red
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFDC2626,
                                          ).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Reject',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(width: 24),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check_circle_outline, color: Colors.blueGrey[300], size: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PROCESSED',
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[300]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          ],
        ),
      ),
    ),
  );
}

  TextStyle _headerStyle() => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.blueGrey[400],
    letterSpacing: 1.0,
  );



  Widget _buildBottomStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        if (isMobile) {
          return Column(
            children: [
              _buildStatCard(
                'APPLICATION VELOCITY',
                '+24%',
                'vs. Previous Month',
                const Color(0xFF10B981),
                const Color(0xFFE9D5FF),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'AVG. APPROVAL TIME',
                '1.2 Days',
                'Industry Leading Speed',
                const Color(0xFF4C1D95),
                const Color(0xFFD1FAE5),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'REJECTION RATE',
                '8.4%',
                'Maintaining High Standards',
                const Color(0xFF1E293B),
                const Color(0xFFFECDD3),
              ),
            ],
          );
        }
        return Row(
          children: [
            _buildStatCard(
              'APPLICATION VELOCITY',
              '+24%',
              'vs. Previous Month',
              const Color(0xFF10B981),
              const Color(0xFFE9D5FF),
            ),
            const SizedBox(width: 24),
            _buildStatCard(
              'AVG. APPROVAL TIME',
              '1.2 Days',
              'Industry Leading Speed',
              const Color(0xFF4C1D95),
              const Color(0xFFD1FAE5),
            ),
            const SizedBox(width: 24),
            _buildStatCard(
              'REJECTION RATE',
              '8.4%',
              'Maintaining High Standards',
              const Color(0xFF1E293B),
              const Color(0xFFFECDD3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color mainValueColor,
    Color blobColor,
  ) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 140,
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: blobColor.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[300],
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        height: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mainValueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
