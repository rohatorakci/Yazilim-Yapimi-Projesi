import 'dart:async';
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
  bool _isSaved = false;

  final List<Map<String, dynamic>> _quizResults = [];

  // Kullanıcının her soru için seçtiği cevapları tutan harita (Index: Cevap)
  final Map<int, String> _selectedAnswers = {};

  final List<int> _intervals = [1, 7, 30, 90, 180, 365];

  Timer? _timer;
  int _timeLeft = 180;
  int _targetQuestionCount = 10;
  bool _isUnlimitedTime = false;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isUnlimitedTime) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  String get _formattedTime {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Sadece cevabı işaretler, veritabanına GÖNDERMEZ
  void _selectAnswer(String option) {
    setState(() {
      _selectedAnswers[_currentIndex] = option;
    });
  }

  // Önceki soruya geçiş
  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  // Sonraki soruya geçiş
  void _nextQuestion() {
    if (_currentIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishQuiz(); // Son sorudaysa testi bitirir
    }
  }

  // Testi bitirme ve TÜM VERİLERİ tek seferde kaydetme
  Future<void> _finishQuiz() async {
    if (_isSaved) return;
    _isSaved = true;
    _timer?.cancel();
    setState(
      () => _isLoading = true,
    ); // Kayıt işlemi bitene kadar yükleme göster

    _correctAnswersCount = 0;
    _quizResults.clear();
    DateTime now = DateTime.now();

    // Tüm cevapları değerlendir ve sonuç listesini hazırla
    Map<String, dynamic> wordProgressUpdates = {};

    for (int i = 0; i < _quizQuestions.length; i++) {
      var q = _quizQuestions[i];
      String? selected = _selectedAnswers[i]; // Boş bırakılmış olabilir

      bool isCorrect = (selected == q['correctAnswer']);
      if (isCorrect) _correctAnswersCount++;

      _quizResults.add({
        'english': q['english'],
        'selectedAnswer': selected ?? "Boş Bırakıldı",
        'correctAnswer': q['correctAnswer'],
        'isCorrect': isCorrect,
        'category': q['category'],
      });

      int currentLevel = q['currentLevel'];
      int newLevel;
      int nextReviewDate;

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
        nextReviewDate = now
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch;
      }

      // Güncellenecek kelime verilerini map'e ekle
      wordProgressUpdates[q['wordId']] = {
        'level': newLevel,
        'nextReviewDate': nextReviewDate,
        'lastAnswered': now.millisecondsSinceEpoch,
      };
    }

    if (_user != null && _quizQuestions.isNotEmpty) {
      int totalAnswered = _quizQuestions.length;
      int wrongAnswers = totalAnswered - _correctAnswersCount;

      // 1. Kelime İlerlemelerini (Word Progress) Tek Seferde Kaydet
      for (var entry in wordProgressUpdates.entries) {
        await _dbRef
            .child('Users/${_user.uid}/wordProgress/${entry.key}')
            .set(entry.value);
      }

      // 2. Geçmişi Kaydet
      await _dbRef
          .child('Users/${_user.uid}/quizHistory/${now.millisecondsSinceEpoch}')
          .set({
            'date': now.toIso8601String(),
            'totalAnswered': totalAnswered,
            'correctAnswers': _correctAnswersCount,
            'wrongAnswers': wrongAnswers,
          });

      // 3. Genel İstatistikleri Güncelle
      DatabaseReference statsRef = _dbRef.child('Users/${_user.uid}/stats');
      final snapshot = await statsRef.get();

      int currentTotal = 0;
      int currentCorrect = 0;
      int currentWrong = 0;
      Map<dynamic, dynamic> currentCategories = {};

      if (snapshot.exists) {
        Map<dynamic, dynamic> stats = snapshot.value as Map<dynamic, dynamic>;
        currentTotal = stats['totalQuestions'] ?? 0;
        currentCorrect = stats['correctAnswers'] ?? 0;
        currentWrong = stats['wrongAnswers'] ?? 0;
        if (stats['categories'] != null) {
          currentCategories = stats['categories'] as Map<dynamic, dynamic>;
        }
      }

      Map<String, dynamic> updatedCategories = Map<String, dynamic>.from(
        currentCategories,
      );

      for (var result in _quizResults) {
        String category = result['category'] ?? 'General';
        bool isCorrect = result['isCorrect'];

        if (!updatedCategories.containsKey(category)) {
          updatedCategories[category] = {'total': 0, 'correct': 0};
        }

        updatedCategories[category]['total'] =
            (updatedCategories[category]['total'] ?? 0) + 1;
        if (isCorrect) {
          updatedCategories[category]['correct'] =
              (updatedCategories[category]['correct'] ?? 0) + 1;
        }
      }

      await statsRef.update({
        'totalQuestions': currentTotal + totalAnswered,
        'correctAnswers': currentCorrect + _correctAnswersCount,
        'wrongAnswers': currentWrong + wrongAnswers,
        'categories': updatedCategories,
      });
    }

    setState(() {
      _isLoading = false;
      _quizFinished = true;
    });
  }

  Future<void> _generateQuiz() async {
    if (_user == null) return;

    try {
      final settingsSnapshot = await _dbRef
          .child('Users/${_user.uid}/settings')
          .get();
      if (settingsSnapshot.exists) {
        Map<dynamic, dynamic> settings =
            settingsSnapshot.value as Map<dynamic, dynamic>;
        _targetQuestionCount = settings['questionCount'] ?? 10;
        int savedDuration = settings['quizDuration'] ?? 180;

        if (savedDuration == 0) {
          _isUnlimitedTime = true;
        } else {
          _timeLeft = savedDuration;
        }
      }

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
      selectedWords.addAll(dueWords.take(_targetQuestionCount));
      if (selectedWords.length < _targetQuestionCount) {
        selectedWords.addAll(
          newWords.take(_targetQuestionCount - selectedWords.length),
        );
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
          "category": wordInfo['category'] ?? "General",
          "currentLevel": userProgress[wordInfo['id']]?['level'] ?? 0,
        });
      }

      setState(() {
        _quizQuestions = generatedQuestions;
        _isLoading = false;
      });

      if (_quizQuestions.isNotEmpty) {
        _startTimer();
      }
    } catch (e) {
      debugPrint("Quiz oluşturulurken hata: $e");
      setState(() => _isLoading = false);
    }
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

  Widget _buildResultScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Sonuçları'),
        automaticallyImplyLeading: false,
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isUnlimitedTime && _timeLeft == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Süreniz Doldu!",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: _quizResults.length,
              itemBuilder: (context, index) {
                var result = _quizResults[index];
                bool isCorrect = result['isCorrect'];
                bool isSkipped = result['selectedAnswer'] == "Boş Bırakıldı";

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      isCorrect
                          ? Icons.check_circle
                          : (isSkipped ? Icons.help_outline : Icons.cancel),
                      color: isCorrect
                          ? Colors.green
                          : (isSkipped ? Colors.orange : Colors.red),
                      size: 36,
                    ),
                    title: Text(
                      result['english'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (!isCorrect)
                          Text(
                            'Senin Cevabın: ${result['selectedAnswer']}',
                            style: TextStyle(
                              color: isSkipped ? Colors.orange : Colors.red,
                              decoration: isSkipped
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          isCorrect
                              ? 'Doğru Bildin: ${result['correctAnswer']}'
                              : 'Doğrusu: ${result['correctAnswer']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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
                label: const Text(
                  'Ana Sayfaya Dön',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
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

    // Şu anki soruda hangi şıkkın seçili olduğunu kontrol et
    String? currentSelectedOption = _selectedAnswers[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${_currentIndex + 1} / ${_quizQuestions.length}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isUnlimitedTime)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _timeLeft <= 30
                        ? Colors.red
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 20,
                        color: _timeLeft <= 30
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft <= 30
                              ? Colors.white
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

            // ŞIKLAR BÖLÜMÜ
            ...(currentQuestion['options'] as List<String>).map((option) {
              bool isSelected = option == currentSelectedOption;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _selectAnswer(option),
                  child: Text(option),
                ),
              );
            }),

            const Spacer(flex: 1),

            // ALT MENÜ - İLERİ / GERİ BUTONLARI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0 ? _previousQuestion : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Önceki'),
                ),
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentIndex == _quizQuestions.length - 1
                        ? Colors.green
                        : null,
                    foregroundColor: _currentIndex == _quizQuestions.length - 1
                        ? Colors.white
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentIndex == _quizQuestions.length - 1
                            ? 'Testi Bitir'
                            : 'Sonraki',
                      ),
                      if (_currentIndex < _quizQuestions.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.arrow_forward),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
