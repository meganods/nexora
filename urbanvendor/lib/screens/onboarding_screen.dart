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
      title: "Grow your business\nwith Urban Company",
      description: "Join our network of 100k+ pros and start getting high-quality leads at your doorstep.",
    ),
    OnboardingData(
      image: "assets/images/onboarding_2_home_cleaning_illustration_retry_1774853265369.png",
      title: "Manage bookings\non the go",
      description: "Our high-end vendor portal lets you track orders, manage payments, and update status in real-time.",
    ),
    OnboardingData(
      image: "assets/images/onboarding_3_convenient_service_illustration_1774853244833.png",
      title: "Fast Payouts\nGuaranteed",
      description: "Enjoy secure and transparent payment processing with settlements directly to your bank account.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_onboardingData[index].image, fit: BoxFit.cover),
                  _buildGradientOverlay(),
                ],
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDots(),
                const SizedBox(height: 30),
                Text(_onboardingData[_currentPage].title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 20),
                Text(_onboardingData[_currentPage].description, style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                const SizedBox(height: 50),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.9)]),
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
          decoration: BoxDecoration(color: _currentPage == index ? AppTheme.primaryColor : Colors.white38, borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentPage != _onboardingData.length - 1)
          TextButton(onPressed: () => _pageController.jumpToPage(_onboardingData.length - 1), child: Text("SKIP", style: GoogleFonts.outfit(color: Colors.white70, letterSpacing: 1.2)))
        else
          const SizedBox(width: 50),
        ElevatedButton(
          onPressed: () {
            if (_currentPage == _onboardingData.length - 1) {
              Navigator.pushReplacementNamed(context, '/shop_setup');
            } else {
              _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
          child: Text(_currentPage == _onboardingData.length - 1 ? "GET STARTED" : "NEXT", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String image, title, description;
  OnboardingData({required this.image, required this.title, required this.description});
}
