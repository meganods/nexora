import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)), title: Text("Booking #UC-882201", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 30),
            _buildServiceInfo(),
            const SizedBox(height: 30),
            _buildCustomerInfo(),
            const SizedBox(height: 30),
            _buildPricingSummary(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildActionButtons(context),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Confirmed", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                Text("Service scheduled for today", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.share_outlined, color: Colors.grey, size: 20)),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SERVICE DETAILS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey[100]!)),
          child: Column(
            children: [
              _detailRow(Icons.home_repair_service_outlined, "Deep Home Cleaning", "2 BHK Full Sanitization"),
              const Divider(height: 40),
              _detailRow(Icons.access_time, "10:00 AM - 02:00 PM", "Today, 12 Oct"),
              const Divider(height: 40),
              _detailRow(Icons.location_on_outlined, "Sector 45, Gurgaon", "Flat 402, Bloom Heights"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CUSTOMER INFO", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey[100]!)),
          child: Row(
            children: [
              const CircleAvatar(radius: 25, backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=alex")),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Alex Jordan", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("+91 999 888 7777", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () {}),
              IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue), onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PRICING SUMMARY", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey[100]!)),
          child: Column(
            children: [
              _priceRow("Base Price", "₹1,200", false),
              const SizedBox(height: 15),
              _priceRow("Extra Sanitization", "₹150", false),
              const SizedBox(height: 15),
              _priceRow("Convenience Fee", "₹49", false),
              const Divider(height: 40),
              _priceRow("Total Earnings", "₹1,399", true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: AppTheme.primaryColor, size: 20)),
        const SizedBox(width: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)), Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12))]),
      ],
    );
  }

  Widget _priceRow(String label, String val, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? AppTheme.accentColor : Colors.grey[500], fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(val, style: GoogleFonts.outfit(color: isBold ? AppTheme.primaryColor : AppTheme.accentColor, fontSize: isBold ? 20 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[100]!))),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: Text("START SERVICE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }
}
