import re

with open('lib/screens/dashboard_screen.dart', 'r') as f:
    content = f.read()

# Add import
content = content.replace(
    "import '../widgets/single_promo_banner.dart';", 
    "import '../widgets/single_promo_banner.dart';\nimport '../widgets/hero_banner_carousel.dart';"
)

# Remove _bannerController
content = re.sub(r'  final PageController _bannerController = PageController\(initialPage: 300\);\n', '', content)
# Remove _currentBannerIndex
content = re.sub(r'  int _currentBannerIndex = 0;\n', '', content)
# Remove _bannerTimer
content = re.sub(r'  Timer\? _bannerTimer;\n', '', content)

# Remove _startBannerTimer call from initState
content = re.sub(r'    _startBannerTimer\(\);\n', '', content)

# Remove _startBannerTimer definition
start_timer_pattern = r'  void _startBannerTimer\(\) \{[\s\S]*?  \}\n\n'
content = re.sub(start_timer_pattern, '', content)

# Remove from dispose
content = re.sub(r'    _bannerTimer\?\.cancel\(\);\n', '', content)
content = re.sub(r'    _bannerController\.dispose\(\);\n', '', content)

# Remove _banners
banners_pattern = r'  final List<BannerData> _banners = \[\n(?:    BannerData\(\n(?:      [a-z]+: "[^"]*",\n)+\n    \),\n)+  \];\n\n'
content = re.sub(banners_pattern, '', content)

# Remove addPostFrameCallback
post_frame = r'    WidgetsBinding\.instance\.addPostFrameCallback\(\(\_\) \{\n      if \(mounted && \(_bannerTimer == null \|\| !_bannerTimer!\.isActive\)\) \{\n        _startBannerTimer\(\);\n      \}\n    \}\);\n\n'
content = re.sub(post_frame, '', content)

# Replace _buildBannerCarousel() call
content = content.replace('                  _buildBannerCarousel(),', '                  const HeroBannerCarousel(),')

# Remove _buildBannerCarousel definition (lines 418 to 493)
# It's followed by `  Widget _buildPageIndicator() {`
build_banner_pattern = r'  Widget _buildBannerCarousel\(\) \{[\s\S]*?    \);\n  \}\n\n'
content = re.sub(build_banner_pattern, '', content)

# Remove BannerData class
banner_data_class_pattern = r'class BannerData \{[\s\S]*?\}\n'
content = re.sub(banner_data_class_pattern, '', content)

with open('lib/screens/dashboard_screen.dart', 'w') as f:
    f.write(content)
