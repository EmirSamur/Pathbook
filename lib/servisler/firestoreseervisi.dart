// pathbooks/servisler/firestoreseervisi.dart
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
    print("FirestoreServisi (kullaniciGetir): Kullanıcı $id getiriliyor...");
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection(_kullanicilarKoleksiyonu).doc(id).get();
      if (doc.exists) {
        print("FirestoreServisi (kullaniciGetir): Kullanıcı $id bulundu.");
        return Kullanici.dokumandanUret(doc);
      } else {
        print("FirestoreServisi (kullaniciGetir): Kullanıcı $id bulunamadı.");
        return null;
      }
    } on FirebaseException catch (e) {
      print("Firestore Hatası (kullaniciGetir ID: $id): ${e.code} - ${e.message}");
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
        print("FirestoreServisi: ${onerilerListesi.length} adet öneri başarıyla çekildi.");
      } else {
        print("FirestoreServisi: 'oneriler' koleksiyonunda hiç belge bulunamadı.");
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


  Future<void> gonderiOlustur({
    required String yayinlayanId,
    required List<String> gonderiResmiUrls,
    required String aciklama,
    required String kategori,
    String? konum,
  }) async {
    if (yayinlayanId.isEmpty) throw ArgumentError("Yayınlayan ID'si boş olamaz.");
    if (gonderiResmiUrls.isEmpty) throw ArgumentError("Gönderi resmi URL listesi boş olamaz.");
    if (kategori.isEmpty) throw ArgumentError("Kategori boş olamaz.");

    try {
      await _firestore.collection(_gonderilerKoleksiyonu).add({
        "kullaniciId": yayinlayanId,
        "resimUrls": gonderiResmiUrls,
        "aciklama": aciklama,
        "konum": konum ?? "",
        "kategori": kategori,
        "begeniSayisi": 0,
        "yorumSayisi": 0,
        "olusturulmaZamani": FieldValue.serverTimestamp(),
      });
      print("Firestore: Gönderi oluşturuldu (Kategori: $kategori).");

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
    if (kullaniciId.isEmpty) return Stream.empty();
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
    if (gonderiId.isEmpty) return Stream.empty();
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
    if (dosyaId.isEmpty) return Stream.value([]);
    Query<Map<String, dynamic>> sorgu = _firestore
        .collection(_gonderilerKoleksiyonu)
        .where('aitOlduguDosyaId', isEqualTo: dosyaId) // Bu alanın Gonderi modelinde ve Firestore'da olduğundan emin olun
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
        gonderiler.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
      }
      return gonderiler;
    }).handleError((error){
      print("Firestore Stream Hatası (dosyadanGonderileriGetir): $error");
      return <Gonderi>[];
    });
  }


  // YENİ GÜNCELLENMİŞ METOD: Gönderileri temaya ve sıralamaya göre getirme
  // Hem gönderi listesini hem de son dokümanı döndürecek.
  Future<Map<String, dynamic>> gonderileriGetirFiltreleSirala({
    required String tema,
    String siralamaAlani = 'olusturulmaZamani',
    bool azalan = true,
    int limitSayisi = 10, // ara.dart ile uyumlu olması için 10 yapıldı
    DocumentSnapshot? sonGorunenDoc,
  }) async {
    print("FirestoreServisi: gonderileriGetirFiltreleSirala çağrıldı. Tema: $tema, Sıralama: $siralamaAlani ($azalan), Limit: $limitSayisi, SonDoc: ${sonGorunenDoc?.id}");
    try {
      if (tema.isEmpty) {
        print("FirestoreServisi: Tema boş, boş sonuç döndürülüyor.");
        return {'gonderiler': <Gonderi>[], 'sonDoc': null};
      }

      Query<Map<String, dynamic>> sorgu = _firestore
          .collection(_gonderilerKoleksiyonu)
          .where('kategori', isEqualTo: tema);
      print("FirestoreServisi: `.where('kategori', isEqualTo: '$tema')` uygulandı.");

      sorgu = sorgu.orderBy(siralamaAlani, descending: azalan);
      print("FirestoreServisi: `.orderBy('$siralamaAlani', descending: $azalan)` uygulandı.");

      if (sonGorunenDoc != null) {
        sorgu = sorgu.startAfterDocument(sonGorunenDoc);
        print("FirestoreServisi: `.startAfterDocument(${sonGorunenDoc.id})` uygulandı.");
      }

      // Limiti startAfterDocument'tan SONRA uygulamak daha doğru, özellikle count ile birleştirildiğinde.
      // Ancak burada ayrı bir count sorgusu yok, direkt limitli get yapıyoruz.
      sorgu = sorgu.limit(limitSayisi);
      print("FirestoreServisi: `.limit($limitSayisi)` uygulandı.");


      print("FirestoreServisi: Sorgu Firestore'a gönderiliyor...");
      QuerySnapshot<Map<String, dynamic>> snapshot = await sorgu.get();
      print("FirestoreServisi: Sorgu sonucu alındı. ${snapshot.docs.length} doküman bulundu.");

      List<Gonderi> gonderilerListesi = [];
      DocumentSnapshot? enSonCekilenDoc;

      if (snapshot.docs.isNotEmpty) {
        enSonCekilenDoc = snapshot.docs.last; // Bir sonraki sayfalama için son dokümanı sakla
        for (var i = 0; i < snapshot.docs.length; i++) {
          var doc = snapshot.docs[i];
          print("FirestoreServisi: Doküman ${doc.id} işleniyor (${i+1}/${snapshot.docs.length})...");
          final data = doc.data();
          Kullanici? yayinlayanKullanici;
          final String? kullaniciId = data['kullaniciId'] as String?; // Gonderi modeline göre kontrol et
          if (kullaniciId != null && kullaniciId.isNotEmpty) {
            print("FirestoreServisi: Kullanıcı getiriliyor (ID: $kullaniciId)...");
            yayinlayanKullanici = await kullaniciGetir(kullaniciId);
            print("FirestoreServisi: Kullanıcı ${yayinlayanKullanici?.kullaniciAdi ?? 'bulunamadı'} (ID: $kullaniciId) getirildi.");
          } else {
            print("FirestoreServisi: Doküman ${doc.id} için kullaniciId bulunamadı veya boş.");
          }
          print("FirestoreServisi: Gonderi.dokumandanUret çağrılacak. Doküman ID: ${doc.id}, Veri: $data");
          gonderilerListesi.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
          print("FirestoreServisi: Doküman ${doc.id} Gonderi nesnesine dönüştürüldü.");
        }
      } else {
        print("FirestoreServisi: '$tema' temasında ($siralamaAlani) bu sayfada gönderi bulunamadı (snapshot boş).");
      }

      print("FirestoreServisi: '$tema' temasında ${gonderilerListesi.length} gönderi başarıyla işlendi. Son doküman ID: ${enSonCekilenDoc?.id}");
      return {'gonderiler': gonderilerListesi, 'sonDoc': enSonCekilenDoc};

    } on FirebaseException catch (e, s) {
      print("====== FIRESTORE SERVİSİ - FIREBASE HATASI (gonderileriGetirFiltreleSirala) ======");
      print("TEMA: $tema, SIRALAMA: $siralamaAlani");
      print("HATA KODU: ${e.code}");
      print("HATA MESAJI: ${e.message}");
      print("STACK TRACE (FirebaseException): \n$s");
      print("================================================");
      throw Exception("Gönderiler getirilirken bir sunucu hatası oluştu: ${e.message}");
    } catch (e, s) {
      print("====== FIRESTORE SERVİSİ - BEKLENMEDİK HATA (gonderileriGetirFiltreleSirala) ======");
      print("TEMA: $tema, SIRALAMA: $siralamaAlani");
      print("HATA TİPİ: ${e.runtimeType}");
      print("HATA MESAJI: $e");
      print("STACK TRACE (Beklenmedik): \n$s");
      print("================================================");
      throw Exception("Gönderiler getirilirken beklenmedik bir hata oluştu: $e");
    }
  }
}