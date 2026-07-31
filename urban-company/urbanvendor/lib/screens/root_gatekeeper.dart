import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_journey_screen.dart';
import 'expert_portal_dashboard.dart';
import 'pending_dashboard_screen.dart';

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

        final String primaryId = (user.email != null && user.email!.isNotEmpty) ? user.email! : user.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vendors')
              .doc(primaryId)
              .snapshots(),
          builder: (context, vendorSnapshot) {
            if (vendorSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!vendorSnapshot.hasData || !vendorSnapshot.data!.exists) {
              // Try UID doc if email doc wasn't found
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vendors')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, uidSnapshot) {
                  if (uidSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!uidSnapshot.hasData || !uidSnapshot.data!.exists) {
                    return const PendingDashboardScreen();
                  }
                  return _checkStatusAndNavigate(uidSnapshot.data!.data() as Map<String, dynamic>);
                },
              );
            }

            return _checkStatusAndNavigate(vendorSnapshot.data!.data() as Map<String, dynamic>);
          },
        );
      },
    );
  }

  Widget _checkStatusAndNavigate(Map<String, dynamic> data) {
    final verification = data['verification'] as Map<String, dynamic>? ?? {};
    final status = (data['status'] ?? verification['status'] ?? 'NotStarted').toString().toLowerCase().trim();

    if (status == 'approved') {
      return const ExpertPortalDashboard();
    } else {
      return const PendingDashboardScreen();
    }
  }
}
