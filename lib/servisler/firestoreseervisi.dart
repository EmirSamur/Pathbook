// pathbooks/servisler/firestoreseervisi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelinizin yolu
import 'package:pathbooks/modeller/gonderi.dart';   // Gonderi modelinizin yolu
import 'package:pathbooks/modeller/dosya_modeli.dart'; // DOSYA MODELİNİ İMPORT EDİN

class FirestoreServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _kullanicilarKoleksiyonu = "kullanicilar";
  final String _gonderilerKoleksiyonu = "gonderiler";
  final String _dosyalarKoleksiyonu = "dosyalar"; // Dosyalar/Panolar için koleksiyon adı
  final String _begenilerAltKoleksiyonu = "begenenKullanicilar";
  final String _yorumlarAltKoleksiyonu = "yorumlar";

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
        // Kullanici modelinizin dokumandanUret metodunun Map<String, dynamic> aldığından emin olun
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
    required String gonderiResmiUrl,
    required String aciklama,
    String? konum,
  }) async {
    if (yayinlayanId.isEmpty) {
      print("Firestore Hatası (gonderiOlustur): Yayınlayan ID'si boş olamaz.");
      throw ArgumentError("Yayınlayan ID'si boş olamaz.");
    }
    try {
      await _firestore.collection(_gonderilerKoleksiyonu).add({
        "kullaniciId": yayinlayanId,
        "resimUrl": gonderiResmiUrl,
        "aciklama": aciklama,
        "konum": konum ?? "",
        "begeniSayisi": 0,
        "yorumSayisi": 0,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
      });
      print("Firestore: Gönderi başarıyla oluşturuldu.");

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

  Stream<QuerySnapshot<Map<String, dynamic>>> kullaniciGonderileriniGetir(String kullaniciId) {
    if (kullaniciId.isEmpty) {
      print("Firestore Hatası (kullaniciGonderileriniGetir): Kullanıcı ID'si boş olamaz.");
      return Stream.empty();
    }
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
    return sorgu.snapshots();
  }

  // --- BEĞENİ İŞLEMLERİ ---

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

  // --- YORUM İŞLEMLERİ ---

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

  // --- YENİ: DOSYA (PANO) İŞLEMLERİ ---
  Stream<List<DosyaModeli>> tumDosyalariGetir({DocumentSnapshot? sonGorunenDosya, int limit = 12}) {
    // Firestore'daki koleksiyon adınızın '_dosyalarKoleksiyonu' ile eşleştiğinden emin olun.
    Query<Map<String, dynamic>> sorgu = _firestore
        .collection(_dosyalarKoleksiyonu) // Değişkeni kullan
        .orderBy('sonGuncelleme', descending: true); // Örnek sıralama

    if (sonGorunenDosya != null) {
      sorgu = sorgu.startAfterDocument(sonGorunenDosya);
    }

    sorgu = sorgu.limit(limit);

    return sorgu.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print("Firestore (tumDosyalariGetir): Hiç dosya bulunamadı.");
        return <DosyaModeli>[]; // Boş liste döndür
      }
      print("Firestore (tumDosyalariGetir): ${snapshot.docs.length} adet dosya getirildi.");
      return snapshot.docs.map((doc) {
        return DosyaModeli.fromFirestore(doc); // doc zaten DocumentSnapshot<Map<String, dynamic>> tipinde olmalı
      }).toList();
    }).handleError((error) {
      print("Firestore Stream Hatası (tumDosyalariGetir): $error");
      return <DosyaModeli>[]; // Hata durumunda boş liste döndür
    });
  }

  // TODO: Belirli bir dosyaya ait gönderileri getirme metodu (dosya_detay_sayfasi.dart için)
  // Bu metod, Firestore'daki veri yapınıza göre (gönderilerin dosyalara nasıl bağlandığına göre)
  // dikkatlice tasarlanmalıdır.
  Stream<List<Gonderi>> dosyadanGonderileriGetir(String dosyaId, {DocumentSnapshot? sonGorunenGonderi, int limit = 15}) {
    if (dosyaId.isEmpty) {
      print("Firestore Hatası (dosyadanGonderileriGetir): Dosya ID'si boş olamaz.");
      return Stream.value([]); // Veya Stream.empty()
    }
    print("Firestore (dosyadanGonderileriGetir): $dosyaId için gönderiler getiriliyor...");

    // ÖRNEK 1: Gönderi dökümanlarında 'aitOlduguDosyaId' gibi bir alan varsa:
    Query<Map<String, dynamic>> sorgu = _firestore
        .collection(_gonderilerKoleksiyonu)
        .where('aitOlduguDosyaId', isEqualTo: dosyaId) // BU ALAN ADI SİZİN YAPINIZA UYGUN OLMALI
        .orderBy('olusturulmaZamani', descending: true)
        .limit(limit);

    // ÖRNEK 2: Gönderi dökümanlarında 'dosyalar' diye bir array varsa ve dosyaId'yi içeriyorsa:
    // Query<Map<String, dynamic>> sorgu = _firestore
    //     .collection(_gonderilerKoleksiyonu)
    //     .where('dosyalar', arrayContains: dosyaId) // BU ALAN ADI SİZİN YAPINIZA UYGUN OLMALI
    //     .orderBy('olusturulmaZamani', descending: true)
    //     .limit(limit);


    if (sonGorunenGonderi != null) {
      sorgu = sorgu.startAfterDocument(sonGorunenGonderi);
    }

    return sorgu.snapshots().asyncMap((snapshot) async { // asyncMap kullanımı
      if (snapshot.docs.isEmpty) {
        return <Gonderi>[];
      }
      // Gönderileri Gonderi modeline dönüştürürken yayınlayan kullanıcı bilgisini de çekiyoruz.
      List<Gonderi> gonderiler = [];
      for (var doc in snapshot.docs) {
        Kullanici? yayinlayanKullanici;
        final String? kullaniciId = doc.data()['kullaniciId'] as String?;
        if (kullaniciId != null && kullaniciId.isNotEmpty) {
          yayinlayanKullanici = await kullaniciGetir(kullaniciId); // Mevcut kullaniciGetir metodunu kullan
        }
        gonderiler.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
      }
      return gonderiler;
    }).handleError((error){
      print("Firestore Stream Hatası (dosyadanGonderileriGetir): $error");
      return <Gonderi>[];
    });
  }

}