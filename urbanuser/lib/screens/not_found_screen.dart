import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotFoundScreen extends StatelessWidget {
  static const routeName = '/404';

  const NotFoundScreen({super.key});

  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // 404 Illustration / Icon
              Center(
                child: Container(
                  height: 160, width: 160,
                  decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                  child: const Icon(Icons.search_off_rounded, size: 100, color: Colors.grey),
                ).animate().fade().scale(duration: 500.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(height: 32),

              // 404 Text
              const Text(
                '404',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              Text(
                'The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              
              const Spacer(),

              // Action Buttons
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Go Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/search'),
                icon: const Icon(Icons.search, color: primaryColor),
                label: const Text('Search Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
