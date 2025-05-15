// lib/modeller/oneri_modeli.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OneriModeli {
  final String id;          // Firestore belgesinin ID'si
  final String yerAdi;
  final String ipucuMetni;
  final String? gorselUrl;   // Opsiyonel olduğu için String? yaptık

  OneriModeli({
    required this.id,
    required this.yerAdi,
    required this.ipucuMetni,
    this.gorselUrl,
  });

  // Firestore DocumentSnapshot'tan OneriModeli nesnesi üreten fabrika metodu
  factory OneriModeli.dokumandanUret(DocumentSnapshot doc) {
    // Gelen verinin Map<String, dynamic> olduğundan emin olalım
    final data = doc.data() as Map<String, dynamic>?;

    // data null ise veya beklenen alanlar yoksa hata fırlatmak yerine
    // varsayılan değerler atayabilir veya null döndürebiliriz.
    // Şimdilik, alanlar eksikse boş string veya null atayalım.
    if (data == null) {
      // Bu durum aslında olmamalı, ama bir güvenlik önlemi
      print("UYARI: OneriModeli.dokumandanUret - Belge verisi null geldi. ID: ${doc.id}");
      return OneriModeli(
        id: doc.id,
        yerAdi: "Bilinmeyen Yer",
        ipucuMetni: "Harika bir keşif seni bekliyor!",
        gorselUrl: null,
      );
    }

    return OneriModeli(
      id: doc.id, // Belgenin kendi ID'sini kullanıyoruz
      yerAdi: data['yerAdi'] as String? ?? 'Başlıksız Öneri', // Null ise varsayılan
      ipucuMetni: data['ipucuMetni'] as String? ?? 'Keşfetmek için dokun...', // Null ise varsayılan
      gorselUrl: data['gorselUrl'] as String?, // Zaten nullable, cast yeterli
    );
  }
}