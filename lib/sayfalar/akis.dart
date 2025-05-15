// lib/sayfalar/akis.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// GonderiKarti widget'ının doğru import edildiğinden emin olalım
import 'package:pathbooks/widgets/gonderi_karti.dart'; // Eğer GonderiKarti bu yoldaysa
import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart';

class Akis extends StatefulWidget {
  // selectedFilter parametresi Akis widget'ında tanımlı ama kullanılmıyor gibi duruyor.
  // Eğer bir filtreleme mantığı varsa (örneğin kategoriye göre) bunu _gonderileriYukle
  // metoduna veya FirestoreServisi'ndeki sorguya dahil etmeniz gerekecek.
  // Şimdilik bu parametreyi olduğu gibi bırakıyorum.
  const Akis({Key? key, required int selectedFilter}) : super(key: key);

  @override
  _AkisState createState() => _AkisState();
}

class _AkisState extends State<Akis> {
  late FirestoreServisi _firestoreServisi;
  String? _aktifKullaniciId;

  List<Gonderi> _gonderiler = [];
  bool _isLoadingFirstTime = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _sonGorunenGonderi;
  final int _limit = 3; // Daha fazla gönderi yüklemek için limit

  final PageController _pageController = PageController();
  int _mevcutSayfaIndex = 0;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
    print("Akis initState - Aktif Kullanıcı ID: $_aktifKullaniciId");

    _gonderileriYukle(ilkYukleme: true);

