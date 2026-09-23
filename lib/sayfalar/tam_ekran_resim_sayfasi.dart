// lib/sayfalar/tam_ekran_resim_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';

/// Gönderi görsellerini tam ekran, kaydırılabilir ve yakınlaştırılabilir gösterir.
class TamEkranResimSayfasi extends StatefulWidget {
  final List<String> resimUrls;
  final int baslangicIndex;

  const TamEkranResimSayfasi({super.key, required this.resimUrls, this.baslangicIndex = 0});

  @override
  State<TamEkranResimSayfasi> createState() => _TamEkranResimSayfasiState();
}

class _TamEkranResimSayfasiState extends State<TamEkranResimSayfasi> {
  late final PageController _pageController = PageController(initialPage: widget.baslangicIndex);
  late int _aktifIndex = widget.baslangicIndex;
  bool _yakinlastirildi = false;

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _kontrolcular.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: widget.resimUrls.length > 1
            ? Text("${_aktifIndex + 1} / ${widget.resimUrls.length}", style: const TextStyle(color: Colors.white, fontSize: 16))
            : null,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            // Yakınlaştırılmışken sayfa kaymasın, resim içinde gezinilebilsin.
            physics: _yakinlastirildi ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
            itemCount: widget.resimUrls.length,
            onPageChanged: (i) => setState(() => _aktifIndex = i),
            itemBuilder: (context, index) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              transformationController: _donusumKontrolcusu(index),
              child: Center(child: AgGorseli(url: widget.resimUrls[index], fit: BoxFit.contain)),
            ),
          ),
          if (widget.resimUrls.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(child: SayfaNoktalari(adet: widget.resimUrls.length, aktif: _aktifIndex)),
            ),
        ],
      ),
    );
  }

  final Map<int, TransformationController> _kontrolcular = {};

  TransformationController _donusumKontrolcusu(int index) {
    return _kontrolcular.putIfAbsent(index, () {
      final c = TransformationController();
      c.addListener(() {
        final bool yakin = c.value.getMaxScaleOnAxis() > 1.01;
        if (yakin != _yakinlastirildi && mounted) setState(() => _yakinlastirildi = yakin);
      });
      return c;
    });
  }
}
