import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/admin_provider.dart';
import '../services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String? _selectedCategoryId;

  // Pre-defined colors for UI
  static const _categoryColors = [
    Color(0xFF4C1D95), // Deep Purple
    Color(0xFF0D9488), // Teal
    Color(0xFF2563EB), // Blue
    Color(0xFFDB2777), // Pink
    Color(0xFFDC2626), // Red
    Color(0xFFF59E0B), // Amber
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildRequestsSection(),
        const SizedBox(height: 32),
        StreamBuilder<QuerySnapshot>(
          stream: Provider.of<AdminProvider>(context).servicesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Text(
                    'No categories found. Click "Add New Category" to start.',
                    style: GoogleFonts.poppins(color: Colors.blueGrey[400]),
                  ),
                ),
              );
            }

            final categories = snapshot.data!.docs.toList();
            
            // Auto-select first category if none selected or if selected doesn't exist anymore
            if (_selectedCategoryId == null || !categories.any((c) => c.id == _selectedCategoryId)) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted && categories.isNotEmpty) {
                    setState(() => _selectedCategoryId = categories.first.id);
                 }
               });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      try {
                        if (index >= categories.length) return const SizedBox.shrink();
                        final doc = categories[index];
                        final cat = doc.data() as Map<String, dynamic>;
                        final isActive = _selectedCategoryId == doc.id;
                        final List subServices = (cat['subServices'] is List) ? List.from(cat['subServices']) : [];

                        return Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCategoryId = doc.id),
                            child: SizedBox(
                              width: 320,
                              child: _buildCategoryCard(
                                doc.id,
                                cat['categoryName'] ?? cat['title'] ?? 'Unknown',
                                cat['description'] ?? cat['desc'] ?? '',
                                Color(cat['color'] ?? 0xFF4C1D95),
                                cat['status'] ?? 'ACTIVE',
                                subServices.length,
                                isActive,
                                cat['categoryImageUrl'] ?? cat['imageUrl'],
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                         return Container(
                           width: 320,
                           height: 220,
                           margin: const EdgeInsets.only(right: 24),
                           decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16)),
                           child: Center(child: Text('Card Error: $e', style: const TextStyle(color: Colors.red, fontSize: 10))),
                         );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),
                if (_selectedCategoryId != null && categories.isNotEmpty)
                  _buildSubServicesArea(
                    categories.any((c) => c.id == _selectedCategoryId)
                        ? categories.firstWhere((c) => c.id == _selectedCategoryId)
                        : categories.first,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Portfolio',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage the ecosystem of services and their high-level\nclassifications for the partner network.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.blueGrey[400],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showCategoryDialog(context),
          icon: const Icon(LucideIcons.plusCircle, size: 18),
          label: Text(
            'Add New Category',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4C1D95),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String docId, String title, String desc, Color color, String status, int servicesCount, bool isActiveCategory, String? imageUrl) {
    Color statusBg = status == 'ACTIVE' ? const Color(0xFF5EEAD4) : const Color(0xFFFECACA);
    Color statusText = status == 'ACTIVE' ? const Color(0xFF134E4A) : const Color(0xFF7F1D1D);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActiveCategory ? Border.all(color: color, width: 2) : Border.all(color: Colors.transparent, width: 2),
        boxShadow: isActiveCategory
            ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 6, height: double.infinity, color: color),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: 0,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Icon(
                      LucideIcons.package2,
                      size: 120,
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: (imageUrl != null && imageUrl.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      CloudinaryService.getOptimizedUrl(imageUrl, width: 100, height: 100, crop: 'fill'),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Image.network(
                                        CloudinaryService.getAutoIconUrl(title),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.network(
                                      CloudinaryService.getAutoIconUrl(title),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                          ),
                          Row(
                            children: [
                               Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.poppins(
                                    color: statusText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showCategoryDialog(context, docId: docId, existingData: {
                                  'categoryName': title, 'description': desc, 'status': status, 'color': color.toARGB32(), 'categoryImageUrl': imageUrl
                                }),
                                child: Icon(LucideIcons.edit3, size: 16, color: Colors.blueGrey[300]),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: GoogleFonts.poppins(
                          color: Colors.blueGrey[400],
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '$servicesCount Sub-Services',
                        style: GoogleFonts.poppins(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubServicesArea(DocumentSnapshot categoryDoc) {
    final catData = categoryDoc.data() as Map<String, dynamic>;
    final List subServices = (catData['subServices'] is List) ? List.from(catData['subServices']) : [];
    final color = Color(catData['color'] ?? 0xFF4C1D95);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(LucideIcons.listTree, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${catData['categoryName'] ?? catData['title'] ?? 'Category'} Services',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Currently viewing ${subServices.length} sub-services',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.blueGrey[400],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showSubServiceDialog(context, categoryDoc.id, subServices),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: Text('Add Sub-Service', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('SERVICE NAME', style: _headerStyle())),
                Expanded(flex: 1, child: Text('AVG. PRICE', style: _headerStyle())),
                Expanded(flex: 1, child: Text('DURATION', style: _headerStyle())),
                Expanded(flex: 1, child: Text('STATUS', style: _headerStyle())),
                const SizedBox(width: 32), 
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (subServices.isEmpty)
             Padding(
               padding: const EdgeInsets.all(32.0),
               child: Text('No sub-services added yet.', style: GoogleFonts.poppins(color: Colors.grey)),
             )
          else
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: subServices.length,
                itemBuilder: (context, index) {
                  final srv = (subServices[index] is Map) ? subServices[index] as Map<String, dynamic> : <String, dynamic>{};
                  return _buildServiceRow(
                    categoryDoc.id,
                    subServices,
                    srv['id'] ?? 'unknown',
                    srv['title'] ?? srv['categoryName'] ?? 'Unnamed Service',
                    srv['desc'] ?? srv['description'] ?? '',
                    srv['price'] ?? '₹0',
                    srv['duration'] ?? 'N/A',
                    srv['status'] ?? 'Enabled',
                    color,
                    srv['imageUrl'] ?? srv['categoryImageUrl'],
                  );
                },
             ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.blueGrey[300],
    letterSpacing: 1.0,
  );

  Widget _buildServiceRow(String categoryId, List subServices, String subId, String title, String desc, String price, String duration, String status, Color themeColor, String? imageUrl) {
    Color statusBg = status == 'Enabled' ? const Color(0xFFCCFBF1) : const Color(0xFFE2E8F0);
    Color statusText = status == 'Enabled' ? const Color(0xFF0F766E) : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(CloudinaryService.getOptimizedUrl(imageUrl, width: 80, height: 80, crop: 'fill'), fit: BoxFit.cover),
                      )
                    : const Icon(LucideIcons.package, color: Colors.white54, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blueGrey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              price,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              duration,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusText)),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, color: Colors.blueGrey),
            onSelected: (val) {
              if (val == 'edit') {
                 _showSubServiceDialog(context, categoryId, subServices, existingSubService: {'id': subId, 'title': title, 'desc': desc, 'price': price, 'duration': duration, 'status': status, 'imageUrl': imageUrl});
              } else if (val == 'delete') {
                 _deleteSubService(categoryId, subServices, subId);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  // --- DIALOGS & ACTIONS ---

  void _showCategoryDialog(BuildContext context, {String? docId, Map<String, dynamic>? existingData}) {
    final titleController = TextEditingController(text: existingData?['categoryName'] ?? existingData?['title']);
    final descController = TextEditingController(text: existingData?['description'] ?? existingData?['desc']);
    String status = existingData?['status'] ?? 'ACTIVE';
    int selectedColor = existingData?['color'] ?? _categoryColors[0].toARGB32();
    String? imageUrl = existingData?['categoryImageUrl'] ?? existingData?['imageUrl'];
    XFile? pickedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => StatefulBuilder(
        builder: (sbContext, setStateSB) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(docId == null ? 'New Category' : 'Edit Category', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SizedBox(
               width: 400,
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    TextField(
                      controller: titleController,
                      enabled: !isSaving,
                      decoration: InputDecoration(labelText: 'Category Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      enabled: !isSaving,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: 'Full Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: status == 'ACTIVE' ? 'Enabled' : (status == 'Enabled' ? 'Enabled' : 'Disabled'),
                      decoration: InputDecoration(labelText: 'Listing Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: const [
                        DropdownMenuItem(value: 'Enabled', child: Text('Enabled & Visible')),
                        DropdownMenuItem(value: 'Disabled', child: Text('Disabled / Maintenance')),
                      ],
                      onChanged: isSaving ? null : (v) => setStateSB(() => status = v!),
                    ),
                    const SizedBox(height: 16),
                    Text('Category Icon / Image', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: isSaving ? null : () async {
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        ),
                        child: pickedImage != null
                          ? kIsWeb 
                             ? Image.network(pickedImage!.path, fit: BoxFit.contain)
                             : Image.file(File(pickedImage!.path), fit: BoxFit.contain)
                          : imageUrl != null
                            ? Image.network(imageUrl, fit: BoxFit.contain)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.imagePlus, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('Tap to pick image', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Theme Color', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    AbsorbPointer(
                      absorbing: isSaving,
                      child: Wrap(
                        spacing: 8,
                        children: _categoryColors.map((c) => GestureDetector(
                          onTap: () => setStateSB(() => selectedColor = c.toARGB32()),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: c,
                            child: selectedColor == c.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        )).toList(),
                      ),
                    )
                 ],
               ),
            ),
            actions: [
               if (docId != null)
                  TextButton(
                    onPressed: isSaving ? null : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      try {
                        setStateSB(() => isSaving = true);
                        await Provider.of<AdminProvider>(context, listen: false).deleteService(docId);
                        if (!mounted) return;
                        if (_selectedCategoryId == docId) {
                           setState(() => _selectedCategoryId = null);
                        }
                        navigator.pop();
                        messenger.showSnackBar(const SnackBar(content: Text('Category deleted successfully')));
                      } catch (e) {
                         setStateSB(() => isSaving = false);
                         if (mounted) {
                           messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                         }
                      }
                    },
                    child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
               TextButton(
                 onPressed: isSaving ? null : () => Navigator.pop(sbContext),
                 child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
               ),
               ElevatedButton(
                 onPressed: isSaving ? null : () async {
                   final messenger = ScaffoldMessenger.of(context);
                   final navigator = Navigator.of(context);
                   final admin = Provider.of<AdminProvider>(context, listen: false);
                   if (titleController.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter a title')));
                      return;
                   }
                   
                   try {
                     setStateSB(() => isSaving = true);
                     final data = {
                       'categoryName': titleController.text.trim(),
                       'description': descController.text.trim(),
                       'status': status == 'Enabled' ? 'ACTIVE' : 'DISABLED',
                       'color': selectedColor,
                       'categoryImageUrl': imageUrl,
                     };
                     
                      if (pickedImage != null) {
                        String? uploadedUrl;
                        if (kIsWeb) {
                          uploadedUrl = await CloudinaryService.uploadImageBytes(
                            bytes: await pickedImage!.readAsBytes(),
                            fileName: pickedImage!.name,
                            folder: 'categories',
                          );
                        } else {
                          uploadedUrl = await CloudinaryService.uploadImage(
                            filePath: pickedImage!.path,
                            folder: 'categories',
                          );
                        }
                        if (uploadedUrl != null) {
                          data['categoryImageUrl'] = uploadedUrl;
                        }
                      } else if (imageUrl == null) {
                        data['categoryImageUrl'] = CloudinaryService.getAutoIconUrl(titleController.text.trim());
                      }
                     
                      if (!mounted) return;
                      if (docId == null) {
                        data['subServices'] = [];
                        await admin.addService(data);
                      } else {
                        await admin.updateService(docId, data);
                      }
                     
                     if (!mounted) return;
                     navigator.pop();
                     messenger.showSnackBar(const SnackBar(content: Text('Saved successfully')));
                   } catch (e) {
                     setStateSB(() => isSaving = false);
                   }
                 },
                 style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C1D95),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                 ),
                 child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
               )
            ],
          );
        }
      )
    );
  }

  void _showSubServiceDialog(BuildContext context, String categoryId, List currentSubServices, {Map<String, dynamic>? existingSubService}) {
    final titleC = TextEditingController(text: existingSubService?['title']);
    final descC = TextEditingController(text: existingSubService?['desc']);
    final priceC = TextEditingController(text: existingSubService?['price'] ?? '\$');
    final durationC = TextEditingController(text: existingSubService?['duration'] ?? '45 Mins');
    String status = existingSubService?['status'] ?? 'Enabled';
    String? imageUrl = existingSubService?['imageUrl'];
    XFile? pickedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) => StatefulBuilder(
        builder: (sbContext, setStateSB) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(existingSubService == null ? 'New Sub-Service' : 'Edit Sub-Service', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SizedBox(
               width: 400,
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    TextField(
                      controller: titleC,
                      enabled: !isSaving,
                      decoration: InputDecoration(labelText: 'Service Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descC,
                      enabled: !isSaving,
                      decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: priceC, enabled: !isSaving, decoration: InputDecoration(labelText: 'Price', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: durationC, enabled: !isSaving, decoration: InputDecoration(labelText: 'Duration', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: const [
                        DropdownMenuItem(value: 'Enabled', child: Text('Enabled')),
                        DropdownMenuItem(value: 'Paused', child: Text('Paused')),
                      ],
                      onChanged: isSaving ? null : (v) => setStateSB(() => status = v!),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: isSaving ? null : () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setStateSB(() => pickedImage = image);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: pickedImage != null
                          ? kIsWeb 
                             ? Image.network(pickedImage!.path, fit: BoxFit.cover)
                             : Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                          : imageUrl != null
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : const Center(child: Text('Pick Image')),
                      ),
                    ),
                 ],
               ),
            ),
            actions: [
               TextButton(
                 onPressed: isSaving ? null : () => Navigator.pop(context),
                 child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
               ),                ElevatedButton(
                 onPressed: isSaving ? null : () async {
                   final messenger = ScaffoldMessenger.of(context);
                   final navigator = Navigator.of(context);
                   final admin = Provider.of<AdminProvider>(context, listen: false);
                   if (titleC.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter a name')));
                      return;
                   }

                   try {
                     setStateSB(() => isSaving = true);
                     final newSvc = {
                       'id': existingSubService?['id'] ?? const Uuid().v4(),
                       'title': titleC.text.trim(),
                       'desc': descC.text.trim(),
                       'price': priceC.text.trim(),
                       'duration': durationC.text.trim(),
                       'status': status,
                       'imageUrl': imageUrl,
                     };

                     if (pickedImage != null) {
                        String? uploadedUrl;
                        if (kIsWeb) {
                          uploadedUrl = await CloudinaryService.uploadImageBytes(
                            bytes: await pickedImage!.readAsBytes(),
                            fileName: pickedImage!.name,
                            folder: 'sub_services',
                          );
                        } else {
                          uploadedUrl = await CloudinaryService.uploadImage(
                            filePath: pickedImage!.path,
                            folder: 'sub_services',
                          );
                        }
                        if (uploadedUrl != null) {
                          newSvc['imageUrl'] = uploadedUrl;
                        }
                      } else if (imageUrl == null) {
                        // AUTOMATIC: Suggest an icon based on title if no image exists or was picked
                        newSvc['imageUrl'] = CloudinaryService.getAutoIconUrl(titleC.text.trim());
                      }

                     List updatedList = List.from(currentSubServices);
                     if (existingSubService != null) {
                        final idx = updatedList.indexWhere((s) => s['id'] == existingSubService['id']);
                        if (idx != -1) updatedList[idx] = newSvc;
                     } else {
                        updatedList.add(newSvc);
                     }

                      if (!mounted) return;
                      await admin.updateService(categoryId, {'subServices': updatedList});
                     if (!mounted) return;
                     navigator.pop();
                     messenger.showSnackBar(const SnackBar(content: Text('Sub-service saved')));
                   } catch (e) {
                     setStateSB(() => isSaving = false);
                   }
                 },
                 style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C1D95),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                 ),
                 child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
               )
            ],
          );
        }
      )
    );
  }

  void _deleteSubService(String categoryId, List currentSubServices, String subIdToDelete) async {
    try {
      List updatedList = List.from(currentSubServices);
      updatedList.removeWhere((s) => s['id'] == subIdToDelete);
      await Provider.of<AdminProvider>(context, listen: false).updateService(categoryId, {'subServices': updatedList});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sub-service deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  Widget _buildRequestsSection() {
    final adminProvider = Provider.of<AdminProvider>(context);
    return StreamBuilder<QuerySnapshot>(
      stream: adminProvider.categoryRequestsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final pending = snapshot.data!.docs.where((d) => d['status'] == 'PENDING').toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bellRing, color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 12),
                Text(
                  'Pending Category Requests (${pending.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pending.length,
                itemBuilder: (context, index) {
                  try {
                    if (index >= pending.length) return const SizedBox.shrink();
                    final req = pending[index];
                    final data = req.data() as Map<String, dynamic>;
                    return Container(
                      width: 350,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFED7D7)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: (data['categoryImageUrl'] ?? data['imageUrl']) != null 
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    CloudinaryService.getOptimizedUrl(data['categoryImageUrl'] ?? data['imageUrl'], width: 80, height: 80, crop: 'fill'),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(LucideIcons.helpCircle, color: Color(0xFFDC2626), size: 20),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['categoryName'] ?? data['title'] ?? 'Untitled',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By: ${data['vendorName'] ?? 'Vendor'} (${data['businessName'] ?? 'Business'})',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    data['description'] ?? data['desc'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 22),
                                onPressed: () {
                                  _showCategoryDialog(context, existingData: {
                                    'categoryName': data['categoryName'] ?? data['title'],
                                    'description': data['description'] ?? data['desc'],
                                    'categoryImageUrl': data['categoryImageUrl'] ?? data['imageUrl'],
                                  });
                                  adminProvider.updateCategoryRequestStatus(req.id, 'APPROVED');
                                },
                                tooltip: 'Approve & Create',
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 22),
                                onPressed: () => adminProvider.updateCategoryRequestStatus(req.id, 'REJECTED'),
                                tooltip: 'Reject',
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  } catch (e) {
                     return Center(child: Text('Request Error: $e', style: const TextStyle(color: Colors.red, fontSize: 10)));
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

