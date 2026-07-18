import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import 'booking_detail_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor), onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard')),
        title: Text("My Bookings", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: AppTheme.primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: "Upcoming"), Tab(text: "Completed"), Tab(text: "Cancelled")],
            ),
            Expanded(
              child: TabBarView(
                children: [
                   _buildBookingList("UPCOMING"),
                   _buildBookingList("COMPLETED"),
                   _buildBookingList("CANCELLED"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
    );
  }

  String _getServiceImageUrl(String shopName, String? dbImageUrl) {
    if (dbImageUrl != null && dbImageUrl.startsWith('http')) {
      return dbImageUrl;
    }
    final name = shopName.toLowerCase();
    if (name.contains('meganods') || name.contains('salon') || name.contains('beauty')) {
      return 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=300';
    } else if (name.contains('welder') || name.contains('welding')) {
      return 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=300';
    } else if (name.contains('ac') || name.contains('air conditioning') || name.contains('appliance')) {
      return 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=300';
    } else if (name.contains('garden') || name.contains('lawn')) {
      return 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=300';
    } else if (name.contains('contactor') || name.contains('renovation') || name.contains('civil') || name.contains('painting')) {
      return 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=300';
    }
    return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300';
  }

  Widget _buildBookingList(String status) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          "Please log in to view bookings",
          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 15),
                Text(
                  "No $status bookings found",
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String bookingId = data['id'] ?? doc.id;
            final String shopName = data['shopName'] ?? 'Urban Service Pro';
            final String price = data['price'] ?? '₹1,299';
            final String originalDate = data['date'] ?? 'Mon, Oct 12';
            final String originalTime = data['time'] ?? '10:00 AM';
            final String bookingStatus = (data['status'] ?? 'pending').toString().toLowerCase();

            final String? proposedDate = data['proposedDate'];
            final String? proposedTime = data['proposedTime'];

            final bool isRescheduledByVendor = bookingStatus == 'updated_by_vendor';

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isRescheduledByVendor ? const Color(0xFFFFFDF0) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isRescheduledByVendor ? const Color(0xFFFFCC80) : Colors.grey[100]!,
                  width: isRescheduledByVendor ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                       ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: FutureBuilder<DocumentSnapshot>(
                          future: (data['vendorId'] != null)
                              ? FirebaseFirestore.instance.collection('vendors').doc(data['vendorId']).get()
                              : Future.value(null),
                          builder: (context, vendorSnap) {
                            String? url;
                            if (vendorSnap.hasData && vendorSnap.data != null && vendorSnap.data!.exists) {
                              final vData = vendorSnap.data!.data() as Map<String, dynamic>;
                              url = vData['categoryImageUrl'] ?? vData['imageUrl'] ?? vData['image'];
                            }
                            url ??= data['imageUrl'] ?? data['image'];
                            
                            return Image.network(
                              url ?? _getServiceImageUrl(shopName, null),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 60,
                                height: 60,
                                color: const Color(0xFFEEF2F6),
                                child: const Icon(Icons.design_services_rounded, color: Color(0xFF4F46E5), size: 28),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shopName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Ref #$bookingId", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRescheduledByVendor
                                    ? const Color(0xFFFFF3E0)
                                    : (bookingStatus == 'confirmed' ? Colors.green[50] : Colors.blue[50]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isRescheduledByVendor ? "ACTION REQUIRED" : bookingStatus.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(
                                  color: isRescheduledByVendor
                                      ? const Color(0xFFE65100)
                                      : (bookingStatus == 'confirmed' ? Colors.green : Colors.blue),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.calendar_month, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        if (isRescheduledByVendor && proposedDate != null) ...[
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: originalDate,
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                const TextSpan(
                                  text: " ➔ ",
                                  style: TextStyle(color: Color(0xFFE65100)),
                                ),
                                TextSpan(
                                  text: proposedDate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ] else ...[
                          Text(originalDate, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ]),
                      Row(children: [
                        const Icon(Icons.access_time, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        if (isRescheduledByVendor && proposedTime != null) ...[
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: originalTime,
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                const TextSpan(
                                  text: " ➔ ",
                                  style: TextStyle(color: Color(0xFFE65100)),
                                ),
                                TextSpan(
                                  text: proposedTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ] else ...[
                          Text(originalTime, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isRescheduledByVendor) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(bookingId)
                                  .update({'status': 'cancelled'});
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "Decline & Cancel",
                              style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(bookingId)
                                  .update({
                                'status': 'confirmed',
                                'date': proposedDate ?? originalDate,
                                'time': proposedTime ?? originalTime,
                                'proposedDate': null,
                                'proposedTime': null,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "Accept New Time",
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailScreen(
                              booking: {
                                "id": bookingId,
                                "shopName": shopName,
                                "price": price,
                                "date": originalDate,
                                "time": originalTime,
                                "status": bookingStatus.toUpperCase(),
                              },
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("VIEW DETAILS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

}
