import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initial welcome message
    _messages.add(ChatMessage(
      text: "Hi! I am the Urban Company AI Assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });
    _messageController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();

    // Simulate AI typing delay
    Future.delayed(const Duration(milliseconds: 600), () {
      _generateAiResponse(text);
    });
  }

  void _generateAiResponse(String query) {
    String response = "I'm sorry, I don't understand that question. You can ask me about refunds, bookings, services, or payment.";
    String lowerQuery = query.toLowerCase();

    if (lowerQuery.contains("refund")) {
      response = "Refunds are typically processed within 5-7 business days. If you cancelled a booking before the professional arrived, your refund has already been initiated.";
    } else if (lowerQuery.contains("book") || lowerQuery.contains("schedule")) {
      response = "You can book a service by searching for it on the home page and selecting a convenient date and time slot. Our professionals will arrive at your scheduled time.";
    } else if (lowerQuery.contains("cancel")) {
      response = "To cancel a booking, go to 'My Bookings', select the booking you want to cancel, and tap 'Cancel Booking'. Please note that cancellations within 2 hours of the start time may incur a fee.";
    } else if (lowerQuery.contains("cod") || lowerQuery.contains("cash")) {
      response = "Yes, we support Cash on Delivery (COD)! You can pay the professional directly in cash after your service is completed successfully.";
    } else if (lowerQuery.contains("pay") || lowerQuery.contains("card") || lowerQuery.contains("upi")) {
      response = "We accept all major credit/debit cards, UPI, and wallets. You can securely pay online or choose to pay after the service is completed.";
    } else if (lowerQuery.contains("time") || lowerQuery.contains("hours") || lowerQuery.contains("when")) {
      response = "Our services are available from 8 AM to 9 PM every day. You can select your preferred time slot during the booking process.";
    } else if (lowerQuery.contains("safe") || lowerQuery.contains("professional") || lowerQuery.contains("expert")) {
      response = "All our professionals are background-verified and highly trained. Your safety and satisfaction are our top priorities.";
    } else if (lowerQuery.contains("offer") || lowerQuery.contains("discount") || lowerQuery.contains("coupon")) {
      response = "You can find active coupons and special offers in the 'Offers' section on the Home screen or apply them directly at checkout.";
    } else if (lowerQuery.contains("hello") || lowerQuery.contains("hi") || lowerQuery.contains("hey")) {
      response = "Hello there! How can I assist you with your home services today? You can ask me about bookings, payments, refunds, or our services.";
    } else if (lowerQuery.contains("thank") || lowerQuery.contains("thanks")) {
      response = "You're very welcome! Let me know if you need anything else.";
    } else if (lowerQuery.contains("contact") || lowerQuery.contains("call") || lowerQuery.contains("human")) {
      response = "If you need further assistance, please use the 'Call' option to speak with our support team, available from 9 AM to 9 PM.";
    }

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 18,
              child: Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Support Assistant", style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Online", style: GoogleFonts.outfit(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 20),
          ),
          boxShadow: [
            if (!message.isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.outfit(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: "Type your message...",
                hintStyle: GoogleFonts.outfit(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
