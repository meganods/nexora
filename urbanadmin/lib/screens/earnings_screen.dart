import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final List<Map<String, dynamic>> _vendors = [
    {
      'name': 'Luxe Garden Services',
      'category': 'Outdoor Maintenance',
      'sales': '₹42,500.00',
      'cut': '-₹6,375.00',
      'status': 'PROCESSED',
      'statusColor': const Color(0xFF10B981),
      'avatarBg': const Color(0xFF1E293B),
    },
    {
      'name': 'Elite Logistics Pro',
      'category': 'Premium Transport',
      'sales': '₹38,120.50',
      'cut': '-₹5,718.08',
      'status': 'PENDING',
      'statusColor': const Color(0xFFEF4444),
      'avatarBg': const Color(0xFF0F172A),
    },
    {
      'name': 'Prism Concierge Care',
      'category': 'Housekeeping',
      'sales': '₹19,400.00',
      'cut': '-₹2,910.00',
      'status': 'PROCESSED',
      'statusColor': const Color(0xFF10B981),
      'avatarBg': const Color(0xFF334155),
    },
    {
      'name': 'Gourmet Guild',
      'category': 'Private Dining',
      'sales': '₹64,000.00',
      'cut': '-₹9,600.00',
      'status': 'PROCESSED',
      'statusColor': const Color(0xFF10B981),
      'avatarBg': const Color(0xFFF1F5F9),
      'iconDark': true,
    },
  ];

  double _platformTakeRate = 15.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildTopStats(),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 1100;
            if (isMobile) {
              return Column(
                children: [
                  _buildGlobalCommission(),
                  const SizedBox(height: 24),
                  _buildVendorPerformance(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildGlobalCommission()),
                const SizedBox(width: 24),
                Expanded(flex: 11, child: _buildVendorPerformance()),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        _buildBottomBanner(),
      ],
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 24,
      runSpacing: 24,
      children: [
        SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Oversight',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Real-time revenue monitoring and commission management.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.blueGrey[400],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting financial report...')),
                );
              },
              icon: const Icon(Icons.file_download_rounded, size: 16),
              label: Text(
                'Export Report',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4C1D95),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening transaction portal...')),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'New Transaction',
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
    );
  }

  Widget _buildTopStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildVolumeCard(),
          const SizedBox(width: 24),
          _buildStatCard(
            'COMMISSION EARNED',
            '₹192,675.36',
            'Avg. 15% per service',
            Icons.account_balance_wallet_rounded,
            const Color(0xFF6D28D9),
          ),
          const SizedBox(width: 24),
          _buildStatCard(
            'VENDOR PAYOUTS',
            '₹1,091,827.04',
            'Scheduled for Friday',
            Icons.payments_rounded,
            const Color(0xFF0D9488),
            isCheck: true,
          ),
          const SizedBox(width: 24),
          _buildStatCard(
            'NET PROFIT',
            '₹124,500.00',
            'Post-tax estimation',
            Icons.trending_up_rounded,
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard() {
    return Container(
      width: 450,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF5FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 32,
            right: 32,
            child: LayoutBuilder(
              builder: (context, box) {
                double barWidth = box.maxWidth / 8;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBar(60, 0.2, barWidth),
                    _buildBar(80, 0.3, barWidth),
                    _buildBar(70, 0.25, barWidth),
                    _buildBar(100, 0.4, barWidth),
                    SizedBox(width: barWidth),
                    _buildBar(140, 0.6, barWidth),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL PLATFORM VOLUME',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[300],
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Color(0xFF059669),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+12.4%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₹1,284,502.40',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, double opacity, double width) {
    return Container(
      width: width.clamp(12.0, 36.0),
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF9333EA).withValues(alpha: opacity),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String val,
    String sub,
    IconData icon,
    Color color, {
    bool isCheck = false,
  }) {
    return Container(
      width: 300,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[300],
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              if (isCheck) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 14,
                ),
                const SizedBox(width: 6),
              ],
              Text.rich(
                TextSpan(
                  children: [
                    if (!isCheck)
                      TextSpan(
                        text: '${sub.split(' ')[0]} ',
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    if (!isCheck)
                      TextSpan(
                        text: '${sub.split(' ')[1]} ',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!isCheck)
                      TextSpan(
                        text: sub.split(' ').skip(2).join(' '),
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    if (isCheck)
                      TextSpan(
                        text: sub,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                  ],
                ),
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCommission() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFF4C1D95)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Commission',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Update the platform's cut for all standard vendor services.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blueGrey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLATFORM TAKE RATE',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[400],
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                _platformTakeRate.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4C1D95),
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '%',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[400],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: Color(0xFF4C1D95),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _platformTakeRate = (_platformTakeRate + 0.5).clamp(0.0, 50.0);
                                        });
                                      },
                                    ),
                                    Container(
                                      height: 1,
                                      width: 24,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_rounded,
                                        size: 16,
                                        color: Colors.blueGrey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _platformTakeRate = (_platformTakeRate - 0.5).clamp(0.0, 50.0);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFeeRow('Transaction Fee', '₹0.30 + 2.9%'),
                    const SizedBox(height: 16),
                    _buildFeeRow('Marketing Fee', 'Included', isGreen: true),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Take rate updated to ${_platformTakeRate.toStringAsFixed(1)}%')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C1D95),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply Rate Changes',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String val, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueGrey[600]),
        ),
        Text(
          val,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF0D9488) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorPerformance() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vendor Performance',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('SERVICE PARTNER', style: _headerStyle()),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('GROSS SALES', style: _headerStyle()),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('PLATFORM CUT', style: _headerStyle()),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('PAYOUT STATUS', style: _headerStyle()),
                        ),
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
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vendors.length,
                    itemBuilder: (context, index) {
                      final v = _vendors[index];
                      return Padding(
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
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: v['avatarBg'],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.business_center_rounded,
                                      color: v['iconDark'] == true
                                          ? Colors.blueGrey[800]
                                          : Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        v['category'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.blueGrey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                v['sales'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                v['cut'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4C1D95),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (v['statusColor'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: v['statusColor'],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        v['status'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: v['statusColor'],
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(
                                  Icons.more_vert_rounded,
                                  size: 18,
                                  color: Colors.blueGrey,
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
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Text(
              'VIEW ALL PARTNERS',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4C1D95),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.blueGrey[300],
    letterSpacing: 1.0,
  );

  Widget _buildBottomBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 20,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF4C1D95),
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Reconciliation Active',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last audit completed on October 24th, 2023.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488), // Teal green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              'Generate Quarterly Audit',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
