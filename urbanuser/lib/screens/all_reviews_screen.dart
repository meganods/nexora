import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/service_model.dart';

class AllReviewsScreen extends StatelessWidget {
  final ServiceModel service;

  const AllReviewsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    // Generate some dummy reviews since we don't have them in the model
    final List<Map<String, dynamic>> allReviews = [
      {"name": "Amit Kumar", "comment": "Excellent service! Highly professional.", "rating": 5.0, "date": "10 Oct 2023"},
      {"name": "Priya Sharma", "comment": "Very punctual and did a great job.", "rating": 4.5, "date": "05 Oct 2023"},
      {"name": "Rahul Verma", "comment": "Good work, but arrived a bit late.", "rating": 4.0, "date": "28 Sep 2023"},
      {"name": "Neha Singh", "comment": "Absolutely brilliant, will book again!", "rating": 5.0, "date": "15 Sep 2023"},
      {"name": "Vikas Gupta", "comment": "Decent service, met expectations.", "rating": 4.0, "date": "02 Sep 2023"},
      {"name": "Anjali Patel", "comment": "Very polite and skilled professional.", "rating": 5.0, "date": "20 Aug 2023"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentColor),
        title: Text(
          "All Reviews",
          style: GoogleFonts.outfit(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildRatingHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: allReviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final review = allReviews[index];
                return _buildReviewItem(
                  review["name"] as String,
                  review["comment"] as String,
                  review["rating"] as double,
                  review["date"] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                "${service.rating}",
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < service.rating.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(height: 5),
              Text(
                "Based on ${service.totalReviews} reviews",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String comment, double rating, String date) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                rating.toString(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
