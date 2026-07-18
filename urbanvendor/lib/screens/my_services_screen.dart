import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../providers/vendor_provider.dart';
import '../services/cloudinary_service.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorProvider>(context, listen: false).fetchVendorData();
    });
  }

  void _showAddServiceSheet(BuildContext context, VendorProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddServiceBottomSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final vendor = vendorProvider.vendorData;
    final enabledServiceIds = List<String>.from(vendor?['enabledServices'] ?? []);
    
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Services',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavIcon(Icons.dashboard_customize_outlined, 'Home', false, () {
              Navigator.pushReplacementNamed(context, '/expert_dashboard');
            }),
            _buildBottomNavIcon(Icons.layers, 'Services', true, () {}),
            _buildBottomNavIcon(Icons.calendar_month_outlined, 'Bookings', false, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookings coming soon')));
            }),
            _buildBottomNavIcon(Icons.person_outline, 'Account', false, () {
              Navigator.pushReplacementNamed(context, '/partner_profile');
            }),
          ],
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MANAGEMENT PORTAL',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Craft your service\ncatalog',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Present your expertise through clear,\nprofessional offerings. High-quality\ndescriptions help build trust with new\nclients.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blueGrey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Add New Service Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _showAddServiceSheet(context, vendorProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: primaryBlue, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text('Add New Service', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // DYNAMIC SERVICES LIST
            if (enabledServiceIds.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Colors.grey[300], size: 60),
                    const SizedBox(height: 16),
                    Text('No services active', 
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                    const SizedBox(height: 8),
                    Text('Add your first service to start getting bookings', 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('services').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  // Filter out only the subServices that are enabled in vendor document
                  List<Map<String, dynamic>> displayedServices = [];
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final subServices = List<Map<String, dynamic>>.from(data['subServices'] ?? []);
                    for (var ss in subServices) {
                      if (enabledServiceIds.contains(ss['id'])) {
                        displayedServices.add(ss);
                      }
                    }
                  }

                  return Column(
                    children: displayedServices.map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildServiceCard(
                          imageUrl: service['imageUrl'],
                          iconColor: primaryBlue,
                          iconBgColor: const Color(0xFFF1EFFF),
                          title: service['title'] ?? 'Generic Service',
                          description: service['description'] ?? 'No description available.',
                          rateLabel: 'BASE RATE',
                          price: () {
                            final rawPrice = service['price']?.toString() ?? '0';
                            return rawPrice.startsWith('₹') ? rawPrice : '₹$rawPrice';
                          }(),
                          priceSuffix: '',
                          priceColor: primaryBlue,
                          tagText: 'Active',
                          tagColor: const Color(0xFFC4F1F9),
                          tagTextColor: const Color(0xFF007A99),
                          onDelete: () => vendorProvider.removeService(service['id']),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 10),

            // Create Another Service (Dashed Box)
            GestureDetector(
              onTap: () => _showAddServiceSheet(context, vendorProvider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text('Add More Services', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('Choose from your categories', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
            // Request New Service Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Light Slate
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    "Can't find your service?",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Request a new service to be added to the platform.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey[600]),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _showRequestCategoryDialog(context, vendorProvider),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF4A55ED)),
                      ),
                    ),
                    child: Text(
                      'Request New Service',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF4A55ED)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Request Status Section
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('category_requests')
                  .where('vendorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Status',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ...snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'PENDING';
                      Color statusColor = Colors.orange;
                      if (status == 'APPROVED') statusColor = Colors.green;
                      if (status == 'REJECTED') statusColor = Colors.red;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(Icons.history_edu, color: statusColor, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['categoryName'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(status, style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Text(
                              (data['createdAt'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? '',
                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showRequestCategoryDialog(BuildContext context, VendorProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    XFile? pickedImage;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => StatefulBuilder(
        builder: (sbContext, setStateSB) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Request Service', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Service Name',
                        hintText: 'e.g. Pet Grooming, Yoga Instructor',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      enabled: !isSubmitting,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description/Requirement',
                        hintText: 'Tell us more about the services you want to offer...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: isSubmitting ? null : () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setStateSB(() => pickedImage = image);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb 
                                ? Image.network(pickedImage!.path, fit: BoxFit.cover)
                                : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.blueGrey, size: 28),
                                SizedBox(height: 8),
                                Text('Upload Service Image', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                              ],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dContext),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  if (nameController.text.trim().isEmpty) {
                    messenger.showSnackBar(const SnackBar(content: Text('Please enter a service name')));
                    return;
                  }

                  try {
                    setStateSB(() => isSubmitting = true);
                    String? uploadedUrl;
                    if (pickedImage != null) {
                      if (kIsWeb) {
                        uploadedUrl = await CloudinaryService.uploadImageBytes(
                          bytes: await pickedImage!.readAsBytes(),
                          fileName: pickedImage!.name,
                          folder: 'category_requests',
                        );
                      } else {
                        uploadedUrl = await CloudinaryService.uploadImage(
                          filePath: pickedImage!.path,
                          folder: 'category_requests',
                        );
                      }
                      if (uploadedUrl == null) {
                        throw Exception('Failed to upload category image to Cloudinary. Please try again.');
                      }
                    }

                    await provider.requestNewCategory(
                      nameController.text.trim(),
                      descController.text.trim(),
                      categoryImageUrl: uploadedUrl,
                    );

                    navigator.pop();
                    messenger.showSnackBar(const SnackBar(content: Text('Request submitted successfully!')));
                  } catch (e) {
                    setStateSB(() => isSubmitting = false);
                    messenger.showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B44D3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Request'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceCard({
    String? imageUrl,
    IconData? iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required String rateLabel,
    required String price,
    required String priceSuffix,
    required Color priceColor,
    required String tagText,
    required Color tagColor,
    required Color tagTextColor,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                child: imageUrl != null 
                   ? ClipRRect(
                       borderRadius: BorderRadius.circular(10),
                       child: Image.network(
                         CloudinaryService.getOptimizedUrl(imageUrl, width: 60, height: 60, crop: 'fill'),
                         width: 18, height: 18, fit: BoxFit.cover,
                       ),
                     )
                   : Icon(iconData ?? Icons.auto_awesome, color: iconColor, size: 18),
              ),
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 16),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.delete, color: Colors.red[300], size: 18),
                    onPressed: onDelete,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2)),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey[700], height: 1.5),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rateLabel, style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(color: Colors.black87),
                      children: [
                        TextSpan(text: price, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: priceColor)),
                        TextSpan(text: priceSuffix, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(20)),
                child: Text(tagText, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: tagTextColor)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, String label, bool isActive, VoidCallback onTap) {
    const primaryBlue = Color(0xFF4A55ED);
    
    return GestureDetector(
      onTap: onTap,
      child: isActive 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: primaryBlue, size: 20),
                const SizedBox(height: 2),
                Text(label, style: GoogleFonts.poppins(fontSize: 10, color: primaryBlue, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blueGrey[400], size: 22),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.blueGrey[400])),
            ],
          ),
    );
  }
}

