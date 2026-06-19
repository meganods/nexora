class ServiceModel {
  final String id;
  final String title;
  final String category;
  final String subCategory;
  final String price;
  final int discountPercent;
  final double rating;
  final int totalReviews;
  final String vendorName;
  final String image;
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
    required this.category,
    required this.subCategory,
    required this.price,
    required this.discountPercent,
    required this.rating,
    required this.totalReviews,
    required this.vendorName,
    required this.image,
    required this.images,
    required this.shortDescription,
    required this.description,
    required this.longDescription,
    required this.duration,
    required this.isAvailable,
    required this.location,
    required this.tags,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      price: json['price'] ?? '',
      discountPercent: json['discountPercent'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      vendorName: json['vendorName'] ?? '',
      image: json['image'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      shortDescription: json['shortDescription'] ?? json['description'] ?? '',
      description: json['description'] ?? json['shortDescription'] ?? '',
      longDescription: json['longDescription'] ?? json['description'] ?? '',
      duration: json['duration'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      location: json['location'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  factory ServiceModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      price: data['price'] ?? '',
      discountPercent: data['discountPercent'] ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] ?? 0,
      vendorName: data['vendorName'] ?? '',
      image: data['image'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      shortDescription: data['shortDescription'] ?? data['description'] ?? '',
      description: data['description'] ?? data['shortDescription'] ?? '',
      longDescription: data['longDescription'] ?? data['description'] ?? '',
      duration: data['duration'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      location: data['location'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
}
