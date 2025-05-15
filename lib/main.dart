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
import 'package:pathbooks/yönlendirme.dart'; // Varsayılan olarak 'yonlendirme.dart'
import 'package:pathbooks/sayfalar/girissayfasi.dart';
import 'package:pathbooks/sayfalar/hesapolustur.dart';
// -----------------------------------

import 'package:timeago/timeago.dart' as timeago;
import 'firebase_options.dart'; // Firebase CLI ile oluşturulan dosya

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');

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
          fontFamily: 'Bebas', // GENEL VARSAYILAN FONT

          colorScheme: ColorScheme.dark(
            primary: Colors.red[700]!,
            secondary: Colors.redAccent[400]!,
            background: Colors.black,
            surface: const Color(0xFF1E1E1E),
            error: Colors.orange[700]!,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onBackground: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
          ),

          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Bebas',
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'Bebas', fontSize: 96, fontWeight: FontWeight.w300, letterSpacing: -1.5),
            displayMedium: TextStyle(fontFamily: 'Bebas', fontSize: 60, fontWeight: FontWeight.w300, letterSpacing: -0.5),
            displaySmall: TextStyle(fontFamily: 'Bebas', fontSize: 48, fontWeight: FontWeight.w400),
            headlineMedium: TextStyle(fontFamily: 'Bebas', fontSize: 34, fontWeight: FontWeight.w400, letterSpacing: 0.25),
            headlineSmall: TextStyle(fontFamily: 'Bebas', fontSize: 24, fontWeight: FontWeight.w400),
            titleLarge: TextStyle(fontFamily: 'Bebas', fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15),
            titleMedium: TextStyle(fontFamily: 'Bebas', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
            titleSmall: TextStyle(fontFamily: 'Bebas', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
            bodyLarge: TextStyle(fontFamily: 'OpenSans', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5), // Okunaklı font
            bodyMedium: TextStyle(fontFamily: 'OpenSans', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25), // Okunaklı font
            labelLarge: TextStyle(fontFamily: 'Bebas', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
            bodySmall: TextStyle(fontFamily: 'OpenSans', fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4), // Okunaklı font
            labelSmall: TextStyle(fontFamily: 'OpenSans', fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5), // Okunaklı font
          ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white.withOpacity(0.87),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
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

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Bebas'),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent[200],
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Bebas'),
            ),
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF1E1E1E),
            elevation: 1.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: const Color(0xFF121212),
            selectedItemColor: Colors.red[700],
            unselectedItemColor: Colors.grey[500],
            type: BottomNavigationBarType.fixed,
            elevation: 4.0,
            selectedLabelStyle: const TextStyle(fontFamily: 'Bebas', fontSize: 11, fontWeight: FontWeight.w600), // Font weight eklendi
            unselectedLabelStyle: const TextStyle(fontFamily: 'Bebas', fontSize: 10),
          ),
        ),
        home: const Yonlendirme(),
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