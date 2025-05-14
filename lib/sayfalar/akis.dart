
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/widgets/gonderi_karti.dart'; // Dosya adını ContentCard'dan GonderiKarti'na değiştirdik varsayımıyla
import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart';

class Akis extends StatefulWidget {
  const Akis({Key? key, required int selectedFilter}) : super(key: key);

  @override
  _AkisState createState() => _AkisState();
}

class _AkisState extends State<Akis> {
  late FirestoreServisi _firestoreServisi;
  // _aktifKullaniciId null olabilir, bu durumu yönetmemiz gerek.
  String? _aktifKullaniciId;

  List<Gonderi> _gonderiler = [];
  bool _isLoadingFirstTime = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _sonGorunenGonderi;
  final int _limit = 3;

  final PageController _pageController = PageController();
  int _mevcutSayfaIndex = 0;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);

    // YetkilendirmeServisi'ni dinleyerek _aktifKullaniciId güncellendiğinde UI'ı yeniden çizmek
    // daha karmaşık olabilir. Şimdilik initState'te alıyoruz.
    // Eğer giriş yapıldıktan sonra bu sayfa açılıyorsa, ID'nin dolu olması beklenir.
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
    print("Akis initState - Aktif Kullanıcı ID: $_aktifKullaniciId"); // <<<--- BU PRINT ÇOK ÖNEMLİ

    _gonderileriYukle(ilkYukleme: true);

    _pageController.addListener(() {
      int sonrakiSayfa = _pageController.page!.round();
      if (_mevcutSayfaIndex != sonrakiSayfa) {
        // setState(() { // Bu setState tüm widget'ı yeniden çizebilir, dikkatli kullanılmalı.
        //   _mevcutSayfaIndex = sonrakiSayfa;
        // });
        _mevcutSayfaIndex = sonrakiSayfa; // Sadece state değişkenini güncelle, UI'ı etkilemiyorsa setState gereksiz.
        if (sonrakiSayfa >= _gonderiler.length - 1 && !_isLoadingMore && _hasMore) {
          _gonderileriYukle(dahaFazlaGetir: true);
        }
      }
    });
  }

  // ... (_gonderileriYukle, _sayfayiYenile, dispose metodları aynı kalabilir) ...
  Future<void> _gonderileriYukle({bool ilkYukleme = false, bool dahaFazlaGetir = false}) async {
    if (dahaFazlaGetir && (_isLoadingMore || !_hasMore)) return;
    if (ilkYukleme) {
      if (_isLoadingFirstTime == false && _gonderiler.isNotEmpty && !dahaFazlaGetir) return;
      setState(() => _isLoadingFirstTime = true);
    } else if (dahaFazlaGetir) {
      setState(() => _isLoadingMore = true);
    }


    try {
      QuerySnapshot<Object?> querySnapshot = await _firestoreServisi
          .tumGonderileriGetir(
        sonGorunenGonderi: dahaFazlaGetir ? _sonGorunenGonderi : null,
        limit: _limit,
      ).first;

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
        final gonderiData = doc.data() as Map<String, dynamic>?;
        if (gonderiData != null) {
          Kullanici? yayinlayanKullanici;
          final String? kullaniciId = gonderiData['kullaniciId'] as String?;
          if (kullaniciId != null && kullaniciId.isNotEmpty) {
            yayinlayanKullanici = await _firestoreServisi.kullaniciGetir(kullaniciId);
          }
          yeniGonderiler.add(Gonderi.dokumandanUret(doc as DocumentSnapshot<Map<String, dynamic>>, yayinlayan: yayinlayanKullanici));
        }
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
          _hasMore = yeniGonderiler.length == _limit;
          if (ilkYukleme) _isLoadingFirstTime = false;
          if (dahaFazlaGetir) _isLoadingMore = false;
        });
      }
    } catch (e, s) {
      print("AkisSayfasi - Gönderi yükleme hatası: $e \n$s");
      if (mounted) {
        setState(() {
          if (ilkYukleme) _isLoadingFirstTime = false;
          if (dahaFazlaGetir) _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _sayfayiYenile() async {
    // if (_pageController.hasClients && _pageController.page != 0) { // Önce başa git
    //   await _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    // }
    await _gonderileriYukle(ilkYukleme: true, dahaFazlaGetir: false);
    if (_pageController.hasClients && _pageController.page != 0) {
      _pageController.jumpToPage(0); // Sonra state güncellenince başa atla
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Yeniden _aktifKullaniciId'yi alıp, null ise ve bir önceki değer doluysa onu kullanmaya çalışmak yerine,
    // initState'te alınan değere güvenelim. Eğer o null ise, kullanıcı gerçekten giriş yapmamış demektir.
    // final String anlikAktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId ?? "";
    // print("Akis build - Aktif Kullanıcı ID: $anlikAktifKullaniciId, State'deki ID: $_aktifKullaniciId");

    if (_isLoadingFirstTime && _gonderiler.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else if (_gonderiler.isEmpty && !_hasMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ondemand_video_outlined, size: 60, color: Colors.grey[600]),
              SizedBox(height: 16),
              Text(
                "Takip ettiklerinden henüz gönderi yok.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[500]),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("Yeniden Dene"),
                onPressed: _sayfayiYenile,
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
              scrollDirection: Axis.vertical,
              itemCount: _gonderiler.length,
              itemBuilder: (context, index) {
                final gonderi = _gonderiler[index];
                // _aktifKullaniciId null ise boş string gönderiyoruz.
                // ContentCard bununla başa çıkabilmeli.
                return ContentCard( // İsim ContentCard'dan GonderiKarti'na güncellendi
                  key: ValueKey(gonderi.id + "_akis_gonderi_karti"),
                  gonderiId: gonderi.id,
                  imageUrl: gonderi.resimUrl,
                  profileUrl: gonderi.yayinlayanKullanici?.fotoUrl ?? "",
                  userName: gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Bilinmeyen",
                  location: gonderi.aciklama,
                  initialLikeCount: gonderi.begeniSayisi,
                  initialCommentCount: gonderi.yorumSayisi,
                  aktifKullaniciId: _aktifKullaniciId ?? "", // BURASI ÖNEMLİ
                  onProfileTap: () {
                    print("Akis - Profile Tap: ${gonderi.yayinlayanKullanici?.id}");
                  },
                  onCommentTap: (gonderiId) {
                    print("Akis - Comment Tap: $gonderiId");
                    Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: gonderiId)));
                  },
                  onShareTap: () {/* ... */},
                  onMoreTap: () {/* ... */},
                );
              },
            ),
          ),
          if (_isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
        ],
      ),
    );
  }
}