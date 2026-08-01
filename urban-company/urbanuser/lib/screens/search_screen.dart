import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/service_model.dart';
import 'service_detail_screen.dart';
import 'nexora_ai_assistant_screen.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _blue = Color(0xFF2563EB);
const _dark = Color(0xFF0F172A);
const _gray = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _green = Color(0xFF10B981);

class SearchScreen extends StatefulWidget {
  final bool startVoice;
  const SearchScreen({super.key, this.startVoice = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  bool _isListening = false;

  // Advanced Search Filters
  String _selectedFilterCategory = 'All';
  String _sortBy = 'Popularity';
  double _maxPrice = 2000.0;
  double _minRating = 0.0;
  double _maxDistance = 15.0;
  bool _verifiedOnly = false;
  bool _offerAvailableOnly = false;

  final List<String> _trendingSearches = [
    'AC Repair & Service',
    'Deep Home Cleaning',
    'Sofa Cleaning',
    'Salon for Women',
    'Plumber Visit',
  ];

  final List<Map<String, dynamic>> _fallbackServices = [
    {
      'id': 's1',
      'name': 'Deep Home Cleaning',
      'category': 'Cleaning',
      'startingPrice': 799.0,
      'duration': '3–4 hrs',
      'rating': 4.9,
      'totalReviews': 1280,
      'distance': 2.4,
      'isVerified': true,
      'hasOffer': true,
      'coverImage': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400&auto=format&fit=crop',
    },
    {
      'id': 's2',
      'name': 'AC Service & Repair',
      'category': 'Appliance',
      'startingPrice': 599.0,
      'duration': '1–2 hrs',
      'rating': 4.8,
      'totalReviews': 950,
      'distance': 4.1,
      'isVerified': true,
      'hasOffer': false,
      'coverImage': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=400&auto=format&fit=crop',
    },
    {
      'id': 's3',
      'name': 'Sofa Cleaning & Shampooing',
      'category': 'Cleaning',
      'startingPrice': 499.0,
      'duration': '2 hrs',
      'rating': 4.3,
      'totalReviews': 620,
      'distance': 7.8,
      'isVerified': false,
      'hasOffer': true,
      'coverImage': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=400&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.startVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openLiveVoiceAssistant());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? ['AC Service', 'Deep Cleaning'];
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    // Persist search query in local device cache
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) _recentSearches.removeLast();
      await prefs.setStringList('recentSearches', _recentSearches);
      setState(() {});
    }

    // Sync search queries to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('search_history').add({
          'userId': user.uid,
          'keyword': query.trim(),
          'searchedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentSearches');
    setState(() {
      _recentSearches.clear();
    });
  }

  void _openLiveVoiceAssistant() {
    setState(() => _isListening = true);
    final voiceTextController = TextEditingController(text: _searchController.text);
    Timer? silenceTimer;

    void triggerAutoSearch(String query, BuildContext ctx) {
      silenceTimer?.cancel();
      final text = query.trim();
      if (text.isNotEmpty) {
        setState(() {
          _searchController.text = text;
        });
        _saveSearchQuery(text);
      }
      if (ctx.mounted) {
        Navigator.pop(ctx);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        silenceTimer ??= Timer(const Duration(seconds: 3), () {
          if (voiceTextController.text.trim().isEmpty && ctx.mounted) {
            Navigator.pop(ctx);
          }
        });

        return StatefulBuilder(
          builder: (context, setVoiceState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header Title matching Image 1: 🎙️ Listening...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic_none_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Listening...',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Subtitle in Blue matching Image 1: Listening for your voice...
                  Text(
                    'Listening for your voice...',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 28),

                  // Center Big Blue Mic Button matching Image 1
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 800.ms),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // "Try saying:" Label matching Image 1
                  Text(
                    'Try saying:',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _gray),
                  ),
                  const SizedBox(height: 12),

                  // Chip Pills Layout matching Image 1: [AC Repair] [Deep Home Cleaning] [Plumber near me] [Sofa Shampooing]
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      'AC Repair',
                      'Deep Home Cleaning',
                      'Plumber near me',
                      'Sofa Shampooing',
                    ].map((prompt) {
                      return InkWell(
                        onTap: () => triggerAutoSearch(prompt, context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            prompt,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _dark),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Cancel text button matching Image 1
                  TextButton(
                    onPressed: () {
                      silenceTimer?.cancel();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _gray),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      silenceTimer?.cancel();
      setState(() => _isListening = false);
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter & Sort Services', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(color: _border),
                const SizedBox(height: 12),

                // ── Sort By Options ──────────────────────────────────────────
                Text('Sort By', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 6),
                Row(
                  children: ['Popularity', 'Price: Low to High', 'Rating'].map((sortOption) {
                    final isSel = _sortBy == sortOption;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(sortOption),
                        selected: isSel,
                        selectedColor: const Color(0xFFEFF6FF),
                        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? _blue : _gray),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _sortBy = sortOption);
                            setState(() => _sortBy = sortOption);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // ── Category Chip Selector ───────────────────────────────────
                Text('Category', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 6),
                Row(
                  children: ['All', 'Cleaning', 'Appliance', 'Salon'].map((c) {
                    final isSel = _selectedFilterCategory == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: isSel,
                        selectedColor: const Color(0xFFEFF6FF),
                        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? _blue : _gray),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _selectedFilterCategory = c);
                            setState(() => _selectedFilterCategory = c);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // ── Price Range Slider ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max Price', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                    Text('₹${_maxPrice.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
                  ],
                ),
                Slider(
                  value: _maxPrice,
                  min: 300,
                  max: 2000,
                  divisions: 17,
                  activeColor: _blue,
                  onChanged: (val) {
                    setModalState(() => _maxPrice = val);
                    setState(() => _maxPrice = val);
                  },
                ),
                const SizedBox(height: 12),

                // ── Distance Slider ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max Distance', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                    Text('${_maxDistance.toStringAsFixed(1)} km', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
                  ],
                ),
                Slider(
                  value: _maxDistance,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  activeColor: _blue,
                  onChanged: (val) {
                    setModalState(() => _maxDistance = val);
                    setState(() => _maxDistance = val);
                  },
                ),
                const SizedBox(height: 12),

                // ── Minimum Rating Stars Selector ────────────────────────────
                Text('Minimum Rating', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 6),
                Row(
                  children: [0.0, 4.0, 4.5, 4.8].map((stars) {
                    final label = stars == 0.0 ? 'All' : '$stars ★';
                    final isSel = _minRating == stars;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: const Color(0xFFEFF6FF),
                        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? _blue : _gray),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _minRating = stars);
                            setState(() => _minRating = stars);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // ── Verified Professional Toggle ─────────────────────────────
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Verified Professional Only', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                  subtitle: Text('Show partners who passed complete onboarding check', style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                  value: _verifiedOnly,
                  onChanged: (val) {
                    setModalState(() => _verifiedOnly = val);
                    setState(() => _verifiedOnly = val);
                  },
                ),

                // ── Offer Available Toggle ───────────────────────────────────
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Show Offers Only', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _dark)),
                  subtitle: Text('Filter services with active promo codes or discounts', style: GoogleFonts.inter(fontSize: 10, color: _gray)),
                  value: _offerAvailableOnly,
                  onChanged: (val) {
                    setModalState(() => _offerAvailableOnly = val);
                    setState(() => _offerAvailableOnly = val);
                  },
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Apply Filters', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: _gray, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _saveSearchQuery,
                  style: GoogleFonts.inter(fontSize: 13, color: _dark, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search services, professionals, ...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: _gray, size: 16),
                  onPressed: () => setState(() => _searchController.clear()),
                ),
              GestureDetector(
                onTap: _openLiveVoiceAssistant,
                child: const Icon(Icons.mic_rounded, color: _blue, size: 20),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: _dark),
            onPressed: _showFilterBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _border, height: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snap) {
          List<Map<String, dynamic>> allServices = [];

          if (snap.hasData && snap.data!.docs.isNotEmpty) {
            allServices = snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'name': d['serviceName'] ?? d['name'] ?? d['title'] ?? 'Service',
                'category': d['categoryName'] ?? d['category'] ?? 'Home Service',
                'startingPrice': ((d['startingPrice'] ?? d['price'] ?? 499) as num).toDouble(),
                'duration': d['duration'] ?? '1–2 hrs',
                'rating': ((d['rating'] ?? d['averageRating'] ?? 4.9) as num).toDouble(),
                'totalReviews': (d['totalReviews'] ?? 12) as int,
                'distance': 1.5,
                'isVerified': d['status'] == 'Approved' || d['isApproved'] == true,
                'hasOffer': d['hasOffer'] == true || d['isRecommended'] == true,
                'coverImage': d['coverImage'] ?? d['imageUrl'] ?? d['image'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400&auto=format&fit=crop',
              };
            }).toList();
          } else {
            allServices = _fallbackServices;
          }

          List<Map<String, dynamic>> results = allServices.where((s) {
            final String sName = (s['name'] ?? '').toString().toLowerCase();
            final String sCat = (s['category'] ?? '').toString().toLowerCase();

            final matchesQuery = query.isEmpty || sName.contains(query) || sCat.contains(query);
            final matchesCat = _selectedFilterCategory == 'All' || s['category'] == _selectedFilterCategory;

            final double price = s['startingPrice'] ?? 0.0;
            final double distance = s['distance'] ?? 0.0;
            final double rating = s['rating'] ?? 0.0;
            final bool isVer = s['isVerified'] ?? false;
            final bool hasOff = s['hasOffer'] ?? false;

            final matchesPrice = price <= _maxPrice;
            final matchesDistance = distance <= _maxDistance;
            final matchesRating = rating >= _minRating;
            final matchesVerified = !_verifiedOnly || isVer;
            final matchesOffer = !_offerAvailableOnly || hasOff;

            return matchesQuery && matchesCat && matchesPrice && matchesDistance && matchesRating && matchesVerified && matchesOffer;
          }).toList();

          if (_sortBy == 'Price: Low to High') {
            results.sort((a, b) => (a['startingPrice'] as num).compareTo(b['startingPrice'] as num));
          } else if (_sortBy == 'Rating') {
            results.sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
          }

          return query.isEmpty ? _buildSuggestionsView() : _buildResultsView(results);
        },
      ),
    );
  }

  Widget _buildSuggestionsView() {
    final suggestedChips = ['Home Cleaning', 'AC Repair', 'Deep Home Cleaning', 'Electrician'];
    final trendingChips = ['AC Repair', 'Home Cleaning', "Women's Salon", 'Electrician', 'Pest Control', 'Car Wash'];

    final popularCategories = [
      {'name': 'AC Repair', 'icon': Icons.ac_unit_rounded, 'color': const Color(0xFF0EA5E9)},
      {'name': 'Plumbing', 'icon': Icons.plumbing_rounded, 'color': const Color(0xFF2563EB)},
      {'name': 'Electrician', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFF59E0B)},
      {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded, 'color': const Color(0xFF10B981)},
      {'name': 'Painting', 'icon': Icons.format_paint_rounded, 'color': const Color(0xFF8B5CF6)},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: ✨ Suggested Searches
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _blue, size: 16),
              const SizedBox(width: 6),
              Text('Suggested Searches', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestedChips.map((chipText) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() => _searchController.text = chipText);
                    _saveSearchQuery(chipText);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(chipText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
                      const SizedBox(width: 6),
                      const Icon(Icons.close_rounded, size: 14, color: _gray),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Section 2: Popular Categories (Horizontal Cards matching Image 2)
          Text('Popular Categories', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: popularCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final cat = popularCategories[idx];
                final String catName = cat['name'] as String;
                final IconData catIcon = cat['icon'] as IconData;
                final Color catColor = cat['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    setState(() => _searchController.text = catName);
                    _saveSearchQuery(catName);
                  },
                  child: Container(
                    width: 78,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(catIcon, color: catColor, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          catName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _dark),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: 🔥 Trending Today (matching Image 2)
          Row(
            children: [
              Text('🔥 Trending Today', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _dark)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingChips.map((trend) {
              return GestureDetector(
                onTap: () {
                  setState(() => _searchController.text = trend);
                  _saveSearchQuery(trend);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥 ', style: TextStyle(fontSize: 11)),
                      Text(trend, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Section 4: ✨ Ask NEXORA AI Anything (Blue Gradient Box matching Image 2)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Ask NEXORA AI Anything', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Get instant answers about home care, troubleshooting & service advice.',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'How often to service AC?',
                    'How to clean sofa stains?',
                    'Why is my water purifier leaking?',
                  ].map((aiQuery) {
                    return InkWell(
                      onTap: () {
                        // Open AI Assistant and pass the query
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NexoraAIAssistantScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          aiQuery,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedSuggestionItem(int number, String text, {required bool isRecent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isRecent ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isRecent ? _blue : const Color(0xFFD97706),
              ),
            ),
          ),
        ),
        title: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
        trailing: Icon(isRecent ? Icons.history_rounded : Icons.trending_up_rounded, size: 16, color: _gray),
        onTap: () {
          setState(() {
            _searchController.text = text;
          });
          _saveSearchQuery(text);
        },
      ),
    );
  }

  Widget _buildResultsView(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No Results Found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 4),
            Text('Try adjusting the price range or filters to find match.', style: GoogleFonts.inter(fontSize: 12, color: _gray)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final id = item['id'] ?? '';
        final title = item['name'] ?? 'Service';
        final category = item['category'] ?? 'Home Service';
        final price = ((item['startingPrice'] ?? 499) as num).toDouble();
        final duration = item['duration'] ?? '1 hr';
        final rating = ((item['rating'] ?? 4.9) as num).toDouble();
        final img = item['coverImage'] ?? '';
        final double distance = item['distance'] ?? 1.5;
        final bool isVerified = item['isVerified'] ?? false;
        final bool hasOffer = item['hasOffer'] ?? false;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: img.startsWith('http')
                    ? Image.network(img, width: 75, height: 75, fit: BoxFit.cover)
                    : Container(width: 75, height: 75, color: _blue.withValues(alpha: 0.1), child: const Icon(Icons.handyman_rounded, color: _blue)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                          child: Text(category.toUpperCase(), style: GoogleFonts.inter(fontSize: 7, color: _blue, fontWeight: FontWeight.bold)),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: _blue, size: 10),
                        ],
                        if (hasOffer) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                            child: Text('OFFER', style: GoogleFonts.inter(fontSize: 7, color: _green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
                    const SizedBox(height: 2),
                    Text('⭐ $rating · $duration · ${distance.toStringAsFixed(1)} km', style: GoogleFonts.inter(fontSize: 11, color: _gray)),
                    const SizedBox(height: 2),
                    Text('₹${price.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: _blue)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final model = ServiceModel(
                    id: id,
                    title: title,
                    price: price,
                    image: img,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: model)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text('Book', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
