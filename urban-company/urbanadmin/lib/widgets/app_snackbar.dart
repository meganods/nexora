import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _ToastWidget({
    Key? key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto dismiss after 3 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 3200), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isError ? const Color(0xFFEF4444) : const Color(0xFF4F46E5);
    final bgColor = widget.isError ? const Color(0xFFFEF2F2) : const Color(0xFFEEF2FF);
    final borderColor = widget.isError ? const Color(0xFFFCA5A5) : const Color(0xFFC7D2FE);
    final textColor = widget.isError ? const Color(0xFF991B1B) : const Color(0xFF312E81);

    return Positioned(
      top: 24,
      right: 24,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      // Left accent bar
                      Container(
                        width: 6,
                        height: 70,
                        color: themeColor,
                      ),
                      const SizedBox(width: 16),
                      // Icon wrapper
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isError 
                              ? Icons.error_outline_rounded 
                              : Icons.check_circle_outline_rounded,
                          color: themeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text message content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.isError ? 'Action Failed' : 'Success',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF475569),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: _dismiss,
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
