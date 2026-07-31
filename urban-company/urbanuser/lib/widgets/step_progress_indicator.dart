import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: currentStep / totalSteps,
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
    );
  }
}
