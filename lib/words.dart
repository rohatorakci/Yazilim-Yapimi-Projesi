import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({super.key});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;

  // Kelime listeleri
  List<Map<String, dynamic>> _wrongWords = []; // Lvl 0
  List<Map<String, dynamic>> _learningWords = []; // Lvl 1-5
  List<Map<String, dynamic>> _learnedWords = []; // Lvl 6
  List<Map<String, dynamic>> _allWords = []; // Tüm kelimeler

  @override
  void initState() {
    super.initState();
    _fetchWordsAndProgress();
  }

  Future<void> _fetchWordsAndProgress() async {
    if (_user == null) return;

    try {
      final wordsSnapshot = await _dbRef.child('words').get();
      final progressSnapshot = await _dbRef
          .child('Users/${_user.uid}/wordProgress')
          .get();

      if (!wordsSnapshot.exists) {
        setState(() => _isLoading = false);
        return;
      }

      Map<dynamic, dynamic> allWordsData =
          wordsSnapshot.value as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> userProgress = progressSnapshot.exists
          ? progressSnapshot.value as Map<dynamic, dynamic>
          : {};

      List<Map<String, dynamic>> wrong = [];
      List<Map<String, dynamic>> learning = [];
      List<Map<String, dynamic>> learned = [];
      List<Map<String, dynamic>> all = [];

      allWordsData.forEach((key, value) {
        String wordId = key.toString();
        Map<String, dynamic> wordMap = {
          "id": wordId,
          "english": value['english'],
          "turkish": value['turkish'],
        };

        all.add(wordMap);

        if (userProgress.containsKey(wordId)) {
          int level = userProgress[wordId]['level'] ?? 0;
          if (level == 0) {
            wrong.add(wordMap);
          } else if (level >= 1 && level <= 5) {
            learning.add(wordMap);
          } else if (level >= 6) {
            learned.add(wordMap);
          }
        }
      });

      setState(() {
        _wrongWords = wrong;
        _learningWords = learning;
        _learnedWords = learned;
        _allWords = all;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Kelimeler yüklenirken hata: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Havuzu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildCategoryTile(
                  "Yanlış Bildiğin Kelimeler",
                  _wrongWords,
                  Colors.red,
                ),
                _buildCategoryTile(
                  "Öğrenme Aşamasındaki Kelimeler",
                  _learningWords,
                  Colors.orange,
                ),
                _buildCategoryTile(
                  "Öğrendiğin Kelimeler",
                  _learnedWords,
                  Colors.green,
                ),
                const Divider(),
                _buildCategoryTile("Tüm Kelimeler", _allWords, Colors.blue),
              ],
            ),
    );
  }

  Widget _buildCategoryTile(
    String title,
    List<Map<String, dynamic>> words,
    Color color,
  ) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(
          words.length.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: words.isEmpty
          ? [const ListTile(title: Text("Bu kategoride kelime bulunmuyor."))]
          : words
                .map(
                  (word) => ListTile(
                    title: Text(
                      word['english'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(word['turkish']),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                  ),
                )
                .toList(),
    );
  }
}
