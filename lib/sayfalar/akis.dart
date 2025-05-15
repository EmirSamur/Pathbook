// lib/sayfalar/akis.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/widgets/gonderi_karti.dart'; // ContentCard'ı import ediyoruz
import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart'; // <<<--- YENİ IMPORT EKLENDİ

class Akis extends StatefulWidget {
  final int selectedFilter;
  const Akis({Key? key, required this.selectedFilter}) : super(key: key);

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
  final int _limit = 3;

  late PageController _pageController;
  int _mevcutSayfaIndex = 0;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
    _pageController = PageController();

    print("Akis initState - Aktif Kullanıcı ID: $_aktifKullaniciId");
    _gonderileriYukle(ilkYukleme: true);

    _pageController.addListener(() {
      if (!_pageController.hasClients || _pageController.page == null) return;
      int sonrakiSayfa = _pageController.page!.round();
      if (_mevcutSayfaIndex != sonrakiSayfa) {
        setState(() {
          _mevcutSayfaIndex = sonrakiSayfa;
        });
        if (sonrakiSayfa >= _gonderiler.length - 1 && !_isLoadingMore && _hasMore) {
          _gonderileriYukle(dahaFazlaGetir: true);
        }
      }
    });
  }

  Future<void> _gonderileriYukle({bool ilkYukleme = false, bool dahaFazlaGetir = false}) async {
    if (dahaFazlaGetir && (_isLoadingMore || !_hasMore)) return;
    if (mounted) {
      setState(() {
        if (ilkYukleme) _isLoadingFirstTime = true;
        if (dahaFazlaGetir) _isLoadingMore = true;
      });
    }
    if (ilkYukleme) _sonGorunenGonderi = null;

    try {
      Stream<QuerySnapshot<Map<String, dynamic>>> gonderiStream = _firestoreServisi
          .tumGonderileriGetir(
        sonGorunenGonderi: dahaFazlaGetir ? _sonGorunenGonderi : null,
        limit: _limit,
        // TODO: widget.selectedFilter'a göre kategori filtreleme eklenebilir
      );
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await gonderiStream.first;

      if (querySnapshot.docs.isEmpty) {
        if (mounted) setState(() { _hasMore = false; });
      } else {
        List<Gonderi> yeniGonderiler = [];
        for (var doc in querySnapshot.docs) {
          final gonderiData = doc.data();
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
            } else {
              _gonderiler.addAll(yeniGonderiler);
            }
            if (querySnapshot.docs.isNotEmpty) {
              _sonGorunenGonderi = querySnapshot.docs.last;
            }
            _hasMore = yeniGonderiler.length == _limit;
          });
        }
      }
    } catch (e, s) {
      print("AkisSayfasi - Gönderi yükleme hatası: $e \n$s");
    } finally {
      if (mounted) {
        setState(() {
          if (ilkYukleme) _isLoadingFirstTime = false;
          if (dahaFazlaGetir) _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _sayfayiYenile() async {
    await _gonderileriYukle(ilkYukleme: true);
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
    } else if (_gonderiler.isEmpty && !_isLoadingFirstTime) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_off_outlined, size: 60, color: Colors.grey[600]),
              SizedBox(height: 16),
              Text("Henüz hiç gönderi yok.\nİlk keşfini sen paylaş!", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey[700])),
              SizedBox(height: 16),
              ElevatedButton.icon(icon: Icon(Icons.refresh), label: Text("Yeniden Dene"), onPressed: _sayfayiYenile, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12))),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _sayfayiYenile,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal, // Yatay kaydırma
        itemCount: _gonderiler.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _gonderiler.length) {
            return Center(child: CircularProgressIndicator(strokeWidth: 2.0));
          }

          final gonderi = _gonderiler[index];

          return ContentCard(
            key: ValueKey(gonderi.id + "_akis_gonderi_karti"),
            gonderiId: gonderi.id,
            resimUrls: gonderi.resimUrls, // Tüm resim URL'leri listesi
            profileUrl: gonderi.yayinlayanKullanici?.fotoUrl ?? "",
            userName: gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Gezgin",
            location: gonderi.konum ?? "",
            description: gonderi.aciklama,
            category: gonderi.kategori,
            initialLikeCount: gonderi.begeniSayisi,
            initialCommentCount: gonderi.yorumSayisi,
            aktifKullaniciId: _aktifKullaniciId ?? "",
            onProfileTap: () {
              print("Akis - Profile Tap: ${gonderi.yayinlayanKullanici?.id}");
              // TODO: Profil sayfasına yönlendirme
            },
            onCommentTap: (gonderiId) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: gonderiId)));
            },
            onShareTap: () {
              print("Akis - Share Tap: ${gonderi.id}");
              // TODO: Paylaşma fonksiyonelliği
            },
            onMoreTap: () {
              print("Akis - More Tap: ${gonderi.id}");
              // TODO: Daha fazla seçenek menüsü
            },
            onDetailsTap: () { // <<<--- GÜNCELLENEN KISIM
              print("Detaylar tıklandı (Akis): ${gonderi.id}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GonderiDetaySayfasi(gonderi: gonderi),
                ),
              );
            },
          );
        },
      ),
    );
  }
}