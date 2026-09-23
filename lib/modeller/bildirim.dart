// lib/modeller/bildirim.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Uygulama içi bildirim (beğeni, yorum, takip).
/// Firestore yolu: kullanicilar/{aliciId}/bildirimler/{bildirimId}
class Bildirim {
  static const String turBegeni = "begeni";
  static const String turYorum = "yorum";
  static const String turTakip = "takip";

  final String id;
  final String tur;
  final String yapanId;
  final String? yapanKullaniciAdi;
  final String? yapanFotoUrl;
  final String? gonderiId;
  final String? gonderiResimUrl;
  final String? metin;
  final bool okundu;
  final Timestamp olusturulmaZamani;

  Bildirim({
    required this.id,
    required this.tur,
    required this.yapanId,
    this.yapanKullaniciAdi,
    this.yapanFotoUrl,
    this.gonderiId,
    this.gonderiResimUrl,
    this.metin,
    required this.okundu,
    required this.olusturulmaZamani,
  });

  factory Bildirim.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Bildirim(
      id: doc.id,
      tur: data['tur'] as String? ?? '',
      yapanId: data['yapanId'] as String? ?? '',
      yapanKullaniciAdi: data['yapanKullaniciAdi'] as String?,
      yapanFotoUrl: data['yapanFotoUrl'] as String?,
      gonderiId: data['gonderiId'] as String?,
      gonderiResimUrl: data['gonderiResimUrl'] as String?,
      metin: data['metin'] as String?,
      okundu: data['okundu'] as bool? ?? false,
      olusturulmaZamani: data['olusturulmaZamani'] as Timestamp? ?? Timestamp.now(),
    );
  }

  String get aciklama {
    switch (tur) {
      case turBegeni:
        return "gönderini beğendi.";
      case turYorum:
        return (metin != null && metin!.isNotEmpty) ? "yorum yaptı: $metin" : "gönderine yorum yaptı.";
      case turTakip:
        return "seni takip etmeye başladı.";
      default:
        return "";
    }
  }
}
