import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart';

class PricingAvailabilityScreen extends StatefulWidget {
  const PricingAvailabilityScreen({super.key});

  @override
  State<PricingAvailabilityScreen> createState() => _PricingAvailabilityScreenState();
}

class _PricingAvailabilityScreenState extends State<PricingAvailabilityScreen> {
  double _hourlyRate = 45.0;
  
  Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _morningSelected = true;
  bool _afternoonSelected = true;
  bool _eveningSelected = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RegistrationProvider>(context, listen: false);
    if (provider.baseRate > 0) _hourlyRate = provider.baseRate;
    if (provider.availableDays.isNotEmpty) _selectedDays = provider.availableDays.toSet();
    if (provider.timeSlots.isNotEmpty) {
      _morningSelected = provider.timeSlots.contains('Morning');
      _afternoonSelected = provider.timeSlots.contains('Afternoon');
      _eveningSelected = provider.timeSlots.contains('Evening');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A55ED);
    const bgColor = Color(0xFFFCFBFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Partner\nRegistration',
          style: GoogleFonts.poppins(
            color: primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(8, (index) {
                    return Container(
                      width: 10,
                      height: 3,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: index < 7 ? primaryBlue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '7/8',
                  style: GoogleFonts.poppins(
                    color: Colors.blueGrey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<RegistrationProvider>(context, listen: false);
              provider.baseRate = _hourlyRate;
              provider.availableDays = _selectedDays.toList();
              
              List<String> slots = [];
              if (_morningSelected) slots.add('Morning');
              if (_afternoonSelected) slots.add('Afternoon');
              if (_eveningSelected) slots.add('Evening');
              provider.timeSlots = slots;
              provider.currentStep = '/review_details';

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('vendors').doc(user.uid).update({
                  'baseRate': provider.baseRate,
                  'availableDays': provider.availableDays,
                  'timeSlots': provider.timeSlots,
                  'currentStep': provider.currentStep,
                });
              }
              
              if (context.mounted) Navigator.pushNamed(context, '/review_details');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Your Pricing &\nAvailability',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Control your earnings and work schedule.\nProfessional partners who set transparent pricing and\nconsistent availability receive 40% more bookings.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.blueGrey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            
            // Service Rate Card (Left Border highlight)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: primaryBlue, width: 4)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFE8E5FF), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.money, color: primaryBlue, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text('Service Rate', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hourly Rate', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(color: Colors.black87),
                              children: [
                                TextSpan(text: '₹${_hourlyRate.toInt()}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
                                TextSpan(text: '/hr', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: primaryBlue,
                          inactiveTrackColor: Colors.grey[200],
                          thumbColor: primaryBlue,
                          overlayColor: primaryBlue.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _hourlyRate,
                          min: 15,
                          max: 150,
                          onChanged: (val) {
                            setState(() {
                              _hourlyRate = val;
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹15/hr', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          Text('₹150/hr', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF6F6FB), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb, color: Color(0xFF0C6B8B), size: 16),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Expert Tip', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0C6B8B))),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey[800], height: 1.5),
                                      children: [
                                        const TextSpan(text: 'Top-rated partners in your\ncategory typically charge\nbetween '),
                                        TextSpan(text: '₹400 - ₹600', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                        const TextSpan(text: ' per hour.'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Freedom to Scale Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF6B74F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Freedom to Scale', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Toggle your working hours anytime. Your calendar is\nyours to manage.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  // Decorative grid graph
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      bool isHighlighted = index == 2;
                      return Container(
                        width: 30,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      bool isHighlighted = index == 2 || index == 3;
                      return Container(
                        width: 30,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weekly Availability Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFE2F6F9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.calendar_month, color: Color(0xFF0C6B8B), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text('Weekly Availability', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('AVAILABLE DAYS', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.0)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _days.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.remove(day);
                            } else {
                              _selectedDays.add(day);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            day,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  
                  // Time Slots
                  _buildTimeSlotCard('Morning', '8:00 AM — 12:00 PM', Icons.wb_sunny_outlined, _morningSelected, (val) {
                    setState(() => _morningSelected = val!);
                  }),
                  const SizedBox(height: 12),
                  _buildTimeSlotCard('Afternoon', '12:00 PM — 5:00 PM', Icons.wb_sunny, _afternoonSelected, (val) {
                    setState(() => _afternoonSelected = val!);
                  }),
                  const SizedBox(height: 12),
                  _buildTimeSlotCard('Evening', '5:00 PM — 10:00 PM', Icons.nightlight_round, _eveningSelected, (val) {
                    setState(() => _eveningSelected = val!);
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Next Button removed from here (moved to bottomNavigationBar)
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(String title, String time, IconData icon, bool isSelected, ValueChanged<bool?> onChanged) {
    const primaryBlue = Color(0xFF4A55ED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: title == 'Evening' ? const Color(0xFF9E3A1A) : const Color(0xFF4A55ED), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(time, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: primaryBlue,
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }
}
