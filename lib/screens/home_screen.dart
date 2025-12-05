import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blogify'),
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'This is my home page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
