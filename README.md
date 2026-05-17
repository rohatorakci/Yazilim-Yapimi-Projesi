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
* 1 gün sonra
* 1 hafta sonra
* 1 ay sonra
* 3 ay sonra
* 6 ay sonra son tekrar ve kalıcı öğrenme

## Kullanılan Teknolojiler

* Flutter / Dart
* online veri saklama (Firebase)
* Basit state yönetimi

## Kurulum

Projeyi klonlayın:

```bash id="kl1s0r"
git clone https://github.com/rohatorakci/Yazilim-Yapimi-Projesi
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
* Sesli telaffuz desteği
* Zorluk seviyeleri

## Lisans

Bu proje açık kaynak olarak paylaşılmıştır.

---

Geliştiriciler : 

Muhammet oruçoğlu (highlvmami)
Murat Durmuş Erol (Qwnstriker)
Süleyman Rohat Orakçı (rohatorakci)

Hoşunuza giderse repomuza yıldız ⭐ vermeyi unutmayın !!!!