import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // İsim çakışmasını önlemek için alias kullandık

// flutter/material.dart importu bu sınıf için gerekli değilse kaldırılabilir.
// import 'package:flutter/material.dart';

class Kullanici {
  final String id; // ID genellikle zorunludur ve null olamaz
  final String? kullaniciAdi; // Null olabilir
  final String? fotoUrl;      // Null olabilir
  final String? email;        // Null olabilir (bazı auth yöntemlerinde)
  final String? hakkinda;     // Null olabilir

  // Constructor: 'required' anahtar kelimesi ve nullable tipler kullanıldı
  Kullanici({
    required this.id,
    this.kullaniciAdi,
    this.fotoUrl,
    this.email,
    this.hakkinda,
  });

  // Factory: Firebase Auth kullanıcısından Kullanici nesnesi üretir
  factory Kullanici.firebasedenUret(fb_auth.User firebaseUser) {
    // firebaseUser null olmamalı, bu kontrol genellikle çağıran yerde yapılır.
    return Kullanici(
      id: firebaseUser.uid, // uid null olamaz
      kullaniciAdi: firebaseUser.displayName, // displayName null olabilir
      fotoUrl: firebaseUser.photoURL,       // photoURL null olabilir
      email: firebaseUser.email,          // email null olabilir
      hakkinda: null, // Firebase Auth User objesinde 'hakkinda' bilgisi yoktur
    );
  }

  // Factory: Firestore DocumentSnapshot'tan Kullanici nesnesi üretir
  // En iyi pratik, tip güvenliği için Map<String, dynamic> kullanmaktır.
  factory Kullanici.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc) {
    // doc.data() metodu Map<String, dynamic>? döndürür (null olabilir)
    final docData = doc.data();

    // docData'nın null olup olmadığını kontrol etmek iyi bir pratiktir.
    // Uygulamanızın mantığına göre null ise hata fırlatabilir veya varsayılan değerlerle dönebilirsiniz.
    // if (docData == null) {
    //   // Örneğin: Hata fırlat
    //   throw StateError("Doküman verisi bulunamadı: ${doc.id}");
    //   // Veya: Varsayılan bir Kullanici döndür / null döndür
    //   // return Kullanici(id: doc.id); // Sadece ID ile veya null
    // }

    return Kullanici(
      id: doc.id, // doc.id null olamaz
      // Alanlara güvenli erişim: `docData?['alanAdi']` ve tip dönüşümü `as String?`
      kullaniciAdi: docData?['kullaniciAdi'] as String?,
      email: docData?['email'] as String?,
      fotoUrl: docData?['fotoUrl'] as String?,
      hakkinda: docData?['hakkinda'] as String?,
    );
  }


/*
  // Eğer DocumentSnapshot tipi belirtilmemişse (eski usül veya genel kullanım):
  factory Kullanici.dokumandanUretEski(DocumentSnapshot doc) {
    // doc.data() Object? döndürür, güvenli cast gerekir.
    final docData = doc.data() as Map<String, dynamic>?;

    return Kullanici(
      id: doc.id,
      kullaniciAdi: docData?['kullaniciAdi'] as String?,
      email: docData?['email'] as String?,
      fotoUrl: docData?['fotoUrl'] as String?,
      hakkinda: docData?['hakkinda'] as String?,
    );
  }
  */
}