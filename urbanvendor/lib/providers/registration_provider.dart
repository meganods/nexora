import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationProvider with ChangeNotifier {
  // Profile Info
  String name = "";
  String email = "";
  String businessName = "";
  String experience = "";
  String businessBio = "";
  String password = "";
  String phoneNumber = "";
  
  // Category & Services
  List<String> selectedCategoryIds = [];
  List<String> enabledServices = [];
  List<String> enabledServiceNames = [];
  
  // Locality & Pricing
  double baseRate = 0.0;
  int serviceRadius = 25;
  String address = "";
  String city = "";
  String pincode = "";
  
  // Availability
  List<String> availableDays = [];
  List<String> timeSlots = [];
  
  // Documents (URLs or paths)
  List<Map<String, String>> documents = [];

  // Tracking progress
  String currentStep = "/create_profile";
  dynamic createdAt;

  void fromMap(Map<String, dynamic> data) {
    name = data['name'] ?? "";
    email = data['email'] ?? "";
    businessName = data['businessName'] ?? "";
    experience = data['experience'] ?? "";
    businessBio = data['businessBio'] ?? "";
    phoneNumber = data['phoneNumber'] ?? "";
    selectedCategoryIds = List<String>.from(data['selectedCategoryIds'] ?? []);
    enabledServices = List<String>.from(data['enabledServices'] ?? []);
    enabledServiceNames = List<String>.from(data['enabledServiceNames'] ?? []);
    baseRate = (data['baseRate'] ?? 0.0).toDouble();
    serviceRadius = data['serviceRadius'] ?? 25;
    address = data['address'] ?? "";
    city = data['city'] ?? "";
    pincode = data['pincode'] ?? "";
    availableDays = List<String>.from(data['availableDays'] ?? []);
    timeSlots = List<String>.from(data['timeSlots'] ?? []);
    documents = List<Map<String, String>>.from(
      (data['documents'] ?? []).map((e) => Map<String, String>.from(e))
    );
    currentStep = data['currentStep'] ?? "/create_profile";
    createdAt = data['createdAt'];
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'businessName': businessName,
      'experience': experience,
      'businessBio': businessBio,
      'phoneNumber': phoneNumber,
      'selectedCategoryIds': selectedCategoryIds,
      'enabledServices': enabledServices,
      'enabledServiceNames': enabledServiceNames,
      'baseRate': baseRate,
      'serviceRadius': serviceRadius,
      'address': address,
      'city': city,
      'pincode': pincode,
      'availableDays': availableDays,
      'timeSlots': timeSlots,
      'documents': documents,
      'currentStep': currentStep,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'status': 'PENDING_REGISTRATION',
    };
  }
}
