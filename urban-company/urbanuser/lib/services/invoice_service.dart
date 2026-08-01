import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// ─── NEXORA Invoice Service ───────────────────────────────────────────────────
/// Generates a professional real PDF invoice from booking data and
/// triggers a native download/print/share dialog on all platforms.
class InvoiceService {
  /// Downloads/shares a real PDF invoice for the given booking data.
  /// Shows the system's native share/print/save dialog.
  static Future<void> downloadInvoice({
    required BuildContext context,
    required Map<String, dynamic> booking,
  }) async {
    final pdfBytes = await _generatePdf(booking);

    final bookingId = booking['id'] ?? booking['bookingId'] ?? 'NEX-00001';
    final fileName = 'NEXORA_Invoice_$bookingId.pdf';

    // Use the printing package to save/share/print the PDF
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }

  /// Builds the PDF document from booking data.
  static Future<Uint8List> _generatePdf(Map<String, dynamic> booking) async {
    final pdf = pw.Document(
      theme: pw.ThemeData(
        defaultTextStyle: pw.TextStyle(
          font: await PdfGoogleFonts.nunitoRegular(),
          fontSize: 12,
        ),
      ),
    );

    // ── Parse booking fields ───────────────────────────────────────────────
    final String bookingId = booking['id'] ?? booking['bookingId'] ?? 'NEX-00001';
    final String serviceName = booking['shopName'] ?? booking['serviceName'] ?? booking['title'] ?? 'Home Service';
    final String userName = booking['userName'] ?? booking['userEmail']?.split('@')?.first ?? 'Customer';
    final String userEmail = booking['userEmail'] ?? '';
    final String userPhone = booking['userPhone'] ?? booking['userMobile'] ?? '';
    final String userAddress = booking['userAddress'] ?? booking['address'] ?? '—';
    final String bookingDate = booking['date'] ?? DateFormat('dd MMM yyyy').format(DateTime.now());
    final String bookingTime = booking['time'] ?? '—';
    final String paymentMethod = booking['paymentMethod'] ?? 'Online Payment';
    final String vendorName = booking['shopName'] ?? booking['vendorName'] ?? 'NEXORA Partner';
    final String couponCode = booking['couponCode'] ?? '';
    final String status = booking['bookingStatus'] ?? booking['status'] ?? 'Completed';

    // ── Parse amounts ─────────────────────────────────────────────────────
    double rawAmount = 0.0;
    if (booking['rawAmount'] != null) {
      rawAmount = (booking['rawAmount'] as num).toDouble();
    } else if (booking['price'] != null) {
      final p = booking['price'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
      rawAmount = double.tryParse(p) ?? 499.0;
    } else {
      rawAmount = 499.0;
    }

    const double platformFee = 29.0;
    const double gst = 52.0;
    final double couponDiscount = (booking['couponDiscount'] as num?)?.toDouble() ?? 0.0;
    final double basePrice = rawAmount - platformFee - gst + couponDiscount;

    // ── Invoice number ─────────────────────────────────────────────────────
    final String invoiceNo = 'INV-${bookingId.replaceAll('NEX-', '').replaceAll('-', '')}';
    final String invoiceDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // ── Define colors ──────────────────────────────────────────────────────
    const primaryBlue = PdfColor.fromInt(0xFF2563EB);
    const darkColor = PdfColor.fromInt(0xFF0F172A);
    const grayColor = PdfColor.fromInt(0xFF64748B);
    const borderColor = PdfColor.fromInt(0xFFE2E8F0);
    const lightBlue = PdfColor.fromInt(0xFFEFF6FF);
    const greenColor = PdfColor.fromInt(0xFF10B981);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: primaryBlue,
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NEXORA',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'India\'s Smart Home Services Platform',
                          style: pw.TextStyle(fontSize: 10, color: const PdfColor(1, 1, 1, 0.75)),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'nexora.app  •  support@nexora.app',
                          style: pw.TextStyle(fontSize: 9, color: const PdfColor(1, 1, 1, 0.75)),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoiceNo,
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          invoiceDate,
                          style: pw.TextStyle(fontSize: 9, color: const PdfColor(1, 1, 1, 0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Billing Info Row ─────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bill To
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: lightBlue,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, color: grayColor, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text(userName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkColor)),
                          if (userEmail.isNotEmpty) pw.Text(userEmail, style: pw.TextStyle(fontSize: 10, color: grayColor)),
                          if (userPhone.isNotEmpty) pw.Text(userPhone, style: pw.TextStyle(fontSize: 10, color: grayColor)),
                          pw.SizedBox(height: 4),
                          pw.Text(userAddress, style: pw.TextStyle(fontSize: 10, color: grayColor)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Service Provider
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('SERVICE PROVIDER', style: pw.TextStyle(fontSize: 9, color: grayColor, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text(vendorName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkColor)),
                          pw.Text('NEXORA Verified Partner', style: pw.TextStyle(fontSize: 10, color: greenColor, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('Booking ID: $bookingId', style: pw.TextStyle(fontSize: 9, color: grayColor)),
                          pw.Text('Status: ${status.toUpperCase()}', style: pw.TextStyle(fontSize: 9, color: primaryBlue, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ── Booking Details Table ────────────────────────────────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    // Table Header
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        color: darkColor,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(11),
                          topRight: pw.Radius.circular(11),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: pw.Row(
                        children: [
                          pw.Expanded(flex: 4, child: pw.Text('SERVICE DESCRIPTION', style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 2, child: pw.Text('SCHEDULE', style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 2, child: pw.Text('PAYMENT', style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 1, child: pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                        ],
                      ),
                    ),
                    // Table Row
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(serviceName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor)),
                                pw.SizedBox(height: 3),
                                pw.Text('Professional home service by NEXORA Partner', style: pw.TextStyle(fontSize: 9, color: grayColor)),
                                pw.Text('Includes platform guarantee & safety protocols', style: pw.TextStyle(fontSize: 9, color: grayColor)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(bookingDate, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkColor)),
                                pw.Text(bookingTime, style: pw.TextStyle(fontSize: 9, color: grayColor)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(paymentMethod, style: pw.TextStyle(fontSize: 10, color: darkColor)),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              '₹${basePrice.toStringAsFixed(0)}',
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkColor),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Price Summary ────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: lightBlue,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfPriceRow('Service Base Price', '₹${basePrice.toStringAsFixed(0)}', grayColor, darkColor),
                        _pdfPriceRow('Platform & Safety Fee', '₹${platformFee.toStringAsFixed(0)}', grayColor, darkColor),
                        _pdfPriceRow('GST (18%)', '₹${gst.toStringAsFixed(0)}', grayColor, darkColor),
                        if (couponCode.isNotEmpty)
                          _pdfPriceRow('Coupon ($couponCode)', '-₹${couponDiscount.toStringAsFixed(0)}', greenColor, greenColor),
                        pw.Divider(color: borderColor, thickness: 0.5),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL PAID', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkColor)),
                            pw.Text('₹${rawAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ── GST Notice ───────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFFBEB),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDE68A)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('ℹ  ', style: pw.TextStyle(fontSize: 12, color: const PdfColor.fromInt(0xFFD97706))),
                    pw.Expanded(
                      child: pw.Text(
                        'This is a system-generated invoice. GST @ 18% is included in the total amount. NEXORA GSTIN: 27AABCN1234R1Z5',
                        style: pw.TextStyle(fontSize: 9, color: const PdfColor.fromInt(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ── Footer ───────────────────────────────────────────────────
              pw.Divider(color: borderColor, thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for choosing NEXORA!', style: pw.TextStyle(fontSize: 10, color: primaryBlue, fontWeight: pw.FontWeight.bold)),
                  pw.Text('nexora.app  •  support@nexora.app', style: pw.TextStyle(fontSize: 9, color: grayColor)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Helper: price row for the summary table in the PDF
  static pw.Widget _pdfPriceRow(String label, String value, PdfColor labelColor, PdfColor valueColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: labelColor)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
