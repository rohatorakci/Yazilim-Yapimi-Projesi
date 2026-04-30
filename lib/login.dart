import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "register.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Input alanlarındaki verileri kontrol etmek için controller'lar
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; // Giriş işlemi sırasında loading göstermek için

  // Firebase Giriş Fonksiyonu
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Auth ile giriş yapma tetikleyicisi
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Başarılı olursa AuthWrapper otomatik olarak MyHomePage'e geçirecek
    } on FirebaseAuthException catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      String message = "Bir hata oluştu";
      if (e.code == 'user-not-found') {
        message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        message = "Hatalı şifre girdiniz.";
      } else if (e.code == 'invalid-email') {
        message = "Geçersiz bir e-posta adresi girdiniz.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Kelime Ezberleme Uygulaması",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // E-posta Alanı
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-posta",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            // Şifre Alanı
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true, // Şifreyi gizle
            ),
            const SizedBox(height: 25),

            // Giriş Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Giriş Yap", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 15),

            // Kayıt Ol Yönlendirmesi (Henüz register.dart yazmadıysan boş kalabilir)
            TextButton(
              onPressed: () {
                // Kayıt ol sayfasına yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text("Hesabın yok mu? Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
