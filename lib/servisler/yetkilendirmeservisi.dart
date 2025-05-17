// pathbooks/servisler/yetkilendirmeservisi.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';

class YetkilendirmeServisi {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreServisi _firestoreServisi;

  String? _aktifKullaniciId;
  Kullanici? _aktifKullaniciDetaylari;

  String? get aktifKullaniciId => _aktifKullaniciId;
  Kullanici? get aktifKullaniciDetaylari => _aktifKullaniciDetaylari;

  YetkilendirmeServisi({required FirestoreServisi firestoreServisi})
      : _firestoreServisi = firestoreServisi {
    // Servis oluşturulduğunda mevcut kullanıcı durumunu kontrol et
    _firebaseAuth.authStateChanges().listen((fb_auth.User? user) async {
      _aktifKullaniciId = user?.uid;
      if (user != null) {
        await _aktifKullaniciDetaylariniYukle(user.uid); // Detayları yükle
      } else {
        _aktifKullaniciDetaylari = null;
      }
      // Eğer ChangeNotifier kullanıyor olsaydık burada notifyListeners() çağırırdık.
      // Şu an için bu stream'i dinleyen widget'lar (durumTakipcisi) zaten güncellenecek.
    });
  }

  Kullanici? _kullaniciAuthModelindenUret(fb_auth.User? firebaseUser) {
    return firebaseUser == null ? null : Kullanici.firebasedenUret(firebaseUser);
  }

  // Firestore'dan kullanıcı detaylarını çekip _aktifKullaniciDetaylari'nı güncelleyen yardımcı metod
  Future<void> _aktifKullaniciDetaylariniYukle(String kullaniciId) async {
    try {
      _aktifKullaniciDetaylari = await _firestoreServisi.kullaniciGetir(kullaniciId);
      if (_aktifKullaniciDetaylari == null) {
        // Firestore'da kullanıcı yoksa ve Auth'da varsa, Auth'dan temel bilgilerle doldur.
        // Bu senaryo normalde kayitOl veya googleIleGiris sırasında Firestore'a yazıldığı için nadir olmalı.
        fb_auth.User? currentUserAuth = _firebaseAuth.currentUser;
        if (currentUserAuth != null && currentUserAuth.uid == kullaniciId) {
          _aktifKullaniciDetaylari = Kullanici.firebasedenUret(currentUserAuth);
          print("YetkilendirmeServisi: Firestore'da kullanıcı ($kullaniciId) bulunamadı, sadece Auth bilgileriyle oluşturuldu.");
        }
      }
      // ChangeNotifier olsaydı: notifyListeners();
    } catch (e) {
      print("YetkilendirmeServisi (_aktifKullaniciDetaylariniYukle): Kullanıcı detayları çekilirken hata: $e");
      // Hata durumunda da en azından Auth'dan gelen temel bilgiyi tutmaya çalışabiliriz
      fb_auth.User? currentUserAuth = _firebaseAuth.currentUser;
      if (currentUserAuth != null && currentUserAuth.uid == kullaniciId) {
        _aktifKullaniciDetaylari = Kullanici.firebasedenUret(currentUserAuth);
      } else {
        _aktifKullaniciDetaylari = null;
      }
      // ChangeNotifier olsaydı: notifyListeners();
    }
  }


