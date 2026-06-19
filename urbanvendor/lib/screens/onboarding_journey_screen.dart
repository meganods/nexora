import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingJourneyScreen extends StatelessWidget {
  const OnboardingJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3B44D3);
    const bgColor = Color(0xFFFCFBFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: primaryBlue),
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Partner\nRegistration',
                style: GoogleFonts.poppins(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 40),
              // Step Indicator
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 20,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '1 /\n8',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline, color: Color(0xFF8C9FB1)),
                const SizedBox(height: 4),
                Text('HELP', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8C9FB1), fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save_outlined, color: Color(0xFF8C9FB1)),
                const SizedBox(height: 4),
                Text('SAVE DRAFT', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8C9FB1), fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ONBOARDING JOURNEY',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.1,
                ),
                children: const [
                  TextSpan(text: 'Become a\n'),
                  TextSpan(
                    text: 'Professional\nPartner',
                    style: TextStyle(color: primaryBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Earn money by offering services on our platform. Join an elite network of service experts and take control of your schedule.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF00B4DB)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(color: primaryBlue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Get Started', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Already have an account? ', style: GoogleFonts.poppins(color: Colors.grey[600])),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text('Login', style: GoogleFonts.poppins(color: primaryBlue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFFA1492D), shape: BoxShape.circle),
                          child: const Icon(Icons.access_time_filled, color: Colors.white, size: 16),
                        ),
                        const SizedBox(height: 12),
                        Text('Flexible Hours', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Work whenever fits your lifestyle.', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.payments, color: Color(0xFF166d8e), size: 16),
                        ),
                        const SizedBox(height: 12),
                        Text('Secure Payouts', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Direct deposits every Friday.', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Hero Image Container (Replacing the illustration with a visually similar colored box and verified badge)
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF6AB6B6), // Teal background
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  // Using a network placeholder or just keeping it flat teal. Since we don't have the asset, a clean gradient/teal looks best.
                  image: NetworkImage('https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=600&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Color(0xFF6AB6B6), BlendMode.multiply),
                )
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified, color: primaryBlue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trusted by 10k+ Partners',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                  ),
                                  Text(
                                    'Join our growing professional community',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
