import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
                ),
              ),
              const SizedBox(height: 40),
              Text("Thank You!", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
              const SizedBox(height: 10),
              Text("Your booking is successful", style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Booking ID: ", style: GoogleFonts.outfit(color: Colors.grey[600])),
                    Text("#UC-882201", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              _buildButton("MY BOOKING PAGE", () => Navigator.pushNamed(context, '/my_bookings'), isPrimary: true),
              const SizedBox(height: 15),
              _buildButton("CONTINUE BOOKING", () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false), isPrimary: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {required bool isPrimary}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.accentColor : Colors.white,
          foregroundColor: isPrimary ? Colors.white : AppTheme.accentColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1)),
      ),
    );
  }
}