  Stream<Kullanici?> get durumTakipcisi {
    return _firebaseAuth.authStateChanges().asyncMap((fb_auth.User? firebaseUser) async {
      _aktifKullaniciId = firebaseUser?.uid;

      if (firebaseUser == null) {
        _aktifKullaniciDetaylari = null;
        return null;
      }
      // Detayları zaten _aktifKullaniciDetaylariniYukle ile veya constructor'daki listener ile güncelledik.
      // Burada tekrar çekmek yerine mevcut _aktifKullaniciDetaylari'nı döndürebiliriz.
      // Ancak, her auth state değiştiğinde en güncelini çekmek daha güvenli olabilir.
      await _aktifKullaniciDetaylariniYukle(firebaseUser.uid);
      return _aktifKullaniciDetaylari;
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
        await _firestoreServisi.kullaniciOlustur(
          id: user.uid,
          email: email,
          kullaniciAdi: kullaniciAdi,
        );
        await user.reload(); // Firebase Auth user nesnesini sunucudakiyle senkronize et
        // fb_auth.User? updatedUser = _firebaseAuth.currentUser; // Bu satır yerine direkt user.uid kullan

        await _aktifKullaniciDetaylariniYukle(user.uid); // Detayları yükle ve _aktifKullaniciDetaylari'nı set et
        return _aktifKullaniciDetaylari;
      }
      return null;
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
      if (userCredential.user != null) {
        await _aktifKullaniciDetaylariniYukle(userCredential.user!.uid);
        return _aktifKullaniciDetaylari;
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
      // _aktifKullaniciId ve _aktifKullaniciDetaylari constructor'daki listener tarafından zaten null yapılacak.
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
        bool isNewUserInFirestore = false;
        // Önce Firestore'da kullanıcı var mı diye kontrol et
        Kullanici? existingFirestoreUser = await _firestoreServisi.kullaniciGetir(firebaseUser.uid);

        if (existingFirestoreUser == null) {
          isNewUserInFirestore = true;
          print("Yeni Google kullanıcısı (Firestore'da yok), Firestore'a kaydediliyor...");
          await _firestoreServisi.kullaniciOlustur(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? googleUser.email,
            kullaniciAdi: firebaseUser.displayName ?? googleUser.displayName ?? "Google Kullanıcısı",
            fotoUrl: firebaseUser.photoURL ?? googleUser.photoUrl ?? '',
          );
          print("Yeni Google kullanıcısı Firestore'a kaydedildi: ${firebaseUser.uid}");
        }

        await _aktifKullaniciDetaylariniYukle(firebaseUser.uid);
        return _aktifKullaniciDetaylari;
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception("Google ile giriş sırasında beklenmedik bir hata oluştu.");
    }
  }

  // YENİ EKLENEN METOD
  Future<void> aktifKullaniciGuncelleVeYenidenYukle(Kullanici guncellenmisKullanici) async {
    if (_aktifKullaniciId != null) {
      print("YetkilendirmeServisi: Aktif kullanıcı detayları yeniden yükleniyor (ID: $_aktifKullaniciId)...");
      await _aktifKullaniciDetaylariniYukle(_aktifKullaniciId!);
      // Bu metodun kendisi doğrudan UI'ı güncellemez (ChangeNotifier olmadığı için).
      // Bu metodu çağıran yer, UI'ın güncellenmesi için gerekli adımları atmalıdır.
      // (Örneğin, Provider'ı dinleyen bir widget'ın state'ini güncellemek veya
      //  ana widget ağacında bir state değişikliğini tetiklemek.)
      //  durumTakipcisi stream'i zaten yeni _aktifKullaniciDetaylari ile bir event yayınlayacaktır
      //  eğer bu metod çağrıldıktan sonra authStateChanges tetiklenirse veya
      //  bu metodun dönüş değeri kullanılarak UI güncellenirse.
      //  Daha proaktif olmak için, bu metodun bir bool döndürmesi (başarılı/başarısız)
      //  veya güncellenmiş Kullanici nesnesini döndürmesi de düşünülebilir.
      //  Şimdilik sadece _aktifKullaniciDetaylari'nı güncelliyor.
      print("YetkilendirmeServisi: Aktif kullanıcı detayları yeniden yüklendi.");
    } else {
      print("YetkilendirmeServisi: Yeniden yüklenecek aktif kullanıcı ID'si bulunamadı.");
    }
  }

  // Profil düzenleme sayfasından sonra manuel olarak Kullanici nesnesini set etmek için (opsiyonel)
  void setAktifKullaniciDetaylariManuel(Kullanici? kullanici) {
    if (kullanici != null && _aktifKullaniciId == kullanici.id) {
      _aktifKullaniciDetaylari = kullanici;
      print("YetkilendirmeServisi: Aktif kullanıcı detayları manuel olarak set edildi.");
      // ChangeNotifier olsaydı: notifyListeners();
      // Bu, durumTakipcisi'nın bir sonraki event'inde bu güncel bilgiyi kullanmasını sağlar.
    }
  }
}