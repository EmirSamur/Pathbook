// pathbooks/servisler/firestoreseervisi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelinizin yolu
import 'package:pathbooks/modeller/gonderi.dart';   // Gonderi modelinizin yolu
import 'package:pathbooks/modeller/dosya_modeli.dart'; // DOSYA MODELİNİ İMPORT EDİN

class FirestoreServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _kullanicilarKoleksiyonu = "kullanicilar";
  final String _gonderilerKoleksiyonu = "gonderiler";
  final String _dosyalarKoleksiyonu = "dosyalar";
  final String _begenilerAltKoleksiyonu = "begenenKullanicilar";
  final String _yorumlarAltKoleksiyonu = "yorumlar";

  // --- KULLANICI İŞLEMLERİ --- (Mevcut haliyle kalabilir)
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
      print("Firestore: Kullanıcı belgesi başarıyla oluşturuldu (ID: $id)");
    } on FirebaseException catch (e) {
      print("Firestore Hatası (kullaniciOlustur): ${e.code} - ${e.message}");
      throw Exception("Kullanıcı profili oluşturulamadı: ${e.message}");
    } catch (e) {
      print("Beklenmedik Hata (kullaniciOlustur): $e");
      throw Exception("Kullanıcı profili oluşturulurken beklenmedik bir hata oluştu.");
    }
  }

  Future<Kullanici?> kullaniciGetir(String id) async {
    if (id.isEmpty) {
      print("Firestore Hatası (kullaniciGetir): Kullanıcı ID'si boş olamaz.");
      return null;
    }
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).get();
      if (doc.exists) {
        return Kullanici.dokumandanUret(doc);
      } else {
        print("Firestore: Kullanıcı bulunamadı (ID: $id)");
        return null;
      }
    } on FirebaseException catch (e) {
      print("Firestore Hatası (kullaniciGetir): ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Beklenmedik Hata (kullaniciGetir): $e");
      return null;
    }
  }

  Future<void> kullaniciGuncelle({
    required String id,
    required Map<String, dynamic> veri,
  }) async {
    if (id.isEmpty) {
      print("Firestore Hatası (kullaniciGuncelle): Kullanıcı ID'si boş olamaz.");
      throw ArgumentError("Kullanıcı ID'si boş olamaz.");
    }
    try {
      Map<String, dynamic> guncellenecekVeri = Map.from(veri);
      guncellenecekVeri['guncellenmeZamani'] = FieldValue.serverTimestamp();
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).update(guncellenecekVeri);
      print("Firestore: Kullanıcı belgesi güncellendi (ID: $id)");
    } on FirebaseException catch (e) {
      print("Firestore Hatası (kullaniciGuncelle): ${e.code} - ${e.message}");
      throw Exception("Kullanıcı bilgileri güncellenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      print("Beklenmedik Hata (kullaniciGuncelle): $e");
      throw Exception("Kullanıcı bilgileri güncellenirken beklenmedik bir hata oluştu.");
    }
  }


  // --- GÖNDERİ İŞLEMLERİ ---

  Future<void> gonderiOlustur({
    required String yayinlayanId,
    // required String gonderiResmiUrl, // ESKİ: Tek resim URL'i
    required List<String> gonderiResmiUrls, // YENİ: Resim URL listesi
    required String aciklama,
    required String kategori, // YENİ: Kategori bilgisi
    String? konum,
  }) async {
    if (yayinlayanId.isEmpty) {
      print("Firestore Hatası (gonderiOlustur): Yayınlayan ID'si boş olamaz.");
      throw ArgumentError("Yayınlayan ID'si boş olamaz.");
    }
    if (gonderiResmiUrls.isEmpty) {
      print("Firestore Hatası (gonderiOlustur): Gönderi resmi URL listesi boş olamaz.");
      throw ArgumentError("Gönderi resmi URL listesi boş olamaz.");
    }
    if (kategori.isEmpty) {
      print("Firestore Hatası (gonderiOlustur): Kategori boş olamaz.");
      throw ArgumentError("Kategori boş olamaz.");
    }

    try {
      await _firestore.collection(_gonderilerKoleksiyonu).add({
        "kullaniciId": yayinlayanId,
        // "resimUrl": gonderiResmiUrl, // ESKİ
        "resimUrls": gonderiResmiUrls, // YENİ
        "aciklama": aciklama,
        "konum": konum ?? "",
        "kategori": kategori, // YENİ
        "begeniSayisi": 0,
        "yorumSayisi": 0,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
      });
      print("Firestore: Gönderi başarıyla oluşturuldu (Resimler: ${gonderiResmiUrls.length}, Kategori: $kategori).");

      DocumentReference kullaniciRef = _firestore.collection(_kullanicilarKoleksiyonu).doc(yayinlayanId);
      await kullaniciRef.update({
        "gonderiSayisi": FieldValue.increment(1),
        "guncellenmeZamani": FieldValue.serverTimestamp(),
      });
      print("Firestore: Kullanıcının gönderi sayısı artırıldı.");

    } on FirebaseException catch (e) {
      print("Firestore Hatası (gonderiOlustur): ${e.code} - ${e.message}");
      throw Exception("Gönderi oluşturulurken bir hata oluştu: ${e.message}");
    } catch (e) {
      print("Beklenmedik Hata (gonderiOlustur): $e");
      throw Exception("Gönderi oluşturulurken beklenmedik bir hata oluştu.");
    }
  }

  // --- Diğer metodlar (kullaniciGonderileriniGetir, tumGonderileriGetir vb.) ---
  // Bu metodları da yeni `resimUrls` ve `kategori` alanlarını kullanacak şekilde
  // Gonderi modelinizle uyumlu olarak güncellemeniz gerekecektir.
  // Özellikle `Gonderi.dokumandanUret` metodunun bu yeni alanları işlemesi önemlidir.
  // Örnek olarak tumGonderileriGetir'i bırakıyorum, ancak Gonderi modelinin
  // `List<String> resimUrls` ve `String kategori` alanlarını beklediğini varsayıyorum.

  Stream<QuerySnapshot<Map<String, dynamic>>> kullaniciGonderileriniGetir(String kullaniciId) {
    if (kullaniciId.isEmpty) {
      print("Firestore Hatası (kullaniciGonderileriniGetir): Kullanıcı ID'si boş olamaz.");
      return Stream.empty();
    }
    // Kategoriye göre filtreleme eklemek isterseniz buraya .where('kategori', isEqualTo: 'Doğa') gibi eklemeler yapabilirsiniz.
    return _firestore
        .collection(_gonderilerKoleksiyonu)
        .where('kullaniciId', isEqualTo: kullaniciId)
        .orderBy('olusturulmaZamani', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tumGonderileriGetir({DocumentSnapshot? sonGorunenGonderi, int limit = 10}) {
    Query<Map<String, dynamic>> sorgu = _firestore
        .collection(_gonderilerKoleksiyonu)
        .orderBy('olusturulmaZamani', descending: true)
        .limit(limit);

    if (sonGorunenGonderi != null) {
      sorgu = sorgu.startAfterDocument(sonGorunenGonderi);
    }
    // Bu sorgu tüm gönderileri getirir. Anasayfada veya arama sonuçlarında
    // Gonderi modelinizin `resimUrls` listesinden örneğin ilk resmi göstermeyi
    // veya bir carousel ile tüm resimleri göstermeyi tercih edebilirsiniz.
    // Kategoriye göre filtreleme için ARA sayfasında bu sorguya .where clause eklenecektir.
    return sorgu.snapshots();
  }

  // --- BEĞENİ İŞLEMLERİ --- (Mevcut haliyle kalabilir)
  Future<bool> kullaniciGonderiyiBegendiMi({
    required String gonderiId,
    required String aktifKullaniciId,
  }) async {
    if (gonderiId.isEmpty || aktifKullaniciId.isEmpty) return false;
    try {
      DocumentSnapshot begeniDoc = await _firestore
          .collection(_gonderilerKoleksiyonu)
          .doc(gonderiId)
          .collection(_begenilerAltKoleksiyonu)
          .doc(aktifKullaniciId)
          .get();
      return begeniDoc.exists;
    } catch (e) {
      print("Firestore Hatası (kullaniciGonderiyiBegendiMi): $e");
      return false;
    }
  }

  Future<void> gonderiBegenToggle({
    required String gonderiId,
    required String aktifKullaniciId,
  }) async {
    if (gonderiId.isEmpty || aktifKullaniciId.isEmpty) {
      throw ArgumentError("Gönderi ID'si veya Aktif Kullanıcı ID'si boş olamaz.");
    }
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference gonderiRef = _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId);
      DocumentReference begeniRef = gonderiRef.collection(_begenilerAltKoleksiyonu).doc(aktifKullaniciId);

      DocumentSnapshot begeniDocSnapshot = await begeniRef.get();

      if (begeniDocSnapshot.exists) {
        batch.update(gonderiRef, {"begeniSayisi": FieldValue.increment(-1)});
        batch.delete(begeniRef);
        print("Firestore: Beğeni geri alındı. Gönderi: $gonderiId, Kullanıcı: $aktifKullaniciId");
      } else {
        batch.update(gonderiRef, {"begeniSayisi": FieldValue.increment(1)});
        batch.set(begeniRef, {"begeniZamani": FieldValue.serverTimestamp()});
        print("Firestore: Gönderi beğenildi. Gönderi: $gonderiId, Kullanıcı: $aktifKullaniciId");
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      print("Firestore Hatası (gonderiBegenToggle): ${e.code} - ${e.message}");
      throw Exception("Beğeni işlemi güncellenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      print("Beklenmedik Hata (gonderiBegenToggle): $e");
      throw Exception("Beğeni işlemi güncellenirken beklenmedik bir hata oluştu.");
    }
  }

  // --- YORUM İŞLEMLERİ --- (Mevcut haliyle kalabilir)
  Future<void> yorumEkle({
    required String aktifKullaniciId,
    required String gonderiId,
    required String yorumMetni,
  }) async {
    if (aktifKullaniciId.isEmpty || gonderiId.isEmpty || yorumMetni.trim().isEmpty) {
      throw ArgumentError("Kullanıcı ID, Gönderi ID veya Yorum metni boş olamaz.");
    }
    try {
      DocumentReference yorumRef = _firestore
          .collection(_gonderilerKoleksiyonu)
          .doc(gonderiId)
          .collection(_yorumlarAltKoleksiyonu)
          .doc();

      await yorumRef.set({
        "yorumMetni": yorumMetni.trim(),
        "kullaniciId": aktifKullaniciId,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
      });

      DocumentReference gonderiRef = _firestore.collection(_gonderilerKoleksiyonu).doc(gonderiId);
      await gonderiRef.update({"yorumSayisi": FieldValue.increment(1)});
      print("Firestore: Yorum başarıyla eklendi. Gönderi: $gonderiId");
    } on FirebaseException catch (e) {
      print("Firestore Hatası (yorumEkle): ${e.code} - ${e.message}");
      throw Exception("Yorum eklenirken bir hata oluştu: ${e.message}");
    } catch (e) {
      print("Beklenmedik Hata (yorumEkle): $e");
      throw Exception("Yorum eklenirken beklenmedik bir hata oluştu.");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> yorumlariGetir(String gonderiId) {
    if (gonderiId.isEmpty) {
      print("Firestore Hatası (yorumlariGetir): Gönderi ID'si boş olamaz.");
      return Stream.empty();
    }
    return _firestore
        .collection(_gonderilerKoleksiyonu)
        .doc(gonderiId)
        .collection(_yorumlarAltKoleksiyonu)
        .orderBy('olusturulmaZamani', descending: false)
        .snapshots()
        .handleError((error) {
      print("Firestore Stream Hatası (yorumlariGetir): $error");
      return Stream.empty();
    });
  }


  // --- DOSYA (PANO) İŞLEMLERİ --- (Mevcut haliyle kalabilir, bu istekle doğrudan ilgili değil)
  Stream<List<DosyaModeli>> tumDosyalariGetir({DocumentSnapshot? sonGorunenDosya, int limit = 12}) {
    Query<Map<String, dynamic>> sorgu = _firestore
        .collection(_dosyalarKoleksiyonu)
        .orderBy('sonGuncelleme', descending: true);

    if (sonGorunenDosya != null) {
      sorgu = sorgu.startAfterDocument(sonGorunenDosya);
    }
    sorgu = sorgu.limit(limit);

    return sorgu.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <DosyaModeli>[];
      }
      return snapshot.docs.map((doc) => DosyaModeli.fromFirestore(doc)).toList();
    }).handleError((error) {
      print("Firestore Stream Hatası (tumDosyalariGetir): $error");
      return <DosyaModeli>[];
    });
  }

  Stream<List<Gonderi>> dosyadanGonderileriGetir(String dosyaId, {DocumentSnapshot? sonGorunenGonderi, int limit = 15}) {
    if (dosyaId.isEmpty) {
      print("Firestore Hatası (dosyadanGonderileriGetir): Dosya ID'si boş olamaz.");
      return Stream.value([]);
    }
    Query<Map<String, dynamic>> sorgu = _firestore
        .collection(_gonderilerKoleksiyonu)
        .where('aitOlduguDosyaId', isEqualTo: dosyaId)
        .orderBy('olusturulmaZamani', descending: true)
        .limit(limit);

    if (sonGorunenGonderi != null) {
      sorgu = sorgu.startAfterDocument(sonGorunenGonderi);
    }

    return sorgu.snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return <Gonderi>[];
      List<Gonderi> gonderiler = [];
      for (var doc in snapshot.docs) {
        Kullanici? yayinlayanKullanici;
        final String? kullaniciId = doc.data()['kullaniciId'] as String?;
        if (kullaniciId != null && kullaniciId.isNotEmpty) {
          yayinlayanKullanici = await kullaniciGetir(kullaniciId);
        }
        // Gonderi.dokumandanUret metodunuzun da güncellenmiş Firestore yapısını
        // (resimUrls, kategori) desteklediğinden emin olun.
        gonderiler.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
      }
      return gonderiler;
    }).handleError((error){
      print("Firestore Stream Hatası (dosyadanGonderileriGetir): $error");
      return <Gonderi>[];
    });
  }
}