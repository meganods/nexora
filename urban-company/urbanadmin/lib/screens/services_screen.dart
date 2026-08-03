import 'package:urbanadmin/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _selectedStatusFilter = 'Pending Review'; // Pending Review, Approved, Changes Requested, Rejected, Draft, Disabled, Archived
  final List<String> _statusFilters = [
    'Pending Review',
    'Approved',
    'Changes Requested',
    'Rejected',
    'Draft',
    'Disabled',
    'Archived'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildFiltersTab(),
        const SizedBox(height: 24),
        _buildServicesList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partner Service Approvals',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review, approve, or request changes for partner-created services and pricing models.',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((status) {
          final isSelected = _selectedStatusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedStatusFilter = status);
                }
              },
              selectedColor: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServicesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('status', isEqualTo: _selectedStatusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.packageOpen, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text(
                  'No services found matching status: $_selectedStatusFilter',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String serviceId = doc.id;
            final String serviceName = data['serviceName'] ?? 'Unnamed Service';
            final String description = data['shortDescription'] ?? data['description'] ?? 'No description';
            final String vendorName = data['vendorName'] ?? 'Unknown Vendor';
            final String categoryId = data['categoryId'] ?? '';
            final String coverImage = data['coverImage'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover image container
                    Container(
                      width: 120,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF1F5F9),
                        image: coverImage.isNotEmpty
                            ? DecorationImage(image: NetworkImage(coverImage), fit: BoxFit.cover)
                            : null,
                      ),
                      child: coverImage.isEmpty
                          ? const Center(child: Icon(LucideIcons.image, color: Colors.grey))
                          : null,
                    ),
                    const SizedBox(width: 20),
                    // Content details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                serviceName,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F172A)),
                              ),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('categories').doc(categoryId).get(),
                                builder: (context, catSnap) {
                                  final catData = catSnap.data?.data() as Map<String, dynamic>?;
                                  final catName = catData?['categoryName'] ?? 'No Category';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      catName,
                                      style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Provider: $vendorName',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          // Live Placement Toggle Controls for Admin
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: Text(
                                  data['isRecommended'] == true ? '⭐ Recommended ON' : '⭐ Recommended OFF',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: data['isRecommended'] == true ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                                  ),
                                ),
                                selected: data['isRecommended'] == true,
                                selectedColor: const Color(0xFFDBEAFE),
                                backgroundColor: const Color(0xFFF1F5F9),
                                onSelected: (val) async {
                                  await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
                                    'isRecommended': val,
                                    'isRecommendedForYou': val,
                                  });
                                  if (mounted) {
                                    AppSnackbar.show(context, val ? 'Service marked as Recommended!' : 'Service removed from Recommended.');
                                  }
                                },
                              ),
                              FilterChip(
                                label: Text(
                                  data['isNewService'] == true ? '✨ New Service ON' : '✨ New Service OFF',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: data['isNewService'] == true ? const Color(0xFF065F46) : const Color(0xFF64748B),
                                  ),
                                ),
                                selected: data['isNewService'] == true,
                                selectedColor: const Color(0xFFD1FAE5),
                                backgroundColor: const Color(0xFFF1F5F9),
                                onSelected: (val) async {
                                  await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
                                    'isNewService': val,
                                    'isNew': val,
                                  });
                                  if (mounted) {
                                    AppSnackbar.show(context, val ? 'Service marked as New Service!' : 'Service removed from New Services.');
                                  }
                                },
                              ),
                              FilterChip(
                                label: Text(
                                  data['featured'] == true ? '🔥 Featured ON' : '🔥 Featured OFF',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: data['featured'] == true ? const Color(0xFF991B1B) : const Color(0xFF64748B),
                                  ),
                                ),
                                selected: data['featured'] == true,
                                selectedColor: const Color(0xFFFEE2E2),
                                backgroundColor: const Color(0xFFF1F5F9),
                                onSelected: (val) async {
                                  await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
                                    'featured': val,
                                  });
                                  if (mounted) {
                                    AppSnackbar.show(context, val ? 'Service marked as Featured!' : 'Service removed from Featured.');
                                  }
                                },
                              ),
                            ],
                          ),
                          if (data['rejectionReason'] != null && data['rejectionReason'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFEE2E2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Rejection / Changes Reason: ${data['rejectionReason']}',
                                      style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Review Action Button
                    ElevatedButton(
                      onPressed: () => _openReviewDialog(serviceId, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: Text('Review Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openReviewDialog(String serviceId, Map<String, dynamic> serviceData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
            padding: const EdgeInsets.all(32),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sub_services')
                  .where('serviceId', isEqualTo: serviceId)
                  .snapshots(),
              builder: (context, subSnap) {
                final subDocs = subSnap.data?.docs ?? [];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          serviceData['serviceName'] ?? 'Service Details',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 24, color: const Color(0xFF0F172A)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.x),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Expanded(
                      child: ListView(
                        children: [
                          Text('Service Description', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF334155))),
                          const SizedBox(height: 8),
                          Text(serviceData['description'] ?? 'No details provided', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569), height: 1.5)),
                          const SizedBox(height: 24),
                          Text('Nested Sub-services (${subDocs.length})', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF334155))),
                          const SizedBox(height: 12),
                          if (subDocs.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('No sub-services built under this model.', style: GoogleFonts.inter(color: Colors.grey))),
                            )
                          else
                            ...subDocs.map((sdoc) {
                              final sdata = sdoc.data() as Map<String, dynamic>;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                color: const Color(0xFFF8FAFC),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sdata['name'] ?? 'Unnamed Sub-service',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              sdata['description'] ?? '',
                                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        '₹${sdata['price'] ?? sdata['discountPrice'] ?? '0'}',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                                        child: Text(
                                          sdata['duration'] ?? '30 Mins',
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => _updateStatusDialog(serviceId, 'Changes Requested'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                            foregroundColor: const Color(0xFFD97706),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Request Changes'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => _updateStatusDialog(serviceId, 'Rejected'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            foregroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
                              'status': 'Approved',
                              'rejectionReason': '',
                            });
                            if (mounted) {
                              AppSnackbar.show(context, 'Service approved and visible to customers!');
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Approve & Publish'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _updateStatusDialog(String serviceId, String targetStatus) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$targetStatus Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Provide feedback / reason for the vendor to update or correct:'),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Images are blurry / price too high...',
                ),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
                  'status': targetStatus,
                  'rejectionReason': textController.text.trim(),
                  'adminFeedback': textController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context); // Close current prompt
                Navigator.pop(context); // Close review details dialog
                if (mounted) {
                  AppSnackbar.show(context, 'Service updated to status: $targetStatus');
                }
              },
              child: const Text('Submit'),
            )
          ],
        );
      },
    );
  }
}
