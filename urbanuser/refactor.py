import re

with open('lib/screens/cart_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. State variables
state_vars = """class _CartScreenState extends State<CartScreen> {
  int _selectedDayIndex = 0;
  String _selectedTimeSlot = "10:00 AM";

  late List<Map<String, dynamic>> _selectedItems;

  final List<Map<String, dynamic>> _addons = [
    {
      "name": "Step Cut",
      "price": 499,
      "img": "assets/images/banner1.png",
      "options": "2 options",
    },
    {
      "name": "Face Spa",
      "price": 799,
      "img": "assets/images/house_cleaning_demo_1774854111518.png",
      "options": "3 options",
    },
    {
      "name": "Waxing",
      "price": 299,
      "img": "assets/images/kitchen_cleaning_demo_1774854091381.png",
      "options": "4 options",
    },
    {
      "name": "Nail Art",
      "price": 399,
      "img": "assets/images/car_wash_banner_illustration_1774854072344.png",
      "options": "1 option",
    },
  ];

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
  }

  double get _currentTotal {
    return _selectedItems.fold(0.0, (sum, item) => sum + (item["price"] as int));
  }
"""
code = code.replace('class _CartScreenState extends State<CartScreen> {\n  int _selectedDayIndex = 0;\n  String _selectedTimeSlot = "10:00 AM";', state_vars)

# 2. _buildSelectionList
selection_list_old = """  Widget _buildSelectionList() {
    final selectedItems = [
      {
        "name": "Standard Haircut",
        "price": "₹499",
        "img": "assets/images/banner1.png",
      },
      {
        "name": "Beard Grooming",
        "price": "₹299",
        "img": "assets/images/house_cleaning_demo_1774854111518.png",
      },
      {
        "name": "Face Massage",
        "price": "₹599",
        "img": "assets/images/kitchen_cleaning_demo_1774854091381.png",
      },
      {
        "name": "L'Oreal Spa",
        "price": "₹1,299",
        "img": "assets/images/car_wash_banner_illustration_1774854072344.png",
      },
    ];
    return Padding("""
selection_list_new = """  Widget _buildSelectionList() {
    if (_selectedItems.isEmpty) return const SizedBox();
    return Padding("""
code = code.replace(selection_list_old, selection_list_new)

code = code.replace('...selectedItems', '..._selectedItems')

# Update mapped item to handle integer price
code = code.replace('item["price"]!,', '"₹${item["price"]}",')
code = code.replace('item["name"]!,', 'item["name"] as String,')
code = code.replace('item["img"]!,', 'item["img"] as String,')

# Update Remove button
remove_old = """                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${item["name"]} removed from cart"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },"""
remove_new = """                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedItems.remove(item);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${item["name"]} removed from cart"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },"""
code = code.replace(remove_old, remove_new)

# 3. _buildAddOnsInCart
addons_old = """  Widget _buildAddOnsInCart() {
    final addons = [
      {
        "name": "Step Cut",
        "price": "₹499",
        "img": "assets/images/banner1.png",
        "options": "2 options",
      },
      {
        "name": "Face Spa",
        "price": "₹799",
        "img": "assets/images/house_cleaning_demo_1774854111518.png",
        "options": "3 options",
      },
      {
        "name": "Waxing",
        "price": "₹299",
        "img": "assets/images/kitchen_cleaning_demo_1774854091381.png",
        "options": "4 options",
      },
      {
        "name": "Nail Art",
        "price": "₹399",
        "img": "assets/images/car_wash_banner_illustration_1774854072344.png",
        "options": "1 option",
      },
      {
        "name": "Hydra Facial",
        "price": "₹1,499",
        "img":
            "assets/images/onboarding_3_convenient_service_illustration_1774853244833.png",
        "options": "1 option",
      },
      {
        "name": "Full Wax",
        "price": "₹899",
        "img":
            "assets/images/onboarding_1_handyman_illustration_1774853199914.png",
        "options": "2 options",
      },
      {
        "name": "Hair Color",
        "price": "₹1,299",
        "img": "assets/images/banner_bg_cleaning_1774854573561.png",
        "options": "1 option",
      },
    ];
    return Column("""
addons_new = """  Widget _buildAddOnsInCart() {
    if (_addons.isEmpty) return const SizedBox();
    return Column("""
code = code.replace(addons_old, addons_new)

code = code.replace('addons.length', '_addons.length')
code = code.replace('addons[index]', '_addons[index]')

add_old = """                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${a["name"]} added to cart"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },"""
add_new = """                            onTap: () {
                              setState(() {
                                _selectedItems.add({
                                  "name": a["name"],
                                  "price": a["price"],
                                  "img": a["img"],
                                });
                                _addons.remove(a);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${a["name"]} added to cart"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },"""
code = code.replace(add_old, add_new)

code = code.replace('a["price"]!,', '"₹${a["price"]}",')
code = code.replace('a["name"]!,', 'a["name"] as String,')
code = code.replace('a["img"]!,', 'a["img"] as String,')

# 4. Update widget.totalPrice references
code = code.replace('widget.totalPrice.toStringAsFixed', '_currentTotal.toStringAsFixed')
code = code.replace('(widget.totalPrice + 71).toStringAsFixed', '(_currentTotal + 71).toStringAsFixed')
code = code.replace('(widget.totalPrice + 71)', '(_currentTotal + 71)')

# Remove static AssetImage in addons list since they can be network images now
code = code.replace('Image.asset(item["img"]', 'item["img"].toString().startsWith("assets") ? Image.asset(item["img"] as String, width: 60, height: 60, fit: BoxFit.cover) : Image.network(item["img"] as String, width: 60, height: 60, fit: BoxFit.cover)')
code = code.replace('Image.asset(a["img"]', 'a["img"].toString().startsWith("assets") ? Image.asset(a["img"] as String, fit: BoxFit.cover) : Image.network(a["img"] as String, fit: BoxFit.cover)')
code = code.replace('width: 60,\n                          height: 60,\n                          fit: BoxFit.cover,\n                        )', '')
code = code.replace('fit: BoxFit.cover)', 'fit: BoxFit.cover)')

with open('lib/screens/cart_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print('Done!')
