import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_journey_screen.dart';
import 'application_status_screen.dart';
import 'expert_portal_dashboard.dart';

class RootGatekeeper extends StatelessWidget {
  const RootGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const OnboardingJourneyScreen();
        }

        // User is logged in, now check their vendor status
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vendors')
              .where(Filter.or(
                Filter('uid', isEqualTo: user.uid),
                Filter('email', isEqualTo: user.email ?? ''),
              ))
              .snapshots(),
          builder: (context, vendorSnapshot) {
            if (vendorSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!vendorSnapshot.hasData || vendorSnapshot.data!.docs.isEmpty) {
              return const OnboardingJourneyScreen();
            }

            final data = vendorSnapshot.data!.docs.first.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'PENDING';

            if (status == 'APPROVED') {
              return const ExpertPortalDashboard();
            } else {
              return const ApplicationStatusScreen();
            }
          },
        );
      },
    );
  }
}
