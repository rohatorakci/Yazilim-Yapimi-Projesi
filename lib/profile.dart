import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  String? _userName;
  bool _isLoading = true;
  bool _themeExpanded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
    _loadUserName();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final ref = FirebaseDatabase.instance
        .ref(
      'Users/${user.uid}/UserName',
    );

    final snapshot = await ref.get();

    setState(() {
      _userName = snapshot.exists
          ? snapshot.value as String?
          : null;

      _isLoading = false;
    });
  }

  Future<void> _signOut(
      BuildContext context) async {
    await FirebaseAuth.instance
        .signOut();
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final primary =
        color ??
            Theme.of(context)
                .colorScheme
                .primary;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
        leading: Container(
          padding:
              const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                primary.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSelector(
      ThemeMode currentMode) {
    Widget item({
      required String title,
      required IconData icon,
      required ThemeMode mode,
    }) {
      final selected =
          currentMode == mode;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            themeNotifier.value = mode;
            setState(() {});
          },
          child: AnimatedContainer(
            duration:
                const Duration(
                    milliseconds: 250),
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                      16),
              color: selected
                  ? Colors.deepPurple
                  : Colors.grey.shade200,
              border: Border.all(
                color: selected
                    ? Colors.deepPurple
                    : Colors.grey
                        .shade400,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : Colors.grey
                          .shade700,
                ),
                const SizedBox(
                    height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: selected
                        ? Colors.white
                        : Colors.grey
                            .shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
              16, 0, 16, 16),
      child: Row(
        children: [
          item(
            title: "Açık",
            icon: Icons.light_mode,
            mode: ThemeMode.light,
          ),
          const SizedBox(width: 12),
          item(
            title: "Koyu",
            icon: Icons.dark_mode,
            mode: ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    final isDark =
        themeNotifier.value ==
            ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding:
                const EdgeInsets.all(18),
            children: [
              const SizedBox(height: 8),

              // PROFIL HEADER
              Container(
                padding:
                    const EdgeInsets.all(
                        24),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius
                          .circular(26),
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment
                            .topLeft,
                    end:
                        Alignment
                            .bottomRight,
                    colors: isDark
                        ? [
                            Colors
                                .deepPurple
                                .shade800,
                            Colors
                                .deepPurple
                                .shade600,
                          ]
                        : [
                            Colors
                                .deepPurple
                                .shade400,
                            Colors
                                .deepPurple
                                .shade700,
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .deepPurple
                          .withOpacity(
                              0.30),
                      blurRadius: 18,
                      offset:
                          const Offset(
                              0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .all(4),
                      decoration:
                          BoxDecoration(
                        shape: BoxShape
                            .circle,
                        border:
                            Border.all(
                          color: Colors
                              .white
                              .withOpacity(
                                  0.30),
                          width: 2,
                        ),
                      ),
                      child:
                          const CircleAvatar(
                        radius: 42,
                        backgroundColor:
                            Colors.white24,
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: Colors
                              .white,
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 14),
                    _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors
                                .white,
                          )
                        : Text(
                            _userName ??
                                user?.email ??
                                "Kullanıcı",
                            style:
                                const TextStyle(
                              fontSize:
                                  22,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color: Colors
                                  .white,
                            ),
                          ),
                    const SizedBox(
                        height: 6),
                    Text(
                      "Kelime Ezberleme Uygulaması",
                      style:
                          TextStyle(
                        color: Colors
                            .white
                            .withOpacity(
                                0.80),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration:
                        BoxDecoration(
                      color: Theme.of(
                              context)
                          .colorScheme
                          .primary,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  5),
                    ),
                  ),
                  const SizedBox(
                      width: 10),
                  const Text(
                    "Ayarlar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _buildMenuCard(
                icon:
                    Icons.notifications,
                title: "Bildirimler",
                onTap: () {},
                color: Colors.orange,
              ),

              // THEME CARD
              Container(
                margin:
                    const EdgeInsets.only(
                        bottom: 14),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius
                          .circular(20),
                  color: Theme.of(
                          context)
                      .colorScheme
                      .surfaceContainer,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding:
                            const EdgeInsets
                                .all(10),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .deepPurple
                              .withOpacity(
                                  0.14),
                          shape: BoxShape
                              .circle,
                        ),
                        child: const Icon(
                          Icons.dark_mode,
                          color: Colors
                              .deepPurple,
                        ),
                      ),
                      title: const Text(
                        "Tema",
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                      trailing: AnimatedRotation(
                        turns:
                            _themeExpanded
                                ? 0.5
                                : 0,
                        duration:
                            const Duration(
                                milliseconds:
                                    250),
                        child: const Icon(
                          Icons
                              .keyboard_arrow_down,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _themeExpanded =
                              !_themeExpanded;
                        });
                      },
                    ),

                    if (_themeExpanded)
                      ValueListenableBuilder<
                          ThemeMode>(
                        valueListenable:
                            themeNotifier,
                        builder: (
                          context,
                          currentMode,
                          _,
                        ) {
                          return _buildThemeSelector(
                            currentMode,
                          );
                        },
                      ),
                  ],
                ),
              ),

              _buildMenuCard(
                icon: Icons.lock,
                title: "Güvenlik",
                onTap: () {},
                color: Colors.blue,
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child:
                    ElevatedButton.icon(
                  onPressed: () =>
                      _signOut(
                          context),
                  icon: const Icon(
                    Icons.logout,
                  ),
                  label: const Text(
                    "Çıkış Yap",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.red,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                                  18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}