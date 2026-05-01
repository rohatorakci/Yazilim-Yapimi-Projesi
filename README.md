# Kelime Öğrenme Uygulaması

Bu proje, kelime öğrenimini daha verimli hale getirmek için geliştirilmiş bir mobil uygulamadır. Sistem, tekrar mantığıyla çalışır ve kullanıcıların kelimeleri kısa sürede unutmasını engellemeyi hedefler.

## Proje Hakkında

Uygulama, “spaced repetition” (aralıklı tekrar) mantığına dayanır. Her eklenen kelime belirli zaman aralıklarında tekrar edilerek kalıcı öğrenme sağlanır.

Toplamda 6 aşamalı bir tekrar sistemi kullanılır. Bu sayede kullanıcılar kelimeleri sadece ezberlemez, uzun süreli hafızaya aktarır.

## Özellikler

* Kelime ekleme ve listeleme
* 6 aşamalı tekrar sistemi
* Günlük tekrar takibi
* Öğrenilen / öğrenilmeyen kelime ayrımı
* Basit ve anlaşılır kullanıcı arayüzü
* Mobil uyumlu yapı

## Nasıl Çalışır?

Kullanıcı bir kelime eklediğinde sistem bunu bir öğrenme döngüsüne alır. Kelime belirlenen zamanlarda tekrar kullanıcıya gösterilir.

Temel akış şu şekildedir:

* İlk öğrenme
* Kısa süre sonra tekrar
* 1 gün sonra tekrar
* 3–4 gün sonra tekrar
* 1 hafta sonra tekrar
* Son tekrar ve kalıcı öğrenme

## Kullanılan Teknolojiler

* Flutter / Dart
* Yerel veri saklama (Hive / SQLite / SharedPreferences)
* Basit state yönetimi

## Kurulum

Projeyi klonlayın:

```bash id="kl1s0r"
git clone https://github.com/kullaniciadi/kelime-uygulamasi.git
```

Dizin içine girin:

```bash id="d8k2la"
cd kelime-uygulamasi
```

Bağımlılıkları yükleyin:

```bash id="p2m9xq"
flutter pub get
```

Uygulamayı çalıştırın:

```bash id="r0v8tt"
flutter run
```

## Amaç

Bu proje eğitim amaçlı geliştirilmiştir. Hedef, kelime öğrenme sürecini daha düzenli ve verimli hale getirmektir.

## Geliştirme

İlerleyen süreçte aşağıdaki özellikler eklenebilir:

* Bulut senkronizasyonu
* Test modu (quiz sistemi)
* Sesli telaffuz desteği
* İstatistik ekranı
* Zorluk seviyeleri

## Lisans

Bu proje açık kaynak olarak paylaşılmıştır.

---

Geliştiriciler : 
