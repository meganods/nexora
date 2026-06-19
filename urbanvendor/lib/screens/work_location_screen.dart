import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart';

class WorkLocationScreen extends StatefulWidget {
  const WorkLocationScreen({super.key});

  @override
  State<WorkLocationScreen> createState() => _WorkLocationScreenState();
}

class _WorkLocationScreenState extends State<WorkLocationScreen> {
  bool _useCurrentLocation = false;
  bool _isLoading = false;
  String? _city;
  String? _area;
  String? _fullAddress;

  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RegistrationProvider>(context, listen: false);
    _cityController.text = provider.city;
    _addressController.text = provider.address;
    _areaController.text = provider.pincode;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  final MapController _mapController = MapController();
  LatLng _selectedPosition = const LatLng(
    12.9716,
    77.5946,
  ); // Default: Bangalore

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      var status = await Permission.location.status;
      if (status.isPermanentlyDenied) {
        if (mounted) _showPermissionDialog();
        setState(() => _useCurrentLocation = false);
        return;
      }
      if (!status.isGranted) status = await Permission.location.request();

      if (status.isGranted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enable location services.')),
            );
          }
          setState(() => _useCurrentLocation = false);
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        LatLng newPos = LatLng(position.latitude, position.longitude);

        _mapController.move(newPos, 15);
        _updateAddress(newPos);
      }
    } catch (e) {
      debugPrint('Location Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _city = place.locality ?? place.subAdministrativeArea;
          _area = place.postalCode;
          _fullAddress =
              '${place.name}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';
          
          _cityController.text = _city ?? '';
          _areaController.text = _area ?? '';
          _addressController.text = _fullAddress ?? '';
          
          _selectedPosition = pos;
        });
      }
    } catch (e) {
      debugPrint('Geocoding Error: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: const Text('Open settings to allow location access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);
    const inputBgColor = Color(0xFFF6F6FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Partner\nRegistration',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PROGRESS',
                      style: GoogleFonts.poppins(
                        color: Colors.blueGrey[600],
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '3/8',
                      style: GoogleFonts.poppins(
                        color: Colors.blueGrey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Container(
                      width: 14,
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i < 3 ? primaryBlue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              // if (!_formKey.currentState!.validate()) return;
              final provider = Provider.of<RegistrationProvider>(context, listen: false);
              provider.address = _addressController.text;
              provider.city = _cityController.text;
              provider.pincode = _areaController.text;
              provider.currentStep = '/select_category';

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('vendors').doc(user.uid).update({
                  'address': provider.address,
                  'city': provider.city,
                  'pincode': provider.pincode,
                  'currentStep': provider.currentStep,
                });
              }

              if (context.mounted) Navigator.pushNamed(context, '/select_category');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  children: const [
                    TextSpan(text: 'Your Work '),
                    TextSpan(
                      text: 'Location',
                      style: TextStyle(
                        color: primaryBlue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirm where you\'ll be offering your expertise to match with local customers.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
              ),
              const SizedBox(height: 30),
  
              // Interaction Fields
              _buildInfoCard(
                'CITY',
                'Select your city',
                Icons.location_city,
                inputBgColor,
                primaryBlue,
                controller: _cityController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'AREA/PINCODE',
                'e.g. 560038',
                Icons.pin_drop,
                inputBgColor,
                primaryBlue,
                controller: _areaController,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 6 || int.tryParse(v) == null) return 'Enter 6-digit pincode';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'FULL ADDRESS',
                'House no, Street name...',
                Icons.location_on,
                inputBgColor,
                primaryBlue,
                controller: _addressController,
                isMultiline: true,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

            const SizedBox(height: 24),

            // Use Current Location Toggle
            _buildLocationToggle(primaryBlue),

            const SizedBox(height: 24),

            // Live FlutterMap Integration
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPosition,
                        initialZoom: 15,
                        onPositionChanged: (pos, hasGesture) {
                          if (hasGesture) _selectedPosition = pos.center;
                        },
                        onMapEvent: (evt) {
                          if (evt is MapEventMoveEnd) {
                            _updateAddress(_selectedPosition);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.urbanvendor.app',
                        ),
                      ],
                    ),
                    // Central Pin Overlay
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Icon(
                          Icons.location_on,
                          color: primaryBlue,
                          size: 40,
                        ),
                      ),
                    ),
                    // Map Branding Overlay
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LIVE MAP',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                'Confirming this sets your visibility in a 15km radius.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String hint,
    IconData icon,
    Color bg,
    Color accent, {
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            maxLines: isMultiline ? 3 : 1,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: label.contains('PINCODE') 
              ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)] 
              : null,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              hintText: label.contains('PINCODE') ? '123456' : hint,
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
              icon: Icon(icon, color: Colors.grey[500], size: 18),
              border: InputBorder.none,
              errorStyle: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationToggle(Color primaryBlue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: Color(0xFF0C6B8B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use current location',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0C6B8B),
              ),
            )
          else
            Switch(
              value: _useCurrentLocation,
              onChanged: (val) {
                if (val) {
                  _getCurrentLocation();
                } else {
                  setState(() {
                    _useCurrentLocation = false;
                    _city = _area = _fullAddress = null;
                    _cityController.clear();
                    _areaController.clear();
                    _addressController.clear();
                  });
                }
              },
              activeThumbColor: primaryBlue,
            ),
        ],
      ),
    );
  }
}
