// lib/sayfalar/hesapolustur.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';

class HesapOlustur extends StatefulWidget {
  const HesapOlustur({super.key});

  @override
  State<HesapOlustur> createState() => _HesapOlusturState();
}

class _HesapOlusturState extends State<HesapOlustur> {
  final _formKey = GlobalKey<FormState>();
  String _kullaniciAdi = '';
  String _email = '';
  String _sifre = '';
  bool _isLoading = false;

  late final TextEditingController _kullaniciAdiController;
  late final TextEditingController _emailController;
  late final TextEditingController _sifreController;

  @override
  void initState() {
    super.initState();
    _kullaniciAdiController = TextEditingController();
    _emailController = TextEditingController();
    _sifreController = TextEditingController();
  }

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _trySubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();
    if (!isValid || _isLoading) {
      if (!isValid) _showErrorSnackbar('Lütfen formdaki tüm alanları doğru doldurun.');
      return;
    }
    _formKey.currentState?.save();
    if (mounted) setState(() { _isLoading = true; });

    try {
      final yetkilendirmeServisi = context.read<YetkilendirmeServisi>();
      final firestoreServisi = context.read<FirestoreServisi>();
      Kullanici? yeniKullanici = await yetkilendirmeServisi.kayitOl(
        kullaniciAdi: _kullaniciAdi,
        email: _email,
        password: _sifre,
      );
      if (yeniKullanici != null) {
        await firestoreServisi.kullaniciOlustur(
          id: yeniKullanici.id,
          email: _email,
          kullaniciAdi: _kullaniciAdi,
          fotoUrl: '',
        );
        if (mounted) {
          _showSuccessSnackbar('Hesap başarıyla oluşturuldu! Giriş yapabilirsiniz.');
          if (Navigator.canPop(context)) {
            await Future.delayed(const Duration(seconds: 1));
            Navigator.of(context).pop();
          }
        }
      } else if (mounted) {
        _showErrorSnackbar('Kayıt işlemi tamamlandı ancak kullanıcı bilgisi alınamadı.');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Hesap oluşturulamadı.';
      if (e.code == 'weak-password') message = 'Şifre çok zayıf.';
      else if (e.code == 'email-already-in-use') message = 'Bu e-posta zaten kayıtlı.';
      else if (e.code == 'invalid-email') message = 'Geçersiz e-posta formatı.';
      else message = "Bir kimlik doğrulama hatası oluştu: ${e.message}";
      _showErrorSnackbar(message);
    } catch (err) {
      _showErrorSnackbar('Beklenmedik bir hata oluştu: ${err.toString()}');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // <<<--- InputDecoration Yardımcı Metodu Sınıf Seviyesine Taşındı ---<<<
  InputDecoration _getInputDecoration(BuildContext context, String label, IconData prefixIcon) {
    final theme = Theme.of(context); // Temayı burada al
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14.5),
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor ?? colorScheme.surface.withOpacity(0.07),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.error, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Yeni Hesap Oluştur",
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 20, letterSpacing: 0.5), // Boyut ayarlandı
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.appBarTheme.iconTheme?.color ?? Colors.white70),
          onPressed: () => _isLoading ? null : Navigator.of(context).pop(),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.3, // Hafif bir elevation
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0), // Dikey padding azaltıldı
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 35.0, top: 5.0), // Boşluk ayarlandı
                    child: Text(
                      'PATHBOOK',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Bebas',
                        color: colorScheme.onBackground.withOpacity(0.9),
                        fontSize: 50, // Boyut ayarlandı
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),

                  TextFormField(
                    controller: _kullaniciAdiController,
                    enabled: !_isLoading,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
                    decoration: _getInputDecoration(context, "Kullanıcı Adı", Icons.person_outline_rounded), // context eklendi
                    validator: (value) {
                      final deger = value?.trim() ?? '';
                      if (deger.isEmpty) return 'Kullanıcı adı boş bırakılamaz.';
                      if (deger.length < 3) return 'Kullanıcı adı en az 3 karakter olmalıdır.';
                      if (deger.length > 20) return 'Kullanıcı adı en fazla 20 karakter olabilir.';
                      if (deger.contains(' ')) return 'Kullanıcı adı boşluk içeremez.';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(deger)) return 'Sadece harf, rakam ve alt çizgi (_).';
                      return null;
                    },
                    onSaved: (value) { _kullaniciAdi = value?.trim() ?? ''; },
                  ),
                  const SizedBox(height: 18.0),

                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
                    decoration: _getInputDecoration(context, "E-posta Adresi", Icons.mail_outline_rounded), // context eklendi
                    validator: (value) {
                      final deger = value?.trim() ?? '';
                      if (deger.isEmpty) return 'E-posta alanı boş bırakılamaz.';
                      if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(deger)) {
                        return 'Geçerli bir e-posta adresi giriniz.';
                      }
                      return null;
                    },
                    onSaved: (value) { _email = value?.trim() ?? ''; },
                  ),
                  const SizedBox(height: 18.0),

                  TextFormField(
                    controller: _sifreController,
                    enabled: !_isLoading,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
                    decoration: _getInputDecoration(context, "Şifre", Icons.lock_outline_rounded), // context eklendi
                    validator: (value) {
                      final deger = value ?? '';
                      if (deger.isEmpty) return 'Şifre alanı boş bırakılamaz.';
                      if (deger.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
                      return null;
                    },
                    onSaved: (value) { _sifre = value ?? ''; },
                    onFieldSubmitted: (_) => _isLoading ? null : _trySubmit(),
                  ),
                  const SizedBox(height: 30.0), // Boşluk ayarlandı

                  ElevatedButton(
                    onPressed: _isLoading ? null : _trySubmit,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)), // Yükseklik ayarlandı
                        textStyle: MaterialStateProperty.all(
                            theme.textTheme.labelLarge?.copyWith(fontSize: 16, letterSpacing: 1.1, fontWeight: FontWeight.bold, fontFamily: 'Bebas') // Stil ayarlandı
                        )
                    ),
                    child: _isLoading
                        ? SizedBox(
                      height: 18, width: 18, // Boyut küçültüldü
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0, // Kalınlık azaltıldı
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary.withOpacity(0.9)),
                      ),
                    )
                        : const Text("Hesap Oluştur"),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}