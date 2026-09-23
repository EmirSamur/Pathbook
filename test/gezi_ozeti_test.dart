import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/veri/gezi_ozeti.dart';
import 'package:pathbooks/veri/konumlar.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';

Gonderi _gonderi({String? sehir, String? ulke, String kategori = "Doğa"}) => Gonderi(
      id: "g",
      kullaniciId: "k",
      resimUrls: const [],
      kategori: kategori,
      aciklama: "",
      sehir: sehir,
      ulke: ulke,
      begeniSayisi: 0,
      yorumSayisi: 0,
      olusturulmaZamani: Timestamp.fromMillisecondsSinceEpoch(0),
    );

void main() {
  group('konumAnahtari', () {
    test('Türkçe karakter ve büyük/küçük harf farklarını yok sayar', () {
      expect(konumAnahtari("İzmir"), "izmir");
      expect(konumAnahtari("IZMIR"), "izmir");
      expect(konumAnahtari("  Balıkesir "), "balikesir");
      expect(konumAnahtari("Şanlıurfa"), "sanliurfa");
      expect(konumAnahtari("New   York"), "new york");
    });
  });

  group('konumKoordinati', () {
    test('şehir bulunursa şehrin koordinatını döndürür', () {
      final k = konumKoordinati(sehir: "balıkesir", ulke: "Türkiye");
      expect(k, isNotNull);
      expect(k!.enlem, closeTo(39.65, 0.01));
    });

    test('şehir bilinmiyorsa ülkeye düşer', () {
      final k = konumKoordinati(sehir: "Bilinmeyen Köy", ulke: "Türkiye");
      expect(k, isNotNull);
      expect(k!.enlem, 39.0);
    });

    test('hiçbiri bilinmiyorsa null döner', () {
      expect(konumKoordinati(sehir: "Atlantis", ulke: "Hayalistan"), isNull);
      expect(konumKoordinati(), isNull);
    });

    test('81 ilin hepsinin koordinatı var', () {
      final eksikler = turkiyeIlleri.where((il) => konumKoordinati(sehir: il) == null).toList();
      expect(eksikler, isEmpty);
      expect(turkiyeIlleri.length, 81);
    });
  });

  group('GeziOzeti', () {
    test('aynı şehrin farklı yazımlarını tek sayar', () {
      final ozet = GeziOzeti.hesapla([
        _gonderi(sehir: "İzmir", ulke: "Türkiye"),
        _gonderi(sehir: "izmir", ulke: "turkiye"),
        _gonderi(sehir: "Paris", ulke: "Fransa", kategori: "Kültür"),
      ]);
      expect(ozet.gonderiSayisi, 3);
      expect(ozet.sehirler.length, 2);
      expect(ozet.sehirler["izmir"], "İzmir"); // İlk görülen yazım korunur
      expect(ozet.ulkeler.length, 2);
      expect(ozet.kategoriler, {"Doğa", "Kültür"});
    });

    test('rozetler eşiklere göre kazanılır', () {
      Rozet rozet(GeziOzeti o, String ad) => o.rozetler.firstWhere((r) => r.ad == ad);

      final bos = GeziOzeti.hesapla(const []);
      expect(bos.rozetler.where((r) => r.kazanildi), isEmpty);

      final ozet = GeziOzeti.hesapla([
        for (final s in ["Ankara", "Bursa", "Van", "Rize", "Kars"]) _gonderi(sehir: s, ulke: "Türkiye"),
        _gonderi(sehir: "Roma", ulke: "İtalya"),
        _gonderi(sehir: "Tokyo", ulke: "Japonya"),
      ]);
      expect(rozet(ozet, "İlk Adım").kazanildi, isTrue);
      expect(rozet(ozet, "Gezgin").kazanildi, isTrue);
      expect(rozet(ozet, "Kaşif").kazanildi, isFalse);
      expect(rozet(ozet, "Dünya Vatandaşı").kazanildi, isTrue);
    });
  });

  group('Ortak widgetlar', () {
    testWidgets('KullaniciAvatari fotoğraf yoksa baş harfi gösterir', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: KullaniciAvatari(kullaniciAdi: "gezgin"))));
      expect(find.text("G"), findsOneWidget);
    });

    testWidgets('KullaniciAvatari ad da yoksa ikon gösterir', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: KullaniciAvatari())));
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('BegeniKalbi oynatılınca görünür, sonra kaybolur', (tester) async {
      final key = GlobalKey<BegeniKalbiState>();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: BegeniKalbi(key: key)))));
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);

      key.currentState!.oynat();
      await tester.pump(); // Animasyon bu karede başlar
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('SayfaNoktalari doğru sayıda nokta çizer', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: SayfaNoktalari(adet: 4, aktif: 1)))));
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });
  });
}
