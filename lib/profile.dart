import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('Users/${user.uid}/UserName');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      setState(() {
        _userName = snapshot.value as String?;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 👤 Profil kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 10),
                // ✅ UserName - Realtime Database'den
                _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _userName ?? user?.email ?? "Kullanıcı",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 5),
                const Text("Kelime Ezberleme Uygulaması"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ⚙️ AYARLAR BAŞLIK
          const Text(
            "Ayarlar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // 🔔 Bildirimler
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Bildirimler"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          // 🌙 Tema
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Tema"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          // 🔒 Güvenlik
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Güvenlik"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),

          const SizedBox(height: 20),

          // 🚪 Çıkış yap
          ElevatedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text("Çıkış Yap"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }
}