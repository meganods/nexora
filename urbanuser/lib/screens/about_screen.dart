import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'help_center_screen.dart';
import 'terms_conditions_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About Us",
          style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(),
              _buildMissionCard(),
              _buildStatistics(),
              _buildWhyChooseUs(),
              _buildAppInfo(),
              _buildSocialLinks(),
              _buildLegalSection(context),
              _buildContactSection(),
              _buildFooter(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.grey[50],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.home_repair_service,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Urban Company",
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Professional Home Services at Your Doorstep",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  "Our Mission",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Our mission is to simplify everyday living by connecting customers with trusted professionals for high-quality home services through a seamless digital experience.",
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = [
      {"count": "10k+", "label": "Customers"},
      {"count": "5k+", "label": "Services"},
      {"count": "500+", "label": "Pros"},
      {"count": "4.8", "label": "Rating"},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stats.map((stat) {
          return Column(
            children: [
              Text(
                stat["count"]!,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat["label"]!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhyChooseUs() {
    final reasons = [
      {"icon": Icons.verified_user_outlined, "title": "Verified Professionals"},
      {"icon": Icons.price_check_outlined, "title": "Transparent Pricing"},
      {"icon": Icons.event_available_outlined, "title": "Easy Booking"},
      {"icon": Icons.payment_outlined, "title": "Secure Payments"},
      {"icon": Icons.support_agent_outlined, "title": "Customer Support"},
      {"icon": Icons.thumb_up_outlined, "title": "Satisfaction Guarantee"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Why Choose Us",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reasons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(reasons[index]["icon"] as IconData, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reasons[index]["title"] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentColor,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem("App Version", "1.0.0"),
          _infoItem("Build Number", "1"),
          _infoItem("Platform", "Android / iOS"),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _socialButton(Icons.language, () {}),
          _socialButton(Icons.facebook, () {}),
          _socialButton(Icons.camera_alt_outlined, () {}),
          _socialButton(Icons.alternate_email, () {}),
          _socialButton(Icons.work_outline, () {}),
          _socialButton(Icons.play_circle_outline, () {}),
        ],
      ),
    );
  }

  Widget _socialButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Legal & Support",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _legalLink(context, "Privacy Policy", const PrivacyPolicyScreen()),
                Divider(height: 1, color: Colors.grey[200]),
                _legalLink(context, "Terms & Conditions", const TermsConditionsScreen()),
                Divider(height: 1, color: Colors.grey[200]),
                _legalLink(context, "Refund Policy", const TermsConditionsScreen()),
                Divider(height: 1, color: Colors.grey[200]),
                _legalLink(context, "Help Center", const HelpCenterScreen(), isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalLink(BuildContext context, String title, Widget targetScreen, {bool isLast = false}) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.accentColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
      },
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(
              "Contact Information",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 16),
            _contactRow(Icons.location_on_outlined, "123 Urban Street, Tech City, 10001"),
            const SizedBox(height: 12),
            _contactRow(Icons.email_outlined, "support@urbancompany.com"),
            const SizedBox(height: 12),
            _contactRow(Icons.phone_outlined, "+91 98765 43210"),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        "© 2026 Urban Company Clone.\nAll Rights Reserved.",
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}
