// lib/veri/gezi_ozeti.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/veri/konumlar.dart';

class Rozet {
  final String ad;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  final bool kazanildi;

  const Rozet({required this.ad, required this.aciklama, required this.ikon, required this.renk, required this.kazanildi});
}

/// Bir kullanıcının gönderilerinden gezdiği yerlerin özetini çıkarır.
class GeziOzeti {
  final int gonderiSayisi;
  /// Anahtar: normalleştirilmiş şehir adı, değer: ilk görülen yazımı.
  final Map<String, String> sehirler;
  final Map<String, String> ulkeler;
  final Set<String> kategoriler;

  GeziOzeti._(this.gonderiSayisi, this.sehirler, this.ulkeler, this.kategoriler);

  factory GeziOzeti.hesapla(List<Gonderi> gonderiler) {
    final Map<String, String> sehirler = {};
    final Map<String, String> ulkeler = {};
    final Set<String> kategoriler = {};
    for (final g in gonderiler) {
      if (g.sehir != null && g.sehir!.trim().isNotEmpty) sehirler.putIfAbsent(konumAnahtari(g.sehir!), () => g.sehir!.trim());
      if (g.ulke != null && g.ulke!.trim().isNotEmpty) ulkeler.putIfAbsent(konumAnahtari(g.ulke!), () => g.ulke!.trim());
      if (g.kategori.isNotEmpty) kategoriler.add(g.kategori);
    }
    return GeziOzeti._(gonderiler.length, sehirler, ulkeler, kategoriler);
  }

  List<Rozet> get rozetler => [
        Rozet(ad: "İlk Adım", aciklama: "İlk paylaşımını yap", ikon: Icons.flag_rounded, renk: Colors.greenAccent, kazanildi: gonderiSayisi >= 1),
        Rozet(ad: "Gezgin", aciklama: "5 farklı şehirde paylaşım yap", ikon: Icons.hiking_rounded, renk: Colors.orangeAccent, kazanildi: sehirler.length >= 5),
        Rozet(ad: "Kaşif", aciklama: "15 farklı şehirde paylaşım yap", ikon: Icons.explore_rounded, renk: Colors.lightBlueAccent, kazanildi: sehirler.length >= 15),
        Rozet(ad: "Dünya Vatandaşı", aciklama: "3 farklı ülkede paylaşım yap", ikon: Icons.public_rounded, renk: Colors.purpleAccent, kazanildi: ulkeler.length >= 3),
        Rozet(ad: "Çok Yönlü", aciklama: "4 farklı kategoride paylaşım yap", ikon: Icons.auto_awesome_rounded, renk: Colors.amberAccent, kazanildi: kategoriler.length >= 4),
        Rozet(ad: "Hikâye Anlatıcı", aciklama: "25 paylaşıma ulaş", ikon: Icons.menu_book_rounded, renk: Colors.redAccent, kazanildi: gonderiSayisi >= 25),
      ];
}
