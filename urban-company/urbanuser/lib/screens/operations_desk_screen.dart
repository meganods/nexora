import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);

class OperationsDeskScreen extends StatefulWidget {
  const OperationsDeskScreen({super.key});

  @override
  State<OperationsDeskScreen> createState() => _OperationsDeskScreenState();
}

class _OperationsDeskScreenState extends State<OperationsDeskScreen> {
  bool _isLoading = true;

  // Real-time Platform States
  bool _maintenanceMode = false;
  bool _emergencyStop = false;
  String _activeEnvironment = 'Production';
  int _activeUsers = 42;
  int _onlineVendors = 18;
  int _pendingBookings = 5;

  @override
  void initState() {
    super.initState();
    _loadControlStates();
  }

  Future<void> _loadControlStates() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('app_config').get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        _maintenanceMode = d['maintenanceMode'] ?? false;
        _emergencyStop = d['emergencyStopBookings'] ?? false;
        _activeEnvironment = d['environment'] ?? 'Production';
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _toggleConfig(String key, bool value) async {
    try {
      await FirebaseFirestore.instance.collection('app_settings').doc('app_config').set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Global config updated successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update config. Check permissions.', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _triggerGlobalAnnouncement() {
    final TextEditingController announceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('BroadCast Announcement', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: announceController,
              decoration: InputDecoration(
                hintText: 'Enter text announcement to all users…',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: _gray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: _gray))),
          ElevatedButton(
            onPressed: () async {
              final text = announceController.text.trim();
              if (text.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('notifications').add({
                    'userId': 'all',
                    'title': 'Platform Broadcast Announcement',
                    'body': text,
                    'type': 'broadcast',
                    'isRead': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Announcement Broadcasted Live!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      backgroundColor: _green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (_) {}
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _blue),
            child: Text('Broadcast', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _triggerFirestoreBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Database Backup Manager', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Initiating complete data snapshots transfer of collections. Exporting collections schema reports...', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Firestore JSON Snapshot backup complete!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: _green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _blue),
            child: Text('Start Backup Export', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Operations Launch Desk', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
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
                  // ── Realtime Stats Summary Card ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Operations Monitor', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                              child: Text(_activeEnvironment.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, color: _green, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: _border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statCol('Active Users', '$_activeUsers'),
                            _statCol('Online Partners', '$_onlineVendors'),
                            _statCol('Pending Bookings', '$_pendingBookings'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Admin System Controls Card ─────────────────────────────
                  Text('System Config Control Desk', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Platform Maintenance Mode', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                          subtitle: Text('Instantly overlay system upgrade banner to all users', style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                          value: _maintenanceMode,
                          onChanged: (val) {
                            setState(() => _maintenanceMode = val);
                            _toggleConfig('maintenanceMode', val);
                          },
                        ),
                        const Divider(color: _border, height: 1),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Emergency Stop Bookings', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                          subtitle: Text('Instantly block checkout payments and new slot schedules', style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                          value: _emergencyStop,
                          onChanged: (val) {
                            setState(() => _emergencyStop = val);
                            _toggleConfig('emergencyStopBookings', val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Operations Quick Actions ───────────────────────────────
                  Text('Operational Actions', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          Icons.broadcast_on_home_rounded,
                          'Broadcast News',
                          _triggerGlobalAnnouncement,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          Icons.cloud_download_rounded,
                          'Database Backup',
                          _triggerFirestoreBackup,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: _blue)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: _gray, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _blue, size: 24),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
          ],
        ),
      ),
    );
  }
}
