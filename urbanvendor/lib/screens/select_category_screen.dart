import 'package:urbanvendor/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/registration_provider.dart';
import '../services/cloudinary_service.dart';

class SelectCategoryScreen extends StatefulWidget {
  const SelectCategoryScreen({super.key});

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen> {
  // Using dynamic data from Firestore via StreamBuilder in build.
  // We'll keep default styles for specific categories if they match by title, 
  // otherwise we use defaults from the DB.
  
  final Map<String, dynamic> _defaultStyling = {
    'salon': {'icon': Icons.spa, 'color': const Color(0xFFEBCBB9), 'iconColor': const Color(0xFF863B15)},
    'cleaning': {'icon': Icons.cleaning_services, 'color': const Color(0xFFC4EBF6), 'iconColor': const Color(0xFF0C6B8B)},
    'electrician': {'icon': Icons.electrical_services, 'color': const Color(0xFFD6DBF8), 'iconColor': const Color(0xFF33339F)},
    'plumbing': {'icon': Icons.plumbing, 'color': const Color(0xFFEDEEF0), 'iconColor': const Color(0xFF263238)},
    'appliance': {'icon': Icons.ac_unit, 'color': const Color(0xFFD3E0F4), 'iconColor': const Color(0xFF1E3A8A)},
    'carpenter': {'icon': Icons.handyman, 'color': const Color(0xFFFDE68A), 'iconColor': const Color(0xFF92400E)},
  };

  Map<String, dynamic> _getStyle(String title, int? colorValue) {
    String slug = title.toLowerCase();
    for (var key in _defaultStyling.keys) {
      if (slug.contains(key)) return _defaultStyling[key];
    }
    // Fallback based on DB color if available
    return {
      'icon': Icons.category_outlined,
      'color': colorValue != null ? Color(colorValue).withValues(alpha: 0.2) : Colors.grey[200],
      'iconColor': colorValue != null ? Color(colorValue) : Colors.black54,
    };
  }

  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RegistrationProvider>(context, listen: false);
    _selectedIds.addAll(provider.selectedCategoryIds);
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
          'Partner\nRegistration',
          style: GoogleFonts.poppins(
            color: primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PROGRESS 4 / 8',
                  style: GoogleFonts.poppins(
                    color: Colors.blueGrey[400],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: primaryBlue, // Completed
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(2)),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Remaining
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                      ),
                    ),
                  ],
                ),
              ],
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
              final registration = Provider.of<RegistrationProvider>(context, listen: false);
              registration.selectedCategoryIds = _selectedIds.toList();
              
              // if (registration.selectedCategoryIds.isEmpty) {
              //    AppSnackbar.show(context, 'Please select at least one category');
              //    return;
              // }

              registration.currentStep = '/select_services';
              
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('vendors').doc(user.uid).update({
                  'selectedCategoryIds': registration.selectedCategoryIds,
                  'currentStep': registration.currentStep,
                });
              }

              if (context.mounted) Navigator.pushNamed(context, '/select_services');
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
            Text(
              'SERVICE EXPERTISE',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B7B87),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select Your\nCategory',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose the core areas of your expertise.\nYou can select multiple categories if you\nprovide a diverse range of services.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.blueGrey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            
            // Grid of categories
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services')
                .snapshots(), // Showing all first to be safe, filtering in code if needed
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                   return Center(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 40),
                       child: Column(
                         children: [
                           Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
                           const SizedBox(height: 16),
                           Text('No categories available yet', style: GoogleFonts.poppins(color: Colors.grey[500])),
                         ],
                       ),
                     ),
                   );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final isSelected = _selectedIds.contains(docId);
                    final style = _getStyle(data['categoryName'] ?? data['title'] ?? '', data['color'] as int?);
                    final String? imageUrl = data['categoryImageUrl'] ?? data['imageUrl'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(docId);
                          } else {
                            _selectedIds.add(docId);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [primaryBlue, Color(0xFF00B4DB)],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: style['color'],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: imageUrl != null 
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            CloudinaryService.getOptimizedUrl(imageUrl, width: 100, height: 100, crop: 'fill'),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Image.network(
                                              CloudinaryService.getAutoIconUrl(data['categoryName'] ?? data['title'] ?? ''),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.network(
                                            CloudinaryService.getAutoIconUrl(data['categoryName'] ?? data['title'] ?? ''),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    data['categoryName'] ?? data['title'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    data['description'] ?? data['desc'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (isSelected)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Request Category Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryBlue.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_task_rounded, color: primaryBlue, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "Can't find your service?",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Request a new category from our admin team and we'll review it.",
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
                      onPressed: () => _showRequestCategoryDialog(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryBlue.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Request New Category',
                        style: GoogleFonts.poppins(
                          color: primaryBlue,
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

  void _showRequestCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    const primaryBlue = Color(0xFF4A55ED);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Request New Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: GoogleFonts.poppins(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
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
                'categoryName': nameController.text.trim(),
                'description': descController.text.trim(),
                'imageUrl': CloudinaryService.getAutoIconUrl(nameController.text.trim()),
                'status': 'PENDING',
                'createdAt': FieldValue.serverTimestamp(),
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                AppSnackbar.show(context, 'Request submitted successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
