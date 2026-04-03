import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text("My Customers", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildReviewHeader(),
            _buildCustomerList(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    );
  }

  Widget _buildReviewHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text("Customer Satisfaction", style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("4.9", style: GoogleFonts.outfit(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Text("Based on 1.2k+ reviews", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    final clients = [
      {"name": "Alex Jordan", "orders": "12 Orders", "rating": "5.0", "img": "https://i.pravatar.cc/150?u=alex"},
      {"name": "Sara Smith", "orders": "8 Orders", "rating": "4.8", "img": "https://i.pravatar.cc/150?u=sara"},
      {"name": "Zoe Doe", "orders": "5 Orders", "rating": "4.9", "img": "https://i.pravatar.cc/150?u=zoe"},
      {"name": "Mike Ross", "orders": "3 Orders", "rating": "5.0", "img": "https://i.pravatar.cc/150?u=mike"},
    ];
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TOP REPEAT CLIENTS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
          const SizedBox(height: 25),
          ...clients.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 25),
                child: Row(
                  children: [
                    CircleAvatar(radius: 25, backgroundImage: NetworkImage(c["img"]!)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c["name"]!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.accentColor)),
                          Text(c["orders"]!, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 5), Text(c["rating"]!, style: GoogleFonts.outfit(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 12))])),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
