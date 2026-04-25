# 📚 Kelime Öğrenme Uygulaması (6 Tekrar Sistemi)

Akıllı tekrar mantığıyla çalışan bu uygulama, yeni kelimeleri **kalıcı şekilde öğrenmen** için tasarlanmıştır.
Her kelime, belirli aralıklarla toplam **6 kez tekrar edilir** ve böylece unutma eğrisine karşı etkili bir öğrenme sistemi oluşturulur.

---

## 🚀 Proje Hakkında

Bu uygulama, kullanıcıların yeni kelimeleri ezberlemek yerine **uzun süreli hafızaya aktarmasını** hedefler.

Her eklenen kelime, sistem tarafından otomatik olarak tekrar planına alınır. Kullanıcı günlük tekrarlarını yaparak kelimeleri adım adım öğrenir.

---

## 🧠 Nasıl Çalışır?

Bir kelime sisteme eklendiğinde aşağıdaki tekrar sürecine girer:

1.  İlk öğrenme
2.  1. tekrar – kısa süre sonra
3.  2. tekrar – ertesi gün
4.  3. tekrar – birkaç gün sonra
5.  4. tekrar – 1 hafta sonra
6.  5. tekrar – 1 ay sonra
7.  Son tekrar – kalıcı öğrenme aşaması

> Bu yapı, **Spaced Repetition (Aralıklı Tekrar)** mantığına dayanır.

---

## ✨ Özellikler

*  Yeni kelime ekleme
*  6 aşamalı tekrar sistemi
*  Günlük tekrar listesi
*  Öğrenme ilerleme takibi
*  Zor kelimeleri işaretleme
*  Kelime arama sistemi
*  Mobil uyumlu tasarım
*  Dark Mode desteği *(opsiyonel)*

---

## 🛠️ Kullanılan Teknolojiler

* Flutter
* Dart
* SharedPreferences / Hive / SQLite
* Provider / Riverpod

---

## 📂 Proje Yapısı

```bash
src/
 ┣ screens/
 ┣ components/
 ┣ models/
 ┣ services/
 ┣ utils/
 ┗ main.dart / app.js
```

---

## 🎯 Hedef Kitle

* İngilizce öğrenenler
* YKS / YDS öğrencileri
* KPSS / Akademik sınav hazırlananlar
* Günlük kelime geliştirmek isteyen herkes

---

## 📸 Ekran Görselleri

Buraya ekran görüntülerini koyacağız:

```md
![Home](images/home.png)
![Review](images/review.png)
```

---

## ⚙️ Kurulum

```bash
git clone https://github.com/rohatorakci/kelime-ogrenme-app.git
cd kelime-ogrenme-app
npm install
npm run dev
```

veya Flutter için:

```bash
flutter pub get
flutter run
```

---

## 🔮 Gelecek Güncellemeler

*  Sesli telaffuz sistemi
*  Yapay zekâ ile kelime önerisi
*  Günlük quiz modu
*  Bulut senkronizasyonu
*  Arkadaşlarla yarış sistemi

---

## 🤝 Katkı Sağlama

Pull Request gönderebilir veya fikir paylaşabilirsin.

---

## 📜 Lisans

MIT License

---

## 👨‍💻 Geliştirici

Muhammet oruçoğlu (highlvmami)
Süleyman Rohat Orakçı (rohatorakci)
Murat Durmuş Erol (Qwnstriker)

---

⭐ Eğer projeyi beğendiysen repo'ya yıldız bırakmayı unutma!
