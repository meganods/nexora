import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart';

class ApplicationStatusScreen extends StatelessWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text("Not Logged In"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Application Not Found")));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'PENDING';
        final name = data['name'] ?? 'Partner';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            titleSpacing: 0,
            backgroundColor: bgColor,
            elevation: 0,
            title: Padding(
              padding: const EdgeInsets.only(left: 24.1),
              child: Text(
                'Application Status',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: () => FirebaseAuth.instance.signOut(),
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHero(status, name, primaryBlue),
                const SizedBox(height: 30),
                _buildRoadmap(status, primaryBlue),
                if (status == 'PENDING_REGISTRATION') ...[
                  const SizedBox(height: 30),
                  _buildContinueRegistrationButton(context, primaryBlue),
                ],
                const SizedBox(height: 30),
                _buildSupportSection(primaryBlue),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHero(String status, String name, Color primaryBlue) {
    Color statusColor;
    Color statusBg;
    String statusText;
    String desc;
    double progress;

    switch (status) {
      case 'REJECTED':
        statusColor = Colors.red;
        statusBg = const Color(0xFFFFEEEE);
        statusText = 'REJECTED';
        desc = 'Unfortunately, your application does not meet our current requirements. Contact support for details.';
        progress = 1.0;
        break;
      case 'UNDER_REVIEW':
        statusColor = const Color(0xFFD69E2E);
        statusBg = const Color(0xFFFFF6E5);
        statusText = 'UNDER REVIEW';
        desc = 'Our quality assurance team is verifying your professional background and documents.';
        progress = 0.66;
        break;
      case 'PENDING_REGISTRATION':
        statusColor = Colors.blueGrey;
        statusBg = Colors.grey[200]!;
        statusText = 'INCOMPLETE';
        desc = 'You haven\'t finished your registration steps yet. Please continue where you left off.';
        progress = 0.33;
        break;
      case 'PENDING':
      default:
        statusColor = primaryBlue;
        statusBg = const Color(0xFFE8E5FF);
        statusText = 'SUBMITTED';
        desc = 'Your application has been received and is waiting in the queue for our team to review.';
        progress = 0.5;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            status == 'REJECTED' ? 'Application Status' : 'Waiting for Approval,\n$name!',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[700], height: 1.6),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[100],
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                status == 'PENDING' ? '50%' : status == 'UNDER_REVIEW' ? '75%' : '100%',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmap(String status, Color primaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Application Roadmap', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        _buildStep(
          icon: Icons.assignment_returned_outlined,
          title: 'Account Created',
          subtitle: 'Profile steps initiated',
          isDone: true,
          isCurrent: false,
          color: Colors.green,
        ),
        _buildStep(
          icon: Icons.fact_check_outlined,
          title: 'Admin Verification',
          subtitle: status == 'PENDING' ? 'Waiting in queue' : 'Verification in progress',
          isDone: status == 'UNDER_REVIEW' || status == 'APPROVED' || status == 'REJECTED',
          isCurrent: status == 'PENDING' || status == 'UNDER_REVIEW',
          color: status == 'REJECTED' ? Colors.red : primaryBlue,
        ),
        _buildStep(
          icon: Icons.rocket_launch_outlined,
          title: 'Final Activation',
          subtitle: 'Ready to receive bookings',
          isDone: status == 'APPROVED',
          isCurrent: false,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDone ? color.withValues(alpha: 0.1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              color: isDone ? color : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDone || isCurrent ? Colors.black87 : Colors.grey[400],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(Color primaryBlue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: Color(0xFF4A55ED), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need Assistance?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Chat with our support team', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildContinueRegistrationButton(BuildContext context, Color primaryBlue) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String nextStep = '/create_profile';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          nextStep = data['currentStep'] ?? '/create_profile';
        }

        return Container(
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
            onPressed: () {
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                context.read<RegistrationProvider>().fromMap(data);
              }
              Navigator.pushNamed(context, nextStep);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue Registration',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        );
      }
    );
  }
}
