import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/service_model.dart';
import 'all_reviews_screen.dart';

class VendorProfileScreen extends StatelessWidget {
  final ServiceModel service;

  const VendorProfileScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentColor),
        title: Text(
          "Vendor Profile",
          style: GoogleFonts.outfit(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('vendors')
            .where('enabledServices', arrayContains: service.id)
            .get(),
        builder: (context, snapshot) {
          Map<String, dynamic> vendorInfo = {
            'name': service.vendorName,
            'rating': service.rating,
            'reviewsCount': service.totalReviews,
            'experience': 'Professional Partner • Member since 2021',
            'about': "Hi, I am ${service.vendorName}, a verified professional at NEXORA. I specialize in providing top-notch services directly at your doorstep with a 100% satisfaction guarantee. I follow all safety protocols and use premium quality products.",
            'jobs': '500+',
            'completion': '98%',
            'replyTime': '2 hrs',
          };

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final doc = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            vendorInfo['name'] = doc['name'] ?? doc['businessName'] ?? service.vendorName;
            vendorInfo['rating'] = doc['rating'] ?? service.rating;
            vendorInfo['reviewsCount'] = doc['reviewsCount'] ?? service.totalReviews;
            vendorInfo['experience'] = "Verified Partner • ${doc['businessName'] ?? 'NEXORA Expert'}";
            vendorInfo['about'] = doc['about'] ?? "Hi, I am ${vendorInfo['name']}, a verified professional at NEXORA. I specialize in providing top-notch services directly at your doorstep with a 100% satisfaction guarantee.";
            vendorInfo['jobs'] = doc['jobsCount']?.toString() ?? '150+';
            vendorInfo['completion'] = doc['completionRate']?.toString() ?? '99%';
            vendorInfo['replyTime'] = doc['replyTime'] ?? '1 hr';
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(vendorInfo),
                const SizedBox(height: 30),
                _buildStats(vendorInfo),
                const SizedBox(height: 30),
                _buildSectionDivider(),
                _buildAboutSection(vendorInfo),
                _buildSectionDivider(),
                _buildReviewsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> vendorInfo) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.lightGray,
          child: Icon(Icons.person, size: 50, color: AppTheme.accentColor),
        ),
        const SizedBox(height: 15),
        Text(
          vendorInfo['name'],
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          vendorInfo['experience'],
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 5),
            Text(
              "${vendorInfo['rating']}",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              " (${vendorInfo['reviewsCount']} reviews)",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(Map<String, dynamic> vendorInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(vendorInfo['jobs'], "Jobs Done"),
        _buildStatItem(vendorInfo['completion'], "Completion"),
        _buildStatItem(vendorInfo['replyTime'], "Avg Reply"),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 8,
      color: const Color(0xFFF5F5F5),
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> vendorInfo) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            vendorInfo['about'],
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Reviews",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllReviewsScreen(service: service),
                    ),
                  );
                },
                child: Text(
                  "See all",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReviewItem("Amit Kumar", "Excellent service! Highly professional.", 5),
          const SizedBox(height: 15),
          _buildReviewItem("Priya Sharma", "Very punctual and did a great job.", 4.5),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String comment, double rating) {
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
