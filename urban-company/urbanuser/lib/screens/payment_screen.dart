import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/thank_you_screen.dart';
import '../widgets/step_progress_indicator.dart';
import '../services/smart_assignment_service.dart';

class PaymentScreen extends StatefulWidget {
  final double? totalAmount;
  final Map<String, dynamic>? coupon;
  final String? shopName;
  final String? date;
  final String? time;
  final List<Map<String, dynamic>>? selectedItems;
  final String? vendorId;
  final String? imageUrl;

  const PaymentScreen({
    super.key, 
    this.totalAmount, 
    this.coupon,
    this.shopName,
    this.date,
    this.time,
    this.selectedItems,
    this.vendorId,
    this.imageUrl,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPayment = "Credit / Debit Card";
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    double total = widget.totalAmount ?? 1299.0;

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
          "Payment",
          style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("PAYMENT METHOD"),
                  _buildPaymentSelection(),
                  const SizedBox(height: 20),
                  _buildOrderSummary(total),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildPayNowButton(total),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 1.2)),
    );
  }

  Widget _buildPaymentSelection() {
    return Column(
      children: [
        _paymentCard("Credit / Debit Card", "Ends in 4242", Icons.credit_card_rounded),
        _paymentCard("Google Pay", "Instant pay via UPI", Icons.account_balance_wallet_rounded),
        _paymentCard("PhonePe / Paytm", "UPI & Wallets", Icons.account_balance_rounded),
      ],
    );
  }

  Widget _paymentCard(String title, String subtitle, IconData icon) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.1) : const Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B))),
                  Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ORDER SUMMARY", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Amount Payable", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                Text("₹${total.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: GestureDetector(
        onTap: _isSubmitting ? null : () async {
          setState(() => _isSubmitting = true);

          final user = FirebaseAuth.instance.currentUser;
          final String bookingId = "UC-${100000 + DateTime.now().millisecond + DateTime.now().second * 1000}";
                  // Smart Vendor Assignment calculation
          String assignedVendorId = widget.vendorId ?? 'vendor_01';
          String assignedShopName = widget.shopName ?? 'Urban Service Pro';
          String bookingStatus = 'pending';
          String timelineTitle = 'Booking Placed';
          String timelineDesc = 'Your service booking has been created successfully. Awaiting vendor/technician assignment.';

          try {
            final firstService = (widget.selectedItems != null && widget.selectedItems!.isNotEmpty)
                ? widget.selectedItems!.first['name'].toString()
                : '';
            String category = 'Cleaning';
            if (firstService.toLowerCase().contains('plumb') || firstService.toLowerCase().contains('leak')) {
              category = 'Plumber';
            } else if (firstService.toLowerCase().contains('paint')) {
              category = 'Painter';
            } else if (firstService.toLowerCase().contains('electric') || firstService.toLowerCase().contains('wire')) {
              category = 'Electrician';
            } else if (firstService.toLowerCase().contains('salon') || firstService.toLowerCase().contains('spa')) {
              category = 'Salon';
            }

            final bestVendor = await SmartAssignmentService.assignBestVendor(
              categoryName: category,
              userCity: 'Mumbai',
              bookingPrice: total,
            );

            if (bestVendor != null) {
              assignedVendorId = bestVendor['id'];
              assignedShopName = bestVendor['businessName'] ?? bestVendor['name'] ?? 'Urban Service Pro';
              bookingStatus = 'assigned';
              timelineTitle = 'Vendor Assigned';
              timelineDesc = 'System automatically assigned your booking to $assignedShopName.';
            }
          } catch (e) {
            debugPrint("Smart assignment failed: $e");
          }

          try {
            await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
              'id': bookingId,
              'userId': user?.uid ?? 'guest_user',
              'userEmail': user?.email ?? 'guest@nexora.com',
              'shopName': assignedShopName,
              'price': '₹${total.toStringAsFixed(0)}',
              'date': widget.date ?? 'Today',
              'time': widget.time ?? '10:00 AM',
              'paymentMethod': selectedPayment,
              'status': bookingStatus,
              'createdAt': FieldValue.serverTimestamp(),
              'services': widget.selectedItems ?? [],
              'vendorId': assignedVendorId,
              'imageUrl': widget.imageUrl ?? '',
              if (bookingStatus == 'assigned') 'assignedAt': FieldValue.serverTimestamp(),
            }).timeout(const Duration(seconds: 2));

             // Record coupon usage
            if (widget.coupon != null && widget.coupon!['code'] != null) {
              final couponCode = widget.coupon!['code'];
              await FirebaseFirestore.instance.collection('coupon_redemptions').add({
                'couponCode': couponCode,
                'userId': user?.uid ?? 'guest_user',
                'userEmail': user?.email ?? 'guest@nexora.com',
                'bookingId': bookingId,
                'discountAmount': widget.coupon!['discount'] ?? 0.0,
                'timestamp': FieldValue.serverTimestamp(),
              });

              final cQuery = await FirebaseFirestore.instance
                  .collection('coupons')
                  .where('code', isEqualTo: couponCode)
                  .get();
              if (cQuery.docs.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('coupons')
                    .doc(cQuery.docs.first.id)
                    .update({'totalUsed': FieldValue.increment(1)});
              }
            }

            // Write Payment Record
            final String paymentId = "PM-${100000 + DateTime.now().millisecond + DateTime.now().second * 1000}";
            await FirebaseFirestore.instance.collection('payments').doc(paymentId).set({
              'paymentId': paymentId,
              'bookingId': bookingId,
              'userId': user?.uid ?? 'guest_user',
              'vendorId': assignedVendorId,
              'amount': total,
              'paymentMethod': selectedPayment,
              'status': 'success',
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Write Booking Timeline Record
            final String timelineId = "TL-${bookingId}";
            await FirebaseFirestore.instance.collection('booking_timeline').doc(timelineId).set({
              'timelineId': timelineId,
              'bookingId': bookingId,
              'status': bookingStatus,
              'title': timelineTitle,
              'description': timelineDesc,
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Write Notification for Admin (full booking details)
            await FirebaseFirestore.instance.collection('notifications').add({
              'title': 'New Booking Request',
              'body': 'Booking ${bookingId} placed for ${assignedShopName} on ${widget.date ?? "Today"} at ${widget.time ?? "10:00 AM"}. Total: ₹${total.toStringAsFixed(0)} via $selectedPayment.',
              'userId': 'admin',
              'type': 'booking',
              'bookingId': bookingId,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
              // Full admin details
              'details': {
                'bookingId': bookingId,
                'shopName': assignedShopName,
                'vendorId': assignedVendorId,
                'userEmail': user?.email ?? 'guest@nexora.com',
                'date': widget.date ?? 'Today',
                'time': widget.time ?? '10:00 AM',
                'amount': total,
                'paymentMethod': selectedPayment,
                'paymentStatus': 'paid',
                'status': bookingStatus,
                'services': widget.selectedItems?.map((s) => s['name']).toList() ?? [],
              },
            });

            // Write Notification for Vendor (service info only — NO price, NO payment)
            await FirebaseFirestore.instance.collection('notifications').add({
              'title': 'New Service Request',
              'body': 'You have a new booking for ${(widget.selectedItems?.isNotEmpty == true) ? widget.selectedItems!.first["name"] ?? assignedShopName : assignedShopName} on ${widget.date ?? "Today"} at ${widget.time ?? "10:00 AM"}.',
              'userId': assignedVendorId,
              'type': 'booking',
              'bookingId': bookingId,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
              // Vendor sees service info only — no price/payment
              'details': {
                'bookingId': bookingId,
                'date': widget.date ?? 'Today',
                'time': widget.time ?? '10:00 AM',
                'services': widget.selectedItems?.map((s) => s['name']).toList() ?? [],
                'status': bookingStatus,
              },
            });

            // Write Notification for User
            await FirebaseFirestore.instance.collection('notifications').add({
              'title': 'Booking Confirmed',
              'body': 'Your booking (${bookingId}) for ${assignedShopName} has been successfully placed!',
              'userId': user?.uid ?? 'guest_user',
              'type': 'booking',
              'bookingId': bookingId,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint("Firestore booking write (handled smoothly): $e");
          }

          if (mounted) {
            setState(() => _isSubmitting = false);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ThankYouScreen()));
          }
        },
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "PAY ₹${total.toStringAsFixed(0)}",
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
