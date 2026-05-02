import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class WordlePage extends StatefulWidget {
  const WordlePage({super.key});

  @override
  State<WordlePage> createState() => _WordlePageState();
}

enum GameStatus { playing, won, lost }

class _WordlePageState extends State<WordlePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  String _targetWord = "";
  String _categoryHint = "";

  int _maxGuesses = 5; // Artık final değil, kelimeye göre dinamik hesaplanacak
  List<String> _guesses = [];
  String _currentGuess = "";

  GameStatus _gameStatus = GameStatus.playing;

  final Map<String, Color> _keyboardColors = {};

  @override
  void initState() {
    super.initState();
    _fetchLevel6Words();
  }

  Future<void> _fetchLevel6Words() async {
    if (_user == null) return;

    setState(() {
      _isLoading = true;
      _guesses.clear();
      _currentGuess = "";
      _gameStatus = GameStatus.playing;
      _keyboardColors.clear();
    });

    try {
      final wordsSnap = await _dbRef.child('words').get();
      final progressSnap = await _dbRef
          .child('Users/${_user!.uid}/wordProgress')
          .get();

      if (!wordsSnap.exists || !progressSnap.exists) {
        setState(() => _isLoading = false);
        return;
      }

      Map<dynamic, dynamic> allWords = wordsSnap.value as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> userProgress =
          progressSnap.value as Map<dynamic, dynamic>;

      List<Map<String, dynamic>> level6Words = [];

      userProgress.forEach((wordId, progressData) {
        int level = progressData['level'] ?? 0;

        if (level >= 6 && allWords.containsKey(wordId)) {
          String englishWord = allWords[wordId]['english']
              .toString()
              .trim()
              .toUpperCase();

          // Uzunluk sınırı yok, sadece tek kelime olacak
          if (!englishWord.contains(' ') && !englishWord.contains('-')) {
            level6Words.add({
              'english': englishWord,
              'category': allWords[wordId]['category'] ?? 'Genel',
            });
          }
        }
      });

      if (level6Words.isNotEmpty) {
        final random = Random();
        var selectedWord = level6Words[random.nextInt(level6Words.length)];

        setState(() {
          _targetWord = selectedWord['english'];
          _categoryHint = selectedWord['category'];

          // Maksimum hak hesabı (En az 5, uzun kelimelerde Harf Sayısı - 2)
          _maxGuesses = max(5, _targetWord.length - 2);

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Wordle verisi çekilirken hata: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onKeyPressed(String key) {
    if (_gameStatus != GameStatus.playing) return;

    setState(() {
      if (key == 'ENTER') {
        if (_currentGuess.length == _targetWord.length) {
          _submitGuess();
        } else {
          _showSnackBar("Kelime ${_targetWord.length} harfli olmalı!");
        }
      } else if (key == 'DEL') {
        if (_currentGuess.isNotEmpty) {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
        }
      } else {
        if (_currentGuess.length < _targetWord.length) {
          _currentGuess += key;
        }
      }
    });
  }

  void _submitGuess() {
    setState(() {
      _guesses.add(_currentGuess);
      _updateKeyboardColors(_currentGuess);

      if (_currentGuess == _targetWord) {
        _gameStatus = GameStatus.won;
      } else if (_guesses.length >= _maxGuesses) {
        _gameStatus = GameStatus.lost;
      }

      _currentGuess = "";
    });
  }

  void _updateKeyboardColors(String guess) {
    List<bool> targetUsed = List.filled(_targetWord.length, false);

    for (int i = 0; i < guess.length; i++) {
      String letter = guess[i];
      if (letter == _targetWord[i]) {
        _keyboardColors[letter] = Colors.green;
        targetUsed[i] = true;
      }
    }

    for (int i = 0; i < guess.length; i++) {
      String letter = guess[i];
      if (letter != _targetWord[i]) {
        bool found = false;
        for (int j = 0; j < _targetWord.length; j++) {
          if (!targetUsed[j] && letter == _targetWord[j]) {
            if (_keyboardColors[letter] != Colors.green) {
              _keyboardColors[letter] = Colors.orange;
            }
            targetUsed[j] = true;
            found = true;
            break;
          }
        }
        if (!found &&
            _keyboardColors[letter] != Colors.green &&
            _keyboardColors[letter] != Colors.orange) {
          _keyboardColors[letter] = Colors.grey.shade700;
        }
      }
    }
  }

  List<Color> _getColorsForGuess(String guess) {
    List<Color> colors = List.filled(guess.length, Colors.grey.shade800);
    List<bool> targetUsed = List.filled(_targetWord.length, false);
    List<bool> guessUsed = List.filled(guess.length, false);

    for (int i = 0; i < guess.length; i++) {
      if (guess[i] == _targetWord[i]) {
        colors[i] = Colors.green;
        targetUsed[i] = true;
        guessUsed[i] = true;
      }
    }

    for (int i = 0; i < guess.length; i++) {
      if (!guessUsed[i]) {
        for (int j = 0; j < _targetWord.length; j++) {
          if (!targetUsed[j] && guess[i] == _targetWord[j]) {
            colors[i] = Colors.orange;
            targetUsed[j] = true;
            break;
          }
        }
      }
    }
    return colors;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wordle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_targetWord.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wordle')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Uygun kritere sahip öğrendiğiniz (Level 6) kelime bulunamadı.\nÖnce biraz Quiz çözerek kelime öğrenin!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    int remainingGuesses = _maxGuesses - _guesses.length;
    bool showHint = remainingGuesses <= 3; // Kilit açılma şartı

    // KUTULARI EKRANA GÖRE DİNAMİK ÖLÇEKLENDİRME
    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidth = screenWidth - 32; // Kenar boşlukları
    double totalMargin =
        _targetWord.length * 4; // Her kutu için sağlı sollu 2px boşluk
    double rawBoxSize = (availableWidth - totalMargin) / _targetWord.length;
    double boxSize = rawBoxSize > 55
        ? 55
        : rawBoxSize; // Kutunun maksimum büyüklüğü 55 olsun
    double letterFontSize =
        boxSize * 0.55; // Font boyutunu da kutu boyuna göre ayarla

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordle Oyna'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yeni Kelime',
            onPressed: _fetchLevel6Words,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Üst Bilgi Paneli: Kilitli/Açık İpucu ve Kalan Hak
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        showHint ? Icons.category : Icons.lock,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        showHint ? _categoryHint : "İpucu Kilitli",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: remainingGuesses <= 2
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 18,
                        color: remainingGuesses <= 2
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$remainingGuesses Hak",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: remainingGuesses <= 2
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // WORDLE GRID (Tahmin Kutuları)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(_maxGuesses, (rowIndex) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_targetWord.length, (colIndex) {
                      String letter = "";
                      Color boxColor = Colors.transparent;
                      Color textColor = Theme.of(context).colorScheme.onSurface;

                      if (rowIndex < _guesses.length) {
                        letter = _guesses[rowIndex][colIndex];
                        List<Color> guessColors = _getColorsForGuess(
                          _guesses[rowIndex],
                        );
                        boxColor = guessColors[colIndex];
                        textColor = Colors.white;
                      } else if (rowIndex == _guesses.length &&
                          colIndex < _currentGuess.length) {
                        letter = _currentGuess[colIndex];
                      }

                      return Container(
                        width: boxSize,
                        height: boxSize,
                        margin: const EdgeInsets.all(
                          2,
                        ), // Boşlukları daralttık ki uzun kelimeler sığsın
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: boxColor,
                          border: Border.all(
                            color: boxColor == Colors.transparent
                                ? Colors.grey.shade400
                                : boxColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: letterFontSize,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),

          // SONUÇ EKRANI
          if (_gameStatus != GameStatus.playing)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _gameStatus == GameStatus.won
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _gameStatus == GameStatus.won
                        ? "Tebrikler, Bildin!"
                        : "Maalesef Bilemedin!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _gameStatus == GameStatus.won
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kelime: $_targetWord",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchLevel6Words,
                    child: const Text("Yeni Kelime Oyna"),
                  ),
                ],
              ),
            ),

          // SANAL KLAVYE
          if (_gameStatus == GameStatus.playing) _buildKeyboard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final keyWidth = (screenWidth - 20) / 10 - 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return _buildKey(key, keyWidth);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key, double keyWidth) {
    bool isAction = key == 'ENTER' || key == 'DEL';
    Color bgColor =
        _keyboardColors[key] ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    Color textColor = _keyboardColors.containsKey(key)
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    double width = isAction ? (keyWidth * 1.5) : keyWidth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: InkWell(
        onTap: () => _onKeyPressed(key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: width,
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            key,
            style: TextStyle(
              fontSize: isAction ? 14 : 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
