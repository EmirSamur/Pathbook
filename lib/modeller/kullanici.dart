// lib/modeller/kullanici.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // İsim çakışmasını önlemek için alias

class Kullanici {
  final String id;
  final String? kullaniciAdi;
  final String? fotoUrl;
  final String? email;
  final String? hakkinda;
  final Timestamp? olusturulmaZamani; // Firestore'dan gelebilir

  // YENİ EKLENEN ALANLAR (Firestore'dan okunacaklar)
  final int? gonderiSayisi;
  final int? takipciSayisi;
  final int? takipEdilenSayisi;
  final Timestamp? guncellenmeZamani; // Firestore'dan gelebilir

  Kullanici({
    required this.id,
    this.kullaniciAdi,
    this.fotoUrl,
    this.email,
    this.hakkinda,
    this.olusturulmaZamani,
    this.gonderiSayisi,     // Constructor'a eklendi
    this.takipciSayisi,     // Constructor'a eklendi
    this.takipEdilenSayisi, // Constructor'a eklendi
    this.guncellenmeZamani, // Constructor'a eklendi
  });

  // Factory: Firebase Auth kullanıcısından Kullanici nesnesi üretir (Temel bilgiler)
  factory Kullanici.firebasedenUret(fb_auth.User firebaseUser) {
    return Kullanici(
      id: firebaseUser.uid,
      kullaniciAdi: firebaseUser.displayName,
      fotoUrl: firebaseUser.photoURL,
      email: firebaseUser.email,
      // hakkinda, olusturulmaZamani, gonderiSayisi vb. bilgiler Firebase Auth User objesinde doğrudan bulunmaz.
      // Bu bilgiler Firestore'dan ayrıca çekilmelidir.
      // Bu factory metodu, sadece Auth'dan gelen temel bilgileri alır.
      hakkinda: null,
      olusturulmaZamani: firebaseUser.metadata.creationTime != null
          ? Timestamp.fromDate(firebaseUser.metadata.creationTime!) // Auth'dan creationTime alınıyor
          : null,
      gonderiSayisi: 0, // Varsayılan veya Firestore'dan çekilene kadar 0
      takipciSayisi: 0,
      takipEdilenSayisi: 0,
      guncellenmeZamani: firebaseUser.metadata.lastSignInTime != null
          ? Timestamp.fromDate(firebaseUser.metadata.lastSignInTime!) // Auth'dan lastSignInTime (yaklaşık bir güncelleme zamanı)
          : null,
    );
  }

  // Factory: Firestore DocumentSnapshot'tan Kullanici nesnesi üretir (Tam bilgiler)
  factory Kullanici.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc) {
    final docData = doc.data();

    if (docData == null) {
      print("HATA: Kullanıcı doküman verisi (${doc.id}) Firestore'da bulunamadı veya boş.");
      // Uygulamanın çökmemesi için varsayılan bir Kullanici veya hata fırlatılabilir.
      // Bu durumda ID ile temel bir Kullanici döndürmek bir seçenek olabilir:
      // return Kullanici(id: doc.id, email: "hata@hata.com"); // veya throw Exception(...)
      throw StateError("Kullanıcı (${doc.id}) için Firestore verisi bulunamadı.");
    }

    return Kullanici(
      id: doc.id,
      kullaniciAdi: docData['kullaniciAdi'] as String?,
      email: docData['email'] as String?, // Firestore'da email her zaman olmayabilir, uygulamana göre zorunlu yapabilirsin
      fotoUrl: docData['fotoUrl'] as String?,
      hakkinda: docData['hakkinda'] as String?,
      olusturulmaZamani: docData['olusturulmaZamani'] as Timestamp?,
      // YENİ: Firestore'dan sayısal değerleri ve güncelleme zamanını oku
      gonderiSayisi: docData['gonderiSayisi'] as int? ?? 0, // Null ise 0 ata
      takipciSayisi: docData['takipciSayisi'] as int? ?? 0, // Null ise 0 ata
      takipEdilenSayisi: docData['takipEdilenSayisi'] as int? ?? 0, // Null ise 0 ata
      guncellenmeZamani: docData['guncellenmeZamani'] as Timestamp?,
    );
  }
}