// lib/sayfalar/girissayfasi.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // Bu import çift görünüyor, biri kaldırılabilir.
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
// import 'package:pathbooks/servisler/firestoreseervisi.dart'; // Zaten yukarıda var
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';

class Girissayfasi extends StatefulWidget {
  const Girissayfasi({Key? key}) : super(key: key);

  @override
  _GirissayfasiState createState() => _GirissayfasiState();
}

class _GirissayfasiState extends State<Girissayfasi> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _girisYap() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      if (!(_formKey.currentState?.validate() ?? false)) _showErrorSnackbar('Lütfen tüm alanları doğru doldurun.');
      return;
    }
    setState(() { _isLoading = true; });
    FocusScope.of(context).unfocus();
    final yetkilendirmeServisi = context.read<YetkilendirmeServisi>();
    try {
      await yetkilendirmeServisi.girisYap(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Başarılı giriş sonrası yönlendirme Provider ile otomatik olacak.
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Giriş sırasında bir hata oluştu.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "E-posta veya şifre hatalı.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Geçersiz e-posta formatı.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "Hesabınız devre dışı bırakılmış.";
      } else {
        errorMessage = "Bir kimlik doğrulama hatası oluştu.";
        print("Firebase Auth Error (Giriş): ${e.code} - ${e.message}");
      }
      _showErrorSnackbar(errorMessage);
    } catch (e) {
      print("Giriş Hatası (Diğer): ${e.toString()}");
      _showErrorSnackbar('Beklenmedik bir hata oluştu. Bağlantınızı kontrol edin.');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _googleIleGirisYap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final yetkilendirmeServisi = context.read<YetkilendirmeServisi>();
    final firestoreServisi = context.read<FirestoreServisi>();
    try {
      final Kullanici? girisYapanKullanici = await yetkilendirmeServisi.googleIleGiris();
      if (girisYapanKullanici != null) {
        final Kullanici? mevcutFirestoreKullanici = await firestoreServisi.kullaniciGetir(girisYapanKullanici.id);
        if (mevcutFirestoreKullanici == null) {
          await firestoreServisi.kullaniciOlustur(
            id: girisYapanKullanici.id,
            email: girisYapanKullanici.email ?? '',
            kullaniciAdi: girisYapanKullanici.kullaniciAdi ?? girisYapanKullanici.email?.split('@')[0] ?? '', // Kullanıcı adı için fallback
            fotoUrl: girisYapanKullanici.fotoUrl ?? '', // Google'dan gelen fotoUrl'i kullan
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar("Google ile giriş yapılamadı: ${e.message}");
    } catch (e) {
      _showErrorSnackbar("Google ile giriş sırasında bir hata oluştu.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sifremiUnuttum() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar("Şifre sıfırlama için geçerli e-posta adresinizi girin.");
      return;
    }
    if (_isLoading) return;
    if(mounted) setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();
    final yetkilendirmeServisi = context.read<YetkilendirmeServisi>();
    try {
      await yetkilendirmeServisi.sifreSifirla(email: email);
      if (mounted) _showSuccessSnackbar('Şifre sıfırlama bağlantısı $email adresine gönderildi.');
    } on FirebaseAuthException catch (e) {
      String message = "Şifre sıfırlama e-postası gönderilemedi.";
      if(e.code == 'user-not-found') message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      else if (e.code == 'invalid-email') message = "Geçersiz e-posta formatı.";
      _showErrorSnackbar(message);
    } catch (e) {
      _showErrorSnackbar('Şifre sıfırlama sırasında bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // HesapOlustur sayfasındaki gibi bir InputDecoration stili
  InputDecoration _getInputDecoration(BuildContext context, String label, IconData prefixIcon) {
    final theme = Theme.of(context);
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  // Yüklenme göstergesi
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    )
                  else // Yüklenmiyorsa normal boşluk
                    const SizedBox(height: 40.0),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 50.0, top: 10.0), // Boşluk ayarlandı
                    child: Text(
                      'PATHBOOK',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Bebas',
                        color: colorScheme.onBackground.withOpacity(0.9),
                        fontSize: 56, // HesapOlustur ile aynı
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
                    decoration: _getInputDecoration(context, "E-posta Adresi", Icons.mail_outline_rounded),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'E-posta alanı boş bırakılamaz.';
                      if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
                        return 'Geçerli bir e-posta adresi giriniz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18.0),

                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
                    decoration: _getInputDecoration(context, "Şifre", Icons.lock_outline_rounded),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Şifre alanı boş bırakılamaz.';
                      return null;
                    },
                    onFieldSubmitted: (_) => _isLoading ? null : _girisYap(),
                  ),
                  const SizedBox(height: 30.0),

                  // Giriş Butonu
                  ElevatedButton(
                    onPressed: _isLoading ? null : _girisYap,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: MaterialStateProperty.all(const Color.fromRGBO(139, 0, 0, 1).withOpacity(_isLoading ? 0.5 : 1)), // Koyu kırmızı, yüklenirken opak
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 15)),
                        textStyle: MaterialStateProperty.all(
                            theme.textTheme.labelLarge?.copyWith(fontSize: 18, letterSpacing: 1.1, fontWeight: FontWeight.bold, fontFamily: 'Bebas', color: Colors.white) // Font ayarlandı
                        )
                    ),
                    child: _isLoading && (ModalRoute.of(context)?.isCurrent ?? false) // Sadece bu sayfa aktifken ve yükleniyorsa göster
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)))
                        : const Text("Giriş Yap"),
                  ),
                  const SizedBox(height: 12.0),

                  // Hesap Oluştur Butonu
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pushNamed('/hesapOlustur'),
                    style: theme.textButtonTheme.style?.copyWith(
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                    ),
                    child: Text(
                      "Hesabın yok mu? Kayıt Ol",
                      style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary.withOpacity(0.9), // Temadan birincil renk
                          fontFamily: 'Bebas', // Bebas fontu
                          fontSize: 16,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // "veya" ve Google Butonu
                  if (!_isLoading) // Yüklenirken gösterme
                    Column(
                      children: [
                        Row(
                          children: <Widget>[
                            Expanded(child: Divider(color: Colors.grey[700], thickness: 0.5)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text("VEYA", style: textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 11, letterSpacing: 0.5)),
                            ),
                            Expanded(child: Divider(color: Colors.grey[700], thickness: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        OutlinedButton.icon( // Google butonu için OutlinedButton daha şık olabilir

                          label: Text(
                            "Google ile Devam Et",
                            style: TextStyle(
                                fontFamily: 'OpenSans', // Google için daha standart bir font
                                fontSize: 14,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                          onPressed: _isLoading ? null : _googleIleGirisYap,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[700]!, width: 1.0),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 15.0),

                  // Şifremi Unuttum
                  if (!_isLoading)
                    Center(
                      child: TextButton(
                        onPressed: _sifremiUnuttum,
                        child: Text(
                          "Şifremi Unuttum?",
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontFamily: 'OpenSans', // Daha standart bir font
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}