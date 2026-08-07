import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/app_snackbar.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _blue    = Color(0xFF2563EB);
const _dark    = Color(0xFF0F172A);
const _gray    = Color(0xFF64748B);
const _border  = Color(0xFFE2E8F0);
const _green   = Color(0xFF10B981);
const _red     = Color(0xFFEF4444);
const _amber   = Color(0xFFF59E0B);
const _purple  = Color(0xFF8B5CF6);
const _bgLight = Color(0xFFF8FAFC);

// ─── Event meta-data ──────────────────────────────────────────────────────────
class _EventMeta {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _EventMeta(this.label, this.color, this.bgColor, this.icon);
}

const _eventMap = <String, _EventMeta>{
  'LOGIN_SUCCESS':    _EventMeta('Login Success',    _green,  Color(0xFFECFDF5), Icons.check_circle_rounded),
  'LOGIN_FAILED':     _EventMeta('Login Failed',     _red,    Color(0xFFFEF2F2), Icons.cancel_rounded),
  'OTP_SENT':         _EventMeta('OTP Sent',         _blue,   Color(0xFFEFF6FF), Icons.send_rounded),
  'OTP_RESENT':       _EventMeta('OTP Resent',       _blue,   Color(0xFFEFF6FF), Icons.refresh_rounded),
  'OTP_VERIFIED':     _EventMeta('OTP Verified',     _green,  Color(0xFFECFDF5), Icons.verified_rounded),
  'OTP_EXPIRED':      _EventMeta('OTP Expired',      _amber,  Color(0xFFFFFBEB), Icons.timer_off_rounded),
  'OTP_WRONG':        _EventMeta('Wrong OTP',        _red,    Color(0xFFFEF2F2), Icons.close_rounded),
  'OTP_BLOCKED':      _EventMeta('OTP Blocked',      _red,    Color(0xFFFEF2F2), Icons.block_rounded),
  'RESEND_BLOCKED':   _EventMeta('Resend Blocked',   _amber,  Color(0xFFFFFBEB), Icons.hourglass_top_rounded),
  'ACCOUNT_LOCKED':   _EventMeta('Account Locked',   _red,    Color(0xFFFFF0F0), Icons.lock_rounded),
};

_EventMeta _metaFor(String action) => _eventMap[action] ??
    const _EventMeta('Unknown Event', _gray, Color(0xFFF1F5F9), Icons.help_outline_rounded);

// ─── Screen ───────────────────────────────────────────────────────────────────
class LoginMonitoringScreen extends StatefulWidget {
  const LoginMonitoringScreen({super.key});

  @override
  State<LoginMonitoringScreen> createState() => _LoginMonitoringScreenState();
}

