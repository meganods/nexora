import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text("All Bookings", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
          bottom: TabBar(unselectedLabelColor: Colors.grey, labelColor: AppTheme.primaryColor, indicatorColor: AppTheme.primaryColor, tabs: const [Tab(text: "Active"), Tab(text: "Completed"), Tab(text: "Cancelled")]),
        ),
        body: TabBarView(
          children: [
            _buildBookingList("New Orders", true),
            _buildBookingList("Finished Tasks", false),
            _buildBookingList("Cancelled Tasks", false),
          ],
        ),
        bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
      ),
    );
  }

  Widget _buildBookingList(String title, bool isNew) {
    final list = [
      {"id": "#UC-882201", "service": "House Cleaning", "user": "Alex Jordan", "time": "10:00 AM", "date": "12 Oct"},
      {"id": "#UC-882202", "service": "AC Repair", "user": "Sara Smith", "time": "12:30 PM", "date": "14 Oct"},
      {"id": "#UC-882203", "service": "Salon", "user": "Zoe Doe", "time": "02:00 PM", "date": "15 Oct"},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(25),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final b = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[100]!), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(b["id"]!, style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  if (isNew) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(5)), child: Text("NEW", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 15),
              Text(b["service"]!, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
              const SizedBox(height: 4),
              Text(b["user"]!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(b["time"]!, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
                  Row(children: [const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(b["date"]!, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
