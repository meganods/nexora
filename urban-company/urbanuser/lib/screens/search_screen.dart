import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  final bool startVoice;
  const SearchScreen({super.key, this.startVoice = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Search Screen (startVoice: $startVoice)'),
      ),
    );
  }
}