    _pageController.addListener(() {
      int sonrakiSayfa = _pageController.page!.round();
      if (_mevcutSayfaIndex != sonrakiSayfa) {
        _mevcutSayfaIndex = sonrakiSayfa;
        // Sayfanın sonuna gelindiğinde ve daha fazla gönderi varsa yenilerini yükle
        if (sonrakiSayfa >= _gonderiler.length - 1 && !_isLoadingMore && _hasMore) {
          _gonderileriYukle(dahaFazlaGetir: true);
        }
      }
    });
  }

  Future<void> _gonderileriYukle({bool ilkYukleme = false, bool dahaFazlaGetir = false}) async {
    if (dahaFazlaGetir && (_isLoadingMore || !_hasMore)) return;

    // Yükleme durumlarını ayarla
    if (mounted) {
      setState(() {
        if (ilkYukleme) _isLoadingFirstTime = true;
        if (dahaFazlaGetir) _isLoadingMore = true;
      });
    }
    // ilkYukleme true ise _sonGorunenGonderi'yi null yap ki en baştan başlasın
    if (ilkYukleme) {
      _sonGorunenGonderi = null;
    }


    try {
      // FirestoreServisi.tumGonderileriGetir metodu QuerySnapshot<Map<String, dynamic>> döndürmeli.
      // Eğer QuerySnapshot<Object?> döndürüyorsa, .first'ten sonra casting gerekebilir.
      // Gonderi modeliniz ve FirestoreServisi.tumGonderileriGetir ile uyumlu olmalı.
      Stream<QuerySnapshot<Map<String, dynamic>>> gonderiStream = _firestoreServisi
          .tumGonderileriGetir( // Bu metodun QuerySnapshot<Map<String, dynamic>> döndürdüğünü varsayıyoruz
        sonGorunenGonderi: dahaFazlaGetir ? _sonGorunenGonderi : null,
        limit: _limit,
      );

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await gonderiStream.first;


      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMore = false;
            if (dahaFazlaGetir) _isLoadingMore = false;
            if (ilkYukleme) _isLoadingFirstTime = false;
          });
        }
        return;
      }

      List<Gonderi> yeniGonderiler = [];
      for (var doc in querySnapshot.docs) {
        // Gonderi.dokumandanUret zaten DocumentSnapshot<Map<String, dynamic>> bekliyor.
        // Kullanıcı bilgilerini de burada çekiyoruz.
        final gonderiData = doc.data(); // Bu zaten Map<String, dynamic> olmalı
        Kullanici? yayinlayanKullanici;
        final String? kullaniciId = gonderiData['kullaniciId'] as String?;
        if (kullaniciId != null && kullaniciId.isNotEmpty) {
          yayinlayanKullanici = await _firestoreServisi.kullaniciGetir(kullaniciId);
        }
        yeniGonderiler.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
      }

      if (mounted) {
        setState(() {
          if (ilkYukleme) {
            _gonderiler = yeniGonderiler;
          } else if (dahaFazlaGetir) {
            _gonderiler.addAll(yeniGonderiler);
          }

          if (querySnapshot.docs.isNotEmpty) {
            _sonGorunenGonderi = querySnapshot.docs.last;
          }
          _hasMore = yeniGonderiler.length == _limit; // Eğer limit kadar geldiyse daha fazlası olabilir
          _isLoadingFirstTime = false; // İlk yükleme bitti
          if (dahaFazlaGetir) _isLoadingMore = false;
        });
      }
    } catch (e, s) {
      print("AkisSayfasi - Gönderi yükleme hatası: $e \n$s");
      if (mounted) {
        setState(() {
          _isLoadingFirstTime = false;
          if (dahaFazlaGetir) _isLoadingMore = false;
        });
        // Kullanıcıya bir hata mesajı göstermek iyi olabilir
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gönderiler yüklenirken bir hata oluştu.")));
      }
    }
  }

  Future<void> _sayfayiYenile() async {
    // if (_pageController.hasClients && _pageController.page != 0) {
    //   await _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    // }
    await _gonderileriYukle(ilkYukleme: true); // dahaFazlaGetir default false olacak
    // Sayfa yenilendiğinde, eğer PageView'daysak ve ilk sayfada değilsek başa atla
    if (_pageController.hasClients && _pageController.page != 0) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingFirstTime && _gonderiler.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else if (_gonderiler.isEmpty && !_isLoadingFirstTime) { // !_isLoadingFirstTime eklendi, boş ve yükleme bittiyse
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_off_outlined, size: 60, color: Colors.grey[600]), // İkonu değiştirdim
              SizedBox(height: 16),
              Text(
                "Henüz hiç gönderi yok.\nİlk keşfini sen paylaş!", // Mesajı güncelledim
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]), // Rengi biraz koyulaştırdım
              ),
              SizedBox(height: 16), // Boşluğu artırdım
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("Yeniden Dene"),
                onPressed: _sayfayiYenile,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Theme.of(context).colorScheme.secondary, // Tema rengi
                  // foregroundColor: Theme.of(context).colorScheme.onSecondary, // Tema rengi
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              )
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _sayfayiYenile,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical, // Dikey kaydırma devam ediyor
              itemCount: _gonderiler.length,
              itemBuilder: (context, index) {
                final gonderi = _gonderiler[index];

                // ---->>>>> DEĞİŞİKLİK BURADA <<<<<----
                // gonderi.resimUrls listesinin boş olmadığını kontrol et ve ilk resmi al.
                // Eğer GonderiKarti null URL'i veya boş string'i kaldırabiliyorsa,
                // bu kontrolü GonderiKarti içinde de yapabilirsiniz.
                String gosterilecekImageUrl = "";
                if (gonderi.resimUrls.isNotEmpty) {
                  gosterilecekImageUrl = gonderi.resimUrls[0]; // İlk resmi al
                } else {
                  // Eğer resimUrls listesi boşsa (bu durum olmamalı, gönderi oluştururken en az bir resim zorunlu)
                  // bir placeholder URL veya boş string verebilirsiniz.
                  // Ya da GonderiKarti'nda bu durumu ele alacak bir mantık olmalı.
                  print("UYARI: ${gonderi.id} ID'li gönderinin resimUrls listesi boş!");
                }

                return ContentCard( // Widget adının GonderiKarti olduğunu varsayıyoruz
                  key: ValueKey(gonderi.id + "_akis_gonderi_karti"), // Benzersiz key
                  gonderiId: gonderi.id,
                  // imageUrl: gonderi.resimUrls, // ESKİ HATALI KOD
                  imageUrl: gosterilecekImageUrl,  // YENİ DOĞRU KOD
                  // Eğer GonderiKarti birden fazla URL alacak şekilde güncellenirse:
                  // imageUrls: gonderi.resimUrls, // şeklinde de olabilirdi.
                  profileUrl: gonderi.yayinlayanKullanici?.fotoUrl ?? "",
                  userName: gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Gezgin", // Varsayılan isim
                  location: gonderi.konum?? '', // Açıklama yerine konumu gösterelim, açıklama kartın içinde olabilir
                  description: gonderi.aciklama, // Açıklama için yeni bir parametre ekledim GonderiKarti'na
                  category: gonderi.kategori, // Kategori için yeni bir parametre ekledim GonderiKarti'na
                  initialLikeCount: gonderi.begeniSayisi,
                  initialCommentCount: gonderi.yorumSayisi,
                  aktifKullaniciId: _aktifKullaniciId ?? "",
                  onProfileTap: () {
                    print("Akis - Profile Tap: ${gonderi.yayinlayanKullanici?.id}");
                    // TODO: Profil sayfasına yönlendirme
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilSayfasi(kullaniciId: gonderi.kullaniciId)));
                  },
                  onCommentTap: (gonderiId) {
                    print("Akis - Comment Tap: $gonderiId");
                    Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: gonderiId)));
                  },
                  onShareTap: () {
                    print("Akis - Share Tap: ${gonderi.id}");
                    // TODO: Paylaşma fonksiyonelliği
                  },
                  onMoreTap: () {
                    print("Akis - More Tap: ${gonderi.id}");
                    // TODO: Daha fazla seçenek menüsü (örn: rapor et, kullanıcıyı engelle vb.)
                  },
                  // Eğer GonderiKarti beğeni durumunu kendisi yönetmiyorsa, bu bilgiyi de geçmek gerekebilir
                  // isLikedByActiveUser: ... ,
                  // onLikeTap: () => _firestoreServisi.gonderiBegenToggle(gonderiId: gonderi.id, aktifKullaniciId: _aktifKullaniciId ?? ""),
                );
              },
            ),
          ),
          if (_isLoadingMore)
            const Padding( // const eklendi
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
        ],
      ),
    );
  }
}