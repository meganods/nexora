import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:urbanvendor/theme/vendor_theme.dart';
import 'package:urbanvendor/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/cloudinary_service.dart';

// Display placement options with pricing
class _PlacementOption {
  final String id;
  final String label;
  final String description;
  final int pricePerDay;
  final IconData icon;
  final Color color;

  const _PlacementOption({
    required this.id,
    required this.label,
    required this.description,
    required this.pricePerDay,
    required this.icon,
    required this.color,
  });
}

const List<_PlacementOption> _placements = [
  _PlacementOption(
    id: 'hero_banner',
    label: 'Hero Banner',
    description: 'Top rotating banner on User Home',
    pricePerDay: 499,
    icon: Icons.image_outlined,
    color: Color(0xFF6366F1),
  ),
  _PlacementOption(
    id: 'featured_section',
    label: 'Featured Section',
    description: 'Highlighted card in "Featured" row',
    pricePerDay: 299,
    icon: Icons.star_outline_rounded,
    color: Color(0xFFF59E0B),
  ),
  _PlacementOption(
    id: 'flash_offers',
    label: 'Flash Offers Strip',
    description: 'Scrollable flash deals strip below categories',
    pricePerDay: 199,
    icon: Icons.bolt_outlined,
    color: Color(0xFFEF4444),
  ),
  _PlacementOption(
    id: 'promo_banner',
    label: 'Mid-Page Promo Banner',
    description: 'Static banner between service sections',
    pricePerDay: 149,
    icon: Icons.campaign_outlined,
    color: Color(0xFF10B981),
  ),
  _PlacementOption(
    id: 'vendor_spotlight',
    label: 'Vendor Spotlight',
    description: 'Your shop highlighted in "Top Professionals"',
    pricePerDay: 249,
    icon: Icons.person_pin_outlined,
    color: Color(0xFF06B6D4),
  ),
];

class VendorCampaignsScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;

  const VendorCampaignsScreen({super.key, this.isTab = false, this.onBack});

  @override
  State<VendorCampaignsScreen> createState() => _VendorCampaignsScreenState();
}

