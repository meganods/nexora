import re

with open('lib/screens/dashboard_screen.dart', 'r') as f:
    content = f.read()

# Add import
content = content.replace("import '../widgets/single_promo_banner.dart';", "import '../widgets/single_promo_banner.dart';\nimport '../widgets/hero_banner_carousel.dart';")

# 1. Remove state fields
content = content.replace(
    '  final PageController _bannerController = PageController(initialPage: 300);\n',
    ''
)
content = content.replace(
    '  int _currentBannerIndex = 0;\n',
    ''
)
content = content.replace(
    '  Timer? _bannerTimer;\n',
    ''
)

# 2. Remove from initState
content = content.replace(
    '    _startBannerTimer();\n',
    ''
)

# 3. Remove _startBannerTimer function
start_timer_func = """  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients) {
        int nextPage = _bannerController.page!.round() + 1;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }
"""
content = content.replace(start_timer_func, '')

# 4. Remove from dispose
content = content.replace(
    '    _bannerTimer?.cancel();\n',
    ''
)
content = content.replace(
    '    _bannerController.dispose();\n',
    ''
)

# 5. Remove _banners list (try exact match or regex)
# Let's use regex to find _banners list
banners_pattern = r'  final List<BannerData> _banners = \[\n(?:    BannerData\(\n(?:      [a-z]+: "[^"]*",\n)+\n    \),\n)+  \];\n'
content = re.sub(banners_pattern, '', content)

# 6. Remove post frame callback
post_frame = """    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_bannerTimer == null || !_bannerTimer!.isActive)) {
        _startBannerTimer();
      }
    });

"""
content = content.replace(post_frame, '')

# 7. Replace _buildBannerCarousel() with const HeroBannerCarousel()
content = content.replace('                  _buildBannerCarousel(),', '                  const HeroBannerCarousel(),')

# 8. Remove _buildBannerCarousel, _campaignColor, and _campaignIcon methods
# We will just remove from "  Widget _buildBannerCarousel() {" down to "default:            return Icons.star_outlined;\n    }\n  }\n"
start_build_banner = content.find('  Widget _buildBannerCarousel() {')
end_campaign_icon = content.find('      default:            return Icons.star_outlined;\n    }\n  }')
if start_build_banner != -1 and end_campaign_icon != -1:
    end_campaign_icon += len('      default:            return Icons.star_outlined;\n    }\n  }')
    methods_str = content[start_build_banner:end_campaign_icon]
    content = content.replace(methods_str + '\n', '')

# Remove BannerData class from the file (at the end)
content = re.sub(r'class BannerData \{[^}]+\}', '', content)

with open('lib/screens/dashboard_screen.dart', 'w') as f:
    f.write(content)
