import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppToast {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color iconColor = const Color(0xFF2563EB),
    Color iconBgColor = const Color(0xFFEFF6FF),
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return _TopRightToastWidget(
          title: title,
          message: message,
          icon: icon,
          iconColor: isError ? Colors.red : iconColor,
          iconBgColor: isError ? const Color(0xFFFEF2F2) : iconBgColor,
          duration: duration,
          onTap: () {
            overlayEntry.remove();
            if (_currentOverlay == overlayEntry) _currentOverlay = null;
            if (onTap != null) onTap();
          },
          onClose: () {
            overlayEntry.remove();
            if (_currentOverlay == overlayEntry) _currentOverlay = null;
          },
        );
      },
    );

    _currentOverlay = overlayEntry;
    overlayState.insert(overlayEntry);

    Future.delayed(duration, () {
      if (_currentOverlay == overlayEntry) {
        overlayEntry.remove();
        _currentOverlay = null;
      }
    });
  }
}

class _TopRightToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Duration duration;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TopRightToastWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.duration,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TopRightToastWidget> createState() => _TopRightToastWidgetState();
}

class _TopRightToastWidgetState extends State<_TopRightToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Slides in from upper right side
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16, // Upper Right side toast position
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 310,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
