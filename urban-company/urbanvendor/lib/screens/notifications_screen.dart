import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/vendor_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: VendorTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(user?.email),
            child: Text(
              "Mark all read",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', whereIn: [user?.email ?? '', 'all', 'vendors'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyNotifications();
          }

          // Sort in memory by timestamp descending since whereIn query can conflict with orderBy fields
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
            ..sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['read'] == true;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                ),
                onDismissed: (_) {
                  FirebaseFirestore.instance.collection('notifications').doc(doc.id).delete();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(data['type']).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(data['type']),
                          color: _getNotificationColor(data['type']),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    data['title'] ?? 'Notification Update',
                                    style: GoogleFonts.inter(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 14,
                                      color: VendorTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['body'] ?? 'No detail provided.',
                              style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimestamp(data['timestamp'] as Timestamp?),
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                ),
                                if (!isRead)
                                  GestureDetector(
                                    onTap: () {
                                      FirebaseFirestore.instance.collection('notifications').doc(doc.id).update({'read': true});
                                    },
                                    child: Text(
                                      "Mark Read",
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                    ),
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
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              "No notifications yet",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              "We'll notify you when booking updates or admin alerts arrive.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'booking':
      case 'assigned':
        return Icons.assignment_turned_in_rounded;
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'alert':
      case 'admin':
        return Icons.campaign_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getNotificationColor(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'booking':
      case 'assigned':
        return const Color(0xFF2563EB);
      case 'payment':
        return const Color(0xFF10B981);
      case 'alert':
      case 'admin':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${diff.inDays} days ago";
  }

  Future<void> _markAllAsRead(String? email) async {
    if (email == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', whereIn: [email, 'all', 'vendors'])
        .where('read', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
