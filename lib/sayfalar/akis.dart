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
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';
import 'package:pathbooks/sayfalar/profil.dart'; // Profil sayfasına yönlendirme için

class Akis extends StatefulWidget {
  final int selectedFilter; // 0: Keşfet (Tüm gönderiler), 1: Takip Edilenler
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
  final int _limit = 3; // Bir seferde yüklenecek gönderi sayısı

  late PageController _pageController;
  int _mevcutSayfaIndex = 0;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
    // viewportFraction, kartların yan yana biraz görünmesini sağlar
    _pageController = PageController(viewportFraction: 0.94);

    print("Akis initState - Aktif Kullanıcı ID: $_aktifKullaniciId, Seçilen Filtre: ${widget.selectedFilter}");
    _gonderileriYukle(ilkYukleme: true);

    _pageController.addListener(() {
      if (!_pageController.hasClients || _pageController.page == null || _gonderiler.isEmpty) return;
      int sonrakiSayfa = _pageController.page!.round();
      if (_mevcutSayfaIndex != sonrakiSayfa) {
        setState(() {
          _mevcutSayfaIndex = sonrakiSayfa;
        });
        // Son elemana 1 kala daha fazla yükle (daha akıcı bir deneyim için)
        if (sonrakiSayfa >= _gonderiler.length - 1 && !_isLoadingMore && _hasMore) {
          _gonderileriYukle(dahaFazlaGetir: true);
        }
      }
    });
  }

  // widget.selectedFilter değiştiğinde gönderileri yeniden yükle
  @override
  void didUpdateWidget(covariant Akis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFilter != oldWidget.selectedFilter) {
      print("Akis didUpdateWidget - Filtre değişti: ${widget.selectedFilter}");
      _gonderileriYukle(ilkYukleme: true);
    }
  }

  Future<void> _gonderileriYukle({bool ilkYukleme = false, bool dahaFazlaGetir = false}) async {
    if (dahaFazlaGetir && (_isLoadingMore || !_hasMore)) return;
    if (!mounted) return;

    setState(() {
      if (ilkYukleme) {
        _isLoadingFirstTime = true;
        _gonderiler.clear(); // İlk yüklemede veya filtre değiştiğinde listeyi temizle
        _sonGorunenGonderi = null;
        _hasMore = true;
        _mevcutSayfaIndex = 0; // Sayfa indexini de sıfırla
        if (_pageController.hasClients && _pageController.page != 0) {
          // Animate etmeden direkt başa al, kullanıcı filtre değiştirdiğini bilsin.
          _pageController.jumpToPage(0);
        }
      }
      if (dahaFazlaGetir) _isLoadingMore = true;
    });

    try {
      Stream<QuerySnapshot<Map<String, dynamic>>> gonderiStream;

      if (widget.selectedFilter == 1 && _aktifKullaniciId != null) {
        // TODO: FirestoreServisi'nde "takipEdilenKullanicilarinGonderileriniGetir" metodu oluşturulmalı.
        // Bu metot, aktif kullanıcının takip ettiği kişilerin ID'lerini alıp
        // bu ID'lere ait gönderileri çekmeli.
        // Şimdilik, bu özellik hazır olana kadar tüm gönderileri göstermeye devam edelim
        // veya boş bir liste gösterelim/kullanıcıya bilgi verelim.
        print("Akis: 'Takip Edilenler' filtresi seçildi. Bu özellik henüz implemente edilmedi, tüm gönderiler gösteriliyor.");
        gonderiStream = _firestoreServisi.tumGonderileriGetir(
          sonGorunenGonderi: dahaFazlaGetir ? _sonGorunenGonderi : null,
          limit: _limit,
        );
        // Örnek (eğer metot olsaydı):
        // gonderiStream = _firestoreServisi.takipEdilenKullanicilarinGonderileriniGetir(
        //   aktifKullaniciId: _aktifKullaniciId!,
        //   sonGorunenGonderi: dahaFazlaGetir ? _sonGorunenGonderi : null,
        //   limit: _limit,
        // );
      } else {
        // Keşfet (selectedFilter == 0) veya kullanıcı giriş yapmamışsa tüm gönderileri getir
        gonderiStream = _firestoreServisi.tumGonderileriGetir(
          sonGorunenGonderi: dahaFazlaGetir ? _sonGorunenGonderi : null,
          limit: _limit,
        );
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await gonderiStream.first;

      if (querySnapshot.docs.isEmpty) {
        if (mounted) setState(() => _hasMore = false);
      } else {
        List<Gonderi> yeniGonderiler = [];
        for (var doc in querySnapshot.docs) {
          Kullanici? yayinlayanKullanici;
          final String? kullaniciId = doc.data()['kullaniciId'] as String?;
          if (kullaniciId != null && kullaniciId.isNotEmpty) {
            yayinlayanKullanici = await _firestoreServisi.kullaniciGetir(kullaniciId);
          }
          yeniGonderiler.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
        }
        if (mounted) {
          setState(() {
            // ilkYukleme true ise _gonderiler zaten temizlenmişti.
            _gonderiler.addAll(yeniGonderiler);
            if (querySnapshot.docs.isNotEmpty) {
              _sonGorunenGonderi = querySnapshot.docs.last;
            }
            _hasMore = yeniGonderiler.length == _limit;
          });
        }
      }
    } catch (e, s) {
      print("AkisSayfasi - Gönderi yükleme hatası: $e \n$s");
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gönderiler yüklenirken bir sorun oluştu."))
        );
      }
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingFirstTime && _gonderiler.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor.withOpacity(0.8)));
    }
    if (_gonderiler.isEmpty && !_isLoadingFirstTime) {
      String mesaj = "Keşfedilecek yeni gönderi yok.\nİlk paylaşımı sen yapabilirsin!";
      if (widget.selectedFilter == 1) {
        mesaj = "Takip ettiğin kişilerin henüz hiç gönderisi yok\nveya bu özellik yakında gelecek!";
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.selectedFilter == 1 ? Icons.people_outline_rounded : Icons.travel_explore_rounded, size: 60, color: Colors.grey[500]),
            SizedBox(height: 16),
            Text(mesaj, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text("Yeniden Dene"),
              onPressed: _sayfayiYenile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: TextStyle(fontSize: 14)
              ),
            ),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _sayfayiYenile,
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor, // Tema ile uyumlu
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: _gonderiler.length + (_hasMore && !_isLoadingMore && _gonderiler.isNotEmpty ? 1 : 0), // Sadece gönderi varsa ve daha fazla varsa yükleme göstergesi
        itemBuilder: (context, index) {
          if (index == _gonderiler.length) {
            // Bu blok sadece daha fazla gönderi varsa ve yüklenmiyorsa çalışır.
            return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2.0, color: theme.primaryColor.withOpacity(0.6))));
          }

          final gonderi = _gonderiler[index];
          return Padding(
            // viewportFraction 1'den küçükse kartlar arasında boşluk bırak
            padding: EdgeInsets.symmetric(horizontal: _pageController.viewportFraction < 1.0 ? 8.0 : 0.0),
            child: ContentCard(
              key: ValueKey(gonderi.id + "_akis_karti_${widget.selectedFilter}"), // Filtreyi de ekleyerek key'i daha benzersiz yap
              gonderiId: gonderi.id,
              resimUrls: gonderi.resimUrls,
              profileUrl: gonderi.yayinlayanKullanici?.fotoUrl ?? "",
              userName: gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Gezgin",
              location: gonderi.konum ?? "",
              description: gonderi.aciklama,
              category: gonderi.kategori,
              initialLikeCount: gonderi.begeniSayisi,
              initialCommentCount: gonderi.yorumSayisi,
              aktifKullaniciId: _aktifKullaniciId ?? "",
              yayinlayanKullanici: gonderi.yayinlayanKullanici, // ContentCard'a bu bilgiyi geçiyoruz
              onProfileTap: () {
                if (gonderi.yayinlayanKullanici != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profil(aktifKullanici: gonderi.yayinlayanKullanici!),
                    ),
                  );
                } else {
                  // Kullanıcı bilgisi yoksa bir uyarı gösterilebilir
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Kullanıcı profiline ulaşılamadı.")),
                  );
                }
              },
              onCommentTap: (gonderiId) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: gonderiId)));
              },
              onDetailsTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: gonderi)));
              },
              onMoreTap: () {
                // TODO: Akış sayfasındaki gönderiler için "Daha Fazla" seçenekleri
                // Örneğin: Raporla, Kullanıcıyı Engelle vb.
                // Bu, gönderinin kendi kullanıcısına ait olup olmamasına göre değişebilir.
                print("Akis - More Tap: ${gonderi.id}");
                // Örnek bir menü:
                // showModalBottomSheet(context: context, builder: (context) => ...);
              },
              // onShareTap ContentCard içinde halledildiği için burada tekrar belirtmeye gerek yok.
            ),
          );
        },
      ),
    );
  }
}