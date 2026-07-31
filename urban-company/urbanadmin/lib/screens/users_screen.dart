import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Users Management Coming Soon',
        style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
