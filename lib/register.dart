import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Firestore yerine Database eklendi
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller'lar
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Şifreler birbiriyle uyuşmuyor!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth: Kullanıcı oluşturma
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Realtime Database: Bilgileri "Users" düğümüne kaydetme
      // Firestore'daki .collection().doc().set() yerine .ref().set() kullanıyoruz
      DatabaseReference ref = FirebaseDatabase.instance.ref(
        "Users/${userCredential.user!.uid}",
      );

      await ref.set({
        'UserID': userCredential.user!.uid,
        'FirstName': _firstNameController.text.trim(),
        'LastName': _lastNameController.text.trim(),
        'UserName':
            "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
        'Email': _emailController.text.trim(),
        'CreatedAt': DateTime.now()
            .toIso8601String(), // Realtime DB için ISO formatı
      });

      if (mounted) {
        _showSnackBar("Hesabınız başarıyla oluşturuldu!", Colors.green);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Kayıt hatası oluştu", Colors.red);
    } catch (e) {
      // Beklenmedik hatalar (bağlantı vb.) için
      _showSnackBar("Bir hata oluştu: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(
                Icons.person_add_outlined,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: "Ad",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Ad alanı boş bırakılamaz" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: "Soyad",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Soyad alanı boş bırakılamaz" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    !value!.contains("@") ? "Geçerli bir e-posta girin" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                ),
                validator: (value) =>
                    value!.length < 6 ? "Şifre en az 6 karakter olmalı" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureText,
                decoration: const InputDecoration(
                  labelText: "Şifre Tekrar",
                  prefixIcon: Icon(Icons.lock_reset),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Lütfen şifrenizi tekrar girin" : null,
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
