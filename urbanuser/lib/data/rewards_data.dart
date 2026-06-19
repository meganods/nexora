import 'package:flutter/material.dart';

class RewardsData {
  static List<Map<String, dynamic>> availableRewards = [
    {
      "id": "1",
      "code": "FLAT10",
      "title": "Flat 10% Off",
      "description": "Get 10% off on your total booking.",
      "expiry": "Expires in 2 days",
      "color": const Color(0xFF673AB7),
      "icon": Icons.local_offer,
      "discountPercent": 10.0,
      "discountAmount": null,
    },
    {
      "id": "2",
      "code": "SAVE200",
      "title": "₹200 Voucher",
      "description": "Get a flat ₹200 discount on your booking.",
      "expiry": "Expires in 5 days",
      "color": const Color(0xFFFFD700),
      "icon": Icons.card_giftcard,
      "discountPercent": null,
      "discountAmount": 200.0,
    },
    {
      "id": "3",
      "code": "CLEAN15",
      "title": "15% Off Cleaning",
      "description": "Get 15% off on all cleaning services.",
      "expiry": "Expires in 10 days",
      "color": const Color(0xFF00BFA5),
      "icon": Icons.cleaning_services,
      "discountPercent": 15.0,
      "discountAmount": null,
    },
  ];

  static List<Map<String, dynamic>> claimedCoupons = [];
}
