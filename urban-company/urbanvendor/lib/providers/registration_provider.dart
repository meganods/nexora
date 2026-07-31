import 'package:flutter/material.dart';

class RegistrationProvider extends ChangeNotifier {
  String name = '';
  String email = '';
  String businessBio = '';
  List<String> selectedCategoryIds = [];
  List<String> enabledServiceNames = [];
  double baseRate = 0.0;
  double serviceRadius = 0.0;
  String address = '';
  String currentStep = '';



  void fromMap(Map<String, dynamic> data) {
    name = data['name'] ?? data['businessName'] ?? '';
    email = data['email'] ?? '';
    businessBio = data['businessBio'] ?? data['bio'] ?? '';
    if (data['selectedCategoryIds'] is List) {
      selectedCategoryIds = List<String>.from(data['selectedCategoryIds']);
    }
    if (data['enabledServiceNames'] is List) {
      enabledServiceNames = List<String>.from(data['enabledServiceNames']);
    }
    baseRate = (data['baseRate'] ?? 0.0).toDouble();
    serviceRadius = (data['serviceRadius'] ?? 0.0).toDouble();
    address = data['address'] ?? '';
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'businessBio': businessBio,
      'selectedCategoryIds': selectedCategoryIds,
      'enabledServiceNames': enabledServiceNames,
      'baseRate': baseRate,
      'serviceRadius': serviceRadius,
      'address': address,
    };
  }
}
