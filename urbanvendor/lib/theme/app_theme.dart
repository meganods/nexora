import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color secondaryColor = Color(0xFFE5E7EB);
  static const Color accentColor = Color(0xFF111827); // Slate
  static const Color backgroundColor = Colors.white;
  static const Color lightGray = Color(0xFFF3F4F6);

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
