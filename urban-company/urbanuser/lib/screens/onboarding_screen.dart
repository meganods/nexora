import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Trusted Professionals',
      'subtitle': 'Book verified professionals in minutes.',
      'image': 'assets/onboarding/image.png',
    },
    {
      'title': 'Track Every Service',
      'subtitle': 'Know exactly when your professional will arrive with real-time map updates and smart notifications.',
      'image': 'assets/onboarding/image copy.png',
    },
    {
      'title': 'Fast & Secure Payments',
      'subtitle': 'Pay securely with multiple payment options.',
      'image': 'assets/onboarding/image copy 2.png',
    },
  ];

  Future<void> _completeOnboarding(String routeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding('/login');
    }
  }

  void _onBack() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);
    const textPrimary = Color(0xFF131B2E);
    const textSecondary = Color(0xFF434655);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC), // Light off-white
              Color(0xFFEEF6FF), // Soft light blue
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: brandBlue, size: 24),
                          onPressed: () => _completeOnboarding('/login'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NEXORA',
                          style: GoogleFonts.outfit(
                            color: brandBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _completeOnboarding('/login'),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          color: brandBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Swiper
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Illustration container
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(29), // slightly less than container to sit nicely inside border
                                child: Image.asset(
                                  slide['image']!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.handyman_rounded, color: brandBlue, size: 100);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            slide['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 12),
                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              slide['subtitle']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ).animate().fade(duration: 450.ms).slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 36),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Indicator & Controls Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    // Progress Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index ? brandBlue : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Navigation buttons row
                    Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: _currentIndex > 0 ? _onBack : null,
                          child: Opacity(
                            opacity: _currentIndex > 0 ? 1.0 : 0.4,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: brandBlue,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Next Button
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _onNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentIndex == _slides.length - 1 ? 'Get Started' : 'Next',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
