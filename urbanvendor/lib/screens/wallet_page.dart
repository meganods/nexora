import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text("My Wallet", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBalanceHeader(),
            _buildActionButtons(),
            _buildRecentTransactions(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text("Wallet Balance", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Text("₹12,450.00", style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem("₹45,290", "Total Earning"),
              const SizedBox(width: 30),
              _statItem("₹2,450", "Pending Payout"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text("WITHDRAW NOW", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          const SizedBox(width: 15),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)), child: const Icon(Icons.more_horiz, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final txns = [
      {"name": "Deduction - Service Fee", "time": "12 Oct, 10:00 AM", "price": "- ₹122", "color": Colors.red},
      {"name": "Salon Service - Booking #UC882", "time": "11 Oct, 04:00 PM", "price": "+ ₹2,299", "color": Colors.green},
      {"name": "Withdrawal to Bank", "time": "10 Oct, 09:30 AM", "price": "- ₹5,000", "color": Colors.red},
      {"name": "Cleaning - Booking #UC881", "time": "10 Oct, 02:00 PM", "price": "+ ₹1,499", "color": Colors.green},
    ];
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("RECENT TRANSACTIONS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
          const SizedBox(height: 25),
          ...txns.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (t["color"] as Color).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.payment, color: t["color"] as Color, size: 20)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t["name"] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.accentColor)),
                          Text(t["time"] as String, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(t["price"] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: t["color"] as Color, fontSize: 14)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
