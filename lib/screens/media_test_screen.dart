import 'package:flutter/material.dart';

class MediaTestScreen extends StatelessWidget {
  const MediaTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Test'),
      ),
      body: const Center(
        child: Text('Media Test - Yakında!'),
      ),
    );
  }
}
