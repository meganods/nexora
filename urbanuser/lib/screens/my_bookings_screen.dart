import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import 'booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor), onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard')),
        title: Text("My Bookings", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: AppTheme.primaryColor, unselectedLabelColor: Colors.grey, indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: "Upcoming"), Tab(text: "Completed"), Tab(text: "Cancelled")],
            ),
            Expanded(
              child: TabBarView(
                children: [
                   _buildBookingList("UPCOMING"),
                   _buildBookingList("COMPLETED"),
                   _buildBookingList("CANCELLED"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
    );
  }

  Widget _buildBookingList(String status) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: status == "UPCOMING" ? 1 : 0,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey[100]!), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset("assets/images/banner1.png", width: 60, height: 60, fit: BoxFit.cover)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Urban Barber Shop", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Ref #UC-882201", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      const SizedBox(height: 5),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: status == "UPCOMING" ? Colors.blue[50] : Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: status == "UPCOMING" ? Colors.blue : Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.calendar_month, color: Colors.grey, size: 16), const SizedBox(width: 8), Text("Mon, Oct 12", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold))]),
                Row(children: [const Icon(Icons.access_time, color: Colors.grey, size: 16), const SizedBox(width: 8), Text("10:00 AM", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold))]),
              ],
            ),
             const SizedBox(height: 20),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailScreen(booking: {"id": "#UC-882201"}))),
                 style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                 child: Text("VIEW DETAILS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ),
          ],
        ),
      ),
    );
  }

}
