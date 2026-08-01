import 'package:flutter/material.dart';
import 'app_toast.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    AppToast.show(
      context,
      title: isError ? 'Attention' : 'Notification',
      message: message,
      isError: isError,
      icon: isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
      iconColor: isError ? Colors.red : const Color(0xFF10B981),
      iconBgColor: isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
    );
  }
}
