import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'cloudinary_service.dart';

class KycService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends an Aadhaar OTP to the registered mobile linked with Aadhaar.
  /// This is a service layer placeholder that returns a transaction ID.
  Future<String> sendAadhaarOTP(String aadhaarNumber) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API network latency
    if (aadhaarNumber.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(aadhaarNumber)) {
      throw Exception("Invalid Aadhaar Number. Must be exactly 12 digits.");
    }
    // Return a mock transaction ID
    return "TXN-${DateTime.now().millisecondsSinceEpoch}";
  }

  /// Verifies the Aadhaar OTP with the transaction ID.
  /// This is a service layer placeholder.
  Future<bool> verifyAadhaarOTP(String transactionId, String otpCode) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API network latency
    if (otpCode.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(otpCode)) {
      throw Exception("Invalid OTP. Must be exactly 6 digits.");
    }
    // In simulation mode, accept 123456 or any numeric 6-digit OTP
    return true;
  }

  /// Uploads a document (PAN / GST) using Cloudinary.
  Future<String?> uploadDocument(String filePath) async {
    return await CloudinaryService.uploadImage(
      filePath: filePath,
      folder: 'urban_company/vendor_profiles',
    );
  }

  /// Saves the progress step and section data of the KYC flow to Firestore.
  Future<void> saveKycProgress({
    required String uid,
    required String currentStep,
    required Map<String, dynamic> stepData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final String targetUid = user?.uid ?? uid;
    final String? email = user?.email ?? (uid.contains('@') ? uid : null);

    final updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
      'verification': {
        'currentStep': currentStep,
        'status': 'InProgress',
        ...stepData,
      },
      'timestamps': {
        'lastUpdated': FieldValue.serverTimestamp(),
      }
    };

    await _firestore.collection('vendors').doc(targetUid).set(updateData, SetOptions(merge: true));
    if (email != null && email.isNotEmpty && email != targetUid) {
      await _firestore.collection('vendors').doc(email).set(updateData, SetOptions(merge: true));
    }
  }

  /// Submits the verification application for Admin Review.
  Future<void> submitKycVerification(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    final String targetUid = user?.uid ?? uid;
    final String? email = user?.email ?? (uid.contains('@') ? uid : null);

    final updateData = {
      'status': 'PENDING',
      'updatedAt': FieldValue.serverTimestamp(),
      'verification': {
        'status': 'PENDING',
        'currentStep': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
      },
      'timestamps': {
        'submittedAt': FieldValue.serverTimestamp(),
      }
    };

    await _firestore.collection('vendors').doc(targetUid).set(updateData, SetOptions(merge: true));
    if (email != null && email.isNotEmpty && email != targetUid) {
      await _firestore.collection('vendors').doc(email).set(updateData, SetOptions(merge: true));
    }
  }

  /// Admin action: Approve Vendor KYC.
  Future<void> adminApproveVendor(String vendorId, String adminEmail) async {
    final docRef = _firestore.collection('vendors').doc(vendorId);
    final snap = await docRef.get();
    final data = snap.data();

    final updateData = {
      'status': 'APPROVED',
      'updatedAt': FieldValue.serverTimestamp(),
      'verification': {
        'status': 'APPROVED',
      },
      'adminReview': {
        'approvedBy': adminEmail,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
        'requestChangesReason': null,
      }
    };

    await docRef.set(updateData, SetOptions(merge: true));

    if (data != null) {
      final String? email = data['email'];
      final String? uid = data['uid'];
      if (email != null && email.isNotEmpty && email != vendorId) {
        await _firestore.collection('vendors').doc(email).set(updateData, SetOptions(merge: true));
      }
      if (uid != null && uid.isNotEmpty && uid != vendorId) {
        await _firestore.collection('vendors').doc(uid).set(updateData, SetOptions(merge: true));
      }
    }
  }

  /// Admin action: Request changes.
  Future<void> adminRequestChanges(String vendorId, String adminEmail, String reason) async {
    final docRef = _firestore.collection('vendors').doc(vendorId);
    final snap = await docRef.get();
    final data = snap.data();

    final updateData = {
      'status': 'REQUEST_CHANGES',
      'updatedAt': FieldValue.serverTimestamp(),
      'verification': {
        'status': 'RequestChanges',
        'currentStep': 'pan',
      },
      'adminReview': {
        'approvedBy': adminEmail,
        'rejectionReason': null,
        'requestChangesReason': reason,
      }
    };

    await docRef.set(updateData, SetOptions(merge: true));

    if (data != null) {
      final String? email = data['email'];
      final String? uid = data['uid'];
      if (email != null && email.isNotEmpty && email != vendorId) {
        await _firestore.collection('vendors').doc(email).set(updateData, SetOptions(merge: true));
      }
      if (uid != null && uid.isNotEmpty && uid != vendorId) {
        await _firestore.collection('vendors').doc(uid).set(updateData, SetOptions(merge: true));
      }
    }
  }

  /// Admin action: Reject Vendor KYC.
  Future<void> adminRejectVendor(String vendorId, String adminEmail, String reason) async {
    final docRef = _firestore.collection('vendors').doc(vendorId);
    final snap = await docRef.get();
    final data = snap.data();

    final updateData = {
      'status': 'REJECTED',
      'updatedAt': FieldValue.serverTimestamp(),
      'verification': {
        'status': 'REJECTED',
        'currentStep': 'welcome',
      },
      'adminReview': {
        'approvedBy': adminEmail,
        'rejectionReason': reason,
        'requestChangesReason': null,
      }
    };

    await docRef.set(updateData, SetOptions(merge: true));

    if (data != null) {
      final String? email = data['email'];
      final String? uid = data['uid'];
      if (email != null && email.isNotEmpty && email != vendorId) {
        await _firestore.collection('vendors').doc(email).set(updateData, SetOptions(merge: true));
      }
      if (uid != null && uid.isNotEmpty && uid != vendorId) {
        await _firestore.collection('vendors').doc(uid).set(updateData, SetOptions(merge: true));
      }
    }
  }
}
