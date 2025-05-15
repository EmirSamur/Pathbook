// pathbooks/modeller/gonderi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelini import et

class Gonderi {
  final String id;
  final String kullaniciId;
  // final String resimUrl;    // ESKİ: Tek resim URL'i
  final List<String> resimUrls; // YENİ: Birden fazla resim URL'i için liste
  final String kategori;      // YENİ: Gönderi kategorisi
  final String aciklama;
  final String? konum;
  final int begeniSayisi;
  final int yorumSayisi;
  final Timestamp olusturulmaZamani;
  final Kullanici? yayinlayanKullanici;

  Gonderi({
    required this.id,
    required this.kullaniciId,
    // required this.resimUrl,    // ESKİ
    required this.resimUrls,   // YENİ
    required this.kategori,    // YENİ
    required this.aciklama,
    this.konum,
    required this.begeniSayisi,
    required this.yorumSayisi,
    required this.olusturulmaZamani,
    this.yayinlayanKullanici,
  });

  factory Gonderi.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc, {Kullanici? yayinlayan}) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Gönderi doküman verisi bulunamadı: ${doc.id}");
    }

    // Firestore'dan 'resimUrls' alanını List<String> olarak oku
    List<String> urls = [];
    if (data['resimUrls'] != null && data['resimUrls'] is List) {
      // Gelen listeyi güvenli bir şekilde List<String>'e çevir
      urls = List<String>.from(data['resimUrls'].map((item) => item.toString()));
    } else if (data['resimUrl'] != null && data['resimUrl'] is String) {
      // Geriye dönük uyumluluk için eski tek 'resimUrl' alanını da kontrol et
      // Yeni gönderilerde bu alan olmayacak, ama eski veriler için eklenebilir.
      // Ancak ideal olan tüm verinin yeni formata migrate edilmesi.
      // Şimdilik, eğer 'resimUrls' yoksa ve 'resimUrl' varsa onu tek elemanlı listeye ekle.
      urls.add(data['resimUrl'] as String);
    }


    return Gonderi(
      id: doc.id,
      kullaniciId: data['kullaniciId'] as String? ?? '', // Önlem amaçlı boş string fallback
      // resimUrl: data['resimUrl'] as String? ?? '', // ESKİ
      resimUrls: urls, // YENİ
      kategori: data['kategori'] as String? ?? 'Diğer', // YENİ, kategori yoksa varsayılan 'Diğer'
      aciklama: data['aciklama'] as String? ?? '',
      konum: data['konum'] as String?,
      begeniSayisi: data['begeniSayisi'] as int? ?? 0,
      yorumSayisi: data['yorumSayisi'] as int? ?? 0,
      olusturulmaZamani: data['olusturulmaZamani'] as Timestamp? ?? Timestamp.now(),
      yayinlayanKullanici: yayinlayan,
    );
  }
}