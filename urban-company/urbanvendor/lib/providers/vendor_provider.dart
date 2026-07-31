import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorProvider extends ChangeNotifier {
  Map<String, dynamic>? vendorData;

  void fetchVendorDataRealtime() {
    final email = FirebaseAuth.instance.currentUser?.email;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final targetId = email ?? uid;
    
    if (targetId != null) {
      FirebaseFirestore.instance
          .collection('vendors')
          .doc(targetId)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          vendorData = doc.data() as Map<String, dynamic>;
          notifyListeners();
        }
      });
    }
  }
}
