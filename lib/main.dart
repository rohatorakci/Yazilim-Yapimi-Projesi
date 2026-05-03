import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'login.dart';
import 'profile.dart';
import 'quiz.dart';
import 'wordle.dart';
import 'addWords.dart';
import 'quizSettings.dart';
import 'stats.dart';
import 'words.dart';
import 'PrintReport.dart';
import 'AIassistant.dart';
import 'leaderboard.dart';

// Global tema notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseDatabase.instance.databaseURL =
      "https://yazilim-yapimi-eb2a5-default-rtdb.europe-west1.firebasedatabase.app/";

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Kelime Ezberleme Uygulaması",
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MyHomePage(title: "Kelime Ezberleme Ana Sayfa");
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  Widget _buildWordOfTheDay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Günün Kelimesi",
                  style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Persistent",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Israrcı, kalıcı",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const Divider(height: 25),
          Text(
            "\"Success is the result of persistent effort.\"",
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey[400] : Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleBox(
    String title,
    IconData icon,
    VoidCallback onTap,
    Color color,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.16),
                  color.withOpacity(0.05),
                ],
              ),
              border: Border.all(color: color.withOpacity(0.28), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ??
        user?.email?.split('@').first ??
        "Kullanıcı";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.deepPurple.shade800, Colors.deepPurple.shade600]
                        : [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hoş Geldin 👋",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Text("📚", style: TextStyle(fontSize: 35)),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              _buildWordOfTheDay(context),
              const SizedBox(height: 25),

              // MODÜLLER BAŞLIĞI
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                        color: primary, borderRadius: BorderRadius.circular(5)),
                  ),
                  const SizedBox(width: 10),
                  const Text("Modüller",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(height: 16),

              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _buildModuleBox("Quiz Ol", Icons.quiz_rounded, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const QuizPage()));
                  }, Colors.deepPurple, 0),
                  _buildModuleBox("Wordle Oyna", Icons.grid_view_rounded, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WordlePage()));
                  }, Colors.teal, 80),
                  _buildModuleBox("Kelime Ekle", Icons.add_circle_outline, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddWordsPage()));
                  }, Colors.orange, 160),
                  _buildModuleBox("Quiz Ayarları", Icons.settings_rounded, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QuizSettingsPage()));
                  }, Colors.indigo, 240),
                  _buildModuleBox("Analiz Raporu", Icons.analytics_outlined, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PrintReport()));
                  }, Colors.green, 320),
                  _buildModuleBox("AI Asistan", Icons.smart_toy_outlined, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AIassistant()));
                  }, Colors.redAccent, 400),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return FadeTransition(
            opacity: _fadeAnimation, child: const WordsPage());
      case 2:
        return FadeTransition(
            opacity: _fadeAnimation, child: const StatsPage());
      case 3:
        return FadeTransition(
            opacity: _fadeAnimation, child: const LeaderboardPage());
      case 4:
        return FadeTransition(
            opacity: _fadeAnimation, child: const ProfilePage());
      default:
        return const Center(child: Text("Sayfa bulunamadı"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Icon(Icons.auto_stories_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text("WordMaster",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              themeNotifier.value =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changePage,
        height: 70,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Ana Sayfa",
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: "Kelimeler",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: "İstatistik",
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: "Sıralama",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}