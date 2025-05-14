// pathbooks/servisler/yetkilendirmeservisi.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // FirestoreServisi'ni import et

class YetkilendirmeServisi {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreServisi _firestoreServisi; // FirestoreServisi'ni tutacak alan

  // --- AKTİF KULLANICI BİLGİLERİ ---
  String? _aktifKullaniciId;
  Kullanici? _aktifKullaniciDetaylari; // Firestore'dan çekilen detaylı kullanıcı bilgisi

  String? get aktifKullaniciId => _aktifKullaniciId;
  Kullanici? get aktifKullaniciDetaylari => _aktifKullaniciDetaylari;
  // --- ---

  // Constructor: FirestoreServisi'ni dependency olarak alır
  YetkilendirmeServisi({required FirestoreServisi firestoreServisi})
      : _firestoreServisi = firestoreServisi;


  Kullanici? _kullaniciAuthModelindenUret(fb_auth.User? firebaseUser) {
    // Bu metod sadece Firebase Auth User objesinden temel Kullanici modeli üretir.
    // Firestore'dan detaylı bilgiyi durumTakipcisi içinde çekeceğiz.
    return firebaseUser == null ? null : Kullanici.firebasedenUret(firebaseUser);
  }

  Stream<Kullanici?> get durumTakipcisi {
    return _firebaseAuth.authStateChanges().asyncMap((fb_auth.User? firebaseUser) async {
      _aktifKullaniciId = firebaseUser?.uid; // Her durumda aktif kullanıcı ID'sini güncelle

      if (firebaseUser == null) {
        _aktifKullaniciDetaylari = null; // Kullanıcı yoksa detayları da null yap
        return null;
      }

      // Kullanıcı varsa, Firestore'dan detaylarını çek.
      try {
        // Önce Firestore'dan kullanıcıyı getirmeyi dene
        _aktifKullaniciDetaylari = await _firestoreServisi.kullaniciGetir(firebaseUser.uid);

        if (_aktifKullaniciDetaylari == null) {
          // Firestore'da kullanıcı yoksa (örneğin, sadece Auth'a kayıt olmuş ama profil Firestore'a yazılmamış)
          // Bu durum özellikle yeni kayıt olmuş veya Google ile ilk kez giriş yapmış kullanıcılar için olabilir.
          // Firebase Auth bilgilerinden temel bir Kullanici nesnesi oluştur.
          // Google ile giriş yapılıyorsa, Firestore'a kayıt işlemini googleIleGiris metodu halledecek.
          // Normal kayıt için, kayitOl metodu Firestore'a yazmalı.
          print("Firestore'da kullanıcı (${firebaseUser.uid}) bulunamadı. Sadece Auth bilgileri kullanılıyor.");
          _aktifKullaniciDetaylari = Kullanici.firebasedenUret(firebaseUser);
          // Eğer bu bir e-posta/şifre kullanıcısıysa ve Firestore'da yoksa,
          // burada Firestore'a yazma işlemi de düşünülebilir, ancak bu genellikle
          // kayitOl veya googleIleGiris metodlarının sorumluluğundadır.
        }
        return _aktifKullaniciDetaylari;
      } catch (e) {
        print("YetkilendirmeServisi - Aktif kullanıcı detayları çekilirken hata: $e");
        // Hata durumunda en azından Firebase Auth bilgilerinden bir Kullanici nesnesi oluştur
        _aktifKullaniciDetaylari = Kullanici.firebasedenUret(firebaseUser);
        return _aktifKullaniciDetaylari;
      }
    });
  }

  Future<Kullanici?> kayitOl({
    required String kullaniciAdi,
    required String email,
    required String password
  }) async {
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(kullaniciAdi);
        // Yeni kullanıcıyı Firestore'a kaydet
        await _firestoreServisi.kullaniciOlustur(
          id: user.uid,
          email: email,
          kullaniciAdi: kullaniciAdi,
          // fotoUrl başlangıçta boş olabilir veya varsayılan bir URL atanabilir.
        );
        await user.reload();
        fb_auth.User? updatedUser = _firebaseAuth.currentUser;
        print('Kullanıcı oluşturuldu, DisplayName güncellendi ve Firestore\'a kaydedildi: ${updatedUser?.uid}');

        // Firestore'dan güncel kullanıcı detaylarını çekip _aktifKullaniciDetaylari'nı set et
        _aktifKullaniciDetaylari = await _firestoreServisi.kullaniciGetir(user.uid);
        return _aktifKullaniciDetaylari ?? _kullaniciAuthModelindenUret(updatedUser); // Firestore'dan gelmezse Auth'dan üret
      } else {
        return null;
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Kayıt sırasında beklenmedik bir hata oluştu.");
    }
  }

  Future<Kullanici?> girisYap({required String email, required String password}) async {
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Giriş yapıldığında da Firestore'dan kullanıcı detaylarını çek
      if (userCredential.user != null) {
        _aktifKullaniciDetaylari = await _firestoreServisi.kullaniciGetir(userCredential.user!.uid);
        return _aktifKullaniciDetaylari ?? _kullaniciAuthModelindenUret(userCredential.user);
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Giriş sırasında beklenmedik bir hata oluştu.");
    }
  }

  Future<void> cikisYap() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      _aktifKullaniciId = null; // ID'yi sıfırla
      _aktifKullaniciDetaylari = null; // Detayları sıfırla
      print("Firebase oturumu başarıyla kapatıldı.");
    } catch (e) {
      throw Exception("Oturum kapatılırken bir hata oluştu.");
    }
  }

  Future<void> sifreSifirla({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch(e) {
      throw Exception("Şifre sıfırlama sırasında beklenmedik bir hata oluştu.");
    }
  }

  Future<Kullanici?> googleIleGiris() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final fb_auth.AuthCredential credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final fb_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Google ile ilk kez giriş yapılıyorsa Firestore'a kaydet
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          print("Yeni Google kullanıcısı, Firestore'a kaydediliyor...");
          await _firestoreServisi.kullaniciOlustur(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? googleUser.email, // Firebase'den gelen email öncelikli
            kullaniciAdi: firebaseUser.displayName ?? googleUser.displayName ?? "Google Kullanıcısı",
            fotoUrl: firebaseUser.photoURL ?? googleUser.photoUrl ?? '',
          );
          print("Yeni Google kullanıcısı Firestore'a kaydedildi: ${firebaseUser.uid}");
        }
        // Giriş yapıldığında Firestore'dan kullanıcı detaylarını çek
        _aktifKullaniciDetaylari = await _firestoreServisi.kullaniciGetir(firebaseUser.uid);
        return _aktifKullaniciDetaylari ?? _kullaniciAuthModelindenUret(firebaseUser);
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Google ile giriş sırasında beklenmedik bir hata oluştu.");
    }
  }
}