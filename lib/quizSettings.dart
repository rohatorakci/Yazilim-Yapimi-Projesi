import 'package:flutter/material.dart';

class QuizSettingsPage extends StatelessWidget {
  const QuizSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Ayarları'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Quiz Ayarları Yapım Aşamasında',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}