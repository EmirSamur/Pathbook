// lib/modeller/kullanici.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // İsim çakışmasını önlemek için alias

class Kullanici {
  final String id;
  final String? kullaniciAdi;
  final String? fotoUrl;
  final String? email;
  final String? hakkinda;
  final Timestamp? olusturulmaZamani;

  final int? gonderiSayisi;
  final int? takipciSayisi;
  final int? takipEdilenSayisi;
  final Timestamp? guncellenmeZamani;

  final bool? isVerified; // <<<--- YENİ ALAN: Doğrulanmış hesap durumu

  Kullanici({
    required this.id,
    this.kullaniciAdi,
    this.fotoUrl,
    this.email,
    this.hakkinda,
    this.olusturulmaZamani,
    this.gonderiSayisi,
    this.takipciSayisi,
    this.takipEdilenSayisi,
    this.guncellenmeZamani,
    this.isVerified, // <<<--- CONSTRUCTOR'A EKLENDİ
  });

  // Factory: Firebase Auth kullanıcısından Kullanici nesnesi üretir (Temel bilgiler)
  factory Kullanici.firebasedenUret(fb_auth.User firebaseUser) {
    return Kullanici(
      id: firebaseUser.uid,
      kullaniciAdi: firebaseUser.displayName,
      fotoUrl: firebaseUser.photoURL,
      email: firebaseUser.email,
      hakkinda: null,
      olusturulmaZamani: firebaseUser.metadata.creationTime != null
          ? Timestamp.fromDate(firebaseUser.metadata.creationTime!)
          : null,
      gonderiSayisi: 0,
      takipciSayisi: 0,
      takipEdilenSayisi: 0,
      guncellenmeZamani: firebaseUser.metadata.lastSignInTime != null
          ? Timestamp.fromDate(firebaseUser.metadata.lastSignInTime!)
          : null,
      isVerified: false, // <<<--- YENİ KULLANICI VARSAYILAN OLARAK DOĞRULANMAMIŞ
    );
  }

  // Factory: Firestore DocumentSnapshot'tan Kullanici nesnesi üretir (Tam bilgiler)
  factory Kullanici.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc) {
    final docData = doc.data();

    if (docData == null) {
      print("HATA: Kullanıcı doküman verisi (${doc.id}) Firestore'da bulunamadı veya boş.");
      throw StateError("Kullanıcı (${doc.id}) için Firestore verisi bulunamadı.");
    }

    return Kullanici(
      id: doc.id,
      kullaniciAdi: docData['kullaniciAdi'] as String?,
      email: docData['email'] as String?,
      fotoUrl: docData['fotoUrl'] as String?,
      hakkinda: docData['hakkinda'] as String?,
      olusturulmaZamani: docData['olusturulmaZamani'] as Timestamp?,
      gonderiSayisi: docData['gonderiSayisi'] as int? ?? 0,
      takipciSayisi: docData['takipciSayisi'] as int? ?? 0,
      takipEdilenSayisi: docData['takipEdilenSayisi'] as int? ?? 0,
      guncellenmeZamani: docData['guncellenmeZamani'] as Timestamp?,
      isVerified: docData['isVerified'] as bool? ?? false, // <<<--- Firestore'DAN OKU, YOKSA FALSE
    );
  }
}