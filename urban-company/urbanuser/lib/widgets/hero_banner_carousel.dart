import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/category_detail_screen.dart';

class BannerData {
  final String title;
  final String subtitle;
  final String discount;
  final String image;

  BannerData({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.image,
  });
}

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

  Color _campaignColor(String type) {
    switch (type) {
      case 'Festival':    return const Color(0xFFF59E0B);
      case 'Flash Sale':  return const Color(0xFFEF4444);
      case 'Referral':    return const Color(0xFF10B981);
      case 'Seasonal':    return const Color(0xFF06B6D4);
      case 'Limited Time': return const Color(0xFFEC4899);
      default:            return const Color(0xFF6366F1);
    }
  }

  IconData _campaignIcon(String type) {
    switch (type) {
      case 'Festival':    return Icons.celebration_outlined;
      case 'Flash Sale':  return Icons.bolt_outlined;
      case 'Referral':    return Icons.group_outlined;
      case 'Seasonal':    return Icons.ac_unit_outlined;
      case 'Limited Time': return Icons.timer_outlined;
      default:            return Icons.star_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (ctx, adminSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vendor_campaigns')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (ctx2, vendorSnap) {
            final now = DateTime.now();
            final liveBanners = <Map<String, dynamic>>[];

            for (final doc in (adminSnap.data?.docs ?? [])) {
              final d = doc.data() as Map<String, dynamic>;
              final end = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
              final start = d['startDate'] != null ? (d['startDate'] as Timestamp).toDate() : null;
              final notExpired = end == null || end.isAfter(now);
              final hasStarted = start == null || !start.isAfter(now);
              if (notExpired && hasStarted) {
                liveBanners.add({...d, '_source': 'admin'});
              }
            }

            for (final doc in (vendorSnap.data?.docs ?? [])) {
              final d = doc.data() as Map<String, dynamic>;
              final placements = List<String>.from(d['placements'] ?? []);
              if (!placements.contains('hero_banner')) continue;
              final end = d['endDate'] != null ? (d['endDate'] as Timestamp).toDate() : null;
              final start = d['startDate'] != null ? (d['startDate'] as Timestamp).toDate() : null;
              final adminFee = ((d['adminFee'] ?? 0) as num).toDouble();
              final feePaid = d['feePaid'] == true;
              final feeCleared = adminFee == 0 || feePaid;
              final notExpired = end == null || end.isAfter(now);
              final hasStarted = start == null || !start.isAfter(now);
              if (feeCleared && notExpired && hasStarted) {
                liveBanners.add({...d, '_source': 'vendor'});
              }
            }

            final totalBannerCount = liveBanners.length + _banners.length;

            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBannerIndex = index % totalBannerCount;
                      });
                    },
                    itemCount: 10000,
                    itemBuilder: (context, index) {
                      final realIndex = index % totalBannerCount;

                      if (realIndex < liveBanners.length) {
                        final d = liveBanners[realIndex];
                        final Color bgColor = _campaignColor(d['type'] ?? '');
                        final bool isAdmin = d['_source'] == 'admin';
                        final hasImage = d['imageUrl'] != null;

                        if (hasImage) {
                          return GestureDetector(
                            onTap: () {
                              String targetCategory = "Cleaning";
                              final type = (d['type'] ?? '').toString().toLowerCase();
                              if (type.contains("repair") || type.contains("seasonal")) {
                                targetCategory = "Plumber";
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryDetailScreen(categoryName: targetCategory),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.network(d['imageUrl'], fit: BoxFit.cover),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [bgColor, bgColor.withValues(alpha: 0.65)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: bgColor.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.22),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              (d['type'] ?? 'PROMO').toUpperCase(),
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 8,
                                                  fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (isAdmin)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text('NEXORA',
                                                  style: TextStyle(
                                                      color: Colors.white70, fontSize: 8,
                                                      fontWeight: FontWeight.bold)),
                                            )
                                          else
                                            Flexible(
                                              child: Text(
                                                'by ${d['businessName'] ?? d['vendorName'] ?? ''}',
                                                style: const TextStyle(color: Colors.white70, fontSize: 9),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        d['name'] ?? d['title'] ?? 'Special Campaign',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 19,
                                            fontWeight: FontWeight.w900),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        d['description'] ?? d['subtitle'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 11, height: 1.3),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _campaignIcon(d['type'] ?? ''),
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final banner = _banners[(realIndex - liveBanners.length) % _banners.length];
                      return GestureDetector(
                        onTap: () {
                          String targetCategory = "Cleaning";
                          if (banner.title.contains("Repair") || banner.title.contains("Maintenance")) {
                            targetCategory = "Plumber";
                          } else if (banner.title.contains("Car")) {
                            targetCategory = "Car Wash";
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailScreen(categoryName: targetCategory),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: banner.image.startsWith("http")
                                    ? Image.network(banner.image, fit: BoxFit.cover)
                                    : Image.asset(banner.image, fit: BoxFit.cover),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalBannerCount,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentBannerIndex == index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: _currentBannerIndex == index
                            ? const Color(0xFF673AB7)
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
