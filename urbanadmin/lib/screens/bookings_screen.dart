import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final List<Map<String, dynamic>> _bookings = [
    {
      'id': '#BK-9402',
      'customerInitials': 'ED',
      'customerName': 'Eleanor\nDonahue',
      'customerColor': const Color(0xFFF3E8FF),
      'customerTextColor': const Color(0xFF6B21A8),
      'vendor': 'SwiftFix\nSolutions',
      'services': ['HVAC', 'REPAIR'],
      'status': 'COMPLETED',
      'statusColor': const Color(0xFF10B981),
      'date': 'Oct 24,\n2023',
    },
    {
      'id': '#BK-9388',
      'customerInitials': 'JM',
      'customerName': 'Julian\nMartinez',
      'customerColor': const Color(0xFFCCFBF1),
      'customerTextColor': const Color(0xFF0F766E),
      'vendor': 'VoltMaster\nElectric',
      'services': ['PANEL', 'UPGRADE'],
      'status': 'PENDING',
      'statusColor': const Color(0xFF8B5CF6),
      'date': 'Oct 26,\n2023',
    },
    {
      'id': '#BK-9371',
      'customerInitials': 'SA',
      'customerName': 'Sarah Al-\nFayed',
      'customerColor': const Color(0xFFFCE7F3),
      'customerTextColor': const Color(0xFFBE185D),
      'vendor': 'AquaLine\nPlumbing',
      'services': ['LEAK', 'DETECTION'],
      'status': 'CANCELLED',
      'statusColor': const Color(0xFFEF4444),
      'date': 'Oct 21,\n2023',
    },
    {
      'id': '#BK-9365',
      'customerInitials': 'TB',
      'customerName': 'Thomas\nBaxter',
      'customerColor': const Color(0xFFDBEAFE),
      'customerTextColor': const Color(0xFF1D4ED8),
      'vendor': 'GreenScape\nLandscaping',
      'services': ['LAWN CARE'],
      'status': 'COMPLETED',
      'statusColor': const Color(0xFF10B981),
      'date': 'Oct 20,\n2023',
    },
    {
      'id': '#BK-9340',
      'customerInitials': 'LH',
      'customerName': 'Lydia\nHuang',
      'customerColor': const Color(0xFFFEF3C7),
      'customerTextColor': const Color(0xFFB45309),
      'vendor': 'Elite Cleaning Co.',
      'services': ['DEEP CLEAN'],
      'status': 'COMPLETED',
      'statusColor': const Color(0xFF10B981),
      'date': 'Oct 18,\n2023',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildFilterAndVolume(),
        const SizedBox(height: 32),
        _buildTable(),
        const SizedBox(height: 32),
        _buildBottomStats(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.blueGrey[400],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Colors.blueGrey[300],
              ),
              const SizedBox(width: 8),
              Text(
                'Booking Management',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4C1D95),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservations & Flow',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage, filter and audit all service requests across the platform.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.download, size: 16),
                  label: Text(
                    'Export CSV',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4C1D95),
                    side: const BorderSide(color: Color(0xFFC4B5FD)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: Text(
                    'Manual Booking',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C1D95),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterAndVolume() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;
        if (isMobile) {
          return Column(
            children: [
              _buildFilterSection(),
              const SizedBox(height: 24),
              _buildVolumeCard(),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _buildFilterSection()),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: _buildVolumeCard()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _buildFilterChip(
              LucideIcons.calendar,
              'Date Range: ',
              'Oct 01, 2023 - Oct 31, 2023',
            ),
            _buildFilterChip(
              LucideIcons.listFilter,
              'Status: ',
              'All Statuses',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _buildFilterChip(
              LucideIcons.briefcase,
              'Category: ',
              'All Services',
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Clear All',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4C1D95),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(IconData icon, String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
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
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            val,
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

  Widget _buildVolumeCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4C1D95),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(
                LucideIcons.receipt,
                size: 120,
                color: Colors.white12,
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
                  'TOTAL VOLUME',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[200],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1,284',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.trendingUp,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+12% vs last month',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ],
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
          width: 1200,
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
                      flex: 2,
                      child: Text('BOOKING ID', style: _headerStyle()),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('CUSTOMER', style: _headerStyle()),
                    ),
                    Expanded(flex: 3, child: Text('VENDOR', style: _headerStyle())),
                    Expanded(
                      flex: 3,
                      child: Text('SERVICE', style: _headerStyle()),
                    ),
                    Expanded(flex: 2, child: Text('STATUS', style: _headerStyle())),
                    Expanded(flex: 2, child: Text('DATE', style: _headerStyle())),
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bookings.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final b = _bookings[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            b['id'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4C1D95),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: b['customerColor'],
                                child: Text(
                                  b['customerInitials'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: b['customerTextColor'],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  b['customerName'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            b['vendor'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blueGrey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: (b['services'] as List<String>)
                                .map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      s,
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[700],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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
                                color: (b['statusColor'] as Color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: b['statusColor'],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    b['status'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: b['statusColor'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            b['date'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.moreHorizontal,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.blueGrey[300],
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
                'Average Response',
                '14.2 min',
                'TARGET: UNDER 20 MIN',
                LucideIcons.timer,
                const Color(0xFF4C1D95),
                LucideIcons.clock,
                const Color(0xFF4C1D95),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Fulfillment Rate',
                '98.4%',
                'INDUSTRY AVG: 92%',
                LucideIcons.checkCircle2,
                const Color(0xFF0D9488),
                LucideIcons.shieldCheck,
                const Color(0xFF0D9488),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Dispute Ratio',
                '0.8%',
                'LOWER THAN LAST WK',
                LucideIcons.xCircle,
                const Color(0xFFDC2626),
                LucideIcons.alertTriangle,
                const Color(0xFFDC2626),
              ),
            ],
          );
        }
        return Row(
          children: [
            _buildStatCard(
              'Average Response',
              '14.2 min',
              'TARGET: UNDER 20 MIN',
              LucideIcons.timer,
              const Color(0xFF4C1D95),
              LucideIcons.clock,
              const Color(0xFF4C1D95),
            ),
            const SizedBox(width: 24),
            _buildStatCard(
              'Fulfillment Rate',
              '98.4%',
              'INDUSTRY AVG: 92%',
              LucideIcons.checkCircle2,
              const Color(0xFF0D9488),
              LucideIcons.shieldCheck,
              const Color(0xFF0D9488),
            ),
            const SizedBox(width: 24),
            _buildStatCard(
              'Dispute Ratio',
              '0.8%',
              'LOWER THAN LAST WK',
              LucideIcons.xCircle,
              const Color(0xFFDC2626),
              LucideIcons.alertTriangle,
              const Color(0xFFDC2626),
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
    IconData icon,
    Color mainColor,
    IconData watermark,
    Color color,
  ) {
    return Expanded(
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: 10,
              top: 10,
              child: Icon(watermark, size: 80, color: Colors.grey[200]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[400],
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
