import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class BookingPhotosScreen extends StatefulWidget {
  const BookingPhotosScreen({super.key});

  @override
  State<BookingPhotosScreen> createState() => _BookingPhotosScreenState();
}

class _BookingPhotosScreenState extends State<BookingPhotosScreen> {
  final List<String> _beforePhotos = [
    "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500"
  ];
  final List<String> _afterPhotos = [
    "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500"
  ];

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final bookingId = args['bookingId'] ?? 'BK-9921';
    final data = args['data'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: VendorTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Before / After Work Photos",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Before Photos Section
            _buildPhotoSection(
              title: "Before Work Photos",
              subtitle: "Capture work area condition prior to starting service",
              photos: _beforePhotos,
              onAdd: () {
                setState(() {
                  _beforePhotos.add("https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500");
                });
                AppSnackbar.show(context, "Before work photo attached!");
              },
            ),
            const SizedBox(height: 24),

            // After Photos Section
            _buildPhotoSection(
              title: "After Work Photos",
              subtitle: "Capture completed work results for quality audit",
              photos: _afterPhotos,
              onAdd: () {
                setState(() {
                  _afterPhotos.add("https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500");
                });
                AppSnackbar.show(context, "After work photo attached!");
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _completeWorkAndGenerateInvoice(context, bookingId, data),
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
            label: Text("Complete Job & Generate Invoice", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: VendorTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection({
    required String title,
    required String subtitle,
    required List<String> photos,
    required VoidCallback onAdd,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: VendorTheme.textPrimary)),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_a_photo_rounded, size: 14),
                  label: const Text("Add Photo"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: VendorTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: photos.map((url) {
                return Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeWorkAndGenerateInvoice(BuildContext context, String bookingId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'COMPLETED',
      'completedAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      AppSnackbar.show(context, "Job marked as COMPLETED! Generating invoice...");
      Navigator.pushReplacementNamed(context, '/bookings/invoice', arguments: {'bookingId': bookingId, 'data': data});
    }
  }
}
