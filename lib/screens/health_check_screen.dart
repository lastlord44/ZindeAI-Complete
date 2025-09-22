import 'package:flutter/material.dart';

class HealthCheckScreen extends StatelessWidget {
  const HealthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sağlık Kontrolü'),
      ),
      body: const Center(
        child: Text('Sağlık Kontrolü - Yakında!'),
      ),
    );
  }
}
