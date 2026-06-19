import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/payment_screen.dart';
import '../data/rewards_data.dart';

class CartScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  final int cartCount;
  final double totalPrice;

  const CartScreen({
    super.key,
    required this.shop,
    required this.cartCount,
    required this.totalPrice,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _selectedDayIndex = 0;
  String _selectedTimeSlot = "10:00 AM";

  List<Map<String, dynamic>> _selectedItems = [];
  Map<String, dynamic>? _appliedCoupon;

  List<Map<String, dynamic>> _addons = [];

  @override
  void initState() {
    super.initState();
    _selectedItems = [
      {
        "name": widget.shop["name"],
        "price": widget.totalPrice.toInt(),
        "img": widget.shop["img"],
      }
    ];

    _addons = _generateRelatedAddons(widget.shop["name"] as String);
  }

  List<Map<String, dynamic>> _generateRelatedAddons(String serviceName) {
    String name = serviceName.toLowerCase();
    String category = "General";
    
    if (name.contains("clean") || name.contains("wash") || name.contains("maid")) {
      category = "Cleaning";
    } else if (name.contains("hair") || name.contains("salon") || name.contains("barber") || name.contains("cut") || name.contains("makeup")) {
      category = "Salon";
    } else if (name.contains("plumb") || name.contains("repair") || name.contains("electric") || name.contains("fix") || name.contains("ac") || name.contains("mechanic")) {
      category = "Repair";
    } else if (name.contains("spa") || name.contains("massage") || name.contains("relax") || name.contains("therapy")) {
      category = "Spa";
    } else if (name.contains("car")) {
      category = "Car";
    }

    if (category == "Cleaning") {
      return [
        {"name": "Disinfectant", "price": 199, "img": "assets/images/categories/cleaner_icon_1774853550305.png", "options": "1 option"},
        {"name": "Stain Removal", "price": 299, "img": "assets/images/categories/cleaner_icon_1774853550305.png", "options": "2 options"},
        {"name": "Sofa Wash", "price": 499, "img": "assets/images/house_cleaning_demo_1774854111518.png", "options": "1 option"},
      ];
    } else if (category == "Salon") {
      return [
        {"name": "Head Massage", "price": 149, "img": "assets/images/banner1.png", "options": "2 options"},
        {"name": "Beard Trim", "price": 99, "img": "assets/images/banner1.png", "options": "1 option"},
        {"name": "Face Scrub", "price": 199, "img": "assets/images/onboarding_1_handyman_illustration_1774853199914.png", "options": "1 option"},
      ];
    } else if (category == "Repair") {
      return [
        {"name": "Deep Check", "price": 149, "img": "assets/images/categories/electrician_icon_1774853479339.png", "options": "1 option"},
        {"name": "Spare Parts", "price": 500, "img": "assets/images/categories/mechanic_icon_1774853532535.png", "options": "Varies"},
      ];
    } else if (category == "Spa") {
      return [
        {"name": "Aroma Oil", "price": 199, "img": "assets/images/house_cleaning_demo_1774854111518.png", "options": "2 options"},
        {"name": "Foot Massage", "price": 299, "img": "assets/images/onboarding_1_handyman_illustration_1774853199914.png", "options": "1 option"},
      ];
    } else {
      return [
        {"name": "Priority Service", "price": 149, "img": widget.shop["img"], "options": "1 option"},
        {"name": "Extended Warranty", "price": 299, "img": widget.shop["img"], "options": "1 option"},
        {"name": "Premium Care", "price": 199, "img": widget.shop["img"], "options": "1 option"},
      ];
    }
  }

  double get _currentTotal {
    return _selectedItems.fold(0.0, (sum, item) => sum + (item["price"] as int));
  }

  double get _finalTotal {
    double discount = 0.0;
    if (_appliedCoupon != null) {
      if (_appliedCoupon!["discountPercent"] != null) {
        discount = _currentTotal * (_appliedCoupon!["discountPercent"] / 100);
      } else if (_appliedCoupon!["discountAmount"] != null) {
        discount = _appliedCoupon!["discountAmount"];
      }
    }
    double total = _currentTotal - discount + 49 + 22; // +71 is taxes & fees
    return total > 0 ? total : 0;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Booking Summary",
          style: GoogleFonts.outfit(
            color: AppTheme.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShopHeader(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
            _buildSelectionList(),
            _buildAddOnsInCart(),
            _buildDateSelection(),
            _buildTimeSlotSelection(),
            _buildApplyCouponButton(),
            _buildPriceSummary(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildShopHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: widget.shop["img"].toString().startsWith('assets')
                ? Image.asset(
                    widget.shop["img"],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    widget.shop["img"],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shop["name"],
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.shop["rating"],
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("•", style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(
                      "45 mins estimated",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionList() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _selectedItems.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Services",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_selectedItems.isNotEmpty)
                    _buildMainServiceCard(_selectedItems[0]),

                  if (_selectedItems.length > 1) ...[
                    const SizedBox(height: 20),
                    Text(
                      "Extra Services",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._selectedItems.sublist(1).map((item) => _buildExtraServiceCard(item)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMainServiceCard(Map<String, dynamic> item) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item["img"].toString().startsWith("assets") 
                    ? Image.asset(item["img"] as String, width: 60, height: 60, fit: BoxFit.cover) 
                    : Image.network(item["img"] as String, width: 60, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item["name"] as String,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "(Base Service - Cannot Be Removed)",
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "₹${item["price"]}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtraServiceCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item["img"].toString().startsWith("assets") 
                ? Image.asset(item["img"] as String, width: 50, height: 50, fit: BoxFit.cover) 
                : Image.network(item["img"] as String, width: 50, height: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item["name"] as String,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  "₹${item["price"]}",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedItems.remove(item);
                _addons.insert(0, {
                  "name": item["name"],
                  "price": item["price"],
                  "img": item["img"],
                });
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Extra service removed successfully."),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            child: Text(
              "Remove",
              style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnsInCart() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _addons.isEmpty
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Frequently Added Together",
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: _addons.length,
            itemBuilder: (context, index) {
              final a = _addons[index];
              return Container(
                width: 105,
                margin: const EdgeInsets.only(right: 15),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: a["img"].toString().startsWith("assets") ? Image.asset(a["img"] as String, fit: BoxFit.cover) : Image.network(a["img"] as String, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          bottom: -15,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedItems.add({
                                  "name": a["name"],
                                  "price": a["price"],
                                  "img": a["img"],
                                });
                                _addons.remove(a);
                              });
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${a["name"]} added to cart"),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(milliseconds: 800),
                                ),
                              );
                            },
                            child: Container(
                              width: 70,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFEEEEEE),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "ADD",
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF673AB7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      a["name"] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "₹${a["price"]}",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
            ),
    );
  }

  Widget _buildDateSelection() {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final dates = [
      "Oct 12",
      "Oct 13",
      "Oct 14",
      "Oct 15",
      "Oct 16",
      "Oct 17",
      "Oct 18",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Select Date",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: days.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: Container(
                width: 75,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _selectedDayIndex == index
                      ? AppTheme.accentColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedDayIndex == index
                        ? AppTheme.accentColor
                        : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      days[index],
                      style: GoogleFonts.outfit(
                        color: _selectedDayIndex == index
                            ? Colors.white70
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dates[index].split(" ")[1],
                      style: GoogleFonts.outfit(
                        color: _selectedDayIndex == index
                            ? Colors.white
                            : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dates[index].split(" ")[0],
                      style: GoogleFonts.outfit(
                        color: _selectedDayIndex == index
                            ? Colors.white60
                            : Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    final slots = [
      "08:00 AM",
      "10:00 AM",
      "12:00 PM",
      "02:00 PM",
      "04:00 PM",
      "06:00 PM",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Select Time Slot",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => setState(() => _selectedTimeSlot = slots[index]),
            child: Container(
              decoration: BoxDecoration(
                color: _selectedTimeSlot == slots[index]
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedTimeSlot == slots[index]
                      ? AppTheme.primaryColor
                      : Colors.grey[200]!,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                slots[index],
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _selectedTimeSlot == slots[index]
                      ? AppTheme.primaryColor
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    double discount = 0.0;
    if (_appliedCoupon != null) {
      if (_appliedCoupon!["discountPercent"] != null) {
        discount = _currentTotal * (_appliedCoupon!["discountPercent"] / 100);
      } else if (_appliedCoupon!["discountAmount"] != null) {
        discount = _appliedCoupon!["discountAmount"];
      }
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Price Summary",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _summaryRow("Item Total", "₹${_currentTotal.toStringAsFixed(0)}"),
          if (discount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Coupon Discount", style: GoogleFonts.outfit(color: Colors.green, fontSize: 14)),
                  Text("-₹${discount.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.green)),
                ],
              ),
            ),
          _summaryRow("Service Fee", "₹49"),
          _summaryRow("Taxes & Charges", "₹22"),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹${_finalTotal.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyCouponButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Coupons & Offers", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: _showCouponBottomSheet,
                child: Text("View all", style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _appliedCoupon == null ? _showCouponBottomSheet : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _appliedCoupon != null ? Colors.green.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _appliedCoupon != null ? Colors.green : AppTheme.primaryColor),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer, color: _appliedCoupon != null ? Colors.green : AppTheme.primaryColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appliedCoupon != null ? "'${_appliedCoupon!["code"]}' applied" : "Apply Coupon / Offers",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _appliedCoupon != null ? Colors.green : AppTheme.primaryColor,
                        ),
                      ),
                      if (_appliedCoupon == null)
                        Text(
                          "Save more on your booking",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
            if (_appliedCoupon != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _appliedCoupon = null;
                  });
                },
                child: const Icon(Icons.close, color: Colors.green),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCouponBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Claimed Rewards",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 20),
                if (RewardsData.claimedCoupons.isEmpty)
                  Text(
                    "You haven't claimed any rewards yet. Go to the Rewards section to claim them!",
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                  )
                else
                  ...RewardsData.claimedCoupons.map((coupon) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _appliedCoupon = coupon;
                        });
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Coupon applied!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(coupon["icon"] as IconData, color: coupon["color"] as Color, size: 30),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coupon["code"] as String,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    coupon["title"] as String,
                                    style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "APPLY",
                              style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF5F5F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PaymentScreen(totalAmount: _finalTotal),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Text(
                "PROCEED TO PAYMENT",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
