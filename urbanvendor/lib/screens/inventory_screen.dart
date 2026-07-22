import 'package:urbanvendor/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InventoryScreen extends StatefulWidget {
  static const routeName = '/inventory';

  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  final List<Map<String, dynamic>> _inventory = [
    {
      'id': 1,
      'title': 'Deep Home Cleaning',
      'category': 'Cleaning',
      'price': 'â‚¹1,299',
      'duration': '3 hrs',
      'inStock': true,
    },
    {
      'id': 2,
      'title': 'Sofa Cleaning',
      'category': 'Cleaning',
      'price': 'â‚¹499',
      'duration': '1 hr',
      'inStock': true,
    },
    {
      'id': 3,
      'title': 'AC Servicing',
      'category': 'Appliance Repair',
      'price': 'â‚¹599',
      'duration': '45 mins',
      'inStock': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Inventory', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_product'),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms),
      body: _inventory.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _inventory.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _inventory[index];
                return _buildInventoryCard(item);
              },
            ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final bool inStock = item['inStock'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: inStock ? Colors.grey.shade200 : Colors.red.shade100, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.handyman, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor))),
                          Text(item['price'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['category'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          Text(item['duration'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: inStock,
                      activeTrackColor: accentColor.withValues(alpha: 0.5),
                      activeThumbColor: accentColor,
                      onChanged: (val) {
                        setState(() => item['inStock'] = val);
                        AppSnackbar.show(context, val ? '${item['title']} is now in stock' : '${item['title']} is out of stock');
                      },
                    ),
                    Text(inStock ? 'Available' : 'Out of Stock', style: TextStyle(color: inStock ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    AppSnackbar.show(context, 'Opening Edit Service...');
                  },
                  icon: const Icon(Icons.edit, size: 16, color: primaryColor),
                  label: const Text('Edit', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Your inventory is empty', style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add services you offer to start getting bookings.', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    ).animate().fadeIn();
  }
}
