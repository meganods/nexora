import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isCancelled = false;
  String _address = "Indirapuram, Ghaziabad";

  @override
  void initState() {
    super.initState();
    _isCancelled = widget.booking['status'] == 'CANCELLED';
    _loadAddress();
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
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                messenger.showSnackBar(const SnackBar(content: Text("Booking Cancelled Successfully"), backgroundColor: Colors.red));
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support feature coming soon')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: Text('Report Issue', style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report issue feature coming soon')));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor), onPressed: () => Navigator.pop(context)),
        title: Text("Booking Info", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
        actions: [
          if (!_isCancelled) IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: _showMoreOptions),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(),
                _buildServiceImage(),
                _buildShopInfo(),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
                _buildItemizedServices(),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
                _buildDateTimeInfo(),
                _buildLocationInfo(),
                _buildPricingSection(),
                const SizedBox(height: 40),
                if (!_isCancelled) _buildCancelButton(),
                const SizedBox(height: 40),
              ],
            ),
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
    final firstImg = services.isNotEmpty && services[0]['img'] != null ? services[0]['img'] : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=300&auto=format&fit=crop';
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
            ...services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10), 
                        child: s["img"].toString().startsWith("assets") 
                            ? Image.asset(s["img"]!, width: 50, height: 50, fit: BoxFit.cover) 
                            : Image.network(s["img"]!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, st) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.cleaning_services, color: Colors.grey))),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s["name"] ?? 'Service Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("Includes preparation & post-service cleanup", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(s["price"].toString().startsWith("₹") ? s["price"].toString() : "₹${s["price"]}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        children: [
          _buildInfoItem(Icons.calendar_month_outlined, "Date", widget.booking['date'] ?? "Mon, Oct 12"),
          const Spacer(),
          _buildInfoItem(Icons.access_time_outlined, "Time", widget.booking['time'] ?? "10:00 AM"),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
          ],
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
}
