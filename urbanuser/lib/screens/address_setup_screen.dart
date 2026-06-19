import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('userName') ?? '';
      _mobileController.text = prefs.getString('userMobile') ?? '';
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentLocation, 15.0);
    });
    _reverseGeocode(position.latitude, position.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _streetController.text = p.street ?? "";
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
          setState(() {
            _streetController.text = address['road'] ?? address['neighbourhood'] ?? "";
            _cityController.text = address['city'] ?? address['town'] ?? address['county'] ?? "";
            _stateController.text = address['state'] ?? "";
            _pincodeController.text = address['postcode'] ?? "";
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
    if (_cityController.text.isEmpty || _stateController.text.isEmpty || _pincodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('City, State, and Pincode are required.'), backgroundColor: Colors.red));
      return;
    }
    
    // Simulate saving user address locally to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userAddress', "\${_houseController.text}, \${_buildingController.text}, \${_streetController.text}");
    await prefs.setString('userCity', _cityController.text);
    
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
                  _buildInputField("Full Name", _nameController),
                  const SizedBox(height: 12),
                  _buildInputField("Mobile Number", _mobileController),
                  const SizedBox(height: 24),
                  
                  Text("Address Details", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputField("House / Flat Number", _houseController),
                  const SizedBox(height: 12),
                  _buildInputField("Building / Society Name", _buildingController),
                  const SizedBox(height: 12),
                  _buildInputField("Street / Area", _streetController),
                  const SizedBox(height: 12),
                  _buildInputField("Landmark (Optional)", _landmarkController),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(child: _buildInputField("City *", _cityController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInputField("State *", _stateController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInputField("Pincode *", _pincodeController),
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

  Widget _buildInputField(String label, TextEditingController controller) {
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
            style: GoogleFonts.outfit(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
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
