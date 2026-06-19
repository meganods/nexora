import 'dart:io';

final panels = {
  'urbanuser': {
    'Login': 'login_screen.dart',
    'Register': 'register_screen.dart',
    'Forgot Password': 'forgot_password_screen.dart',
    'Dashboard': 'dashboard_screen.dart',
    'Home': 'home_screen.dart',
    'Profile': 'profile_screen.dart',
    'Edit Profile': 'edit_profile_screen.dart',
    'Address Management': 'address_management_screen.dart',
    'Cart': 'cart_screen.dart',
    'Checkout': 'checkout_screen.dart',
    'Orders': 'orders_screen.dart',
    'Order Details': 'order_details_screen.dart',
    'Notifications': 'notifications_screen.dart',
    'Wishlist': 'wishlist_screen.dart',
    'Settings': 'settings_screen.dart',
    'Help & Support': 'help_support_screen.dart',
    'Search': 'search_screen.dart',
    'Category Details': 'category_details_screen.dart',
    'Product Details': 'product_details_screen.dart',
    'Payment Success': 'payment_success_screen.dart',
    'Payment Failed': 'payment_failed_screen.dart',
    '404 Page': 'not_found_screen.dart',
  },
  'urbanvendor': {
    'Login': 'login_screen.dart',
    'Register': 'register_screen.dart',
    'Dashboard': 'dashboard_screen.dart',
    'Store Profile': 'store_profile_screen.dart',
    'Edit Store': 'edit_store_screen.dart',
    'Products List': 'products_list_screen.dart',
    'Add Product': 'add_product_screen.dart',
    'Edit Product': 'edit_product_screen.dart',
    'Inventory': 'inventory_screen.dart',
    'Orders': 'orders_screen.dart',
    'Order Details': 'order_details_screen.dart',
    'Customers': 'customers_screen.dart',
    'Reviews': 'reviews_screen.dart',
    'Analytics': 'analytics_screen.dart',
    'Notifications': 'notifications_screen.dart',
    'Coupons': 'coupons_screen.dart',
    'Withdrawals': 'withdrawals_screen.dart',
    'Reports': 'reports_screen.dart',
    'Settings': 'settings_screen.dart',
    'Help Center': 'help_center_screen.dart',
    '404 Page': 'not_found_screen.dart',
  },
  'urbanadmin': {
    'Login': 'login_screen.dart',
    'Dashboard': 'admin_dashboard.dart',
    'Users Management': 'users_screen.dart',
    'Vendors Management': 'vendors_screen.dart',
    'Products Management': 'products_screen.dart',
    'Categories Management': 'categories_screen.dart',
    'Orders Management': 'orders_screen.dart',
    'Payments Management': 'payments_screen.dart',
    'Reports': 'reports_screen.dart',
    'Analytics': 'analytics_screen.dart',
    'CMS Management': 'cms_screen.dart',
    'Banner Management': 'banner_screen.dart',
    'Notifications': 'notifications_screen.dart',
    'Roles & Permissions': 'roles_permissions_screen.dart',
    'Settings': 'settings_screen.dart',
    'Audit Logs': 'audit_logs_screen.dart',
    'Support Tickets': 'support_tickets_screen.dart',
    'System Monitoring': 'system_monitoring_screen.dart',
    'Backup Management': 'backup_management_screen.dart',
    '404 Page': 'not_found_screen.dart',
  }
};

String toCamelCase(String fileName) {
  final parts = fileName.replaceAll('.dart', '').split('_');
  return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join('');
}

String toRouteName(String fileName) {
  return '/' + fileName.replaceAll('.dart', '').replaceAll('_screen', '');
}

void main() async {
  final rootDir = Directory.current.path;
  final report = StringBuffer();
  final createdFiles = <String>[];
  final fixedFiles = <String>[];
  
  for (final panel in panels.keys) {
    report.writeln('### $panel\n');
    final connected = <String>[];
    final missing = <String>[];
    final screenMap = panels[panel]!;
    
    final screensDir = Directory('$rootDir\\$panel\\lib\\screens');
    if (!screensDir.existsSync()) screensDir.createSync(recursive: true);
    
    final mainFile = File('$rootDir\\$panel\\lib\\main.dart');
    bool mainExists = mainFile.existsSync();
    String mainContent = mainExists ? mainFile.readAsStringSync() : '';
    
    for (final entry in screenMap.entries) {
      final title = entry.key;
      final fileName = entry.value;
      final file = File('${screensDir.path}\\$fileName');
      
      if (file.existsSync()) {
        connected.add('- $title ($fileName)');
      } else {
        missing.add('- $title ($fileName)');
        // Generate File
        final className = toCamelCase(fileName);
        file.writeAsStringSync('''
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$title')),
      body: const Center(child: Text('$title Screen Placeholder')),
    );
  }
}
''');
        createdFiles.add('$panel/lib/screens/$fileName');
        
        // Inject into main.dart
        if (mainExists) {
          final importLine = "import 'screens/$fileName';\n";
          if (!mainContent.contains("import 'screens/$fileName';")) {
            // Find last import
            final lastImportIndex = mainContent.lastIndexOf(RegExp(r"import '.*;"));
            if (lastImportIndex != -1) {
              final endOfImport = mainContent.indexOf('\n', lastImportIndex);
              mainContent = mainContent.substring(0, endOfImport + 1) + importLine + mainContent.substring(endOfImport + 1);
            } else {
              mainContent = importLine + mainContent;
            }
          }
          
          final routeName = toRouteName(fileName);
          final routeLine = "        '$routeName': (context) => const $className(),\n";
          if (!mainContent.contains("'$routeName'")) {
            final routesIndex = mainContent.indexOf('routes: {');
            if (routesIndex != -1) {
              final endOfRoutes = mainContent.indexOf('{', routesIndex);
              mainContent = mainContent.substring(0, endOfRoutes + 1) + '\n' + routeLine + mainContent.substring(endOfRoutes + 1);
            }
          }
        }
      }
    }
    
    if (mainExists && missing.isNotEmpty) {
      mainFile.writeAsStringSync(mainContent);
      fixedFiles.add('$panel/lib/main.dart');
    }
    
    report.writeln('✅ Connected Pages:');
    if (connected.isEmpty) report.writeln('- None');
    for (var c in connected) report.writeln(c);
    report.writeln('');
    
    report.writeln('❌ Missing Pages (Auto-Created):');
    if (missing.isEmpty) report.writeln('- None');
    for (var m in missing) report.writeln(m);
    report.writeln('');
    
    report.writeln('⚠ Broken Connections (Auto-Fixed):');
    if (missing.isEmpty) report.writeln('- None');
    else report.writeln('- Automatically registered routes for newly created pages in main.dart.');
    report.writeln('');
  }
  
  report.writeln('### Files Created');
  for (var f in createdFiles) report.writeln('- $f');
  report.writeln('');
  
  report.writeln('### Files Fixed');
  for (var f in fixedFiles) report.writeln('- $f');
  report.writeln('');
  
  report.writeln('### Manual Action Required');
  report.writeln('- Update sidebar menus to include new routes if they are not already mapped.');
  
  File('audit_report_output.txt').writeAsStringSync(report.toString());
  print('Audit complete! Output written to audit_report_output.txt');
}
