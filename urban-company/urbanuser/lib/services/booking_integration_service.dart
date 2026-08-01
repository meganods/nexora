import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingIntegrationService {
  // ─── Auto Assign Dispatch Engine ──────────────────────────────────────────
  static Future<bool> autoAssignVendorForBooking(String bookingId, String category) async {
    try {
      final vendorsSnap = await FirebaseFirestore.instance
          .collection('vendors')
          .where('category', isEqualTo: category)
          .where('isOnline', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();

      if (vendorsSnap.docs.isEmpty) return false;

      // Filter and score vendors by active workload, rating, and distance
      DocumentSnapshot? bestVendor;
      double bestScore = -1.0;

      for (var doc in vendorsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final d = data;
        
        final double rating = ((d['rating'] ?? 5.0) as num).toDouble();
        final int activeWorkload = d['activeWorkload'] ?? 0;
        final double basePrice = ((d['basePrice'] ?? 500.0) as num).toDouble();

        // Scoring: Higher rating, lower price, lower workload is better
        final double score = (rating * 10) - (activeWorkload * 5) - (basePrice * 0.01);

        if (score > bestScore) {
          bestScore = score;
          bestVendor = doc;
        }
      }

      if (bestVendor != null) {
        final vendorId = bestVendor.id;
        final vendorName = bestVendor.get('fullName') ?? 'Partner';
        final vendorPhone = bestVendor.get('phoneNumber') ?? '1800-000-000';

        // Update booking with the assigned vendor
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
          'vendorId': vendorId,
          'vendorName': vendorName,
          'vendorPhone': vendorPhone,
          'status': 'Vendor Assigned',
          'timeline': FieldValue.arrayUnion([
            {
              'status': 'Vendor Assigned',
              'title': 'Professional Assigned',
              'description': '$vendorName has been matched to your booking slot.',
              'timestamp': Timestamp.now(),
            }
          ]),
        });

        // Push notification to Vendor
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': vendorId,
          'title': 'New Booking Assigned',
          'body': 'You have been assigned a new task. Accept in your Vendor App.',
          'type': 'booking',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      }
    } catch (e) {
      debugPrint("Dispatch Note: $e");
    }
    return false;
  }

  // ─── Real-Time Status Timeline Synchronization ─────────────────────────────
  static Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    required String title,
    required String desc,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      final userId = data['userId'] as String?;
      final vendorId = data['vendorId'] as String?;

      await docRef.update({
        'status': status,
        'timeline': FieldValue.arrayUnion([
          {
            'status': status,
            'title': title,
            'description': desc,
            'timestamp': Timestamp.now(),
          }
        ]),
      });

      // Notify User
      if (userId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': desc,
          'type': 'booking',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Notify Vendor
      if (vendorId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': vendorId,
          'title': 'Booking Sync: $title',
          'body': desc,
          'type': 'booking',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  // ─── Update Vendor Rating dynamically after review ─────────────────────────
  static Future<void> updateVendorRatingScore(String vendorId) async {
    try {
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      if (reviewsSnap.docs.isEmpty) return;

      double total = 0.0;
      for (var doc in reviewsSnap.docs) {
        total += ((doc.get('rating') ?? 5.0) as num).toDouble();
      }

      final avgRating = total / reviewsSnap.docs.length;

      await FirebaseFirestore.instance.collection('vendors').doc(vendorId).update({
        'rating': avgRating,
        'totalReviews': reviewsSnap.docs.length,
      });
    } catch (_) {}
  }
}
