import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  List<Map<String, dynamic>> _quizQuestions = [];
  int _currentIndex = 0;
  int _correctAnswersCount = 0;
  bool _quizFinished = false;

  // Kullanıcının verdiği cevapları tutacağımız liste
  final List<Map<String, dynamic>> _quizResults = [];

  // Algoritma için bekleme süreleri (Gün cinsinden)
  final List<int> _intervals = [1, 7, 30, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
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

      Map<dynamic, dynamic> allWords =
          wordsSnapshot.value as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> userProgress = progressSnapshot.exists
          ? progressSnapshot.value as Map<dynamic, dynamic>
          : {};

      List<Map<String, dynamic>> dueWords = [];
      List<Map<String, dynamic>> newWords = [];
      List<String> allTurkishMeanings = [];

      int now = DateTime.now().millisecondsSinceEpoch;

      allWords.forEach((key, value) {
        String wordId = key.toString();
        allTurkishMeanings.add(value['turkish'].toString());

        if (userProgress.containsKey(wordId)) {
          var progress = userProgress[wordId];
          int nextReviewDate = progress['nextReviewDate'] ?? 0;
          int level = progress['level'] ?? 0;

          if (level < 6 && now >= nextReviewDate) {
            dueWords.add({"id": wordId, ...value});
          }
        } else {
          newWords.add({"id": wordId, ...value});
        }
      });

      dueWords.shuffle();
      newWords.shuffle();

      List<Map<String, dynamic>> selectedWords = [];
      selectedWords.addAll(dueWords.take(10));
      if (selectedWords.length < 10) {
        selectedWords.addAll(newWords.take(10 - selectedWords.length));
      }

      List<Map<String, dynamic>> generatedQuestions = [];
      final random = Random();

      for (var wordInfo in selectedWords) {
        String correctTurkish = wordInfo['turkish'];
        List<String> options = [correctTurkish];

        while (options.length < 4) {
          String randomMeaning =
              allTurkishMeanings[random.nextInt(allTurkishMeanings.length)];
          if (!options.contains(randomMeaning)) {
            options.add(randomMeaning);
          }
        }
        options.shuffle();

        generatedQuestions.add({
          "wordId": wordInfo['id'],
          "english": wordInfo['english'],
          "example": wordInfo['example'],
          "correctAnswer": correctTurkish,
          "options": options,
          "currentLevel": userProgress[wordInfo['id']]?['level'] ?? 0,
        });
      }

      setState(() {
        _quizQuestions = generatedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Quiz oluşturulurken hata: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAnswer(
    String selectedAnswer,
    Map<String, dynamic> question,
  ) async {
    bool isCorrect = selectedAnswer == question['correctAnswer'];
    if (isCorrect) _correctAnswersCount++;

    // Sonucu listeye kaydet
    _quizResults.add({
      'english': question['english'],
      'selectedAnswer': selectedAnswer,
      'correctAnswer': question['correctAnswer'],
      'isCorrect': isCorrect,
    });

    int currentLevel = question['currentLevel'];
    int newLevel;
    int nextReviewDate;

    DateTime now = DateTime.now();

    if (isCorrect) {
      newLevel = currentLevel + 1;
      int daysToAdd = (currentLevel < _intervals.length)
          ? _intervals[currentLevel]
          : 365;
      nextReviewDate = now
          .add(Duration(days: daysToAdd))
          .millisecondsSinceEpoch;
    } else {
      newLevel = 0;
      nextReviewDate = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
    }

    await _dbRef
        .child('Users/${_user!.uid}/wordProgress/${question['wordId']}')
        .set({
          'level': newLevel,
          'nextReviewDate': nextReviewDate,
          'lastAnswered': now.millisecondsSinceEpoch,
        });

    setState(() {
      if (_currentIndex < _quizQuestions.length - 1) {
        _currentIndex++;
      } else {
        _quizFinished = true;
      }
    });
  }

  List<TextSpan> _buildUnderlinedText(String sentence, String targetWord) {
    String lowerSentence = sentence.toLowerCase();
    String lowerTarget = targetWord.toLowerCase();
    int index = lowerSentence.indexOf(lowerTarget);

    if (index == -1) return [TextSpan(text: sentence)];

    return [
      TextSpan(text: sentence.substring(0, index)),
      TextSpan(
        text: sentence.substring(index, index + targetWord.length),
        style: TextStyle(
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      TextSpan(text: sentence.substring(index + targetWord.length)),
    ];
  }

  // Quiz bittiğinde gösterilecek olan sonuç ekranı widget'ı
  // Quiz bittiğinde gösterilecek olan sonuç ekranı widget'ı
  Widget _buildResultScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Sonuçları'),
        automaticallyImplyLeading: false, // Geri butonunu kapatıyoruz (Ana Sayfaya Dön butonu var)
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer,
            width: double.infinity,
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 60, color: Colors.orange),
                const SizedBox(height: 10),
                Text(
                  'Skor: $_correctAnswersCount / ${_quizQuestions.length}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(), // ESNEMEYİ (UZAMAYI) ENGELLEYEN KOD BURADA
              itemCount: _quizResults.length,
              itemBuilder: (context, index) {
                var result = _quizResults[index];
                bool isCorrect = result['isCorrect'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 36,
                    ),
                    title: Text(
                      result['english'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // Eğer yanlış yaptıysa, verdiği cevabı üstü çizili kırmızı gösteriyoruz
                        if (!isCorrect)
                          Text(
                            'Senin Cevabın: ${result['selectedAnswer']}',
                            style: const TextStyle(
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        // Doğru cevabı yeşil gösteriyoruz
                        Text(
                          isCorrect
                              ? 'Doğru Bildin: ${result['correctAnswer']}'
                              : 'Doğrusu: ${result['correctAnswer']}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Ana Sayfaya Dön', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Ol')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Ol')),
        body: const Center(
          child: Text("Test olacak yeterli kelime bulunamadı."),
        ),
      );
    }

    if (_quizFinished) {
      return _buildResultScreen();
    }

    var currentQuestion = _quizQuestions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${_currentIndex + 1} / ${_quizQuestions.length}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),
            Text(
              currentQuestion['english'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: _buildUnderlinedText(
                    currentQuestion['example'],
                    currentQuestion['english'],
                  ),
                ),
              ),
            ),
            const Spacer(flex: 2),
            ...(currentQuestion['options'] as List<String>).map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _handleAnswer(option, currentQuestion),
                  child: Text(option),
                ),
              );
            }),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
