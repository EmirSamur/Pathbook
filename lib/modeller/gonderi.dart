// pathbooks/modeller/gonderi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelini import et

class Gonderi {
  final String id; // Firestore'daki döküman ID'si
  final String kullaniciId; // Önceden yayinlayanId idi, daha standart olması için kullaniciId yapalım
  final String resimUrl;    // Önceden gonderiResmiUrl idi
  final String aciklama;
  final String? konum;
  final int begeniSayisi;
  final int yorumSayisi;     // EKLENDİ
  final Timestamp olusturulmaZamani; // EKLENDİ

  // Opsiyonel: Gönderiyi yayınlayan kullanıcı bilgilerini de burada tutabiliriz
  final Kullanici? yayinlayanKullanici; // EKLENDİ

  Gonderi({
    required this.id,
    required this.kullaniciId, // DEĞİŞTİ
    required this.resimUrl,    // DEĞİŞTİ
    required this.aciklama,
    this.konum,
    required this.begeniSayisi,
    required this.yorumSayisi,     // EKLENDİ
    required this.olusturulmaZamani, // EKLENDİ
    this.yayinlayanKullanici,        // EKLENDİ
  });

  factory Gonderi.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc, {Kullanici? yayinlayan}) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Gönderi doküman verisi bulunamadı: ${doc.id}");
    }

    // Firestore'daki alan adlarının eşleştiğinden emin ol!
    return Gonderi(
      id: doc.id,
      kullaniciId: data['kullaniciId'] as String? ?? data['yayinlayanId'] as String? ?? '', // Eski ve yeni alan adını kontrol et
      resimUrl: data['resimUrl'] as String? ?? data['gonderiResmiUrl'] as String? ?? '', // Eski ve yeni alan adını kontrol et
      aciklama: data['aciklama'] as String? ?? '',
      konum: data['konum'] as String?,
      begeniSayisi: data['begeniSayisi'] as int? ?? 0,
      yorumSayisi: data['yorumSayisi'] as int? ?? 0,         // EKLENDİ
      olusturulmaZamani: data['olusturulmaZamani'] as Timestamp? ?? Timestamp.now(), // EKLENDİ
      yayinlayanKullanici: yayinlayan,                     // EKLENDİ
    );
  }

// toMap metodu şimdilik gerekli değil, çünkü gönderi oluşturma FirestoreServisi'nde hallediliyor.
// İleride gerekirse eklenebilir.
}