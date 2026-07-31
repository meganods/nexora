import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorTheme {
  // Brand Palette (Premium Light Theme consistent with User App)
  static const primaryColor = Color(0xFF2563EB);    // Nexora Royal Blue
  static const secondaryColor = Color(0xFF38BDF8);  // Sky Blue
  static const accentColor = Color(0xFF22C55E);     // Success Green
  
  static const bgColor = Color(0xFFF8FAFC);         // Clean light background
  static const surfaceColor = Color(0xFFFFFFFF);     // Plain white containers
  static const textPrimary = Color(0xFF0F172A);     // Deep charcoal
  static const textSecondary = Color(0xFF64748B);   // Muted slate gray
  static const borderColor = Color(0xFFE2E8F0);     // Soft gray border
  
  static const successColor = Color(0xFF22C55E);    // Green
  static const warningColor = Color(0xFFF59E0B);    // Orange/Amber
  static const errorColor = Color(0xFFEF4444);      // Red

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.inter(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 15),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
