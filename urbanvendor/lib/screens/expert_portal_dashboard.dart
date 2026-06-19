import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/vendor_provider.dart';
import '../services/cloudinary_service.dart';
import 'bookings_screen.dart';

class ExpertPortalDashboard extends StatefulWidget {
  const ExpertPortalDashboard({super.key});

  @override
  State<ExpertPortalDashboard> createState() => _ExpertPortalDashboardState();
}

class _ExpertPortalDashboardState extends State<ExpertPortalDashboard> {
  int _currentTab = 0;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorProvider>(context, listen: false).fetchVendorData();
    });
  }

  Future<void> _pickAndUploadImage(bool isBanner) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final url = await CloudinaryService.uploadImageBytes(bytes: bytes, fileName: pickedFile.name);
        if (url != null) {
          final updates = isBanner ? {'bannerUrl': url} : {'brandLogo': url};
          if (!mounted) return;
          await Provider.of<VendorProvider>(context, listen: false).updateVendorProfile(updates);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image updated successfully!')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final vendor = vendorProvider.vendorData;

    if (vendorProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _currentTab == 0 ? _buildDashboardTab(vendorProvider, vendor) : _buildBookingsTab(),
      floatingActionButton: _currentTab == 0 ? _buildFAB() : null,
      bottomNavigationBar: _buildBottomTabs(),
    );
  }

  Widget _buildBookingsTab() {
    return const BookingsScreen();
  }

  Widget _buildDashboardTab(VendorProvider vendorProvider, Map<String, dynamic>? vendor) {
    return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. HERO HEADER WITH COVER BANNER
          _buildHeroHeader(vendor),

          // 2. DASHBOARD CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATS CARDS
                  _buildStatsGrid(vendor),
                  const SizedBox(height: 32),

                  // STORE SETUP STATUS (IF NOT COMPLETE)
                  if (!(vendor?['storeSetupComplete'] ?? false))
                    _buildSetupProgressCard(),

                  const SizedBox(height: 10),
                  _buildSectionHeader('Management', () {
                    Navigator.pushNamed(context, '/my_services');
                  }),
                  const SizedBox(height: 16),
                  _buildQuickActionGrid(),

                  const SizedBox(height: 32),

                  // RECENT REVIEWS PREVIEW
                  _buildSectionHeader('Recent Feedback', () => Navigator.pushNamed(context, '/vendor_store')),
                  const SizedBox(height: 16),
                  _buildReviewsPreview(vendorProvider),

                  const SizedBox(height: 32),

                  // GALLERY PREVIEW
                  _buildSectionHeader('Store Gallery', () => Navigator.pushNamed(context, '/store_setup')),
                  const SizedBox(height: 16),
                  _buildGalleryPreview(vendor?['gallery'] ?? []),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildHeroHeader(Map<String, dynamic>? vendor) {
    const primaryBlue = Color(0xFF4F46E5);
    final String brandName = vendor?['brandName'] ?? vendor?['businessName'] ?? 'Business Name';
    final String? logoUrl = vendor?['brandLogo'];
    final String? bannerUrl = vendor?['bannerUrl'];

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Background
            GestureDetector(
              onTap: () => _pickAndUploadImage(true),
              child: Container(
                decoration: BoxDecoration(
                  gradient: bannerUrl == null ? const LinearGradient(
                    colors: [primaryBlue, Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  image: bannerUrl != null ? DecorationImage(image: NetworkImage(bannerUrl), fit: BoxFit.cover) : null,
                ),
              ),
            ),
            // Abstract Decorative Circles
            Positioned(top: -50, right: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.05))),
            
            // Header Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo
                  GestureDetector(
                    onTap: () => _pickAndUploadImage(false),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                            image: logoUrl != null ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover) : null,
                          ),
                          child: logoUrl == null ? const Icon(Icons.store_rounded, color: primaryBlue, size: 30) : null,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Brand Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(brandName, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 16),
                          ],
                        ),
                        Text(vendor?['tagline'] ?? 'Professional Service Provider', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text('${vendor?['rating'] ?? 4.9}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('  (${vendor?['reviewsCount'] ?? 0} reviews)', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
        }, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20)),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? vendor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard('Earnings', '₹12,450', Icons.account_balance_wallet_rounded, [const Color(0xFF6366F1), const Color(0xFF4F46E5)]),
          const SizedBox(width: 12),
          _buildStatCard('Bookings', '28', Icons.calendar_today_rounded, [const Color(0xFFF59E0B), const Color(0xFFD97706)]),
          const SizedBox(width: 12),
          _buildStatCard('Pending', '03', Icons.pending_actions_rounded, [const Color(0xFFEC4899), const Color(0xFFDB2777)]),
          const SizedBox(width: 12),
          _buildStatCard('Profile Views', '1.2k', Icons.visibility_rounded, [const Color(0xFF10B981), const Color(0xFF059669)]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> colors) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSetupProgressCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, color: Colors.blue, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete Your Store', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Improve your ranking by 40% with a full profile.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/store_setup'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), minimumSize: const Size(double.infinity, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Add Brand Details', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildActionItem('Services', Icons.grid_view_rounded, Colors.indigo, () => Navigator.pushNamed(context, '/my_services')),
        _buildActionItem('Profile', Icons.person_rounded, Colors.purple, () => Navigator.pushNamed(context, '/partner_profile')),
        _buildActionItem('Store', Icons.storefront_rounded, Colors.orange, () => Navigator.pushNamed(context, '/vendor_store')),
        _buildActionItem('Reviews', Icons.star_outline_rounded, Colors.pink, () => Navigator.pushNamed(context, '/vendor_store')),
      ],
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildReviewsPreview(VendorProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: provider.streamVendorReviews(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No reviews yet. Quality service brings good feedback!', Icons.reviews_outlined);
        }
        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: Colors.indigo[50], child: Text(data['userName']?[0] ?? 'C')),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['userName'] ?? 'Customer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(data['comment'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 16), Text(' ${data['rating']}', style: const TextStyle(fontWeight: FontWeight.bold))]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryPreview(List gallery) {
    if (gallery.isEmpty) return _buildEmptyState('Share your work photos!', Icons.image_outlined);
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gallery.length,
        itemBuilder: (context, index) => Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(gallery[index]), fit: BoxFit.cover)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        TextButton(onPressed: onSeeAll, child: Text('See All', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[50]!, style: BorderStyle.none)),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[300], size: 30),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/my_services'),
      backgroundColor: const Color(0xFF4F46E5),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text('Add Service', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildBottomTabs() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) {
          if (i == 3) {
            Navigator.pushNamed(context, '/partner_profile');
          } else if (i == 2) {
            Navigator.pushNamed(context, '/my_services');
          } else {
            setState(() => _currentTab = i);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.design_services_rounded), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
