import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Analytics Screen Coming Soon',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
