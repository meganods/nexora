import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/registration_provider.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Partner Registration',
          style: GoogleFonts.poppins(
            color: primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 35,
                    height: 5,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 12,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<RegistrationProvider>(context, listen: false);
              provider.currentStep = '/pricing_availability';

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('vendors').doc(user.uid).update({
                  'currentStep': provider.currentStep,
                });
              }

              if (context.mounted) Navigator.pushNamed(context, '/pricing_availability');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Your\nDocuments',
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To ensure safety and compliance for our clients, please provide clear scans or photos of the following official documents.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.blueGrey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            
            // Document Card 1: Aadhaar
            _buildDocumentCard(
              title: 'Aadhaar Card',
              subtitle: 'Government Identity Proof',
              icon: Icons.badge,
              iconColor: primaryBlue,
              iconBgColor: const Color(0xFFE8E5FF),
              isUploaded: true,
              filename: 'DOCUMENT_FRONT.JPG',
            ),
            const SizedBox(height: 24),

            // Document Card 2: PAN Card
            _buildDocumentCard(
              title: 'PAN Card',
              subtitle: 'Tax Registration Document',
              icon: Icons.credit_card,
              iconColor: const Color(0xFF8C3B12),
              iconBgColor: const Color(0xFFF9DDD4),
              isUploaded: false,
              filename: '',
            ),
            
            const SizedBox(height: 40),
            
            // Next Button removed from here
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isUploaded,
    required String filename,
  }) {
    const primaryBlue = Color(0xFF4A55ED);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Upload Area Box
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[300], // For the mockup it's grey
              borderRadius: BorderRadius.circular(16),
              border: isUploaded 
                  ? Border.all(color: Colors.grey[400]!, width: 2, style: BorderStyle.solid) 
                  : Border.all(color: Colors.grey[400]!, width: 2, style: BorderStyle.solid), // In a real app we'd use dotted
            ),
            child: isUploaded 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_done, color: primaryBlue, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        filename,
                        style: GoogleFonts.poppins(
                          color: primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[500], size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload front side',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          
          // Card Footer
          if (isUploaded)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Verified',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0C8A9E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0C8A9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document replacement requires admin approval first.')));
                  },
                  child: Text(
                    'Replace',
                    style: GoogleFonts.poppins(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}
