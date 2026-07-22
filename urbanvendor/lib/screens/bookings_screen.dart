import 'package:urbanvendor/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4F46E5),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('UPCOMING'),
          _buildBookingsList('COMPLETED'),
          _buildBookingsList('CANCELLED'),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, String bookingId, String currentDate, String currentTime) {
    final formKey = GlobalKey<FormState>();
    final dateC = TextEditingController(text: currentDate);
    final timeC = TextEditingController(text: currentTime);

    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reschedule Booking', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: dateC,
                decoration: InputDecoration(
                  labelText: 'Proposed Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: timeC,
                decoration: InputDecoration(
                  labelText: 'Proposed Time',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dContext),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({
                  'status': 'updated_by_vendor',
                  'proposedDate': dateC.text.trim(),
                  'proposedTime': timeC.text.trim(),
                });
                if (context.mounted) {
                  Navigator.pop(dContext);
                  AppSnackbar.show(context, 'Reschedule proposal sent to customer');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Send Proposed Time', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String status) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not authenticated.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('vendorId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bookingStatus = (data['status'] ?? 'pending').toString().toLowerCase();
          if (status == 'UPCOMING') {
            return bookingStatus == 'pending' || bookingStatus == 'confirmed' || bookingStatus == 'updated_by_vendor' || bookingStatus == 'upcoming';
          } else if (status == 'COMPLETED') {
            return bookingStatus == 'completed';
          } else {
            return bookingStatus == 'cancelled';
          }
        }).toList();

        if (docs.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            // Preserve Firestore document ID if missing in internal map
            final Map<String, dynamic> mutableData = Map.from(data);
            mutableData['id'] = mutableData['id'] ?? docs[index].id;
            return _buildBookingCard(mutableData, status);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message = 'No bookings found.';
    IconData icon = Icons.calendar_today_rounded;

    if (status == 'UPCOMING') {
      message = "You don't have any upcoming bookings right now.";
      icon = Icons.event_available_rounded;
    } else if (status == 'COMPLETED') {
      message = "Your completed bookings will appear here.";
      icon = Icons.check_circle_outline_rounded;
    } else if (status == 'CANCELLED') {
      message = "You don't have any cancelled bookings.";
      icon = Icons.cancel_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String status) {
    final String bookingId = data['id'] ?? '';
    final userEmail = data['userEmail'] ?? 'Customer';
    final customerName = data['customerName'] ?? userEmail.split('@')[0];
    final serviceName = data['serviceName'] ?? data['shopName'] ?? 'Urban Service Pro';
    final price = data['price'] ?? data['totalAmount'] ?? '0';
    final bookingStatus = (data['status'] ?? 'pending').toString().toLowerCase();

    final originalDate = data['date'] ?? 'Today';
    final originalTime = data['time'] ?? '10:00 AM';
    final proposedDate = data['proposedDate'];
    final proposedTime = data['proposedTime'];

    final bool isProposed = bookingStatus == 'updated_by_vendor';
    final bool isPending = bookingStatus == 'pending' || bookingStatus == 'upcoming';
    final bool isConfirmed = bookingStatus == 'confirmed';

    return Opacity(
      opacity: isProposed ? 0.75 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isProposed ? Border.all(color: Colors.amber[300]!, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customerName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bookingStatus).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bookingStatus.toUpperCase().replaceAll('_', ' '),
                    style: GoogleFonts.poppins(
                      color: _getStatusColor(bookingStatus),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              serviceName,
              style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "$originalDate • $originalTime",
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            if (isProposed && proposedDate != null && proposedTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    "Waiting for response ($proposedDate • $proposedTime)",
                    style: GoogleFonts.poppins(color: Colors.amber[800], fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price',
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  price.startsWith('₹') ? price : '₹$price',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (isPending || isConfirmed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRescheduleDialog(context, bookingId, originalDate, originalTime),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: Color(0xFF4F46E5)),
                        ),
                        child: Text('Reschedule', style: GoogleFonts.poppins(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({'status': 'confirmed'});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Accept', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  if (isConfirmed) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({'status': 'cancelled'});
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({'status': 'completed'});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Complete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'upcoming') {
      return const Color(0xFF4F46E5);
    } else if (s == 'confirmed') {
      return const Color(0xFF10B981);
    } else if (s == 'updated_by_vendor') {
      return Colors.amber[800]!;
    } else if (s == 'completed') {
      return const Color(0xFF10B981);
    } else if (s == 'cancelled') {
      return const Color(0xFFEF4444);
    }
    return Colors.grey;
  }
}
