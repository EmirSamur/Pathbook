// girissayfasi.dart (Provider ve Modernize Edilmiş Hali)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthException için
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:provider/provider.dart'; // Provider importu
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modeli (kullanılmasa da importu kalabilir)
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // Firestore servisi importu (Doğru yolu kontrol et!)
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart'; // Yetkilendirme servisi importu

class Girissayfasi extends StatefulWidget {
  const Girissayfasi({Key? key}) : super(key: key);

  @override
  _GirissayfasiState createState() => _GirissayfasiState();
}

class _GirissayfasiState extends State<Girissayfasi> {
  final _formKey = GlobalKey<FormState>();
  // Controller'lar initState içinde başlatılacak
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false; // Yüklenme durumunu takip etmek için

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  // Hata mesajları için Snackbar gösteren yardımcı metot
  void _showErrorSnackbar(String message) {
    // Eğer widget hala ağaçtaysa (sayfadan ayrılmadıysa) Snackbar göster
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Varsa önceki Snackbar'ı kaldır
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error, // Temanın hata rengini kullan
        ),
      );
    }
  }

  // Başarı mesajları için Snackbar gösteren yardımcı metot
  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green, // Başarı için yeşil renk
        ),
      );
    }
  }

  @override
  void dispose() {
    // Controller'ları temizle
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- E-posta/Şifre ile Giriş Yapma Metodu ---
  void _girisYap() async {
    // Form geçerli değilse veya zaten bir işlem yapılıyorsa metottan çık
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() { _isLoading = true; }); // Yüklenme durumunu başlat
    FocusScope.of(context).unfocus(); // Açık klavye varsa kapat

    // YetkilendirmeServisi'ni Provider'dan al ('read' yeterli, çünkü sadece metot çağırıyoruz)
    final yetkilendirmeServisi = context.read<YetkilendirmeServisi>();

    try {
      // Yetkilendirme Servisi üzerinden giriş yapmayı dene
      await yetkilendirmeServisi.girisYap(
        email: _emailController.text.trim(), // E-postanın başındaki/sonundaki boşlukları temizle
        password: _passwordController.text, // Şifreyi olduğu gibi gönder (boşluklar önemli olabilir)
      );
      // Başarılı giriş sonrası manuel yönlendirme YAPMA.
      // Provider'dan gelen state değişikliği ile Yonlendirme widget'ı AnaSayfa'yı gösterecek.
      print("E-posta/Şifre ile giriş başarılı.");

    } on FirebaseAuthException catch (e) {
      // Firebase Authentication'a özel hataları yakala ve kullanıcıya uygun mesaj göster
      String errorMessage = "Giriş sırasında bir hata oluştu."; // Varsayılan mesaj
      // Yaygın hata kodlarına göre mesajı özelleştir
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "E-posta veya şifre hatalı.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Geçersiz e-posta formatı.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "Hesabınız devre dışı bırakılmış.";
      } else {
        // Diğer Firebase hataları için genel bir mesaj ve loglama
        errorMessage = "Bir kimlik doğrulama hatası oluştu. Lütfen tekrar deneyin.";
        print("Firebase Auth Error Code (Giriş): ${e.code} - ${e.message}");
      }
      _showErrorSnackbar(errorMessage); // Hata mesajını göster

    } catch (e) {
      // Diğer beklenmedik hataları yakala (Ağ hatası vb.)
      print("Giriş Hatası (Diğer): ${e.toString()}");
      _showErrorSnackbar('Beklenmedik bir hata oluştu. Lütfen internet bağlantınızı kontrol edin.');

    } finally {
      // İşlem bitince (başarılı veya başarısız) yükleme durumunu kapat
      // Widget hala ekranda ise setState çağır
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- Google ile Giriş Yapma Metodu ---
  void _googleIleGirisYap() async {
    if (_isLoading) return; // Zaten işlem varsa tekrar başlatma
    setState(() => _isLoading = true);
    print("Google ile giriş başlatılıyor...");

    // Servisleri Provider'dan al
    final yetkilendirmeServisi = context.read<YetkilendirmeServisi>();
    final firestoreServisi = context.read<FirestoreServisi>(); // Firestore servisini de al

    try {
      // Yetkilendirme Servisi üzerinden Google ile giriş yapmayı dene
      final Kullanici? girisYapanKullanici = await yetkilendirmeServisi.googleIleGiris();

      // Giriş başarılı ve kullanıcı bilgisi alındıysa devam et
      if (girisYapanKullanici != null) {
        print("Google ile Auth başarılı: ${girisYapanKullanici.id}");

        // Firestore'da kullanıcı var mı kontrol et (kullaniciGetir metodu olduğunu varsayıyoruz)
        print("Firestore kontrol ediliyor...");
        final Kullanici? mevcutFirestoreKullanici = await firestoreServisi.kullaniciGetir(girisYapanKullanici.id);

        // Firestore'da kullanıcı yoksa yeni belge oluştur
        if (mevcutFirestoreKullanici == null) {
          print("Firestore'da kullanıcı bulunamadı, oluşturuluyor...");
          await firestoreServisi.kullaniciOlustur(
            id: girisYapanKullanici.id,
            email: girisYapanKullanici.email ?? '', // Null ise boş string
            // Google'dan gelen DisplayName'i kullan, null ise boş string
            kullaniciAdi: girisYapanKullanici.kullaniciAdi ?? '', fotoUrl: '',
            // Kullanici modelinizde fotoUrl varsa:
            // fotoUrl: girisYapanKullanici.fotoUrl,
          );
          print("Yeni Firestore kullanıcısı oluşturuldu.");
        } else {
          print("Firestore kullanıcısı zaten mevcut.");
          // İsteğe bağlı: Mevcut Firestore belgesini güncelleyebilirsiniz.
        }
        // Başarılı giriş ve Firestore işlemi sonrası yönlendirme otomatik olacak.
        print("Google ile giriş ve Firestore işlemi tamamlandı.");

      } else {
        // Google girişi iptal edildi veya Auth servisi null döndürdü.
        print("Google ile giriş Auth sonucu null veya iptal edildi.");
        // İsteğe bağlı olarak kullanıcıya "Giriş iptal edildi" mesajı gösterilebilir.
        // _showErrorSnackbar("Google ile giriş iptal edildi.");
      }

    } on FirebaseAuthException catch (e) {
      print("Google Giriş Hatası (FirebaseAuthException UI): ${e.code} - ${e.message}");
      _showErrorSnackbar("Google ile giriş yapılamadı. Hesap farklı bir yöntemle oluşturulmuş olabilir.");
    } catch (e, stackTrace) {
      print("Google Giriş Hatası (Diğer UI): ${e.toString()}");
      print("Stack Trace:\n$stackTrace");
      _showErrorSnackbar("Google ile giriş sırasında bir hata oluştu: ${e.toString()}");
    } finally {
      if (mounted) {
        print("Google ile giriş işlemi finally bloğu.");
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Şifre Sıfırlama Metodu ---
  void _sifremiUnuttum() async {
    final email = _emailController.text.trim();
    // E-posta alanı geçerli mi kontrol et
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar("Lütfen geçerli e-posta adresinizi girin.");
      return;
    }
    if (_isLoading) return; // Zaten işlem varsa tekrar başlatma

    if(mounted) setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    // YetkilendirmeServisi'ni Provider'dan al
    final yetkilendirmeServisi = context.read<YetkilendirmeServisi>();

    try {
      // Şifre sıfırlama e-postası göndermeyi dene
      await yetkilendirmeServisi.sifreSifirla(email: email);
      // Başarı mesajı göster
      if (mounted) {
        _showSuccessSnackbar('Şifre sıfırlama bağlantısı $email adresine gönderildi (Gereksiz/Spam klasörünü kontrol etmeyi unutmayın).');
      }
    } on FirebaseAuthException catch (e) {
      // Firebase Auth hatalarını yakala
      String message = "Şifre sıfırlama e-postası gönderilemedi.";
      if(e.code == 'user-not-found'){
        message = "Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı.";
      } else if (e.code == 'invalid-email') {
        message = "Geçersiz e-posta formatı.";
      }
      print("Şifre Sıfırlama Hatası (FirebaseAuthException): ${e.code}");
      _showErrorSnackbar(message);
    } catch (e) {
      // Diğer hatalar
      print("Şifre Sıfırlama Hatası (Diğer): ${e.toString()}");
      _showErrorSnackbar('Şifre sıfırlama sırasında bir hata oluştu.');
    } finally {
      // İşlem bitince yüklemeyi durdur
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Tema bilgilerini alarak UI elemanlarını oluştur
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // Scaffold arka plan rengi otomatik olarak temadan gelir
      body: SafeArea( // Ekranın güvenli alanlarında kalmasını sağlar (örn. çentik altı)
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Form(
              key: _formKey,
              child: ListView( // Çok fazla eleman varsa kaydırma sağlar
                shrinkWrap: true, // İçeriğe göre boyut almasını sağlar
                children: <Widget>[
                  const SizedBox(height: 40.0), // Üst boşluk

                  Center(
                    child: Text(
                      'PATHBOOK',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Bebas', // Bebas fontunu burada kullandık
                        color: colorScheme.onBackground,
                        fontSize: 60,
                        letterSpacing: 1.5,

                      ),
                    ),
                  ),

                  const SizedBox(height: 60.0), // Başlık ve form arası boşluk

                  // E-posta Giriş Alanı
                  TextFormField(
                    controller: _emailController,
                    autocorrect: false, // Otomatik düzeltmeyi kapat
                    keyboardType: TextInputType.emailAddress, // Klavye tipini ayarla
                    textInputAction: TextInputAction.next, // Klavyede "sonraki" tuşu
                    style: TextStyle(color: colorScheme.onSurface), // Temadan yazı rengi
                    decoration: InputDecoration( // Tema varsayılanlarını kullanır
                      labelText: "E-posta",
                      hintText: "ornek@eposta.com", // Yardımcı metin
                      prefixIcon: const Icon(Icons.mail_outline), // İkon
                    ),
                    validator: (value) { // Doğrulama mantığı
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'E-posta alanı boş bırakılamaz.';
                      if (!email.contains('@') || !email.contains('.')) return 'Geçerli bir e-posta adresi giriniz.';
                      return null; // Geçerliyse null döndür
                    },
                  ),
                  const SizedBox(height: 25.0), // Alanlar arası boşluk

                  // Şifre Giriş Alanı
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true, // Şifreyi gizle
                    textInputAction: TextInputAction.done, // Klavyede "bitti" tuşu
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: const Icon(Icons.lock_outline),
                      // İsteğe bağlı: Şifre gösterme/gizleme butonu eklenebilir (suffixIcon)
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Şifre alanı boş bırakılamaz.';
                      // Giriş ekranında genellikle minimum uzunluk kontrolü yapılmaz.
                      return null;
                    },
                    // Klavyeden "bitti" tuşuna basıldığında girişi tetikle
                    onFieldSubmitted: (_) => _isLoading ? null : _girisYap(),
                  ),
                  const SizedBox(height: 40.0), // Şifre alanı ve butonlar arası boşluk

                  // Giriş/Kayıt Butonları veya Yüklenme Göstergesi
                  _isLoading
                      ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) // Yükleniyorsa gösterge
                      : Column( // Yüklenmiyorsa butonları göster
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Butonları genişlet
                    children: [
                      // Giriş Yap Butonu
                      ElevatedButton(
                        onPressed: _girisYap, // Tanımlanan metodu çağır
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(139, 0, 0, 1), // Koyu kırmızı
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Giriş Yap",
                          style: TextStyle(
                            fontFamily: 'Bebas',
                            fontSize: 20,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0), // Butonlar arası boşluk

                      // Hesap Oluştur Butonu
                      ElevatedButton(
                        onPressed: () {
                          // Hesap Oluştur sayfasına gitmek için pushNamed kullan
                          Navigator.of(context).pushNamed('/hesapOlustur');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(139, 0, 0, 1), // Koyu kırmızı
                          foregroundColor: Colors.white,
                        ), // Tema stilini kullan
                        child: const Text(
                          "Hesap Oluştur",
                          style: TextStyle(
                            fontFamily: 'Bebas',
                            fontSize: 20,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 35.0), // "veya" öncesi boşluk
                      Center(child: Text("veya", style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]))),
                      const SizedBox(height: 25.0), // "veya" sonrası boşluk

                      // Google ile Giriş Yap Butonu
                      TextButton(
                        onPressed: _googleIleGirisYap, // Tanımlanan metodu çağır
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          foregroundColor: colorScheme.onBackground,
                        ),
                        child: const Text(
                          "Google ile Giriş Yap",
                          style: TextStyle(
                            fontFamily: 'Bebas',
                            fontSize: 20,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Şifremi Unuttum Linki
                  const SizedBox(height: 20.0),
                  // Yükleme sırasında bu butonu gösterme/devre dışı bırak
                  if (!_isLoading)
                    Center(
                      child: TextButton(
                        onPressed: _sifremiUnuttum, // Tanımlanan metodu çağır
                        style: theme.textButtonTheme.style, // Tema stilini kullan
                        child: const Text(
                          "Şifremi Unuttum?",
                          style: TextStyle(
                            fontFamily: 'Bebas',
                            fontSize: 15,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40.0), // En alt boşluk
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}