import 'package:urbanuser/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/invoice_service.dart';
import '../widgets/app_toast.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isCancelled = false;
  String _address = "Indirapuram, Ghaziabad";
  double _userRating = 5;
  final _reviewController = TextEditingController();
  bool _hasSubmittedReview = false;
  bool _isCheckingReview = true;
  bool _isDownloadingInvoice = false;

  @override
  void initState() {
    super.initState();
    _isCancelled = widget.booking['status'] == 'CANCELLED';
    _loadAddress();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    final String bookingId = widget.booking['id'] ?? '';
    if (bookingId.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        setState(() {
          _hasSubmittedReview = true;
          _isCheckingReview = false;
        });
        return;
      }
    }
    setState(() {
      _isCheckingReview = false;
    });
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('userAddress') ?? prefs.getString('userAddressStreet') ?? '';
    if (savedAddress.isNotEmpty) {
      setState(() {
        _address = savedAddress;
      });
    }
  }

  /// Downloads a real-time PDF invoice for this booking
  Future<void> _downloadInvoice() async {
    if (_isDownloadingInvoice) return;
    setState(() => _isDownloadingInvoice = true);

    // Merge saved address into booking data for the invoice
    final bookingData = Map<String, dynamic>.from(widget.booking);
    bookingData['userAddress'] = _address;

    // Try to get fresh data from Firestore
    final String bookingId = widget.booking['id'] ?? '';
    if (bookingId.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
        if (snap.exists && snap.data() != null) {
          bookingData.addAll(snap.data()!);
        }
      } catch (_) {}
    }

    try {
      await InvoiceService.downloadInvoice(
        context: context,
        booking: bookingData,
      );
      if (mounted) {
        AppToast.show(
          context,
          title: '✅ Invoice Downloaded',
          message: 'Invoice for ${bookingData['shopName'] ?? 'your booking'} saved successfully!',
          icon: Icons.picture_as_pdf_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: '❌ Download Failed',
          message: 'Could not generate invoice. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingInvoice = false);
    }
  }

  void _confirmCancellation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Booking?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to cancel this booking? This action cannot be undone.", style: GoogleFonts.outfit(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("NO", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () async {
              setState(() => _isCancelled = true);
              final String bookingId = widget.booking['id'] ?? '';
              if (bookingId.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                    'status': 'cancelled',
                  });
                } catch (e) {
                  debugPrint("Error cancelling booking in database: $e");
                }
              }
              if (mounted) {
                AppSnackbar.show(context, "Booking Cancelled Successfully", isError: true);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
              }
            },
            child: Text("YES, CANCEL", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text('Contact Support', style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(context);
                  AppSnackbar.show(context, 'Support feature coming soon');
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: Text('Report Issue', style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(context);
                  AppSnackbar.show(context, 'Report issue feature coming soon');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        title: Text("Booking Info", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
        actions: [
          if (!_isCancelled) IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: _showMoreOptions),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<DocumentSnapshot>(
            stream: (widget.booking['id'] ?? '').isNotEmpty
                ? FirebaseFirestore.instance.collection('bookings').doc(widget.booking['id']).snapshots()
                : const Stream.empty(),
            builder: (context, liveSnap) {
              final liveData = liveSnap.data?.data() as Map<String, dynamic>? ?? widget.booking;
              final liveStatus = (liveData['status'] ?? widget.booking['status'] ?? '').toString().toLowerCase();
              final showOtp = liveStatus == 'arrived' || liveStatus == 'en_route';
              final showReview = liveStatus == 'completed' || liveStatus == 'waiting_for_verification';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(),
                    _buildLiveProgressTimeline(widget.booking['id'] ?? ''),
                    if (showOtp) _buildOtpCard(widget.booking['id'] ?? '', liveData),
                    if (showReview) _buildCustomerReviewCard(widget.booking['id'] ?? '', liveData['vendorId'] ?? widget.booking['vendorId'] ?? 'vendor_01'),
                    _buildServiceImage(),
                    _buildShopInfo(),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
                    _buildItemizedServices(),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
                    _buildDateTimeInfo(),
                    _buildLocationInfo(),
                    _buildPricingSection(),
                    _buildDownloadInvoiceButton(),
                    const SizedBox(height: 20),
                    if (!_isCancelled) _buildCancelButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      color: _isCancelled ? Colors.red[50] : const Color(0xFFE3F2FD),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        children: [
          Icon(_isCancelled ? Icons.cancel : Icons.calendar_today, color: _isCancelled ? Colors.red : Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(_isCancelled ? "Booking Cancelled" : "Scheduled For ${widget.booking['date'] ?? 'Mon, Oct 12'}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: _isCancelled ? Colors.red : Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildServiceImage() {
    final services = widget.booking['services'] as List<dynamic>? ?? [];
    final rawImg = services.isNotEmpty ? (services[0]['img'] ?? services[0]['image'] ?? widget.booking['imageUrl']) : widget.booking['imageUrl'];
    final firstImg = rawImg ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop';
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 800),
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: DecorationImage(
            image: firstImg.toString().startsWith("assets") 
                ? AssetImage(firstImg) as ImageProvider 
                : NetworkImage(firstImg),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildShopInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.booking['shopName'] ?? "Urban Barber Shop", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
          const SizedBox(height: 8),
          Text("Ref ID: #${widget.booking['id'] ?? 'UC-882201'}", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItemizedServices() {
    final List<dynamic> services = widget.booking['services'] as List<dynamic>? ?? [];
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Services Booked", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          if (services.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network("https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=120&auto=format&fit=crop", width: 50, height: 50, fit: BoxFit.cover)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.booking['shopName'] ?? "Urban Service", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Includes preparation & post-service cleanup", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(widget.booking['price'] ?? "₹1,299", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                ],
              ),
            )
          else
            ...services.map((s) {
              final sImg = s["img"] ?? s["image"] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=120&auto=format&fit=crop';
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: sImg.toString().startsWith("assets")
                          ? Image.asset(sImg, width: 50, height: 50, fit: BoxFit.cover)
                          : Image.network(sImg, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, st) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.cleaning_services, color: Colors.grey))),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s["name"] ?? s["title"] ?? 'Service Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("Includes preparation & post-service cleanup", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(s["price"].toString().startsWith("₹") ? s["price"].toString() : "₹${s["price"]}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(Icons.calendar_month_outlined, "Date", widget.booking['date'] ?? "Mon, Oct 12"),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildInfoItem(Icons.access_time_outlined, "Time", widget.booking['time'] ?? "10:00 AM"),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: _buildInfoItem(Icons.location_on_outlined, "Location", _address),
    );
  }

  Widget _buildPricingSection() {
    final String totalPaid = widget.booking['price'] ?? '₹1,299';
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Billing Summary", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          _priceRow("Grand Total", totalPaid),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Paid", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(totalPaid, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle), child: Icon(icon, color: Colors.grey, size: 20)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDownloadInvoiceButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: GestureDetector(
        onTap: _isDownloadingInvoice ? null : _downloadInvoice,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _isDownloadingInvoice
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: _isDownloadingInvoice ? const Color(0xFFCBD5E1) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isDownloadingInvoice
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: _isDownloadingInvoice
              ? const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Text('Generating Invoice...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Download Invoice (PDF)',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.download_rounded, color: Colors.white70, size: 16),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton(
          onPressed: _confirmCancellation,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: Text("CANCEL BOOKING", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLiveProgressTimeline(String bookingId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('booking_timeline')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  "Awaiting assignment...",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SERVICE STATUS",
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Updated';
                  final description = data['description'] ?? '';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final timeStr = timestamp != null
                      ? "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                      : '';
                  final isLast = index == docs.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentColor),
                                ),
                                if (timeStr.isNotEmpty)
                                  Text(
                                    timeStr,
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                                  ),
                              ],
                            ),
                            if (description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  description,
                                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Phase 5: Show OTP to customer when vendor has arrived
  Widget _buildOtpCard(String bookingId, Map<String, dynamic> liveData) {
    final String otp = liveData['serviceOtp']?.toString() ?? '';
    if (otp.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Service OTP",
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "Share this code with your vendor to start service",
                      style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              otp.split('').join('  '),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: const Color(0xFF1D4ED8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "⚠️  Do NOT share this OTP with anyone except your assigned vendor.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReviewCard(String bookingId, String vendorId) {

    if (_isCheckingReview) {
      return const Padding(
        padding: EdgeInsets.all(25.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasSubmittedReview) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.green, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                "Thank you for rating this service! Your feedback has been recorded.",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[900]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "RATE & REVIEW YOUR SERVICE",
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                icon: Icon(
                  _userRating >= starValue ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _userRating = starValue.toDouble();
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your review here...",
              hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final double rating = _userRating;
                final String reviewText = _reviewController.text;
                
                await FirebaseFirestore.instance.collection('reviews').add({
                  'bookingId': bookingId,
                  'vendorId': vendorId,
                  'rating': rating,
                  'review': reviewText,
                  'images': [
                    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400'
                  ],
                  'userName': widget.booking['userEmail']?.split('@')?.first ?? 'Customer',
                  'userEmail': widget.booking['userEmail'] ?? 'customer@example.com',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // Update vendor profile
                final vendorDoc = await FirebaseFirestore.instance.collection('vendors').doc(vendorId).get();
                if (vendorDoc.exists) {
                  final vData = vendorDoc.data() ?? {};
                  final double currentRating = (vData['rating'] ?? 5.0).toDouble();
                  final int totalReviews = (vData['totalReviews'] ?? 0).toInt();
                  final int newTotal = totalReviews + 1;
                  final double newRating = ((currentRating * totalReviews) + rating) / newTotal;
                  
                  await FirebaseFirestore.instance.collection('vendors').doc(vendorId).update({
                    'rating': newRating,
                    'totalReviews': newTotal,
                  });
                }

                // Update analytics
                await FirebaseFirestore.instance.collection('analytics').doc('reviews_summary').set({
                  'totalReviewsCount': FieldValue.increment(1),
                }, SetOptions(merge: true));

                // Log timeline event
                await FirebaseFirestore.instance.collection('booking_timeline').add({
                  'bookingId': bookingId,
                  'status': 'review_submitted',
                  'title': 'Feedback Submitted',
                  'description': 'Customer rated the service with $rating stars.',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                setState(() {
                  _hasSubmittedReview = true;
                });

                if (mounted) {
                  AppSnackbar.show(context, "Review submitted successfully!");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                "Submit Review",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
