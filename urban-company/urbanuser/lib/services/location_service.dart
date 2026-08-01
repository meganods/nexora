import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressResult {
  final String houseNumber;
  final String buildingName;
  final String street;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String fullAddress;
  final LatLng location;

  AddressResult({
    this.houseNumber = '',
    this.buildingName = '',
    this.street = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.fullAddress = '',
    required this.location,
  });
}

class LocationService {
  /// Request location permissions and get live current position
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Reverse geocode coordinates to detailed address result (using native geocoding + Nominatim fallback)
  static Future<AddressResult> reverseGeocode(double lat, double lng) async {
    String houseNumber = '';
    String buildingName = '';
    String street = '';
    String area = '';
    String city = '';
    String state = '';
    String pincode = '';
    String fullAddr = '';

    // 1. Try Native Geocoding Package first if not Web
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          houseNumber = p.subThoroughfare ?? '';
          street = p.thoroughfare ?? '';
          area = p.subLocality ?? p.locality ?? '';
          city = p.locality ?? p.subAdministrativeArea ?? '';
          state = p.administrativeArea ?? '';
          pincode = p.postalCode ?? '';
          
          buildingName = p.name != null && p.name != houseNumber && p.name != street ? p.name! : '';
          
          fullAddr = [houseNumber, buildingName, street, area, city, state, pincode]
              .where((element) => element.isNotEmpty)
              .join(', ');
        }
      } catch (e) {
        debugPrint("Native geocoding error, trying fallback: $e");
      }
    }

    // 2. Fallback to OpenStreetMap Nominatim Reverse Geocoding API if empty or on Web
    if (fullAddr.isEmpty || city.isEmpty) {
      try {
        final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1');
        final response = await http.get(url, headers: {
          'User-Agent': 'NexoraHomeServicesApp/1.0',
        }).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final address = data['address'] as Map<String, dynamic>? ?? {};

          houseNumber = address['house_number'] ?? address['flat'] ?? '';
          buildingName = address['building'] ?? address['apartments'] ?? address['amenity'] ?? '';
          street = address['road'] ?? address['pedestrian'] ?? '';
          area = address['suburb'] ?? address['neighbourhood'] ?? address['residential'] ?? address['quarter'] ?? '';
          city = address['city'] ?? address['town'] ?? address['city_district'] ?? address['county'] ?? '';
          state = address['state'] ?? address['state_district'] ?? '';
          pincode = address['postcode'] ?? '';

          fullAddr = data['display_name'] ?? '';
        }
      } catch (e) {
        debugPrint("Nominatim geocoding error: $e");
      }
    }

    // If still empty, provide clean defaults
    if (city.isEmpty) city = 'New Delhi';
    if (state.isEmpty) state = 'Delhi';
    if (pincode.isEmpty) pincode = '110001';

    return AddressResult(
      houseNumber: houseNumber,
      buildingName: buildingName,
      street: street,
      area: area,
      city: city,
      state: state,
      pincode: pincode,
      fullAddress: fullAddr,
      location: LatLng(lat, lng),
    );
  }
}
