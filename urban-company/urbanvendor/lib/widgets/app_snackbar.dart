import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      content: Text(
        message,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
