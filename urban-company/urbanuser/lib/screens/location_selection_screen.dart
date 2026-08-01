import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLatLng = const LatLng(28.6139, 77.2090); // Default New Delhi
  String _addressLine = 'Detecting current address...';
  String _city = '';
  String _state = '';
  String _country = 'India';
  String _pincode = '';
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _determineAndLocatePosition();
  }

  Future<void> _determineAndLocatePosition() async {
    setState(() {
      _isLoading = true;
      _addressLine = 'Fetching live position...';
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final newLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLatLng = newLatLng;
        });
        _mapController.move(newLatLng, 16.0);
        await _reverseGeocode(position.latitude, position.longitude);
      } else {
        setState(() {
          _addressLine = 'Location permission denied. Tap on map to select.';
        });
      }
    } catch (e) {
      setState(() {
        _addressLine = 'Location detection error. Tap map to select manually.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reverseGeocode(double latitude, double longitude) async {
    final res = await LocationService.reverseGeocode(latitude, longitude);
    if (mounted) {
      setState(() {
        _city = res.city;
        _state = res.state;
        _pincode = res.pincode;
        _addressLine = res.fullAddress.isNotEmpty ? res.fullAddress : '${res.area}, ${res.city}, ${res.state} - ${res.pincode}';
      });
    }
  }

  Future<void> _saveLocationAndProceed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'location': {
          'latitude': _selectedLatLng.latitude,
          'longitude': _selectedLatLng.longitude,
          'address': _addressLine,
          'city': _city,
          'state': _state,
          'country': _country,
          'pincode': _pincode,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save location: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const borderGray = Color(0xFFE2E8F0);
    const textDark = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Your Location',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
        ),
      ),
      body: Stack(
        children: [
          // FlutterMap Interactive Area
          Column(
            children: [
              // Search input field
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: textGray, size: 22),
                    hintText: 'Search address manually...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderGray),
                    ),
                  ),
                ),
              ),

              // Interactive FlutterMap OpenStreetMap Area
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLatLng,
                    initialZoom: 15.0,
                    onTap: (tapPos, point) {
                      setState(() {
                        _selectedLatLng = point;
                      });
                      _reverseGeocode(point.latitude, point.longitude);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nexora.urbanuser',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLatLng,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFEF4444),
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 250), // Reserve height for Bottom Address Panel
            ],
          ),

          // Floating Quick GPS button
          Positioned(
            right: 16,
            bottom: 266,
            child: FloatingActionButton(
              onPressed: _determineAndLocatePosition,
              backgroundColor: Colors.white,
              foregroundColor: primaryBlue,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2.5),
                    )
                  : const Icon(Icons.my_location_rounded, size: 22),
            ),
          ),

          // Bottom Slide Card Details Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Location',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textGray,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _addressLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Saved Location Presets Shortcuts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetShortcut(Icons.home_rounded, 'Home', const LatLng(28.6139, 77.2090)),
                      _buildPresetShortcut(Icons.work_rounded, 'Work', const LatLng(28.5355, 77.3910)),
                      _buildPresetShortcut(Icons.star_rounded, 'Other', const LatLng(28.4595, 77.0266)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Confirm Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: borderGray),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              foregroundColor: textGray,
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveLocationAndProceed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Confirm Location',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetShortcut(IconData icon, String label, LatLng coords) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLatLng = coords;
        });
        _mapController.move(coords, 15.0);
        _reverseGeocode(coords.latitude, coords.longitude);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}
