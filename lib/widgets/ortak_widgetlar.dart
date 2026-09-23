// lib/widgets/ortak_widgetlar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Profil fotoğrafı; fotoğraf yoksa kullanıcı adının baş harfini gösterir.
class KullaniciAvatari extends StatelessWidget {
  final String? fotoUrl;
  final String? kullaniciAdi;
  final double yaricap;

  const KullaniciAvatari({super.key, this.fotoUrl, this.kullaniciAdi, this.yaricap = 18});

  static const List<Color> _renkler = [
    Color(0xFFB71C1C), Color(0xFF4A148C), Color(0xFF0D47A1), Color(0xFF004D40),
    Color(0xFFE65100), Color(0xFF3E2723), Color(0xFF263238), Color(0xFF880E4F),
  ];

  @override
  Widget build(BuildContext context) {
    final bool fotoVar = fotoUrl != null && fotoUrl!.startsWith('http');
    final String ad = (kullaniciAdi ?? '').trim();
    final String basHarf = ad.isNotEmpty ? ad.characters.first.toUpperCase() : '';
    final Color arkaPlan = ad.isNotEmpty ? _renkler[ad.codeUnitAt(0) % _renkler.length] : Colors.grey[850]!;

    return CircleAvatar(
      radius: yaricap,
      backgroundColor: arkaPlan,
      backgroundImage: fotoVar ? CachedNetworkImageProvider(fotoUrl!) : null,
      child: fotoVar
          ? null
          : basHarf.isNotEmpty
              ? Text(basHarf, style: TextStyle(color: Colors.white, fontSize: yaricap * 0.95, fontWeight: FontWeight.bold))
              : Icon(Icons.person_rounded, size: yaricap, color: Colors.grey[500]),
    );
  }
}

/// Ağ görseli: önbellekli, yüklenirken iskelet, hata durumunda ikon gösterir.
class AgGorseli extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const AgGorseli({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (context, _) => const IskeletKutu(),
      errorWidget: (context, _, __) => Container(
        color: Colors.grey[900],
        child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 30)),
      ),
    );
  }
}

/// Yükleme sırasında gösterilen parıldayan (shimmer) kutu.
class IskeletKutu extends StatefulWidget {
  final double? genislik;
  final double? yukseklik;
  final BorderRadius borderRadius;

  const IskeletKutu({super.key, this.genislik, this.yukseklik, this.borderRadius = BorderRadius.zero});

  @override
  State<IskeletKutu> createState() => _IskeletKutuState();
}

class _IskeletKutuState extends State<IskeletKutu> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double t = _controller.value * 3 - 1; // -1 → 2
        return Container(
          width: widget.genislik,
          height: widget.yukseklik,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(t - 1, -0.3),
              end: Alignment(t, 0.3),
              colors: const [Color(0xFF1C1C1E), Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
            ),
          ),
        );
      },
    );
  }
}

/// Gönderi kartı biçiminde yükleme iskeleti.
class GonderiKartiIskeleti extends StatelessWidget {
  const GonderiKartiIskeleti({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IskeletKutu(genislik: 36, yukseklik: 36, borderRadius: BorderRadius.circular(18)),
              const SizedBox(width: 10),
              IskeletKutu(genislik: 110, yukseklik: 12, borderRadius: BorderRadius.circular(6)),
            ]),
          ),
          const AspectRatio(aspectRatio: 1, child: IskeletKutu()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IskeletKutu(genislik: 160, yukseklik: 12, borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 8),
              IskeletKutu(genislik: 220, yukseklik: 12, borderRadius: BorderRadius.circular(6)),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Resmin üzerinde çift dokunmada beliren kalp animasyonu.
class BegeniKalbi extends StatefulWidget {
  const BegeniKalbi({super.key});

  @override
  State<BegeniKalbi> createState() => BegeniKalbiState();
}

class BegeniKalbiState extends State<BegeniKalbi> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final Animation<double> _olcek = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
  ]).animate(_controller);

  void oynat() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _olcek,
        builder: (context, _) => _olcek.value <= 0
            ? const SizedBox.shrink()
            : Transform.scale(
                scale: _olcek.value,
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 96, shadows: [
                  Shadow(color: Colors.black54, blurRadius: 18),
                ]),
              ),
      ),
    );
  }
}

/// Çok görselli gönderiler için sayfa noktaları.
class SayfaNoktalari extends StatelessWidget {
  final int adet;
  final int aktif;

  const SayfaNoktalari({super.key, required this.adet, required this.aktif});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(adet, (i) {
        final bool secili = i == aktif;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: secili ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: secili ? Colors.white : Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
