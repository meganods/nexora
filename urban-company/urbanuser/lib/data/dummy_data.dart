import '../models/service_model.dart';

class DummyData {
  static const List<Map<String, dynamic>> reviews = [
    {
      'userName': 'Amit S.',
      'rating': 5,
      'comment': 'Amazing service, very clean and professional.',
    },
    {
      'userName': 'Priya K.',
      'rating': 4,
      'comment': 'Good behavior and punctuality. Cleaned up afterwards.',
    },
  ];

  static List<ServiceModel> getBySection(String section) {
    return [
      ServiceModel(
        id: '1',
        title: 'Salon at Home',
        rating: 4.9,
        price: 299,
        image: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=500',
      ),
      ServiceModel(
        id: '2',
        title: 'AC Repairing',
        rating: 4.8,
        price: 499,
        image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500',
      ),
    ];
  }

  static List<ServiceModel> getByCategory(String categoryName) {
    return getBySection(categoryName);
  }

  static const List<Map<String, dynamic>> topVendors = [
    {
      'name': 'Grooming Pro',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=500',
    }
  ];

  static const List<Map<String, dynamic>> allCategories = [
    {
      'title': 'Salon',
      'image': 'assets/images/banner1.png',
    }
  ];
}
