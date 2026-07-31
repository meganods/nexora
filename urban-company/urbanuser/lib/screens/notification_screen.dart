import 'dart:async';
import 'package:flutter/material.dart';

class NotificationModel {
  final bool isRead;
  NotificationModel({required this.isRead});
}

final notificationStreamController = StreamController<List<NotificationModel>>.broadcast();

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Notifications'),
      ),
    );
  }
}
