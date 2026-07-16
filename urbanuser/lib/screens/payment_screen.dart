import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/thank_you_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double? totalAmount;
  const PaymentScreen({super.key, this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedAddress = "Home";
  String selectedPayment = "Credit Card";

  @override
  Widget build(BuildContext context) {
    double subtotal = widget.totalAmount ?? 1299.0;
    double tax = subtotal * 0.18;
    double total = subtotal + tax + 20.0; // 20 is delivery/conv fee

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("DELIVERY ADDRESS"),
            _buildAddressSelection(),
            const SizedBox(height: 25),
            _buildSectionHeader("PAYMENT METHOD"),
            _buildPaymentSelection(),
            const SizedBox(height: 40),
            _buildOrderSummary(subtotal, tax, total),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildPayNowButton(total),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Checkout", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 22)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
    );
  }

  Widget _buildAddressSelection() {
    return Column(
      children: [
        _addressCard("Home", "Sector 45, Gurgaon, Block B, 402", "+91 888 888 8888"),
        _addressCard("Office", "Cyber Hub, DLF Phase 3, Gurgaon", "+91 999 999 9999"),
      ],
    );
  }

  Widget _addressCard(String title, String desc, String phone) {
    bool isSelected = selectedAddress == title;
    return GestureDetector(
      onTap: () => setState(() => selectedAddress = title),
      child: Container(
        margin: const EdgeInsets.fromLTRB(25, 0, 25, 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[100]!, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey[50], shape: BoxShape.circle),
              child: Icon(isSelected ? Icons.home : Icons.home_outlined, color: isSelected ? AppTheme.primaryColor : Colors.grey[400], size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accentColor)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelection() {
    return Column(
      children: [
        _paymentCard("Credit Card", "Ends in 4242", Icons.credit_card),
        _paymentCard("Google Pay", "tap to pay via UPI", Icons.account_balance_wallet_outlined),
        _paymentCard("Paytm Wallet", "₹1,240 Balance", Icons.account_balance),
        _paymentCard("Cash on Delivery", "Pay with cash at doorstep", Icons.money_rounded),
      ],
    );
  }

  Widget _paymentCard(String title, String subtitle, IconData icon) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        margin: const EdgeInsets.fromLTRB(25, 0, 25, 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[100]!, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey[50], shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey[600], size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? AppTheme.primaryColor : Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double tax, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ORDER SUMMARY", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey[100]!)),
            child: Column(
              children: [
                _priceRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
                const SizedBox(height: 15),
                _priceRow("Tax (GST 18%)", "₹${tax.toStringAsFixed(0)}"),
                const SizedBox(height: 15),
                _priceRow("Convenience Fee", "₹20"),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                    Text("₹${total.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.accentColor)),
      ],
    );
  }

  Widget _buildPayNowButton(double total) {
    bool isCOD = selectedPayment == "Cash on Delivery";
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[100]!))),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ThankYouScreen()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isCOD ? "PLACE ORDER" : "PAY ₹${total.toStringAsFixed(0)}", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
            const SizedBox(width: 15),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
