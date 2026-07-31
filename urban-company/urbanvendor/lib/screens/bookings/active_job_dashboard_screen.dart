import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class ActiveJobDashboardScreen extends StatelessWidget {
  const ActiveJobDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final bookingId = args['bookingId'] ?? 'BK-9921';
    final customerName = args['customerName'] ?? 'Julian Vance';

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
          "Dashboard",
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
            // 1. Customer profile card with chat button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
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
                        Text(
                          customerName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFF2563EB), size: 14),
                            const SizedBox(width: 4),
                            Text("4.8", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0F172A))),
                            const SizedBox(width: 8),
                            const Text("•", style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text("Premium Client", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble, color: Color(0xFF2563EB), size: 20),
                      onPressed: () => AppSnackbar.show(context, "Opening customer chat..."),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Live Progress Timeline
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("LIVE PROGRESS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 0.8)),
                  const SizedBox(height: 20),

                  // Timeline Items
                  _buildTimelineItem("Booking Accepted", "10:45 AM", true, false),
                  _buildTimelineItem("On The Way", "En route to location", false, true),
                  _buildTimelineItem("Arrived", "", false, false),
                  _buildTimelineItem("OTP Verification", "", false, false),
                  _buildTimelineItem("Work Started", "", false, false, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Control actions Call, Chat, Maps, Cancel
            Row(
              children: [
                Expanded(child: _buildQuickAction(context, Icons.phone, "Call", const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickAction(context, Icons.message, "Chat", const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickAction(context, Icons.map, "Maps", const Color(0xFFEFF6FF), const Color(0xFF2563EB))),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickAction(context, Icons.cancel, "Cancel", const Color(0xFFFEE2E2), const Color(0xFFDC2626))),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Map Preview block
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage("https://images.unsplash.com/photo-1524661135-423995f22d0b?w=500"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF2563EB), size: 14),
                          SizedBox(width: 4),
                          Text("123 Service Lane, Tech City", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Floating Start Navigation button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/bookings/navigation', arguments: {
                    'bookingId': bookingId,
                    'customerName': customerName,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0256D0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                label: const Text("START NAVIGATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, bool isDone, bool isActive, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone 
                    ? const Color(0xFF0256D0) 
                    : (isActive ? const Color(0xFF0256D0) : Colors.transparent),
                border: Border.all(
                  color: isDone || isActive ? const Color(0xFF0256D0) : const Color(0xFFCBD5E1),
                  width: isActive ? 4 : 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isDone 
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? const Color(0xFF0256D0) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: isDone || isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                  color: isDone || isActive ? const Color(0xFF0F172A) : Colors.grey,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color bg, Color tint) {
    return InkWell(
      onTap: () => AppSnackbar.show(context, "$label button tapped."),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: tint, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tint)),
          ],
        ),
      ),
    );
  }
}
