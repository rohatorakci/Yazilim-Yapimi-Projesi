import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "register.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Bir hata oluştu";
      if (e.code == 'user-not-found') message = "Kullanıcı bulunamadı.";
      else if (e.code == 'wrong-password') message = "Hatalı şifre.";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-posta adresinizi giriniz."), backgroundColor: Colors.orange),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sıfırlama linki gönderildi."), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını alıyoruz
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap"), elevation: 0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Ekranın yüksekliğine göre içeriği ortalamak için kullanılır
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortala
                    children: [
                      const Spacer(flex: 2), // Üstten esnek boşluk
                      Icon(
                        Icons.auto_stories,
                        size: size.width * 0.2, // İkon boyutu ekran genişliğine duyarlı
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Kelime Master",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),
                      
                      // E-posta Alanı
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "E-posta",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Şifre Alanı
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Şifre",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        obscureText: true,
                      ),

                      // Şifremi Unuttum
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text("Şifremi Unuttum"),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Giriş Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Giriş Yap", style: TextStyle(fontSize: 18)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Kayıt Ol
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text("Hesabın yok mu? Kayıt Ol", 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(flex: 3), // Alttan esnek boşluk
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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