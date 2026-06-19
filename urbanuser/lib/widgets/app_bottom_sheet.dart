import 'package:flutter/material.dart';

class AppBottomSheet {
  static void show(BuildContext context, {
    required Widget child,
    bool isScrollControlled = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    );
  }
}
