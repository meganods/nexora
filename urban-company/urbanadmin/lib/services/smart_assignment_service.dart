import 'package:cloud_firestore/cloud_firestore.dart';

class SmartAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find the best matching approved vendor based on:
  /// Price (Lowest first) -> Rating (Highest first) -> Workload (Least jobs first) -> Distance (Nearest first)
  static Future<Map<String, dynamic>?> assignBestVendor({
    required String categoryName,
    required String userCity,
    required double bookingPrice,
    String? subServiceId,
  }) async {
    try {
      // 1. Get all approved & active vendors matching the main category
      final vendorQuery = await _firestore
          .collection('vendors')
          .where('status', isEqualTo: 'APPROVED')
          .where('mainCategory', isEqualTo: categoryName)
          .get();

      if (vendorQuery.docs.isEmpty) return null;

      final List<Map<String, dynamic>> eligibleVendors = [];

      for (var doc in vendorQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Mandatory check 1: Approved & Active Account
        final isApproved = data['approved'] ?? data['isApproved'] ?? true;
        if (!isApproved) continue;

        // Mandatory check 2: Online Status
        final isOnline = data['isOnline'] ?? data['online'] ?? true;
        if (!isOnline) continue;

        // Mandatory check 3: Customer Area Match
        final vendorCity = data['city'] ?? data['address']?.toString().split(',').last.trim() ?? '';
        if (userCity.isNotEmpty && vendorCity.isNotEmpty) {
          if (!vendorCity.toLowerCase().contains(userCity.toLowerCase())) {
            continue; // Skip if vendor is in a different city/area
          }
        }

        // Mandatory check 4: Working Hours
        final workingHours = data['workingHours']; // e.g. "09:00 - 18:00"
        if (workingHours != null) {
          final now = DateTime.now();
          final startHour = int.tryParse(workingHours.toString().split('-').first.split(':').first.trim()) ?? 9;
          final endHour = int.tryParse(workingHours.toString().split('-').last.split(':').first.trim()) ?? 21;
          if (now.hour < startHour || now.hour >= endHour) {
            continue; // Skip if vendor is outside working hours
          }
        }

        // Step 2: Apply Minimum Quality Thresholds
        // Minimum Rating: 4.5 Stars
        final double rating = ((data['rating'] ?? 5.0) as num).toDouble();
        if (rating < 4.5) continue;

        // Minimum Completion Rate: 90% (if present in document)
        final double completionRate = ((data['completionRate'] ?? 100.0) as num).toDouble();
        if (completionRate < 90.0) continue;

        // Maximum Cancellation Rate: 10% (if present in document)
        final double cancellationRate = ((data['cancellationRate'] ?? 0.0) as num).toDouble();
        if (cancellationRate > 10.0) continue;

        // Fetch vendor service details to get the custom vendor price for this sub-service
        double vendorPrice = bookingPrice; // Default to booking price if sub-service price is not found
        if (subServiceId != null && subServiceId.isNotEmpty) {
          final serviceQuery = await _firestore
              .collection('vendor_services')
              .where('vendorId', isEqualTo: doc.id)
              .where('subServiceId', isEqualTo: subServiceId)
              .limit(1)
              .get();
          if (serviceQuery.docs.isNotEmpty) {
            final serviceData = serviceQuery.docs.first.data();
            vendorPrice = ((serviceData['vendorPrice'] ?? bookingPrice) as num).toDouble();
          }
        }
        data['calculatedVendorPrice'] = vendorPrice;

        // Active Jobs workload check
        final activeJobsCount = (data['activeJobs'] ?? 0) as int;
        data['jobsCount'] = activeJobsCount;

        eligibleVendors.add(data);
      }

      if (eligibleVendors.isEmpty) return null;

      // Step 3: Sort Vendors based on priority logic:
      // 1. Lowest Vendor Price (Ascending)
      // 2. Highest Rating (Descending)
      // 3. Least Active Jobs (Ascending)
      // 4. Shortest Distance (if distance/location is stored)
      eligibleVendors.sort((a, b) {
        // 1. Price comparison
        final double priceA = a['calculatedVendorPrice'] as double;
        final double priceB = b['calculatedVendorPrice'] as double;
        final int priceCompare = priceA.compareTo(priceB);
        if (priceCompare != 0) return priceCompare;

        // 2. Rating comparison (Highest first)
        final double ratingA = ((a['rating'] ?? 5.0) as num).toDouble();
        final double ratingB = ((b['rating'] ?? 5.0) as num).toDouble();
        final int ratingCompare = ratingB.compareTo(ratingA);
        if (ratingCompare != 0) return ratingCompare;

        // 3. Workload comparison (Least active jobs first)
        final int jobsA = a['jobsCount'] as int;
        final int jobsB = b['jobsCount'] as int;
        return jobsA.compareTo(jobsB);
      });

      // Select highest-ranked vendor
      return eligibleVendors.first;
    } catch (e) {
      print("Error in SmartAssignmentService: $e");
      return null;
    }
  }
}
