import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for all vendor applications (Pending or otherwise)
  Stream<QuerySnapshot> get vendorApplicationsStream {
    return _firestore
        .collection('vendors')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Method to approve a vendor
  Future<bool> approveVendor(String docId) async {
    try {
      await _firestore.collection('vendors').doc(docId).update({
        'status': 'APPROVED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error approving vendor: $e');
      return false;
    }
  }

  // Method to reject a vendor
  Future<bool> rejectVendor(String docId) async {
    try {
      await _firestore.collection('vendors').doc(docId).update({
        'status': 'REJECTED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error rejecting vendor: $e');
      return false;
    }
  }

  // Delete a vendor (Delete)
  Future<void> deleteVendor(String docId) async {
    try {
      await _firestore.collection('vendors').doc(docId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting vendor: $e');
      rethrow;
    }
  }

  // Update vendor data (Update)
  Future<void> updateVendorData(String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('vendors').doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating vendor: $e');
      rethrow;
    }
  }

  // ====== SERVICES CRUD ======

  // Stream for all services
  Stream<QuerySnapshot> get servicesStream {
    return _firestore.collection('services').snapshots();
  }

  // Add a new service (Create)
  Future<DocumentReference> addService(Map<String, dynamic> serviceData) async {
    try {
      final docRef = await _firestore.collection('services').add({
        ...serviceData,
        'createdAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return docRef;
    } catch (e) {
      debugPrint('Error adding service: $e');
      rethrow;
    }
  }

  // Update a service (Update)
  Future<void> updateService(String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('services').doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating service: $e');
      rethrow;
    }
  }

  // Delete a service (Delete)
  Future<void> deleteService(String docId) async {
    try {
      await _firestore.collection('services').doc(docId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting service: $e');
      rethrow;
    }
  }

  // ====== CATEGORY REQUESTS CRUD ======

  // Stream for all category requests
  Stream<QuerySnapshot> get categoryRequestsStream {
    return _firestore
        .collection('category_requests')
        .snapshots();
  }

  // Update a category request (Approve/Reject)
  Future<void> updateCategoryRequestStatus(String docId, String status) async {
    try {
      await _firestore.collection('category_requests').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating category request: $e');
      rethrow;
    }
  }

  // ====== BOOKINGS CRUD ======

  Stream<QuerySnapshot> get bookingsStream {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateBookingStatus(String docId, String status) async {
    try {
      await _firestore.collection('bookings').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      rethrow;
    }
  }
}
