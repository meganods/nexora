import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  bool _isLoading = true;
  String _referralCode = 'NEXORA8X5P2';
  String _referralLink = 'https://nexora.app/invite?ref=NEXORA8X5P2';

  // Configurable Campaign Rewards (Admin config loaded from Firestore)
  double _rewardAmount = 100.0;
  double _friendDiscount = 100.0;

  // Track which platforms were used to share
  final Set<String> _sharedPlatforms = {};

  final List<Map<String, dynamic>> _fallbackReferrals = [
    {
      'id': 'ref_user_1',
      'fullName': 'Aman Sharma',
      'status': 'Completed',
      'rewardAmount': 100.0,
      'createdAt': '28 Jul 2026',
      'sharedVia': 'WhatsApp',
    },
    {
      'id': 'ref_user_2',
      'fullName': 'Karan Malhotra',
      'status': 'Pending',
      'rewardAmount': 100.0,
      'createdAt': '30 Jul 2026',
      'sharedVia': 'Telegram',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadReferralCampaign();
  }

  Future<void> _loadReferralCampaign() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final seg = user.uid.length > 6 ? user.uid.substring(0, 6).toUpperCase() : 'USER89';
      _referralCode = 'NEXORA$seg';
      _referralLink = 'https://nexora.app/invite?ref=$_referralCode';
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('referral_config').get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        if (d['rewardAmount'] != null) _rewardAmount = (d['rewardAmount'] as num).toDouble();
        if (d['friendDiscount'] != null) _friendDiscount = (d['friendDiscount'] as num).toDouble();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Opens the platform share and marks it as used
  Future<void> _shareOnPlatform(String platform) async {
    final msg = '🏠 Join NEXORA – India\'s smartest home services app!\n'
        'Get ₹${_friendDiscount.toStringAsFixed(0)} OFF your first booking.\n'
        'Use my code: $_referralCode\n$_referralLink';

    String? url;

    switch (platform) {
      case 'WhatsApp':
        final encoded = Uri.encodeComponent(msg);
        url = 'https://wa.me/?text=$encoded';
        break;
      case 'Telegram':
        final encoded = Uri.encodeComponent(msg);
        url = 'https://t.me/share/url?url=${Uri.encodeComponent(_referralLink)}&text=${Uri.encodeComponent('Join NEXORA! Use code: $_referralCode')}';
        break;
      case 'SMS':
        final smsMsg = Uri.encodeComponent(msg);
        url = 'sms:?body=$smsMsg';
        break;
      case 'Email':
        final subject = Uri.encodeComponent('Join NEXORA – Get ₹${_friendDiscount.toStringAsFixed(0)} OFF!');
        final body = Uri.encodeComponent(msg);
        url = 'mailto:?subject=$subject&body=$body';
        break;
      case 'Copy Link':
      default:
        _copyToClipboard(_referralLink, '🔗 Referral link copied to clipboard!');
        setState(() => _sharedPlatforms.add('Copy Link'));
        return;
    }

    if (url != null) {
      try {
        final uri = Uri.parse(url);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) {
          setState(() => _sharedPlatforms.add(platform));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Text(_platformEmoji(platform), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Shared via $platform!',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
                backgroundColor: _platformColor(platform),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        } else {
          // Fallback: copy to clipboard
          _copyToClipboard(msg, 'Link copied! Open $platform manually.');
        }
      } catch (_) {
        _copyToClipboard(msg, 'Referral link copied! Share via $platform.');
      }
    }
  }

  String _platformEmoji(String platform) {
    switch (platform) {
      case 'WhatsApp': return '💬';
      case 'Telegram': return '✈️';
      case 'SMS': return '📱';
      case 'Email': return '📧';
      default: return '🔗';
    }
  }

  Color _platformColor(String platform) {
    switch (platform) {
      case 'WhatsApp': return const Color(0xFF25D366);
      case 'Telegram': return const Color(0xFF0088CC);
      case 'SMS': return const Color(0xFF6366F1);
      case 'Email': return const Color(0xFFEF4444);
      default: return _blue;
    }
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan to Download & Register', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: _dark)),
            const SizedBox(height: 16),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 150, color: _dark),
            ),
            const SizedBox(height: 12),
            Text('Ref Code: $_referralCode', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: _blue)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Close', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Refer & Earn Rewards', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Invite Card ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [_blue, Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invite Friends & Earn Wallet Rewards', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 6),
                              Text('Share your personal link and get rewards credited when your friend places their first booking.',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Campaign Reward Split Card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _rewardSplitTile('You Earn', '₹${_rewardAmount.toStringAsFixed(0)}', 'Wallet Balance Credit'),
                        ),
                        Container(width: 1, height: 40, color: _border),
                        Expanded(
                          child: _rewardSplitTile('Friend Gets', '₹${_friendDiscount.toStringAsFixed(0)}', 'First Booking Discount'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Unique Referral Code & Copy Card ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Personal Referral Code', style: GoogleFonts.inter(fontSize: 12, color: _gray, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _border),
                                ),
                                child: Text(_referralCode, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark, letterSpacing: 1.2)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: _blue),
                              onPressed: () => _copyToClipboard(_referralCode, 'Referral code copied!'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2_rounded, color: _dark),
                              onPressed: _showQrCodeDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Share on Platforms ────────────────────────────────────
                  Text('Share On', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 4),
                  Text('Choose a platform to share your referral link directly', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                  const SizedBox(height: 12),

                  // Platform share grid
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.88,
                    children: [
                      _platformTile('WhatsApp', Icons.chat_rounded, const Color(0xFF25D366)),
                      _platformTile('Telegram', Icons.send_rounded, const Color(0xFF0088CC)),
                      _platformTile('SMS', Icons.sms_rounded, const Color(0xFF6366F1)),
                      _platformTile('Email', Icons.email_rounded, const Color(0xFFEF4444)),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Copy link button
                  GestureDetector(
                    onTap: () => _shareOnPlatform('Copy Link'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link_rounded, color: _blue, size: 18),
                          const SizedBox(width: 8),
                          Text('Copy Referral Link', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _blue)),
                          if (_sharedPlatforms.contains('Copy Link')) ...[ 
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded, color: _green, size: 14),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Shared platforms summary (visible once any platform used)
                  if (_sharedPlatforms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: _green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Shared via: ${_sharedPlatforms.join(', ')}',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Real-Time Referral Statistics & History ────────────────
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('referrals')
                        .where('referrerId', isEqualTo: user?.uid ?? 'guest_user')
                        .snapshots(),
                    builder: (ctx, snap) {
                      List<Map<String, dynamic>> refList = _fallbackReferrals;
                      if (snap.hasData && snap.data!.docs.isNotEmpty) {
                        refList = snap.data!.docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return {'id': d.id, ...data};
                        }).toList();
                      }

                      final totalInvites = refList.length;
                      final successful = refList.where((r) => r['status'] == 'Completed' || r['status'] == 'Rewarded').length;
                      final pending = totalInvites - successful;
                      final totalRewards = successful * _rewardAmount;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics Grid Row
                          Text('Referral Statistics', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem('Total Invites', '$totalInvites'),
                                _vDivider(),
                                _statItem('Successful', '$successful'),
                                _vDivider(),
                                _statItem('Pending', '$pending'),
                                _vDivider(),
                                _statItem('Rewards', '₹${totalRewards.toStringAsFixed(0)}'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text('Referral History', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                          const SizedBox(height: 10),

                          if (refList.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _border),
                              ),
                              child: Center(
                                child: Text('No referrals joined yet. Share your code and invite friends to earn rewards!',
                                    textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: refList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final r = refList[i];
                                final String name = r['fullName'] ?? r['referredUserId'] ?? 'New Customer';
                                final String date = r['createdAt'] ?? 'Just now';
                                final String status = r['status'] ?? 'Pending';
                                final double amt = ((r['rewardAmount'] ?? _rewardAmount) as num).toDouble();
                                final String? platform = r['sharedVia'] as String?;

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _border),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: const Color(0xFFEFF6FF),
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'N',
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _blue),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                                            Row(
                                              children: [
                                                Text('Joined $date', style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                                                if (platform != null) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _platformColor(platform).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(_platformEmoji(platform), style: const TextStyle(fontSize: 9)),
                                                        const SizedBox(width: 2),
                                                        Text(platform, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: _platformColor(platform))),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _statusBadge(status),
                                          const SizedBox(height: 4),
                                          Text('+₹${amt.toStringAsFixed(0)}',
                                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold,
                                                  color: status == 'Completed' ? _green : _gray)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  /// Platform card for sharing
  Widget _platformTile(String platform, IconData icon, Color color) {
    final isShared = _sharedPlatforms.contains(platform);
    return GestureDetector(
      onTap: () => _shareOnPlatform(platform),
      child: Container(
        decoration: BoxDecoration(
          color: isShared ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isShared ? color.withValues(alpha: 0.4) : _border, width: isShared ? 1.5 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (isShared)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              platform,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isShared ? color : _dark),
            ),
            if (isShared)
              Text('Shared', style: GoogleFonts.inter(fontSize: 8, color: _green, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _rewardSplitTile(String title, String val, String subtitle) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: _blue)),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
      ],
    );
  }

  Widget _statItem(String label, String val) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _blue)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: _gray, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 20, color: _border);

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFEFF6FF);
    Color fg = _blue;

    if (status == 'Completed' || status == 'Rewarded') {
      bg = const Color(0xFFECFDF5);
      fg = _green;
    } else if (status == 'Pending' || status == 'Registered') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, color: fg, fontWeight: FontWeight.bold)),
    );
  }
}
