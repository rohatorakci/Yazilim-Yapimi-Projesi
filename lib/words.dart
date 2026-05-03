import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class WordsPage extends StatefulWidget {
  const WordsPage({super.key});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage>
    with TickerProviderStateMixin {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref();

  final User? _user =
      FirebaseAuth.instance.currentUser;

  bool _isLoading = true;

  List<Map<String, dynamic>> _wrongWords = [];
  List<Map<String, dynamic>> _learningWords = [];
  List<Map<String, dynamic>> _learnedWords = [];
  List<Map<String, dynamic>> _allWords = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
    _fetchWordsAndProgress();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchWordsAndProgress() async {
    if (_user == null) return;

    try {
      final wordsSnapshot =
          await _dbRef.child('words').get();

      final progressSnapshot = await _dbRef
          .child(
            'Users/${_user!.uid}/wordProgress',
          )
          .get();

      if (!wordsSnapshot.exists) {
        setState(() => _isLoading = false);
        return;
      }

      Map<dynamic, dynamic> allWordsData =
          wordsSnapshot.value
              as Map<dynamic, dynamic>;

      Map<dynamic, dynamic> userProgress =
          progressSnapshot.exists
              ? progressSnapshot.value
                  as Map<dynamic, dynamic>
              : {};

      List<Map<String, dynamic>> wrong =
          [];

      List<Map<String, dynamic>>
          learning = [];

      List<Map<String, dynamic>>
          learned = [];

      List<Map<String, dynamic>> all =
          [];

      allWordsData.forEach((key, value) {
        String wordId = key.toString();

        Map<String, dynamic> wordMap = {
          "id": wordId,
          "english": value['english'],
          "turkish": value['turkish'],
        };

        all.add(wordMap);

        if (userProgress.containsKey(
          wordId,
        )) {
          int level =
              userProgress[wordId]['level'] ??
                  0;

          if (level == 0) {
            wrong.add(wordMap);
          } else if (level >= 1 &&
              level <= 5) {
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
      debugPrint(
        "Kelimeler yüklenirken hata: $e",
      );

      setState(() => _isLoading = false);
    }
  }

  Widget _buildHeaderCard() {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.deepPurple
                      .shade800,
                  Colors.deepPurple
                      .shade600,
                ]
              : [
                  Colors.deepPurple
                      .shade400,
                  Colors.deepPurple
                      .shade700,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple
                .withOpacity(0.30),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  "📚 Kelime Havuzu",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                    height: 8),
                Text(
                  "Tüm ilerlemeni tek ekranda görüntüle",
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(
                            0.80),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.all(
                    14),
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    String title,
    List<Map<String, dynamic>> words,
    Color color,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(
                  22),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.04),
              blurRadius: 10,
              offset:
                  const Offset(
                      0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context)
              .copyWith(
            dividerColor:
                Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            childrenPadding:
                const EdgeInsets.only(
              left: 10,
              right: 10,
              bottom: 10,
            ),
            leading: CircleAvatar(
              backgroundColor:
                  color,
              child: Text(
                words.length
                    .toString(),
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight
                          .bold,
                ),
              ),
            ),
            title: Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),
            children: words.isEmpty
                ? [
                    const Padding(
                      padding:
                          EdgeInsets.all(
                              12),
                      child: Text(
                        "Bu kategoride kelime bulunmuyor.",
                      ),
                    ),
                  ]
                : words
                    .map(
                      (word) =>
                          Container(
                        margin:
                            const EdgeInsets.only(
                          bottom:
                              8,
                        ),
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                                  14),
                          color: Theme.of(
                                  context)
                              .colorScheme
                              .surface,
                        ),
                        child:
                            ListTile(
                          leading:
                              Icon(
                            Icons
                                .translate_rounded,
                            color:
                                color,
                          ),
                          title:
                              Text(
                            word[
                                'english'],
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              Text(
                            word[
                                'turkish'],
                          ),
                          trailing:
                              const Icon(
                            Icons
                                .chevron_right_rounded,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                          18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      _buildHeaderCard(),

                      const SizedBox(
                          height: 26),

                      Row(
                        children: [
                          Container(
                            width: 4,
                            height:
                                20,
                            decoration:
                                BoxDecoration(
                              color: Theme.of(
                                      context)
                                  .colorScheme
                                  .primary,
                              borderRadius:
                                  BorderRadius.circular(
                                      5),
                            ),
                          ),
                          const SizedBox(
                              width:
                                  10),
                          const Text(
                            "Kategoriler",
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 16),

                      _buildCategoryTile(
                        "Yanlış Bildiğin Kelimeler",
                        _wrongWords,
                        Colors.red,
                        0,
                      ),

                      _buildCategoryTile(
                        "Öğrenme Aşamasındaki Kelimeler",
                        _learningWords,
                        Colors.orange,
                        80,
                      ),

                      _buildCategoryTile(
                        "Öğrendiğin Kelimeler",
                        _learnedWords,
                        Colors.green,
                        160,
                      ),

                      _buildCategoryTile(
                        "Tüm Kelimeler",
                        _allWords,
                        Colors.blue,
                        240,
                      ),

                      const SizedBox(
                          height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}