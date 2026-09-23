// lib/sayfalar/etiket_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';

enum EtiketTuru { kategori, ulke, sehir, konum }

/// Bir kategori, ülke, şehir veya konum etiketine dokunulduğunda
/// o etiketteki tüm gönderileri ızgara hâlinde gösterir.
class EtiketSayfasi extends StatefulWidget {
  final EtiketTuru tur;
  final String deger;

  const EtiketSayfasi({super.key, required this.tur, required this.deger});

  @override
  State<EtiketSayfasi> createState() => _EtiketSayfasiState();
}

class _EtiketSayfasiState extends State<EtiketSayfasi> {
  static const int _limit = 18;
  late final FirestoreServisi _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
  final ScrollController _scrollController = ScrollController();

  final List<Gonderi> _gonderiler = [];
  DocumentSnapshot? _sonDoc;
  bool _yukleniyor = false;
  bool _hepsiYuklendi = false;
  bool _hata = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) _yukle();
    });
    _yukle();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    if (_yukleniyor || _hepsiYuklendi) return;
    setState(() {
      _yukleniyor = true;
      _hata = false;
    });
    try {
      final sonuc = await _firestoreServisi.gonderileriGetirFiltreleSirala(
        kategori: widget.tur == EtiketTuru.kategori ? widget.deger : null,
        ulke: widget.tur == EtiketTuru.ulke ? widget.deger : null,
        sehir: widget.tur == EtiketTuru.sehir ? widget.deger : null,
        konum: widget.tur == EtiketTuru.konum ? widget.deger : null,
        limitSayisi: _limit,
        sonGorunenDoc: _sonDoc,
      );
      final yeni = sonuc['gonderiler'] as List<Gonderi>;
      if (!mounted) return;
      setState(() {
        _gonderiler.addAll(yeni);
        _sonDoc = sonuc['sonDoc'] as DocumentSnapshot? ?? _sonDoc;
        _hepsiYuklendi = yeni.length < _limit;
      });
    } catch (e) {
      if (mounted) setState(() => _hata = true);
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  IconData get _ikon {
    switch (widget.tur) {
      case EtiketTuru.kategori:
        return Icons.category_outlined;
      case EtiketTuru.ulke:
        return Icons.public_rounded;
      case EtiketTuru.sehir:
        return Icons.location_city_rounded;
      case EtiketTuru.konum:
        return Icons.push_pin_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_ikon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(child: Text(widget.deger, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      body: _govde(theme),
    );
  }

  Widget _govde(ThemeData theme) {
    if (_gonderiler.isEmpty && _yukleniyor) {
      return GridView.builder(
        padding: const EdgeInsets.all(1),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
        itemCount: 12,
        itemBuilder: (_, __) => const IskeletKutu(),
      );
    }
    if (_gonderiler.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_hata ? Icons.cloud_off_rounded : Icons.travel_explore_rounded, size: 52, color: Colors.grey[600]),
            const SizedBox(height: 14),
            Text(
              _hata ? "Gönderiler yüklenemedi." : "\"${widget.deger}\" etiketinde henüz gönderi yok.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            if (_hata) TextButton(onPressed: _yukle, child: const Text("Tekrar dene")),
          ]),
        ),
      );
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1, mainAxisSpacing: 1),
      itemCount: _gonderiler.length,
      itemBuilder: (context, index) {
        final gonderi = _gonderiler[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: gonderi))),
          child: Stack(fit: StackFit.expand, children: [
            gonderi.resimUrls.isNotEmpty ? AgGorseli(url: gonderi.resimUrls.first) : Container(color: Colors.grey[900]),
            if (gonderi.resimUrls.length > 1)
              const Positioned(top: 5, right: 5, child: Icon(Icons.collections_rounded, size: 16, color: Colors.white)),
          ]),
        );
      },
    );
  }
}
