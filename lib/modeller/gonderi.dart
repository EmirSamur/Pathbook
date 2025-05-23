// pathbooks/modeller/gonderi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelini import et

class Gonderi {
  final String id;
  final String kullaniciId;
  final List<String> resimUrls; // Birden fazla resim URL'i için liste
  final String kategori;      // Gönderi kategorisi (örn: Doğa, Tarih vb.)
  final String aciklama;
  final String? konum;       // Coğrafi bir adres veya yer adı (örn: "Eiffel Kulesi, Paris")
  final String? ulke;        // YENİ: Gönderinin yapıldığı/ait olduğu ülke (örn: "Fransa")
  final String? sehir;       // YENİ: Gönderinin yapıldığı/ait olduğu şehir (örn: "Paris")
  final int begeniSayisi;
  final int yorumSayisi;
  final Timestamp olusturulmaZamani;
  final Kullanici? yayinlayanKullanici; // Bu genellikle gönderi listelenirken Firestore'dan kullanıcı bilgisi çekilip sonradan doldurulur

  Gonderi({
    required this.id,
    required this.kullaniciId,
    required this.resimUrls,
    required this.kategori,
    required this.aciklama,
    this.konum,
    this.ulke,    // YENİ constructor parametresi
    this.sehir,   // YENİ constructor parametresi
    required this.begeniSayisi,
    required this.yorumSayisi,
    required this.olusturulmaZamani,
    this.yayinlayanKullanici,
  });

  factory Gonderi.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc, {Kullanici? yayinlayan}) {
    final data = doc.data(); // DocumentSnapshot'tan veriyi al

    // Verinin null olup olmadığını kontrol et, bu çok önemli.
    if (data == null) {
      // Eğer veri null ise, bu durumu uygun şekilde ele almak gerekir.
      // Hata fırlatmak bir seçenek, bu sayede geliştirme aşamasında sorunlar daha kolay fark edilir.
      // Alternatif olarak, bazı varsayılan değerlerle bir Gonderi nesnesi döndürülebilir veya null döndürülebilir
      // (eğer Gonderi.dokumandanUret metodu Gonderi? döndürüyorsa).
      // Şimdilik, bir hata fırlatıyoruz.
      print("HATA: Gönderi doküman verisi (${doc.id}) bulunamadı veya Firestore'dan null geldi.");
      throw StateError("Gönderi doküman verisi (${doc.id}) alınamadı.");
    }

    // Firestore'dan 'resimUrls' alanını güvenli bir şekilde List<String> olarak oku
    List<String> urls = [];
    if (data['resimUrls'] != null && data['resimUrls'] is List) {
      // Gelen listenin elemanlarının gerçekten String olduğundan emin olmak için map kullan.
      // Eğer listede String olmayan bir eleman varsa, toString() ile string'e çevirir.
      urls = List<String>.from(
          (data['resimUrls'] as List).map((item) => item.toString()));
    } else if (data['resimUrl'] != null && data['resimUrl'] is String) {
      // Geriye dönük uyumluluk için eski tek 'resimUrl' alanını da kontrol et.
      // İdeal olan tüm verinin 'resimUrls' formatına migrate edilmesidir.
      urls.add(data['resimUrl'] as String);
      print("UYARI: Gönderi ${doc.id} için 'resimUrls' alanı bulunamadı, eski 'resimUrl' alanı kullanıldı. Veri modelinizi güncellemeniz önerilir.");
    }
    // else {
    //   // Resim URL'si hiç yoksa, urls listesi boş kalacak.
    //   print("BİLGİ: Gönderi ${doc.id} için resim URL'si bulunamadı.");
    // }

    return Gonderi(
      id: doc.id, // Firestore belgesinin ID'si
      kullaniciId: data['kullaniciId'] as String? ?? '', // Null ise boş string ata
      resimUrls: urls, // Oluşturulan URL listesi
      kategori: data['kategori'] as String? ?? 'Diğer', // Kategori yoksa veya null ise 'Diğer' ata
      aciklama: data['aciklama'] as String? ?? '', // Null ise boş string ata
      konum: data['konum'] as String?, // Null olabilir
      ulke: data['ulke'] as String?,      // YENİ: Firestore'dan 'ulke' alanını oku, null olabilir
      sehir: data['sehir'] as String?,     // YENİ: Firestore'dan 'sehir' alanını oku, null olabilir
      begeniSayisi: data['begeniSayisi'] as int? ?? 0, // Null ise 0 ata
      yorumSayisi: data['yorumSayisi'] as int? ?? 0, // Null ise 0 ata
      olusturulmaZamani: data['olusturulmaZamani'] as Timestamp? ?? Timestamp.now(), // Null ise şu anki zamanı ata
      yayinlayanKullanici: yayinlayan, // Opsiyonel olarak dışarıdan gelen Kullanici nesnesi
    );
  }
}