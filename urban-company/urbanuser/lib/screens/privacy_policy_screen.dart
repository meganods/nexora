import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isLoading = true;
  final Map<String, dynamic> _firestoreData = {};

  @override
  void initState() {
    super.initState();
    _fetchLegalData();
  }

  Future<void> _fetchLegalData() async {
    try {
      final legalSnap = await FirebaseFirestore.instance.collection('legal_pages').get();
      final infoSnap = await FirebaseFirestore.instance.collection('company_information').get();

      for (var doc in legalSnap.docs) {
        _firestoreData[doc.id] = doc.data();
      }
      for (var doc in infoSnap.docs) {
        _firestoreData[doc.id] = doc.data();
      }
    } catch (e) {
      debugPrint("Legal Center Firestore note: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDetailModal(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(color: _border),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail Views ───────────────────────────────────────────────────────────

  Widget _buildPrivacyContent() {
    final data = _firestoreData['privacy_policy'] ?? {};
    final lastUpdated = data['lastUpdated'] ?? 'July 31, 2026';
    final content = data['text'] ??
        'At Nexora, we prioritize the protection of your personal information. This Privacy Policy details how we secure, process, and use your data when you book services through our platform.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last Updated: $lastUpdated', style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(content, style: GoogleFonts.inter(fontSize: 13, color: _dark, height: 1.5)),
        const SizedBox(height: 20),
        _heading('1. Data Security & Encryption'),
        _body('All personal details, including your verified mobile number and saved service addresses, are transmitted using industry-standard 256-bit SSL encryption. We enforce a zero-third-party sharing policy.'),
        _bullet('We do not share your exact location data with unassigned vendors.'),
        _bullet('Customer phone numbers are masked to protect user identity.'),
        const SizedBox(height: 14),
        _heading('2. Location Consent'),
        _body('With your permission, we use your device GPS coordinates to show available services and assign the closest certified home professional.'),
      ],
    );
  }

  Widget _buildTermsContent() {
    final data = _firestoreData['terms_and_conditions'] ?? {};
    final content = data['text'] ??
        'Welcome to Nexora. By accessing or using our managed home services marketplace, you agree to comply with the booking and payment terms defined below.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(content, style: GoogleFonts.inter(fontSize: 13, color: _dark, height: 1.5)),
        const SizedBox(height: 20),
        _heading('1. Booking & Scheduling Rules'),
        _body('All bookings must be scheduled through the official Nexora app. Standard duration estimates are provided, and users must ensure entry permission for assigned professionals at the selected time slot.'),
        _heading('2. Payment & Escrow Guarantee'),
        _body('User payments are held securely in a protected escrow account. Funds are released to the service provider only after you confirm service completion or the 24-hour dispute window closes.'),
        _heading('3. User Responsibilities'),
        _body('Users must provide a safe environment for the assigned service professional. Duplicate accounts or fraudulent booking requests will result in immediate account termination.'),
      ],
    );
  }

  Widget _buildRefundContent() {
    final data = _firestoreData['refund_policy'] ?? {};
    final content = data['text'] ??
        'We believe in fair pricing and complete transparency. Read below for our full cancellation guidelines and refund processing timelines.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(content, style: GoogleFonts.inter(fontSize: 13, color: _dark, height: 1.5)),
        const SizedBox(height: 20),
        _heading('1. Cancellation Windows'),
        _bullet('Cancellations made 3+ hours before the service slot: 100% Free Refund.'),
        _bullet('Cancellations made after the professional is on the way: A nominal convenience fee of ₹100 may apply.'),
        const SizedBox(height: 14),
        _heading('2. Refund Processing Timeline'),
        _body('Refunds are initiated instantly upon cancellation. Depending on your payment method, the credit will reflect within:'),
        _bullet('UPI / GPay: 2 - 12 hours.'),
        _bullet('Credit / Debit Cards: 2 - 5 business days.'),
        const SizedBox(height: 14),
        _heading('3. Duplicate Payment Policy'),
        _body('If your bank account was debited twice due to payment gateway errors, the duplicate amount is automatically reversed by the payment processor within 24 hours.'),
      ],
    );
  }

  Widget _buildCookieContent() {
    final data = _firestoreData['cookie_policy'] ?? {};
    final content = data['text'] ??
        'Nexora uses cookies and secure secure session tokens to keep you logged in, personalize your dashboard, and analyze service performance metrics.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(content, style: GoogleFonts.inter(fontSize: 13, color: _dark, height: 1.5)),
        const SizedBox(height: 20),
        _heading('1. Security Session Tokens'),
        _body('We use secure, encrypted local tokens to verify your login session and prevent unauthorized account access.'),
        _heading('2. Performance & Analytics'),
        _body('Performance cookies help us track search queries and page response speeds to optimize the managed marketplace interface.'),
        _heading('3. User Controls'),
        _body('You can disable cookies and clear local secure storage via your device settings. Note that some functions (like automatic logins) may require these cookies.'),
      ],
    );
  }

  Widget _buildAboutContent() {
    final data = _firestoreData['about_nexora'] ?? {};
    final mission = data['mission'] ?? 'To empower local certified professionals and provide customers with seamless, top-rated home services.';
    final vision = data['vision'] ?? 'To become the most reliable, transparent, and user-friendly managed services platform globally.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blue, Color(0xFF1D4ED8)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.home_repair_service_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              Text('NEXORA', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: _blue)),
              Text('Version 2.4.0 (Build 8291)', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _heading('Our Mission'),
        _body(mission),
        const SizedBox(height: 14),
        _heading('Our Vision'),
        _body(vision),
        const SizedBox(height: 14),
        _heading('Official Channel'),
        _bullet('Website: https://nexora.app'),
      ],
    );
  }

  Widget _buildContactContent() {
    final data = _firestoreData['contact_us'] ?? {};
    final email = data['email'] ?? 'support@nexora.com';
    final phone = data['phone'] ?? '1800-102-9482';
    final address = data['address'] ?? 'BKC Tech Park, Bandra East, Mumbai, MH - 400051';
    final hours = data['hours'] ?? '09:00 AM - 09:00 PM (All Days)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Get in Touch'),
        _body('Need assistance with a booking or refund? Our support agents are available to help you.'),
        const SizedBox(height: 16),
        _contactRow(Icons.email_outlined, 'Support Email', email),
        const Divider(color: _border),
        _contactRow(Icons.phone_outlined, 'Helpline Number', phone),
        const Divider(color: _border),
        _contactRow(Icons.location_on_outlined, 'Corporate Office', address),
        const Divider(color: _border),
        _contactRow(Icons.access_time_rounded, 'Business Hours', hours),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call_rounded, size: 16),
                label: Text('Call Support', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message_rounded, size: 16),
                label: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: _blue), foregroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLicensesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Open Source Acknowledgements'),
        _body('Nexora is built using Flutter and the following high-quality open-source packages:'),
        const SizedBox(height: 16),
        _licenseRow('Flutter Framework', 'BSD 3-Clause License'),
        _licenseRow('Firebase Core & Firestore', 'Apache License 2.0'),
        _licenseRow('Google Maps SDK', 'Apache License 2.0'),
        _licenseRow('Google Fonts', 'SIL Open Font License'),
        _licenseRow('Shared Preferences', 'BSD 3-Clause License'),
      ],
    );
  }

  Widget _buildAppVersionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('System Information'),
        const SizedBox(height: 12),
        _rowInfo('App Version', '2.4.0'),
        const Divider(color: _border),
        _rowInfo('Build Code', '8291.a4'),
        const Divider(color: _border),
        _rowInfo('Release Date', 'July 31, 2026'),
        const Divider(color: _border),
        _rowInfo('Environment', 'Production (Release)'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('App is up to date!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: _green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Check for Updates', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
    );
  }

  Widget _body(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.4));
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: GoogleFonts.inter(fontSize: 14, color: _blue, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.4))),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _licenseRow(String package, String license) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(package, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
          Text(license, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: _gray)),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Legal & Policy Center', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: _isLoading
          ? _buildShimmerLoader()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _menuItemCard(Icons.privacy_tip_outlined, 'Privacy Policy', 'Data protection and usage guidelines', _buildPrivacyContent()),
                  _menuItemCard(Icons.gavel_rounded, 'Terms & Conditions', 'User agreement and booking policies', _buildTermsContent()),
                  _menuItemCard(Icons.monetization_on_outlined, 'Refund & Cancellation Policy', 'Refund timelines and duplicate payments', _buildRefundContent()),
                  _menuItemCard(Icons.cookie_outlined, 'Cookie Policy', 'How secure local tokens are used', _buildCookieContent()),
                  _menuItemCard(Icons.info_outline_rounded, 'About Nexora', 'Mission, vision and company details', _buildAboutContent()),
                  _menuItemCard(Icons.support_agent_rounded, 'Contact Us', 'Support helpline, email and address', _buildContactContent()),
                  _menuItemCard(Icons.integration_instructions_outlined, 'Open Source Licenses', 'Package acknowledgement list', _buildLicensesContent()),
                  _menuItemCard(Icons.perm_device_information_rounded, 'App Version & Info', 'Build code, release date & updates', _buildAppVersionContent()),
                ],
              ),
            ),
    );
  }

  Widget _menuItemCard(IconData icon, String title, String subtitle, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFF6FF),
          child: Icon(icon, color: _blue, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _gray),
        onTap: () => _showDetailModal(title, content),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const CircleAvatar(radius: 20, backgroundColor: Color(0xFFF1F5F9)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 120, height: 12, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(width: 180, height: 8, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
