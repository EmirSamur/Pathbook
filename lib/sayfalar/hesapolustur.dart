// hesapolustur.dart (Provider ve Modernize Edilmiş Hali)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthException için
import 'package:provider/provider.dart'; // Provider importu
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modeli importu
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart'; // Yetkilendirme servisi importu
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // <-- FirestoreServisi importu (YOLU KONTROL ET!)

class HesapOlustur extends StatefulWidget {
  const HesapOlustur({super.key}); // super.key kullanımı

  @override
  State<HesapOlustur> createState() => _HesapOlusturState();
}

class _HesapOlusturState extends State<HesapOlustur> {
  // Formun durumunu yönetmek için GlobalKey
  final _formKey = GlobalKey<FormState>();

  // Form alanlarındaki değerleri tutacak değişkenler
  String _kullaniciAdi = '';
  String _email = '';
  String _sifre = '';

  // İşlem sırasında yüklenme durumunu belirtmek için bool değişken
  bool _isLoading = false;

  // TextFormField'ları kontrol etmek için Controller'lar (late final ile)
  late final TextEditingController _kullaniciAdiController;
  late final TextEditingController _emailController;
  late final TextEditingController _sifreController;

  @override
  void initState() {
    super.initState();
    // Controller'ları başlat
    _kullaniciAdiController = TextEditingController();
    _emailController = TextEditingController();
    _sifreController = TextEditingController();
  }

