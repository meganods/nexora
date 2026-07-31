import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final bookingId = args['bookingId'] ?? 'BK-9921';
    final double extraCharges = args['extraCharges'] as double? ?? 35.0;
    final int durationSeconds = args['durationSeconds'] as int? ?? 4500; // default 1h 15m

    final int hours = durationSeconds ~/ 3600;
    final int minutes = (durationSeconds % 3600) ~/ 60;
    final String durationText = hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";

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
          "Job Execution",
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mission Complete check header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF047857), // Green
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MISSION COMPLETE", style: GoogleFonts.inter(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text("Job Summary", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Customer profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150"),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Julian Vance", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 12),
                            const SizedBox(width: 4),
                            Text("Oak Ridge Estate, North Wing", style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble, color: Color(0xFF2563EB), size: 18),
                      onPressed: () => AppSnackbar.show(context, "Opening customer chat..."),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Service Type & Duration row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.assignment, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(height: 8),
                        Text("Service Type", style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                        Text("HVAC Maintenance", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time_filled, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(height: 8),
                        Text("Duration", style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                        Text(durationText, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Service Documentation gallery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Service Documentation", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                Text("2 Photos", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=200"), fit: BoxFit.cover),
                    ),
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                      child: const Text("BEFORE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=200"), fit: BoxFit.cover),
                    ),
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                      child: const Text("AFTER", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Cost Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cost Breakdown", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Base Service Fee", style: TextStyle(color: Colors.black54)),
                      Text("\$150.00", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Parts & Materials", style: TextStyle(color: Colors.black54)),
                      Text("\$${extraCharges.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Amount", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E3A8A))),
                      Text("\$${(150.0 + extraCharges).toStringAsFixed(2)}", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF2563EB))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 6. Submit Job button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  AppSnackbar.show(context, "Documentation Submitted! Returning to Dashboard.");
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/expert_dashboard', 
                    (route) => false,
                    arguments: {'isTestBypass': true},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0256D0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text("Submit Job Documentation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text("By submitting, you confirm all maintenance tasks were performed according to safety standards.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
