import '../models/service_model.dart';
import 'package:flutter/material.dart';

class CategoryItem {
  final String title;
  final String imagePath;
  const CategoryItem({required this.title, required this.imagePath});
}

class DummyData {
  static const List<CategoryItem> homeCategories = [
    CategoryItem(title: "Cleaning", imagePath: "assets/images/categories/cleaner_icon_1774853550305.png"),
    CategoryItem(title: "Plumbing", imagePath: "assets/images/categories/plumber_icon_1774853426358.png"),
    CategoryItem(title: "Laundry", imagePath: "assets/images/categories/laundry_icon_1774853512710.png"),
    CategoryItem(title: "Car Wash", imagePath: "assets/images/car_wash_banner_illustration_1774854072344.png"), // fallback
    CategoryItem(title: "Painting", imagePath: "assets/images/categories/painter_icon_1774853496361.png"),
    CategoryItem(title: "Electrician", imagePath: "assets/images/categories/electrician_icon_1774853479339.png"),
    CategoryItem(title: "Mechanic", imagePath: "assets/images/categories/mechanic_icon_1774853532535.png"),
    CategoryItem(title: "Carpenter", imagePath: "assets/images/categories/carpenter_icon_1774853442272.png"),
  ];

  static const List<CategoryItem> allCategories = [
    CategoryItem(title: "Plumber", imagePath: "assets/images/categories/plumber_icon_1774853426358.png"),
    CategoryItem(title: "Carpenter", imagePath: "assets/images/categories/carpenter_icon_1774853442272.png"),
    CategoryItem(title: "Welder", imagePath: "assets/images/categories/welder_icon_1774853460487.png"),
    CategoryItem(title: "Contactor", imagePath: "assets/images/categories/contactor_icon_1774853573965.png"),
    CategoryItem(title: "Electrician", imagePath: "assets/images/categories/electrician_icon_1774853479339.png"),
    CategoryItem(title: "Painter", imagePath: "assets/images/categories/painter_icon_1774853496361.png"),
    CategoryItem(title: "Laundry", imagePath: "assets/images/categories/laundry_icon_1774853512710.png"),
    CategoryItem(title: "Mechanic", imagePath: "assets/images/categories/mechanic_icon_1774853532535.png"),
    CategoryItem(title: "Cleaner", imagePath: "assets/images/categories/cleaner_icon_1774853550305.png"),
    CategoryItem(title: "AC Detail", imagePath: "assets/images/categories/ac_repair.png"),
    CategoryItem(title: "Gardening", imagePath: "assets/images/house_cleaning_demo_1774854111518.png"), // fallback
    CategoryItem(title: "Car Wash", imagePath: "assets/images/car_wash_banner_illustration_1774854072344.png"), // fallback
  ];

  static final List<Map<String, dynamic>> topVendors = [
    {"name": "Apex Cleaners", "tasks": "1.2k Tasks", "color": 0xFFE3F2FD},
    {"name": "Elite Repairs", "tasks": "850 Tasks", "color": 0xFFFFF3E0},
    {"name": "Swift Mechanic", "tasks": "2k Tasks", "color": 0xFFE8F5E9},
    {"name": "Alpha Painters", "tasks": "1k Tasks", "color": 0xFFFCE4EC},
  ];

  static final List<Map<String, dynamic>> newServices = [
    {"title": "Exterior Cleaning", "color": 0xFF00796B},
    {"title": "Garden Grooming", "color": 0xFF00897B},
    {"title": "Special Plumber", "color": 0xFF26A69A},
  ];

  static final List<Map<String, dynamic>> specialOffers = [
    {"title": "Free Inspection", "subtitle": "Valid till Oct 2026", "color": 0xFFFFF9C4},
    {"title": "Coupon Apply", "subtitle": "Valid till Oct 2026", "color": 0xFFE0F7FA},
  ];

  static final List<Map<String, dynamic>> trendingServices = [
    {"title": "Sofa Cleaning", "icon": Icons.chair_alt, "color": 0xFFE1F5FE},
    {"title": "Deep Repair", "icon": Icons.build, "color": 0xFFFFF3E0},
  ];

  static final List<Map<String, dynamic>> reviews = [
    {'rating': 5, 'comment': "Excellent service and very professional handyman. Saved me a lot of time!", 'userName': "User 1"},
    {'rating': 5, 'comment': "Excellent service and very professional handyman. Saved me a lot of time!", 'userName': "User 2"},
    {'rating': 5, 'comment': "Excellent service and very professional handyman. Saved me a lot of time!", 'userName': "User 3"},
  ];

