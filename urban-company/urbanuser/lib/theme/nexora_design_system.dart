import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NexoraDesignSystem {
  // ─── Design Tokens (Colors) ────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color dark = Color(0xFF0F172A);
  static const Color gray = Color(0xFF64748B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);

  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);

  // ─── Spacing Tokens (8px Grid System) ──────────────────────────────────────
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // ─── Border Radius Tokens ──────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;

  // ─── Typography System ─────────────────────────────────────────────────────
  static TextStyle display(double size, {Color color = dark, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);
  }

  static TextStyle body(double size, {Color color = gray, FontWeight weight = FontWeight.normal, double height = 1.4}) {
    return GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight, height: height);
  }

  // ─── Reusable Component: Primary/Secondary Buttons ─────────────────────────
  static Widget button({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isSecondary = false,
    IconData? icon,
  }) {
    final bg = isSecondary ? primaryLight : primary;
    final fg = isSecondary ? primary : Colors.white;

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
        child: isLoading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: fg, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: display(13, color: fg, weight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  // ─── Reusable Component: Text Input Field ──────────────────────────────────
  static Widget input({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: display(13, color: dark, weight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: body(13, color: const Color(0xFFCBD5E1)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: gray, size: 18) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  // ─── Reusable Component: Cards ─────────────────────────────────────────────
  static Widget card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    Color color = surface,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radiusExtraLarge),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── Reusable Component: Status Badge ──────────────────────────────────────
  static Widget statusBadge(String status) {
    Color bg = primaryLight;
    Color fg = primary;

    final normalized = status.trim().toUpperCase();
    if (normalized == 'COMPLETED' || normalized == 'REWARDED' || normalized == 'SUCCESS') {
      bg = successBg;
      fg = success;
    } else if (normalized == 'PENDING' || normalized == 'REGISTERED') {
      bg = warningBg;
      fg = warning;
    } else if (normalized == 'CANCELLED' || normalized == 'FAILED') {
      bg = errorBg;
      fg = error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      child: Text(
        status.toUpperCase(),
        style: display(8, color: fg, weight: FontWeight.bold),
      ),
    );
  }
}
