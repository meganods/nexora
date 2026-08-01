import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:urbanvendor/providers/vendor_provider.dart';
import 'package:urbanvendor/services/cloudinary_service.dart';
import 'package:urbanvendor/theme/vendor_theme.dart';
import 'package:urbanvendor/widgets/app_snackbar.dart';

class MyServicesScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;
  const MyServicesScreen({super.key, this.isTab = false, this.onBack});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 0: Dashboard, 1: My Services, 2: Revenue Streams, 3: Add/Edit Wizard, 4: Service Details, 5: Service Analytics, 6: Availability
  int _currentSubView = 0;

  // Add/Edit Wizard fields
  int _wizardStep = 1;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _detailedDescController = TextEditingController();
  final _priceController = TextEditingController(text: "250.00");
  final _durationController = TextEditingController(text: "2h 30m");
  double _coverageRadius = 25.0;
  List<String> _selectedDays = ["Mon", "Tue", "Wed", "Thu", "Fri"];
  final List<String> _weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  late final _categoryController = TextEditingController(text: "Home Care");
  late final _subcategoryController = TextEditingController(text: "Gardening");
  final List<String> _mediaPaths = []; // Starts empty — user picks from gallery
  bool _isUploadingMedia = false;

  // Phase 9 Nexora Service Management Architecture State
  String _serviceStatus = "Draft"; // Draft, Pending Review, Approved, Rejected
  String _rejectionReason = "";
  String? _submittedRequestId; // Firestore doc ID of the submitted category request
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _wizardSubServices = [];
  final List<Map<String, dynamic>> _wizardAddOns = [];
  final List<Map<String, dynamic>> _wizardFAQs = [];

  // Temporary Sub-service dialog form controllers
  final _subNameController = TextEditingController();
  final _subDescController = TextEditingController();
  final _subPriceController = TextEditingController();
  final _subDurationController = TextEditingController();
  final _subIncludedController = TextEditingController();
  final _subExcludedController = TextEditingController();

  // Temporary Add-on controllers
  final _addOnNameController = TextEditingController();
  final _addOnPriceController = TextEditingController();

  // Temporary FAQ controllers
  final _faqQController = TextEditingController();
  final _faqAController = TextEditingController();

  // Filters for My Services list
  String _searchQuery = "";
  String _selectedCategoryFilter = "All Services";
  String _selectedStatusFilter = "All";
  String _sortBy = "Price";
  String _selectedPriceRange = "All";
  Map<String, dynamic>? _selectedServiceData;

  // Stream cache to prevent rebuild blinking
  Stream<QuerySnapshot>? _servicesStreamCache;
  Stream<QuerySnapshot> get _servicesStream {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    _servicesStreamCache ??= FirebaseFirestore.instance
        .collection('services')
        .where('vendorId', isEqualTo: uid)
        .snapshots();
    return _servicesStreamCache!;
  }

  // Availability Fields
  double _basePrice = 1250.0;
  double _weekendSurcharge = 0.15;
  String _dailyHoursStr = "09:00 AM - 06:00 PM";
  String _lunchBreakStr = "01:00 PM - 02:00 PM";
  bool _holidayMode = false;
  bool _vacationMode = false;

  Future<void> _selectTimeRange(bool isLunch) async {
    final start = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (start == null) return;
    final end = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (end == null) return;
    
    setState(() {
      final timeRange = "${start.format(context)} - ${end.format(context)}";
      if (isLunch) {
        _lunchBreakStr = timeRange;
      } else {
        _dailyHoursStr = timeRange;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorProvider>(context, listen: false).fetchVendorDataRealtime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: isDesktop ? null : _buildMobileAppBar(),
          endDrawer: _buildFilterDrawer(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  // ==========================================
  // MOBILE APPBAR
  // ==========================================
  PreferredSizeWidget _buildMobileAppBar() {
    String title = "Services Dashboard";
    if (_currentSubView == 1) title = "My Services";
    if (_currentSubView == 2) title = "Revenue Streams";
    if (_currentSubView == 3) title = "Add Service";
    if (_currentSubView == 4) title = "Service Details";
    if (_currentSubView == 5) title = "Service Analytics";
    if (_currentSubView == 6) title = "Availability";

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
        onPressed: () {
          if (_currentSubView > 0) {
            // Go back to Dashboard tab inside the Services screen
            setState(() => _currentSubView = 0);
          } else if (widget.onBack != null) {
            // Embedded in dashboard — switch parent tab back to 0
            widget.onBack!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: VendorTheme.textPrimary),
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('recipientId', whereIn: [FirebaseAuth.instance.currentUser?.email ?? '', 'all', 'vendors'])
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: VendorTheme.textPrimary),
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMobileLayout() {
    Widget body;
    switch (_currentSubView) {
      case 1:
        body = _buildMyServicesMobile();
        break;
      case 2:
        body = _buildRevenueStreamsMobile();
        break;
      case 3:
        body = _buildAddEditWizardMobile();
        break;
      case 4:
        body = SingleChildScrollView(child: _buildServiceDetailsBody());
        break;
      case 5:
        body = _buildServiceAnalyticsMobile();
        break;
      case 6:
        body = _buildAvailabilityMobile();
        break;
      default:
        body = _buildServicesDashboardMobile();
    }
    return Column(
      children: [
        // Persistent Tab Bar
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: _buildMobileSubTabs(),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
          ),
        ),
        // Animated Page Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(key: ValueKey(_currentSubView), child: body),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FILTER DRAWER (RIGHT SIDE DRAWER)
  // ==========================================
  Widget _buildFilterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Filters", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              Text("Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ["All", "Active", "Inactive"].map((status) {
                  final isSel = _selectedStatusFilter == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSel,
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      setState(() => _selectedStatusFilter = status);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text("Service Category", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _servicesStream,
                  builder: (context, snapshot) {
                    final List<String> categories = [];
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final catName = data['categoryName']?.toString() ?? doc.id;
                        if (!categories.contains(catName)) {
                          categories.add(catName);
                        }
                      }
                    }
                    // Always include dummy category options alongside Firestore categories
                    for (var fallback in ["helooooo", "abcd", "service name"]) {
                      if (!categories.contains(fallback)) {
                        categories.add(fallback);
                      }
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text("All Categories"),
                          selected: _selectedCategoryFilter == "All Services",
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(color: _selectedCategoryFilter == "All Services" ? Colors.white : Colors.black87),
                          onSelected: (selected) {
                            setState(() => _selectedCategoryFilter = "All Services");
                          },
                        ),
                        ...categories.map((cat) {
                          final isSel = _selectedCategoryFilter == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                            onSelected: (selected) {
                              setState(() => _selectedCategoryFilter = cat);
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text("Price Filter", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  "All",
                  "0 to 199",
                  "200 to 499",
                  "500 to 999",
                  "1000 to 1999"
                ].map((range) {
                  final isSel = _selectedPriceRange == range;
                  return ChoiceChip(
                    label: Text(range == "All" ? "All Prices" : "₹$range"),
                    selected: isSel,
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPriceRange = range);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: const Text("Apply Filters"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 0: SERVICES DASHBOARD (MOBILE)
  // ==========================================
  Widget _buildServicesDashboardMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsCard("Total Services", "42", "+4 this month", Colors.blue, Icons.inventory_2_outlined),
          const SizedBox(height: 12),
          _buildMetricsCard("Active", "38", "90% active rate", Colors.green, Icons.check_circle_outline_rounded),
          const SizedBox(height: 12),
          _buildMetricsCard("Inactive", "4", "Drafts & Paused", Colors.red, Icons.pause_circle_outline_rounded),
          const SizedBox(height: 20),
          _buildOptimizePricingCard(),
          const SizedBox(height: 20),
          Text("Recent Activity", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
          const SizedBox(height: 12),
          _buildRecentActivityItem("AC Repair", "Price updated", "₹85 -> ₹92", "2h ago"),
          _buildRecentActivityItem("Leakage Plumbing", "New Add-on added", "Pipe Insulation", "5h ago"),
          _buildRecentActivityItem("Home Security Install", "Status change", "Active -> Inactive", "Yesterday"),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 1: MY SERVICES (MOBILE)
  // ==========================================
  Widget _buildMyServicesMobile() {
    final provider = Provider.of<VendorProvider>(context);
    final vendor = provider.vendorData;
    final selectedCategoryIds = List<String>.from(vendor?['selectedCategoryIds'] ?? []);
    final enabledServiceIds = List<String>.from(vendor?['enabledServices'] ?? []);

    return Column(
      children: [
        // Horizontal Scrollable Categories Tabs
        Container(
          height: 56,
          color: Colors.white,
          child: StreamBuilder<QuerySnapshot>(
            stream: _servicesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final categories = snapshot.data!.docs
                  .map((doc) => (doc.data() as Map<String, dynamic>)['categoryName']?.toString() ?? doc.id)
                  .toList();
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: categories.length + 1,
                itemBuilder: (context, idx) {
                  final label = idx == 0 ? "All Services" : categories[idx - 1];
                  return _buildCategoryPill(label);
                },
              );
            },
          ),
        ),
        
        // Search & Filter Trigger Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: VendorTheme.textSecondary, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              hintText: "Search services...",
              hintStyle: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 13),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),

        // Live Catalog List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _servicesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              // Flatten all subServices from enabled categories and collect IDs
              final List<Map<String, dynamic>> subServices = [];
              final List<String> allSubServiceIds = [];

              for (var doc in snapshot.data!.docs) {
                final catData = doc.data() as Map<String, dynamic>;
                final catName = catData['categoryName'] ?? 'General';
                final subList = List<Map<String, dynamic>>.from(catData['subServices'] ?? []);
                
                for (var ss in subList) {
                  final ssId = ss['id']?.toString() ?? '';
                  if (ssId.isNotEmpty) {
                    allSubServiceIds.add(ssId);
                  }
                  
                  // Only filter by active category pill if selected
                  if (_selectedCategoryFilter == "All Services" || _selectedCategoryFilter == catName) {
                    subServices.add({
                      ...ss,
                      'category': catName,
                      'isActive': enabledServiceIds.isEmpty || enabledServiceIds.contains(ssId),
                    });
                  }
                }
              }

              // Automatically synchronize Firestore vendor doc to activate all services
              if (allSubServiceIds.isNotEmpty && user?.email != null) {
                final missingIds = allSubServiceIds.where((id) => !enabledServiceIds.contains(id)).toList();
                if (missingIds.isNotEmpty) {
                  FirebaseFirestore.instance.collection('vendors').doc(user!.email).update({
                    'enabledServices': FieldValue.arrayUnion(missingIds),
                    'selectedCategoryIds': FieldValue.arrayUnion(snapshot.data!.docs.map((doc) => doc.id).toList()),
                  });
                }
              }

              // Apply Search text query
              var filteredList = subServices.where((ss) {
                final title = (ss['title'] ?? '').toString().toLowerCase();
                return title.contains(_searchQuery.toLowerCase());
              }).toList();

              // Apply Status chip filtering
              if (_selectedStatusFilter == "Active") {
                filteredList = filteredList.where((ss) => ss['isActive'] == true).toList();
              } else if (_selectedStatusFilter == "Inactive") {
                filteredList = filteredList.where((ss) => ss['isActive'] == false).toList();
              }

              // Apply Price Range filtering
              if (_selectedPriceRange != "All") {
                filteredList = filteredList.where((ss) {
                  final priceStr = ss['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
                  final double priceVal = double.tryParse(priceStr) ?? 0;
                  if (_selectedPriceRange == "0 to 199") {
                    return priceVal >= 0 && priceVal <= 199;
                  } else if (_selectedPriceRange == "200 to 499") {
                    return priceVal >= 200 && priceVal <= 499;
                  } else if (_selectedPriceRange == "500 to 999") {
                    return priceVal >= 500 && priceVal <= 999;
                  } else if (_selectedPriceRange == "1000 to 1999") {
                    return priceVal >= 1000 && priceVal <= 1999;
                  }
                  return true;
                }).toList();
              }

              // Apply Sorting
              if (_sortBy == "Price") {
                filteredList.sort((a, b) {
                  final pA = double.tryParse(a['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0;
                  final pB = double.tryParse(b['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0;
                  return pA.compareTo(pB);
                });
              } else {
                filteredList.sort((a, b) => (a['title'] ?? '').toString().compareTo((b['title'] ?? '').toString()));
              }

              if (filteredList.isEmpty) {
                return Center(
                  child: Text("No services matched.", style: GoogleFonts.inter(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final ss = filteredList[index];
                  final String price = ss['price']?.toString() ?? '0';
                  final String formattedPrice = price.startsWith('₹') ? price : '₹$price';

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedServiceData = ss;
                      _currentSubView = 4;
                    }),
                    child: _buildMobileServiceCard(
                      ss['category'] ?? 'Service',
                      ss['title'] ?? 'NEX Service',
                      formattedPrice,
                      ss['duration'] ?? 'Variable',
                      "4.8",
                      ss['isActive'] == true,
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Create Action
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _currentSubView = 3),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text("Create New Service"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: REVENUE STREAMS (MOBILE)
  // ==========================================
  Widget _buildRevenueStreamsMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsCard("Average Order Value", "₹${_basePrice.toInt()}", "+12.4% vs last month", Colors.blue, Icons.analytics_outlined),
          const SizedBox(height: 12),
          _buildMetricsCard("Add-on Conversion", "68.2%", "Top Performer: 'Open Bar'", Colors.teal, Icons.auto_awesome_rounded),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 3: ADD/EDIT WIZARD (MOBILE)
  // ==========================================
  Widget _buildAddEditWizardMobile() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Step $_wizardStep of 6: ${_getWizardStepName()}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2563EB))),
                Text("${(_wizardStep / 6 * 100).toInt()}%", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VendorTheme.textSecondary)),
              ],
            ),
          ),
          LinearProgressIndicator(value: _wizardStep / 6, color: const Color(0xFF2563EB), backgroundColor: const Color(0xFFE2E8F0)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _wizardStep == 1
                  ? _buildWizardStep1()
                  : _wizardStep == 2
                      ? _buildWizardStep2()
                      : _wizardStep == 3
                          ? _buildWizardStep3()
                          : _wizardStep == 4
                              ? _buildWizardStep4()
                              : _wizardStep == 5
                                  ? _buildWizardStep5()
                                  : _wizardStep == 6
                                      ? _buildWizardStep6()
                                      : const SizedBox.shrink(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                if (_wizardStep > 1) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _wizardStep--),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text("Back"),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () async {
                      if (_wizardStep < 6) {
                        setState(() => _wizardStep++);
                      } else {
                        // Already submitted — don't submit again
                        if (_submittedRequestId != null) return;
                        await _submitServiceForAdminReview();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _submittedRequestId != null ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_wizardStep == 6
                              ? (_submittedRequestId != null ? "✓ Submitted" : "Submit For Review 🚀")
                              : "Continue"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWizardStepName() {
    switch (_wizardStep) {
      case 1: return "Basic Info";
      case 2: return "Media Uploads";
      case 3: return "Service Details";
      case 4: return "Sub Services";
      case 5: return "Add-ons & FAQs";
      case 6: return "Review & Submit";
      default: return "";
    }
  }

  // ==========================================
  // VIEW 5: SERVICE ANALYTICS (MOBILE)
  // ==========================================
  Widget _buildServiceAnalyticsMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Live Stats", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: Text("Last 30 Days ▾", style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              _buildSimpleKPI("Total Revenue", "₹12.4k", "+12.5%", Colors.blue, [20, 35, 28, 42, 38, 55, 60, 72, 68, 80]),
              _buildSimpleKPI("Bookings", "184", "+8.2%", Colors.green, [10, 18, 14, 22, 30, 25, 35, 40, 38, 45]),
              _buildSimpleKPI("Views", "3.2k", "Steady", Colors.purple, [50, 48, 55, 52, 58, 54, 60, 57, 62, 65]),
              _buildSimpleKPI("Conversion", "5.8%", "Top 10%", Colors.orange, [3, 4, 3.5, 5, 4.8, 6, 5.5, 6.2, 7, 5.8]),
            ],
          ),
          const SizedBox(height: 24),
          Text("Revenue Growth", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            height: 172,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildFakeBar("Mon", 60),
                _buildFakeBar("Tue", 80),
                _buildFakeBar("Wed", 70),
                _buildFakeBar("Thu", 95),
                _buildFakeBar("Fri", 50),
                _buildFakeBar("Sat", 85),
                _buildFakeBar("Sun", 110, isAccent: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Top Services", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildTopServiceRow("Deep Tissue Therapy", "42 bookings • ₹2,100", "+14%"),
          _buildTopServiceRow("Hydra-Facial Glow", "38 bookings • ₹1,900", "+8%"),
          _buildTopServiceRow("Aromatherapy Session", "29 bookings • ₹1,450", "-2%"),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 6: AVAILABILITY & WORKING HOURS (MOBILE)
  // ==========================================
  Widget _buildAvailabilityMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("CURRENT STATUS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.0)),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Open for Business", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Available until 6:00 PM today", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Working Days", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekdays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(day, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Daily Hours", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(_dailyHoursStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _selectTimeRange(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.restaurant_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Lunch Break", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(_lunchBreakStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _selectTimeRange(true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Special Modes", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text("Holiday Mode", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Automatically close on local public holidays.", style: GoogleFonts.inter(fontSize: 12)),
            value: _holidayMode,
            onChanged: (v) => setState(() => _holidayMode = v),
          ),
          SwitchListTile(
            title: Text("Vacation Mode", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Pause all bookings for a set period.", style: GoogleFonts.inter(fontSize: 12)),
            value: _vacationMode,
            onChanged: (v) => setState(() => _vacationMode = v),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (STITCH INSPIRED)
  // ==========================================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PERFORMANCE HUB", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text("Services Dashboard", style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentSubView = 3),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text("New Service Offering"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDesktopSubTabs(),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey(_currentSubView),
                    child: _currentSubView == 0 ? _buildDesktopDashboardPane()
                        : _currentSubView == 1 ? _buildDesktopMyServicesPane()
                        : _currentSubView == 2 ? _buildDesktopRevenueStreamsPane()
                        : _currentSubView == 3 ? _buildDesktopWizardPane()
                        : _currentSubView == 4 ? _buildServiceDetailsBody()
                        : _currentSubView == 5 ? _buildServiceAnalyticsMobile()
                        : _buildAvailabilityMobile(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopDashboardPane() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 8,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetricsCard("Total Services", "42", "+4 this month", Colors.blue, Icons.inventory_2_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricsCard("Active", "38", "Active listings", Colors.green, Icons.check_circle_outline_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricsCard("Inactive", "4", "Drafts & Paused", Colors.red, Icons.pause_circle_outline_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricsCard("Top Performer", "Premium...", "824 Bookings", Colors.purple, Icons.star_border_rounded)),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Service Activity", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("View All Updates", style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildActivityTableHeader(),
                    _buildRecentActivityItem("AC Repair", "Price updated", "₹85 -> ₹92", "2h ago"),
                    const Divider(),
                    _buildRecentActivityItem("Leakage Plumbing", "New Add-on added", "Pipe Insulation", "5h ago"),
                    const Divider(),
                    _buildRecentActivityItem("Home Security Install", "Status change", "Active -> Inactive", "Yesterday"),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildOptimizePricingCard(),
            ],
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildQuickManagementPane(),
              const SizedBox(height: 28),
              _buildListingHealthCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopMyServicesPane() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: "Search by name, ID, or keyword...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded),
                label: const Text("Export Catalog"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDesktopServicesTable(),
        ],
      ),
    );
  }

  Widget _buildDesktopRevenueStreamsPane() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Advanced Pricing", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Text("Standard Base Price (per 4h)", style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: "₹ ${_basePrice.toInt()}",
                  onChanged: (val) {
                    final cleanVal = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
                    if (cleanVal != null) {
                      setState(() => _basePrice = cleanVal);
                    }
                  },
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Weekend Surcharge (%)", style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary)),
                    Text("${(_weekendSurcharge * 100).toInt()}%", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                  ],
                ),
                Slider(
                  value: _weekendSurcharge,
                  onChanged: (v) => setState(() => _weekendSurcharge = v),
                  activeColor: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 20),
                Text("Peak Season Multiplier", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dec 15 - Jan 05", style: GoogleFonts.inter(fontSize: 13)),
                      Text("x 1.50 multiplier", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          flex: 7,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add-on Inventory", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                _buildAddonInventoryRow("Premium Open Bar", "₹45.00", "Per Guest"),
                const Divider(),
                _buildAddonInventoryRow("AV Tech Package", "₹850.00", "Flat Fee"),
                const Divider(),
                _buildAddonInventoryRow("Floral Centerpieces", "₹120.00", "Per Table"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopWizardPane() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Add New Service offering", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _currentSubView = 0)),
            ],
          ),
          const SizedBox(height: 24),
          _buildWizardStep1(),
          const SizedBox(height: 24),
          _buildWizardStep2(),
          const SizedBox(height: 24),
          _buildWizardStep3(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _currentSubView = 0),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(context, "Service Created Successfully! 🚀");
                  setState(() => _currentSubView = 1);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
                child: const Text("Publish Service 🚀"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 4: SERVICE DETAILS (DESKTOP DETAIL BLOCK)
  // ==========================================
  Widget _buildServiceDetailsBody() {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
    final serviceName = _selectedServiceData?['title'] ?? "Corporate Facility Management";
    final categoryLabel = _selectedServiceData?['category'] ?? "Premium Tier";
    final bool isServiceActive = _selectedServiceData?['isActive'] == true;

    final coverImage = Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1000"), fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: Colors.black.withValues(alpha: 0.4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(6)),
                      child: Text(categoryLabel, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(serviceName, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text("ID: NEX-8829-CFM", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final statusCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Service Status", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              Switch(
                value: isServiceActive,
                activeColor: const Color(0xFF2563EB),
                onChanged: (v) {
                  setState(() {
                    if (_selectedServiceData != null) {
                      _selectedServiceData!['isActive'] = v;
                    }
                  });
                  final serviceId = _selectedServiceData?['id']?.toString() ?? '';
                  if (serviceId.isNotEmpty && user?.email != null) {
                    FirebaseFirestore.instance.collection('vendors').doc(user!.email).update({
                      'enabledServices': v
                          ? FieldValue.arrayUnion([serviceId])
                          : FieldValue.arrayRemove([serviceId])
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(isServiceActive ? "Currently visible to customers" : "Paused - Invisible to customers", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentSubView = 3;
                      _wizardStep = 4;
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text("Edit Details"),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final performanceInsightsCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Performance Insights", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("98.4%", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
              const SizedBox(width: 8),
              Text("+2.1%", style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );

    final overviewText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Service Overview", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Text(
          "Professional high-quality facility management and customized service solutions matching enterprise SLA metrics with smart IoT reporting systems.",
          style: GoogleFonts.inter(color: VendorTheme.textSecondary, height: 1.5, fontSize: 14),
        ),
      ],
    );

    final listDetails = isDesktop
        ? Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Included", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                      const SizedBox(height: 8),
                      _buildBullet("Daily Sanitization Protocols"),
                      _buildBullet("Standard equipment inspection"),
                      _buildBullet("Smart system monitoring"),
                      _buildBullet("Dedicated account helpdesk"),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Excluded", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      _buildBullet("Heavy parts replacement"),
                      _buildBullet("Hazardous chemicals"),
                      _buildBullet("Structural modification"),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Included", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                    const SizedBox(height: 8),
                    _buildBullet("Daily Sanitization Protocols"),
                    _buildBullet("Standard equipment inspection"),
                    _buildBullet("Smart system monitoring"),
                    _buildBullet("Dedicated account helpdesk"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Excluded", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    _buildBullet("Heavy parts replacement"),
                    _buildBullet("Hazardous chemicals"),
                    _buildBullet("Structural modification"),
                  ],
                ),
              ),
            ],
          );

    final backButton = TextButton.icon(
      onPressed: () => setState(() => _currentSubView = 1),
      icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF2563EB)),
      label: Text("Back to My Services", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
    );

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            backButton,
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      coverImage,
                      const SizedBox(height: 24),
                      overviewText,
                      const SizedBox(height: 24),
                      listDetails,
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      statusCard,
                      const SizedBox(height: 24),
                      performanceInsightsCard,
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            backButton,
            const SizedBox(height: 16),
            coverImage,
            const SizedBox(height: 16),
            statusCard,
            const SizedBox(height: 16),
            performanceInsightsCard,
            const SizedBox(height: 20),
            overviewText,
            const SizedBox(height: 20),
            listDetails,
          ],
        ),
      );
    }
  }

  // ==========================================
  // SHARED DESKTOP WIDGET HELPMETHODS
  // ==========================================
  Widget _buildDesktopSubTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSubTabButton("Dashboard", 0),
          _buildSubTabButton("My Services", 1),
          _buildSubTabButton("Revenue Streams", 2),
          _buildSubTabButton("Analytics", 5),
          _buildSubTabButton("Availability", 6),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, int index) {
    final isSelected = _currentSubView == index;
    return GestureDetector(
      onTap: () => setState(() => _currentSubView = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: isSelected ? Colors.white : VendorTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSubTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSubTabButton("Dashboard", 0),
          _buildSubTabButton("My Services", 1),
          _buildSubTabButton("Revenue", 2),
          _buildSubTabButton("Analytics", 5),
          _buildSubTabButton("Availability", 6),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label) {
    final isSelected = _selectedCategoryFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF2563EB))),
      ),
    );
  }

  Widget _buildMetricsCard(String label, String value, String trend, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(trend, style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: VendorTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOptimizePricingCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 450;
        final cardContent = [
          Expanded(
            flex: useVerticalLayout ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Optimize your pricing.", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                const SizedBox(height: 8),
                Text("Our AI analyzed your market competitors. You could increase revenue by 14% by bundling 'Add-ons' with your top 3 services.", style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _currentSubView = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("View Suggestions"),
                ),
              ],
            ),
          ),
          if (useVerticalLayout) const SizedBox(height: 16) else const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=200",
              width: useVerticalLayout ? double.infinity : 100,
              height: useVerticalLayout ? 120 : 90,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                width: useVerticalLayout ? double.infinity : 100, height: useVerticalLayout ? 120 : 90,
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics_rounded, size: 36, color: Color(0xFF2563EB)),
              ),
            ),
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: useVerticalLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cardContent,
                )
              : Row(
                  children: cardContent,
                ),
        );
      },
    );
  }

  Widget _buildRecentActivityItem(String name, String action, String change, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), radius: 18, child: Icon(Icons.history, color: Colors.blueGrey)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(action, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
              child: Text(change, style: GoogleFonts.inter(color: const Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 10), overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildActivityTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("SERVICE ITEM", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text("ACTIVITY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text("CHANGE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text("TIMESTAMP", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildMobileServiceCard(String category, String name, String price, String duration, String rating, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1542038784456-1ea8e935640e?w=200"), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: const Color(0xFF2563EB))),
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: VendorTheme.textPrimary)),
                const SizedBox(height: 4),
                Text("$price • $duration", style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: Text(isActive ? "ACTIVE" : "PAUSED", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 9, color: isActive ? const Color(0xFF15803D) : Colors.grey)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(rating, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickManagementPane() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Management", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildQuickActionRow("Add New Service", "Create a listing from scratch", Icons.add_circle_outline_rounded),
          const Divider(),
          _buildQuickActionRow("Manage Add-ons", "Upsell with extra features", Icons.add_moderator_outlined),
          const Divider(),
          _buildQuickActionRow("Update Pricing", "Bulk adjust service rates", Icons.currency_exchange_rounded),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow(String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () => setState(() => _currentSubView = 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildListingHealthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Listing Health", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: Text("Good", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHealthIndicator("Image Quality", 0.92),
          const SizedBox(height: 12),
          _buildHealthIndicator("Description Length", 0.64),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String title, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13)),
            Text("${(progress * 100).toInt()}%", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress, color: const Color(0xFF15803D), backgroundColor: const Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildDesktopServicesTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(3),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
          children: [
            _buildTableHeaderCell("SERVICE DETAILS"),
            _buildTableHeaderCell("CATEGORY"),
            _buildTableHeaderCell("PRICE/DURATION"),
            _buildTableHeaderCell("PERFORMANCE"),
            _buildTableHeaderCell("STATUS"),
          ],
        ),
        _buildDesktopTableServiceRow("Premium Brand Strategy", "Marketing", "₹1,250.00 / 90 Min", "4.9 (124) Bookings", "Active"),
        _buildDesktopTableServiceRow("Technical Architecture Audit", "Engineering", "₹2,800.00 / Full Day", "5.0 (18) Bookings", "Inactive"),
        _buildDesktopTableServiceRow("Visual Identity Package", "Creative Design", "₹4,500.00 / Project", "4.8 (310) Bookings", "Active"),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  TableRow _buildDesktopTableServiceRow(String title, String category, String price, String performance, String status) {
    final isActive = status == "Active";
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: GestureDetector(
            onTap: () => setState(() => _currentSubView = 4),
            child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2563EB))),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(category, style: GoogleFonts.inter(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(price, style: GoogleFonts.inter(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(performance, style: GoogleFonts.inter(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(status, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddonInventoryRow(String title, String price, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(price, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
          const SizedBox(width: 12),
          Text(type, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildContractCard(String title, String price, List<String> lines, bool isPopular) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPopular ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPopular ? Colors.transparent : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
              child: Text("POPULAR", style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isPopular ? Colors.white70 : Colors.grey)),
          Text(price, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: isPopular ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: isPopular ? Colors.greenAccent : Colors.green),
                    const SizedBox(width: 8),
                    Text(l, style: GoogleFonts.inter(fontSize: 12, color: isPopular ? Colors.white70 : Colors.black87)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: isPopular ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9)),
              child: Text(isPopular ? "Current Selection" : "Select Tier", style: TextStyle(color: isPopular ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleKPI(String title, String value, String change, Color color, List<double> sparkData) {
    final bool isPositive = !change.startsWith('-');
    final Color changeColor = change == "Steady" ? Colors.orange : (isPositive ? Colors.green : Colors.red);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: changeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(change, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: changeColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary)),
          const Spacer(),
          SizedBox(
            height: 36,
            child: CustomPaint(
              size: const Size(double.infinity, 36),
              painter: _SparklinePainter(sparkData, color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFakeBar(String label, double height, {bool isAccent = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(color: isAccent ? const Color(0xFF2563EB) : const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTopServiceRow(String name, String bookings, String change) {
    final isPositive = !change.startsWith('-');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(bookings, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
          Text(change, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildTimeConfigRow(String title, String hours, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(hours, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildWizardStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Service Name *", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: "e.g. Deep Home Cleaning",
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Category *", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: "e.g. Home Care",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Subcategory *", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _subcategoryController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: "e.g. Gardening",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text("Short Description", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _shortDescController,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: "Quick summary line..."),
        ),
        const SizedBox(height: 16),
        Text("Detailed Description", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _detailedDescController,
          maxLines: 3,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: "Detailed service descriptions..."),
        ),
      ],
    );
  }

  Widget _buildWizardStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Service Media", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text("Cover and showcase gallery images (Max 10)", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Add Photo button
            GestureDetector(
              onTap: _isUploadingMedia || _mediaPaths.length >= 10 ? null : _pickAndUploadImage,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: _isUploadingMedia
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB))))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF2563EB)),
                          SizedBox(height: 4),
                          Text("Add Photo", style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            // Uploaded images with remove button
            ..._mediaPaths.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Remove (X) button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _mediaPaths.removeAt(index)),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        if (_mediaPaths.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              "Tap \"Add Photo\" to pick images from your gallery.",
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isUploadingMedia = true);

      String? uploadedUrl;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadedUrl = await CloudinaryService.uploadImageBytes(
          bytes: bytes,
          fileName: image.name,
          folder: 'service_media',
        );
      } else {
        uploadedUrl = await CloudinaryService.uploadImage(
          filePath: image.path,
          folder: 'service_media',
        );
      }

      if (uploadedUrl != null) {
        setState(() {
          _mediaPaths.add(uploadedUrl!);
          _isUploadingMedia = false;
        });
      } else {
        setState(() => _isUploadingMedia = false);
        if (mounted) AppSnackbar.show(context, 'Upload failed. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() => _isUploadingMedia = false);
      if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
    }
  }

  Widget _buildWizardStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Service Duration & Range", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: "Est. Duration"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Est. Base Price (₹)"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Service Radius Range", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            Text("${_coverageRadius.toInt()} km", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
          ],
        ),
        Slider(
          value: _coverageRadius,
          min: 5,
          max: 100,
          onChanged: (v) => setState(() => _coverageRadius = v),
          activeColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _buildWizardStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Sub Services", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton.icon(
              onPressed: _showAddSubServiceDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add Sub Service"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_wizardSubServices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text("No sub-services added yet. Add at least one.", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ),
          )
        else
          Column(
            children: _wizardSubServices.map((sub) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text("Price: ₹${sub['price']} • Duration: ${sub['duration']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _wizardSubServices.remove(sub);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWizardStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Service Add-ons", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton.icon(
              onPressed: _showAddAddonDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Link Add-on"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_wizardAddOns.isEmpty)
          Text("No add-ons created.", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            children: _wizardAddOns.map((addon) {
              return Chip(
                label: Text("${addon['name']} (₹${addon['price']})"),
                onDeleted: () => setState(() => _wizardAddOns.remove(addon)),
              );
            }).toList(),
          ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("FAQ List Builder", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton.icon(
              onPressed: _showAddFAQDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add FAQ"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_wizardFAQs.isEmpty)
          Text("No FAQs configured.", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey))
        else
          Column(
            children: _wizardFAQs.map((faq) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(faq['q'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(faq['a'], style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                    onPressed: () => setState(() => _wizardFAQs.remove(faq)),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWizardStep6() {
    if (_submittedRequestId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .doc(_submittedRequestId)
            .snapshots(),
        builder: (context, snapshot) {
          String liveStatus = "Pending Review";
          String liveReason = "";
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            liveStatus = data['status'] ?? "Pending Review";
            liveReason = data['adminFeedback'] ?? data['rejectionReason'] ?? "";
          }
          return _buildStatusTrackerUI(liveStatus, liveReason);
        },
      );
    }

    return _buildStatusTrackerUI(_serviceStatus, _rejectionReason);
  }

  Widget _buildStatusTrackerUI(String status, String rejectionReason) {
    Color bgColor, borderColor, iconColor;
    IconData statusIcon;
    String statusLine2;

    switch (status) {
      case "Approved":
        bgColor = const Color(0xFFDCFCE7);
        borderColor = const Color(0xFF10B981);
        iconColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_outline;
        statusLine2 = "Your service is now live and visible to customers! 🎉";
        break;
      case "Changes Requested":
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFD97706);
        iconColor = const Color(0xFFD97706);
        statusIcon = Icons.rule_folder_outlined;
        statusLine2 = rejectionReason.isNotEmpty ? "Feedback: $rejectionReason" : "Admin requested updates. Please edit and submit again.";
        break;
      case "Rejected":
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFEF4444);
        iconColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_outlined;
        statusLine2 = rejectionReason.isNotEmpty ? "Reason: $rejectionReason" : "Please review your submission.";
        break;
      case "Pending Review":
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF3B82F6);
        iconColor = const Color(0xFF3B82F6);
        statusIcon = Icons.hourglass_top_rounded;
        statusLine2 = "Your request has been sent to the Nexora Admin. We'll notify you once reviewed.";
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        borderColor = Colors.grey;
        iconColor = Colors.grey;
        statusIcon = Icons.info_outline;
        statusLine2 = "Click \"Submit For Review\" below when you're ready.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Approval Status Tracker", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: borderColor,
                child: Icon(statusIcon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "STATUS: $status".toUpperCase(),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5, color: iconColor),
                    ),
                    const SizedBox(height: 4),
                    Text(statusLine2, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info steps for pending/draft
        if (status == "Draft" || status == "Pending Review") ..._buildApprovalSteps(status),
      ],
    );
  }

  List<Widget> _buildApprovalSteps(String currentStatus) {
    final steps = [
      {"label": "Service Details Filled", "done": true},
      {"label": "Submitted for Admin Review", "done": currentStatus == "Pending Review"},
      {"label": "Admin Approval", "done": false},
      {"label": "Live on Customer App", "done": false},
    ];
    return [
      Text("What happens next?", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF374151))),
      const SizedBox(height: 10),
      ...steps.asMap().entries.map((e) {
        final step = e.value;
        final isDone = step["done"] as bool;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.circle_outlined,
                  size: 16,
                  color: isDone ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                step["label"] as String,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  color: isDone ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  Future<void> _submitServiceForAdminReview() async {
    setState(() => _isSubmitting = true);
    try {
      final uid = user?.uid ?? "unknown";
      
      String vendorName = user?.displayName ?? "Vendor";
      String businessName = "";
      final vendorQuery = await FirebaseFirestore.instance
          .collection('vendors')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (vendorQuery.docs.isNotEmpty) {
        final vData = vendorQuery.docs.first.data();
        vendorName = vData['fullName'] ?? vData['name'] ?? vendorName;
        businessName = vData['businessName'] ?? "";
      }

      String categoryId = "";
      final catQuery = await FirebaseFirestore.instance
          .collection('categories')
          .where('categoryName', isEqualTo: _categoryController.text.trim())
          .limit(1)
          .get();
      if (catQuery.docs.isNotEmpty) {
        categoryId = catQuery.docs.first.id;
      }

      final serviceData = {
        'vendorId': uid,
        'categoryId': categoryId,
        'serviceName': _nameController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'description': _shortDescController.text.trim(),
        'coverImage': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
        'galleryImages': [],
        'status': 'Pending Review',
        'rejectionReason': '',
        'vendorName': vendorName,
        'businessName': businessName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final serviceRef = await FirebaseFirestore.instance
          .collection('services')
          .add(serviceData);

      final batch = FirebaseFirestore.instance.batch();
      for (var s in _wizardSubServices) {
        final subRef = FirebaseFirestore.instance.collection('sub_services').doc();
        batch.set(subRef, {
          'subServiceId': subRef.id,
          'serviceId': serviceRef.id,
          'vendorId': uid,
          'name': s['name'] ?? s['title'] ?? '',
          'description': s['desc'] ?? '',
          'price': s['price']?.toString().replaceAll('₹', '') ?? '0',
          'discountPrice': s['price']?.toString().replaceAll('₹', '') ?? '0',
          'duration': s['duration'] ?? '30 Mins',
          'unit': 'job',
          'images': [],
          'materialsIncluded': 'Yes',
          'faqs': [],
          'status': 'Enabled',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      setState(() {
        _submittedRequestId = serviceRef.id;
        _serviceStatus = "Pending Review";
        _isSubmitting = false;
      });
      if (mounted) AppSnackbar.show(context, "✅ Service submitted for Admin Review!");
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) AppSnackbar.show(context, "Error submitting: $e", isError: true);
    }
  }

  Color _getStatusBgColor() {
    switch (_serviceStatus) {
      case "Approved": return const Color(0xFFDCFCE7);
      case "Rejected": return const Color(0xFFFEE2E2);
      case "Pending Review": return const Color(0xFFFEF3C7);
      default: return const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusBorderColor() {
    switch (_serviceStatus) {
      case "Approved": return const Color(0xFF10B981);
      case "Rejected": return const Color(0xFFEF4444);
      case "Pending Review": return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  void _showAddSubServiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Sub Service"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _subNameController, decoration: const InputDecoration(labelText: "Sub Service Name")),
                TextField(controller: _subPriceController, decoration: const InputDecoration(labelText: "Price (₹)")),
                TextField(controller: _subDurationController, decoration: const InputDecoration(labelText: "Duration (mins)")),
                TextField(controller: _subDescController, decoration: const InputDecoration(labelText: "Short Description")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (_subNameController.text.trim().isEmpty) return;
                setState(() {
                  _wizardSubServices.add({
                    "name": _subNameController.text,
                    "price": _subPriceController.text,
                    "duration": _subDurationController.text,
                    "desc": _subDescController.text,
                  });
                  _subNameController.clear();
                  _subPriceController.clear();
                  _subDurationController.clear();
                  _subDescController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showAddAddonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Add-on"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _addOnNameController, decoration: const InputDecoration(labelText: "Add-on Name")),
              TextField(controller: _addOnPriceController, decoration: const InputDecoration(labelText: "Price (₹)")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (_addOnNameController.text.trim().isEmpty) return;
                setState(() {
                  _wizardAddOns.add({
                    "name": _addOnNameController.text,
                    "price": _addOnPriceController.text,
                  });
                  _addOnNameController.clear();
                  _addOnPriceController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showAddFAQDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add FAQ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _faqQController, decoration: const InputDecoration(labelText: "Question")),
              TextField(controller: _faqAController, decoration: const InputDecoration(labelText: "Answer")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (_faqQController.text.trim().isEmpty) return;
                setState(() {
                  _wizardFAQs.add({
                    "q": _faqQController.text,
                    "a": _faqAController.text,
                  });
                  _faqQController.clear();
                  _faqAController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    // Draw gradient fill
    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      points.add(Offset(x, y));
    }

    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth cubic bezier
      final prev = points[i - 1];
      final curr = points[i];
      final ctrlX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw endpoint dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points.last, 3.5, dotPaint);
    canvas.drawCircle(points.last, 3.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data || old.color != color;
}
