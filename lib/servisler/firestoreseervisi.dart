// pathbooks/servisler/firestore_servisi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelinin isVerified alanını içerdiğinden emin ol
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/dosya_modeli.dart';
import 'package:pathbooks/modeller/oneri_modeli.dart';
import 'package:pathbooks/modeller/bildirim.dart';
// StoryModeli importu burada gerekli değil gibi, eğer story ile ilgili metodlar yoksa.
// import 'package:pathbooks/modeller/story_modeli.dart';

class FirestoreServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _kullanicilarKoleksiyonu = "kullanicilar";
  final String _gonderilerKoleksiyonu = "gonderiler";
  final String _dosyalarKoleksiyonu = "dosyalar";
  final String _begenilerAltKoleksiyonu = "begenenKullanicilar";
  final String _yorumlarAltKoleksiyonu = "yorumlar";
  final String _onerilerKoleksiyonu = "oneriler";
  final String _kaydedilenlerAltKoleksiyonu = "kaydedilenler";
  final String _bildirimlerAltKoleksiyonu = "bildirimler";
  final String _sikayetlerKoleksiyonu = "sikayetler";
  // final String _storiesKoleksiyonu = "stories"; // Eğer story özelliği varsa bu da tanımlanmalı

  // --- KULLANICI İŞLEMLERİ ---
  Future<void> kullaniciOlustur({
    required String id,
    required String email,
    required String kullaniciAdi,
    String fotoUrl = '',
  }) async {
    try {
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).set({
        "kullaniciAdi": kullaniciAdi,
        "email": email,
        "fotoUrl": fotoUrl,
        "hakkinda": "",
        "olusturulmaZamani": FieldValue.serverTimestamp(),
        "gonderiSayisi": 0,
        "takipciSayisi": 0,
        "takipEdilenSayisi": 0,
        "guncellenmeZamani": FieldValue.serverTimestamp(),
        "isVerified": false, // <<<--- YENİ EKLENEN ALAN (Varsayılan olarak false)
      });
      print("Firestore: Kullanıcı belgesi oluşturuldu (ID: $id), isVerified: false");
    } on FirebaseException catch (e) {
      print("Firestore Hatası (kullaniciOlustur): Kod: ${e.code}, Mesaj: ${e.message}");
      throw Exception("Kullanıcı profili oluşturulamadı: ${e.message}");
    } catch (e) {
      print("Beklenmedik Hata (kullaniciOlustur): $e");
      throw Exception("Kullanıcı profili oluşturulurken beklenmedik bir hata oluştu.");
    }
  }

  // Aynı kullanıcı için tekrar tekrar istek atılmaması için basit bir önbellek.
  final Map<String, Future<Kullanici?>> _kullaniciOnbellegi = {};

  Future<Kullanici?> kullaniciGetir(String id, {bool onbellekKullan = true}) {
    if (!onbellekKullan) {
      final Future<Kullanici?> taze = _kullaniciGetirSunucudan(id);
      _kullaniciOnbellegi[id] = taze;
      return taze;
    }
    return _kullaniciOnbellegi.putIfAbsent(id, () => _kullaniciGetirSunucudan(id).then((k) {
      if (k == null) _kullaniciOnbellegi.remove(id); // Hata/boş sonucu önbellekte tutma
      return k;
    }));
  }

  void kullaniciOnbelleginiTemizle([String? id]) {
    if (id == null) {
      _kullaniciOnbellegi.clear();
    } else {
      _kullaniciOnbellegi.remove(id);
    }
  }

  Future<Kullanici?> _kullaniciGetirSunucudan(String id) async {
    if (id.isEmpty) {
      print("Firestore Hatası (kullaniciGetir): Kullanıcı ID'si boş.");
      return null;
    }
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).get();
      if (doc.exists) {
        return Kullanici.dokumandanUret(doc); // Kullanici modeli isVerified'ı okuyacak şekilde güncellenmiş olmalı
      } else {
        print("FirestoreServisi: Kullanıcı $id bulunamadı.");
        return null;
      }
    } on FirebaseException catch (e) {
      print("Firestore Hatası (kullaniciGetir ID: $id): Kod: ${e.code}, Mesaj: ${e.message}");
      return null;
    } catch (e) {
      print("Beklenmedik Hata (kullaniciGetir ID: $id): $e");
      return null;
    }
  }

  Future<List<OneriModeli>> tumOnerileriGetir() async {
    List<OneriModeli> onerilerListesi = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await _firestore.collection(_onerilerKoleksiyonu).get();
      if (querySnapshot.docs.isNotEmpty) {
        onerilerListesi = querySnapshot.docs
            .map((doc) => OneriModeli.dokumandanUret(doc))
            .toList();
      }
    } catch (e) {
      print("FirestoreServisi - tumOnerileriGetir HATA: $e");
    }
    return onerilerListesi;
  }

  Future<void> kullaniciGuncelle({
    required String id,
    required Map<String, dynamic> veri,
  }) async {
    if (id.isEmpty) throw ArgumentError("Kullanıcı ID'si boş olamaz.");
    try {
      Map<String, dynamic> guncellenecekVeri = Map.from(veri);
      guncellenecekVeri['guncellenmeZamani'] = FieldValue.serverTimestamp();
      // 'isVerified' alanının normal kullanıcılar tarafından güncellenmemesi için
      // Firestore Güvenlik Kuralları'nda kısıtlama olmalı.
      // Bu metot, admin paneli veya güvenli bir yerden çağrılıyorsa 'isVerified' de güncelleyebilir.
      // Şimdilik, gelen 'veri' map'inde ne varsa onu güncelliyoruz.
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).update(guncellenecekVeri);
      print("Firestore: Kullanıcı güncellendi (ID: $id)");
      kullaniciOnbelleginiTemizle(id);
    } on FirebaseException catch (e) {
      throw Exception("Kullanıcı bilgileri güncellenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Kullanıcı bilgileri güncellenirken beklenmedik bir hata oluştu.");
    }
  }

  // --- GÖNDERİ İŞLEMLERİ ---
  Future<void> gonderiOlustur({
    required String yayinlayanId,
    required List<String> gonderiResmiUrls,
    required String aciklama,
    required String kategori,
    String? konum,
    String? ulke,
    String? sehir,
  }) async {
    if (yayinlayanId.isEmpty) throw ArgumentError("Yayınlayan ID'si boş olamaz.");
    if (gonderiResmiUrls.isEmpty) throw ArgumentError("Gönderi resmi URL listesi boş olamaz.");
    if (kategori.isEmpty) throw ArgumentError("Kategori boş olamaz.");
    try {
      Map<String, dynamic> gonderiVerisi = {
        "kullaniciId": yayinlayanId, "resimUrls": gonderiResmiUrls, "aciklama": aciklama.trim(),
        "konum": konum?.trim().isNotEmpty == true ? konum!.trim() : null,
        "kategori": kategori, "begeniSayisi": 0, "yorumSayisi": 0,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
      };
      if (ulke != null && ulke.trim().isNotEmpty) gonderiVerisi['ulke'] = ulke.trim();
      if (sehir != null && sehir.trim().isNotEmpty) gonderiVerisi['sehir'] = sehir.trim();
      await _firestore.collection(_gonderilerKoleksiyonu).add(gonderiVerisi);
      DocumentReference kullaniciRef = _firestore.collection(_kullanicilarKoleksiyonu).doc(yayinlayanId);
      await kullaniciRef.update({"gonderiSayisi": FieldValue.increment(1), "guncellenmeZamani": FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw Exception("Gönderi oluşturulurken bir sunucu hatası oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Gönderi oluşturulurken beklenmedik bir hata oluştu.");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> kullaniciGonderileriniGetir(String kullaniciId) {
    if (kullaniciId.isEmpty) return Stream.empty();
    return _firestore.collection(_gonderilerKoleksiyonu)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .orderBy('olusturulmaZamani', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> kullanicininSehirGonderileriniGetir({
    required String kullaniciId,
    required String sehir,
  }) {
    if (kullaniciId.isEmpty || sehir.isEmpty) return Stream.empty();
    return _firestore.collection(_gonderilerKoleksiyonu)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('sehir', isEqualTo: sehir)
        .orderBy('olusturulmaZamani', descending: true)
        .snapshots()
        .handleError((error, stackTrace) {
      print("Firestore Stream Hatası (kullanicininSehirGonderileriniGetir): $error \n$stackTrace");
      if (error is FirebaseException && error.code == 'failed-precondition') {
        print("EKSİK INDEX UYARISI! (kullanicininSehirGonderileriniGetir) Firebase konsolunda index oluşturun. Mesaj: ${error.message}");
      }
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    });
  }

  /// Kullanıcının tüm gönderileri (istatistik ve harita için). Sıralama
  /// istemci tarafında yapılır, böylece ek bir Firestore index'i gerekmez.
  Future<List<Gonderi>> kullanicininTumGonderileriniGetir(String kullaniciId) async {
    if (kullaniciId.isEmpty) return [];
    try {
      final snapshot = await _firestore.collection(_gonderilerKoleksiyonu).where('kullaniciId', isEqualTo: kullaniciId).get();
      final Kullanici? yayinlayan = await kullaniciGetir(kullaniciId);
      final gonderiler = snapshot.docs.map((d) => Gonderi.dokumandanUret(d, yayinlayan: yayinlayan)).toList();
      gonderiler.sort((a, b) => b.olusturulmaZamani.compareTo(a.olusturulmaZamani));
      return gonderiler;
    } catch (e) {
      print("FirestoreServisi - kullanicininTumGonderileriniGetir HATA: $e");
      return [];
    }
  }

  Future<List<String>> kullanicininPaylastigiSehirleriGetir(String kullaniciId) async {
    if (kullaniciId.isEmpty) return [];
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(_gonderilerKoleksiyonu)
          .where('kullaniciId', isEqualTo: kullaniciId)
      // .select(['sehir']) // Eğer sadece sehir alanını çekmek istersen ve Firestore destekliyorsa
          .get();
      if (snapshot.docs.isNotEmpty) {
        final Set<String> sehirlerSeti = {};
        for (var doc in snapshot.docs) {
          final String? sehir = doc.data()['sehir'] as String?;
          if (sehir != null && sehir.trim().isNotEmpty) {
            sehirlerSeti.add(sehir.trim());
          }
        }
        List<String> sehirListesi = sehirlerSeti.toList();
        sehirListesi.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return sehirListesi;
      } else {
        return [];
      }
    } catch (e) {
      print("FirestoreServisi - Kullanıcının paylaştığı şehirler getirilirken hata: $e");
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> akisGonderileriniGetir({DocumentSnapshot? sonGorunenGonderi, int limit = 7}) {
    Query<Map<String, dynamic>> sorgu = _firestore.collection(_gonderilerKoleksiyonu).orderBy('olusturulmaZamani', descending: true);
    if (sonGorunenGonderi != null) sorgu = sorgu.startAfterDocument(sonGorunenGonderi);
    sorgu = sorgu.limit(limit);
    return sorgu.snapshots();
  }

  Future<Map<String, dynamic>> gonderileriGetirFiltreleSirala({
    String? aramaMetni, String? kategori, String? ulke, String? sehir, String? konum,
    String siralamaAlani = 'olusturulmaZamani', bool azalan = true,
    int limitSayisi = 7, DocumentSnapshot? sonGorunenDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> sorgu = _firestore.collection(_gonderilerKoleksiyonu);
      if (kategori != null && kategori.isNotEmpty && kategori.toLowerCase() != "tümü") sorgu = sorgu.where('kategori', isEqualTo: kategori);
      if (ulke != null && ulke.isNotEmpty && ulke.toLowerCase() != "tümü") sorgu = sorgu.where('ulke', isEqualTo: ulke);
      if (sehir != null && sehir.isNotEmpty && sehir.toLowerCase() != "tümü") sorgu = sorgu.where('sehir', isEqualTo: sehir);
      if (konum != null && konum.isNotEmpty) sorgu = sorgu.where('konum', isEqualTo: konum);
      sorgu = sorgu.orderBy(siralamaAlani, descending: azalan);
      if (sonGorunenDoc != null) sorgu = sorgu.startAfterDocument(sonGorunenDoc);
      sorgu = sorgu.limit(limitSayisi);
      QuerySnapshot<Map<String, dynamic>> snapshot = await sorgu.get();
      List<Gonderi> gonderilerListesi = [];
      DocumentSnapshot? enSonCekilenDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      for (var doc in snapshot.docs) {
        Kullanici? yayinlayanKullanici;
        final String? kullaniciId = doc.data()['kullaniciId'] as String?;
        if (kullaniciId != null && kullaniciId.isNotEmpty) yayinlayanKullanici = await kullaniciGetir(kullaniciId);
        Gonderi gonderi = Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici);
        if (aramaMetni != null && aramaMetni.trim().isNotEmpty) {
          final String aramaLower = aramaMetni.trim().toLowerCase();
          bool eslesme = (gonderi.aciklama.toLowerCase().contains(aramaLower)) || (gonderi.kategori.toLowerCase().contains(aramaLower)) || (gonderi.konum?.toLowerCase().contains(aramaLower) ?? false) || (gonderi.ulke?.toLowerCase().contains(aramaLower) ?? false) || (gonderi.sehir?.toLowerCase().contains(aramaLower) ?? false) || (gonderi.yayinlayanKullanici?.kullaniciAdi?.toLowerCase().contains(aramaLower) ?? false);
          if (eslesme) gonderilerListesi.add(gonderi);
        } else {
          gonderilerListesi.add(gonderi);
        }
      }
      return {'gonderiler': gonderilerListesi, 'sonDoc': enSonCekilenDoc};
    } on FirebaseException catch (e, s) {
      if (e.code == 'failed-precondition') print("EKSİK INDEX UYARISI! (gonderileriGetirFiltreleSirala) Firebase konsolunda index oluşturun. Mesaj: ${e.message}");
      print("FIRESTORE HATA (gonderileriGetirFiltreleSirala): ${e.code} - ${e.message}\nStack: $s");
      throw Exception("Gönderiler filtrelenirken bir sunucu hatası oluştu: ${e.message}");
    } catch (e, s) {
      print("BEKLENMEDİK HATA (gonderileriGetirFiltreleSirala): $e\nStack: $s");
      throw Exception("Gönderiler filtrelenirken beklenmedik bir hata oluştu: $e");
    }
  }

  Future<void> gonderiSil({required String gonderiId, required String kullaniciId}) async {
    if (gonderiId.isEmpty || kullaniciId.isEmpty) throw ArgumentError("Gönderi ID veya Kullanıcı ID boş olamaz.");
    try {
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).delete();
      DocumentReference kullaniciRef = _firestore.collection(_kullanicilarKoleksiyonu).doc(kullaniciId);
      await kullaniciRef.update({"gonderiSayisi": FieldValue.increment(-1), "guncellenmeZamani": FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw Exception("Gönderi silinirken bir sunucu hatası oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Gönderi silinirken beklenmedik bir hata oluştu.");
    }
  }

  Future<bool> kullaniciGonderiyiBegendiMi({required String gonderiId, required String aktifKullaniciId}) async {
    if (gonderiId.isEmpty || aktifKullaniciId.isEmpty) return false;
    try {
      DocumentSnapshot begeniDoc = await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).collection(_begenilerAltKoleksiyonu).doc(aktifKullaniciId).get();
      return begeniDoc.exists;
    } catch (e) { return false; }
  }

  Future<void> gonderiBegenToggle({required String gonderiId, required String aktifKullaniciId}) async {
    if (gonderiId.isEmpty || aktifKullaniciId.isEmpty) throw ArgumentError("Gönderi ID veya Aktif Kullanıcı ID boş olamaz.");
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference gonderiRef = _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId);
      DocumentReference begeniRef = gonderiRef.collection(_begenilerAltKoleksiyonu).doc(aktifKullaniciId);
      DocumentSnapshot begeniDocSnapshot = await begeniRef.get();
      if (begeniDocSnapshot.exists) {
        batch.update(gonderiRef, {"begeniSayisi": FieldValue.increment(-1)});
        batch.delete(begeniRef);
      } else {
        batch.update(gonderiRef, {"begeniSayisi": FieldValue.increment(1)});
        batch.set(begeniRef, {"begeniZamani": FieldValue.serverTimestamp()});
      }
      await batch.commit();
      if (!begeniDocSnapshot.exists) {
        _gonderiIcinBildirimGonder(gonderiId: gonderiId, yapanId: aktifKullaniciId, tur: Bildirim.turBegeni);
      }
    } on FirebaseException catch (e) {
      throw Exception("Beğeni işlemi güncellenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Beğeni işlemi güncellenirken beklenmedik bir hata oluştu.");
    }
  }

  Future<void> yorumEkle({required String aktifKullaniciId, required String gonderiId, required String yorumMetni, String? ustYorumId}) async {
    if (aktifKullaniciId.isEmpty || gonderiId.isEmpty || yorumMetni.trim().isEmpty) throw ArgumentError("Gerekli alanlar boş olamaz.");
    try {
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).collection(_yorumlarAltKoleksiyonu).add({
        "yorumMetni": yorumMetni.trim(), "kullaniciId": aktifKullaniciId, "olusturulmaZamani": FieldValue.serverTimestamp(),
        "ustYorumId": ustYorumId, "begenenler": <String>[], "begeniSayisi": 0,
      });
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).update({"yorumSayisi": FieldValue.increment(1)});
      _gonderiIcinBildirimGonder(gonderiId: gonderiId, yapanId: aktifKullaniciId, tur: Bildirim.turYorum, metin: yorumMetni.trim());
    } on FirebaseException catch (e) {
      throw Exception("Yorum eklenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Yorum eklenirken beklenmedik bir hata oluştu.");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> yorumlariGetir(String gonderiId) {
    if (gonderiId.isEmpty) return Stream.empty();
    return _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).collection(_yorumlarAltKoleksiyonu).orderBy('olusturulmaZamani', descending: false).snapshots().handleError((error, stackTrace) {
      print("Firestore Stream Hatası (yorumlariGetir): $error \n$stackTrace");
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    });
  }

  Stream<List<DosyaModeli>> tumDosyalariGetir({DocumentSnapshot? sonGorunenDosya, int limit = 12}) {
    Query<Map<String, dynamic>> sorgu = _firestore.collection(_dosyalarKoleksiyonu).orderBy('sonGuncelleme', descending: true);
    if (sonGorunenDosya != null) sorgu = sorgu.startAfterDocument(sonGorunenDosya);
    sorgu = sorgu.limit(limit);
    return sorgu.snapshots().map((snapshot) => snapshot.docs.map((doc) => DosyaModeli.fromFirestore(doc)).toList()).handleError((error, stackTrace) {
      print("Firestore Stream Hatası (tumDosyalariGetir): $error \n$stackTrace");
      return Stream<List<DosyaModeli>>.value(<DosyaModeli>[]);
    });
  }

  Stream<List<Gonderi>> dosyadanGonderileriGetir(String dosyaId, {DocumentSnapshot? sonGorunenGonderi, int limit = 15}) {
    if (dosyaId.isEmpty) return Stream.value(<Gonderi>[]);
    Query<Map<String, dynamic>> sorgu = _firestore.collection(_gonderilerKoleksiyonu).where('aitOlduguDosyaId', isEqualTo: dosyaId).orderBy('olusturulmaZamani', descending: true).limit(limit);
    if (sonGorunenGonderi != null) sorgu = sorgu.startAfterDocument(sonGorunenGonderi);
    return sorgu.snapshots().asyncMap((snapshot) async {
      List<Gonderi> gonderiler = [];
      for (var doc in snapshot.docs) {
        Kullanici? yayinlayanKullanici;
        final String? kullaniciId = doc.data()['kullaniciId'] as String?;
        if (kullaniciId != null && kullaniciId.isNotEmpty) yayinlayanKullanici = await kullaniciGetir(kullaniciId);
        gonderiler.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
      }
      return gonderiler;
    }).handleError((error, stackTrace){
      print("Firestore Stream Hatası (dosyadanGonderileriGetir): $error \n$stackTrace");
      return Stream<List<Gonderi>>.value(<Gonderi>[]);
    });
  }

  Future<List<Gonderi>> takipEdilenlerinGonderileriniGetir({required String aktifKullaniciId, int limit = 20}) async {
    if (aktifKullaniciId.isEmpty) return [];
    try {
      DocumentSnapshot<Map<String, dynamic>> kullaniciDoc = await _firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId).get();
      if (!kullaniciDoc.exists || kullaniciDoc.data() == null) return [];
      final List<String> engellenenler = List<String>.from(kullaniciDoc.data()!['engellenenler'] as List? ?? []);
      List<String> takipEdilenIdListesi = List<String>.from(kullaniciDoc.data()!['takipEdilenler'] as List? ?? [])
        ..removeWhere(engellenenler.contains);
      if (takipEdilenIdListesi.isEmpty) return [];
      List<String> sorgulanacakIdler = takipEdilenIdListesi.take(30).toList();
      if (sorgulanacakIdler.isEmpty) return [];
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore.collection(_gonderilerKoleksiyonu).where('kullaniciId', whereIn: sorgulanacakIdler).orderBy('olusturulmaZamani', descending: true).limit(limit).get();
      List<Gonderi> gonderiler = [];
      for (var doc in querySnapshot.docs) {
        Kullanici? yayinlayanKullanici;
        final String? kullaniciId = doc.data()['kullaniciId'] as String?;
        if (kullaniciId != null && kullaniciId.isNotEmpty) yayinlayanKullanici = await kullaniciGetir(kullaniciId);
        gonderiler.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
      }
      return gonderiler;
    } catch (e, s) {
      print("HATA (takipEdilenlerinGonderileriniGetir): $e \n$s");
      return [];
    }
  }

  // --- GÖNDERİ YARDIMCILARI ---
  Future<Gonderi?> gonderiGetir(String gonderiId) async {
    if (gonderiId.isEmpty) return null;
    try {
      final doc = await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).get();
      if (!doc.exists) return null;
      final String kullaniciId = doc.data()?['kullaniciId'] as String? ?? '';
      final Kullanici? yayinlayan = kullaniciId.isNotEmpty ? await kullaniciGetir(kullaniciId) : null;
      return Gonderi.dokumandanUret(doc, yayinlayan: yayinlayan);
    } catch (e) {
      print("FirestoreServisi - gonderiGetir HATA: $e");
      return null;
    }
  }

  Future<void> gonderiGuncelle({required String gonderiId, required String aciklama}) async {
    if (gonderiId.isEmpty) throw ArgumentError("Gönderi ID'si boş olamaz.");
    try {
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).update({
        "aciklama": aciklama.trim(),
        "guncellenmeZamani": FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception("Gönderi güncellenirken bir hata oluştu: ${e.message}");
    }
  }

  // --- KULLANICI ARAMA ---
  /// Kullanıcı adının başı [metin] ile eşleşen kullanıcıları getirir.
  /// Firestore büyük/küçük harf duyarlı olduğundan hem yazıldığı gibi hem de
  /// ilk harfi büyük hâliyle aranır.
  Future<List<Kullanici>> kullaniciAra(String metin, {int limit = 10}) async {
    final String temiz = metin.trim();
    if (temiz.isEmpty) return [];
    final Set<String> varyantlar = {
      temiz,
      temiz.toLowerCase(),
      temiz[0].toUpperCase() + temiz.substring(1),
      temiz.toUpperCase(),
    };
    final Map<String, Kullanici> sonuclar = {};
    try {
      await Future.wait(varyantlar.map((v) async {
        final snapshot = await _firestore
            .collection(_kullanicilarKoleksiyonu)
            .orderBy('kullaniciAdi')
            .startAt([v])
            .endAt(['$v'])
            .limit(limit)
            .get();
        for (final doc in snapshot.docs) {
          sonuclar[doc.id] = Kullanici.dokumandanUret(doc);
        }
      }));
    } catch (e) {
      print("FirestoreServisi - kullaniciAra HATA: $e");
    }
    return sonuclar.values.take(limit).toList();
  }

  Future<List<Kullanici>> kullanicilariGetir(List<String> idler) async {
    final sonuclar = await Future.wait(idler.where((id) => id.isNotEmpty).map((id) => kullaniciGetir(id)));
    return sonuclar.whereType<Kullanici>().toList();
  }

  // --- TAKİP İŞLEMLERİ ---
  // Veri modeli: kullanicilar/{uid}.takipEdilenler (takip ettiklerim)
  //              kullanicilar/{uid}.takipciler     (beni takip edenler)
  Future<bool> takipEdiyorMu({required String aktifKullaniciId, required String hedefKullaniciId}) async {
    if (aktifKullaniciId.isEmpty || hedefKullaniciId.isEmpty) return false;
    try {
      final doc = await _firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId).get();
      final List takipEdilenler = doc.data()?['takipEdilenler'] as List? ?? [];
      return takipEdilenler.contains(hedefKullaniciId);
    } catch (e) {
      return false;
    }
  }

  Future<void> takipEt({required String aktifKullaniciId, required String hedefKullaniciId}) async {
    if (aktifKullaniciId.isEmpty || hedefKullaniciId.isEmpty || aktifKullaniciId == hedefKullaniciId) return;
    if (await takipEdiyorMu(aktifKullaniciId: aktifKullaniciId, hedefKullaniciId: hedefKullaniciId)) return;
    final batch = _firestore.batch();
    batch.update(_firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId), {
      "takipEdilenler": FieldValue.arrayUnion([hedefKullaniciId]),
      "takipEdilenSayisi": FieldValue.increment(1),
    });
    batch.update(_firestore.collection(_kullanicilarKoleksiyonu).doc(hedefKullaniciId), {
      "takipciler": FieldValue.arrayUnion([aktifKullaniciId]),
      "takipciSayisi": FieldValue.increment(1),
    });
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception("Takip edilirken bir hata oluştu: ${e.message}");
    }
    kullaniciOnbelleginiTemizle(aktifKullaniciId);
    kullaniciOnbelleginiTemizle(hedefKullaniciId);
    bildirimGonder(aliciId: hedefKullaniciId, yapanId: aktifKullaniciId, tur: Bildirim.turTakip);
  }

  Future<void> takibiBirak({required String aktifKullaniciId, required String hedefKullaniciId}) async {
    if (aktifKullaniciId.isEmpty || hedefKullaniciId.isEmpty) return;
    if (!await takipEdiyorMu(aktifKullaniciId: aktifKullaniciId, hedefKullaniciId: hedefKullaniciId)) return;
    final batch = _firestore.batch();
    batch.update(_firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId), {
      "takipEdilenler": FieldValue.arrayRemove([hedefKullaniciId]),
      "takipEdilenSayisi": FieldValue.increment(-1),
    });
    batch.update(_firestore.collection(_kullanicilarKoleksiyonu).doc(hedefKullaniciId), {
      "takipciler": FieldValue.arrayRemove([aktifKullaniciId]),
      "takipciSayisi": FieldValue.increment(-1),
    });
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception("Takipten çıkılırken bir hata oluştu: ${e.message}");
    }
    kullaniciOnbelleginiTemizle(aktifKullaniciId);
    kullaniciOnbelleginiTemizle(hedefKullaniciId);
  }

  /// [takipciler] true ise kullanıcının takipçilerini, false ise takip ettiklerini döndürür.
  Future<List<Kullanici>> takipListesiGetir({required String kullaniciId, required bool takipciler}) async {
    if (kullaniciId.isEmpty) return [];
    try {
      final doc = await _firestore.collection(_kullanicilarKoleksiyonu).doc(kullaniciId).get();
      final List<String> idler = List<String>.from(doc.data()?[takipciler ? 'takipciler' : 'takipEdilenler'] as List? ?? []);
      return kullanicilariGetir(idler);
    } catch (e) {
      print("FirestoreServisi - takipListesiGetir HATA: $e");
      return [];
    }
  }

  // --- KAYDEDİLENLER ---
  Future<bool> gonderiKaydedildiMi({required String aktifKullaniciId, required String gonderiId}) async {
    if (aktifKullaniciId.isEmpty || gonderiId.isEmpty) return false;
    try {
      final doc = await _firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId).collection(_kaydedilenlerAltKoleksiyonu).doc(gonderiId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Gönderiyi kaydeder veya kayıttan çıkarır. Yeni durumu (kaydedildi mi) döndürür.
  Future<bool> gonderiKaydetToggle({required String aktifKullaniciId, required String gonderiId}) async {
    if (aktifKullaniciId.isEmpty || gonderiId.isEmpty) throw ArgumentError("Kullanıcı veya gönderi ID boş olamaz.");
    final ref = _firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId).collection(_kaydedilenlerAltKoleksiyonu).doc(gonderiId);
    try {
      final doc = await ref.get();
      if (doc.exists) {
        await ref.delete();
        return false;
      }
      await ref.set({"kaydedilmeZamani": FieldValue.serverTimestamp()});
      return true;
    } on FirebaseException catch (e) {
      throw Exception("Kaydetme işlemi sırasında bir hata oluştu: ${e.message}");
    }
  }

  Future<List<Gonderi>> kaydedilenGonderileriGetir(String aktifKullaniciId, {int limit = 60}) async {
    if (aktifKullaniciId.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection(_kullanicilarKoleksiyonu)
          .doc(aktifKullaniciId)
          .collection(_kaydedilenlerAltKoleksiyonu)
          .orderBy('kaydedilmeZamani', descending: true)
          .limit(limit)
          .get();
      final gonderiler = await Future.wait(snapshot.docs.map((d) => gonderiGetir(d.id)));
      return gonderiler.whereType<Gonderi>().toList(); // Silinmiş gönderiler atlanır
    } catch (e) {
      print("FirestoreServisi - kaydedilenGonderileriGetir HATA: $e");
      return [];
    }
  }

  // --- ŞİKAYET & ENGELLEME ---
  Future<void> gonderiSikayetEt({required String gonderiId, required String sikayetEdenId, required String sebep}) async {
    try {
      await _firestore.collection(_sikayetlerKoleksiyonu).add({
        "gonderiId": gonderiId,
        "sikayetEdenId": sikayetEdenId,
        "sebep": sebep,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
        "durum": "beklemede",
      });
    } on FirebaseException catch (e) {
      throw Exception("Şikayet gönderilemedi: ${e.message}");
    }
  }

  Future<List<String>> engellenenleriGetir(String aktifKullaniciId) async {
    if (aktifKullaniciId.isEmpty) return [];
    try {
      final doc = await _firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId).get();
      return List<String>.from(doc.data()?['engellenenler'] as List? ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<void> kullaniciEngelle({required String aktifKullaniciId, required String hedefKullaniciId}) async {
    if (aktifKullaniciId.isEmpty || hedefKullaniciId.isEmpty || aktifKullaniciId == hedefKullaniciId) return;
    try {
      await takibiBirak(aktifKullaniciId: aktifKullaniciId, hedefKullaniciId: hedefKullaniciId);
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId).update({
        "engellenenler": FieldValue.arrayUnion([hedefKullaniciId]),
      });
    } on FirebaseException catch (e) {
      throw Exception("Kullanıcı engellenemedi: ${e.message}");
    }
  }

  Future<void> engeliKaldir({required String aktifKullaniciId, required String hedefKullaniciId}) async {
    try {
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(aktifKullaniciId).update({
        "engellenenler": FieldValue.arrayRemove([hedefKullaniciId]),
      });
    } on FirebaseException catch (e) {
      throw Exception("Engel kaldırılamadı: ${e.message}");
    }
  }

  // --- YORUM BEĞENİ ---
  Future<void> yorumBegenToggle({required String gonderiId, required String yorumId, required String aktifKullaniciId}) async {
    final ref = _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).collection(_yorumlarAltKoleksiyonu).doc(yorumId);
    try {
      await _firestore.runTransaction((tx) async {
        final doc = await tx.get(ref);
        final List begenenler = doc.data()?['begenenler'] as List? ?? [];
        if (begenenler.contains(aktifKullaniciId)) {
          tx.update(ref, {"begenenler": FieldValue.arrayRemove([aktifKullaniciId]), "begeniSayisi": FieldValue.increment(-1)});
        } else {
          tx.update(ref, {"begenenler": FieldValue.arrayUnion([aktifKullaniciId]), "begeniSayisi": FieldValue.increment(1)});
        }
      });
    } on FirebaseException catch (e) {
      throw Exception("Yorum beğenilemedi: ${e.message}");
    }
  }

  Future<void> yorumSil({required String gonderiId, required String yorumId}) async {
    try {
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).collection(_yorumlarAltKoleksiyonu).doc(yorumId).delete();
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).update({"yorumSayisi": FieldValue.increment(-1)});
    } on FirebaseException catch (e) {
      throw Exception("Yorum silinemedi: ${e.message}");
    }
  }

  // --- BİLDİRİMLER ---
  /// Bildirim yazma işlemi asıl işlemi (beğeni, yorum, takip) engellememeli;
  /// bu yüzden hatalar yutulur.
  Future<void> bildirimGonder({
    required String aliciId,
    required String yapanId,
    required String tur,
    String? gonderiId,
    String? gonderiResimUrl,
    String? metin,
  }) async {
    if (aliciId.isEmpty || yapanId.isEmpty || aliciId == yapanId) return;
    try {
      final Kullanici? yapan = await kullaniciGetir(yapanId);
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(aliciId).collection(_bildirimlerAltKoleksiyonu).add({
        "tur": tur,
        "yapanId": yapanId,
        "yapanKullaniciAdi": yapan?.kullaniciAdi,
        "yapanFotoUrl": yapan?.fotoUrl,
        "gonderiId": gonderiId,
        "gonderiResimUrl": gonderiResimUrl,
        "metin": metin != null && metin.length > 80 ? "${metin.substring(0, 80)}..." : metin,
        "okundu": false,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("FirestoreServisi - bildirimGonder HATA: $e");
    }
  }

  Future<void> _gonderiIcinBildirimGonder({required String gonderiId, required String yapanId, required String tur, String? metin}) async {
    try {
      final doc = await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).get();
      final data = doc.data();
      if (data == null) return;
      final List resimler = data['resimUrls'] as List? ?? [];
      await bildirimGonder(
        aliciId: data['kullaniciId'] as String? ?? '',
        yapanId: yapanId,
        tur: tur,
        gonderiId: gonderiId,
        gonderiResimUrl: resimler.isNotEmpty ? resimler.first.toString() : null,
        metin: metin,
      );
    } catch (e) {
      print("FirestoreServisi - _gonderiIcinBildirimGonder HATA: $e");
    }
  }

  Stream<List<Bildirim>> bildirimleriGetir(String aktifKullaniciId, {int limit = 50}) {
    if (aktifKullaniciId.isEmpty) return Stream.value(<Bildirim>[]);
    return _firestore
        .collection(_kullanicilarKoleksiyonu)
        .doc(aktifKullaniciId)
        .collection(_bildirimlerAltKoleksiyonu)
        .orderBy('olusturulmaZamani', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Bildirim.dokumandanUret).toList());
  }

  Stream<int> okunmamisBildirimSayisi(String aktifKullaniciId) {
    if (aktifKullaniciId.isEmpty) return Stream.value(0);
    return _firestore
        .collection(_kullanicilarKoleksiyonu)
        .doc(aktifKullaniciId)
        .collection(_bildirimlerAltKoleksiyonu)
        .where('okundu', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size)
        .handleError((_) => 0);
  }

  Future<void> bildirimleriOkunduYap(String aktifKullaniciId) async {
    if (aktifKullaniciId.isEmpty) return;
    try {
      final snap = await _firestore
          .collection(_kullanicilarKoleksiyonu)
          .doc(aktifKullaniciId)
          .collection(_bildirimlerAltKoleksiyonu)
          .where('okundu', isEqualTo: false)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {"okundu": true});
      }
      await batch.commit();
    } catch (e) {
      print("FirestoreServisi - bildirimleriOkunduYap HATA: $e");
    }
  }
}
