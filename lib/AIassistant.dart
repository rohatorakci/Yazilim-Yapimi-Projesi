import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIassistant extends StatefulWidget {
  const AIassistant({super.key});

  @override
  State<AIassistant> createState() => _AIassistantState();
}

class _AIassistantState extends State<AIassistant> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  // --- Üretim Kısımı Değişkenleri ---
  bool _isLoading = false;
  bool _isWordsLoading = true;
  String _generatedStory = "";
  String _generatedImageBase64 = "";
  List<Map<String, String>> _availableWords = [];
  List<Map<String, String>> _selectedWords = [];

  // --- Geçmiş Hikayeler Kısımı Değişkenleri ---
  bool _isHistoryLoading = true;
  List<Map<dynamic, dynamic>> _storiesList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserWords();
    _fetchStories();
  }

  // --- VERİ ÇEKME İŞLEMLERİ ---
  Future<void> _fetchUserWords() async {
    if (_user == null) return;
    try {
      final progressSnapshot = await _dbRef
          .child('Users/${_user!.uid}/wordProgress')
          .get();
      final wordsSnapshot = await _dbRef.child('words').get();

      if (progressSnapshot.exists && wordsSnapshot.exists) {
        Map<dynamic, dynamic> userProgress =
            progressSnapshot.value as Map<dynamic, dynamic>;
        Map<dynamic, dynamic> allWords =
            wordsSnapshot.value as Map<dynamic, dynamic>;
        List<Map<String, String>> tempWords = [];

        userProgress.forEach((wordId, _) {
          if (allWords.containsKey(wordId)) {
            tempWords.add({
              'id': wordId.toString(),
              'english': allWords[wordId]['english'].toString(),
            });
          }
        });

        setState(() {
          _availableWords = tempWords;
        });
      }
    } catch (e) {
      debugPrint("Kelimeler çekilirken hata: $e");
    } finally {
      setState(() => _isWordsLoading = false);
    }
  }

  Future<void> _fetchStories() async {
    if (_user == null) return;
    try {
      final snapshot = await _dbRef
          .child('Users/${_user!.uid}/AI_Stories')
          .get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> storiesMap =
            snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> tempStories = [];

        storiesMap.forEach((key, value) {
          tempStories.add({'id': key, ...value});
        });

        tempStories.sort((a, b) {
          DateTime dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
          DateTime dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

        setState(() {
          _storiesList = tempStories;
        });
      } else {
        // Eğer hiç hikaye kalmadıysa listeyi boşalt
        setState(() {
          _storiesList = [];
        });
      }
    } catch (e) {
      debugPrint("Hikayeler çekilirken hata: $e");
    } finally {
      setState(() => _isHistoryLoading = false);
    }
  }

  // --- HİKAYE SİLME İŞLEMİ ---
  Future<void> _deleteStory(String storyId) async {
    if (_user == null) return;

    // Önce kullanıcıya emin olup olmadığını soralım
    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hikayeyi Sil'),
              content: const Text(
                'Bu hikayeyi kalıcı olarak silmek istediğinize emin misiniz?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Sil',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Eğer boşluğa tıklayıp kapatırsa false dönsün

    if (!confirmDelete) return;

    setState(() => _isHistoryLoading = true);

    try {
      // Firebase'den silme işlemi
      await _dbRef.child('Users/${_user!.uid}/AI_Stories/$storyId').remove();

      // Listeyi güncelle
      await _fetchStories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hikaye başarıyla silindi!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isHistoryLoading = false);
    }
  }

  // --- HİKAYE ÜRETİM VE KAYDETME İŞLEMLERİ ---
  void _openWordSelectionSheet() {
    if (_availableWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce biraz quiz çözüp kelime biriktirmelisin!'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kelime Seçin (1 - 5)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedWords.length}/5',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedWords.length == 5
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableWords.length,
                      itemBuilder: (context, index) {
                        final word = _availableWords[index];
                        final isSelected = _selectedWords.any(
                          (w) => w['id'] == word['id'],
                        );

                        return CheckboxListTile(
                          title: Text(word['english'] ?? ''),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                if (_selectedWords.length < 5) {
                                  setState(() => _selectedWords.add(word));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'En fazla 5 kelime seçebilirsiniz!',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                setState(
                                  () => _selectedWords.removeWhere(
                                    (w) => w['id'] == word['id'],
                                  ),
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Seçimi Tamamla',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateContent() async {
    if (_selectedWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen listeden en az 1 kelime seçin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedStory = "";
      _generatedImageBase64 = "";
    });

    try {
      String wordsChainForAI = _selectedWords
          .map((w) => w['english'])
          .join(', ');

      // --- 1. ADIM: HİKAYE ÜRETİMİ ---
      final promptText = Uri.encodeComponent(
        "You are a storyteller. DO NOT use JSON formatting. DO NOT show your thinking process or internal monologue. Just give me the final text directly without any introduction.\n\n"
        "Task 1: Write a short, creative story in TURKISH using these exact words: $wordsChainForAI.\n"
        "Task 2: At the very end of your response, write the exact word 'Prompt:' followed by a 1-sentence English visual description of the story.\n\n"
        "Output ONLY the Turkish story and the English prompt line. Nothing else.",
      );

      final textUrl = Uri.parse('https://text.pollinations.ai/$promptText');
      final textResponse = await http.get(textUrl);

      if (textResponse.statusCode != 200) {
        throw Exception(
          "Hikaye üretilemedi. Status: ${textResponse.statusCode}",
        );
      }

      String responseText = textResponse.body;

      if (responseText.trim().startsWith('{') &&
          responseText.contains('content"')) {
        try {
          final jsonDecodeText = jsonDecode(responseText);
          responseText = jsonDecodeText['content'] ?? responseText;
        } catch (e) {
          // JSON decode edilemezse düz metin olarak devam et
        }
      }

      // --- GELEN METNİ PARÇALAMA ---
      String storyResult = "";
      String imagePrompt = wordsChainForAI;

      if (responseText.contains("Prompt:")) {
        var parts = responseText.split("Prompt:");
        storyResult = parts[0].replaceAll("Hikaye:", "").trim();
        imagePrompt = parts[1].trim();
      } else if (responseText.contains("prompt:")) {
        var parts = responseText.split("prompt:");
        storyResult = parts[0].replaceAll("Hikaye:", "").trim();
        imagePrompt = parts[1].trim();
      } else {
        storyResult = responseText.trim();
      }

      // --- 2. ADIM: GÖRSEL ÜRETİMİ ---
      String safeImagePrompt = Uri.encodeComponent(imagePrompt);
      String seed = DateTime.now().millisecondsSinceEpoch.toString();
      String imageUrlResult =
          "https://image.pollinations.ai/prompt/$safeImagePrompt?seed=$seed&width=800&height=600&nologo=true";

      setState(() {
        _generatedStory = storyResult;
        _generatedImageBase64 = imageUrlResult;
      });
    } catch (e) {
      debugPrint("API ÇAĞRISI HATASI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToDatabase() async {
    if (_user == null ||
        _generatedStory.isEmpty ||
        _generatedImageBase64.isEmpty)
      return;

    setState(() => _isLoading = true);

    try {
      DateTime now = DateTime.now();
      String wordsChainSaved = _selectedWords
          .map((w) => w['english'])
          .join(', ');

      await _dbRef
          .child('Users/${_user!.uid}/AI_Stories/${now.millisecondsSinceEpoch}')
          .set({
            'wordsChain': wordsChainSaved,
            'story': _generatedStory,
            'imageUrl': _generatedImageBase64,
            'date': now.toIso8601String(),
          });

      await _fetchStories();

      setState(() {
        _generatedStory = "";
        _generatedImageBase64 = "";
        _selectedWords.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Tarih Formatlayıcı
  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return "Bilinmeyen Tarih";
    try {
      DateTime date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoDate;
    }
  }

  // Base64 veya URL uyumlu Görsel Çizici
  Widget _buildImageWidget(String imageData, {double height = 200}) {
    if (imageData.isEmpty)
      return Container(height: height, color: Colors.grey[300]);

    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      try {
        return Image.memory(
          base64Decode(imageData),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Asistan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isWordsLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. YENİ HİKAYE OLUŞTURMA BÖLÜMÜ ---
                  Text(
                    'Yeni Hikaye Oluştur',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.5),
                    elevation: 0,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.deepPurple,
                            size: 40,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Daha önce çözdüğünüz kelimelerden seçim yapın ve yapay zeka sizin için hikaye ve görsel oluştursun!",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.checklist),
                    label: const Text('Kelime Seç'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openWordSelectionSheet,
                  ),
                  const SizedBox(height: 10),

                  if (_selectedWords.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _selectedWords.map((word) {
                        return Chip(
                          label: Text(word['english'] ?? ''),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          onDeleted: () => setState(
                            () => _selectedWords.removeWhere(
                              (w) => w['id'] == word['id'],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.generating_tokens),
                      label: Text(
                        _isLoading
                            ? 'Üretiliyor...'
                            : 'Hikaye ve Görsel Oluştur',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading || _selectedWords.isEmpty
                          ? null
                          : _generateContent,
                    ),
                  ),

                  // Üretilen İçerik Gösterimi ve Kaydetme
                  if (_generatedStory.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _generatedStory,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageWidget(_generatedImageBase64),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Hikayeyi Kaydet'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _saveToDatabase,
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
                  const SizedBox(height: 20),

                  // --- 2. GEÇMİŞ HİKAYELER BÖLÜMÜ ---
                  Text(
                    'Geçmiş Hikayelerim',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _isHistoryLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _storiesList.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Henüz kaydedilmiş bir hikaye yok.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _storiesList.length,
                          itemBuilder: (context, index) {
                            var storyData = _storiesList[index];

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // TARIH VE SİLME BUTONU YAN YANA
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(storyData['date'] ?? ''),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteStory(storyData['id']),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          tooltip: "Sil",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8.0,
                                      children: (storyData['wordsChain'] ?? '')
                                          .toString()
                                          .split(',')
                                          .map(
                                            (word) => Chip(
                                              label: Text(word.trim()),
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 12),

                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildImageWidget(
                                        storyData['imageUrl'] ?? '',
                                        height: 180,
                                      ),
                                    ),

                                    const SizedBox(height: 12),
                                    Text(
                                      storyData['story'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
