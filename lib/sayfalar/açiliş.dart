// lib/sayfalar/acilis.dart
import 'dart:async';
import 'package:flutter/material.dart';

class AcilisSayfasi extends StatefulWidget {
  const AcilisSayfasi({Key? key}) : super(key: key);

  @override
  _AcilisSayfasiState createState() => _AcilisSayfasiState();
}

class _AcilisSayfasiState extends State<AcilisSayfasi> with TickerProviderStateMixin { // Birden fazla controller için TickerProviderStateMixin
  late AnimationController _entryController;
  late AnimationController _fadeOutController;

  // Her harf için animasyonlar
  late List<Animation<Offset>> _letterSlideAnimations;
  late List<Animation<double>> _letterFadeInAnimations; // Harflerin belirme animasyonu
  late Animation<double> _textFadeOutAnimation;    // Tüm metnin solma animasyonu

  final String _appName = "PATHBOOK";
  final int _harfAnimasyonSuresiMs = 300; // Her bir harfin kayma süresi
  final int _harflerArasiGecikmeMs = 100; // Harflerin birbiri ardına gelme gecikmesi
  final int _birlesmeSonrasiBeklemeMs = 1000; // Harfler birleştikten sonra bekleme
  final int _tumMetinSolmaSuresiMs = 700; // Tüm metnin solma süresi

  bool _harflerBirlesiyor = true; // Başlangıçta harfler birleşme animasyonunda

  @override
  void initState() {
    super.initState();

    // --- Giriş Animasyonları (Harflerin Kayması ve Belirmesi) ---
    _entryController = AnimationController(
      vsync: this,
      // Toplam giriş animasyon süresi: (harf sayısı * harflerArasiGecikme) + harfAnimasyonSuresi
      duration: Duration(milliseconds: (_appName.length * _harflerArasiGecikmeMs) + _harfAnimasyonSuresiMs),
    );

    _letterSlideAnimations = [];
    _letterFadeInAnimations = [];

    for (int i = 0; i < _appName.length; i++) {
      // Her harf için kayma animasyonu (farklı başlangıç noktalarından ortaya)
      // Örnek: P soldan, A yukarıdan, T sağdan... bunu daha dinamik yapabiliriz.
      // Şimdilik hepsi farklı Y eksenlerinden gelsin.
      final double startY;
      if (i % 2 == 0) {
        startY = -1.5; // Yukarıdan
      } else {
        startY = 1.5;  // Aşağıdan
      }

      _letterSlideAnimations.add(
        Tween<Offset>(
          begin: Offset(0.0, startY), // X sabit, Y farklı
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entryController,
            // Her harf için gecikmeli başlangıç
            curve: Interval(
              (i * _harflerArasiGecikmeMs).toDouble() / _entryController.duration!.inMilliseconds,
              ((i * _harflerArasiGecikmeMs) + _harfAnimasyonSuresiMs).toDouble() / _entryController.duration!.inMilliseconds,
              curve: Curves.elasticOut, // Daha enerjik bir giriş
            ),
          ),
        ),
      );

      // Her harf için fade in animasyonu
      _letterFadeInAnimations.add(
          Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _entryController,
              curve: Interval(
                (i * _harflerArasiGecikmeMs).toDouble() / _entryController.duration!.inMilliseconds,
                ((i * _harflerArasiGecikmeMs) + _harfAnimasyonSuresiMs * 0.7).toDouble() / _entryController.duration!.inMilliseconds, // Biraz daha hızlı belirsin
                curve: Curves.easeIn,
              ),
            ),
          )
      );
    }

    // --- Çıkış Animasyonu (Tüm Metnin Solması) ---
    _fadeOutController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _tumMetinSolmaSuresiMs),
    );

    _textFadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
    );

    // Giriş animasyonu bittikten sonra bekle ve çıkış animasyonunu başlat
    _entryController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _harflerBirlesiyor = false; // Harfler artık birleşti, tek bir grup gibi davranacak
        });
        Future.delayed(Duration(milliseconds: _birlesmeSonrasiBeklemeMs), () {
          if (mounted) {
            _fadeOutController.forward();
          }
        });
      }
    });

    // Çıkış animasyonu bittikten sonra yönlendir
    _fadeOutController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _yonlendir();
      }
    });

    // Giriş animasyonunu başlat
    _entryController.forward();
  }

  void _yonlendir() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/yonlendirme');
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.displaySmall?.copyWith( // displaySmall veya displayMedium
      color: Colors.white,
      fontWeight: FontWeight.bold,
      // fontFamily: 'Bebas', // Temadan alınıyor varsayalım
    ) ?? const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white);

    List<Widget> letterWidgets = [];
    for (int i = 0; i < _appName.length; i++) {
      letterWidgets.add(
        FadeTransition(
          opacity: _letterFadeInAnimations[i],
          child: SlideTransition(
            position: _letterSlideAnimations[i],
            child: Text(
              _appName[i],
              style: textStyle,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        // Eğer harfler birleşiyorsa (giriş animasyonu), harfleri ayrı ayrı Row içinde göster.
        // Eğer harfler birleşti ve çıkış animasyonu başlayacaksa, tüm yazıyı tek bir FadeTransition ile göster.
        child: _harflerBirlesiyor
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: letterWidgets,
        )
            : FadeTransition(
          opacity: _textFadeOutAnimation,
          child: Text(
            _appName,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}