  @override
  void dispose() {
    // Controller'ları temizle (hafıza sızıntısını önlemek için önemli)
    _kullaniciAdiController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  // Hata durumunda kullanıcıya Snackbar ile geri bildirim veren metot
  void _showErrorSnackbar(String message) {
    // Widget hala ekrandaysa işlemi yap
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Önceki varsa kaldır
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error, // Temadan hata rengi
          duration: const Duration(seconds: 4), // Biraz daha uzun süre göster
        ),
      );
    }
  }

  // Başarı durumunda kullanıcıya Snackbar ile geri bildirim veren metot
  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green, // Başarı için yeşil
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  // Formu gönderme, Auth ve Firestore işlemlerini yapma metodu
  Future<void> _trySubmit() async {
    // 1. Formun geçerli olup olmadığını kontrol et
    final isValid = _formKey.currentState?.validate() ?? false;
    // 2. Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // Form geçerli değilse veya zaten bir işlem yapılıyorsa devam etme
    if (!isValid || _isLoading) {
      if(!isValid){
        _showErrorSnackbar('Lütfen formdaki hataları düzeltin.');
      }
      return;
    }

    // 3. Formdaki onSaved metotlarını çalıştırarak değerleri değişkenlere ata
    _formKey.currentState?.save();
    print("Form kaydedildi: K.Adı: $_kullaniciAdi, Email: $_email"); // Log
    // 4. Yüklenme durumunu başlat ve UI'ı güncelle
    setState(() { _isLoading = true; });
    print("Yükleme başladı..."); // Log

    // 5. Gerekli servisleri Provider'dan al ('read' yeterli)
    YetkilendirmeServisi yetkilendirmeServisi;
    FirestoreServisi firestoreServisi;
    try {
      yetkilendirmeServisi = context.read<YetkilendirmeServisi>();
      firestoreServisi = context.read<FirestoreServisi>();
      print("Servisler Provider'dan alındı."); // Log
    } catch (e) {
      print("Provider Hatası (Servisler alınamadı): $e");
      _showErrorSnackbar("Uygulama hatası: Servisler başlatılamadı.");
      if (mounted) setState(() { _isLoading = false; }); // Yüklemeyi bitir
      return; // İşleme devam etme
    }

    // 6. try-catch-finally bloğu içinde Auth ve Firestore işlemlerini yap
    try {
      print("Auth kaydı deneniyor..."); // Log
      // 6a. Firebase Authentication ile kullanıcıyı kaydet
      Kullanici? yeniKullanici = await yetkilendirmeServisi.kayitOl(
        kullaniciAdi: _kullaniciAdi,
        email: _email,
        password: _sifre,
      );
      print("Auth kaydı sonucu: ${yeniKullanici?.id ?? 'null'}"); // Log

      // 6b. Eğer Auth kaydı başarılıysa (kullanıcı null değilse)
      if (yeniKullanici != null) {
        print("Firestore'a yazma deneniyor (ID: ${yeniKullanici.id})..."); // Log
        // Firestore'a kullanıcı belgesini oluştur/yaz
        // Bu işlem sırasında hata olursa aşağıdaki iç try-catch yakalayacak
        try {
          await firestoreServisi.kullaniciOlustur(
            id: yeniKullanici.id,
            email: _email,
            kullaniciAdi: _kullaniciAdi, fotoUrl: '',
            // Kullanici modelinizde başka alanlar varsa ve burada
            // varsayılan değerler atamak isterseniz ekleyebilirsiniz.
          );
          print("Firestore yazma işlemi tamamlandı."); // Log
        } catch (firestoreError, firestoreStack) {
          // Firestore özelinde bir hata oluşursa logla ve kullanıcıya bildir.
          // Auth işlemi başarılı olduğu için bu kritik bir durumdur.
          print("Firestore Hatası Yakalandı (İç Try-Catch): $firestoreError");
          print("Firestore Stack Trace:\n$firestoreStack");
          if (mounted) {
            _showErrorSnackbar('Hesap oluşturuldu ancak profil bilgileri kaydedilemedi.');
          }
          // Bu hatadan sonra işlemin nasıl devam edeceğine karar verilebilir.
          // Şimdilik finally bloğuna gitmesine izin veriyoruz.
          // throw firestoreError; // İsterseniz hatayı dış catch'e fırlatabilirsiniz.
        }

        // 6c. Auth ve Firestore denemesi sonrası kontrol (mounted ise)
        if (mounted) {
          print('Auth başarılı, Firestore denendi.'); // Log
          // Başarılı kayıt mesajı gösterilebilir. Yönlendirme otomatik olacak.
          _showSuccessSnackbar('Hesap başarıyla oluşturuldu!');
        }
      } else if (mounted) {
        // Auth kaydı başarılı oldu ama servis null döndürdü (beklenmedik)
        print("Auth kaydı null döndü (beklenmedik)."); // Log
        _showErrorSnackbar('Kayıt işlemi tamamlandı ancak kullanıcı bilgisi alınamadı.');
      }

    } on FirebaseAuthException catch (e) { // Firebase Auth hatalarını yakala
      print("FirebaseAuthException Yakalandı (UI): ${e.code} - ${e.message}"); // Log
      String message = 'Hesap oluşturulamadı.'; // Varsayılan mesaj
      // Özel hata kodlarına göre mesajı ayarla
      if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi formatı.';
      }
      _showErrorSnackbar(message);

    } catch (err, stackTrace) { // Diğer tüm hataları yakala
      print('Beklenmedik Hata Yakalandı (UI - Dış Try-Catch): $err'); // Log
      print('Dış Hata Stack Trace:\n$stackTrace');
      _showErrorSnackbar('Hesap oluşturulurken bir hata oluştu: ${err.toString()}');

    } finally {
      // 7. İşlem ne olursa olsun (başarılı/başarısız) yükleme durumunu bitir
      print("Finally bloğuna girildi."); // Log
      if (mounted) {
        print("Widget mounted, isLoading false yapılıyor."); // Log
        setState(() { _isLoading = false; });
      } else {
        print("Widget unmounted, setState çağrılmıyor."); // Log
      }
    }
  }
  // ----- _trySubmit METODU BİTİŞİ -----


  @override
  Widget build(BuildContext context) {
    // Tema bilgilerini build metodu içinde al
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "HESAP OLUŞTUR",
          style: TextStyle(
            fontFamily: 'Bebas',
            fontSize: 26, // İsteğe göre artır/azalt
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        // Başlık
        elevation: 0, // Gölgeyi kaldır
        leading: IconButton( // Geri butonu
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Yüklenme sırasında geri gitmeyi engelle (isteğe bağlı)
            if(!_isLoading) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea( // Güvenli alan içinde
        child: Form(
          key: _formKey, // Form anahtarını ata
          child: ListView( // Kaydırılabilir içerik
            padding: const EdgeInsets.all(20.0), // Kenar boşlukları
            children: <Widget>[
              // Yüklenme göstergesi (eğer yükleniyorsa)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 15.0), // Altına biraz boşluk
                  child: LinearProgressIndicator(minHeight: 5),
                ),
              // const SizedBox(height: 20.0), // ProgressIndicator varsa bu gerekmeyebilir

              // Kullanıcı Adı Giriş Alanı
              TextFormField(
                controller: _kullaniciAdiController,
                enabled: !_isLoading, // Yüklenirken alanı pasif yap
                autocorrect: false,
                textInputAction: TextInputAction.next, // Sonraki alana geç
                style: TextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration( // Temadan alır + özel ayarlar
                  labelText: "Kullanıcı Adı",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final deger = value?.trim() ?? '';
                  if (deger.isEmpty) return 'Kullanıcı adı boş bırakılamaz.';
                  if (deger.length < 4 || deger.length > 15) return 'Kullanıcı adı 4-15 karakter olmalıdır.'; // Uzunluk güncellendi (örnek)
                  // Kullanıcı adında özel karakter kontrolü (isteğe bağlı)
                  // if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(deger)) return 'Sadece harf, rakam ve alt çizgi kullanın.';
                  return null;
                },
                // Değeri state değişkenine kaydet
                onSaved: (value) { _kullaniciAdi = value?.trim() ?? ''; },
              ),
              const SizedBox(height: 20.0), // Alanlar arası boşluk

              // E-posta Giriş Alanı
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final deger = value?.trim() ?? '';
                  if (deger.isEmpty) return 'E-posta alanı boş bırakılamaz.';
                  // Daha basit bir e-posta kontrolü
                  if (!deger.contains('@') || !deger.contains('.')) return 'Geçerli bir e-posta adresi giriniz.';
                  return null;
                },
                onSaved: (value) { _email = value?.trim() ?? ''; },
              ),
              const SizedBox(height: 20.0),

              // Şifre Giriş Alanı
              TextFormField(
                controller: _sifreController,
                enabled: !_isLoading,
                obscureText: true, // Şifreyi gizle
                textInputAction: TextInputAction.done, // Klavye bitti tuşu
                style: TextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: Icon(Icons.lock_outline),
                  // Şifre gösterme/gizleme ikonu eklenebilir
                ),
                validator: (value) {
                  final deger = value ?? '';
                  if (deger.isEmpty) return 'Şifre alanı boş bırakılamaz.';
                  if (deger.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
                  // Daha güçlü şifre kontrolü eklenebilir (büyük harf, rakam vb.)
                  return null;
                },
                onSaved: (value) { _sifre = value ?? ''; },
                // Klavyeden bitti tuşuna basınca formu göndermeyi dene
                onFieldSubmitted: (_) => _isLoading ? null : _trySubmit(),
              ),
              const SizedBox(height: 40.0), // Buton öncesi boşluk

              // Hesap Oluştur Butonu
              ElevatedButton(
                // Yükleniyorsa veya metot null ise onPressed null olur (buton pasifleşir)
                onPressed: _isLoading ? null : _trySubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(139, 0, 0, 1), // Koyu kırmızı
                  foregroundColor: Colors.white,
                ),// Temadan stil al
                child: _isLoading
                    ? SizedBox( // Buton içinde dönen ikon
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary), // Buton içindeki yazı rengi
                  ),
                )
                    : const Text(
                  "Hesap oluştur",
                  style: TextStyle(
                    fontFamily: 'Bebas',
                    fontSize: 20,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ), // Normal metin
              ),
              const SizedBox(height: 20.0), // En alt boşluk
            ],
          ),
        ),
      ),
    );
  }
}