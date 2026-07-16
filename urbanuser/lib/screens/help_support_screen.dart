import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpSupportScreen extends StatefulWidget {
  static const routeName = '/help_support';

  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I cancel my booking?',
      'a': 'You can cancel your booking from the Bookings tab. Select your upcoming booking and tap the "Cancel Booking" button at the bottom of the screen. Please note that cancellations made within 2 hours of the scheduled time may incur a fee.'
    },
    {
      'q': 'What happens if the professional is late?',
      'a': 'Our professionals usually arrive on time. If there is a delay due to traffic or unforeseen circumstances, the professional will call you. You can also track their location in the app.'
    },
    {
      'q': 'How do I pay for the service?',
      'a': 'You can pay securely via the app using UPI, Credit/Debit cards, Wallets, or Net Banking. You also have the option to pay via cash or UPI directly to the professional after the service.'
    },
    {
      'q': 'Are there any hidden charges?',
      'a': 'No, NEXORA follows a strict transparent pricing policy. The final price shown at checkout includes all taxes, visiting charges, and service fees.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Help & Support', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How can we help you today?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for articles...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 24),

            // Contact Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildContactCard(Icons.chat_bubble_outline, 'Chat', Colors.blue, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Chat Support...')));
                  }),
                  const SizedBox(width: 16),
                  _buildContactCard(Icons.phone_outlined, 'Call', Colors.green, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling Support...')));
                  }),
                  const SizedBox(width: 16),
                  _buildContactCard(Icons.email_outlined, 'Email', Colors.orange, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Email Client...')));
                  }),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            // Raise Ticket Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Raise a Ticket'),
                      content: const Text('A new support ticket will be created. Our team will contact you within 24 hours.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support ticket raised successfully!'), backgroundColor: accentColor));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.confirmation_num_outlined),
                label: const Text('Raise a Support Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            // FAQs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _faqs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: primaryColor)),
                        iconColor: accentColor,
                        collapsedIconColor: Colors.grey,
                        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        children: [
                          Text(faq['a']!, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}
