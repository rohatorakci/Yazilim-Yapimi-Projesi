import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Görseldeki "Users" düğümüne referans alıyoruz
    final DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('Users');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
        stream: usersRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Veriler yüklenirken bir hata oluştu."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> userList = [];
          
          if (snapshot.data!.snapshot.value != null) {
            // Firebase'deki tüm kullanıcıları alıyoruz
            Map<dynamic, dynamic> usersData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            
            usersData.forEach((userId, userData) {
              // Veri çekme mantığı (Görseldeki hiyerarşiye tam uyumlu)
              String name = userData['UserName'] ?? "Adsız Kullanıcı";
              
              int correctCount = 0;
              // 'stats' düğümü altındaki 'correctAnswers' değerine ulaşıyoruz
              if (userData['stats'] != null) {
                var stats = userData['stats'];
                correctCount = stats['correctAnswers'] ?? 0;
              }

              userList.add({
                'userName': name,
                'correctAnswers': correctCount,
              });
            });

            // Büyükten küçüğe doğru sıralıyoruz
            userList.sort((a, b) => b['correctAnswers'].compareTo(a['correctAnswers']));
          }

          if (userList.isEmpty) {
            return const Center(child: Text("Sıralama için kayıtlı kullanıcı bulunamadı."));
          }

          return Column(
            children: [
              _buildTopSection(context, userList.isNotEmpty ? userList.first : null),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    return _buildUserTile(context, index, user);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Üst Kısım: Birinci olan kişiyi vurgulayan şık tasarım
  Widget _buildTopSection(BuildContext context, Map<String, dynamic>? winner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
          const SizedBox(height: 10),
          const Text("LİDERLİK TABLOSU", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          CircleAvatar(
            radius: 35,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            winner?['userName'] ?? "-",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            "${winner?['correctAnswers']} Toplam Doğru Cevap",
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Liste elemanı tasarımı
  Widget _buildUserTile(BuildContext context, int index, Map<String, dynamic> user) {
    bool isFirst = index == 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isFirst ? Colors.amber.withOpacity(0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isFirst ? Colors.amber : Colors.transparent),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey : (index == 2 ? Colors.orange : Colors.grey.shade300)),
          child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(user['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${user['correctAnswers']} Doğru",
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}