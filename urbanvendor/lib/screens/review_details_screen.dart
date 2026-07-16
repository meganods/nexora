import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart';

class ReviewDetailsScreen extends StatefulWidget {
  const ReviewDetailsScreen({super.key});

  @override
  State<ReviewDetailsScreen> createState() => _ReviewDetailsScreenState();
}

class _ReviewDetailsScreenState extends State<ReviewDetailsScreen> {
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  Future<void> _submitToFirebase() async {
    setState(() => _isSubmitting = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final vendorData = context.read<RegistrationProvider>().toMap();
      
      // Update the existing document created during Step 2
      await FirebaseFirestore.instance.collection('vendors').doc(user.uid).set({
        ...vendorData,
        'uid': user.uid,
        'status': 'PENDING', // Final submission status
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/application_submitted', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'STEP 8 OF 8',
                  style: GoogleFonts.poppins(
                    color: primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: primaryBlue, height: 1.0),
        ),
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
            onPressed: (_agreedToTerms && !_isSubmitting) ? _submitToFirebase : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              disabledBackgroundColor: primaryBlue.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Submit Application', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
              'FINAL STEP',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: const Color(0xFFC45E45),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review Your Details',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please verify all information before\nsubmitting your application for review.\nOnce submitted, some details may be\nlocked during the approval process.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blueGrey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            
            // Profile Card
            _buildReviewCard(
              title: 'Profile',
              icon: Icons.person,
              iconColor: primaryBlue,
              iconBgColor: const Color(0xFFE8E5FF),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[300],
                        ),
                        // Mock avatar placeholder or generic icon
                        child: const Icon(Icons.face, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Consumer<RegistrationProvider>(
                        builder: (context, registration, child) => Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(registration.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(registration.email, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF6F6FB), borderRadius: BorderRadius.circular(12)),
                    child: Consumer<RegistrationProvider>(
                      builder: (context, registration, child) => Text(
                        '"${registration.businessBio}"',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Services Card
            _buildReviewCard(
              title: 'Services',
              icon: Icons.category, // Approximate triangle icon
              iconColor: const Color(0xFF0C6B8B),
              iconBgColor: const Color(0xFFE2F6F9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Categories', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFC4EBF6), borderRadius: BorderRadius.circular(8)),
                          child: Consumer<RegistrationProvider>(
                            builder: (context, registration, child) {
                              if (registration.selectedCategoryIds.isEmpty) return const Text('None', style: TextStyle(fontSize: 10));
                              return Text('${registration.selectedCategoryIds.length} Selected', style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w500));
                            },
                          ),
                        ),
                      ],
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFEEEEEE), height: 1),
                  ),
                  Text('ENABLED SERVICES', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Consumer<RegistrationProvider>(
                    builder: (context, registration, child) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: registration.enabledServiceNames.map((s) => _buildServicePill(s)).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Documents Card
            _buildReviewCard(
              title: 'Documents',
              icon: Icons.file_present,
              iconColor: const Color(0xFF9E3A1A),
              iconBgColor: const Color(0xFFF9DDD4),
              child: Column(
                children: [
                  _buildDocumentItem('Business License.pdf', 'VERIFIED'),
                  const SizedBox(height: 8),
                  _buildDocumentItem('ID_Verification.jpg', 'VERIFIED'),
                  const SizedBox(height: 8),
                  _buildDocumentItem('Portfolio_Work.pdf', 'UPLOADED', isUploaded: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pricing & Locality Card
            _buildReviewCard(
              title: 'Pricing & Locality',
              icon: Icons.payments_outlined,
              iconColor: primaryBlue,
              iconBgColor: const Color(0xFFE8E5FF),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF6F6FB), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BASE RATE', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 1.0)),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(color: Colors.black87),
                                  children: [
                                    TextSpan(text: '₹${Provider.of<RegistrationProvider>(context).baseRate.toInt()}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E66))),
                                    TextSpan(text: '/hr', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFECF9FA), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SERVICE RADIUS', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF0C6B8B), letterSpacing: 1.0)),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(color: Colors.black87),
                                  children: [
                                    TextSpan(text: '${Provider.of<RegistrationProvider>(context).serviceRadius}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                                    TextSpan(text: 'km', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF6F6FB), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            Provider.of<RegistrationProvider>(context).address,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey[800]),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Agreement Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9F9FF), borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (val) {
                        setState(() {
                          _agreedToTerms = val ?? false;
                        });
                      },
                      activeColor: primaryBlue,
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700], height: 1.5),
                        children: const [
                          TextSpan(text: 'I certify that all provided information is accurate and I agree to the '),
                          TextSpan(text: 'Partner Terms of Service ', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                          TextSpan(text: 'and '),
                          TextSpan(text: 'Privacy Policy', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                          TextSpan(text: '. I understand that background checks are required for final activation.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button removed from here (moved to bottomNavigationBar)
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
              const Spacer(),
              const Icon(Icons.edit, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildServicePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87)),
    );
  }

  Widget _buildDocumentItem(String title, String status, {bool isUploaded = false}) {
    final statusColor = isUploaded ? const Color(0xFF1EA04D) : const Color(0xFF1EA04D);
    final statusBgColor = isUploaded ? const Color(0xFFEFFFF3) : const Color(0xFFEFFFF3);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF1EA04D), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87))),
          Text(status, style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
