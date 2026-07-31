import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service_model.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: Center(
        child: Text(
          'Service Details for ${service.title} Coming Soon',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
