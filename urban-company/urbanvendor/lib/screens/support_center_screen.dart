import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class SupportCenterScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;
  const SupportCenterScreen({super.key, this.isTab = false, this.onBack});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  // Sub-view controllers inside support:
  // 0: FAQ & Support Options Dashboard
  // 1: Raise a Support Ticket Form
  // 2: Live Chat Simulator
  // 3: Ticket Logs & Timeline History
  int _activeSupportIndex = 0;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = "Payment Issues";

  // Live Chat Simulator State
  final _chatController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"sender": "agent", "msg": "Hello! How can Nexora Partner Support help you today?"}
  ];

  // Dummy Help Center FAQs
  final List<Map<String, dynamic>> _faqs = [
    {
      "q": "How does Nexora calculate platform commissions?",
      "a": "Nexora operates on a flat-tier commission of 10% on bookings. No hidden platform costs are billed to Gold and Platinum status vendors.",
      "expanded": false,
    },
    {
      "q": "Why is my withdrawal status pending?",
      "a": "Standard bank withdrawals settle within 24-48 hours depending on banking holidays. UPI withdrawals execute instantly.",
      "expanded": false,
    },
    {
      "q": "How can I appeal a customer rating?",
      "a": "If you believe a review violates Nexora Partner Code of Conduct, raise a support ticket and upload client chat screenshots.",
      "expanded": false,
    }
  ];

  // Dummy Ticket Log History
  final List<Map<String, dynamic>> _tickets = [
    {
      "id": "TCK_981240",
      "category": "Payment Issues",
      "title": "Payout settlement delayed for BK_9082",
      "status": "Resolved",
      "date": "2026-07-27",
    },
    {
      "id": "TCK_981224",
      "category": "Account Security",
      "title": "UPI handle verification failure warning",
      "status": "Open",
      "date": "2026-07-28",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: isDesktop ? null : _buildMobileAppBar(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    final titles = [
      "FAQ & Support Hub",
      "Raise Support Ticket",
      "Nexora Live Chat",
      "Ticket Logs History",
    ];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
        onPressed: () {
          if (_activeSupportIndex > 0) {
            setState(() => _activeSupportIndex = 0);
          } else if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      title: Text(
        titles[_activeSupportIndex],
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: VendorTheme.textPrimary),
      ),
    );
  }

  Widget _buildMobileLayout() {
    Widget body;
    switch (_activeSupportIndex) {
      case 1:
        body = _buildRaiseTicketView();
        break;
      case 2:
        body = _buildLiveChatView();
        break;
      case 3:
        body = _buildTicketLogsView();
        break;
      default:
        body = _buildSupportDashboardView();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_activeSupportIndex), child: body),
    );
  }

  Widget _buildDesktopLayout() {
    final items = [
      {"title": "FAQ & Helplines", "icon": Icons.help_outline_rounded, "idx": 0},
      {"title": "Live Support Chat", "icon": Icons.support_agent_rounded, "idx": 2},
    ];

    Widget body;
    switch (_activeSupportIndex) {
      case 1:
        body = _buildRaiseTicketView();
        break;
      case 2:
        body = _buildLiveChatView();
        break;
      case 3:
        body = _buildTicketLogsView();
        break;
      default:
        body = _buildSupportDashboardView();
    }

    return Row(
      children: [
        // Sidebar list
        Container(
          width: 250,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
                        onPressed: widget.onBack,
                      ),
                    Text("SUPPORT DESK", style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF2563EB), fontSize: 15, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final isSel = _activeSupportIndex == item['idx'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => setState(() => _activeSupportIndex = item['idx'] as int),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: isSel ? const Color(0xFF2563EB) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(item['icon'] as IconData, color: isSel ? Colors.white : VendorTheme.textSecondary, size: 20),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : VendorTheme.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Body pane
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(key: ValueKey(_activeSupportIndex), child: body),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 0: FAQ & DIRECT HELPLINES
  // ==========================================
  Widget _buildSupportDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Help Center Quick Connect Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("24/7 PARTNER RESOLUTION DESK", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Need Urgent Assistance?", style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Instant resolution support pathways are active for all certified Nexora Partners.", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _activeSupportIndex = 2),
                      icon: const Icon(Icons.support_agent_rounded, size: 16),
                      label: const Text("Live Chat"),
                      style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFF2563EB), backgroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text("Frequently Asked Questions", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
          const SizedBox(height: 12),
          Column(
            children: _faqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: ExpansionTile(
                  title: Text(faq['q'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(faq['a'], style: GoogleFonts.inter(fontSize: 12.5, color: VendorTheme.textSecondary, height: 1.4)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 1: RAISE A SUPPORT TICKET
  // ==========================================
  Widget _buildRaiseTicketView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ticket Category", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: ["Payment Issues", "Account Security", "CSAT Appeal"].map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),

          Text("Subject", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: "Enter short ticket title...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          Text("Issue Details", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Describe your issue with booking references...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
                  AppSnackbar.show(context, "Please fill out all fields", isError: true);
                  return;
                }
                AppSnackbar.show(context, "Support Ticket Raised Successfully!");
                setState(() => _activeSupportIndex = 3);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text("Submit Ticket"),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: LIVE CHAT SIMULATOR
  // ==========================================
  Widget _buildLiveChatView() {
    return Column(
      children: [
        // Top Info Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nexora Support Bot", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("Average response time: Instant", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Message Feed
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (context, idx) {
              final msg = _messages[idx];
              final isMe = msg['sender'] == 'vendor';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(msg['msg'], style: GoogleFonts.inter(color: isMe ? Colors.white : Colors.black87, fontSize: 13)),
                ),
              );
            },
          ),
        ),

        // Text input bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: "Ask support bot...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
                onPressed: () {
                  if (_chatController.text.trim().isEmpty) return;
                  final userMsg = _chatController.text;
                  setState(() {
                    _messages.add({"sender": "vendor", "msg": userMsg});
                    _chatController.clear();
                  });

                  // Simulated Bot reply
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        _messages.add({
                          "sender": "agent",
                          "msg": "I have logged your concern regarding this query. A live agent is connecting..."
                        });
                      });
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 3: SUPPORT TICKET HISTORY & TIMELINE
  // ==========================================
  Widget _buildTicketLogsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _tickets.length,
      itemBuilder: (context, idx) {
        final t = _tickets[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t['id'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), fontSize: 13.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: t['status'] == "Resolved" ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      t['status'],
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: t['status'] == "Resolved" ? const Color(0xFF15803D) : const Color(0xFFD97706)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(t['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text("Category: ${t['category']} • Opened: ${t['date']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}