class _AddServiceBottomSheet extends StatelessWidget {
  final VendorProvider provider;
  const _AddServiceBottomSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final vendor = provider.vendorData;
    final categoryIds = List<String>.from(vendor?['selectedCategoryIds'] ?? []);
    final enabledServiceIds = List<String>.from(vendor?['enabledServices'] ?? []);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Service', 
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Available services based on your categories', 
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: provider.streamAvailableServices(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    // Flatten subServices from relevant categories
                    List<Map<String, dynamic>> available = [];
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (categoryIds.contains(doc.id)) {
                        final subServices = List<Map<String, dynamic>>.from(data['subServices'] ?? []);
                        for (var ss in subServices) {
                          if (!enabledServiceIds.contains(ss['id'])) {
                            available.add(ss);
                          }
                        }
                      }
                    }

                    if (available.isEmpty) {
                      return Center(
                        child: Text('No more services available in your categories', 
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      controller: controller,
                      itemCount: available.length,
                      itemBuilder: (context, index) {
                        final ss = available[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: ss['imageUrl'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(ss['imageUrl'], fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.inventory_2, color: Colors.grey, size: 20),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ss['title'] ?? '', 
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    Builder(
                                      builder: (context) {
                                        final String rawPrice = ss['price']?.toString() ?? '0';
                                        final String formattedPrice = rawPrice.startsWith('₹') ? rawPrice : '₹$rawPrice';
                                        return Text(
                                          formattedPrice, 
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey),
                                        );
                                      }
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  provider.addService(ss['id'], ss);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A55ED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

