// lib/modeller/dosya_modeli.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Sadece Timestamp için gerekli

class DosyaModeli {
  final String id;
  final String ad;
  final List<String> kapakResimleri;
  final int gonderiSayisi;
  final String olusturanKullaniciId;
  final DateTime? sonGuncelleme;
  final bool gizliMi;
  final List<String> katkidaBulunanlarProfilResimleri;

  DosyaModeli({
    required this.id,
    required this.ad,
    this.kapakResimleri = const [],
    required this.gonderiSayisi,
    required this.olusturanKullaniciId,
    this.sonGuncelleme,
    this.gizliMi = false,
    this.katkidaBulunanlarProfilResimleri = const [],
  });

  factory DosyaModeli.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data() ?? {};
    List<String> kapakListesi = [];
    if (data['kapakResimleri'] is List) {
      kapakListesi = List<String>.from(
          (data['kapakResimleri'] as List).whereType<String>());
    }
    List<String> katkidaBulunanlarListesi = [];
    if (data['katkidaBulunanlarProfilResimleri'] is List) {
      katkidaBulunanlarListesi = List<String>.from(
          (data['katkidaBulunanlarProfilResimleri'] as List)
              .whereType<String>());
    }
    DateTime? sonGuncellemeTarihi;
    if (data['sonGuncelleme'] is Timestamp) {
      sonGuncellemeTarihi = (data['sonGuncelleme'] as Timestamp).toDate();
    }
    return DosyaModeli(
      id: doc.id,
      ad: data['ad'] as String? ?? 'İsimsiz Dosya',
      kapakResimleri: kapakListesi,
      gonderiSayisi: data['gonderiSayisi'] as int? ?? 0,
      olusturanKullaniciId: data['olusturanKullaniciId'] as String? ?? '',
      sonGuncelleme: sonGuncellemeTarihi,
      gizliMi: data['gizliMi'] as bool? ?? false,
      katkidaBulunanlarProfilResimleri: katkidaBulunanlarListesi,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ad': ad,
      'kapakResimleri': kapakResimleri,
      'gonderiSayisi': gonderiSayisi,
      'olusturanKullaniciId': olusturanKullaniciId,
      'sonGuncelleme': sonGuncelleme != null ? Timestamp.fromDate(sonGuncelleme!) : null,
      'gizliMi': gizliMi,
      'katkidaBulunanlarProfilResimleri': katkidaBulunanlarProfilResimleri,
    };
  }
}