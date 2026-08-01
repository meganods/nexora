import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class AddressSetupScreen extends StatefulWidget {
  const AddressSetupScreen({super.key});

  @override
  State<AddressSetupScreen> createState() => _AddressSetupScreenState();
}

class _AddressSetupScreenState extends State<AddressSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final MapController _mapController = MapController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String _addressType = 'Home';
  bool _isSaving = false;
  bool _isFetchingLocation = false;
  String? _validationError;

  LatLng _currentLocation = const LatLng(28.6139, 77.2090); // New Delhi Center

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchLiveLocation();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    String name = prefs.getString('temp_signup_name') ?? user?.displayName ?? '';
    String phone = prefs.getString('temp_signup_phone') ?? user?.phoneNumber ?? '';

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if ((data['fullName'] ?? '').toString().isNotEmpty) {
            name = data['fullName'];
          }
          if ((data['phoneNumber'] ?? '').toString().isNotEmpty) {
            phone = data['phoneNumber'];
          }
        }
      } catch (_) {}
    }

    // Format phone to 10 digits
    phone = phone.replaceAll('+91', '').replaceAll(' ', '').trim();

    if (mounted) {
      setState(() {
        _nameController.text = name;
        _phoneController.text = phone;
      });
    }
  }

  Future<void> _fetchLiveLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final lat = position.latitude;
        final lng = position.longitude;
        await _updateLocationAndAddress(lat, lng);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tap anywhere on the map to set your location.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
              backgroundColor: _blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching live location: $e");
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _updateLocationAndAddress(double lat, double lng) async {
    final result = await LocationService.reverseGeocode(lat, lng);

    if (mounted) {
      setState(() {
        _currentLocation = LatLng(lat, lng);
        if (result.houseNumber.isNotEmpty && _houseController.text.isEmpty) {
          _houseController.text = result.houseNumber;
        }
        if (result.buildingName.isNotEmpty && _buildingController.text.isEmpty) {
          _buildingController.text = result.buildingName;
        }
        if (result.street.isNotEmpty) {
          _streetController.text = result.street;
        } else if (result.area.isNotEmpty) {
          _streetController.text = result.area;
        }
        if (result.city.isNotEmpty) {
          _cityController.text = result.city;
        }
        if (result.state.isNotEmpty) {
          _stateController.text = result.state;
        }
        if (result.pincode.isNotEmpty) {
          _pincodeController.text = result.pincode;
        }
      });

      _mapController.move(LatLng(lat, lng), 16.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Live location fetched! Address auto-filled.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddressAndProceed() async {
    setState(() => _validationError = null);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final house = _houseController.text.trim();
    final building = _buildingController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid 10-digit mobile number.');
      return;
    }
    if (house.isEmpty) {
      _showError('Please enter House / Flat Number.');
      return;
    }
    if (building.isEmpty) {
      _showError('Please enter Building / Society Name.');
      return;
    }
    if (street.isEmpty) {
      _showError('Please enter Street / Area.');
      return;
    }
    if (city.isEmpty) {
      _showError('Please enter City.');
      return;
    }
    if (state.isEmpty) {
      _showError('Please enter State.');
      return;
    }
    if (pincode.isEmpty || pincode.length < 6) {
      _showError('Please enter a valid 6-digit Pincode.');
      return;
    }

    setState(() => _isSaving = true);

    final String fullAddr = "$house, $building, $street, ${_landmarkController.text.trim()}, $city, $state - $pincode"
        .replaceAll(', ,', ',');

    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    try {
      await prefs.setString('userAddress', fullAddr);
      await prefs.setString('userAddressType', _addressType);

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'userAddress': fullAddr,
          'userAddressType': _addressType,
          'fullName': name,
          'phoneNumber': '+91$phone',
          'hasCompletedAddressSetup': true,
        }, SetOptions(merge: true));
      }

      await FirebaseFirestore.instance.collection('addresses').add({
        'userId': user?.uid ?? 'guest_user',
        'type': _addressType,
        'fullName': name,
        'phone': '+91$phone',
        'houseNumber': house,
        'buildingName': building,
        'street': street,
        'landmark': _landmarkController.text.trim(),
        'city': city,
        'state': state,
        'pincode': pincode,
        'fullAddress': fullAddr,
        'latitude': _currentLocation.latitude,
        'longitude': _currentLocation.longitude,
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Address saved! Please log in to continue.',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Redirect to Login page as requested
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Could not save address. Please try again.');
      }
    }
  }

  void _showError(String message) {
    setState(() => _validationError = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _dark),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        title: Text(
          'Setup Address',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top OpenStreetMap Interactive View ─────────────────────────
            Container(
              height: 200,
              width: double.infinity,
              color: const Color(0xFFEFF6FF),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 15.0,
                      onTap: (tapPos, point) {
                        _updateLocationAndAddress(point.latitude, point.longitude);
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
                            point: _currentLocation,
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

                  // Location Target Floating Button
                  Positioned(
                    bottom: 14,
                    right: 16,
                    child: GestureDetector(
                      onTap: _fetchLiveLocation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isFetchingLocation
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
                              )
                            : const Icon(Icons.my_location_rounded, color: _blue, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _validationError!,
                                style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 1. Personal Details Section ────────────────────────
                    Text(
                      'Personal Details',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark),
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Full Name'),
                    const SizedBox(height: 6),
                    _textInput(_nameController, 'e.g. Vishal Ratan'),
                    const SizedBox(height: 16),

                    _fieldLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('🇮🇳', style: GoogleFonts.inter(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text('+91', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _textInput(_phoneController, '10-digit mobile number', isPhone: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── 2. Address Details Section ─────────────────────────
                    Text(
                      'Address Details',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark),
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('House / Flat Number'),
                    const SizedBox(height: 6),
                    _textInput(_houseController, 'e.g. K-1501'),
                    const SizedBox(height: 14),

                    _fieldLabel('Building / Society Name'),
                    const SizedBox(height: 6),
                    _textInput(_buildingController, 'e.g. Ajnara Homes'),
                    const SizedBox(height: 14),

                    _fieldLabel('Street / Area'),
                    const SizedBox(height: 6),
                    _textInput(_streetController, 'e.g. Gaur City 2, Sector 16B'),
                    const SizedBox(height: 14),

                    _fieldLabel('Landmark (Optional)'),
                    const SizedBox(height: 6),
                    _textInput(_landmarkController, 'e.g. Near Galaxy Plaza'),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('City *'),
                              const SizedBox(height: 6),
                              _textInput(_cityController, 'e.g. Greater Noida'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('State *'),
                              const SizedBox(height: 6),
                              _textInput(_stateController, 'e.g. Uttar Pradesh'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Pincode *'),
                    const SizedBox(height: 6),
                    _textInput(_pincodeController, 'e.g. 201318', isPhone: true, maxLength: 6),
                    const SizedBox(height: 24),

                    // ── 3. Address Type Selection ──────────────────────────
                    Text(
                      'Address Type',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _typeChip('Home', Icons.home_rounded),
                        const SizedBox(width: 10),
                        _typeChip('Work', Icons.work_rounded),
                        const SizedBox(width: 10),
                        _typeChip('Other', Icons.location_on_rounded),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── 4. Save & Continue Action Button ───────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAddressAndProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Save & Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _gray,
      ),
    );
  }

  Widget _textInput(TextEditingController controller, String hint, {bool isPhone = false, int? maxLength}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _dark),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _typeChip(String label, IconData icon) {
    final bool isSelected = _addressType == label;

    return GestureDetector(
      onTap: () => setState(() => _addressType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _blue : _border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : _gray),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : _gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
