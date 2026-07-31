import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'My Bookings Screen Coming Soon',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
