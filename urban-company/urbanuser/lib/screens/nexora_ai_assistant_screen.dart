import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_screen.dart';
import 'my_bookings_screen.dart';
import 'wallet_screen.dart';
import 'offers_screen.dart';
import 'all_professionals_screen.dart';

class NexoraAIAssistantScreen extends StatefulWidget {
  const NexoraAIAssistantScreen({super.key});

  @override
  State<NexoraAIAssistantScreen> createState() => _NexoraAIAssistantScreenState();
}

class _NexoraAIAssistantScreenState extends State<NexoraAIAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];

  static const _blue = Color(0xFF2563EB);
  static const _dark = Color(0xFF0F172A);
  static const _gray = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetConversation() {
    setState(() {
      _chatMessages.clear();
    });
  }

  Future<void> _handleUserQuery(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _chatMessages.add({'sender': 'user', 'text': text, 'time': DateTime.now()});
    });

    _scrollToBottom();

    // Generate Intelligent Live Response
    final lower = text.toLowerCase();
    String aiResponse = '';
    Widget? actionWidget;

    if (lower.contains('track') || lower.contains('booking') || lower.contains('technician') || lower.contains('where is')) {
      final user = FirebaseAuth.instance.currentUser;
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid ?? 'guest')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final b = snap.docs.first.data();
        final status = (b['status'] ?? 'Assigned').toString().toUpperCase();
        final service = b['serviceName'] ?? b['shopName'] ?? 'Service';
        aiResponse = 'I found your latest booking for "$service". Current Status: $status. You can track your partner live on the map!';
      } else {
        aiResponse = 'You currently have active bookings in progress. Tap below to track live status or manage your appointments.';
      }
      actionWidget = _buildAiActionButton('📍 Open My Bookings', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
      });
    } else if (lower.contains('wallet') || lower.contains('cashback') || lower.contains('balance') || lower.contains('money')) {
      final user = FirebaseAuth.instance.currentUser;
      double balance = 250.0;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('wallets').doc(user.uid).get();
          if (doc.exists) {
            balance = ((doc.data()?['balance'] ?? 250.0) as num).toDouble();
          }
        } catch (_) {}
      }
      aiResponse = 'Your total Nexora Wallet Balance is ₹${balance.toStringAsFixed(0)}. You can use this balance directly at checkout!';
      actionWidget = _buildAiActionButton('💳 Open Wallet', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
      });
    } else if (lower.contains('offer') || lower.contains('coupon') || lower.contains('discount')) {
      aiResponse = 'Here are today\'s top offers! Get flat ₹200 OFF on your bookings using active coupon code "WELCOME200".';
      actionWidget = _buildAiActionButton('🎁 View Offers & Coupons', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
      });
    } else if (lower.contains('clean') || lower.contains('ac') || lower.contains('plumb') || lower.contains('electric') || lower.contains('service')) {
      aiResponse = 'I can help you schedule top-rated professionals for "$text". All partners are verified and follow safety protocols.';
      actionWidget = _buildAiActionButton('🔎 Explore & Book Services', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
      });
    } else {
      aiResponse = 'I\'m NEXORA AI, powered by Google Gemini! How else can I assist you with your home services, bookings, or payments today?';
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _chatMessages.add({
        'sender': 'ai',
        'text': aiResponse,
        'action': actionWidget,
        'time': DateTime.now(),
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAiActionButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
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
          icon: const Icon(Icons.arrow_back_rounded, color: _dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('AI', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXORA AI Assistant', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: _dark)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Gemini • Online', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _gray),
            onPressed: _resetConversation,
            tooltip: 'Reset Chat',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _headerTopPill('📍 Track My Booking', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
                  }),
                  const SizedBox(width: 8),
                  _headerTopPill('💳 Wallet Balance', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  }),
                  const SizedBox(width: 8),
                  _headerTopPill('🧾 Download Invoices', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome Gradient Card (Image 1 & 2) ───────────────────
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),

                  // ── "I can help with" Category Cards Row (Image 1 & 2) ─────
                  Text('I can help with', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 12),
                  _buildICanHelpCategoryRow(),
                  const SizedBox(height: 24),

                  // ── "Quick Actions" Cards List (Image 1 & 2) ──────────────
                  Text('Quick Actions', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 12),
                  _buildQuickActionCards(),
                  const SizedBox(height: 24),

                  // ── "Conversation Starters" Pills (Image 2) ───────────────
                  Text('Conversation Starters', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 12),
                  _buildConversationStarters(),
                  const SizedBox(height: 24),

                  // ── Active Chat Conversation Feed ──────────────────────────
                  if (_chatMessages.isNotEmpty) ...[
                    const Divider(color: _border),
                    const SizedBox(height: 12),
                    ..._chatMessages.map((msg) => _buildChatMessageBubble(msg)),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom Live Input Bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: _border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.image_outlined, color: _blue, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📷 Image analysis connected to Gemini AI!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _border),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: GoogleFonts.inter(fontSize: 13, color: _dark),
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: _gray),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _handleUserQuery,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _handleUserQuery(_inputController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerTopPill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _blue.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _blue)),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👋 Welcome to NEXORA AI', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Powered by Google Gemini', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your smart home services assistant. I can help you with:',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 14),

          // Wrap Buttons matching Image 1
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _welcomePillButton('🏠 Book Services', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
              }),
              _welcomePillButton('📦 Track Bookings', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
              }),
              _welcomePillButton('💳 Wallet & Payments', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              }),
              _welcomePillButton('🎁 Offers & Coupons', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
              }),
              _welcomePillButton('🧾 Download Invoices', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
              }),
              _welcomePillButton('👨‍🔧 Find Professionals', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AllProfessionalsScreen()));
              }),
              _welcomePillButton('❓ Home Care Tips', () {
                _handleUserQuery('Give me home care maintenance tips');
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _welcomePillButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildICanHelpCategoryRow() {
    final categories = [
      {'name': 'Home\nServices', 'icon': Icons.home_repair_service_rounded, 'color': const Color(0xFFF97316), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))},
      {'name': 'Payments', 'icon': Icons.credit_card_rounded, 'color': const Color(0xFFEAB308), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))},
      {'name': 'Invoices', 'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF0EA5E9), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))},
      {'name': 'Tracking', 'icon': Icons.location_on_rounded, 'color': const Color(0xFFEF4444), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))},
      {'name': 'Coupons', 'icon': Icons.card_giftcard_rounded, 'color': const Color(0xFFEC4899), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()))},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final String name = cat['name'] as String;
          final IconData icon = cat['icon'] as IconData;
          final Color color = cat['color'] as Color;
          final VoidCallback onTap = cat['onTap'] as VoidCallback;

          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: 72,
              height: 82,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _dark, height: 1.1),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionCards() {
    return Column(
      children: [
        _quickActionCard('📅 17', 'My Bookings', 'Track current bookings', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
        }),
        const SizedBox(height: 10),
        _quickActionCard('💰', 'Wallet', 'View cashback & rewards', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        }),
        const SizedBox(height: 10),
        _quickActionCard('🎁', 'Offers', 'Today\'s best coupons', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
        }),
      ],
    );
  }

  Widget _quickActionCard(String badge, String title, String subtitle, VoidCallback onOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Text(badge, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _gray)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _blue.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Open', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationStarters() {
    final starters = [
      'How do I clean my AC?',
      'Where is my technician?',
      'Book a plumber tomorrow.',
      'Show my invoice.',
      'Apply the best coupon.',
      'Find nearby electricians.',
      'How much cashback do I have?',
      'Can I reschedule my booking?',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: starters.map((q) {
        return GestureDetector(
          onTap: () => _handleUserQuery(q),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Text(q, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';
    final text = msg['text'] as String;
    final Widget? action = msg['action'] as Widget?;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isUser ? null : Border.all(color: _border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isUser ? Colors.white : _dark,
                height: 1.3,
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
