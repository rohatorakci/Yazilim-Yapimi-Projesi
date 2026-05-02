import 'package:flutter/material.dart';

class AddWordsPage extends StatelessWidget {
  const AddWordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Ekle'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Kelime Ekleme Sayfası Yapım Aşamasında',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}