import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceListScreen extends StatelessWidget {
  final String sectionTitle;
  const ServiceListScreen({super.key, required this.sectionTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(sectionTitle)),
      body: Center(
        child: Text(
          'Services for $sectionTitle Coming Soon',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
