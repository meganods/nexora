import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/admin_provider.dart';
import '../services/cloudinary_service.dart';
import 'package:uuid/uuid.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  bool _maintenanceMode = false;
  double _commissionRate = 12.5;
  bool _automaticApproval = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildSystemControlGrid(),
        const SizedBox(height: 32),
        _buildConfigurationSection(),
        const SizedBox(height: 32),
        _buildDataManagementSection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.blueGrey[400],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Colors.blueGrey[300],
              ),
              const SizedBox(width: 8),
              Text(
                'Manage System',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'System Control Center',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          'Monitor system health and configure global application parameters.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey[600]),
        ),
      ],
    );
  }

  Widget _buildSystemControlGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildControlCard(
            'API Status',
            'Operational',
            Icons.speed_rounded,
            Colors.green,
            '99.9% uptime',
          ),
          const SizedBox(width: 20),
          _buildControlCard(
            'Server Load',
            'Moderate',
            Icons.developer_board_rounded,
            Colors.blue,
            '24% CPU usage',
          ),
          const SizedBox(width: 20),
          _buildControlCard(
            'Database',
            'Healthy',
            Icons.storage_rounded,
            Colors.indigo,
            '450ms avg latency',
          ),
          const SizedBox(width: 20),
          _buildControlCard(
            'Security',
            'Shielded',
            Icons.shield_rounded,
            Colors.orange,
            'Threat level: Low',
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard(
    String title,
    String status,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      width: 280,
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[400],
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blueGrey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Configuration',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 32),
          _buildConfigItem(
            'Maintenance Mode',
            'Disable all user and vendor access to the system for scheduled updates.',
            Switch(
              value: _maintenanceMode,
              onChanged: (v) => setState(() => _maintenanceMode = v),
              activeThumbColor: const Color(0xFF6366F1),
            ),
          ),
          const Divider(height: 48),
          _buildConfigItem(
            'Commission Rate (%)',
            'Default percentage taken from every vendor booking through the platform.',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_commissionRate.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Slider(
                  value: _commissionRate,
                  min: 0,
                  max: 50,
                  onChanged: (v) => setState(() => _commissionRate = v),
                  activeColor: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
          const Divider(height: 48),
          _buildConfigItem(
            'Automatic Approval',
            'Automatically approve vendors who meet all certification criteria.',
            Switch(
              value: _automaticApproval,
              onChanged: (v) => setState(() => _automaticApproval = v),
              activeThumbColor: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Data Management',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Administrative Access',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildConfigItem(
            'Seed Service Catalog',
            'Populate the database with the pre-defined 10 main categories and 70+ sub-services.',
            ElevatedButton.icon(
              onPressed: () => _handleSeedData(),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                'Seed Main Catalog',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const Divider(height: 48),
          _buildConfigItem(
            'Wipe Demo Data',
            'Permanently remove all categories and services to start with a fresh slate.',
            TextButton.icon(
              onPressed: () => _handleWipeData(),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text(
                'Wipe Portfolio',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWipeData() async {
    
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe All Services?'),
        content: const Text('This will permanently delete all categories and sub-services from the database. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final services = await FirebaseFirestore.instance.collection('services').get();
      for (var doc in services.docs) {
        await doc.reference.delete();
      }
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portfolio wiped successfully.')));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wipe failed: $e')));
    }
  }

  Future<void> _handleSeedData() async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final List<Map<String, dynamic>> categoriesToSeed = [
        {
          'categoryName': 'Salon at Home',
          'description': 'Professional grooming and beauty services at your doorstep.',
          'color': 0xFF4C1D95,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'Haircut', 'price': '₹249', 'duration': '30 Mins', 'desc': 'Professional haircut by top stylists.'},
            {'title': 'Hair Styling', 'price': '₹499', 'duration': '45 Mins', 'desc': 'Trendy styling for any occasion.'},
            {'title': 'Hair Coloring', 'price': '₹899', 'duration': '60 Mins', 'desc': 'Premium color and highlights.'},
            {'title': 'Facial', 'price': '₹1299', 'duration': '60 Mins', 'desc': 'Skin rejuvenating treatment.'},
            {'title': 'Waxing', 'price': '₹599', 'duration': '45 Mins', 'desc': 'Full body or specific area waxing.'},
            {'title': 'Manicure', 'price': '₹699', 'duration': '40 Mins', 'desc': 'Complete hand care and nail art.'},
            {'title': 'Pedicure', 'price': '₹799', 'duration': '45 Mins', 'desc': 'Relaxing foot spa and grooming.'},
          ]
        },
        {
          'categoryName': 'Cleaning Services',
          'description': 'Deep cleaning for homes, offices, and specific areas.',
          'color': 0xFF0D9488,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'Home Cleaning', 'price': '₹2999', 'duration': '5 Hrs', 'desc': 'Complete house deep cleaning.'},
            {'title': 'Bathroom Cleaning', 'price': '₹499', 'duration': '1 Hr', 'desc': 'Sanitization and mirror polishing.'},
            {'title': 'Kitchen Cleaning', 'price': '₹999', 'duration': '2 Hrs', 'desc': 'Chimney and tile degreasing.'},
            {'title': 'Sofa Cleaning', 'price': '₹799', 'duration': '1.5 Hrs', 'desc': 'Shampooing and dirt extraction.'},
          ]
        },
        {
          'categoryName': 'Electrician',
          'description': 'Expert electrical repairs, installations, and wiring.',
          'color': 0xFF2563EB,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'Switch Repair', 'price': '₹149', 'duration': '20 Mins', 'desc': 'Fixing loose or sparking switches.'},
            {'title': 'Fan Installation', 'price': '₹299', 'duration': '30 Mins', 'desc': 'Standard ceiling fan setup.'},
            {'title': 'Wiring Repair', 'price': '₹999', 'duration': 'As per area', 'desc': 'Complete house wiring check.'},
          ]
        },
        {
          'categoryName': 'Plumbing',
          'description': 'Fixing leaks, installations, and drainage solutions.',
          'color': 0xFFDB2777,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'Tap Repair', 'price': '₹199', 'duration': '30 Mins', 'desc': 'Fixing leaky faucets and mixers.'},
            {'title': 'Leakage Fix', 'price': '₹499', 'duration': '1 Hr', 'desc': 'Detecting and sealing pipe leaks.'},
            {'title': 'Drain Cleaning', 'price': '₹399', 'duration': '45 Mins', 'desc': 'Clearing clogged sinks and toilets.'},
          ]
        },
        {
          'categoryName': 'AC & Appliance Repair',
          'description': 'Maintenance and repair for all household electronics.',
          'color': 0xFFDC2626,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'AC Repair', 'price': '₹599', 'duration': '1.5 Hrs', 'desc': 'Cooling and filter issues fixed.'},
            {'title': 'Washing Machine Repair', 'price': '₹799', 'duration': '1.5 Hrs', 'desc': 'Drum and motor diagnostics.'},
            {'title': 'Refrigerator Repair', 'price': '₹699', 'duration': '1 Hr', 'desc': 'Compressor and gas issues.'},
          ]
        },
        {
          'categoryName': 'Home Services',
          'description': 'Reliable everyday assistance for your household.',
          'color': 0xFFF59E0B,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'Cook Service', 'price': '₹300/meal', 'duration': '2 Hrs', 'desc': 'Professional home-cooked meals.'},
            {'title': 'Maid Service', 'price': '₹1500/month', 'duration': 'Daily', 'desc': 'Daily house cleaning assistance.'},
            {'title': 'Babysitting', 'price': '₹500/hr', 'duration': 'As requested', 'desc': 'Safe and engaging child care.'},
          ]
        },
        {
          'categoryName': 'Furniture Services',
          'description': 'Professional carpentry and furniture assembly.',
          'color': 0xFF7C2D12,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'Furniture Assembly', 'price': '₹499', 'duration': '1 Hr', 'desc': 'IKEA and other brand assembly.'},
            {'title': 'Carpentry Work', 'price': '₹399', 'duration': '45 Mins', 'desc': 'Minor repairs and modifications.'},
          ]
        },
        {
          'categoryName': 'Gardening & Outdoor',
          'description': 'Professional landscaping and pest control services.',
          'color': 0xFF064E3B,
          'status': 'ACTIVE',
          'subServices': [
            {'title': 'Gardening', 'price': '₹499', 'duration': '2 Hrs', 'desc': 'Plant pruning and lawn mowing.'},
            {'title': 'Pest Control', 'price': '₹999', 'duration': '1 Hr', 'desc': 'Termite and rodent eradication.'},
          ]
        },
      ];

      final uuid = const Uuid();

      for (var cat in categoriesToSeed) {
        final List<Map<String, dynamic>> subServicesWithIds = (cat['subServices'] as List).map((s) {
          return {
            ...s as Map<String, dynamic>,
            'id': uuid.v4(),
            'status': 'Enabled',
            'imageUrl': CloudinaryService.getAutoIconUrl(s['title']),
          };
        }).toList();

        final data = {
          'categoryName': cat['categoryName'],
          'description': cat['description'],
          'color': cat['color'],
          'status': cat['status'],
          'categoryImageUrl': CloudinaryService.getAutoIconUrl(cat['categoryName']),
          'subServices': subServicesWithIds,
        };

        await provider.addService(data);
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catalog seeded successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seeding failed: $e')),
      );
    }
  }

  Widget _buildConfigItem(String title, String description, Widget control) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blueGrey[400],
                ),
              ),
            ],
          ),
        ),
        control,
      ],
    );
  }
}
