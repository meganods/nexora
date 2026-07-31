import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemScreen extends StatelessWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'System Management Coming Soon',
        style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
