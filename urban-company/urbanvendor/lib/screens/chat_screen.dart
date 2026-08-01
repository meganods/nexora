import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final bool isVendorApp;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    this.isVendorApp = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser;
  bool _isRecipientOnline = false;

  @override
  void initState() {
    super.initState();
    _listenToRecipientStatus();
  }

  void _listenToRecipientStatus() {
    if (widget.recipientId.isEmpty || widget.recipientId == 'support' || widget.recipientId == 'ai') return;
    
    // Listen to user status
    final collection = widget.isVendorApp ? 'users' : 'vendors';
    final docId = widget.recipientId;

    FirebaseFirestore.instance.collection(collection).doc(docId).snapshots().listen((snap) {
      if (snap.exists && mounted) {
        final data = snap.data();
        setState(() {
          _isRecipientOnline = data != null && data['isOnline'] == true;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final String senderId = user?.email ?? user?.uid ?? 'guest';
    final String senderName = widget.isVendorApp ? 'NEXORA Partner' : (user?.displayName ?? 'Customer');

    final messageData = {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // Write message into subcollection
    await chatRef.collection('messages').add(messageData);

    // Update parent chat doc
    await chatRef.set({
      'chatId': widget.chatId,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [senderId, widget.recipientId],
      widget.isVendorApp ? 'vendorName' : 'userName': senderName,
      widget.isVendorApp ? 'userName' : 'vendorName': widget.recipientName,
    }, SetOptions(merge: true));

    // Scroll to bottom
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

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);
    const darkColor = Color(0xFF0F172A);
    const borderGray = Color(0xFFE2E8F0);
    const textGray = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: brandBlue.withValues(alpha: 0.1),
              child: Text(
                widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : 'N',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: brandBlue, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recipientName,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isRecipientOnline || widget.recipientId == 'ai' ? const Color(0xFF10B981) : textGray,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isRecipientOnline || widget.recipientId == 'ai' ? 'Online' : 'Offline',
                        style: GoogleFonts.inter(fontSize: 10, color: textGray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderGray, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Message feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: brandBlue));
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Auto scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: textGray),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor),
                        ),
                        Text(
                          'Send a message to start the conversation.',
                          style: GoogleFonts.inter(fontSize: 11, color: textGray),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String msgSenderId = data['senderId'] ?? '';
                    final String text = data['text'] ?? '';
                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    final String timeStr = ts != null 
                        ? DateFormat('hh:mm a').format(ts.toDate())
                        : '';

                    final String myId = user?.email ?? user?.uid ?? 'guest';
                    final bool isMe = msgSenderId == myId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? brandBlue : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                          border: isMe ? null : Border.all(color: borderGray),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isMe ? Colors.white : darkColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: isMe ? Colors.white70 : textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: borderGray)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderGray),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: GoogleFonts.inter(color: textGray, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: brandBlue,
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
