import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      image: "assets/images/onboarding_1_handyman_illustration_1774853199914.png",
      title: "Trusted Professionals",
      description: "Book verified professionals in minutes.",
    ),
    OnboardingData(
      image: "assets/images/onboarding_2_home_cleaning_illustration_retry_1774853265369.png",
      title: "Track Every Service",
      description: "Know exactly when your professional will arrive with real-time map updates and smart notifications.",
    ),
    OnboardingData(
      image: "assets/images/onboarding_3_convenient_service_illustration_1774853244833.png",
      title: "Fast & Secure Payments",
      description: "Pay securely with multiple payment options.",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. App Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF131B2E), size: 24),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  ),
                  Row(
                    children: [
                      if (_currentPage == 2)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                        ),
                      Text(
                        "NEXORA",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5,
                          color: const Color(0xFF004AC6),
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        "Skip",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48), // Spacer to balance layout
                ],
              ),
            ),

            // 2. Illustration Card and PageView
            Expanded(
              flex: 12,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final item = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card wrapper with soft ambient shadow
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                color: const Color(0xFFE5EEFF),
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  item.image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 48 : 36),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 32 : 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF131B2E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 18 : 15,
                              color: const Color(0xFF434655),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Dot Indicators
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFC3C6D7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Action Buttons (Next/Back)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    GestureDetector(
                      onTap: _previousPage,
                      child: Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEDFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_left_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? "Get Started" : "Next",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Steps Navigation Row
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) => _buildStepTab(index)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTab(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAEDFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF737686),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            "Step ${index + 1}",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF004AC6) : const Color(0xFF737686),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;
  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