class _LoginMonitoringScreenState extends State<LoginMonitoringScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _filterAction = 'All';
  late TabController _tabController;

  static const _filterOptions = [
    'All', 'LOGIN_SUCCESS', 'LOGIN_FAILED', 'OTP_SENT', 'OTP_RESENT',
    'OTP_VERIFIED', 'OTP_EXPIRED', 'OTP_WRONG', 'OTP_BLOCKED', 'ACCOUNT_LOCKED',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Delete a single audit log entry ────────────────────────────────────────
  Future<void> _deleteEntry(String docId) async {
    try {
      await _firestore.collection('otp_audit_log').doc(docId).delete();
      if (mounted) AppSnackbar.show(context, 'Audit entry deleted.');
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Failed to delete entry.', isError: true);
    }
  }

  // ── Purge all audit log entries (superadmin only) ──────────────────────────
  Future<void> _confirmPurge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _red, size: 24),
            SizedBox(width: 10),
            Text('Purge Audit Log?'),
          ],
        ),
        content: Text(
          'This will permanently delete all authentication audit records. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: _gray, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final batch = _firestore.batch();
      final docs = await _firestore.collection('otp_audit_log').limit(500).get();
      for (final doc in docs.docs) batch.delete(doc.reference);
      await batch.commit();
      if (mounted) AppSnackbar.show(context, 'Audit log purged successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page header ────────────────────────────────────────────────────────
        Text('Login Monitoring',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: _dark)),
        Text('Real-time authentication activity, OTP events, and security audit trail.',
            style: GoogleFonts.poppins(fontSize: 13, color: _gray)),
        const SizedBox(height: 24),

        // ── Live KPI cards ─────────────────────────────────────────────────────
        _LiveKpiRow(firestore: _firestore),
        const SizedBox(height: 24),

        // ── Tabs ───────────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              // Tab bar
              TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                labelColor: _blue,
                unselectedLabelColor: _gray,
                indicatorColor: _blue,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Audit Log'),
                  Tab(text: 'Active Sessions'),
                ],
              ),
              const Divider(height: 1),

              // Filter + Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _bgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: _gray, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search by email or UID…',
                                  hintStyle: GoogleFonts.inter(fontSize: 12, color: _gray),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Event filter dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterAction,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark),
                          items: _filterOptions.map((o) => DropdownMenuItem(
                            value: o,
                            child: Text(o == 'All' ? 'All Events' : (_eventMap[o]?.label ?? o)),
                          )).toList(),
                          onChanged: (v) { if (v != null) setState(() => _filterAction = v); },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Purge button
                    Tooltip(
                      message: 'Purge all audit records',
                      child: IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: _red),
                        onPressed: _confirmPurge,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab views
              SizedBox(
                height: 620,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AuditLogTab(
                      firestore: _firestore,
                      searchQuery: _searchQuery,
                      filterAction: _filterAction,
                      onDelete: _deleteEntry,
                    ),
                    _ActiveSessionsTab(firestore: _firestore),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Live KPI Row ─────────────────────────────────────────────────────────────
class _LiveKpiRow extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _LiveKpiRow({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('otp_audit_log')
          .orderBy('createdAt', descending: true)
          .limit(500)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;
        final successes = docs.where((d) {
          final a = (d.data() as Map<String, dynamic>)['action'];
          return a == 'LOGIN_SUCCESS';
        }).length;
        final failures = docs.where((d) {
          final a = (d.data() as Map<String, dynamic>)['action'];
          return a == 'LOGIN_FAILED' || a == 'OTP_WRONG';
        }).length;
        final locked = docs.where((d) {
          final a = (d.data() as Map<String, dynamic>)['action'];
          return a == 'ACCOUNT_LOCKED';
        }).length;

        return Row(
          children: [
            _KpiCard('Total Events',    '$total',     Icons.receipt_long_rounded, _purple),
            const SizedBox(width: 16),
            _KpiCard('Successful Logins','$successes', Icons.check_circle_outline_rounded, _green),
            const SizedBox(width: 16),
            _KpiCard('Failed Attempts', '$failures',  Icons.warning_amber_rounded, _amber),
            const SizedBox(width: 16),
            _KpiCard('Locked Accounts', '$locked',    Icons.lock_outline_rounded,  _red),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: _dark)),
                  const SizedBox(height: 2),
                  Text(label, style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Audit Log Tab ────────────────────────────────────────────────────────────
class _AuditLogTab extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String searchQuery;
  final String filterAction;
  final void Function(String) onDelete;

  const _AuditLogTab({
    required this.firestore,
    required this.searchQuery,
    required this.filterAction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Query query = firestore.collection('otp_audit_log').orderBy('createdAt', descending: true).limit(200);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }

        var docs = snap.data?.docs ?? [];

        // Client-side filter
        if (filterAction != 'All') {
          docs = docs.where((d) => (d.data() as Map<String, dynamic>)['action'] == filterAction).toList();
        }
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['email']?.toString().toLowerCase().contains(q) ?? false) ||
                   (data['uid']?.toString().toLowerCase().contains(q) ?? false);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 48, color: _gray),
                const SizedBox(height: 12),
                Text('No audit events match the current filters.',
                    style: GoogleFonts.inter(color: _gray, fontSize: 13)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 340),
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: [
                DataColumn(label: Text('Event',        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Email',        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('IP Address',   style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Platform',     style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Device',       style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Session ID',   style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Time',         style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Actions',      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final action   = data['action']?.toString()        ?? '—';
                final email    = data['email']?.toString()         ?? '—';
                final ip       = data['ipAddress']?.toString()     ?? '—';
                final platform = data['platform']?.toString()      ?? '—';
                final device   = data['deviceName']?.toString()    ?? '—';
                final sid      = data['loginSessionId']?.toString() ?? '—';
                final ts       = data['createdAt'] as Timestamp?;
                final timeStr  = ts != null
                    ? DateFormat('dd MMM, HH:mm:ss').format(ts.toDate().toLocal())
                    : '—';
                final meta = _metaFor(action);

                return DataRow(cells: [
                  // Event badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: meta.bgColor, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(meta.icon, size: 13, color: meta.color),
                          const SizedBox(width: 5),
                          Text(meta.label,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: meta.color)),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(email, style: GoogleFonts.inter(fontSize: 12, color: _dark))),
                  DataCell(_copyCell(ip, context)),
                  DataCell(_platformChip(platform)),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(device,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 140,
                      child: Text(sid.length > 16 ? '${sid.substring(0, 16)}…' : sid,
                          style: GoogleFonts.inter(fontSize: 11, color: _gray).copyWith(fontFamily: 'monospace')),
                    ),
                  ),
                  DataCell(Text(timeStr, style: GoogleFonts.inter(fontSize: 12, color: _gray))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: _red, size: 18),
                      tooltip: 'Delete entry',
                      onPressed: () => onDelete(doc.id),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _copyCell(String text, BuildContext context) {
    return GestureDetector(
      onTap: () => AppSnackbar.show(context, 'Copied: $text'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: GoogleFonts.inter(fontSize: 12, color: _dark)),
          const SizedBox(width: 4),
          const Icon(Icons.copy_rounded, size: 11, color: _gray),
        ],
      ),
    );
  }

  Widget _platformChip(String platform) {
    IconData icon;
    Color color;
    switch (platform.toLowerCase()) {
      case 'android': icon = Icons.android_rounded;      color = const Color(0xFF3DDC84); break;
      case 'ios':     icon = Icons.phone_iphone_rounded; color = _gray;                  break;
      case 'windows': icon = Icons.desktop_windows_rounded; color = _blue;              break;
      case 'macos':   icon = Icons.laptop_mac_rounded;   color = _gray;                  break;
      default:        icon = Icons.device_unknown_rounded; color = _gray;               break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(platform, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
      ],
    );
  }
}

// ─── Active Sessions Tab ──────────────────────────────────────────────────────
// Shows all otp_verifications docs where verified=false AND expiresAt > now
class _ActiveSessionsTab extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _ActiveSessionsTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('otp_verifications')
          .where('verified', isEqualTo: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }

        final now = DateTime.now();
        final docs = (snap.data?.docs ?? []).where((d) {
          final data = d.data() as Map<String, dynamic>;
          final exp = data['expiresAt'] as Timestamp?;
          return exp != null && exp.toDate().isAfter(now);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_rounded, size: 48, color: _green),
                const SizedBox(height: 12),
                Text('No active pending OTP sessions.',
                    style: GoogleFonts.inter(color: _gray, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final email    = data['email']?.toString()     ?? '—';
            final ip       = data['ipAddress']?.toString() ?? '—';
            final platform = data['platform']?.toString()  ?? '—';
            final device   = data['deviceName']?.toString() ?? '—';
            final attempts = data['attempts'] as int? ?? 0;
            final exp      = data['expiresAt'] as Timestamp?;
            final sid      = data['loginSessionId']?.toString() ?? '—';
            final expStr   = exp != null
                ? DateFormat('HH:mm:ss').format(exp.toDate().toLocal())
                : '—';
            final remaining = exp != null
                ? exp.toDate().difference(now).inSeconds
                : 0;
            final pct = (remaining / 600).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded, size: 16, color: _amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(email,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: _dark)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Expires $expStr',
                            style: GoogleFonts.inter(fontSize: 11, color: _amber, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Session expiry progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: pct > 0.5 ? _green : pct > 0.2 ? _amber : _red,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Metadata row
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _metaItem(Icons.wifi_rounded, ip),
                      _metaItem(Icons.devices_rounded, platform),
                      _metaItem(Icons.smartphone_rounded, device),
                      _metaItem(Icons.fingerprint_rounded, sid.length > 12 ? '${sid.substring(0, 12)}…' : sid),
                      _metaItem(Icons.warning_amber_rounded, '$attempts attempt${attempts == 1 ? '' : 's'}'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _metaItem(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: _gray),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
    ],
  );
}
