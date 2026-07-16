import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  debugPrint('🚀 Initializing Firebase...');
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.get('FIREBASE_API_KEY'),
      authDomain: dotenv.get('FIREBASE_AUTH_DOMAIN'),
      projectId: dotenv.get('FIREBASE_PROJECT_ID'),
      storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
      messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
      appId: dotenv.get('FIREBASE_APP_ID'),
      measurementId: dotenv.get('FIREBASE_MEASUREMENT_ID'),
    ),
  );

  final firestore = FirebaseFirestore.instance;

  debugPrint('🧹 DOING THE WIPE...');
  final services = await firestore.collection('services').get();
  for (var doc in services.docs) {
    await doc.reference.delete();
    debugPrint('   - Deleted: ${doc.id}');
  }

  debugPrint('🌱 DOING THE SEED...');
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

  for (var cat in categoriesToSeed) {
    final docRef = await firestore.collection('services').add({
      'categoryName': cat['categoryName'],
      'description': cat['description'],
      'color': cat['color'],
      'status': cat['status'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final subServices = cat['subServices'] as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> subServicesWithIds = [];

    for (var sub in subServices) {
      subServicesWithIds.add({
        ...sub,
        'id': '${docRef.id}_${DateTime.now().millisecondsSinceEpoch}_${sub['title'].replaceAll(' ', '_').toLowerCase()}',
      });
    }

    await docRef.update({'subServices': subServicesWithIds});
    debugPrint('✅ Seeded: ${cat['categoryName']}');
  }

  debugPrint('\n✨ ALL DONE! Marketplace is now live with your 80+ professional services. ✨');
}