class _VendorCampaignsScreenState extends State<VendorCampaignsScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late TabController _tabController;

  static const _primary = Color(0xFF2563EB);
  static const _accentGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _vendorEmail => _auth.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: _primary,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: _primary,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [Tab(text: '🚀  My Campaigns'), Tab(text: '➕  Create Campaign')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildMyCampaigns(), _buildCreateCampaign()],
          ),
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
            onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          ),
          title: Text('Campaign Management',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: VendorTheme.textPrimary)),
        ),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Campaign Management',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: VendorTheme.textPrimary)),
      ),
      body: content,
    );
  }

  // ─────────────────────────────────────────────────────
  // TAB 1 — MY CAMPAIGNS (live from Firestore)
  // ─────────────────────────────────────────────────────
  Widget _buildMyCampaigns() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vendor_campaigns')
          .where('vendorEmail', isEqualTo: _vendorEmail)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.campaign_outlined, size: 64, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 16),
                Text('No campaigns yet.',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Text('Create your first promotional campaign\nto boost your business visibility!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Create Campaign', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx2, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
            return _campaignCard(d, docId);
          },
        );
      },
    );
  }

  Widget _campaignCard(Map<String, dynamic> d, String docId) {
    final status = d['status'] ?? 'pending';
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = _accentGreen;
        statusLabel = 'Approved & Live';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_outlined;
        break;
      case 'pending_payment':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Payment Required';
        statusIcon = Icons.payment_outlined;
        break;
      default:
        statusColor = const Color(0xFF6366F1);
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_empty_outlined;
    }

    final startDate = d['startDate'] != null ? (d['startDate'] as Timestamp).toDate() : null;
    final endDate = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
    final placements = List<String>.from(d['placements'] ?? []);
    final adminFee = ((d['adminFee'] ?? 0) as num).toDouble();
    final feePaid = d['feePaid'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(statusLabel,
                    style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _campaignTypeColor(d['type'] ?? '').withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(d['type'] ?? 'Campaign',
                      style: GoogleFonts.inter(
                          color: _campaignTypeColor(d['type'] ?? ''), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['name'] ?? 'Campaign',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(d['description'] ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(height: 12),
                if (d['imageUrl'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      d['imageUrl'],
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Placements chips
                if (placements.isNotEmpty) ...[
                  Text('Display Locations:',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: placements.map((p) {
                      final opt = _placements.firstWhere((o) => o.id == p,
                          orElse: () => const _PlacementOption(
                              id: '', label: 'Unknown', description: '', pricePerDay: 0,
                              icon: Icons.place_outlined, color: Color(0xFF64748B)));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: opt.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: opt.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(opt.icon, size: 12, color: opt.color),
                            const SizedBox(width: 4),
                            Text(opt.label, style: GoogleFonts.inter(fontSize: 10, color: opt.color, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                // Date and fee row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      startDate != null && endDate != null
                          ? '${DateFormat('dd MMM').format(startDate)} → ${DateFormat('dd MMM yy').format(endDate)}'
                          : 'Dates TBD',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    if (adminFee > 0) ...[
                      const Icon(Icons.currency_rupee, size: 13, color: Color(0xFF94A3B8)),
                      Text('$adminFee fee',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ],
                ),
                // Rejection reason
                if (status == 'rejected' && d['rejectionReason'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(d['rejectionReason'],
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444))),
                        ),
                      ],
                    ),
                  ),
                ],
                // Pay fee button
                if (status == 'pending_payment' && adminFee > 0 && !feePaid) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _payAdminFee(docId, adminFee, d),
                      icon: const Icon(Icons.payment, color: Colors.white, size: 16),
                      label: Text('Pay ₹${adminFee.toStringAsFixed(0)} to Activate',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _payAdminFee(String docId, double fee, Map<String, dynamic> d) async {
    // Show a payment confirmation dialog (simulate payment)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay Campaign Fee', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campaign: ${d['name']}', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee, color: Color(0xFF10B981), size: 20),
                  Text(fee.toStringAsFixed(0),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 22, color: const Color(0xFF10B981))),
                  const SizedBox(width: 8),
                  Text('Admin Promotion Fee',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('This will be charged from your wallet and your campaign will go live immediately.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('CONFIRM PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('vendor_campaigns').doc(docId).update({
          'feePaid': true,
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) AppSnackbar.show(context, '🎉 Payment successful! Campaign is now live!');
      } catch (e) {
        if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
      }
    }
  }

  // ─────────────────────────────────────────────────────
  // TAB 2 — CREATE CAMPAIGN
  // ─────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'Festival';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final Set<String> _selectedPlacements = {};
  bool _isSubmitting = false;
  String? _campaignImageUrl;
  bool _isUploadingImage = false;

  Future<void> _pickCampaignImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;

      setState(() => _isUploadingImage = true);

      String? url;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        url = await CloudinaryService.uploadImageBytes(
          bytes: bytes,
          fileName: file.name,
          folder: 'urban_company/campaign_banners',
        );
      } else {
        url = await CloudinaryService.uploadImage(
          filePath: file.path,
          folder: 'urban_company/campaign_banners',
        );
      }

      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        if (url != null) {
          _campaignImageUrl = url;
          AppSnackbar.show(context, '🎉 Banner image uploaded successfully!');
        } else {
          AppSnackbar.show(context, 'Banner image upload failed.', isError: true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        AppSnackbar.show(context, 'Error selecting image: $e', isError: true);
      }
    }
  }

  Widget _buildCreateCampaign() {
    final days = _endDate.difference(_startDate).inDays.clamp(1, 9999);
    int totalFee = 0;
    for (final pid in _selectedPlacements) {
      final opt = _placements.firstWhere((o) => o.id == pid, orElse: () => const _PlacementOption(
          id: '', label: '', description: '', pricePerDay: 0, icon: Icons.place_outlined, color: Colors.grey));
      totalFee += opt.pricePerDay * days;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your campaign will be reviewed by admin. Once approved, you\'ll be asked to pay the promotional fee based on your selected display locations.',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Campaign Name
          _label('Campaign Name *'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Diwali Cleaning Mega Sale',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _label('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe your promotional offer to attract users...',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Campaign Banner Image
          _label('Campaign Banner *'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isUploadingImage ? null : _pickCampaignImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _isUploadingImage
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : _campaignImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.network(
                                _campaignImageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: _pickCampaignImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text('Upload Campaign Banner Image', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text('Recommended size: 1200 x 600 px', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 16),

          // Campaign Type
          _label('Campaign Type *'),
          const SizedBox(height: 8),
          StatefulBuilder(
            builder: (ctx, setSt) => Wrap(
              spacing: 10,
              runSpacing: 8,
              children: ['Festival', 'Flash Sale', 'Seasonal', 'Referral', 'Limited Time'].map((t) {
                final selected = _selectedType == t;
                final color = _campaignTypeColor(t);
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      border: Border.all(color: selected ? color : const Color(0xFFE2E8F0), width: selected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(t,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : const Color(0xFF64748B),
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Date Range
          _label('Campaign Duration *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dateTile('Start Date', _startDate, () async {
                  final p = await showDatePicker(context: context, initialDate: _startDate,
                      firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (p != null) setState(() => _startDate = p);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateTile('End Date', _endDate, () async {
                  final p = await showDatePicker(context: context, initialDate: _endDate,
                      firstDate: _startDate, lastDate: DateTime(2030));
                  if (p != null) setState(() => _endDate = p);
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Display Locations
          _label('Where should your campaign appear? *'),
          const SizedBox(height: 4),
          Text('Select one or more display locations in the User App.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          ..._placements.map((opt) {
            final isSelected = _selectedPlacements.contains(opt.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedPlacements.remove(opt.id);
                } else {
                  _selectedPlacements.add(opt.id);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? opt.color.withValues(alpha: 0.07) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? opt.color : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: isSelected ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(opt.icon, color: opt.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt.label,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14,
                                  color: isSelected ? opt.color : VendorTheme.textPrimary)),
                          Text(opt.description,
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${opt.pricePerDay}/day',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13,
                                color: isSelected ? opt.color : VendorTheme.textPrimary)),
                        Text('≈ ₹${opt.pricePerDay * days} total',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? opt.color : Colors.transparent,
                        border: Border.all(color: isSelected ? opt.color : const Color(0xFFCBD5E1), width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),

          // Fee Summary
          if (_selectedPlacements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Promotion Fee',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: _accentGreen)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, color: Color(0xFF10B981), size: 22),
                      Text('$totalFee',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 28, color: _accentGreen)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('for $days day${days > 1 ? 's' : ''} · ${_selectedPlacements.length} location${_selectedPlacements.length > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Final fee confirmed by admin on approval. Payment due after approval.',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitCampaign,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit for Admin Approval',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary));

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                  Text(DateFormat('dd MMM yyyy').format(date),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VendorTheme.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitCampaign() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Campaign name is required', isError: true);
      return;
    }
    if (_selectedPlacements.isEmpty) {
      AppSnackbar.show(context, 'Select at least one display location', isError: true);
      return;
    }

    if (_campaignImageUrl == null) {
      AppSnackbar.show(context, 'Campaign banner image is required', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final vendorSnap = await _firestore.collection('vendors').doc(_vendorEmail).get();
      final vendorData = vendorSnap.data() ?? {};

      final days = _endDate.difference(_startDate).inDays.clamp(1, 9999);
      int estimatedFee = 0;
      for (final pid in _selectedPlacements) {
        final opt = _placements.firstWhere((o) => o.id == pid, orElse: () => const _PlacementOption(
            id: '', label: '', description: '', pricePerDay: 0, icon: Icons.place_outlined, color: Colors.grey));
        estimatedFee += opt.pricePerDay * days;
      }

      await _firestore.collection('vendor_campaigns').add({
        'vendorEmail': _vendorEmail,
        'vendorName': vendorData['ownerName'] ?? vendorData['businessName'] ?? _vendorEmail,
        'businessName': vendorData['businessName'] ?? '',
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'type': _selectedType,
        'imageUrl': _campaignImageUrl,
        'placements': _selectedPlacements.toList(),
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'durationDays': days,
        'estimatedFee': estimatedFee.toDouble(),
        'adminFee': 0.0,
        'feePaid': false,
        'status': 'pending', // pending → pending_payment → approved / rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _selectedType = 'Festival';
        _selectedPlacements.clear();
        _campaignImageUrl = null;
        _startDate = DateTime.now();
        _endDate = DateTime.now().add(const Duration(days: 7));
        _isSubmitting = false;
      });
      _tabController.animateTo(0);
      if (mounted) AppSnackbar.show(context, '🎉 Campaign submitted for review!');
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
    }
  }

  Color _campaignTypeColor(String type) {
    switch (type) {
      case 'Festival': return const Color(0xFFF59E0B);
      case 'Flash Sale': return const Color(0xFFEF4444);
      case 'Referral': return const Color(0xFF10B981);
      case 'Seasonal': return const Color(0xFF06B6D4);
      default: return const Color(0xFF6366F1);
    }
  }
}
