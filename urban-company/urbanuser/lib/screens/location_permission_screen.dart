import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;
  String _locationStatus = 'Not Granted';
  String _notificationStatus = 'Not Granted';

  @override
  void initState() {
    super.initState();
    _checkCurrentStatuses();
  }

  Future<void> _checkCurrentStatuses() async {
    final locStatus = await Permission.locationWhenInUse.status;
    final notifStatus = await Permission.notification.status;
    setState(() {
      _locationStatus = locStatus.isGranted ? 'Granted' : 'Not Granted';
      _notificationStatus = notifStatus.isGranted ? 'Granted' : 'Not Granted';
    });
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // Request Location Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Request Notification Permission
    await Permission.notification.request();

    await _checkCurrentStatuses();

    setState(() => _isLoading = false);

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/location_selection');
      }
    } else {
      // Show permission required explanation dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Location Access Required',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'To find and dispatch home service professionals near you, Nexora needs location access. Please allow permissions in settings.',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Open Settings', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const backgroundSlant = Color(0xFFF8FAFC);
    const borderGray = Color(0xFFE2E8F0);
    const textDark = Color(0xFF0F172A);
    const textGray = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundSlant,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Top Location Illustration Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: primaryBlue,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Enable Your Location',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Allow location access to find nearby verified professionals and provide accurate services.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Benefits Grid/List Cards
              _buildBenefitRow(Icons.near_me_rounded, 'Find nearby partners', 'Connect with professionals in your sector.'),
              _buildBenefitRow(Icons.bolt_rounded, 'Faster booking', 'Skip manual address configurations.'),
              _buildBenefitRow(Icons.home_rounded, 'Accurate address', 'Real-time GPS pin matching.'),
              _buildBenefitRow(Icons.track_changes_rounded, 'Better service recommendations', 'Custom offers in your city.'),
              
              const SizedBox(height: 28),

              // Permission Status Indicators
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGray),
                ),
                child: Column(
                  children: [
                    _buildPermissionStatusRow('Location Access', _locationStatus),
                    const Divider(color: borderGray, height: 24),
                    _buildPermissionStatusRow('Notification Access', _notificationStatus),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Primary "Allow Permission" Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Allow Permission',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Secondary "Not Now" Button
              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to selection screen directly to pick manually
                    Navigator.pushReplacementNamed(context, '/location_selection');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: borderGray),
                    foregroundColor: textGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Not Now',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusRow(String label, String status) {
    final bool isGranted = status == 'Granted';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isGranted ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isGranted ? const Color(0xFF065F46) : const Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }
}
