import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:crypto/crypto.dart'; // SHA-256 için gerekli
import 'dart:convert'; // utf8 dönüştürücü için gerekli

class AddWordsPage extends StatefulWidget {
  const AddWordsPage({super.key});

  @override
  State<AddWordsPage> createState() => _AddWordsPageState();
}

class _AddWordsPageState extends State<AddWordsPage> {
  final _formKey = GlobalKey<FormState>();

  // Input Controller'lar
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _turkishController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();

  bool _isLoading = false;
  String _selectedCategory = "General"; // Varsayılan kategori

  // Belirlediğin 22+ kategori listesi
  final List<String> _categories = [
    "Action",
    "Agriculture",
    "Art",
    "Business",
    "Education",
    "Emotion",
    "Entertainment",
    "Family",
    "Finance",
    "Food",
    "General",
    "Geography",
    "Health",
    "History",
    "Hobby",
    "Industry",
    "Jobs",
    "Law",
    "Media",
    "Nature",
    "Personal",
    "Politics",
    "Science",
    "Shopping",
    "Social",
    "Sports",
    "Success",
    "Technology",
    "Travel",
  ];

  // SHA-256 Hash Algoritması: Sadece İngilizce kelimeye göre üretilir
  String _generateHash(String word) {
    var bytes = utf8.encode(word.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  Future<void> _addWord() async {
    // Form doğrulama (Boş alan kontrolü)
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String englishWord = _englishController.text.trim();
    String hashKey = _generateHash(englishWord);

    try {
      // Realtime Database "words" anahtarı altında hash kontrolü
      DatabaseReference ref = FirebaseDatabase.instance.ref("words/$hashKey");
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        // Hash çakışması varsa hata ver
        _showSnackBar(
          "Bu kelime zaten sistemde kayıtlı! (Hash Çakışması)",
          Colors.orange,
        );
      } else {
        // Çakışma yoksa yeni veriyi kaydet
        await ref.set({
          'english': englishWord,
          'turkish': _turkishController.text.trim(),
          'example': _exampleController.text.trim(),
          'category': _selectedCategory,
        });

        _showSnackBar("'$englishWord' başarıyla kaydedildi!", Colors.green);
        _clearForm();
      }
    } catch (e) {
      _showSnackBar("Veritabanı hatası: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _englishController.clear();
    _turkishController.clear();
    _exampleController.clear();
    setState(() => _selectedCategory = "General");
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Ekle'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Yeni Kelime Bilgileri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // İngilizce Kelime Girişi
              _buildTextField(
                _englishController,
                "İngilizce Kelime",
                Icons.language,
              ),
              const SizedBox(height: 15),

              // Türkçe Kelime Girişi
              _buildTextField(
                _turkishController,
                "Türkçe Karşılığı",
                Icons.translate,
              ),
              const SizedBox(height: 15),

              // Kategori Seçimi (Dropdown)
              const Text(
                "Kategori",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 15),

              // Örnek Cümle Girişi
              _buildTextField(
                _exampleController,
                "Örnek Cümle",
                Icons.short_text,
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Kaydet Butonu
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addWord,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Kelimeyi Sisteme Ekle",
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value!.trim().isEmpty ? "Bu alan boş bırakılamaz" : null,
    );
  }

  @override
  void dispose() {
    _englishController.dispose();
    _turkishController.dispose();
    _exampleController.dispose();
    super.dispose();
  }
}
