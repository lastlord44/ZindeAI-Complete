import 'package:flutter/material.dart';

class WorkoutPlanScreen extends StatelessWidget {
  const WorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Planı Test'),
      ),
      body: const Center(
        child: Text('Antrenman Planı Test - Yakında!'),
      ),
    );
  }
}
