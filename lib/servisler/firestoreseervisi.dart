// pathbooks/servisler/firestore_servisi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/dosya_modeli.dart';
import 'package:pathbooks/modeller/oneri_modeli.dart';

class FirestoreServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _kullanicilarKoleksiyonu = "kullanicilar";
  final String _gonderilerKoleksiyonu = "gonderiler";
  final String _dosyalarKoleksiyonu = "dosyalar";
  final String _begenilerAltKoleksiyonu = "begenenKullanicilar";
  final String _yorumlarAltKoleksiyonu = "yorumlar";
  final String _onerilerKoleksiyonu = "oneriler";

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
      });
      print("Firestore: Kullanıcı belgesi oluşturuldu (ID: $id)");
    } on FirebaseException catch (e) {
      print("Firestore Hatası (kullaniciOlustur): Kod: ${e.code}, Mesaj: ${e.message}");
      throw Exception("Kullanıcı profili oluşturulamadı: ${e.message}");
    } catch (e) {
      print("Beklenmedik Hata (kullaniciOlustur): $e");
      throw Exception("Kullanıcı profili oluşturulurken beklenmedik bir hata oluştu.");
    }
  }

  Future<Kullanici?> kullaniciGetir(String id) async {
    if (id.isEmpty) {
      print("Firestore Hatası (kullaniciGetir): Kullanıcı ID'si boş.");
      return null;
    }
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).get();
      if (doc.exists) {
        return Kullanici.dokumandanUret(doc);
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
    if (id.isEmpty) {
      throw ArgumentError("Kullanıcı ID'si boş olamaz.");
    }
    try {
      Map<String, dynamic> guncellenecekVeri = Map.from(veri);
      guncellenecekVeri['guncellenmeZamani'] = FieldValue.serverTimestamp();
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).update(guncellenecekVeri);
    } on FirebaseException catch (e) {
      throw Exception("Kullanıcı bilgileri güncellenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Kullanıcı bilgileri güncellenirken beklenmedik bir hata oluştu.");
    }
  }

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
        "kullaniciId": yayinlayanId,
        "resimUrls": gonderiResmiUrls,
        "aciklama": aciklama.trim(),
        "konum": konum?.trim().isNotEmpty == true ? konum!.trim() : null,
        "kategori": kategori,
        "begeniSayisi": 0,
        "yorumSayisi": 0,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
      };
      if (ulke != null && ulke.trim().isNotEmpty) gonderiVerisi['ulke'] = ulke.trim();
      if (sehir != null && sehir.trim().isNotEmpty) gonderiVerisi['sehir'] = sehir.trim();
      await _firestore.collection(_gonderilerKoleksiyonu).add(gonderiVerisi);
      DocumentReference kullaniciRef = _firestore.collection(_kullanicilarKoleksiyonu).doc(yayinlayanId);
      await kullaniciRef.update({
        "gonderiSayisi": FieldValue.increment(1),
        "guncellenmeZamani": FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception("Gönderi oluşturulurken bir sunucu hatası oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Gönderi oluşturulurken beklenmedik bir hata oluştu.");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> kullaniciGonderileriniGetir(String kullaniciId) {
    if (kullaniciId.isEmpty) return Stream.empty();
    return _firestore
        .collection(_gonderilerKoleksiyonu)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .orderBy('olusturulmaZamani', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> akisGonderileriniGetir({
    DocumentSnapshot? sonGorunenGonderi,
    int limit = 7,
  }) {
    Query<Map<String, dynamic>> sorgu = _firestore
        .collection(_gonderilerKoleksiyonu)
        .orderBy('olusturulmaZamani', descending: true);
    if (sonGorunenGonderi != null) sorgu = sorgu.startAfterDocument(sonGorunenGonderi);
    sorgu = sorgu.limit(limit);
    return sorgu.snapshots();
  }

  Future<Map<String, dynamic>> gonderileriGetirFiltreleSirala({
    String? aramaMetni,
    String? kategori,
    String? ulke,
    String? sehir,
    String siralamaAlani = 'olusturulmaZamani',
    bool azalan = true,
    int limitSayisi = 7,
    DocumentSnapshot? sonGorunenDoc,
  }) async {
    print("FirestoreServisi: gonderileriGetirFiltreleSirala -> Kategori: $kategori, Ülke: $ulke, Şehir: $sehir, Arama: '$aramaMetni', Sıralama: $siralamaAlani ($azalan)");
    try {
      Query<Map<String, dynamic>> sorgu = _firestore.collection(_gonderilerKoleksiyonu);

      if (kategori != null && kategori.isNotEmpty && kategori.toLowerCase() != "tümü") {
        sorgu = sorgu.where('kategori', isEqualTo: kategori);
      }
      if (ulke != null && ulke.isNotEmpty && ulke.toLowerCase() != "tümü") {
        sorgu = sorgu.where('ulke', isEqualTo: ulke);
      }
      if (sehir != null && sehir.isNotEmpty && sehir.toLowerCase() != "tümü") {
        sorgu = sorgu.where('sehir', isEqualTo: sehir);
      }

      sorgu = sorgu.orderBy(siralamaAlani, descending: azalan);
      if (sonGorunenDoc != null) sorgu = sorgu.startAfterDocument(sonGorunenDoc);
      sorgu = sorgu.limit(limitSayisi);

      QuerySnapshot<Map<String, dynamic>> snapshot = await sorgu.get();
      List<Gonderi> gonderilerListesi = [];
      DocumentSnapshot? enSonCekilenDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      for (var doc in snapshot.docs) {
        Kullanici? yayinlayanKullanici;
        final String? kullaniciId = doc.data()['kullaniciId'] as String?;
        if (kullaniciId != null && kullaniciId.isNotEmpty) {
          yayinlayanKullanici = await kullaniciGetir(kullaniciId);
        }
        Gonderi gonderi = Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici);

        if (aramaMetni != null && aramaMetni.trim().isNotEmpty) {
          final String aramaLower = aramaMetni.trim().toLowerCase();
          bool eslesme = (gonderi.aciklama.toLowerCase().contains(aramaLower)) ||
              (gonderi.kategori.toLowerCase().contains(aramaLower)) ||
              (gonderi.konum?.toLowerCase().contains(aramaLower) ?? false) ||
              (gonderi.ulke?.toLowerCase().contains(aramaLower) ?? false) ||
              (gonderi.sehir?.toLowerCase().contains(aramaLower) ?? false) ||
              (gonderi.yayinlayanKullanici?.kullaniciAdi?.toLowerCase().contains(aramaLower) ?? false);
          if (eslesme) gonderilerListesi.add(gonderi);
        } else {
          gonderilerListesi.add(gonderi);
        }
      }
      return {'gonderiler': gonderilerListesi, 'sonDoc': enSonCekilenDoc};
    } on FirebaseException catch (e, s) {
      print("FIRESTORE HATA (gonderileriGetirFiltreleSirala): ${e.code} - ${e.message}");
      if (e.code == 'failed-precondition') {
        print("EKSİK INDEX UYARISI! Lütfen Firebase konsolunda belirtilen linke giderek index oluşturun. Mesaj: ${e.message}");
      }
      print("Stack Trace: \n$s");
      throw Exception("Gönderiler filtrelenirken bir sunucu hatası oluştu: ${e.message}");
    } catch (e, s) {
      print("BEKLENMEDİK HATA (gonderileriGetirFiltreleSirala): $e\nStack Trace: \n$s");
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
    } catch (e) {
      return false;
    }
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
    } on FirebaseException catch (e) {
      throw Exception("Beğeni işlemi güncellenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      throw Exception("Beğeni işlemi güncellenirken beklenmedik bir hata oluştu.");
    }
  }

  Future<void> yorumEkle({required String aktifKullaniciId, required String gonderiId, required String yorumMetni}) async {
    if (aktifKullaniciId.isEmpty || gonderiId.isEmpty || yorumMetni.trim().isEmpty) throw ArgumentError("Gerekli alanlar boş olamaz.");
    try {
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).collection(_yorumlarAltKoleksiyonu).add({"yorumMetni": yorumMetni.trim(), "kullaniciId": aktifKullaniciId, "olusturulmaZamani": FieldValue.serverTimestamp()});
      await _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId).update({"yorumSayisi": FieldValue.increment(1)});
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
    return sorgu.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DosyaModeli.fromFirestore(doc)).toList();
    }).handleError((error, stackTrace) {
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
      List<String> takipEdilenIdListesi = List<String>.from(kullaniciDoc.data()!['takipEdilenler'] as List? ?? []);
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
}