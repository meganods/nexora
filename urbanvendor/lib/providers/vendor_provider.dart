import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorProvider with ChangeNotifier {
  Map<String, dynamic>? _vendorData;
  bool _isLoading = false;

  Map<String, dynamic>? get vendorData => _vendorData;
  bool get isLoading => _isLoading;

  Future<void> fetchVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(user.uid).get();
      if (doc.exists) {
        _vendorData = doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching vendor data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVendorProfile(Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('vendors').doc(user.uid).update(updates);
      if (_vendorData != null) {
        _vendorData!.addAll(updates);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating vendor profile: $e');
    }
  }

  Future<void> addService(String serviceId, Map<String, dynamic> serviceInfo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Assuming 'enabledServices' is a List of Maps in the actual vendor doc,
      // or just a List of IDs. Let's assume it's a List of Maps for detailed pricing.
      // But the RegistrationProvider has List<String>.
      // Let's stick with List<String> for now, but in the dashboard we might want more.
      
      List<dynamic> services = _vendorData?['enabledServices'] ?? [];
      if (!services.contains(serviceId)) {
        services.add(serviceId);
        await updateVendorProfile({'enabledServices': services});
      }
    } catch (e) {
       debugPrint('Error adding service: $e');
    }
  }

  Future<void> removeService(String serviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      List<dynamic> services = _vendorData?['enabledServices'] ?? [];
      services.remove(serviceId);
      await updateVendorProfile({'enabledServices': services});
    } catch (e) {
       debugPrint('Error removing service: $e');
    }
  }

  Stream<QuerySnapshot> streamAvailableServices() {
    final categoryIds = _vendorData?['selectedCategoryIds'] as List<dynamic>? ?? [];
    if (categoryIds.isEmpty) {
      return const Stream.empty();
    }
    // We can't easily filter by array-contains in a stream if there are multiple,
    // so we fetch all and filter in UI or use a better query if IDs are few.
    // For now, fetch all services and we will filter in the UI based on categoryId.
    return FirebaseFirestore.instance.collection('services').snapshots();
  }

  Future<void> requestNewCategory(String categoryName, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('category_requests').add({
        'vendorId': user.uid,
        'vendorName': _vendorData?['name'] ?? 'Unknown Vendor',
        'businessName': _vendorData?['businessName'] ?? 'No Business Name',
        'categoryName': categoryName,
        'description': description,
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error requesting new category: $e');
    }
  }

  Stream<QuerySnapshot> streamVendorReviews() {
     final user = FirebaseAuth.instance.currentUser;
     if (user == null) return const Stream.empty();
     
     return FirebaseFirestore.instance
        .collection('reviews')
        .where('vendorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> syncRating() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('vendorId', isEqualTo: user.uid)
        .get();

    if (reviews.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in reviews.docs) {
      totalRating += (doc.data()['rating'] ?? 0).toDouble();
    }

    final avgRating = totalRating / reviews.docs.length;
    
    await updateVendorProfile({
      'rating': double.parse(avgRating.toStringAsFixed(1)),
      'reviewsCount': reviews.docs.length,
    });
  }
}
