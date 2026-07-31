import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingJourneyScreen extends StatelessWidget {
  const OnboardingJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Onboarding Journey Screen Placeholder',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
