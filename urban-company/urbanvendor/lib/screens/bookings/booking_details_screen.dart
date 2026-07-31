import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final bookingId = args['bookingId'] ?? 'BK-9921';
    final initialData = args['data'] as Map<String, dynamic>? ?? {};

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
      builder: (context, snapshot) {
        final data = (snapshot.hasData && snapshot.data!.exists)
            ? (snapshot.data!.data() as Map<String, dynamic>)
            : initialData;

        final customerName = data['userName'] ?? data['customerName'] ?? 'Julian Vance';
        final phone = data['userPhone'] ?? data['customerPhone'] ?? '+91 98765 43210';
        final address = data['address'] ?? data['customerAddress'] ?? '1282 Oakwood Ave, Seattle, WA';
        final instructions = data['instructions'] ?? data['notes'] ?? 'Please ring the back doorbell. The unit is in the attic.';
        final status = (data['status'] ?? 'ACCEPTED').toString().toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Request Detail",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"),
                ),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. App Bar Sub-Row Call, Message, Navigate
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: () => AppSnackbar.show(context, "Calling $customerName ($phone)..."),
                          icon: const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF2563EB)),
                          label: const Text("Call", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: () => AppSnackbar.show(context, "Opening chat with $customerName..."),
                          icon: const Icon(Icons.message_outlined, size: 16, color: Color(0xFF2563EB)),
                          label: const Text("Message", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0256D0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.white, size: 20),
                        onPressed: () {
                          Navigator.pushNamed(context, '/bookings/navigation', arguments: {'bookingId': bookingId, 'data': data});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Customer profile card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150"),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customerName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text("4.8", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0F172A))),
                                const SizedBox(width: 8),
                                const Text("•", style: TextStyle(color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text("124 Deliveries", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Delivery address card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("DELIVERY ADDRESS", style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(address, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("House #", style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text("42", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF0F172A))),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Landmark", style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                      Text("Near Central Park", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF0F172A))),
                                    ],
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
                const SizedBox(height: 16),

                // 4. Special Instructions card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.speaker_notes, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Special Instructions", style: GoogleFonts.inter(color: const Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold)),
                                const Icon(Icons.volume_up, color: Color(0xFF2563EB), size: 18),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "\"$instructions\"",
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E3A8A), height: 1.4, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Payment details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.credit_card, color: Color(0xFF0F172A), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Credit Card (Verified)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                            Text("Ending in •••• 8829", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Recent activity header
                Text("RECENT ACTIVITY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                const SizedBox(height: 12),

                // 7. Recent activity card item
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Last Order: Yesterday", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                            Text("Groceries • \$142.50", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomSheet: _buildActionFooter(context, bookingId, status, data),
        );
      },
    );
  }

  Widget _buildActionFooter(BuildContext context, String bookingId, String status, Map<String, dynamic> data) {
    String label = "Start Live Navigation";
    String targetRoute = "/bookings/navigation";

    if (status == 'ON_THE_WAY') {
      label = "Arrived (Prompt OTP Verification)";
      targetRoute = "/bookings/otp";
    } else if (status == 'ARRIVED') {
      label = "Verify 4-Digit Customer OTP";
      targetRoute = "/bookings/otp";
    } else if (status == 'IN_PROGRESS' || status == 'WORK_STARTED' || status == 'WORKING') {
      label = "Fill Service Checklist & Photos";
      targetRoute = "/bookings/checklist";
    } else if (status == 'COMPLETED') {
      label = "View Invoice & Summary";
      targetRoute = "/bookings/invoice";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, targetRoute, arguments: {'bookingId': bookingId, 'data': data});
          },
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0256D0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
