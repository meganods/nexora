import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGoogleLoginScreen extends StatelessWidget {
  const MockGoogleLoginScreen({super.key});

  Future<void> _selectAccount(BuildContext context, String name, String email) async {
    // Show a loading indicator briefly to simulate network
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);
    await prefs.setString('userName', name);
    
    final savedAddress = prefs.getString('userAddress');
    
    if (context.mounted) {
      Navigator.pop(context); // hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome, $name!'), backgroundColor: Colors.green),
      );
      if (savedAddress != null && savedAddress.trim().isNotEmpty) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/address_setup', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Google Logo (Mock)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("G", style: GoogleFonts.poppins(color: Colors.blue, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text("o", style: GoogleFonts.poppins(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text("o", style: GoogleFonts.poppins(color: Colors.yellow[700], fontSize: 32, fontWeight: FontWeight.bold)),
                  Text("g", style: GoogleFonts.poppins(color: Colors.blue, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text("l", style: GoogleFonts.poppins(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text("e", style: GoogleFonts.poppins(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Choose an account",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                "to continue to NEXORA",
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 40),
              
              // Mock Accounts
              _buildAccountTile(context, "Vishal Kumar", "vishal.kumar@example.com", "V", Colors.purple),
              const Divider(),
              _buildAccountTile(context, "John Doe", "john.doe@example.com", "J", Colors.teal),
              const Divider(),
              
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.person_add_alt, color: Colors.black54),
                ),
                title: Text("Use another account", style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adding another account is not supported in this mock.')),
                  );
                },
              ),
              
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  "To continue, Google will share your name, email address, and profile picture with NEXORA. Before using this app, you can review NEXORA's privacy policy and terms of service.",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, String name, String email, String initial, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(initial, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(email, style: GoogleFonts.outfit(color: Colors.grey[700])),
      onTap: () => _selectAccount(context, name, email),
    );
  }
}
