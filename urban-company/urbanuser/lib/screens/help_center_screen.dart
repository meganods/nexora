import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bookingIdController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  String _selectedCategory = 'Bookings';
  String _ticketCategory = 'Bookings';
  bool _isSubmittingTicket = false;

  final List<String> _categories = [
    'Bookings',
    'Payments & Refunds',
    'Account & Profile',
    'Offers & Coupons',
    'Technical Issues',
    'Safety & Security',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'cat': 'Bookings',
      'q': 'How do I reschedule or cancel my booking?',
      'a': 'Go to My Bookings, select your active booking, and tap "Reschedule" or "Cancel Booking". Cancellations made before the professional reaches your location are 100% free.'
    },
    {
      'cat': 'Payments & Refunds',
      'q': 'When do I get my refund after cancellation?',
      'a': 'Refunds are automatically initiated immediately upon cancellation and credited back to your original payment method (UPI/Card/Wallet) within 24 to 48 hours.'
    },
    {
      'cat': 'Safety & Security',
      'q': 'Are all Nexora professionals background verified?',
      'a': 'Yes, 100% of our professionals undergo strict government ID verification, criminal record checks, and mandatory skill certification prior to joining.'
    },
    {
      'cat': 'Bookings',
      'q': 'What if I am not satisfied with the service quality?',
      'a': 'All Nexora services are backed by our 30-Day Service Guarantee. If you face any issues, report a problem and we will re-assign a top-rated pro for free.'
    },
    {
      'cat': 'Payments & Refunds',
      'q': 'How does digital payment escrow protection work?',
      'a': 'Your payment is processed via 256-bit SSL encrypted gateways and held safely in escrow. Partner payout is released only after you confirm service completion.'
    },
  ];

  final List<Map<String, dynamic>> _fallbackTickets = [
    {
      'id': 'TCK-9281',
      'category': 'Payments & Refunds',
      'subject': 'Refund delay for canceled AC service',
      'description': 'I canceled my booking NEX-849201 2 days ago. Please check my refund status.',
      'status': 'In Progress',
      'createdAt': 'Today, 02:30 PM',
      'messages': [
        {'sender': 'customer', 'text': 'I canceled my booking NEX-849201 2 days ago.', 'time': '02:30 PM'},
        {'sender': 'admin', 'text': 'Hello Vishal, your refund has been processed. It will reflect in your UPI within 24 hours.', 'time': '02:45 PM'},
      ]
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _bookingIdController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _showSubmitTicketModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Raise Support Ticket', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),

              _label('Issue Category'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _ticketCategory,
                    isExpanded: true,
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 13, color: _dark, fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _ticketCategory = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _label('Subject'),
              _inputField(_subjectController, 'Brief subject of your issue', Icons.title_rounded),

              const SizedBox(height: 12),
              _label('Booking ID (Optional)'),
              _inputField(_bookingIdController, 'e.g. NEX-849201', Icons.confirmation_number_outlined),

              const SizedBox(height: 12),
              _label('Issue Description'),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your query or problem in detail…',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmittingTicket ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmittingTicket
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Submit Ticket', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (_subjectController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) return;

    setState(() => _isSubmittingTicket = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String tckId = "TCK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'ticketId': tckId,
        'userId': user?.uid ?? 'guest_user',
        'email': user?.email ?? 'guest@nexora.com',
        'category': _ticketCategory,
        'subject': _subjectController.text.trim(),
        'bookingId': _bookingIdController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isSubmittingTicket = false);
        _subjectController.clear();
        _descriptionController.clear();
        _bookingIdController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support ticket $tckId submitted successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmittingTicket = false);
    }
  }

  void _showTicketDetailsModal(Map<String, dynamic> tck) {
    final String tckId = tck['ticketId'] ?? tck['id'] ?? 'TCK-9281';
    final String subject = tck['subject'] ?? 'Support Request';
    final String status = tck['status'] ?? 'Open';
    final String desc = tck['description'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tckId, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _blue)),
                      Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: _dark, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _statusBadge(status),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(color: _border),

            Text('Original Query:', style: GoogleFonts.inter(fontSize: 11, color: _gray, fontWeight: FontWeight.bold)),
            Text(desc, style: GoogleFonts.inter(fontSize: 12, color: _dark, height: 1.4)),
            const SizedBox(height: 12),

            Text('Conversation Timeline:', style: GoogleFonts.inter(fontSize: 12, color: _dark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                children: [
                  _chatBubble('Customer Support Agent', 'Hello Vishal, your ticket has been assigned to our senior resolution manager. We are verifying your booking details.', false, '10 mins ago'),
                  _chatBubble('You (Customer)', 'Thank you, please update me once the refund transaction reference is generated.', true, '5 mins ago'),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Type your reply…',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: _blue),
                  onPressed: () {
                    if (_replyController.text.trim().isNotEmpty) {
                      _replyController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reply sent to support agent!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: _green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(String sender, String text, bool isMe, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? _blue.withValues(alpha: 0.3) : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sender, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isMe ? _blue : _dark)),
              Text(time, style: GoogleFonts.inter(fontSize: 9, color: _gray)),
            ],
          ),
          const SizedBox(height: 4),
          Text(text, style: GoogleFonts.inter(fontSize: 12, color: _dark, height: 1.3)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final query = _searchController.text.trim().toLowerCase();

    final filteredFaqs = _faqs.where((f) {
      final matchesCategory = f['cat'] == _selectedCategory;
      final matchesQuery = query.isEmpty || f['q']!.toLowerCase().contains(query) || f['a']!.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Help & Support Desk', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Support Header Banner ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [_blue, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need Help?', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('We are here to assist you 24×7 with any service issue or payment query.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search FAQs Input ─────────────────────────────────────────────
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search help topics, refunds, booking questions…',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                prefixIcon: const Icon(Icons.search_rounded, color: _gray, size: 20),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _blue)),
              ),
            ),

            const SizedBox(height: 16),

            // ── 4 Quick Contact Support Cards ─────────────────────────────────
            Row(
              children: [
                Expanded(child: _contactCard(Icons.chat_bubble_outline_rounded, 'Live Chat', '< 1 min', _green, () {})),
                const SizedBox(width: 8),
                Expanded(child: _contactCard(Icons.call_rounded, 'Call 24x7', '1800-102-9482', _blue, () {})),
                const SizedBox(width: 8),
                Expanded(child: _contactCard(Icons.email_outlined, 'Email Support', '24h response', const Color(0xFFD97706), () {})),
                const SizedBox(width: 8),
                Expanded(child: _contactCard(Icons.message_rounded, 'WhatsApp', 'Instant', Colors.teal, () {})),
              ],
            ),

            const SizedBox(height: 20),

            // ── Help Categories Chips ─────────────────────────────────────────
            Text('Help Categories', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((cat) {
                  final bool isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: const Color(0xFFEFF6FF),
                      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? _blue : _gray),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Frequently Asked Questions ────────────────────────────────────
            Text('Frequently Asked Questions', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: filteredFaqs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text('No FAQs found matching your search.', style: GoogleFonts.inter(fontSize: 12, color: _gray))),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredFaqs.length,
                      separatorBuilder: (_, __) => const Divider(color: _border, height: 1),
                      itemBuilder: (ctx, idx) {
                        final faq = filteredFaqs[idx];
                        return ExpansionTile(
                          title: Text(faq['q']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            Text(faq['a']!, style: GoogleFonts.inter(fontSize: 12, color: _gray, height: 1.5)),
                          ],
                        );
                      },
                    ),
            ),

            const SizedBox(height: 24),

            // ── My Support Tickets Stream ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Support Tickets', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
                ElevatedButton.icon(
                  onPressed: _showSubmitTicketModal,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Raise Ticket', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_tickets')
                  .where('userId', isEqualTo: user?.uid ?? 'guest_user')
                  .snapshots(),
              builder: (ctx, snap) {
                List<Map<String, dynamic>> ticketsList = _fallbackTickets;
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  ticketsList = snap.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return {'id': d.id, ...data};
                  }).toList();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ticketsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final tck = ticketsList[i];
                    final String tckId = tck['ticketId'] ?? tck['id'] ?? 'TCK-9281';
                    final String subject = tck['subject'] ?? 'Support Query';
                    final String category = tck['category'] ?? 'General';
                    final String status = tck['status'] ?? 'Open';

                    return GestureDetector(
                      onTap: () => _showTicketDetailsModal(tck),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                              child: const Icon(Icons.confirmation_number_outlined, color: _blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(tckId, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _blue)),
                                      const SizedBox(width: 6),
                                      Text('· $category', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
                                ],
                              ),
                            ),
                            _statusBadge(status),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 6),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _dark)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 9, color: _gray)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFEFF6FF);
    Color fg = _blue;

    if (status == 'Resolved' || status == 'Closed') {
      bg = const Color(0xFFECFDF5);
      fg = _green;
    } else if (status == 'In Progress') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, color: fg, fontWeight: FontWeight.bold)),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: _gray),
        fillColor: const Color(0xFFF8FAFC),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue)),
      ),
    );
  }
}
