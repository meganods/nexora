import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'live_tracking_screen.dart';
import '../widgets/app_toast.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? bookingId;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.bookingId,
    required this.isRead,
    required this.timestamp,
  });
}

final notificationStreamController = StreamController<List<NotificationModel>>.broadcast();

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in snap.docs) {
          await doc.reference.set({
            'read': true,
            'isRead': true,
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint("Error marking all read: $e");
      }
    }

    if (mounted) {
      AppToast.show(
        context,
        title: 'Notifications Updated',
        message: 'All notifications marked as read.',
        icon: Icons.check_circle_rounded,
        iconColor: _green,
        iconBgColor: const Color(0xFFECFDF5),
      );
    }
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
        title: Text('Notifications Center', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text('Mark all read', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _blue,
          unselectedLabelColor: _gray,
          indicatorColor: _blue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Bookings'),
            Tab(text: 'Offers & Deals'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.uid ?? 'guest_user')
            .snapshots(),
        builder: (context, snap) {
          List<Map<String, dynamic>> items = [];
          if (snap.hasData && snap.data!.docs.isNotEmpty) {
            items = snap.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return {'id': d.id, ...data};
            }).toList();

            // Sort locally in memory descending
            items.sort((a, b) {
              final aTime = a['createdAt'] ?? a['timestamp'];
              final bTime = b['createdAt'] ?? b['timestamp'];
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              
              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.compareTo(aTime);
              }
              return 0;
            });
          }

          final bookingItems = items.where((i) => (i['type'] ?? '') == 'booking').toList();
          final offerItems = items.where((i) => (i['type'] ?? '') == 'offer' || (i['type'] ?? '') == 'reward').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(items),
              _buildNotificationList(bookingItems),
              _buildNotificationList(offerItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 54, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No Notifications', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 4),
            Text('We will keep you updated on your booking status & offers.', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final id = item['id'] ?? '';
        final title = item['title'] ?? 'Notification';
        final body = item['body'] ?? '';
        final type = item['type'] ?? 'system';
        final bool isRead = item['read'] == true || item['isRead'] == true;
        final String time = item['time'] ?? 'Just now';
        final String? bId = item['bookingId'];

        IconData icon = Icons.notifications_rounded;
        Color iconBg = const Color(0xFFEFF6FF);
        Color iconFg = _blue;

        if (type == 'booking') {
          icon = Icons.calendar_month_rounded;
          iconBg = const Color(0xFFECFDF5);
          iconFg = _green;
        } else if (type == 'offer' || type == 'reward') {
          icon = Icons.local_offer_rounded;
          iconBg = const Color(0xFFFFFBEB);
          iconFg = const Color(0xFFD97706);
        }

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            if (id.isNotEmpty) {
              try {
                FirebaseFirestore.instance.collection('notifications').doc(id).delete();
              } catch (_) {}
            }
            AppToast.show(
              context,
              title: 'Notification Removed',
              message: '"$title" removed from history.',
              icon: Icons.delete_outline_rounded,
              iconColor: Colors.red,
              iconBgColor: const Color(0xFFFEF2F2),
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          child: GestureDetector(
            onTap: () async {
              setState(() {
                item['read'] = true;
                item['isRead'] = true;
              });

              AppToast.show(
                context,
                title: title,
                message: body,
                icon: icon,
                iconColor: iconFg,
                iconBgColor: iconBg,
              );

              if (id.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('notifications').doc(id).set({
                    'read': true,
                    'isRead': true,
                  }, SetOptions(merge: true));
                } catch (_) {}
              }

              if (!context.mounted) return;

              if (bId != null && bId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LiveTrackingScreen(bookingId: bId)),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRead ? Colors.white : const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isRead ? _border : _blue.withValues(alpha: 0.4), width: isRead ? 1.0 : 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, color: iconFg, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(title,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                      color: _dark)),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(body, style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.4)),
                        const SizedBox(height: 6),
                        Text(time, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