  static List<ServiceModel> get allServices => [
    // Best In Your City
    ServiceModel(
      id: "bc-1",
      title: "Luxury Sofa Spa",
      category: "Cleaning",
      subCategory: "Top Rated",
      price: "₹120",
      discountPercent: 0,
      rating: 4.9,
      totalReviews: 1240,
      vendorName: "Sparkle Cleaners",
      image: "https://images.unsplash.com/photo-1563298723-dcfebaa392e3?q=80&w=300&auto=format&fit=crop",
      images: [
        "https://images.unsplash.com/photo-1563298723-dcfebaa392e3?q=80&w=600&auto=format&fit=crop",
      ],
      shortDescription: "Premium sofa deep cleaning service.",
      description: "Premium sofa deep cleaning service.",
      longDescription: "Our expert team uses specialized suction machines...",
      duration: "2 hours",
      isAvailable: true,
      location: "Local",
      tags: ["trusted", "premium"],
    ),
    ServiceModel(
      id: "bc-2",
      title: "Full Home Paint",
      category: "Painting",
      subCategory: "Certified",
      price: "₹999",
      discountPercent: 0,
      rating: 4.8,
      totalReviews: 850,
      vendorName: "Color Masters",
      image: "assets/images/onboarding_1_handyman_illustration_1774853199914.png",
      images: ["assets/images/onboarding_1_handyman_illustration_1774853199914.png"],
      shortDescription: "Professional interior wall painting.",
      description: "Professional interior wall painting.",
      longDescription: "Get a fresh look for your home...",
      duration: "3-5 days",
      isAvailable: true,
      location: "Local",
      tags: ["verified", "professional"],
    ),
    ServiceModel(
      id: "bc-3",
      title: "Express Car Wash",
      category: "Car Wash",
      subCategory: "Certified",
      price: "₹45",
      discountPercent: 0,
      rating: 4.8,
      totalReviews: 850,
      vendorName: "Wash Masters",
      image: "assets/images/car_wash_banner_illustration_1774854072344.png",
      images: ["assets/images/car_wash_banner_illustration_1774854072344.png"],
      shortDescription: "Professional car washing.",
      description: "Professional car washing.",
      longDescription: "Get a fresh look for your car...",
      duration: "1 day",
      isAvailable: true,
      location: "Local",
      tags: ["verified"],
    ),
    // Recommended
    ServiceModel(
      id: "r1",
      title: "Kitchen Cleaning",
      image: "https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=720&auto=format&fit=crop",
      images: ["https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=720&auto=format&fit=crop"],
      category: "Cleaning",
      subCategory: "Recommended",
      price: "₹150",
      discountPercent: 20,
      rating: 4.7,
      totalReviews: 45,
      vendorName: "Shiny Kitchens",
      shortDescription: "Professional kitchen cleaning",
      description: "Professional kitchen cleaning",
      longDescription: "Complete kitchen deep cleaning and degreasing.",
      duration: "3 hrs",
      isAvailable: true,
      location: "Local",
      tags: ["recommended", "cleaning"],
    ),
    ServiceModel(
      id: "r2",
      title: "House Cleaning",
      image: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=720&auto=format&fit=crop",
      images: ["https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=720&auto=format&fit=crop"],
      category: "Cleaning",
      subCategory: "Recommended",
      price: "₹150",
      discountPercent: 20,
      rating: 4.7,
      totalReviews: 45,
      vendorName: "Shiny House",
      shortDescription: "Professional house cleaning",
      description: "Professional house cleaning",
      longDescription: "Complete house deep cleaning.",
      duration: "3 hrs",
      isAvailable: true,
      location: "Local",
      tags: ["recommended", "cleaning"],
    ),
    ...["Plumbing", "Laundry", "Electrician", "Mechanic", "Carpenter", "Plumber", "Welder", "Contactor", "AC Detail", "Gardening", "Cleaner", "Painter"].expand((c) => [
      _fallbackService(c, "Premium $c Service", "499", 4.8),
      _fallbackService(c, "Standard $c Service", "299", 4.5),
      _fallbackService(c, "Express $c Service", "599", 4.9),
      _fallbackService(c, "Basic $c Service", "199", 4.2),
    ]),
  ];

  static String _getImageForCategory(String cat) {
    if (cat.contains("Plumb")) return "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Laundry")) return "https://images.unsplash.com/photo-1545173168-9f1947eebb7f?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Electric")) return "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Mechanic")) return "https://images.unsplash.com/photo-1619642751056-25f4fb49e8eb?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Carpent")) return "https://images.unsplash.com/photo-1540569014015-19a7be504e3a?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Paint")) return "https://images.unsplash.com/photo-1562259949-e8e7689d7828?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Clean")) return "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Garden")) return "https://images.unsplash.com/photo-1416879598555-141687959855?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("AC")) return "https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=720&auto=format&fit=crop";
    if (cat.contains("Weld")) return "https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?q=80&w=720&auto=format&fit=crop";
    return "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=720&auto=format&fit=crop";
  }

  static ServiceModel _fallbackService(String cat, String title, String price, double rating) {
    final String imageUrl = _getImageForCategory(cat);
    return ServiceModel(
      id: "fb-$cat-$price",
      title: title,
      category: cat,
      subCategory: "Top Rated",
      price: "₹$price",
      discountPercent: 10,
      rating: rating,
      totalReviews: (rating * 30).toInt(),
      vendorName: "Pro $cat",
      image: imageUrl,
      images: [imageUrl],
      shortDescription: "Professional $cat service.",
      description: "Expert and reliable $cat service for your needs.",
      longDescription: "We provide top-notch $cat services with verified professionals.",
      duration: "1-2 hrs",
      isAvailable: true,
      location: "Local",
      tags: ["expert", "verified"],
    );
  }

  static List<ServiceModel> getBySection(String section) {
    switch (section) {
      case "Best In Your City":
        return allServices.where((s) => s.id.startsWith("bc")).toList();
      case "Recommended":
        return allServices.where((s) => s.id.startsWith("r")).toList();
      default:
        return allServices;
    }
  }

  static List<ServiceModel> getByCategory(String category) {
    return allServices.where((s) => s.category == category).toList();
  }
}
