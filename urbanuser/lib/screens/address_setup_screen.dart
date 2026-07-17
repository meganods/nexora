import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class AddressSetupScreen extends StatefulWidget {
  const AddressSetupScreen({super.key});

  @override
  State<AddressSetupScreen> createState() => _AddressSetupScreenState();
}

class _AddressSetupScreenState extends State<AddressSetupScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(28.6139, 77.2090); // Default: New Delhi
  
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _houseController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String _addressType = "Home";
  String? _nameError;
  String? _mobileError;
  String? _houseError;
  String? _buildingError;
  String? _streetError;
  String? _cityError;
  String? _stateError;
  String? _pincodeError;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndLocation();
  }

  Future<void> _loadUserDataAndLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('userAddress');
    
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
      _mobileController.text = prefs.getString('userMobile') ?? '';
    });

    if (savedAddress != null && savedAddress.trim().isNotEmpty) {
      setState(() {
        _houseController.text = prefs.getString('userAddressHouse') ?? '';
        _buildingController.text = prefs.getString('userAddressBuilding') ?? '';
        _streetController.text = prefs.getString('userAddressStreet') ?? '';
        _landmarkController.text = prefs.getString('userAddressLandmark') ?? '';
        _cityController.text = prefs.getString('userCity') ?? '';
        _stateController.text = prefs.getString('userState') ?? '';
        _pincodeController.text = prefs.getString('userPincode') ?? '';
        _addressType = prefs.getString('userAddressType') ?? 'Home';
      });
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackToIpLocation();
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackToIpLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackToIpLocation();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation, 15.0);
      });
      _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      _fallbackToIpLocation();
    }
  }

  Future<void> _fallbackToIpLocation() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final lat = data['lat'];
          final lon = data['lon'];
          setState(() {
            _currentLocation = LatLng(lat, lon);
            _mapController.move(_currentLocation, 15.0);
          });
          _reverseGeocode(lat, lon);
        }
      }
    } catch (e) {
      debugPrint("IP fallback failed: $e");
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _buildingController.text = p.name ?? p.subLocality ?? "";
          _streetController.text = p.street ?? p.thoroughfare ?? "";
          _cityController.text = p.locality ?? p.subAdministrativeArea ?? "";
          _stateController.text = p.administrativeArea ?? "";
          _pincodeController.text = p.postalCode ?? "";
        });
      }
    } catch (e) {
      debugPrint("Geocoding error: $e. Falling back to Nominatim.");
      _fallbackReverseGeocode(lat, lon);
    }
  }

  Future<void> _fallbackReverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      final response = await http.get(url, headers: {'User-Agent': 'UrbanCompanyCloneApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          
          String stateDistrict = address['state_district'] ?? "";
          String postcode = address['postcode'] ?? "";
          String city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['village'] ?? address['city_district'] ?? address['county'] ?? "";
          
          // Map Gautambudh Nagar / Dadri to Noida/Greater Noida based on postcode
          if (stateDistrict.contains("Gautam Buddha") || stateDistrict.contains("Gautam Budh") || city == "Dadri") {
            if (postcode.startsWith("201318") || postcode.startsWith("201308") || postcode.startsWith("201310")) {
              city = "Greater Noida";
            } else if (postcode.startsWith("2013")) {
              city = "Noida";
            }
          }
          
          String street = address['road'] ?? address['neighbourhood'] ?? address['suburb'] ?? "";
          if (street.isEmpty || street == "Dadri") {
            final parts = data['display_name']?.toString().split(',') ?? [];
            if (parts.isNotEmpty) {
              final firstPart = parts.first.trim();
              if (firstPart != city && firstPart != stateDistrict && firstPart != address['state'] && firstPart != address['country']) {
                street = firstPart;
              }
            }
          }
          
          setState(() {
            _buildingController.text = address['building'] ?? address['house_number'] ?? address['amenity'] ?? "";
            _streetController.text = street;
            _cityController.text = city;
            _stateController.text = address['state'] ?? "";
            _pincodeController.text = postcode;
          });
        }
      }
    } catch (e) {
      debugPrint("Nominatim Geocoding error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch address. Please enter manually.')));
      }
    }
  }

  void _saveAddress() async {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? "Full Name is required" : null;
      _mobileError = _mobileController.text.trim().isEmpty ? "Mobile Number is required" : null;
      _houseError = _houseController.text.trim().isEmpty ? "House / Flat Number is required" : null;
      _buildingError = _buildingController.text.trim().isEmpty ? "Building / Society Name is required" : null;
      _streetError = _streetController.text.trim().isEmpty ? "Street / Area is required" : null;
      _cityError = _cityController.text.trim().isEmpty ? "City is required" : null;
      _stateError = _stateController.text.trim().isEmpty ? "State is required" : null;
      _pincodeError = _pincodeController.text.trim().isEmpty ? "Pincode is required" : null;
    });

    if (_nameError != null ||
        _mobileError != null ||
        _houseError != null ||
        _buildingError != null ||
        _streetError != null ||
        _cityError != null ||
        _stateError != null ||
        _pincodeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Simulate saving user address locally to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userAddress', "${_houseController.text}, ${_buildingController.text}, ${_streetController.text}");
    await prefs.setString('userAddressHouse', _houseController.text);
    await prefs.setString('userAddressBuilding', _buildingController.text);
    await prefs.setString('userAddressStreet', _streetController.text);
    await prefs.setString('userAddressLandmark', _landmarkController.text);
    await prefs.setString('userCity', _cityController.text);
    await prefs.setString('userState', _stateController.text);
    await prefs.setString('userPincode', _pincodeController.text);
    await prefs.setString('userAddressType', _addressType);
    
    String fullMobile = _mobileController.text;
    if (fullMobile.isNotEmpty && !fullMobile.startsWith('+91')) {
      // Remove leading 0 if any, then add +91
      if (fullMobile.startsWith('0')) {
        fullMobile = fullMobile.substring(1);
      }
      fullMobile = '+91$fullMobile';
    }
    await prefs.setString('userMobile', fullMobile);
    await prefs.setString('userName', _nameController.text.trim());

    // Save profile and address data to Firestore
    final email = prefs.getString('userEmail');
    if (email != null && email.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(email).set({
          'name': _nameController.text.trim(),
          'phone': fullMobile,
          'email': email,
          'userAddress': "${_houseController.text}, ${_buildingController.text}, ${_streetController.text}",
          'userAddressHouse': _houseController.text,
          'userAddressBuilding': _buildingController.text,
          'userAddressStreet': _streetController.text,
          'userAddressLandmark': _landmarkController.text,
          'userCity': _cityController.text,
          'userState': _stateController.text,
          'userPincode': _pincodeController.text,
          'userAddressType': _addressType,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating profile and address to Firestore: $e");
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address Saved Successfully!'), backgroundColor: Colors.green));
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Setup Address", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        setState(() => _currentLocation = point);
                        _reverseGeocode(point.latitude, point.longitude);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.urbanuser.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(point: _currentLocation, width: 80, height: 80, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 15,
                    bottom: 15,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Personal Details", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputField("Full Name", _nameController, errorText: _nameError),
                  const SizedBox(height: 12),
                  _buildInputField("Mobile Number", _mobileController, errorText: _mobileError),
                  const SizedBox(height: 24),
                  
                  Text("Address Details", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputField("House / Flat Number", _houseController, errorText: _houseError),
                  const SizedBox(height: 12),
                  _buildInputField("Building / Society Name", _buildingController, errorText: _buildingError),
                  const SizedBox(height: 12),
                  _buildInputField("Street / Area", _streetController, errorText: _streetError),
                  const SizedBox(height: 12),
                  _buildInputField("Landmark (Optional)", _landmarkController),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(child: _buildInputField("City *", _cityController, errorText: _cityError)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInputField("State *", _stateController, errorText: _stateError)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInputField("Pincode *", _pincodeController, errorText: _pincodeError),
                  const SizedBox(height: 24),
                  
                  Text("Address Type", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTypeChip("Home", Icons.home),
                      const SizedBox(width: 12),
                      _buildTypeChip("Work", Icons.work),
                      const SizedBox(width: 12),
                      _buildTypeChip("Other", Icons.location_on),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      child: Text("Save & Continue", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeChip(String label, IconData icon) {
    bool isSelected = _addressType == label;
    return GestureDetector(
      onTap: () => setState(() => _addressType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.outfit(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? errorText}) {
    bool isMobile = label == "Mobile Number";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isMobile ? TextInputType.phone : TextInputType.text,
            style: GoogleFonts.outfit(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              errorText: errorText,
              prefixIcon: isMobile
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("🇮🇳", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            "+91",
                            style: GoogleFonts.outfit(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
