import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/nexora_ai_assistant_screen.dart';
import '../screens/search_screen.dart';
import '../screens/all_recommendations_screen.dart';

class FloatingAIButton extends StatefulWidget {
  const FloatingAIButton({super.key});

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Positioned(
      bottom: 90, // Positioned above the bottom navigation bar
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Upper side Pop-up Assistance Menu
          if (_isMenuOpen)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem(Icons.psychology_rounded, 'NEXORA AI Assistant', () {
                    setState(() => _isMenuOpen = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NexoraAIAssistantScreen()),
                    );
                  }),
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  _buildMenuItem(Icons.mic_rounded, 'Live Voice Search', () {
                    setState(() => _isMenuOpen = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen(startVoice: true)),
                    );
                  }),
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  _buildMenuItem(Icons.search_rounded, 'Smart Query Search', () {
                    setState(() => _isMenuOpen = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  }),
                ],
              ),
            ),

          // Main Floating Trigger Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NexoraAIAssistantScreen()),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome, // Sparkles icon
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
