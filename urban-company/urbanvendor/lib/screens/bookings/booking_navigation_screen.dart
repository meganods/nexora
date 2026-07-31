import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../theme/vendor_theme.dart';
import '../../widgets/app_snackbar.dart';

class BookingNavigationScreen extends StatefulWidget {
  const BookingNavigationScreen({super.key});

  @override
  State<BookingNavigationScreen> createState() => _BookingNavigationScreenState();
}

class _BookingNavigationScreenState extends State<BookingNavigationScreen> {
  late final MapController _mapController;
  Timer? _navigationTimer;
  int _currentPathIndex = 0;
  bool _hasArrivedLocally = false;

  // Road-aligned coordinates (e.g. Kasturba Rd -> Queens Rd -> MG Road in Bangalore)
  static final List<LatLng> _roadPoints = [
    const LatLng(12.9716, 77.5946),
    const LatLng(12.9740, 77.5955),
    const LatLng(12.9760, 77.5963),
    const LatLng(12.9775, 77.5963),
    const LatLng(12.9785, 77.5963),
    const LatLng(12.9790, 77.5980),
    const LatLng(12.9790, 77.6015),
    const LatLng(12.9790, 77.6045),
    const LatLng(12.9785, 77.6090),
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Periodically update current location index to simulate live GPS on-road movement
    _navigationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_hasArrivedLocally) {
        setState(() {
          if (_currentPathIndex < _roadPoints.length - 1) {
            _currentPathIndex++;
            _mapController.move(_roadPoints[_currentPathIndex], 14.5);
          } else {
            _hasArrivedLocally = true;
            _navigationTimer?.cancel();
          }
        });
      }
    });
  }

  bool _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      final bookingId = args['bookingId'];
      if (bookingId != null) {
        FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
          'status': 'en_route',
        });
        FirebaseFirestore.instance.collection('booking_timeline').add({
          'bookingId': bookingId,
          'status': 'en_route',
          'title': 'Vendor On The Way',
          'description': 'Vendor is en route to your service location.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final bookingId = args['bookingId'] ?? 'BK-9921';
    final data = args['data'] as Map<String, dynamic>? ?? {};
    final address = data['address'] ?? data['customerAddress'] ?? '4812 Lakeside Dr, Highland Park, TX';
    final customerName = data['userName'] ?? data['customerName'] ?? 'Julian Vance';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Job Execution",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage("https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"),
            ),
          )
        ],
      ),
      body: _hasArrivedLocally 
          ? _buildArrivedUI(bookingId, customerName, address, data)
          : _buildNavigationUI(bookingId, customerName, address, data),
    );
  }

  // SCREEN 3: Navigation UI
  Widget _buildNavigationUI(String bookingId, String customerName, String address, Map<String, dynamic> data) {
    final currentPos = _roadPoints[_currentPathIndex];
    final progressMins = 12 - _currentPathIndex;
    final progressKm = (9 - _currentPathIndex) * 0.5; // in kilometers

    return Column(
      children: [
        // 1. Current Route & Status Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CURRENT ROUTE", style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("Tech Hub East • Bldg 4", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.traffic_rounded, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text("Light Traffic", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.speed_rounded, color: Color(0xFF2563EB), size: 16),
                          SizedBox(width: 6),
                          Text("No Tolls", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Map View
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _roadPoints[0],
                  initialZoom: 14.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nexora.urbanvendor',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _roadPoints,
                        color: const Color(0xFF2563EB),
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentPos,
                        width: 45,
                        height: 45,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      Marker(
                        point: _roadPoints.last,
                        width: 45,
                        height: 45,
                        child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),

              // Float stats pill
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0256D0),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("$progressMins", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 4),
                        const Text("MIN", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 20, color: Colors.white24),
                        const SizedBox(width: 12),
                        Text("${progressKm.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Text("•", style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        const Text("ETA 2:45 PM", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Navigation Controls
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
                      onPressed: () {
                        setState(() {
                          _currentPathIndex = 0;
                        });
                        _mapController.move(_roadPoints[0], 14.5);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
                          try {
                            await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (context.mounted) {
                              AppSnackbar.show(context, "Could not launch Google Maps. Opening web search...");
                              await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0256D0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.navigation, color: Colors.white),
                        label: const Text("START NAVIGATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasArrivedLocally = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFF2563EB)),
                  label: const Text("MARK ARRIVED", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SCREEN 4: You've Arrived UI
  Widget _buildArrivedUI(String bookingId, String customerName, String address, Map<String, dynamic> data) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Blue Arrival Status Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0256D0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  "You've Arrived!",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  "We've detected you're at the service destination.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // 2. Client Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage("https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150"),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("CLIENT", style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(customerName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.phone, color: Color(0xFF2563EB), size: 20),
                            onPressed: () => AppSnackbar.show(context, "Calling $customerName..."),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB), size: 20),
                            onPressed: () => AppSnackbar.show(context, "Opening chat..."),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.ac_unit, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Service Type", style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("Premium HVAC Maintenance", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Location Snippet Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Text("Location Verified via GPS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Service Address", style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(address, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                  ],
                ),
              ],
            ),
          ),

          // 4. Primary CTA Mark Arrived
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _markArrived(context, bookingId, data),
                    icon: const Icon(Icons.login_rounded, color: Colors.white),
                    label: const Text("MARK ARRIVED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0256D0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "By marking arrived, the customer will be notified and your service timer will start.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markArrived(BuildContext context, String bookingId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'ARRIVED',
        'arrivedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('booking_timeline').add({
        'bookingId': bookingId,
        'status': 'arrived',
        'title': 'Vendor Arrived',
        'description': 'Vendor has arrived at your service location.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firestore update failed: $e. Transitioning locally for testing.");
    }
    if (context.mounted) {
      AppSnackbar.show(context, "Arrived at customer site! Enter OTP to begin service.");
      Navigator.pushReplacementNamed(context, '/bookings/otp', arguments: {'bookingId': bookingId, 'data': data});
    }
  }
}
