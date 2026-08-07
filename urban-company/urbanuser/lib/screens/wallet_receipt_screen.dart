import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/app_toast.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _primary = Color(0xFF2563EB);
const _bg = Color(0xFFF8FAFC);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _green = Color(0xFF10B981);

class WalletReceiptScreen extends StatelessWidget {
  final double amount;
  final double newBalance;
  final String transactionId;
  final DateTime date;

  const WalletReceiptScreen({
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Receipt', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _dark, size: 20),
            onPressed: () => AppToast.show(context, title: 'Share', message: 'Sharing receipt feature coming soon!'),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: _dark, size: 22),
            onPressed: () => AppToast.show(context, title: 'Download', message: 'Downloading receipt feature coming soon!'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildReceiptCard(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => AppToast.show(context, title: 'Download', message: 'Downloading receipt feature coming soon!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Download Receipt', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => AppToast.show(context, title: 'Share', message: 'Sharing receipt feature coming soon!'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.ios_share_rounded, color: _primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Share Receipt', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
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

  Widget _buildReceiptCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Successful', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _green)),
                    const SizedBox(height: 4),
                    Text('₹${amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _dark)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction Details', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 24),
                _detailRow('Transaction ID', transactionId),
                const SizedBox(height: 16),
                _detailRow('Order ID', transactionId),
                const SizedBox(height: 16),
                _detailRow('Payment Method', 'Online'), // Cashfree masks the exact method
                const SizedBox(height: 16),
                _detailRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(date)),
                const SizedBox(height: 16),
                _detailRow('Payment Status', 'Success', valueColor: _green),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                _detailRow('Amount Added', '₹${amount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                _detailRow('Wallet Balance', '₹${newBalance.toStringAsFixed(2)}'),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text('NEXORA', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: _primary, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('Thank you for your payment!', style: GoogleFonts.inter(fontSize: 14, color: _dark)),
                const SizedBox(height: 24),
                Icon(Icons.account_balance_wallet_rounded, size: 64, color: _primary.withOpacity(0.8)),
                const SizedBox(height: 24),
                Text('This is a system generated receipt\nFor any queries, contact support.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: _gray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: _gray)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? _dark),
          ),
        ),
      ],
    );
  }
}
