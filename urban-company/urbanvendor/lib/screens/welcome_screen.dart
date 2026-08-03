import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vendor_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _slides.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _slides = [
    {
      "title": "Grow Your Business",
      "desc": "Access thousands of home service booking requests in your neighborhood daily."
    },
    {
      "title": "Flexible Hours",
      "desc": "You are the boss. Work when you want, set your availability calendar and breaks."
    },
    {
      "title": "Instant Withdrawals",
      "desc": "Receive direct bank transfers of your earnings with transparent commission logs."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildDesktopLayout();
          }
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Column: Brand Hero Banner
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFFEFF6FF), // Light slate / Soft Blue panel
            padding: const EdgeInsets.all(64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: VendorTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "NEXORA",
                      style: GoogleFonts.outfit(color: VendorTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Text(
                  "Empowering Service\nProfessionals Globally",
                  style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary, height: 1.2),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.1),
                const SizedBox(height: 24),
                Text(
                  "Manage client bookings, configure service custom rates, track earnings, and coordinate with clients seamlessly.",
                  style: GoogleFonts.inter(fontSize: 16, color: VendorTheme.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        // Right Column: Auth Cards Container
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                height: 540,
                padding: const EdgeInsets.all(40),
                child: _buildWelcomeCardContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handyman_rounded, color: VendorTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  "NEXORA",
                  style: GoogleFonts.outfit(color: VendorTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Expanded(
              child: _buildWelcomeCardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCardContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
              _startAutoScroll(); // Reset timer on manual swipe
            },
            itemCount: _slides.length,
            itemBuilder: (context, idx) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: VendorTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      idx == 0
                          ? Icons.trending_up_rounded
                          : idx == 1
                              ? Icons.alarm_on_rounded
                              : Icons.payments_rounded,
                      color: VendorTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _slides[idx]["title"]!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: VendorTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _slides[idx]["desc"]!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: VendorTheme.textSecondary, height: 1.5),
                  ),
                ],
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slides.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? VendorTheme.primaryColor : VendorTheme.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text("Become a Partner"),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text("Already Registered"),
          ),
        ),
      ],
    );
  }
}
