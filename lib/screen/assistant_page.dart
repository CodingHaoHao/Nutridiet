// lib/screen/assistant_page.dart
import 'package:flutter/material.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: const Text('Assistant')),
      body: const Center(
        child: Text('Assistant page — AI assistant UI goes here'),
      ),
    );
  }
}
