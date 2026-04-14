import 'package:flutter/material.dart';

class CreateActivityScreen extends StatelessWidget {
  const CreateActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Activity')),
      body: const Center(
        child: Text('Create Activity Screen'),
      ),
    );
  }
}