import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          "Privacy Policy",
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
                "We respect your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, store, use, and protect your data when you use the NEXORA platform.",
              ),
              _buildSection(
                "Information We Collect",
                "We may collect the following types of information:\n\n• Name and profile details\n• Phone number and email address\n• Service addresses\n• Payment and billing information\n• Device and app usage analytics",
              ),
              _buildSection(
                "How We Use Information",
                "We use the collected information to:\n\n• Process your bookings and deliver services\n• Manage your user account\n• Improve app performance and features\n• Prevent fraud and ensure safety\n• Provide customer support\n• Send important service updates",
              ),
              _buildSection(
                "Location Data",
                "Location information is essential to our platform. We may use it to:\n\n• Show nearby service providers\n• Improve booking accuracy and navigation\n• Enhance service delivery\n\nYou can disable location access through your device settings at any time, though some features may become unavailable.",
              ),
              _buildSection(
                "Payment Information",
                "All payments are securely processed through trusted third-party payment providers. We do not store your complete credit or debit card details on our servers.",
              ),
              _buildSection(
                "Sharing of Information",
                "Your information may be shared with:\n\n• Service professionals fulfilling your bookings\n• Trusted payment partners\n• Analytics and operational service providers\n• Legal authorities when required by law\n\nWe never sell your personal information to third parties.",
              ),
              _buildSection(
                "Data Retention",
                "We retain your personal information only for as long as necessary to fulfill the operational, legal, and security purposes outlined in this policy.",
              ),
              _buildSection(
                "Data Security",
                "We implement robust security measures to protect your data, including encryption protocols, secure servers, strict access controls, and constant security monitoring.",
              ),
              _buildSection(
                "Your Rights",
                "As a user, you have the right to:\n\n• Access your personal data\n• Update or correct your information\n• Request data deletion\n• Withdraw consent for non-essential processing\n• Request account closure",
              ),
              _buildSection(
                "Cookies & Analytics",
                "The app may use cookies, SDKs, and similar tracking technologies to improve user experience, monitor performance, and deliver personalized content.",
              ),
              _buildSection(
                "Children's Privacy",
                "Our platform is not intended for users under 13 years of age. We do not knowingly collect personal information from children.",
              ),
              _buildSection(
                "Changes to This Policy",
                "We may update this policy periodically to reflect changes in our practices or relevant laws. Significant changes will be communicated to you within the application.",
              ),
              _buildSection(
                "Contact Us",
                "If you have any questions or concerns regarding this Privacy Policy, please contact our privacy team:\n\nEmail: privacy@nexora.com\nPhone: +91 XXXXX XXXXX",
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
