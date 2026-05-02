import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  // İstatistik Kartı Tasarımı
  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
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

  // Kategori Bazlı İlerleme Çubuğu Widget'ı
  Widget _buildCategoryProgress(String categoryName, int total, int correct) {
    double successRate = total == 0 ? 0 : correct / total;
    int percentage = (successRate * 100).toInt();

    // Yüzdeye göre renk değiştirme
    Color barColor;
    if (percentage >= 70) {
      barColor = Colors.green;
    } else if (percentage >= 40) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '%$percentage ($correct / $total)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: successRate,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
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
      return const Center(child: Text('Kullanıcı girişi yapılmadı.'));
    }

    return SafeArea(
      child: FutureBuilder<DataSnapshot>(
        future: _dbRef.child('Users/${_user!.uid}/stats').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          int totalQuestions = 0;
          int correctAnswers = 0;
          int wrongAnswers = 0;
          Map<dynamic, dynamic> categories = {};

          if (snapshot.hasData && snapshot.data!.exists) {
            Map<dynamic, dynamic> stats =
                snapshot.data!.value as Map<dynamic, dynamic>;
            totalQuestions = stats['totalQuestions'] ?? 0;
            correctAnswers = stats['correctAnswers'] ?? 0;
            wrongAnswers = stats['wrongAnswers'] ?? 0;
            if (stats['categories'] != null) {
              categories = stats['categories'] as Map<dynamic, dynamic>;
            }
          }

          double successRate = totalQuestions == 0
              ? 0
              : (correctAnswers / totalQuestions) * 100;

          if (totalQuestions == 0) {
            return const Center(
              child: Text(
                'Henüz istatistik oluşmadı.\nLütfen önce bir Quiz çözün.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Kategorileri başarı oranına göre büyükten küçüğe (descending) sıralıyoruz
          List<MapEntry<dynamic, dynamic>> sortedCategories = categories.entries
              .toList();
          sortedCategories.sort((a, b) {
            int aTotal = a.value['total'] ?? 0;
            int aCorrect = a.value['correct'] ?? 0;
            double aRate = aTotal == 0 ? 0 : aCorrect / aTotal;

            int bTotal = b.value['total'] ?? 0;
            int bCorrect = b.value['correct'] ?? 0;
            double bRate = bTotal == 0 ? 0 : bCorrect / bTotal;

            return bRate.compareTo(
              aRate,
            ); // b'yi a ile karşılaştırmak büyükten küçüğe sıralar
          });

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Genel İstatistiklerim',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Genel Başarı Oranı: %${successRate.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  _buildStatCard(
                    'Çözülen Soru',
                    totalQuestions,
                    Icons.quiz,
                    Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    'Doğru Sayısı',
                    correctAnswers,
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(height: 10),
                  _buildStatCard(
                    'Yanlış Sayısı',
                    wrongAnswers,
                    Icons.cancel,
                    Colors.red,
                  ),

                  const Divider(height: 40, thickness: 2),

                  Text(
                    'Kategori Bazlı Analiz',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  categories.isEmpty
                      ? const Text('Henüz kategori verisi oluşmadı.')
                      : Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              // Artık sıradan map yerine sortedCategories'i dönüyoruz
                              children: sortedCategories.map((entry) {
                                String categoryName = entry.key;
                                int catTotal = entry.value['total'] ?? 0;
                                int catCorrect = entry.value['correct'] ?? 0;
                                return _buildCategoryProgress(
                                  categoryName,
                                  catTotal,
                                  catCorrect,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
