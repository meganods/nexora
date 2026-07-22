import 'package:urbanvendor/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  static const routeName = '/add_product';

  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isServiceStory = false;

  final List<String> _categories = ['Cleaning', 'Appliance Repair', 'Plumbing', 'Electrical', 'Carpentry', 'Salon'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        AppSnackbar.show(context, 'Please select a category', isError: true);
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final newServiceRef = FirebaseFirestore.instance.collection('services').doc();
        await newServiceRef.set({
          'id': newServiceRef.id,
          'categoryName': _selectedCategory,
          'title': _nameController.text.trim(),
          'description': 'Professional service in $_selectedCategory.',
          'desc': 'Professional service in $_selectedCategory.',
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'duration': _durationController.text.trim(),
          'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
          'categoryImageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
          'subServices': [
            {
              'name': _nameController.text.trim(),
              'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
              'duration': _durationController.text.trim(),
            }
          ],
          'isServiceStory': _isServiceStory,
          'rating': 5.0,
          'totalReviews': 0,
        });

        if (mounted) {
          AppSnackbar.show(context, 'Service added successfully!');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.show(context, 'Error: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add New Service', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Widget
              GestureDetector(
                onTap: () {
                  AppSnackbar.show(context, 'Opening gallery...');
                },
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Upload Service Image', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Max size 5MB', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              // Form Fields
              const Text('Service Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nameController,
                label: 'Service Name',
                hint: 'e.g. Deep Home Cleaning',
                icon: Icons.cleaning_services_outlined,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_outlined, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price (₹)',
                      hint: 'e.g. 499',
                      icon: Icons.currency_rupee,
                      isNumeric: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _durationController,
                      label: 'Duration',
                      hint: 'e.g. 2 hrs',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Add to Service Stories', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                subtitle: const Text('Check to show this service under Service Stories on user homepage'),
                value: _isServiceStory,
                activeColor: accentColor,
                onChanged: (val) => setState(() => _isServiceStory = val),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Publish Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '$label is required';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
