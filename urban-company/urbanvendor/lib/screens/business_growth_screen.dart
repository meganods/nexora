import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/vendor_theme.dart';
import '../widgets/app_snackbar.dart';

class BusinessGrowthScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;
  const BusinessGrowthScreen({super.key, this.isTab = false, this.onBack});

  @override
  State<BusinessGrowthScreen> createState() => _BusinessGrowthScreenState();
}

class _BusinessGrowthScreenState extends State<BusinessGrowthScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Sub-view index:
  // 0: Reviews Dashboard
  // 1: Review Details
  // 2: Reply Editor
  // 3: Notifications Center
  // 4: Customer Chat
  // 5: Growth Recommendations
  // 6: Promotions & Campaigns
  // 7: Loyalty Tier
  // 8: Performance Insights
  // 9: Learning Center
  // 10: Achievements & Milestones
  int _activeGrowthIndex = 0;

  // Review Details State
  Map<String, dynamic>? _selectedReview;
  final _replyController = TextEditingController();

  // Chat State
  String? _activeChatUser;
  final _chatMsgController = TextEditingController();
  List<Map<String, dynamic>> _chatHistory = [];

  // Dummy Reviews Data
  final List<Map<String, dynamic>> _reviews = [
    {
      "id": "REV_908",
      "customerName": "Ananya Mishra",
      "avatar": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
      "rating": 5.0,
      "serviceName": "Deep Tissue Therapy",
      "bookingId": "BK_9082",
      "comment": "Rahul did an excellent job with the massage. He was punctual, professional, and solved my back pain instantly.",
      "date": "2h ago",
      "reply": null,
    },
    {
      "id": "REV_907",
      "customerName": "Vikram Malhotra",
      "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
      "rating": 4.0,
      "serviceName": "AC Installation",
      "bookingId": "BK_9075",
      "comment": "Nice work! Cleaned up the area after the installation. Reduced 1 star due to 10 mins delay.",
      "date": "Yesterday",
      "reply": "Thank you for the review, Vikram! We will work on punctuality.",
    },
    {
      "id": "REV_906",
      "customerName": "Suresh Raina",
      "avatar": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
      "rating": 5.0,
      "serviceName": "Emergency Plumbing",
      "bookingId": "BK_9070",
      "comment": "Super quick response for the water leakage. Highly recommended!",
      "date": "3 days ago",
      "reply": null,
    }
  ];

  // Dummy Chat Threads
  final List<Map<String, dynamic>> _chats = [
    {
      "customerName": "Neha Kulkarni",
      "avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
      "lastMessage": "Can we shift the time to 4:00 PM?",
      "time": "10:15 AM",
      "unread": true,
      "online": true,
    },
    {
      "customerName": "Kabir Mehta",
      "avatar": "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
      "lastMessage": "Awesome work on the security camera setup.",
      "time": "Yesterday",
      "unread": false,
      "online": false,
    }
  ];

  // Dummy Notifications List
  final List<Map<String, dynamic>> _notifications = [
    {"type": "booking", "title": "New Booking Request", "body": "Emergency plumbing needed at Worli, Mumbai", "time": "5m ago", "isUnread": true},
    {"type": "payment", "title": "Payout Settlement Confirmed", "body": "₹15,240 settled to HDFC Bank", "time": "2h ago", "isUnread": false},
    {"type": "alert", "title": "System Security Alert", "body": "Update your linked GST credentials immediately", "time": "1d ago", "isUnread": false},
    {"type": "achievement", "title": "Top Rated Badge Unlocked", "body": "Awarded for completing 50+ 5-star jobs YTD", "time": "2d ago", "isUnread": true}
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
      "Reviews Dashboard",
      "Review Details",
      "Reply Editor",
      "Notification Center",
      "Customer Chat",
      "Business Growth Tips",
      "Promotions Hub",
      "Loyalty Program",
      "Performance Insights",
      "Learning Center",
      "Achievements & Badges",
    ];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
        onPressed: () {
          if (_activeGrowthIndex > 0) {
            setState(() => _activeGrowthIndex = 0);
          } else if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      title: Text(
        titles[_activeGrowthIndex],
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: VendorTheme.textPrimary),
      ),
    );
  }

  Widget _buildMobileLayout() {
    Widget body;
    switch (_activeGrowthIndex) {
      case 1:
        body = _buildReviewDetailsView();
        break;
      case 2:
        body = _buildReplyEditorView();
        break;
      case 3:
        body = _buildNotificationsCenterView();
        break;
      case 4:
        body = _buildCustomerChatView();
        break;
      case 5:
        body = _buildGrowthRecommendationsView();
        break;
      case 6:
        body = _buildPromotionsView();
        break;
      case 7:
        body = _buildLoyaltyProgramView();
        break;
      case 8:
        body = _buildPerformanceInsightsView();
        break;
      case 9:
        body = _buildLearningCenterView();
        break;
      case 10:
        body = _buildAchievementsView();
        break;
      default:
        body = _buildReviewsDashboardView();
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
      child: KeyedSubtree(key: ValueKey(_activeGrowthIndex), child: body),
    );
  }

  Widget _buildDesktopLayout() {
    final items = [
      {"title": "Reviews Ledger", "icon": Icons.star_rounded, "idx": 0},
      {"title": "Alerts & Notifications", "icon": Icons.notifications_active_rounded, "idx": 3},
      {"title": "Customer Inbox", "icon": Icons.chat_bubble_rounded, "idx": 4},
      {"title": "Promotions & Offers", "icon": Icons.campaign_rounded, "idx": 6},
      {"title": "Performance Insights", "icon": Icons.query_stats_rounded, "idx": 8},
    ];

    Widget body;
    switch (_activeGrowthIndex) {
      case 1:
        body = _buildReviewDetailsView();
        break;
      case 2:
        body = _buildReplyEditorView();
        break;
      case 3:
        body = _buildNotificationsCenterView();
        break;
      case 4:
        body = _buildCustomerChatView();
        break;
      case 5:
        body = _buildGrowthRecommendationsView();
        break;
      case 6:
        body = _buildPromotionsView();
        break;
      case 7:
        body = _buildLoyaltyProgramView();
        break;
      case 8:
        body = _buildPerformanceInsightsView();
        break;
      case 9:
        body = _buildLearningCenterView();
        break;
      case 10:
        body = _buildAchievementsView();
        break;
      default:
        body = _buildReviewsDashboardView();
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
                    Text("GROWTH SUITE", style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF2563EB), fontSize: 15, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final isSel = _activeGrowthIndex == item['idx'] || (_activeGrowthIndex <= 2 && item['idx'] == 0);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        onTap: () => setState(() => _activeGrowthIndex = item['idx'] as int),
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
            child: KeyedSubtree(key: ValueKey(_activeGrowthIndex), child: body),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 1: REVIEWS DASHBOARD VIEW
  // ==========================================
  Widget _buildReviewsDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Cards row
          Row(
            children: [
              Expanded(
                child: _buildGrowthKPICard(
                  label: "Overall Rating",
                  value: "4.86 / 5.0",
                  sub: "From 128 jobs",
                  color: Colors.amber,
                  icon: Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGrowthKPICard(
                  label: "CSAT Score",
                  value: "96.4%",
                  sub: "Top 5% of Nexora",
                  color: const Color(0xFF10B981),
                  icon: Icons.emoji_emotions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Rating Distribution Chart Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Reviews Distribution", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 16),
                _buildDistributionBar("5 Star", 0.88, Colors.green),
                _buildDistributionBar("4 Star", 0.08, Colors.blue),
                _buildDistributionBar("3 Star", 0.03, Colors.amber),
                _buildDistributionBar("2 Star", 0.01, Colors.orange),
                _buildDistributionBar("1 Star", 0.0, Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reviews List
          Text("Latest Customer Feedback", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
          const SizedBox(height: 12),
          Column(
            children: _reviews.map((rev) => _buildReviewSummaryCard(rev)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthKPICard({required String label, required String value, required String sub, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(String stars, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(stars, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFF1F5F9), color: color, minHeight: 6),
            ),
          ),
          const SizedBox(width: 14),
          Text("${(pct * 100).toInt()}%", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReviewSummaryCard(Map<String, dynamic> rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(rev['avatar']), radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rev['customerName'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(rev['serviceName'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) => Icon(Icons.star_rounded, color: index < rev['rating'].toInt() ? Colors.amber : Colors.grey[200], size: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(rev['comment'], style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textPrimary, height: 1.4)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rev['date'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedReview = rev;
                    _activeGrowthIndex = 1;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                child: Text(rev['reply'] == null ? "Reply" : "View Payout"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 2: REVIEW DETAILS VIEW
  // ==========================================
  Widget _buildReviewDetailsView() {
    if (_selectedReview == null) return const Center(child: Text("Select a review first"));
    final rev = _selectedReview!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundImage: NetworkImage(rev['avatar']), radius: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rev['customerName'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(rev['serviceName'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) => Icon(Icons.star_rounded, color: index < rev['rating'].toInt() ? Colors.amber : Colors.grey[200], size: 16)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(rev['comment'], style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: VendorTheme.textPrimary)),
                const SizedBox(height: 12),
                Text("Date Posted: ${rev['date']} • Booking Reference: ${rev['bookingId']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (rev['reply'] != null) ...[
            Text("Your Reply", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
              child: Text(rev['reply'], style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
            ),
          ] else ...[
            Text("Reply to feedback", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  _replyController.text = "";
                  setState(() => _activeGrowthIndex = 2);
                },
                icon: const Icon(Icons.reply, size: 18),
                label: const Text("Compose Reply"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 3: REPLY TO REVIEW EDITOR VIEW
  // ==========================================
  Widget _buildReplyEditorView() {
    final suggestions = [
      "Thank you so much for the feedback! Delighted to provide top quality therapy session.",
      "Glad you loved our prompt service! Looking forward to helping you again.",
      "Thanks for sharing. We value your feedback on timing and will make adjustment."
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Write reply", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _replyController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Type reply to customer here...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          Text("💡 Suggested AI smart replies", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            children: suggestions.map((sug) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _replyController.text = sug;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Text(sug, style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_replyController.text.trim().isEmpty) {
                  AppSnackbar.show(context, "Please write something first", isError: true);
                  return;
                }
                setState(() {
                  _selectedReview!['reply'] = _replyController.text;
                  _activeGrowthIndex = 1;
                });
                AppSnackbar.show(context, "Reply submitted successfully!");
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text("Submit Reply"),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 4: NOTIFICATIONS CENTER VIEW
  // ==========================================
  Widget _buildNotificationsCenterView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _notifications.length,
      itemBuilder: (context, idx) {
        final item = _notifications[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item['isUnread'] ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item['isUnread'] ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item['type'] == 'booking' ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                radius: 18,
                child: Icon(item['type'] == 'booking' ? Icons.handyman : Icons.account_balance_wallet, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(item['body'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(item['time'], style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 5: CUSTOMER CHAT VIEW
  // ==========================================
  Widget _buildCustomerChatView() {
    if (_activeChatUser == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _chats.length,
        itemBuilder: (context, idx) {
          final thread = _chats[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundImage: NetworkImage(thread['avatar']), radius: 22),
              title: Text(thread['customerName'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(thread['lastMessage'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(thread['time'], style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 4),
                  if (thread['unread']) const CircleAvatar(backgroundColor: Color(0xFF2563EB), radius: 4),
                ],
              ),
              onTap: () {
                setState(() {
                  _activeChatUser = thread['customerName'];
                  _chatHistory = [
                    {"sender": "customer", "msg": "Hi Rahul, are you available for the session today?"},
                    {"sender": "vendor", "msg": "Yes! I will arrive on time."}
                  ];
                });
              },
            ),
          );
        },
      );
    }

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _activeChatUser = null)),
              const SizedBox(width: 8),
              Text(_activeChatUser!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              const CircleAvatar(backgroundColor: Colors.green, radius: 4),
              const SizedBox(width: 6),
              Text("Online", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _chatHistory.length,
            itemBuilder: (context, idx) {
              final msg = _chatHistory[idx];
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

        // Input row
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _chatMsgController,
                  decoration: InputDecoration(
                    hintText: "Type message...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
                onPressed: () {
                  if (_chatMsgController.text.trim().isEmpty) return;
                  setState(() {
                    _chatHistory.add({"sender": "vendor", "msg": _chatMsgController.text});
                    _chatMsgController.clear();
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
  // SCREEN 7: BUSINESS GROWTH TIPS VIEW
  // ==========================================
  Widget _buildGrowthRecommendationsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nexora Visibility Rank", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Level Strength: Excellent", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Your profile visibility is higher than 92% of local vendors.", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Recommended Actions", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTipCard("Add weekend availability slots", "Increases conversion opportunity by 28%", Icons.calendar_month),
          _buildTipCard("Verify second UPI payout path", "Ensures fallback safety on failure", Icons.verified),
          _buildTipCard("Reply to pending customer reviews", "Improves your local search ranking score", Icons.rate_review),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFFEFF6FF), child: Icon(icon, color: const Color(0xFF2563EB))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text(desc, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 8: PROMOTIONS HUB VIEW
  // ==========================================
  Widget _buildPromotionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Festival Season Campaign", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("Active discount codes: FESTIVAL10", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: 0.65, backgroundColor: const Color(0xFFF1F5F9), color: const Color(0xFF2563EB), minHeight: 6),
                const SizedBox(height: 6),
                Text("Campaign performance: 65% utilization target", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Manage Campaigns", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPromotionHubRow("Referral Program: Share & Earn", "Share code", () {}),
          _buildPromotionHubRow("Flash Discount Codes", "Configure", () {}),
        ],
      ),
    );
  }

  Widget _buildPromotionHubRow(String label, String btnLabel, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold))),
          ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)), child: Text(btnLabel)),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 9: LOYALTY PROGRAM VIEW
  // ==========================================
  Widget _buildLoyaltyProgramView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(backgroundColor: Colors.white24, radius: 24, child: Icon(Icons.workspace_premium, color: Colors.white)),
                const SizedBox(height: 16),
                Text("NEXORA GOLD TIER", style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Vishal Patel", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: 0.84, backgroundColor: Colors.white24, color: Colors.amber, minHeight: 6),
                const SizedBox(height: 6),
                Text("84% towards Platinum VIP Upgrade", style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Unlocked Tier Benefits", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildBenefitRow("10% Lower Platform Service Fees"),
          _buildBenefitRow("Instant Wallet withdrawals payout"),
          _buildBenefitRow("Priority 24/7 dedicated support phone line"),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textPrimary)),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 10: PERFORMANCE INSIGHTS VIEW
  // ==========================================
  Widget _buildPerformanceInsightsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildMiniSummaryCard("Acceptance Rate", "98.2%", "Higher than local avg", Colors.blue),
              _buildMiniSummaryCard("Completion Rate", "99.0%", "Excellent score", Colors.green),
              _buildMiniSummaryCard("Response Time", "4.2 mins", "Top tier speed", Colors.orange),
              _buildMiniSummaryCard("Cancellation Rate", "0.8%", "Extremely low risk", Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          Text("Insights Ledger", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDetailRowMetric("Peak Hour Bookings", "06:00 PM - 09:00 PM"),
          _buildDetailRowMetric("Most Booked Service", "Deep Tissue Massage"),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 11: LEARNING CENTER VIEW
  // ==========================================
  Widget _buildLearningCenterView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, idx) {
        final titles = [
          "Professional Etiquette and CSAT growth",
          "Advanced AC diagnostics & troubleshooting",
          "GST filing standard audit roadmap"
        ];
        final lengths = ["12 mins read", "45 mins masterclass video", "15 mins documentation guide"];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), radius: 22, child: Icon(Icons.school, color: Colors.blue)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titles[idx], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(lengths[idx], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.play_circle_fill, color: Color(0xFF2563EB)), onPressed: () {}),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 12: ACHIEVEMENTS & MILESTONES VIEW
  // ==========================================
  Widget _buildAchievementsView() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildAchievementBadge("5-Star Champ", "Complete 50+ jobs", true, Icons.workspace_premium),
        _buildAchievementBadge("Speed Demon", "Response < 5m", true, Icons.bolt),
        _buildAchievementBadge("Revenue Master", "Earn ₹1 Lakh", false, Icons.monetization_on),
        _buildAchievementBadge("Loyal Partner", "1 Year on Nexora", false, Icons.verified_user),
      ],
    );
  }

  Widget _buildAchievementBadge(String title, String rule, bool unlocked, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? const Color(0xFFE2E8F0) : Colors.transparent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: unlocked ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
            radius: 22,
            child: Icon(icon, color: unlocked ? const Color(0xFF2563EB) : Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: unlocked ? VendorTheme.textPrimary : Colors.grey)),
          const SizedBox(height: 2),
          Text(rule, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMiniSummaryCard(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: VendorTheme.textPrimary)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailRowMetric(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary)),
        ],
      ),
    );
  }
}
