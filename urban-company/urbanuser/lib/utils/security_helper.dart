class SecurityHelper {
  // ─── Input Sanitization ──────────────────────────────────────────────────
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;
    
    // Strip HTML Tags & dangerous script parameters
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove dangerous symbols common in SQL/Script Injection attempts
    sanitized = sanitized.replaceAll(RegExp(r"['" + '"' + r';\$%]'), '');
    
    return sanitized.trim();
  }

  // ─── Email Sanitization & Validation ──────────────────────────────────────
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // ─── Phone Number Validator ──────────────────────────────────────────────
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,12}$');
    return phoneRegex.hasMatch(phone.trim());
  }
}
