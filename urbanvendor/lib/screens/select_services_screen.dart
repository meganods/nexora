import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/registration_provider.dart';
import '../services/cloudinary_service.dart';

class SelectServicesScreen extends StatefulWidget {
  const SelectServicesScreen({super.key});

  @override
  State<SelectServicesScreen> createState() => _SelectServicesScreenState();
}

class _SelectServicesScreenState extends State<SelectServicesScreen> {
  // Dynamic services will be fetched from selected categories
  final Set<String> _selectedIds = {}; 
  final Set<String> _selectedTitles = {}; 

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RegistrationProvider>(context, listen: false);
    _selectedIds.addAll(provider.enabledServices);
    _selectedTitles.addAll(provider.enabledServiceNames);
  }
  
  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Partner Registration',
          style: GoogleFonts.poppins(
            color: primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                'Step 5 of 8',
                style: GoogleFonts.poppins(
                  color: Colors.blueGrey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<RegistrationProvider>(context, listen: false);
              
              provider.enabledServices = _selectedIds.toList();
              provider.enabledServiceNames = _selectedTitles.toList();
              provider.currentStep = '/upload_documents';

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('vendors').doc(user.uid).update({
                  'enabledServices': provider.enabledServices,
                  'enabledServiceNames': provider.enabledServiceNames,
                  'currentStep': provider.currentStep,
                });
              }

              if (context.mounted) Navigator.pushNamed(context, '/upload_documents');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9DDD4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PROFESSIONAL CATALOG',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFF9E4024),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Services You\nOffer',
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Curate your service menu. Choose from our standard options or add your signature professional touch.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.blueGrey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            
            // Vertical List of Services
            Consumer<RegistrationProvider>(
              builder: (context, registration, child) {
                if (registration.selectedCategoryIds.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.design_services_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No categories selected. Go back to select categories.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('services')
                    .where(FieldPath.documentId, whereIn: registration.selectedCategoryIds)
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Collect all sub-services from all selected categories
                    List<Map<String, dynamic>> allSubServices = [];
                    for (var doc in snapshot.data!.docs) {
                       final data = doc.data() as Map<String, dynamic>;
                       final colorValue = data['color'] as int?;
                       final subSvcs = data['subServices'] as List? ?? [];
                       for (var s in subSvcs) {
                          final sMap = s as Map<String, dynamic>;
                          allSubServices.add({
                            ...sMap,
                            'themeColor': colorValue != null ? Color(colorValue) : primaryBlue,
                          });
                       }
                    }

                    if (allSubServices.isEmpty) {
                       return Center(
                         child: Padding(
                           padding: const EdgeInsets.symmetric(vertical: 40),
                           child: Column(
                             children: [
                               Icon(Icons.design_services_outlined, size: 64, color: Colors.grey[300]),
                               const SizedBox(height: 16),
                               Text(
                                 'No specific services available for these categories.',
                                 textAlign: TextAlign.center,
                                 style: GoogleFonts.poppins(color: Colors.grey[500]),
                               ),
                             ],
                           ),
                         ),
                       );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allSubServices.length,
                      itemBuilder: (context, index) {
                        final service = allSubServices[index];
                        final isSelected = _selectedIds.contains(service['id']);
                        final String? imageUrl = service['imageUrl'] ?? service['categoryImageUrl'];
                        final Color themeColor = service['themeColor'] as Color;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(service['id']);
                                _selectedTitles.remove(service['title'] ?? service['categoryName']);
                              } else {
                                _selectedIds.add(service['id'] ?? '');
                                _selectedTitles.add(service['title'] ?? service['categoryName'] ?? '');
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected ? themeColor.withValues(alpha: 0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: themeColor, width: 1.5) : null,
                              boxShadow: isSelected 
                                ? null 
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Builder(
                                        builder: (context) {
                                          final titleStr = service['title'] ?? service['categoryName'] ?? '';
                                          if (imageUrl == null || imageUrl.isEmpty) {
                                            return Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Image.network(
                                                CloudinaryService.getAutoIconUrl(titleStr),
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => Icon(Icons.cleaning_services, color: themeColor, size: 24),
                                              ),
                                            );
                                          }
                                          if (imageUrl.startsWith("assets")) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.asset(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Icon(Icons.cleaning_services, color: themeColor, size: 24),
                                              ),
                                            );
                                          }
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              CloudinaryService.getOptimizedUrl(imageUrl, width: 100, height: 100, crop: 'fill'),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Image.network(
                                                CloudinaryService.getAutoIconUrl(titleStr),
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) => Icon(Icons.cleaning_services, color: themeColor, size: 24),
                                              ),
                                            ),
                                          );
                                        }
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: themeColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  service['title'] ?? service['categoryName'] ?? 'N/A',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service['desc'] ?? service['description'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (service['price'] != null) ...[
                                  const SizedBox(height: 12),
                                  Builder(
                                    builder: (context) {
                                      final String rawPrice = service['price']?.toString() ?? '';
                                      final String formattedPrice = rawPrice.startsWith('₹') ? rawPrice : '₹$rawPrice';
                                      return Text(
                                        'Base Price: $formattedPrice',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: themeColor,
                                        ),
                                      );
                                    }
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Request Service Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_fix_high_rounded, color: Colors.orange, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "Offer something else?",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Request a specific sub-service and we'll add it to your menu once approved.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showRequestServiceDialog(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Request New Service',
                        style: GoogleFonts.poppins(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showRequestServiceDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Request Specific Service',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Service Name',
                labelStyle: GoogleFonts.poppins(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Requirements/Details',
                labelStyle: GoogleFonts.poppins(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              await FirebaseFirestore.instance.collection('category_requests').add({
                'vendorId': user?.uid,
                'title': nameController.text,
                'desc': descController.text,
                'type': 'SUB_SERVICE',
                'status': 'PENDING',
                'createdAt': FieldValue.serverTimestamp(),
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service request submitted!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A55ED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
