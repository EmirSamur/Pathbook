// lib/sayfalar/gezi_haritasi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';
import 'package:pathbooks/veri/konumlar.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';

class _HaritaNoktasi {
  final String baslik;
  final LatLng konum;
  final List<Gonderi> gonderiler = [];

  _HaritaNoktasi(this.baslik, this.konum);
}

/// Kullanıcının paylaşım yaptığı şehirleri haritada iğnelerle gösterir.
class GeziHaritasiSayfasi extends StatelessWidget {
  final List<Gonderi> gonderiler;
  final String kullaniciAdi;

  const GeziHaritasiSayfasi({super.key, required this.gonderiler, required this.kullaniciAdi});

  @override
  Widget build(BuildContext context) {
    final Map<String, _HaritaNoktasi> noktalar = {};
    final Set<String> bulunamayanlar = {};
    for (final g in gonderiler) {
      final Koordinat? k = konumKoordinati(sehir: g.sehir, ulke: g.ulke);
      final String baslik = [g.sehir, g.ulke].where((e) => e != null && e.trim().isNotEmpty).join(", ");
      if (k == null) {
        if (baslik.isNotEmpty) bulunamayanlar.add(baslik);
        continue;
      }
      final String anahtar = "${k.enlem},${k.boylam}";
      noktalar.putIfAbsent(anahtar, () => _HaritaNoktasi(baslik.isNotEmpty ? baslik : "Bilinmeyen konum", LatLng(k.enlem, k.boylam))).gonderiler.add(g);
    }
    final List<_HaritaNoktasi> liste = noktalar.values.toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text("$kullaniciAdi · Gezi Haritası")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              // Tek nokta varsa ona yakınlaş, birden fazlaysa hepsini sığdır.
              initialCenter: liste.length == 1 ? liste.first.konum : const LatLng(39.0, 35.0),
              initialZoom: liste.length == 1 ? 8 : 5,
              initialCameraFit: liste.length >= 2
                  ? CameraFit.coordinates(coordinates: liste.map((n) => n.konum).toList(), padding: const EdgeInsets.all(60), maxZoom: 9)
                  : null,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'com.example.pathbooks',
              ),
              MarkerLayer(
                markers: liste
                    .map((n) => Marker(
                          point: n.konum,
                          width: 52,
                          height: 60,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => _noktaDetayiGoster(context, n),
                            child: _Igne(sayi: n.gonderiler.length, kapakUrl: n.gonderiler.first.resimUrls.isNotEmpty ? n.gonderiler.first.resimUrls.first : null, renk: theme.colorScheme.primary),
                          ),
                        ))
                    .toList(),
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap katkıcıları'),
                  TextSourceAttribution('CARTO'),
                ],
              ),
            ],
          ),
          if (liste.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  "Haritada gösterilecek konum yok.\nPaylaşım yaparken şehir ve ülke eklersen burada görünecek.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ),
          if (bulunamayanlar.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "Haritada bulunamayan yerler: ${bulunamayanlar.join(" · ")}",
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _noktaDetayiGoster(BuildContext context, _HaritaNoktasi nokta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${nokta.baslik} · ${nokta.gonderiler.length} paylaşım", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nokta.gonderiler.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final g = nokta.gonderiler[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: g)));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 110,
                          child: g.resimUrls.isNotEmpty ? AgGorseli(url: g.resimUrls.first) : Container(color: Colors.grey[850]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Igne extends StatelessWidget {
  final int sayi;
  final String? kapakUrl;
  final Color renk;

  const _Igne({required this.sayi, required this.kapakUrl, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: renk, width: 2.5),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
              ),
              child: ClipOval(child: kapakUrl != null ? AgGorseli(url: kapakUrl!) : Container(color: Colors.grey[800])),
            ),
            if (sayi > 1)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(10)),
                  child: Text("$sayi", style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        Icon(Icons.arrow_drop_down_rounded, color: renk, size: 16),
      ],
    );
  }
}
