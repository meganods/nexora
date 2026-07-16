import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF008060);
  static const Color secondaryColor = Color(0xFFE7F4F1);
  static const Color accentColor = Color(0xFF1E2432);
  static const Color backgroundColor = Colors.white;
  static const Color lightGray = Color(0xFFF5F5F5);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(),
      useMaterial3: true,
    );
  }
}
