// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- Servis ve Model Importları ---
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/modeller/kullanici.dart';
// -----------------------------------

// --- Sayfa Importları ---
import 'package:pathbooks/yönlendirme.dart'; // Yonlendirme sayfası hala kullanılacak
import 'package:pathbooks/sayfalar/girissayfasi.dart';
import 'package:pathbooks/sayfalar/hesapolustur.dart';
import 'package:pathbooks/sayfalar/açiliş.dart'; // <<<--- YENİ AÇILIŞ SAYFASI IMPORTU
// -----------------------------------

import 'package:timeago/timeago.dart' as timeago;
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');

  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreServisi>(
          create: (_) => FirestoreServisi(),
        ),
        ProxyProvider<FirestoreServisi, YetkilendirmeServisi>(
          update: (context, firestoreServisi, previousYetkilendirmeServisi) =>
              YetkilendirmeServisi(firestoreServisi: firestoreServisi),
        ),
        StreamProvider<Kullanici?>(
          create: (context) => context.read<YetkilendirmeServisi>().durumTakipcisi,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Pathbooks',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Bebas',
          colorScheme: ColorScheme.dark(
            primary: Colors.red[700]!,
            secondary: Colors.redAccent[400]!,
            background: Colors.black,
            surface: const Color(0xFF1E1E1E), // Kart ve diyaloglar için
            error: Colors.orange[700]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onBackground: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF121212), // Genellikle scaffoldBackgroundColor ile aynı veya biraz farklı
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20, // Biraz küçültüldü, Bebas zaten büyük duruyor
              fontWeight: FontWeight.w500, // Bold yerine w500
              fontFamily: 'Bebas',
            ),
            iconTheme: const IconThemeData(color: Colors.white70), // İkon rengi
          ),
          textTheme: const TextTheme( /* ... (Mevcut TextTheme ayarların) ... */ ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white.withOpacity(0.87),
          ),
          inputDecorationTheme: InputDecorationTheme( /* ... (Mevcut InputDecorationTheme ayarların) ... */ ),
          elevatedButtonTheme: ElevatedButtonThemeData( /* ... (Mevcut ElevatedButtonThemeData ayarların) ... */ ),
          textButtonTheme: TextButtonThemeData( /* ... (Mevcut TextButtonThemeData ayarların) ... */ ),
          cardTheme: CardTheme( /* ... (Mevcut CardTheme ayarların) ... */ ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData( /* ... (Mevcut BottomNavigationBarThemeData ayarların) ... */ ),
        ),
        // home: const Yonlendirme(), // <<<--- ESKİ BAŞLANGIÇ SAYFASI
        home: const AcilisSayfasi(),   // <<<--- YENİ BAŞLANGIÇ SAYFASI
        routes: {
          '/girisYap': (context) => const Girissayfasi(),
          '/hesapOlustur': (context) => const HesapOlustur(),
          '/yonlendirme': (context) => const Yonlendirme(), // Yonlendirme için bir route eklendi (AcilisSayfasi'ndan geçiş için)
          // Diğer named route'ların varsa burada kalabilir.
        },
        onUnknownRoute: (settings) { /* ... (Mevcut onUnknownRoute) ... */ },
      ),
    );
  }
}