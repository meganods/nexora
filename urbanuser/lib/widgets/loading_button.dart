import 'package:flutter/material.dart';
import 'app_button.dart';

// Alias for convenience as requested
class LoadingButton extends AppButton {
  const LoadingButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.isOutlined = false,
    super.icon,
    super.color = const Color(0xFF0F172A),
  }) : super(isLoading: true);
}
