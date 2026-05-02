import 'package:flutter/material.dart';

class WordlePage extends StatelessWidget {
  const WordlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordle Oyna'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Wordle Oyunu Yapım Aşamasında',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}