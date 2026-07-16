import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isCancelled = false;

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
            onPressed: () {
              setState(() => _isCancelled = true);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(const SnackBar(content: Text("Booking Cancelled Successfully"), backgroundColor: Colors.red));
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
          Text(_isCancelled ? "Booking Cancelled" : "Scheduled For Mon, Oct 12", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: _isCancelled ? Colors.red : Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildServiceImage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 800),
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: const DecorationImage(
            image: AssetImage("assets/images/banner1.png"),
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
          Text("Urban Barber Shop", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
          const SizedBox(height: 8),
          Text("Ref ID: #UC-882201", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItemizedServices() {
    final services = [
      {"name": "Standard Haircut", "price": "₹499", "img": "assets/images/banner1.png"},
      {"name": "Beard Grooming", "price": "₹299", "img": "assets/images/house_cleaning_demo_1774854111518.png"},
      {"name": "Face Massage", "price": "₹599", "img": "assets/images/kitchen_cleaning_demo_1774854091381.png"},
      {"name": "L'Oreal Spa", "price": "₹1,299", "img": "assets/images/car_wash_banner_illustration_1774854072344.png"},
    ];
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Services Booked", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          ...services.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(s["img"]!, width: 50, height: 50, fit: BoxFit.cover)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s["name"]!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("Includes preparation & post-service cleanup", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(s["price"]!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
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
          _buildInfoItem(Icons.calendar_month_outlined, "Date", "Mon, Oct 12"),
          const Spacer(),
          _buildInfoItem(Icons.access_time_outlined, "Time", "10:00 AM"),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: _buildInfoItem(Icons.location_on_outlined, "Location", "1749 Chaudhray Dhaba Delhi, Indirapuram"),
    );
  }

  Widget _buildPricingSection() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Billing Summary", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          _priceRow("Item Total", "₹2,696"),
          _priceRow("Taxes", "₹22"),
          _priceRow("Service Fee", "₹49"),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Paid", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("₹2,767", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
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
