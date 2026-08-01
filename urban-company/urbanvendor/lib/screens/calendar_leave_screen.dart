import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Design Tokens (Aesthetic Matching) ──────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);

class CalendarLeaveScreen extends StatefulWidget {
  const CalendarLeaveScreen({super.key});

  @override
  State<CalendarLeaveScreen> createState() => _CalendarLeaveScreenState();
}

class _CalendarLeaveScreenState extends State<CalendarLeaveScreen> {
  final String _email = FirebaseAuth.instance.currentUser?.email ?? FirebaseAuth.instance.currentUser?.uid ?? 'partner@nexora.com';
  bool _isLoading = true;

  // Schedule Toggles
  bool _mon = true, _tue = true, _wed = true, _thu = true, _fri = true, _sat = true, _sun = false;
  String _startTime = '09:00 AM';
  String _endTime = '06:00 PM';

  // Leaves List
  List<Map<String, dynamic>> _leaves = [];

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(_email).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        final sched = d['workingSchedule'] as Map<String, dynamic>? ?? {};
        setState(() {
          _mon = sched['Mon'] ?? true;
          _tue = sched['Tue'] ?? true;
          _wed = sched['Wed'] ?? true;
          _thu = sched['Thu'] ?? true;
          _fri = sched['Fri'] ?? true;
          _sat = sched['Sat'] ?? true;
          _sun = sched['Sun'] ?? false;
          _startTime = sched['startTime'] ?? '09:00 AM';
          _endTime = sched['endTime'] ?? '06:00 PM';
        });
      }

      // Load leaves list
      final leavesSnap = await FirebaseFirestore.instance
          .collection('vendor_leaves')
          .where('vendorId', isEqualTo: _email)
          .orderBy('startDate', descending: true)
          .get();

      setState(() {
        _leaves = leavesSnap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
      });
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _saveWorkingHours() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('vendors').doc(_email).set({
        'workingSchedule': {
          'Mon': _mon,
          'Tue': _tue,
          'Wed': _wed,
          'Thu': _thu,
          'Fri': _fri,
          'Sat': _sat,
          'Sun': _sun,
          'startTime': _startTime,
          'endTime': _endTime,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Working Schedule saved successfully!'),
          backgroundColor: _green,
        ),
      );
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _applyLeave() async {
    final TextEditingController reasonController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Apply for Leave', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Leave Date:', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: selectedDate!,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (d != null) {
                  selectedDate = d;
                }
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 14),
              label: Text('Choose Date'),
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for leave…',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: _gray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: _gray))),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty && selectedDate != null) {
                try {
                  await FirebaseFirestore.instance.collection('vendor_leaves').add({
                    'vendorId': _email,
                    'startDate': Timestamp.fromDate(selectedDate!),
                    'reason': reason,
                    'status': 'PENDING',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  _loadCalendarData();
                } catch (_) {}
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: Text('Submit', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: Text('Calendar & Availability', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Working Hours Card
                  Text('Weekly Availability Schedule', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        _daySwitch('Monday', _mon, (val) => setState(() => _mon = val)),
                        _daySwitch('Tuesday', _tue, (val) => setState(() => _tue = val)),
                        _daySwitch('Wednesday', _wed, (val) => setState(() => _wed = val)),
                        _daySwitch('Thursday', _thu, (val) => setState(() => _thu = val)),
                        _daySwitch('Friday', _fri, (val) => setState(() => _fri = val)),
                        _daySwitch('Saturday', _sat, (val) => setState(() => _sat = val)),
                        _daySwitch('Sunday', _sun, (val) => setState(() => _sun = val)),
                        const Divider(height: 32, color: _border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shift Start', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                            TextButton(
                              onPressed: () async {
                                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (t != null) {
                                  setState(() => _startTime = t.format(context));
                                }
                              },
                              child: Text(_startTime, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _primary)),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shift End', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                            TextButton(
                              onPressed: () async {
                                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (t != null) {
                                  setState(() => _endTime = t.format(context));
                                }
                              },
                              child: Text(_endTime, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveWorkingHours,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Save Working Schedule', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Leave Requests Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Leave & Off-Duty Registry', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                      TextButton.icon(
                        onPressed: _applyLeave,
                        icon: const Icon(Icons.add, size: 16, color: _primary),
                        label: Text('Apply Leave', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _leaves.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _border),
                          ),
                          child: Text('No leaves requested yet.', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _leaves.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _leaves[index];
                            final date = (item['startDate'] as Timestamp).toDate();
                            final dateStr = '${date.day}/${date.month}/${date.year}';
                            final reason = item['reason'] ?? '';
                            final status = item['status'] ?? 'PENDING';

                            Color statColor = _amber;
                            if (status == 'APPROVED') statColor = _green;
                            if (status == 'REJECTED') statColor = Colors.red;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dateStr, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                                      const SizedBox(height: 4),
                                      Text(reason, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.inter(fontSize: 10, color: statColor, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _daySwitch(String day, bool val, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(day, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
      value: val,
      onChanged: onChanged,
    );
  }
}
