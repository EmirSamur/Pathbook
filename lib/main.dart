// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// --- Servis ve Model Importları ---
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // Dosya adı kontrol edilmeli
import 'package:pathbooks/modeller/kullanici.dart';
// -----------------------------------

// --- Sayfa Importları ---
// Dosya adında "%C3%B6" gibi karakterler olmamalı. "yonlendirme.dart" olmalı.
import 'package:pathbooks/yönlendirme.dart'; // Varsayılan olarak 'yonlendirme.dart'
import 'package:pathbooks/sayfalar/girissayfasi.dart';
import 'package:pathbooks/sayfalar/hesapolustur.dart';
// -----------------------------------

// **** YENİ: Timeago importu ****
import 'package:timeago/timeago.dart' as timeago;

import 'firebase_options.dart'; // Firebase CLI ile oluşturulan dosya

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // **** YENİ: Timeago için Türkçe dil ayarları ****
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr'); // Varsayılan lokali ayarla

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. FirestoreServisi'ni sağla (bağımsız)
        Provider<FirestoreServisi>(
          create: (_) => FirestoreServisi(),
        ),
        // 2. YetkilendirmeServisi'ni FirestoreServisi'ne bağımlı olarak ProxyProvider ile sağla
        ProxyProvider<FirestoreServisi, YetkilendirmeServisi>(
          // update fonksiyonu, dinlenen provider (FirestoreServisi) her değiştiğinde
          // veya YetkilendirmeServisi ilk kez oluşturulduğunda çağrılır.
          // `firestoreServisi` parametresi, Provider<FirestoreServisi>'nden gelen örnektir.
          // `previousYetkilendirmeServisi` ise (varsa) bir önceki YetkilendirmeServisi örneğidir.
          update: (context, firestoreServisi, previousYetkilendirmeServisi) =>
              YetkilendirmeServisi(firestoreServisi: firestoreServisi),
          // Eğer YetkilendirmeServisi'nin state'ini korumak istemiyorsanız (genellikle gerekmez):
          // create: (context) => YetkilendirmeServisi(
          //   firestoreServisi: Provider.of<FirestoreServisi>(context, listen: false),
          // ),
          // Ancak ProxyProvider, dinlenen provider güncellendiğinde bağımlı provider'ı da
          // yeniden oluşturmak veya güncellemek için daha iyidir.
        ),
        // 3. Kullanıcı durumunu StreamProvider ile dinle
        StreamProvider<Kullanici?>(
          create: (context) => context.read<YetkilendirmeServisi>().durumTakipcisi,
          initialData: null, // Başlangıçta kullanıcı bilgisi yok
        ),
      ],
      child: MaterialApp(
        title: 'Pathbooks',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // --- Ana Tema Ayarları (Siyah Tema) ---
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,

          // --- Renk Şeması (Siyah Temaya Uygun) ---
          colorScheme: ColorScheme.dark(
            primary: Colors.red[700]!,
            secondary: Colors.redAccent[400]!,
            background: Colors.black,
            surface: Color(0xFF1E1E1E),
            error: Colors.orange[700]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onBackground: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
          ),

          // --- AppBar Teması ---
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF121212),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Bebas',
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),

          // --- Input Alanları İçin Varsayılan Stil ---
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF2C2C2E),
            hintStyle: TextStyle(color: Colors.grey[600]),
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIconColor: Colors.grey[400],
            errorStyle: TextStyle(color: Colors.orange[700]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey[700]!, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2.0),
            ),
          ),

          // --- Buton Temaları ---
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent[200],
              textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          // --- Diğer Tema Ayarları (Örnek) ---
          cardTheme: CardTheme(
            color: Color(0xFF1E1E1E), // colorScheme.surface ile uyumlu
            elevation: 1.0, // Daha sade bir görünüm için
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Kartlar arası boşluk
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF121212), // AppBar ile aynı veya biraz farklı
            selectedItemColor: Colors.red[700], // Temanın primary rengi
            unselectedItemColor: Colors.grey[500],
            type: BottomNavigationBarType.fixed, // Tüm etiketleri göster
            elevation: 4.0, // Hafif bir gölge
          ),
          // --- Varsayılan Metin Teması ---
          // Projenizde genel metin stillerini buradan ayarlayabilirsiniz.
          // textTheme: TextTheme(
          //   bodyLarge: TextStyle(color: Colors.white),
          //   bodyMedium: TextStyle(color: Colors.grey[300]),
          //   // ... diğer stiller
          // ),
        ),
        home: const Yonlendirme(), // Dosya adı 'yonlendirme.dart' olmalı
        routes: {
          '/girisYap': (context) => const Girissayfasi(),
          '/hesapOlustur': (context) => const HesapOlustur(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text("Hata")),
              body: Center(child: Text("Sayfa bulunamadı: ${settings.name}")),
            ),
          );
        },
      ),
    );
  }
}