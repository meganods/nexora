import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentFailedScreen extends StatelessWidget {
  static const routeName = '/payment_failed';

  const PaymentFailedScreen({super.key});

  static const primaryColor = Color(0xFF0F172A);
  static const errorColor = Color(0xFFE53935);
  static const bgColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Failure Animation / Icon
              Center(
                child: Container(
                  height: 120, width: 120,
                  decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline, size: 80, color: errorColor),
                ).animate().shake(duration: 500.ms, hz: 4),
              ),
              const SizedBox(height: 32),

              // Failure Text
              const Text(
                'Payment Failed',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'We could not process your payment.\nPlease check your connection or try another payment method.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 40),

              // Error Details Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Error Code', style: TextStyle(color: Colors.grey.shade600)),
                        const Text('ERR_TIMEOUT_408', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount', style: TextStyle(color: Colors.grey.shade600)),
                        const Text('â‚¹1,448', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const Spacer(),

              // Action Buttons
              ElevatedButton(
                onPressed: () => Navigator.pop(context), // Pops back to checkout to retry
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Retry Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/help_support'),
                icon: const Icon(Icons.support_agent, color: primaryColor),
                label: const Text('Contact Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
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
