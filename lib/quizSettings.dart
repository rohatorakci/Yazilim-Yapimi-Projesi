import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class QuizSettingsPage extends StatefulWidget {
  const QuizSettingsPage({super.key});

  @override
  State<QuizSettingsPage> createState() => _QuizSettingsPageState();
}

class _QuizSettingsPageState extends State<QuizSettingsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;

  // Varsayılan değerler
  int _selectedQuestionCount = 10;
  int _selectedDuration = 180; // Saniye cinsinden (3 dakika)

  // Seçenekler
  final List<int> _questionOptions = [5, 10, 15, 20];
  // 1 dk(60s), 3 dk(180s), 5 dk(300s), 10 dk(600s), Limitsiz(0s)
  final Map<int, String> _durationOptions = {
    60: '1 Dakika',
    180: '3 Dakika',
    300: '5 Dakika',
    600: '10 Dakika',
    0: 'Süresiz',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Firebase'den mevcut ayarları çek
  Future<void> _loadSettings() async {
    if (_user == null) return;

    try {
      final snapshot = await _dbRef.child('Users/${_user!.uid}/settings').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> settings =
            snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _selectedQuestionCount = settings['questionCount'] ?? 10;
          _selectedDuration = settings['quizDuration'] ?? 180;
        });
      }
    } catch (e) {
      debugPrint("Ayarlar yüklenirken hata: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Ayarları Firebase'e kaydet
  Future<void> _saveSettings() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      await _dbRef.child('Users/${_user!.uid}/settings').update({
        'questionCount': _selectedQuestionCount,
        'quizDuration': _selectedDuration,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Ayarları')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Ayarları'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Soru Sayısı Ayarı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soru Sayısı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _selectedQuestionCount,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      items: _questionOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value Soru'),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedQuestionCount = newValue);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Süre Ayarı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiz Süresi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _selectedDuration,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      items: _durationOptions.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedDuration = newValue);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Kaydet Butonu
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text(
                  'Ayarları Kaydet',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveSettings,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
