import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userName;
  bool _isLoading = true;
  bool _themeExpanded = false; // Tema paneli açık/kapalı

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

    setState(() {
      _userName = snapshot.exists ? snapshot.value as String? : null;
      _isLoading = false;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
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

          // ⚙️ Ayarlar başlık
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

          // 🌙 Tema - genişleyebilir panel
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text("Tema"),
                  trailing: Icon(
                    _themeExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                  ),
                  onTap: () {
                    setState(() => _themeExpanded = !_themeExpanded);
                  },
                ),
                // Tema seçenekleri
                if (_themeExpanded)
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, _) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            // ☀️ Açık tema
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  themeNotifier.value = ThemeMode.light;
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentMode == ThemeMode.light
                                        ? Colors.deepPurple
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: currentMode == ThemeMode.light
                                          ? Colors.deepPurple
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.light_mode,
                                        color: currentMode == ThemeMode.light
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Açık",
                                        style: TextStyle(
                                          color: currentMode == ThemeMode.light
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 🌙 Koyu tema
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  themeNotifier.value = ThemeMode.dark;
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentMode == ThemeMode.dark
                                        ? Colors.deepPurple
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: currentMode == ThemeMode.dark
                                          ? Colors.deepPurple
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.dark_mode,
                                        color: currentMode == ThemeMode.dark
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Koyu",
                                        style: TextStyle(
                                          color: currentMode == ThemeMode.dark
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
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
