import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Elite Tier Onboarding',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavIcon(Icons.home_outlined, 'Home', false),
              _buildBottomNavIcon(Icons.settings_outlined, 'Services', false),
              _buildBottomNavIcon(Icons.show_chart, 'Status', true),
              _buildBottomNavIcon(Icons.person_outline, 'Account', false),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Progress Indicator (4 pills)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 30, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Container(width: 30, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Container(width: 30, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Container(width: 60, height: 4, decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(2))),
              ],
            ),
            const SizedBox(height: 30),
            
            // Success Hero Icon
            Stack(
              alignment: Alignment.center,
              children: [
                // Faint glowing outer ring
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: primaryBlue.withValues(alpha: 0.08), blurRadius: 40, spreadRadius: 10),
                    ],
                  ),
                ),
                // Inner solid circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Title & Description
            Text(
              'Application\nSubmitted',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[500], height: 1.5),
                  children: [
                    const TextSpan(text: "Our team will review your profile. You'll\nbe notified within "),
                    TextSpan(text: '24-48 hours', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Status Checklists
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildStatusCard(
                    icon: Icons.security,
                    iconColor: const Color(0xFF0C8A9E),
                    title: 'Security Check',
                    subtitle: 'Verification in progress',
                  ),
                  const SizedBox(height: 12),
                  _buildStatusCard(
                    icon: Icons.schema_outlined,
                    iconColor: const Color(0xFF9E3A1A),
                    title: 'Profile Sync',
                    subtitle: 'Database indexing...',
                  ),
                  const SizedBox(height: 12),
                  _buildStatusCard(
                    icon: Icons.rocket_launch,
                    iconColor: primaryBlue,
                    title: 'Access Tier',
                    subtitle: 'Elite Professional',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Finish & Track Status', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Decorative Abstract Graphic (Using a stylized container to emulate the shape)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[300]!, Colors.grey[200]!],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    right: 60,
                    child: Icon(Icons.water_drop, size: 100, color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 50,
                    child: Icon(Icons.bubble_chart, size: 80, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({required IconData icon, required Color iconColor, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, bool isActive) {
    const primaryBlue = Color(0xFF4A55ED);
    
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF2FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryBlue, size: 20),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: primaryBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueGrey[400], size: 22),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.blueGrey[400])),
      ],
    );
  }
}
