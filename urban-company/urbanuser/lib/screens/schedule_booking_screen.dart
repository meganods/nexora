import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urbanuser/widgets/app_snackbar.dart';
import '../models/service_model.dart';
import 'address_setup_screen.dart';
import 'payment_screen.dart';

class ScheduleBookingScreen extends StatefulWidget {
  final ServiceModel service;
  final List<Map<String, dynamic>> selectedItems;
  final double totalPrice;

  const ScheduleBookingScreen({
    super.key,
    required this.service,
    required this.selectedItems,
    required this.totalPrice,
  });

  @override
  State<ScheduleBookingScreen> createState() => _ScheduleBookingScreenState();
}

class _ScheduleBookingScreenState extends State<ScheduleBookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Default tomorrow
  String _selectedTimeSlot = "10:00 AM";
  
  
  String _userRealAddress = '';
  String _userAddressType = 'Home';
  String _userName = '';
  String _userPhone = '';
  
  bool _useWallet = false;
  final double _walletBalance = 150.0;
  double _couponDiscount = 0.0;
  String? _appliedCouponCode;

  final TextEditingController _notesController = TextEditingController();
  final List<String> _quickNotes = [
    "Call before arrival",
    "Bring Ladder",
    "Ring Bell",
    "Pet at home",
  ];
  final Set<String> _selectedQuickNotes = {};

  final double _platformFee = 29.0;
  final double _gstTaxes = 52.0;

  double get _calculatedFinalTotal {
    double total = widget.totalPrice + _platformFee + _gstTaxes - _couponDiscount;
    if (_useWallet) {
      total -= _walletBalance;
    }
    return total < 0 ? 0 : total;
  }

  @override
  void initState() {
    super.initState();
    _loadRealUserAddress();
  }

  Future<void> _loadRealUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    String addr = prefs.getString('userAddress') ?? prefs.getString('saved_address') ?? '';
    String type = prefs.getString('userAddressType') ?? 'Home';
    String name = prefs.getString('userName') ?? '';
    String phone = prefs.getString('userMobile') ?? prefs.getString('userPhone') ?? '';

    if (addr.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      final email = prefs.getString('userEmail') ?? user?.email;
      if (email != null && email.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            addr = data['userAddress'] ?? data['address'] ?? '';
            type = data['userAddressType'] ?? 'Home';
            name = data['name'] ?? '';
            phone = data['phone'] ?? '';
          }
        } catch (e) {
          debugPrint("Note fetching user address: $e");
        }
      }
    }

    if (mounted) {
      setState(() {
        _userRealAddress = addr;
        _userAddressType = type.isNotEmpty ? type : 'Home';
        _userName = name;
        _userPhone = phone;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCalendarDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickCustomTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formattedTime = "${hour.toString().padLeft(2, '0')}:$minute $period";
      setState(() {
        _selectedTimeSlot = formattedTime;
      });
    }
  }

  String _formatDateShort(DateTime dt) {
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return "Today, ${dt.day} ${months[dt.month - 1]}";
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day) {
      return "Tomorrow, ${dt.day} ${months[dt.month - 1]}";
    }

    return "${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Schedule Your Service",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendarDateSection(),
                  const SizedBox(height: 20),
                  _buildTimeSlotSection(),
                  const SizedBox(height: 20),
                  _buildAddressSection(),
                  const SizedBox(height: 20),
                  _buildAdditionalNotesSection(),
                  const SizedBox(height: 20),
                  _buildCouponAndWalletSection(),
                  const SizedBox(height: 20),
                  _buildPriceSummarySection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActionBar(context),
    );
  }

  Widget _buildCalendarDateSection() {
    // Generate next 7 days for quick strip
    final List<DateTime> daysStrip = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text("Select Service Date", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                ],
              ),
              GestureDetector(
                onTap: _pickCalendarDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6), size: 12),
                      const SizedBox(width: 4),
                      Text("Full Calendar", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Horizontal date strip with fixed height 72px (avoids RenderFlex overflow)
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: daysStrip.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final dt = daysStrip[index];
                final isSelected = dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
                final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                final weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

                String label = weekdays[dt.weekday - 1];
                final now = DateTime.now();
                if (dt.year == now.year && dt.month == now.month && dt.day == now.day) label = "Today";
                final tom = now.add(const Duration(days: 1));
                if (dt.year == tom.year && dt.month == tom.month && dt.day == tom.day) label = "Tomorrow";

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = dt;
                    });
                  },
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${dt.day} ${months[dt.month - 1]}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, color: Color(0xFF3B82F6), size: 16),
                const SizedBox(width: 8),
                Text(
                  "Selected Date: ${_formatDateShort(_selectedDate)}",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text("Select Custom Time", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickCustomTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                    child: const Icon(Icons.watch_later_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Selected Arrival Time", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          _selectedTimeSlot,
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text("Change Time", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Text("Service Address", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSetupScreen()));
                  _loadRealUserAddress();
                },
                child: Text(
                  _userRealAddress.isNotEmpty ? "+ Change Address" : "+ Add Address",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_userRealAddress.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _userAddressType.toLowerCase().contains('work') ? Icons.business_rounded : Icons.home_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E40AF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _userAddressType.toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            if (_userName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                _userName,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userRealAddress,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155), height: 1.3),
                        ),
                        if (_userPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Mobile: $_userPhone",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6), size: 22),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSetupScreen()));
                _loadRealUserAddress();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_location_alt_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("No Address Saved", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF92400E))),
                          Text("Tap here to add your home or work address for service delivery", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB45309))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalNotesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_alt_rounded, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text("Additional Instructions", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickNotes.map((note) {
              final isSel = _selectedQuickNotes.contains(note);
              return FilterChip(
                label: Text(note, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? Colors.white : const Color(0xFF334155))),
                selected: isSel,
                selectedColor: const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFFF1F5F9),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedQuickNotes.add(note);
                    } else {
                      _selectedQuickNotes.remove(note);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Add specific instructions for professional...",
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponAndWalletSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Offers & Wallet", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              GestureDetector(
                onTap: _showCouponsBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_rounded, color: Color(0xFF3B82F6), size: 12),
                      const SizedBox(width: 4),
                      Text("View Coupons", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showCouponsBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _appliedCouponCode != null ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _appliedCouponCode != null ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _appliedCouponCode != null ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appliedCouponCode != null ? "Coupon '$_appliedCouponCode' Applied" : "Apply Coupon / Promo Code",
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: _appliedCouponCode != null ? const Color(0xFF065F46) : const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _appliedCouponCode != null ? "You save ₹${_couponDiscount.toStringAsFixed(0)} on this service!" : "Explore Admin & Vendor discount coupons",
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (_appliedCouponCode != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _appliedCouponCode = null;
                          _couponDiscount = 0.0;
                        });
                        AppSnackbar.show(context, "Coupon Removed");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                        child: Text("Remove", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                      child: Text("Apply", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("NEXORA Wallet", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                      Text("Balance: ₹${_walletBalance.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _useWallet,
                activeTrackColor: const Color(0xFF3B82F6),
                onChanged: (val) {
                  setState(() {
                    _useWallet = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCouponsBottomSheet() {
    final TextEditingController inputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_rounded, color: Color(0xFF3B82F6), size: 22),
                          const SizedBox(width: 8),
                          Text("Coupons & Promo Codes", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Custom Promo Input Box
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputController,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: "Enter Coupon Code (e.g. WELCOME100)",
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final typedCode = inputController.text.trim().toUpperCase();
                          if (typedCode.isEmpty) return;

                          // Search firestore collections for coupon with matching code
                          final qSnapshot = await FirebaseFirestore.instance
                              .collection('coupons')
                              .where('status', isEqualTo: true)
                              .get();
                          
                          Map<String, dynamic>? match;
                          for (var doc in qSnapshot.docs) {
                            final data = doc.data();
                            if ((data['code'] ?? '').toString().toUpperCase() == typedCode) {
                              match = data;
                              match['id'] = doc.id;
                              break;
                            }
                          }

                          if (match != null) {
                            final double minOrder = ((match['minimumOrder'] ?? match['minOrder'] ?? 0.0) as num).toDouble();
                            if (widget.totalPrice < minOrder) {
                              if (context.mounted) {
                                AppSnackbar.show(context, "Minimum order of ₹${minOrder.toStringAsFixed(0)} required for this coupon!", isError: true);
                              }
                              return;
                            }

                            final double discountValue = (match['discountValue'] ?? 0.0) as double;
                            setState(() {
                              _appliedCouponCode = match!['code'] as String;
                              _couponDiscount = discountValue;
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              AppSnackbar.show(context, "Coupon '$typedCode' Applied (-₹${_couponDiscount.toStringAsFixed(0)})");
                            }
                          } else {
                            if (context.mounted) {
                              AppSnackbar.show(context, "Invalid Coupon Code", isError: true);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)),
                          child: Text("APPLY", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text("AVAILABLE COUPONS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 1.0)),
                  const SizedBox(height: 12),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('coupon_redemptions')
                          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? 'guest_user')
                          .snapshots(),
                      builder: (ctx1, redemptionsSnap) {
                        final redemptionDocs = redemptionsSnap.data?.docs ?? [];
                        final Map<String, int> userUsageMap = {};
                        for (var doc in redemptionDocs) {
                          final code = (doc.data() as Map<String, dynamic>)['couponCode'] as String?;
                          if (code != null) {
                            userUsageMap[code] = (userUsageMap[code] ?? 0) + 1;
                          }
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('coupons')
                              .where('status', isEqualTo: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final now = DateTime.now();
                            final List<Map<String, dynamic>> activeCoupons = [];

                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final code = data['code'] ?? doc.id;

                                DateTime? startDate;
                                DateTime? endDate;
                                if (data['startDate'] != null) {
                                  startDate = (data['startDate'] as Timestamp).toDate();
                                }
                                if (data['endDate'] != null) {
                                  endDate = (data['endDate'] as Timestamp).toDate();
                                }

                                // Filter active date ranges
                                if (startDate != null && startDate.isAfter(now)) continue;
                                if (endDate != null && endDate.isBefore(now)) continue;

                                // Limits validation
                                final totalUsed = data['totalUsed'] ?? 0;
                                final usageLimit = data['usageLimit'] ?? 999999;
                                final usagePerUser = data['usagePerUser'] ?? 999999;
                                final userUsed = userUsageMap[code] ?? 0;

                                if (totalUsed >= usageLimit) continue;
                                if (userUsed >= usagePerUser) continue;

                                activeCoupons.add({
                                  "code": code,
                                  "title": data['title'] ?? "Special Platform Coupon",
                                  "discount": ((data['discountValue'] ?? 0.0) as num).toDouble(),
                                  "type": data['vendorId'] != null ? "Vendor" : "Admin",
                                  "provider": data['vendorName'] ?? "NEXORA Official",
                                  "minOrder": ((data['minimumOrder'] ?? data['minOrder'] ?? 0.0) as num).toDouble(),
                                  "desc": data['description'] ?? "Instant discount offer.",
                                  "expiry": endDate != null ? "Valid till ${DateFormat('dd MMM').format(endDate)}" : "Limited Period",
                                  "badgeColor": data['vendorId'] != null ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                                });
                              }
                            }

                            if (activeCoupons.isEmpty) {
                              return Center(
                                child: Text(
                                  "No coupons currently available.",
                                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                ),
                              );
                            }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: activeCoupons.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 0, height: 12),
                          itemBuilder: (context, index) {
                            final coupon = activeCoupons[index];
                            final isCurrentApplied = _appliedCouponCode == coupon["code"];
                            final isVendor = coupon["type"] == "Vendor";

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrentApplied ? const Color(0xFFECFDF5) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isCurrentApplied ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Code Tag Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (coupon["badgeColor"] as Color).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: (coupon["badgeColor"] as Color).withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.local_offer_rounded, size: 12, color: coupon["badgeColor"] as Color),
                                            const SizedBox(width: 4),
                                            Text(coupon["code"] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: coupon["badgeColor"] as Color)),
                                          ],
                                        ),
                                      ),
                                      // Provider Type Chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isVendor ? const Color(0xFFF3E8FF) : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isVendor ? "VENDOR EXCLUSIVE" : "ADMIN PLATFORM",
                                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: isVendor ? const Color(0xFF7C3AED) : const Color(0xFF2563EB)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(coupon["title"] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                                  const SizedBox(height: 2),
                                  Text(coupon["desc"] as String, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(coupon["provider"] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                                      GestureDetector(
                                        onTap: () {
                                          if (isCurrentApplied) {
                                            setState(() {
                                              _appliedCouponCode = null;
                                              _couponDiscount = 0.0;
                                            });
                                            Navigator.pop(context);
                                            AppSnackbar.show(context, "Coupon Removed");
                                          } else {
                                            final double minOrder = (coupon["minOrder"] as num).toDouble();
                                            if (widget.totalPrice < minOrder) {
                                              AppSnackbar.show(context, "Minimum order of ₹${minOrder.toStringAsFixed(0)} required for this coupon!", isError: true);
                                              return;
                                            }
                                            setState(() {
                                              _appliedCouponCode = coupon["code"] as String;
                                              _couponDiscount = (coupon["discount"] as num).toDouble();
                                            });
                                            Navigator.pop(context);
                                            AppSnackbar.show(context, "Coupon '${coupon['code']}' Applied (-₹${_couponDiscount.toStringAsFixed(0)})");
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isCurrentApplied ? const Color(0xFFFEE2E2) : const Color(0xFF3B82F6),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isCurrentApplied ? "REMOVE" : "APPLY",
                                            style: GoogleFonts.inter(color: isCurrentApplied ? const Color(0xFFEF4444) : Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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
  },
);
}

  Widget _buildPriceSummarySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Price Summary", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ...widget.selectedItems.map((item) => _priceRow(item["name"] as String, "₹${(item["price"] as double).toStringAsFixed(0)}")),
          _priceRow("Platform Fee", "₹${_platformFee.toStringAsFixed(0)}"),
          _priceRow("Taxes & GST", "₹${_gstTaxes.toStringAsFixed(0)}"),
          if (_couponDiscount > 0) _priceRow("Coupon Discount", "-₹${_couponDiscount.toStringAsFixed(0)}", isDiscount: true),
          if (_useWallet) _priceRow("Wallet Credit Used", "-₹${_walletBalance.toStringAsFixed(0)}", isDiscount: true),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Payable Amount", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              Text(
                "₹${_calculatedFinalTotal.toStringAsFixed(0)}",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF64748B)))),
          Text(amount, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final finalAmount = _calculatedFinalTotal;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Final Amount", style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
              Text("₹${finalAmount.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final dateStr = _formatDateShort(_selectedDate);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      totalAmount: finalAmount,
                      coupon: _appliedCouponCode != null ? {"code": _appliedCouponCode, "discount": _couponDiscount} : null,
                      shopName: widget.service.title,
                      date: dateStr,
                      time: _selectedTimeSlot,
                      selectedItems: widget.selectedItems,
                      vendorId: widget.service.vendorId.isNotEmpty ? widget.service.vendorId : "v_101",
                      imageUrl: widget.service.image,
                    ),
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Continue To Payment", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
