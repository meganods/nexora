import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/vendor_provider.dart';
import 'store_setup_screen.dart';

class VendorStorePage extends StatelessWidget {
  const VendorStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vendor = Provider.of<VendorProvider>(context).vendorData;
    const primaryBlue = Color(0xFF4A55ED);

    if (vendor == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final String brandName = vendor['brandName'] ?? vendor['businessName'] ?? 'Your Brand';
    final String? logoUrl = vendor['brandLogo'];
    final double rating = vendor['rating'] ?? 4.9;
    final int reviews = vendor['reviewsCount'] ?? 158;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. BRAND HEADER
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreSetupScreen(initialTabIndex: 0))),
                icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                label: Text('Edit Store', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  _buildHeaderContent(brandName, logoUrl, rating, reviews),
                ],
              ),
            ),
          ),

          // 2. ABOUT SECTION
          SliverToBoxAdapter(
            child: _buildSectionWrapper(
              title: 'About',
              icon: Icons.info_outline_rounded,
              onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreSetupScreen(initialTabIndex: 1))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor['about'] ?? 'No description provided yet.',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(Icons.history_rounded, '${vendor['experience'] ?? '0+'} exp'),
                      const SizedBox(width: 8),
                      _buildInfoChip(Icons.workspace_premium_rounded, vendor['specializations']?.join(', ') ?? 'Expert'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. OFFERS SECTION
          if ((vendor['offers'] as List?)?.isNotEmpty ?? false)
            SliverToBoxAdapter(
              child: _buildSectionWrapper(
                title: 'Specials & Offers',
                icon: Icons.celebration_rounded,
                onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreSetupScreen(initialTabIndex: 3))),
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (vendor['offers'] as List).length,
                    itemBuilder: (context, index) {
                      final offer = vendor['offers'][index];
                      return _buildOfferCard(offer);
                    },
                  ),
                ),
              ),
            ),

          // 4. SERVICES LIST
          SliverToBoxAdapter(
            child: _buildSectionWrapper(
              title: 'Our Services',
              icon: Icons.design_services_rounded,
              onEdit: () => Navigator.pushNamed(context, '/my_services'),
              child: _buildServicesList(context, vendor),
            ),
          ),

          // 5. GALLERY SECTION
          SliverToBoxAdapter(
            child: _buildSectionWrapper(
              title: 'Gallery',
              icon: Icons.photo_library_rounded,
              onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreSetupScreen(initialTabIndex: 2))),
              child: _buildGallery(vendor['gallery'] ?? []),
            ),
          ),

          // 6. TESTIMONIALS
          SliverToBoxAdapter(
            child: _buildSectionWrapper(
              title: 'Reviews & Feedback',
              icon: Icons.forum_rounded,
              onEdit: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reviews cannot be edited.')));
              }, 
              child: StreamBuilder<QuerySnapshot>(
                stream: Provider.of<VendorProvider>(context, listen: false).streamVendorReviews(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reviewsList = snapshot.data?.docs ?? [];
                  if (reviewsList.isEmpty) {
                    return Text('No reviews yet.', style: GoogleFonts.poppins(color: Colors.grey));
                  }
                  return Column(
                    children: [
                      _buildReviewSummary(rating, reviewsList.length),
                      const SizedBox(height: 24),
                      ...reviewsList.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildTestimonialItem(
                          data['userName'] ?? 'Customer',
                          data['comment'] ?? '',
                          (data['rating'] ?? 5).toInt(),
                          data['userImage'],
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),

          // 7. BUSINESS INFO
          SliverToBoxAdapter(
            child: _buildSectionWrapper(
              title: 'Business Details',
              icon: Icons.business_rounded,
              onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreSetupScreen(initialTabIndex: 5))),
              child: Column(
                children: [
                   _buildBusinessRow(Icons.location_on_rounded, vendor['address'] ?? 'Set location'),
                   _buildBusinessRow(Icons.access_time_filled_rounded, vendor['workingHours'] ?? 'Set hours'),
                   _buildBusinessRow(Icons.phone_android_rounded, vendor['contact'] ?? 'Set contact'),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(String name, String? logo, double rating, int reviews) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
              image: logo != null ? DecorationImage(image: NetworkImage(logo), fit: BoxFit.cover) : null,
            ),
            child: logo == null ? const Icon(Icons.store_rounded, color: Colors.indigo, size: 40) : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('$reviews Reviews', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWrapper({required String title, required IconData icon, required VoidCallback onEdit, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF4338CA)),
                  const SizedBox(width: 10),
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                ],
              ),
              IconButton(onPressed: onEdit, icon: Icon(Icons.mode_edit_outline_rounded, size: 16, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 16),
          child,
          const Divider(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.indigo),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange[400]!, Colors.orange[600]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(offer['title'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${offer['discount']} OFF', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, Map<String, dynamic> vendor) {
    // In a real app, you'd filter the main services collection by the IDs in vendor['enabledServices']
    // For this preview, we can show a placeholder message or use a query.
    return Column(
      children: [
         _buildServiceItem('General Consultation', 'Standard diagnostic and advice', '₹499'),
         _buildServiceItem('Premium Support', 'Priority response and deep fix', '₹1,299'),
      ],
    );
  }

  Widget _buildServiceItem(String name, String desc, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(price, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF4A55ED))),
        ],
      ),
    );
  }

  Widget _buildGallery(List gallery) {
    if (gallery.isEmpty) return const Text('No photos yet.');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: gallery.length > 6 ? 6 : gallery.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(gallery[index], fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildReviewSummary(double rating, int count) {
    return Row(
      children: [
        Column(
          children: [
            Text(rating.toString(), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold)),
            Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 14, color: i < rating.floor() ? Colors.amber : Colors.grey[300]))),
            Text('$count reviews', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            children: [
               _buildRatingBar(5, 0.8),
               _buildRatingBar(4, 0.15),
               _buildRatingBar(3, 0.05),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTestimonialItem(String name, String text, int rating, String? imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.indigo[50],
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null ? Text(name[0], style: const TextStyle(fontSize: 12)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        Icons.star_rounded, 
                        size: 12, 
                        color: i < rating ? Colors.amber : Colors.grey[300],
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double factor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(value: factor, backgroundColor: Colors.grey[100], color: Colors.amber, minHeight: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(icon, size: 16, color: Colors.grey[600])),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800]))),
        ],
      ),
    );
  }
}
