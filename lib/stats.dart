import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() =>
      _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with TickerProviderStateMixin {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref();

  final User? _user =
      FirebaseAuth.instance.currentUser;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
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
        padding:
            const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.16),
              color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  color.withOpacity(0.10),
              blurRadius: 14,
              offset:
                  const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                      14),
              decoration:
                  BoxDecoration(
                color: color.withOpacity(
                    0.15),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        TextStyle(
                      fontSize: 14,
                      color: Colors
                          .grey.shade600,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                  const SizedBox(
                      height: 4),
                  Text(
                    count.toString(),
                    style:
                        TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight
                              .bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(
    String categoryName,
    int total,
    int correct,
  ) {
    double rate =
        total == 0 ? 0 : correct / total;

    int percent =
        (rate * 100).toInt();

    Color barColor;

    if (percent >= 70) {
      barColor = Colors.green;
    } else if (percent >= 40) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                "%$percent ($correct/$total)",
                style: TextStyle(
                  color: Colors
                      .grey.shade600,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
                    20),
            child:
                LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor:
                  Colors.grey.shade300,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(
        child: Text(
          "Kullanıcı girişi yapılmadı.",
        ),
      );
    }

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final primary =
        Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child:
            FutureBuilder<DataSnapshot>(
          future: _dbRef
              .child(
                'Users/${_user!.uid}/stats',
              )
              .get(),
          builder:
              (context, snapshot) {
            if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            int totalQuestions = 0;
            int correctAnswers = 0;
            int wrongAnswers = 0;

            Map<dynamic, dynamic>
                categories = {};

            if (snapshot.hasData &&
                snapshot
                    .data!
                    .exists) {
              Map<dynamic, dynamic>
                  stats =
                  snapshot.data!
                          .value
                      as Map<
                          dynamic,
                          dynamic>;

              totalQuestions =
                  stats[
                          'totalQuestions'] ??
                      0;

              correctAnswers =
                  stats[
                          'correctAnswers'] ??
                      0;

              wrongAnswers =
                  stats[
                          'wrongAnswers'] ??
                      0;

              if (stats[
                      'categories'] !=
                  null) {
                categories =
                    stats[
                        'categories'];
              }
            }

            double successRate =
                totalQuestions == 0
                    ? 0
                    : (correctAnswers /
                            totalQuestions) *
                        100;

            if (totalQuestions ==
                0) {
              return const Center(
                child: Text(
                  "Henüz istatistik oluşmadı.\nLütfen önce bir Quiz çözün.",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            }

            List<
                MapEntry<
                    dynamic,
                    dynamic>> sortedCategories =
                categories.entries
                    .toList();

            sortedCategories.sort(
              (a, b) {
                int aTotal =
                    a.value['total'] ??
                        0;

                int aCorrect =
                    a.value[
                            'correct'] ??
                        0;

                int bTotal =
                    b.value['total'] ??
                        0;

                int bCorrect =
                    b.value[
                            'correct'] ??
                        0;

                double aRate =
                    aTotal == 0
                        ? 0
                        : aCorrect /
                            aTotal;

                double bRate =
                    bTotal == 0
                        ? 0
                        : bCorrect /
                            bTotal;

                return bRate
                    .compareTo(
                        aRate);
              },
            );

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                      18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const SizedBox(
                      height: 10),

                  // HEADER
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(24),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  26),
                      gradient:
                          LinearGradient(
                        colors: isDark
                            ? [
                                Colors
                                    .deepPurple
                                    .shade800,
                                Colors
                                    .deepPurple
                                    .shade600,
                              ]
                            : [
                                Colors
                                    .deepPurple
                                    .shade400,
                                Colors
                                    .deepPurple
                                    .shade700,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .deepPurple
                              .withOpacity(
                                  0.30),
                          blurRadius:
                              18,
                          offset:
                              const Offset(
                                  0,
                                  8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          "📊 Genel İstatistikler",
                          style:
                              TextStyle(
                            color: Colors
                                .white
                                .withOpacity(
                                    0.9),
                            fontSize:
                                22,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                            height:
                                10),
                        Text(
                          "Başarı Oranı",
                          style:
                              TextStyle(
                            color: Colors
                                .white
                                .withOpacity(
                                    0.75),
                          ),
                        ),
                        const SizedBox(
                            height:
                                4),
                        Text(
                          "%${successRate.toStringAsFixed(1)}",
                          style:
                              const TextStyle(
                            color: Colors
                                .white,
                            fontSize:
                                32,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 28),

                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration:
                            BoxDecoration(
                          color:
                              primary,
                          borderRadius:
                              BorderRadius.circular(
                                  5),
                        ),
                      ),
                      const SizedBox(
                          width: 10),
                      const Text(
                        "Genel Veriler",
                        style:
                            TextStyle(
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 16),

                  _buildStatCard(
                    "Çözülen Soru",
                    totalQuestions,
                    Icons
                        .quiz_rounded,
                    Colors.blue,
                    0,
                  ),

                  const SizedBox(
                      height: 14),

                  _buildStatCard(
                    "Doğru Sayısı",
                    correctAnswers,
                    Icons
                        .check_circle_rounded,
                    Colors.green,
                    80,
                  ),

                  const SizedBox(
                      height: 14),

                  _buildStatCard(
                    "Yanlış Sayısı",
                    wrongAnswers,
                    Icons
                        .cancel_rounded,
                    Colors.red,
                    160,
                  ),

                  const SizedBox(
                      height: 28),

                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration:
                            BoxDecoration(
                          color:
                              primary,
                          borderRadius:
                              BorderRadius.circular(
                                  5),
                        ),
                      ),
                      const SizedBox(
                          width: 10),
                      const Text(
                        "Kategori Analizi",
                        style:
                            TextStyle(
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 16),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(18),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  22),
                      color: Theme.of(
                              context)
                          .colorScheme
                          .surfaceContainer,
                    ),
                    child: Column(
                      children:
                          sortedCategories.map(
                        (entry) {
                          String name =
                              entry.key;

                          int total =
                              entry.value[
                                      'total'] ??
                                  0;

                          int correct =
                              entry.value[
                                      'correct'] ??
                                  0;

                          return _buildCategoryProgress(
                            name,
                            total,
                            correct,
                          );
                        },
                      ).toList(),
                    ),
                  ),

                  const SizedBox(
                      height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}