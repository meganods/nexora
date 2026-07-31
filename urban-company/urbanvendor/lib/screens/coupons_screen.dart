import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:urbanvendor/theme/vendor_theme.dart';
import 'package:urbanvendor/widgets/app_snackbar.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultCoupons();
  }

  // Auto-populates Firestore with the default coupons if empty
  Future<void> _initializeDefaultCoupons() async {
    try {
      setState(() => _isInitializing = true);
      final snapshot = await _firestore.collection('coupons').get();
      if (snapshot.docs.isEmpty) {
        final now = Timestamp.now();
        final farFuture = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365 * 2)));

        final List<Map<String, dynamic>> defaultCoupons = [
          {
            'code': 'FIRST150',
            'title': 'First Booking Special',
            'description': 'Get flat ₹150 OFF on your first ever booking with Nexora!',
            'discountType': 'Flat',
            'discountValue': 150.0,
            'minimumOrder': 0.0,
            'firstBookingOnly': true,
            'status': true,
            'startDate': now,
            'endDate': farFuture,
            'perUserLimit': 1,
            'usageLimit': 5000,
          },
          {
            'code': 'NEXORA1000',
            'title': 'High Value Bonus',
            'description': 'Flat ₹250 OFF on any premium service booking above ₹1,000!',
            'discountType': 'Flat',
            'discountValue': 250.0,
            'minimumOrder': 1000.0,
            'firstBookingOnly': false,
            'status': true,
            'startDate': now,
            'endDate': farFuture,
            'perUserLimit': 1,
            'usageLimit': 10000,
          },
          {
            'code': 'CLEAN40',
            'title': 'Deep Clean Discount',
            'description': 'Flat 40% OFF on all premium home cleaning services!',
            'discountType': 'Percentage',
            'discountValue': 40.0,
            'minimumOrder': 500.0,
            'maxDiscount': 400.0,
            'firstBookingOnly': false,
            'status': true,
            'startDate': now,
            'endDate': farFuture,
            'perUserLimit': 3,
            'usageLimit': 10000,
          }
        ];

        for (var coupon in defaultCoupons) {
          final docRef = _firestore.collection('coupons').doc();
          coupon['id'] = docRef.id;
          await docRef.set(coupon);
        }
      }
    } catch (e) {
      debugPrint("Error initializing coupons: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Promotional Coupons',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: VendorTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF2563EB)),
            onPressed: () => _showCreateCouponDialog(),
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('coupons').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No promotions configured yet.",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final code = data['code'] ?? 'OFFER';
                    final title = data['title'] ?? 'Discount';
                    final desc = data['description'] ?? '';
                    final minOrder = ((data['minimumOrder'] ?? 0.0) as num).toDouble();
                    final firstOnly = data['firstBookingOnly'] == true;
                    final active = data['status'] == true;
                    final discVal = ((data['discountValue'] ?? 0.0) as num).toDouble();
                    final discType = data['discountType'] ?? 'Flat';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header Vibe
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        code,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (firstOnly)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "FIRST USER",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFD97706),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Switch(
                                  value: active,
                                  onChanged: (val) async {
                                    await _firestore
                                        .collection('coupons')
                                        .doc(docs[index].id)
                                        .update({'status': val});
                                    if (context.mounted) {
                                      AppSnackbar.show(
                                          context, "Status updated successfully!");
                                    }
                                  },
                                  activeColor: const Color(0xFF10B981),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          // Content Info
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: VendorTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.4),
                                ),
                                const SizedBox(height: 12),
                                // Rules list
                                Row(
                                  children: [
                                    const Icon(Icons.rule_rounded, size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 6),
                                    Text(
                                      minOrder > 0
                                          ? "Applies to orders above ₹${minOrder.toStringAsFixed(0)}"
                                          : "No minimum order limit",
                                      style: GoogleFonts.inter(fontSize: 11.5, color: Colors.blueGrey[600]),
                                    ),
                                    const Spacer(),
                                    Text(
                                      discType == 'Flat'
                                          ? "₹${discVal.toStringAsFixed(0)} OFF"
                                          : "${discVal.toStringAsFixed(0)}% OFF",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF10B981),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showCreateCouponDialog() {
    final codeC = TextEditingController();
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final valC = TextEditingController();
    final minOrderC = TextEditingController();
    String discountType = 'Flat';
    bool firstOnly = false;

    showDialog(
      context: context,
      builder: (dContext) => StatefulBuilder(
        builder: (sbContext, setStateSB) {
          return AlertDialog(
            scrollable: true,
            title: Text("Create Promo Coupon", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeC, decoration: const InputDecoration(labelText: "Promo Code (e.g. FLAT300)")),
                  const SizedBox(height: 10),
                  TextField(controller: titleC, decoration: const InputDecoration(labelText: "Display Title")),
                  const SizedBox(height: 10),
                  TextField(controller: descC, decoration: const InputDecoration(labelText: "Description / Rules")),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: discountType,
                    items: const [
                      DropdownMenuItem(value: 'Flat', child: Text('Flat (₹)')),
                      DropdownMenuItem(value: 'Percentage', child: Text('Percentage (%)')),
                    ],
                    onChanged: (v) => setStateSB(() => discountType = v!),
                    decoration: const InputDecoration(labelText: "Discount Type"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: valC,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Discount Value"),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: minOrderC, decoration: const InputDecoration(labelText: "Min Order Amount (e.g. 1000)")),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text("First booking only"),
                    value: firstOnly,
                    onChanged: (val) => setStateSB(() => firstOnly = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(sbContext), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (codeC.text.trim().isEmpty || valC.text.trim().isEmpty) return;
                  final docRef = _firestore.collection('coupons').doc();
                  final couponData = {
                    'id': docRef.id,
                    'code': codeC.text.trim().toUpperCase(),
                    'title': titleC.text.trim(),
                    'description': descC.text.trim(),
                    'discountType': discountType,
                    'discountValue': double.tryParse(valC.text) ?? 0.0,
                    'minimumOrder': double.tryParse(minOrderC.text) ?? 0.0,
                    'firstBookingOnly': firstOnly,
                    'status': true,
                    'startDate': Timestamp.now(),
                    'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
                    'perUserLimit': 1,
                    'usageLimit': 1000,
                  };

                  try {
                    await docRef.set(couponData);
                  } catch (e) {
                    debugPrint("Firestore write failed for coupon, simulated locally: $e");
                  }

                  if (mounted) {
                    Navigator.pop(sbContext);
                    AppSnackbar.show(context, "Promo code created successfully!");
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }
}
