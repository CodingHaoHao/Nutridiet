import 'package:flutter/material.dart';

class LoggingPage extends StatelessWidget {
  const LoggingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: const Text('Logging')),
      body: const Center(
        child: Text('Logging page — add your logging UI here'),
      ),
    );
  }
}
