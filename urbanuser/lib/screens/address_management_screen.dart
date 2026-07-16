import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddressManagementScreen extends StatefulWidget {
  static const routeName = '/address_management';

  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  static const primaryColor = Color(0xFF0F172A);
  static const accentColor = Color(0xFF00A884);
  static const bgColor = Color(0xFFF8FAFC);

  List<Map<String, dynamic>> addresses = [
    {
      'id': 1,
      'type': 'Home',
      'address': 'B-102, Galaxy Apartments, Sector 62, Noida, UP, 201309',
      'isDefault': true,
    },
    {
      'id': 2,
      'type': 'Office',
      'address': 'Tech Park, Building 4, Sector 125, Noida, UP, 201303',
      'isDefault': false,
    },
  ];

  void _deleteAddress(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                addresses.removeWhere((a) => a['id'] == id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address deleted successfully'), backgroundColor: accentColor, behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _setDefault(int id) {
    setState(() {
      for (var a in addresses) {
        a['isDefault'] = a['id'] == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default address updated'), backgroundColor: accentColor, behavior: SnackBarBehavior.floating),
    );
  }

  void _showAddEditAddressBottomSheet([Map<String, dynamic>? address]) {
    final isEditing = address != null;
    final typeController = TextEditingController(text: isEditing ? address['type'] : '');
    final addrController = TextEditingController(text: isEditing ? address['address'] : '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEditing ? 'Edit Address' : 'Add New Address', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 24),
              TextFormField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: 'Save as (e.g. Home, Office)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: addrController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Complete Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      if (isEditing) {
                        final idx = addresses.indexWhere((a) => a['id'] == address['id']);
                        addresses[idx]['type'] = typeController.text;
                        addresses[idx]['address'] = addrController.text;
                      } else {
                        addresses.add({
                          'id': DateTime.now().millisecondsSinceEpoch,
                          'type': typeController.text,
                          'address': addrController.text,
                          'isDefault': addresses.isEmpty,
                        });
                      }
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Address updated' : 'Address added'), backgroundColor: accentColor, behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEditing ? 'Update Address' : 'Save Address', style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Manage Addresses', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _showAddEditAddressBottomSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('+ Add New Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ).animate().slideY(begin: 0.5),
        ),
      ),
      body: addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No addresses saved yet', style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate().fadeIn()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: address['isDefault'] ? accentColor : Colors.grey.shade200, width: address['isDefault'] ? 2 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(address['type'] == 'Home' ? Icons.home : Icons.work, color: primaryColor),
                            const SizedBox(width: 12),
                            Text(address['type'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                            const Spacer(),
                            if (address['isDefault'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Default', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(address['address'], style: const TextStyle(color: Colors.black87, height: 1.5)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!address['isDefault'])
                              TextButton(
                                onPressed: () => _setDefault(address['id']),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: const Text('Set as Default', style: TextStyle(color: accentColor)),
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                                  onPressed: () => _showAddEditAddressBottomSheet(address),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteAddress(address['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
              },
            ),
    );
  }
}
