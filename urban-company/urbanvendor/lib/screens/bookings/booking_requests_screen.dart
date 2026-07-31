import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Booking Requests",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('vendorId', isEqualTo: user?.uid ?? 'vendor_01')
            .where('status', isEqualTo: 'assigned')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, size: 48, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Pending Requests",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You are all caught up for today!",
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final services = List.from(data['services'] ?? []);
              final firstService = services.isNotEmpty ? services.first['name'] ?? 'General Service' : 'General Service';
              final firstSubService = services.isNotEmpty ? services.first['description'] ?? 'Standard maintenance' : 'Standard maintenance';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEFF6FF)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Map Placeholder / Card Header
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        color: Color(0xFFE2E8F0),
                        image: DecorationImage(
                          image: NetworkImage("https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.15),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, color: Colors.amber, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "URGENT REQUEST",
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Customer Profile Info
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage("https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150"),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['customerName'] ?? data['userEmail']?.toString().split('@').first ?? 'Customer Profile',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Mumbai Area (2.4 km away)",
                                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "1.5 hrs est.",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28, color: Color(0xFFF1F5F9)),

                          // 3. Service details
                          Text(
                            "CATEGORY & SERVICE",
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            firstService,
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstSubService,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),

                          // 4. Booking Time Slots
                          Row(
                            children: [
                              Expanded(
                                child: _infoBlock(Icons.calendar_today_rounded, "DATE", data['date'] ?? "Today"),
                              ),
                              Expanded(
                                child: _infoBlock(Icons.access_time_rounded, "TIME SLOT", data['time'] ?? "10:00 AM"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 5. Actions: Accept & Reject
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({
                                      'status': 'rejected',
                                    });
                                    await FirebaseFirestore.instance.collection('booking_timeline').add({
                                      'bookingId': doc.id,
                                      'status': 'rejected',
                                      'title': 'Booking Rejected',
                                      'description': 'Vendor has rejected this assignment.',
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });
                                    if (context.mounted) AppSnackbar.show(context, "Request Declined");
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: Color(0xFFF1F5F9)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: Text(
                                    "Reject",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFDC2626), fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({
                                      'status': 'accepted',
                                      'acceptedAt': FieldValue.serverTimestamp(),
                                    });

                                    // Timeline write
                                    await FirebaseFirestore.instance.collection('booking_timeline').add({
                                      'bookingId': doc.id,
                                      'status': 'accepted',
                                      'title': 'Booking Accepted',
                                      'description': 'Vendor has accepted the booking and is preparing for service.',
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                    // Create Notification for User
                                    await FirebaseFirestore.instance.collection('notifications').add({
                                      'title': 'Booking Confirmed!',
                                      'body': 'Vendor has accepted your booking and is assigned to your service.',
                                      'userId': data['userId'] ?? 'guest_user',
                                      'type': 'booking',
                                      'bookingId': doc.id,
                                      'read': false,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    // Create Notification for Admin
                                    await FirebaseFirestore.instance.collection('notifications').add({
                                      'title': 'Vendor Accepted Job',
                                      'body': 'Vendor accepted booking ${doc.id} successfully.',
                                      'userId': 'admin',
                                      'type': 'booking',
                                      'bookingId': doc.id,
                                      'read': false,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    if (context.mounted) {
                                      AppSnackbar.show(context, "Booking Accepted!");
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D4ED8),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "Accept Request",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoBlock(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
            ),
          ],
        ),
      ],
    );
  }
}
