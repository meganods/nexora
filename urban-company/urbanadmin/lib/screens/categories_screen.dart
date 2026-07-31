import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:urbanadmin/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'package:http/http.dart' as http;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _currentView = 'dashboard'; // 'dashboard', 'list'
  
  // Controllers for Add/Edit Category
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  final _iconUrlController = TextEditingController();
  bool _isActive = true;
  bool _isFeatured = false;
  String? _editingDocId;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _orderController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _descController.clear();
    _orderController.text = '0';
    _iconUrlController.clear();
    _isActive = true;
    _isFeatured = false;
    _editingDocId = null;
  }

  // Download and upload external image URL to Cloudinary
  Future<String?> _uploadExternalUrlToCloudinary(String url) async {
    if (url.trim().isEmpty) return null;
    if (url.contains('cloudinary.com')) return url;
    
    // Convert Google Drive urls to direct image links
    final convertedUrl = _convertDriveUrl(url);
    if (!convertedUrl.startsWith('http://') && !convertedUrl.startsWith('https://')) return url;

    try {
      final cloudinaryUrl = await CloudinaryService.uploadImageUrl(
        imageUrl: convertedUrl,
      );
      return cloudinaryUrl;
    } catch (e) {
      debugPrint('Failed to upload external URL image: $e');
    }
    return url;
  }

  // Convert Google Drive viewing URLs into raw direct download URLs
  String _convertDriveUrl(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      final parts = url.split('/file/d/');
      if (parts.length > 1) {
        final id = parts[1].split('/')[0].split('?')[0];
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    } else if (url.contains('drive.google.com/open?id=')) {
      final parts = url.split('id=');
      if (parts.length > 1) {
        final id = parts[1].split('&')[0];
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildCurrentView(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            if (_currentView == 'list') ...[
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 28),
                onPressed: () => setState(() => _currentView = 'dashboard'),
                tooltip: 'Back to Dashboard',
              ),
              const SizedBox(width: 12),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Management',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and structure the global service catalogs across Nexora apps.',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentView = 'dashboard'),
              icon: const Icon(Icons.dashboard_rounded, size: 18),
              label: const Text('Dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _currentView == 'dashboard' ? const Color(0xFF2563EB) : const Color(0xFF475569),
                side: BorderSide(color: _currentView == 'dashboard' ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentView = 'list'),
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text('All Categories'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _currentView == 'list' ? const Color(0xFF2563EB) : const Color(0xFF475569),
                side: BorderSide(color: _currentView == 'list' ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _openCategoryDialog(),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    if (_currentView == 'list') {
      return _buildCategoryTableSection();
    }
    return _buildDashboardView();
  }

  // ==================== DASHBOARD VIEW ====================
  Widget _buildDashboardView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, catSnap) {
        if (catSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final catDocs = catSnap.data?.docs ?? [];
        
        // Sort in Dart code safely
        catDocs.sort((a, b) {
          final orderA = (a.data() as Map<String, dynamic>)['displayOrder'] as num? ?? 0;
          final orderB = (b.data() as Map<String, dynamic>)['displayOrder'] as num? ?? 0;
          return orderA.compareTo(orderB);
        });

        int totalCat = catDocs.length;
        int activeCat = catDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'ACTIVE').length;
        int inactiveCat = totalCat - activeCat;
        int featuredCat = catDocs.where((d) => ((d.data() as Map<String, dynamic>)['featured'] ?? false) == true).length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, srvSnap) {
            final totalServices = srvSnap.data?.docs.length ?? 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('sub_services').snapshots(),
              builder: (context, subSnap) {
                final totalSubServices = subSnap.data?.docs.length ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards Grid (Compact & Gradient styling)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 900;
                        return GridView.count(
                          crossAxisCount: isDesktop ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          childAspectRatio: isDesktop ? 3.2 : 2.5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildKpiCard('Total Categories', totalCat.toString(), Icons.folder_copy_rounded, const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                            _buildKpiCard('Active Listings', activeCat.toString(), Icons.check_circle_outline_rounded, const [Color(0xFF10B981), Color(0xFF059669)]),
                            _buildKpiCard('Inactive/Hidden', inactiveCat.toString(), Icons.cancel_outlined, const [Color(0xFFF43F5E), Color(0xFFE11D48)]),
                            _buildKpiCard('Featured Items', featuredCat.toString(), Icons.star_rounded, const [Color(0xFFF59E0B), Color(0xFFD97706)]),
                            _buildKpiCard('Associated Services', totalServices.toString(), Icons.design_services_rounded, const [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                            _buildKpiCard('Sub-Services Count', totalSubServices.toString(), Icons.list_alt_rounded, const [Color(0xFFEC4899), Color(0xFFDB2777)]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Distribution Breakdown & Real-Time List
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Stats Table
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Category Distribution Breakdown', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
                                const SizedBox(height: 16),
                                if (catDocs.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    alignment: Alignment.center,
                                    child: Text('No categories available yet. Click "+ Add Category" to create one!', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: catDocs.length,
                                    separatorBuilder: (_, __) => const Divider(height: 20, color: Color(0xFFF1F5F9)),
                                    itemBuilder: (context, index) {
                                      final doc = catDocs[index];
                                      final data = doc.data() as Map<String, dynamic>;
                                      final String docId = doc.id;
                                      final String name = data['categoryName'] ?? 'Unnamed';
                                      final String status = data['status'] ?? 'ACTIVE';
                                      final bool isActive = status == 'ACTIVE';

                                      return Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(0xFFEFF6FF),
                                            child: Text('${index + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                                                const SizedBox(height: 2),
                                                Text(data['description'] ?? 'No description', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                                            onPressed: () => _openCategoryDialog(docId: docId, existingData: data),
                                            tooltip: 'Edit Category',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                            onPressed: () => _confirmDeleteCategory(docId, name),
                                            tooltip: 'Delete Category',
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Quick Actions
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
                                const SizedBox(height: 16),
                                _quickActionButton('Create New Category', Icons.add_circle_outline_rounded, () => _openCategoryDialog()),
                                const SizedBox(height: 12),
                                _quickActionButton('Manage All Categories', Icons.format_list_bulleted_rounded, () => setState(() => _currentView = 'list')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ==================== KPI CARD COMPONENT ====================
  Widget _buildKpiCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 20),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B))),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ==================== CATEGORY TABLE VIEW ====================
  Widget _buildCategoryTableSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];

        docs.sort((a, b) {
          final orderA = (a.data() as Map<String, dynamic>)['displayOrder'] as num? ?? 0;
          final orderB = (b.data() as Map<String, dynamic>)['displayOrder'] as num? ?? 0;
          return orderA.compareTo(orderB);
        });

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Global Categories (${docs.length})', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                  ElevatedButton.icon(
                    onPressed: () => _openCategoryDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (docs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No categories created yet.')))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Category Name')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Display Order')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Featured')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String docId = doc.id;
                      final String name = data['categoryName'] ?? 'Unnamed';
                      final String desc = data['description'] ?? '-';
                      final int order = (data['displayOrder'] ?? 0).toInt();
                      final String status = data['status'] ?? 'ACTIVE';
                      final bool featured = data['featured'] ?? false;

                      return DataRow(
                        cells: [
                          DataCell(Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                          DataCell(Text(desc, style: GoogleFonts.inter(fontSize: 12))),
                          DataCell(Text('#$order')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'ACTIVE' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'ACTIVE' ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ),
                          DataCell(Icon(featured ? Icons.star_rounded : Icons.star_border, color: featured ? Colors.amber : Colors.grey, size: 20)),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 18),
                                  onPressed: () => _openCategoryDialog(docId: docId, existingData: data),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                                  onPressed: () => _confirmDeleteCategory(docId, name),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== ADD / EDIT DIALOG ====================
  void _openCategoryDialog({String? docId, Map<String, dynamic>? existingData}) {
    if (existingData != null) {
      _editingDocId = docId;
      _nameController.text = existingData['categoryName'] ?? '';
      _descController.text = existingData['description'] ?? '';
      _orderController.text = (existingData['displayOrder'] ?? 0).toString();
      _iconUrlController.text = existingData['customIconUrl'] ?? existingData['icon'] ?? existingData['iconUrl'] ?? '';
      _isActive = (existingData['status'] ?? 'ACTIVE') == 'ACTIVE';
      _isFeatured = existingData['featured'] ?? false;
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) {
        bool isDialogUploading = false;
        return StatefulBuilder(
          builder: (dialogCtx2, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                _editingDocId == null ? 'Add Global Category' : 'Edit Category',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Cleaning, Plumbing, Salon...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Short Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _iconUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Icon / Image URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          isDialogUploading 
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                    if (pickedFile != null) {
                                      setDialogState(() {
                                        isDialogUploading = true;
                                      });
                                      try {
                                        final bytes = await pickedFile.readAsBytes();
                                        final url = await CloudinaryService.uploadImageBytes(
                                          bytes: bytes,
                                          fileName: pickedFile.name,
                                        );
                                        if (url != null) {
                                          setDialogState(() {
                                            _iconUrlController.text = url;
                                          });
                                          AppSnackbar.show(context, 'Upload success!');
                                        } else {
                                          AppSnackbar.show(context, 'Image upload failed. Try a smaller image.', isError: true);
                                        }
                                      } catch (e) {
                                        AppSnackbar.show(context, 'Upload failed: $e', isError: true);
                                      } finally {
                                        setDialogState(() {
                                          isDialogUploading = false;
                                        });
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text('Upload'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                        ],
                      ),
                      if (_iconUrlController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _convertDriveUrl(_iconUrlController.text.trim()),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isActive,
                            onChanged: (val) => setDialogState(() => _isActive = val ?? true),
                          ),
                          const Text('Active Listing'),
                          const Spacer(),
                          Checkbox(
                            value: _isFeatured,
                            onChanged: (val) => setDialogState(() => _isFeatured = val ?? false),
                          ),
                          const Text('Featured Category'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) {
                      AppSnackbar.show(context, 'Please enter a category name', isError: true);
                      return;
                    }

                    String targetIconUrl = _iconUrlController.text.trim();
                    if (targetIconUrl.isNotEmpty && 
                        !targetIconUrl.contains('cloudinary.com') && 
                        (targetIconUrl.startsWith('http://') || targetIconUrl.startsWith('https://'))) {
                      AppSnackbar.show(context, 'Hosting pasted URL image to Cloudinary...');
                      final hostedUrl = await _uploadExternalUrlToCloudinary(targetIconUrl);
                      if (hostedUrl != null) {
                        targetIconUrl = hostedUrl;
                        _iconUrlController.text = hostedUrl;
                      }
                    }

                    final catData = {
                      'categoryName': _nameController.text.trim(),
                      'description': _descController.text.trim(),
                      'displayOrder': int.tryParse(_orderController.text.trim()) ?? 0,
                      'icon': targetIconUrl,
                      'customIconUrl': targetIconUrl,
                      'status': _isActive ? 'ACTIVE' : 'INACTIVE',
                      'featured': _isFeatured,
                      'updatedAt': Timestamp.now(),
                    };

                    if (_editingDocId == null) {
                      catData['createdAt'] = Timestamp.now();
                      await FirebaseFirestore.instance.collection('categories').add(catData);
                    } else {
                      await FirebaseFirestore.instance.collection('categories').doc(_editingDocId).update(catData);
                    }

                    if (mounted) {
                      AppSnackbar.show(context, 'Category saved successfully!');
                    }
                    Navigator.pop(dialogCtx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(String docId, String name) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Delete Category "$name"?'),
          content: const Text('Are you sure you want to delete this category? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('categories').doc(docId).delete();
                if (mounted) {
                  AppSnackbar.show(context, 'Category deleted');
                }
                Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
