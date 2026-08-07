import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'wallet_receipt_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _bg = Color(0xFFF8FAFC);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _green = Color(0xFF10B981);

class WalletPaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final double newBalance;
  final String transactionId;
  final DateTime date;

  const WalletPaymentSuccessScreen({
    Key? key,
    required this.amount,
    required this.newBalance,
    required this.transactionId,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false, // User shouldn't go back to processing
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _dark),
            onPressed: () => Navigator.pop(context, true), // pop back to wallet
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCheckmark(),
            const SizedBox(height: 24),
            Text('Money Added\nSuccessfully!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 24),
            _buildAmountCard(),
            const SizedBox(height: 24),
            _buildDetailsCard(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WalletReceiptScreen(
                        amount: amount,
                        newBalance: newBalance,
                        transactionId: transactionId,
                        date: date,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('View Receipt', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, true), // return to wallet
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_rounded, color: _primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Back to Wallet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: _green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text('₹${amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: _green)),
          const SizedBox(height: 4),
          Text('Added to your wallet', style: GoogleFonts.inter(fontSize: 14, color: _gray)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Wallet Balance', style: GoogleFonts.inter(fontSize: 14, color: _gray)),
                const SizedBox(width: 12),
                Text('₹${newBalance.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _detailRow('Transaction ID', transactionId, hasCopy: true),
          const SizedBox(height: 16),
          _detailRow('Payment Method', 'Online'), // Cashfree handles exact method
          const SizedBox(height: 16),
          _detailRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(date)),
          const SizedBox(height: 16),
          _detailRow('Status', 'Success', valueColor: _green),
          const SizedBox(height: 16),
          _detailRow('Remarks', 'Wallet Top-up'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool hasCopy = false, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: _gray)),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? _dark),
                ),
              ),
              if (hasCopy) ...[
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, size: 14, color: _gray),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
