import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryCard extends StatefulWidget {
  final String title;
  final String? price;
  final IconData icon;
  final String? customIconUrl;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    this.price,
    required this.icon,
    this.customIconUrl,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              splashColor: widget.iconColor.withValues(alpha: 0.08),
              highlightColor: widget.iconColor.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Gradient Background for Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.gradientColors,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.gradientColors.last.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                       child: widget.customIconUrl != null && widget.customIconUrl!.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                widget.customIconUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.icon,
                                  color: widget.iconColor,
                                  size: 20,
                                ),
                              ),
                            )
                          : Icon(
                              widget.icon,
                              color: widget.iconColor,
                              size: 20,
                            ),
                    ),
                    const SizedBox(height: 4),
                    // Centered Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (widget.price != null) ...[
                      const SizedBox(height: 1),
                      // Starting Price
                      Text(
                        widget.price!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
