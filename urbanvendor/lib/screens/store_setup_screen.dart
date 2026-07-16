import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/vendor_provider.dart';
import '../services/cloudinary_service.dart';

class StoreSetupScreen extends StatefulWidget {
  final int initialTabIndex;
  const StoreSetupScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _brandNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _aboutController = TextEditingController();
  final _experienceController = TextEditingController();
  final _specializationController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _workingHoursController = TextEditingController();

  String? _logoUrl;
  List<String> _galleryUrls = [];
  List<Map<String, dynamic>> _offers = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendor = Provider.of<VendorProvider>(context, listen: false).vendorData;
      if (vendor != null) {
        setState(() {
          _brandNameController.text = vendor['brandName'] ?? vendor['businessName'] ?? '';
          _taglineController.text = vendor['tagline'] ?? '';
          _aboutController.text = vendor['about'] ?? '';
          _experienceController.text = vendor['experience'] ?? '';
          _specializationController.text = (vendor['specializations'] as List?)?.join(', ') ?? '';
          _addressController.text = vendor['address'] ?? '';
          _contactController.text = vendor['contact'] ?? '';
          _workingHoursController.text = vendor['workingHours'] ?? '';
          _logoUrl = vendor['brandLogo'];
          _galleryUrls = List<String>.from(vendor['gallery'] ?? []);
          _offers = List<Map<String, dynamic>>.from(vendor['offers'] ?? []);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _brandNameController.dispose();
    _taglineController.dispose();
    _aboutController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isSaving = true);
    final url = await CloudinaryService.uploadImage(filePath: image.path, folder: 'vendor_logos');
    setState(() {
      _logoUrl = url;
      _isSaving = false;
    });
  }

  Future<void> _pickAndUploadGalleryImage() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() => _isSaving = true);
    for (var image in images) {
      final url = await CloudinaryService.uploadImage(filePath: image.path, folder: 'vendor_gallery');
      if (url != null) {
        setState(() {
          _galleryUrls.add(url);
        });
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _saveStore() async {
    setState(() => _isSaving = true);
    final updates = {
      'brandName': _brandNameController.text.trim(),
      'tagline': _taglineController.text.trim(),
      'about': _aboutController.text.trim(),
      'experience': _experienceController.text.trim(),
      'specializations': _specializationController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'address': _addressController.text.trim(),
      'contact': _contactController.text.trim(),
      'workingHours': _workingHoursController.text.trim(),
      'brandLogo': _logoUrl,
      'gallery': _galleryUrls,
      'offers': _offers,
      'storeSetupComplete': true,
    };

    await Provider.of<VendorProvider>(context, listen: false).updateVendorProfile(updates);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store details updated successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Store Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: primaryBlue),
              onPressed: _saveStore,
            )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          tabs: const [
            Tab(text: 'Brand'),
            Tab(text: 'About'),
            Tab(text: 'Storefront'),
            Tab(text: 'Offers'),
            Tab(text: 'Feedback'),
            Tab(text: 'Business'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrandTab(),
          _buildAboutTab(),
          _buildStorefrontTab(),
          _buildOffersTab(),
          _buildFeedbackTab(),
          _buildBusinessTab(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveStore,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: _isSaving 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Save Store Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildBrandTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAndUploadLogo,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
                  image: _logoUrl != null ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover) : null,
                ),
                child: _logoUrl == null 
                  ? const Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey)
                  : null,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('Brand Name', _brandNameController, Icons.business_center_rounded, 'e.g., Rizwan Grooming Studio'),
          const SizedBox(height: 20),
          _buildTextField('Brand Tagline', _taglineController, Icons.auto_awesome_rounded, 'e.g., Professional salon at your home'),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextField('About Business', _aboutController, Icons.info_outline_rounded, 'Tell your story...', maxLines: 4),
          const SizedBox(height: 20),
          _buildTextField('Years of Experience', _experienceController, Icons.history_edu_rounded, 'e.g., 5 years'),
          const SizedBox(height: 20),
          _buildTextField('Specializations', _specializationController, Icons.star_outline_rounded, 'e.g., Hair, Skin, AC Repair (comma separated)'),
        ],
      ),
    );
  }

  Widget _buildStorefrontTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Brand Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(onPressed: _pickAndUploadGalleryImage, icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          _galleryUrls.isEmpty 
            ? Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                child: const Center(child: Icon(Icons.image_search_rounded, size: 40, color: Colors.grey)),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _galleryUrls.length,
                itemBuilder: (context, index) => Stack(
                  children: [
                     ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_galleryUrls[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _galleryUrls.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildOffersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Offers', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _offers.add({
                      'title': 'New Offer',
                      'discount': '10%',
                      'expiry': '2026-12-31',
                    });
                  });
                },
                icon: const Icon(Icons.add_card_rounded, size: 14),
                label: const Text('Add Offer'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A55ED).withValues(alpha: 0.1), foregroundColor: const Color(0xFF4A55ED), elevation: 0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _offers.isEmpty 
            ? Container(
                padding: const EdgeInsets.all(40),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                child: Column(
                  children: [
                    const Icon(Icons.confirmation_num_rounded, size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('No active offers. Add one to attract customers!', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _offers.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.indigo.withValues(alpha: 0.1))),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, color: Colors.indigo),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_offers[index]['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            Text('Discount: ${_offers[index]['discount']} | Expiry: ${_offers[index]['expiry']}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => setState(() => _offers.removeAt(index)), icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab() {
    final vendor = Provider.of<VendorProvider>(context).vendorData;
    final rating = vendor?['rating'] ?? 0.0;
    final reviews = vendor?['reviewsCount'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
            ),
            child: Column(
              children: [
                Text(rating.toString(), style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(Icons.star_rounded, color: i < rating.floor() ? Colors.amber : Colors.grey[300])),
                ),
                const SizedBox(height: 8),
                Text('Based on $reviews reviews', style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Testimonials', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          // Placeholder for testimonials - would typically fetch from a subcollection
          const SizedBox(height: 16),
          _buildTestimonialItem('Sarah J.', 'Amazing service, very professional!', 5),
          _buildTestimonialItem('Mike Wilson', 'Quick and efficient. Highly recommended.', 4),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextField('Service Area / Address', _addressController, Icons.location_on_rounded, 'e.g., Downtown, Manhattan'),
          const SizedBox(height: 20),
          _buildTextField('Contact info', _contactController, Icons.phone_android_rounded, 'e.g., +1 234 567 890'),
          const SizedBox(height: 20),
          _buildTextField('Working Hours', _workingHoursController, Icons.access_time_filled_rounded, 'e.g., 9:00 AM - 6:00 PM'),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.blueGrey[800])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialItem(String name, String text, int rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, backgroundColor: Colors.blue[50], child: Text(name[0])),
              const SizedBox(width: 8),
              Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < rating ? Colors.amber : Colors.grey[300]))),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
