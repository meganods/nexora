import re

with open('lib/screens/dashboard_screen.dart', 'r') as f:
    content = f.read()

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

# 5. Remove _banners
banners_list = """  final List<BannerData> _banners = [
    BannerData(
      title: "",
      subtitle: "",
      discount: "",
      image: "assets/images/banner_img/image.png",
    ),
    BannerData(
      title: "",
      subtitle: "",
      discount: "",
      image: "assets/images/banner_img/image copy.png",
    ),
    BannerData(
      title: "",
      subtitle: "",
      discount: "",
      image: "assets/images/banner_img/image copy 2.png",
    ),
  ];
"""
content = content.replace(banners_list, '')

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

# 8. Extract methods
# Find _buildBannerCarousel
start_build_banner = content.find('  Widget _buildBannerCarousel() {')
# Find the end of _campaignIcon
end_campaign_icon = content.find('      default:            return Icons.star_outlined;\n    }\n  }')
if end_campaign_icon != -1:
    end_campaign_icon += len('      default:            return Icons.star_outlined;\n    }\n  }')
    
methods_str = content[start_build_banner:end_campaign_icon]

# Remove them from the original class
content = content.replace(methods_str + '\n', '')

# Create the new class
new_class = """
class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({super.key});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _bannerController = PageController(initialPage: 300);
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  
  final List<BannerData> _banners = [
    BannerData(
      title: "",
      subtitle: "",
      discount: "",
      image: "assets/images/banner_img/image.png",
    ),
    BannerData(
      title: "",
      subtitle: "",
      discount: "",
      image: "assets/images/banner_img/image copy.png",
    ),
    BannerData(
      title: "",
      subtitle: "",
      discount: "",
      image: "assets/images/banner_img/image copy 2.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }
  
  void _startBannerTimer() {
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
  
  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

"""

methods_str = methods_str.replace('  Widget _buildBannerCarousel() {', '  @override\n  Widget build(BuildContext context) {')
# The methods need to be un-indented slightly or we just paste them in. They are indented by 2 spaces, perfect for inside the State class.
new_class += methods_str + '\n}\n'

content = content + '\n' + new_class

with open('lib/screens/dashboard_screen.dart', 'w') as f:
    f.write(content)
