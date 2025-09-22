import 'package:flutter/material.dart';

class BatchTestScreen extends StatelessWidget {
  const BatchTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Test'),
      ),
      body: const Center(
        child: Text('Batch Test - Yakında!'),
      ),
    );
  }
}
