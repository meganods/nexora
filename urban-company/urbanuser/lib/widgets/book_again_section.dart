import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../screens/my_bookings_screen.dart';

class BookAgainSection extends StatefulWidget {
  const BookAgainSection({super.key});

  @override
  State<BookAgainSection> createState() => _BookAgainSectionState();
}

class _BookAgainSectionState extends State<BookAgainSection> {
  final List<Map<String, dynamic>> _fallback = [
    {
      'id': 'b1',
      'serviceName': 'Deep Home Cleaning',
      'category': 'Cleaning',
      'vendorName': 'Rahul Sharma',
      'rating': 5.0,
      'createdAt': DateTime(2026, 7, 15),
      'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400&auto=format&fit=crop',
    },
    {
      'id': 'b2',
      'serviceName': 'AC Complete Service',
      'category': 'AC Repair',
      'vendorName': 'Vikram Kumar',
      'rating': 4.9,
      'createdAt': DateTime(2026, 7, 8),
      'image': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=400&auto=format&fit=crop',
    }
  ];

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);
    const lightBlue = Color(0xFFEFF6FF);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const successGreen = Color(0xFF10B981);
    const borderGray = Color(0xFFE2E8F0);

    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'completed')
              .orderBy('createdAt', descending: true)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        List<Map<String, dynamic>> items = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final createdVal = data['createdAt'];
            DateTime date = DateTime.now();
            if (createdVal is Timestamp) {
              date = createdVal.toDate();
            }
            items.add({
              'id': doc.id,
              'serviceName': data['serviceName'] ?? 'Service',
              'category': data['category'] ?? '',
              'vendorName': data['vendorName'] ?? 'Professional',
              'rating': ((data['rating'] ?? 5.0) as num).toDouble(),
              'createdAt': date,
              'image': data['serviceImage'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400&auto=format&fit=crop',
            });
          }
        } else {
          items = _fallback;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book It Again',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your recently booked services',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          'View History',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: brandBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: brandBlue),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Horizontal Slider
            SizedBox(
              height: 290,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final serviceName = item['serviceName'] as String;
                  final vendorName = item['vendorName'] as String;
                  final double rating = item['rating'] as double;
                  final DateTime date = item['createdAt'] as DateTime;
                  final String image = item['image'] as String;

                  final String dateString = DateFormat('dd MMMM yyyy').format(date);
                  final int daysAgo = DateTime.now().difference(date).inDays;

                  return Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderGray),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with Badges
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                image,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 120,
                                  color: lightBlue,
                                  child: const Icon(Icons.cleaning_services_rounded, color: brandBlue, size: 36),
                                ),
                              ),
                            ),
                            // Previously Booked badge
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: brandBlue.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  'PREVIOUSLY BOOKED',
                                  style: GoogleFonts.inter(
                                    color: brandBlue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Completed badge
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: successGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Completed',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.check, color: Colors.white, size: 10),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Card Body
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Rating row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      serviceName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${rating.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              // Vendor name
                              Text(
                                vendorName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Date
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 11, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateString,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Buttons row
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: brandBlue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          'Repeat Booking',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: lightBlue,
                                          foregroundColor: brandBlue,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          'Details',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Subtitle days ago
                              Center(
                                child: Text(
                                  'Last booked $daysAgo days ago',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
