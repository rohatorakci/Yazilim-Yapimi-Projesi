import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintReport extends StatefulWidget {
  const PrintReport({super.key});

  @override
  State<PrintReport> createState() => _PrintReportState();
}

class _PrintReportState extends State<PrintReport> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;

  // Genel İstatistikler
  int _totalQuestionsSolved = 0;
  int _totalCorrect = 0;
  int _totalWrong = 0;

  // Kategori istatistiklerini tutacağımız liste
  // Örn: {'Action': {'total': 10, 'success': 8}}
  final Map<String, Map<String, int>> _categoryStats = {};

  @override
  void initState() {
    super.initState();
    _analyzeData();
  }

  Future<void> _analyzeData() async {
    if (_user == null) return;

    try {
      // 1. Tüm kelimeleri ve kullanıcının ilerlemesini çek
      final wordsSnap = await _dbRef.child('words').get();
      final progressSnap = await _dbRef
          .child('Users/${_user.uid}/wordProgress')
          .get();

      if (!wordsSnap.exists || !progressSnap.exists) {
        setState(() => _isLoading = false);
        return;
      }

      Map<dynamic, dynamic> allWords = wordsSnap.value as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> userProgress =
          progressSnap.value as Map<dynamic, dynamic>;

      int tempTotalQuestions = 0;
      int tempTotalCorrect = 0;
      int tempTotalWrong = 0;

      // 2. Verileri analiz et
      userProgress.forEach((wordId, progressData) {
        // Kelime veritabanında var mı ve kategorisi ne?
        if (allWords.containsKey(wordId)) {
          String category = allWords[wordId]['category'] ?? 'Genel';
          int level = progressData['level'] ?? 0;

          // Kategoriyi map'e ekle yoksa başlat
          if (!_categoryStats.containsKey(category)) {
            _categoryStats[category] = {'total': 0, 'success': 0};
          }

          // Kategori bazlı istatistikleri artır
          _categoryStats[category]!['total'] =
              _categoryStats[category]!['total']! + 1;

          // Genel istatistikleri artır
          tempTotalQuestions++;

          if (level > 0) {
            // Başarılı (Doğru)
            _categoryStats[category]!['success'] =
                _categoryStats[category]!['success']! + 1;
            tempTotalCorrect++;
          } else {
            // Başarısız (Yanlış)
            tempTotalWrong++;
          }
        }
      });

      setState(() {
        _totalQuestionsSolved = tempTotalQuestions;
        _totalCorrect = tempTotalCorrect;
        _totalWrong = tempTotalWrong;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Analiz hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  // PDF Oluşturma ve Yazdırma Fonksiyonu
  Future<void> _printDocument() async {
    final doc = pw.Document();

    // Türkçe karakter destekli fontlar
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Genel Başarı Yüzdesi
    double generalPercentage = _totalQuestionsSolved > 0
        ? (_totalCorrect / _totalQuestionsSolved) * 100
        : 0;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Başlık
              pw.Header(
                level: 0,
                child: pw.Text(
                  "Kullanici Analiz Raporu",
                  style: pw.TextStyle(font: fontBold, fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 20),

              // GENEL İSTATİSTİKLER BÖLÜMÜ (PDF İÇİN)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Genel Ozet",
                      style: pw.TextStyle(font: fontBold, fontSize: 18),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      "Toplam Cozulen Kelime: $_totalQuestionsSolved",
                      style: pw.TextStyle(font: font, fontSize: 14),
                    ),
                    pw.Text(
                      "Dogru Bilinen: $_totalCorrect",
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        color: PdfColors.green700,
                      ),
                    ),
                    pw.Text(
                      "Yanlis Bilinen: $_totalWrong",
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "Genel Basari Orani: %${generalPercentage.toStringAsFixed(1)}",
                      style: pw.TextStyle(font: fontBold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              pw.Text(
                "Konulara Gore Basari Yuzdeleri:",
                style: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              pw.SizedBox(height: 10),

              // Kategorileri PDF'e yazdır
              ..._categoryStats.entries.map((entry) {
                String category = entry.key;
                int total = entry.value['total']!;
                int success = entry.value['success']!;
                double percentage = (success / total) * 100;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        category,
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                      pw.Text(
                        "%${percentage.toStringAsFixed(1)} ($success/$total)",
                        style: pw.TextStyle(font: font, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),

              // Rapor Oluşturulma Tarihi
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Rapor Tarihi: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Çıktı önizleme ve yazdırma ekranını aç
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Analiz_Raporu',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Raporu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // YAZDIR BUTONU
          if (!_isLoading && _categoryStats.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Çıktı Al',
              onPressed: _printDocument,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categoryStats.isEmpty
          ? const Center(
              child: Text(
                "Henüz yeterli veriniz yok.\nBiraz Quiz çözdükten sonra tekrar gelin!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : CustomScrollView(
              slivers: [
                // GENEL ÖZET KARTI (EKRAN İÇİN)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text(
                              "Genel Performans Özeti",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 30, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryStat(
                                  "Toplam",
                                  "$_totalQuestionsSolved",
                                  Colors.blue,
                                ),
                                _buildSummaryStat(
                                  "Doğru",
                                  "$_totalCorrect",
                                  Colors.green,
                                ),
                                _buildSummaryStat(
                                  "Yanlış",
                                  "$_totalWrong",
                                  Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // KATEGORİ LİSTESİ BAŞLIĞI
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      "Kategori Bazlı Detaylar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // KATEGORİ LİSTESİ (EKRAN İÇİN)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    String category = _categoryStats.keys.elementAt(index);
                    int total = _categoryStats[category]!['total']!;
                    int success = _categoryStats[category]!['success']!;

                    // Yüzde hesaplama
                    double percentage = (success / total);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "%${(percentage * 100).toStringAsFixed(1)}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: percentage >= 0.5
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade300,
                              color: percentage >= 0.5
                                  ? Colors.green
                                  : Colors.red,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$total kelimeden $success tanesi başarıyla öğreniliyor/öğrenildi.",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: _categoryStats.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
    );
  }

  // Genel istatistikleri ekranda göstermek için yardımcı widget
  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
