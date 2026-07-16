import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      title: "Everything you need\nat your doorstep",
      description: "Book home services like plumbing, cleaning, painting and more with just a few clicks.",
    ),
    OnboardingData(
      image: "assets/images/onboarding_2_home_cleaning_illustration_retry_1774853265369.png",
      title: "Trusted Professionals\nHighly Rated",
      description: "Our experts are background checked and verified to ensure your safety and quality service.",
    ),
    OnboardingData(
      image: "assets/images/onboarding_3_convenient_service_illustration_1774853244833.png",
      title: "Convenient & Fast\nHassle-free",
      description: "Simple booking process, real-time tracking, and secure payment options for all services.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > constraints.maxHeight;
                  return Container(
                    color: const Color(0xFFE6EAEB),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _onboardingData[index].image,
                          fit: isWide ? BoxFit.contain : BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                        _buildGradientOverlay(),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Content
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDots(),
                    const Spacer(),
                    Text(
                      _onboardingData[_currentPage].title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width > 600 ? 42 : 34,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _onboardingData[_currentPage].description,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(
        _onboardingData.length,
        (index) => Container(
          width: _currentPage == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentPage != _onboardingData.length - 1)
          TextButton(
            onPressed: () => _pageController.jumpToPage(_onboardingData.length - 1),
            child: Text(
              "SKIP",
              style: GoogleFonts.outfit(color: Colors.white70, letterSpacing: 1.2),
            ),
          )
        else
          const SizedBox(width: 50),
        ElevatedButton(
          onPressed: () {
            if (_currentPage == _onboardingData.length - 1) {
              Navigator.pushReplacementNamed(context, '/login');
            } else {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text(
            _currentPage == _onboardingData.length - 1 ? "GET STARTED" : "NEXT",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;
  OnboardingData({required this.image, required this.title, required this.description});
}
