import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  double _platformTakeRate = 15.0;
  List<dynamic> _pendingPayouts = [];
  bool _isLoadingPayouts = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingPayouts();
  }

  Future<void> _fetchPendingPayouts() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/payouts/admin-pending'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success']) {
          setState(() {
            _pendingPayouts = data['withdrawals'];
            _isLoadingPayouts = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoadingPayouts = false);
    }
  }

  Future<void> _approvePayout(String withdrawalId) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/payouts/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'withdrawalId': withdrawalId}),
      );
      if (res.statusCode == 200) {
        _showTopRightToast('Payout approved successfully!');
        _fetchPendingPayouts();
      } else {
        _showTopRightToast('Failed to approve payout.');
      }
    } catch (e) {
      _showTopRightToast('Error approving payout.');
    }
  }

  // Custom Overlay toast notification on top-right side
  void _showTopRightToast(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.wallet, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          _buildKpis(),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1100) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 12, child: _buildGlobalCommissionCard()),
                    const SizedBox(width: 28),
                    Expanded(flex: 16, child: _buildVendorPerformanceCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildGlobalCommissionCard(),
                    const SizedBox(height: 28),
                    _buildPendingPayoutsCard(),
                    const SizedBox(height: 28),
                    _buildVendorPerformanceCard(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),
          _buildFooterAlert(),
        ],
      ),
    );
  }

  // 1. Title Header Row
  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Oversight',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time revenue monitoring and commission management.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Export Report Button
        OutlinedButton.icon(
          onPressed: () {
            _showTopRightToast('Exporting financial statement report...');
          },
          icon: const Icon(LucideIcons.download, size: 16),
          label: Text('Export Report', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 12),
        // Mark True Session Button
        ElevatedButton.icon(
          onPressed: () {
            _showTopRightToast('Session successfully synchronized and audited.');
          },
          icon: const Icon(LucideIcons.checkCircle, size: 16),
          label: Text('Mark True Session', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // 2. Four KPI Oversight Cards
  Widget _buildKpis() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - (18 * 3)) / 4;
        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            _buildChartKpiCard(width),
            _buildStandardKpiCard(
              title: 'EARNINGS (NET PAYOUT)',
              value: '₹192,675.36',
              subtitle: '▲ 12.5% vs last 30 days',
              subColor: const Color(0xFF2563EB),
              icon: LucideIcons.wallet,
              iconBgColor: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              width: width,
            ),
            _buildStandardKpiCard(
              title: 'VENDOR PAYOUTS',
              value: '₹1,091,827.04',
              subtitle: 'Completed for today',
              subColor: const Color(0xFF10B981),
              icon: LucideIcons.users,
              iconBgColor: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF10B981),
              width: width,
              hasCheck: true,
            ),
            _buildStandardKpiCard(
              title: 'NET PROFIT',
              value: '₹124,500.00',
              subtitle: 'Profit rate ▲ 9.87%',
              subColor: const Color(0xFF10B981),
              icon: LucideIcons.trendingUp,
              iconBgColor: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF10B981),
              width: width,
            ),
          ],
        );
      },
    );
  }

  // Revenue KPI with Mini Bar Chart inside
  Widget _buildChartKpiCard(double width) {
    return Container(
      width: width.clamp(240.0, double.infinity),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL PLATFORM REVENUE',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '▲ 14.2%',
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹1,284,502.40',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          // Mini bar chart
          SizedBox(
            height: 48,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(18, false),
                _buildBar(34, false),
                _buildBar(24, false),
                _buildBar(38, false),
                _buildBar(14, false),
                _buildBar(44, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, bool isFeatured) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: isFeatured ? const Color(0xFF2563EB) : const Color(0xFF93C5FD),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildStandardKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required double width,
    bool hasCheck = false,
  }) {
    return Container(
      width: width.clamp(240.0, double.infinity),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasCheck) ...[
                const Icon(LucideIcons.checkCircle, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: subColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Global Commission Card (Left)
  Widget _buildGlobalCommissionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Commission',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Update the platform\'s cut for all matched vendor services.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          // Large Rate selector container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLATFORM TAKE RATE',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_platformTakeRate.toStringAsFixed(1)} %',
                        style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
                // + and - control buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_platformTakeRate < 100.0) _platformTakeRate += 0.5;
                          });
                        },
                        icon: const Icon(LucideIcons.plus, size: 16, color: Color(0xFF2563EB)),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const Divider(height: 12),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_platformTakeRate > 0.0) _platformTakeRate -= 0.5;
                          });
                        },
                        icon: const Icon(LucideIcons.minus, size: 16, color: Color(0xFF64748B)),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Transaction Fee', '2.50% + 2.5K'),
          const SizedBox(height: 16),
          _buildInfoRow('Marketing Fee', 'Included', valueColor: const Color(0xFF10B981)),
          const SizedBox(height: 24),
          // Apply changes button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                _showTopRightToast('Platform rate successfully updated to ${_platformTakeRate.toStringAsFixed(1)}%!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('Apply Rate Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, color: valueColor ?? const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 4. Vendor Performance Card (Right)
  Widget _buildVendorPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendor Performance',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 24),
          // Table layout
          Row(
            children: [
              Expanded(flex: 3, child: Text('SERVICE PARTNER', style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text('GROSS SALES', style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text('PLATFORM CUT', style: _tableHeaderStyle())),
              Expanded(flex: 2, child: Text('PAYOUT STATUS', style: _tableHeaderStyle())),
              const SizedBox(width: 32),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildPerformanceRow('Luxe Garden Services', 'Home & Gardening', '₹42,566.03', '-₹6,245.89', 'PROCESSED'),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildPerformanceRow('Elite Logistics Pro', 'Packers & Transport', '₹36,820.19', '-₹5,732.81', 'PENDING'),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildPerformanceRow('Prime Cleaning Crew', 'Home Cleaning', '₹31,492.00', '-₹4,930.02', 'PROCESSED'),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          _buildPerformanceRow('Gourmet Guild', 'Home Catering', '₹24,600.06', '-₹3,660.00', 'PROCESSED'),
          const SizedBox(height: 24),
          // View all partners button
          Center(
            child: TextButton(
              onPressed: () {
                _showTopRightToast('Redirecting to full partner lists...');
              },
              child: Text(
                'VIEW ALL PARTNERS',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPendingPayoutsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pending Cashfree Payouts', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 24),
          if (_isLoadingPayouts) const Center(child: CircularProgressIndicator())
          else if (_pendingPayouts.isEmpty) Center(child: Text("No pending payout requests.", style: GoogleFonts.inter(color: Colors.grey)))
          else ..._pendingPayouts.map((p) => _buildPayoutRow(p)).toList(),
        ],
      ),
    );
  }

  Widget _buildPayoutRow(dynamic payout) {
    final amt = payout['amount']?.toString() ?? '0';
    final method = payout['method'] ?? 'Bank';
    final vendor = payout['vendorId']?.substring(0, 8) ?? 'Vendor';
    final wId = payout['id'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vendor: $vendor...', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Method: $method', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text('₹$amt', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), fontSize: 16)),
          ElevatedButton(
            onPressed: () => _approvePayout(wId),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(
    String name,
    String category,
    String gross,
    String cut,
    String status,
  ) {
    return Row(
      children: [
        // Avatar + Name column
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.briefcase, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    Text(category, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Gross Sales
        Expanded(
          flex: 2,
          child: Text(gross, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        ),
        // Platform Cut
        Expanded(
          flex: 2,
          child: Text(cut, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
        ),
        // Status Pill
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'PROCESSED' ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: status == 'PROCESSED' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'PROCESSED' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Actions
        IconButton(
          onPressed: () {
            _showTopRightToast('Actions opened for $name');
          },
          icon: const Icon(LucideIcons.moreVertical, size: 16, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  TextStyle _tableHeaderStyle() => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      );

  // 5. Monthly Reconciliation Footer Alert
  Widget _buildFooterAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.barChart2, color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Reconciliation Active',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                'Last audit completed on October 25th, 2023.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              _showTopRightToast('Quarterly audit report successfully generated.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Generate Quarterly Audit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
