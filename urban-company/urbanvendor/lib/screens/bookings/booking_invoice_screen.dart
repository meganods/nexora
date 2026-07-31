import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class BookingInvoiceScreen extends StatelessWidget {
  const BookingInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final bookingId = args['bookingId'] ?? 'BK-9921';
    final data = args['data'] as Map<String, dynamic>? ?? {};
    final serviceName = data['serviceName'] ?? data['serviceType'] ?? 'General Service';
    final customerName = data['userName'] ?? data['customerName'] ?? 'Customer';
    final basePrice = double.tryParse(data['price']?.toString() ?? '999') ?? 999.0;
    final addOns = 200.0;
    final gst = (basePrice + addOns) * 0.18;
    final grandTotal = basePrice + addOns + gst - 100.0;

    return Scaffold(
      backgroundColor: VendorTheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tax Invoice",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: VendorTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: VendorTheme.primaryColor),
            onPressed: () => AppSnackbar.show(context, "Invoice shared via SMS & Email!"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Brand
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("NEXORA TAX INVOICE", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: VendorTheme.primaryColor)),
                            Text("Invoice #INV-${bookingId.replaceAll('BK-', '')}", style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: VendorTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text("PAID", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: VendorTheme.accentColor)),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Customer & Vendor Meta
                    Text("Billed To: $customerName", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary)),
                    Text("Service Rendered: $serviceName", style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary)),
                    const SizedBox(height: 24),

                    // Itemized Line Breakdown
                    Text("Itemized Breakdown", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: VendorTheme.textSecondary)),
                    const SizedBox(height: 12),
                    _buildInvoiceRow("Base Service Charge", "₹${basePrice.toStringAsFixed(2)}"),
                    _buildInvoiceRow("Additional Spare Parts & Materials", "₹${addOns.toStringAsFixed(2)}"),
                    _buildInvoiceRow("GST (18%)", "₹${gst.toStringAsFixed(2)}"),
                    _buildInvoiceRow("Promo Coupon Discount", "-₹100.00", isDiscount: true),
                    const Divider(height: 24),
                    _buildInvoiceRow("Grand Total Paid", "₹${grandTotal.toStringAsFixed(2)}", isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // PDF Download Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => AppSnackbar.show(context, "Invoice PDF downloaded to device storage!"),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: VendorTheme.primaryColor),
                label: Text("Download PDF Invoice", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: VendorTheme.primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: VendorTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/bookings/summary', arguments: {'bookingId': bookingId, 'data': data, 'earned': grandTotal});
            },
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: Text("View Job Completion Summary", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: VendorTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 13,
              color: isTotal ? VendorTheme.textPrimary : VendorTheme.textSecondary,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              fontSize: isTotal ? 18 : 13,
              color: isDiscount
                  ? VendorTheme.accentColor
                  : isTotal
                      ? VendorTheme.primaryColor
                      : VendorTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
