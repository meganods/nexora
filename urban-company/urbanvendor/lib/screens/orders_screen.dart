import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Orders Screen Coming Soon',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
