class ServiceModel {
  final String id;
  final String title;
  final double price;
  final String vendorId;
  final String image;
  final double rating;

  // Additional parameters for compatibility
  final String category;
  final String subCategory;
  final double discountPercent;
  final int totalReviews;
  final String vendorName;
  final List<String> images;
  final String shortDescription;
  final String description;
  final String longDescription;
  final String duration;
  final bool isAvailable;
  final String location;
  final List<String> tags;

  ServiceModel({
    required this.id,
    required this.title,
    required this.price,
    this.vendorId = '',
    this.image = '',
    this.rating = 5.0,
    this.category = '',
    this.subCategory = '',
    this.discountPercent = 0.0,
    this.totalReviews = 0,
    this.vendorName = '',
    this.images = const [],
    this.shortDescription = '',
    this.description = '',
    this.longDescription = '',
    this.duration = '',
    this.isAvailable = true,
    this.location = '',
    this.tags = const [],
  });

  String get name => title;
}
