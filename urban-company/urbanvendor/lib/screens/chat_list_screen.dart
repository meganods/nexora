import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import '../theme/vendor_theme.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final myEmail = user?.email ?? 'guest';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chats',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: VendorTheme.textPrimary),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: myEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "No active chats",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: VendorTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "When customers initiate a chat with you, they will appear here.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: VendorTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String chatId = data['chatId'] ?? doc.id;
              final String userName = data['userName'] ?? 'Customer';
              final String lastMsg = data['lastMessage'] ?? 'No messages yet';
              final List<dynamic> participants = data['participants'] ?? [];
              
              final String customerId = participants.firstWhere((p) => p != myEmail, orElse: () => 'customer');

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        recipientId: customerId,
                        recipientName: userName,
                        isVendorApp: true,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2563EB), fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: VendorTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12, color: VendorTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
