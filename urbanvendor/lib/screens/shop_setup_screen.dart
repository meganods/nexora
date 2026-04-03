import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final List<String> _selectedCategories = [];

  final List<Map<String, String>> _categories = [
    {"name": "Salon", "image": "assets/images/banner1.png"},
    {"name": "Cleaning", "image": "assets/images/house_cleaning_demo_1774854111518.png"},
    {"name": "Plumbing", "image": "assets/images/onboarding_2_home_cleaning_illustration_retry_1774853265369.png"},
    {"name": "AC Repair", "image": "assets/images/kitchen_cleaning_demo_1774854091381.png"},
    {"name": "Painting", "image": "assets/images/car_wash_banner_illustration_1774854072344.png"},
    {"name": "Electrical", "image": "assets/images/onboarding_1_handyman_illustration_1774853199914.png"},
    {"name": "Carpenter", "image": "assets/images/categories/carpenter_icon_1774853442272.png"},
    {"name": "Laundry", "image": "assets/images/categories/laundry_icon_1774853512710.png"},
    {"name": "Pest Control", "image": "assets/images/categories/cleaner_icon_1774853550305.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Complete Shop Setup", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            const SizedBox(height: 10),
            Text("Provide your professional details and services you offer.", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 40),
            _buildInputField("Shop Name", "Ex: City Cleaners", Icons.store_outlined),
            const SizedBox(height: 20),
            _buildInputField("Contact Number", "+91 8888 888 888", Icons.phone_android_outlined),
            const SizedBox(height: 40),
            Text("Select Your Services", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            const SizedBox(height: 15),
            _buildCategoryGrid(),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text("CONTINUE", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        bool isSelected = _selectedCategories.contains(cat["name"]);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategories.remove(cat["name"]);
              } else {
                _selectedCategories.add(cat["name"]!);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[100]!, width: 2)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset(cat["image"]!, width: 50, height: 50, fit: BoxFit.cover)),
                const SizedBox(height: 10),
                Text(cat["name"]!, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryColor : AppTheme.accentColor)),
              ],
            ),
          ),
        );
      },
    );
  }
}
