import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Terms & Conditions",
          style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Last Updated: June 12, 2026",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                "Introduction",
                "By accessing or using the NEXORA platform, you agree to comply with and be bound by these Terms & Conditions. Please read them carefully.",
              ),
              _buildSection(
                "User Responsibilities",
                "Users must provide accurate information when booking a service, ensure a safe environment for professionals, and complete payments promptly upon service completion.",
              ),
              _buildSection(
                "Booking Rules",
                "Bookings are subject to professional availability. We reserve the right to decline or reschedule bookings due to unforeseen circumstances or safety concerns.",
              ),
              _buildSection(
                "Cancellation Policy",
                "You may cancel a booking up to 2 hours before the scheduled time without penalty. Late cancellations may incur a cancellation fee as specified in the app.",
              ),
              _buildSection(
                "Refund Policy",
                "Refunds are processed for incomplete or unsatisfactory services after a formal review by our support team. Approved refunds will be credited within 5–7 business days.",
              ),
              _buildSection(
                "Professional Conduct",
                "Our service professionals are expected to maintain the highest standards of behavior. Any misconduct by either the professional or the customer will lead to account suspension.",
              ),
              _buildSection(
                "Liability Disclaimer",
                "NEXORA acts as an intermediary connecting users with independent professionals. We are not liable for any direct or indirect damages resulting from the services provided.",
              ),
              _buildSection(
                "Governing Law",
                "These terms are governed by the laws of the jurisdiction in which the company operates. Any disputes will be subject to the exclusive jurisdiction of the local courts.",
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
