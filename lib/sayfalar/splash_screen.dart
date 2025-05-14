import 'dart:async';
import 'package:flutter/material.dart';

// **** ÖNEMLİ: Yonlendirme widget'ının doğru dosya yolunu ve adını buraya yazın ****
// Eğer dosya adını 'yonlendirme.dart' olarak düzelttiyseniz:
import 'package:pathbooks/yönlendirme.dart';
// Eğer hala 'y%C3%B6nlendirme.dart' ise:
// import 'package:pathbooks/y%C3%B6nlendirme.dart';
// ***************************************************************************

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Animasyonlar için TickerProvider sağlar.
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final Duration _animationDuration = const Duration(seconds: 2); // Animasyon süresi
  final Duration _splashDuration = const Duration(seconds: 3); // Toplam splash süresi

  @override
  void initState() {
    super.initState();

    // 1. Animasyon Kontrolcüsünü Başlat
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this, // TickerProvider olarak bu State nesnesini kullanır.
    );

    // 2. Solma (Fade) Animasyonunu Tanımla
    // Tween, animasyonun başlangıç (0.0 - görünmez) ve bitiş (1.0 - tam görünür) değerlerini belirler.
    // CurvedAnimation, animasyonun hızlanma/yavaşlama eğrisini ayarlar (easeIn: yavaş başlar, hızlanır).
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // 3. Animasyonu İleri Yönde Başlat (0.0 -> 1.0)
    _controller.forward();

    // 4. Belirli bir süre sonra Yönlendirme Widget'ına Geçiş Yap
    _navigateToHome();
  }

  @override
  void dispose() {
    // Widget ağaçtan kaldırıldığında animasyon kontrolcüsünü temizle.
    // Bu, hafıza sızıntılarını ve gereksiz kaynak kullanımını önler.
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Timer(_splashDuration, () {
      // Timer çalıştığında widget hala ekranda mı (mounted) kontrolü önemlidir.
      // Asenkron işlemlerden sonra widget kaldırılmış olabilir.
      if (mounted) {
        // pushReplacement: Mevcut ekranı (SplashScreen) yığından kaldırır ve
        // yeni ekrana (Yonlendirme) geçer. Kullanıcı geri tuşuyla splash'a dönemez.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            // Hedef olarak Yonlendirme widget'ını kullanıyoruz.
            builder: (context) => const Yonlendirme(), // **** Import edilen Yonlendirme widget'ı ****
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Temadan renkleri alalım (main.dart'ta tanımlanan tema kullanılır)
    final Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    // ColorScheme'dan primary rengi almak daha modern ve esnektir.
    final Color textColor = Theme.of(context).colorScheme.primary;

    // Konsola renkleri yazdırarak kontrol edebilirsiniz:
    // print("Splash Background: $backgroundColor");
    // print("Splash Text Color: $textColor");

    return Scaffold(
      backgroundColor: backgroundColor, // Temadan gelen arkaplan rengi
      body: Center(
        // FadeTransition, opacity özelliğini verdiğimiz animasyona göre değiştirir.
        child: FadeTransition(
          opacity: _fadeAnimation, // Animasyon kontrolündeki opaklık değeri
          child: Text(
            'PathBook',
            textAlign: TextAlign.center, // Metni ortala (gerekirse)
            style: TextStyle(
              fontFamily: 'Bebas', // pubspec.yaml'da tanımlı olmalı
              fontSize: 55,       // Biraz daha büyük
              fontWeight: FontWeight.bold,
              color: textColor,    // Temadan gelen ana renk
            ),
          ),
        ),
      ),
    );
  }
}

//----------------------------------------------------
// ÖRNEK LoginPage TANIMINI BURADAN KALDIRDIK.
// Çünkü artık doğrudan Yonlendirme'ye gidiyoruz ve
// gerçek giriş sayfanız (Girissayfasi.dart) zaten mevcut.
//----------------------------------------------------