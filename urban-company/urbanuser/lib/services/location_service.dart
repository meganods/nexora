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

  /// Reverse geocode coordinates to detailed address result
  /// Uses multi-stage lookup (BigDataCloud + OpenStreetMap + Postal API + regional tehsil resolvers)
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
          final pCity = p.locality ?? p.subAdministrativeArea ?? '';
          if (pCity.isNotEmpty && pCity.toLowerCase() != 'dadri') {
            city = pCity;
          }
          state = p.administrativeArea ?? '';
          pincode = p.postalCode ?? '';
          
          buildingName = p.name != null && p.name != houseNumber && p.name != street ? p.name! : '';
          
          fullAddr = [houseNumber, buildingName, street, area, city, state, pincode]
              .where((element) => element.isNotEmpty)
              .join(', ');
        }
      } catch (e) {
        debugPrint("Native geocoding note: $e");
      }
    }

    // 2. Try BigDataCloud Reverse Geocoding API (Fast and precise for Indian cities & pincodes)
    try {
      final bdcUrl = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en');
      final bdcResp = await http.get(bdcUrl).timeout(const Duration(seconds: 4));
      if (bdcResp.statusCode == 200) {
        final bdcData = json.decode(bdcResp.body);
        
        final bdcCity = (bdcData['city'] ?? bdcData['locality'] ?? '').toString();
        final bdcState = (bdcData['principalSubdivision'] ?? '').toString();
        final bdcPincode = (bdcData['postcode'] ?? '').toString();
        final bdcLocality = (bdcData['locality'] ?? '').toString();

        if (city.isEmpty && bdcCity.isNotEmpty && bdcCity.toLowerCase() != 'dadri') {
          city = bdcCity;
        }

        if (bdcData['localityInfo'] != null && bdcData['localityInfo']['administrative'] != null) {
          final adminList = bdcData['localityInfo']['administrative'] as List<dynamic>;
          for (var item in adminList) {
            final name = (item['name'] ?? '').toString();
            if (name == 'Greater Noida' || name == 'Noida' || name == 'Ghaziabad' || name == 'Delhi' || name == 'Gurugram') {
              city = name;
              break;
            }
          }
        }

        if (state.isEmpty && bdcState.isNotEmpty) state = bdcState;
        if (pincode.isEmpty && bdcPincode.isNotEmpty) pincode = bdcPincode;
        if (area.isEmpty && bdcLocality.isNotEmpty) area = bdcLocality;
      }
    } catch (e) {
      debugPrint("BigDataCloud geocoding note: $e");
    }

    // 3. Try OpenStreetMap Nominatim Reverse Geocoding API
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'NexoraHomeServicesApp/1.0',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};

        if (houseNumber.isEmpty) houseNumber = address['house_number'] ?? address['flat'] ?? '';
        if (buildingName.isEmpty) buildingName = address['building'] ?? address['apartments'] ?? address['amenity'] ?? '';
        if (street.isEmpty) street = address['road'] ?? address['pedestrian'] ?? '';

        final nomArea = address['suburb'] ?? address['neighbourhood'] ?? address['residential'] ?? address['quarter'] ?? '';
        if (area.isEmpty && nomArea.isNotEmpty) area = nomArea;

        final nomCity = address['city'] ?? address['town'] ?? address['city_district'] ?? address['municipality'] ?? '';
        if (city.isEmpty && nomCity.isNotEmpty && nomCity.toLowerCase() != 'dadri') {
          city = nomCity;
        }

        if (state.isEmpty) state = address['state'] ?? address['state_district'] ?? '';
        if (pincode.isEmpty) pincode = address['postcode'] ?? '';

        if (fullAddr.isEmpty) fullAddr = data['display_name'] ?? '';
      }
    } catch (e) {
      debugPrint("Nominatim geocoding note: $e");
    }

    // 4. India Post Pincode API lookup if pincode is 6-digit
    if (pincode.isNotEmpty && pincode.length >= 6) {
      final cleanPin = pincode.replaceAll(RegExp(r'\D'), '');
      if (cleanPin.length == 6) {
        try {
          final pinUrl = Uri.parse('https://api.postalpincode.in/pincode/$cleanPin');
          final pinResp = await http.get(pinUrl).timeout(const Duration(seconds: 3));
          if (pinResp.statusCode == 200) {
            final pinData = json.decode(pinResp.body);
            if (pinData is List && pinData.isNotEmpty && pinData[0]['Status'] == 'Success') {
              final postOffices = pinData[0]['PostOffice'] as List<dynamic>;
              if (postOffices.isNotEmpty) {
                final po = postOffices.first;
                final district = (po['District'] ?? '').toString();
                final block = (po['Block'] ?? '').toString();
                final stateName = (po['State'] ?? '').toString();

                if (district == 'Gautam Buddha Nagar' || block == 'Greater Noida' || block == 'Noida') {
                  city = 'Greater Noida';
                } else if (district.isNotEmpty && (city.isEmpty || city.toLowerCase() == 'dadri')) {
                  city = district;
                }

                if (state.isEmpty && stateName.isNotEmpty) state = stateName;
              }
            }
          }
        } catch (_) {}
      }
    }

    // 5. Special Tehsil & Regional City Overrides (e.g. Dadri -> Greater Noida for Noida Extension)
    if (city.isEmpty || city.toLowerCase() == 'dadri') {
      if (pincode == '201318' || pincode == '201306' || pincode == '201308' || pincode == '201310' || pincode == '201301') {
        city = 'Greater Noida';
      } else if (pincode.startsWith('2013')) {
        city = 'Noida';
      } else if (pincode.startsWith('2010')) {
        city = 'Ghaziabad';
      } else if (pincode.startsWith('1100')) {
        city = 'New Delhi';
      } else if (pincode.startsWith('1220')) {
        city = 'Gurugram';
      } else {
        city = 'Greater Noida';
      }
    }

    if (state.isEmpty) state = 'Uttar Pradesh';
    if (pincode.isEmpty) pincode = '201318';

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
