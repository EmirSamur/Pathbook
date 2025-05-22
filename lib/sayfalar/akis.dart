// lib/sayfalar/akis.dart
import 'dart:async';
import 'dart:math' as math; // Animasyon için
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/widgets/gonderi_karti.dart';
import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';
import 'package:pathbooks/sayfalar/profil.dart';

class Akis extends StatefulWidget {
  final int selectedFilter; // 0: Keşfet, 1: Takip Edilenler
  const Akis({Key? key, required this.selectedFilter}) : super(key: key);

  @override
  _AkisState createState() => _AkisState();
}

class _AkisState extends State<Akis> {
  late FirestoreServisi _firestoreServisi;
  String? _aktifKullaniciId;

  List<Gonderi> _gonderiler = [];
  bool _isLoadingFirstTime = true;
  bool _isLoadingMore = false; // Sadece Keşfet filtresi için
  bool _hasMore = true;         // Sadece Keşfet filtresi için
  DocumentSnapshot? _sonGorunenGonderi; // Sadece Keşfet filtresi için
  final int _limitPerLoad = 4; // Bir seferde yüklenecek gönderi sayısı (Keşfet için)
  final int _takipEdilenlerLimit = 30; // Takip edilenlerden çekilecek maksimum gönderi

  late PageController _pageController;
  double _currentPageValue = 0.0;

  // Animasyon sabitleri
  static const double _viewportFractionValue = 0.9;
  static const double _cardHorizontalPadding = 4.0;
  static const double _maxScaleFactor = 1.0;
  static const double _minScaleFactor = 0.9;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;

    _pageController = PageController(
      viewportFraction: _viewportFractionValue,
      initialPage: 0,
    );

    _pageController.addListener(() {
      if (mounted && _pageController.page != null) {
        setState(() => _currentPageValue = _pageController.page!);
      }
      // Sadece "Keşfet" modunda ve daha fazla gönderi varsa sayfalama yap
      if (widget.selectedFilter == 0 &&
          _pageController.hasClients &&
          _pageController.page != null &&
          _gonderiler.isNotEmpty) {
        int nextPage = _pageController.page!.round();
        if (nextPage >= _gonderiler.length - 2 && !_isLoadingMore && _hasMore && !_isLoadingFirstTime) {
          _loadPosts(loadMore: true);
        }
      }
    });
    _loadPosts(initialLoad: true);
  }

  @override
  void didUpdateWidget(covariant Akis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFilter != oldWidget.selectedFilter) {
      _loadPosts(initialLoad: true); // Filtre değiştiğinde gönderileri yeniden yükle
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool initialLoad = false, bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMore) && widget.selectedFilter == 0) return;
    if (!mounted) return;

    setState(() {
      if (initialLoad) {
        _isLoadingFirstTime = true;
        _gonderiler.clear();
        _sonGorunenGonderi = null;
        _hasMore = true; // Yeni yüklemede daha fazla olabileceğini varsay
        _currentPageValue = 0.0;
        if (_pageController.hasClients && _pageController.page != 0) {
          _pageController.jumpToPage(0);
        }
      }
      if (loadMore && widget.selectedFilter == 0) _isLoadingMore = true;
    });

    try {
      List<Gonderi> fetchedPosts = [];
      if (widget.selectedFilter == 1) { // Takip Edilenler
        if (_aktifKullaniciId != null && _aktifKullaniciId!.isNotEmpty) {
          fetchedPosts = await _firestoreServisi.takipEdilenlerinGonderileriniGetir(
            aktifKullaniciId: _aktifKullaniciId!,
            limit: _takipEdilenlerLimit,
          );
          if (fetchedPosts.isNotEmpty) {
            fetchedPosts.shuffle(); // Listeyi karıştır
          }
        } else {
          print("Akis: Takip edilenler için aktif kullanıcı ID'si bulunamadı.");
        }
        // Takip edilenler için 'daha fazla yükle' mantığı yok, hepsi bir kerede çekiliyor (limitli)
        if (mounted) setState(() => _hasMore = false);
      } else { // Keşfet (Tüm Gönderiler)
        Stream<QuerySnapshot<Map<String, dynamic>>> postStream =
        _firestoreServisi.tumGonderileriGetir(
          sonGorunenGonderi: loadMore ? _sonGorunenGonderi : null,
          limit: _limitPerLoad,
        );
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await postStream.first;

        if (querySnapshot.docs.isEmpty) {
          if (mounted) setState(() => _hasMore = false);
        } else {
          for (var doc in querySnapshot.docs) {
            Kullanici? yayinlayanKullanici;
            final String? kullaniciId = doc.data()['kullaniciId'] as String?;
            if (kullaniciId != null && kullaniciId.isNotEmpty) {
              yayinlayanKullanici = await _firestoreServisi.kullaniciGetir(kullaniciId);
            }
            fetchedPosts.add(Gonderi.dokumandanUret(doc, yayinlayan: yayinlayanKullanici));
          }
          if (mounted) {
            if (querySnapshot.docs.isNotEmpty) {
              _sonGorunenGonderi = querySnapshot.docs.last;
            }
            _hasMore = fetchedPosts.length == _limitPerLoad;
          }
        }
      }

      if (mounted) {
        setState(() {
          // initialLoad ise _gonderiler zaten temizlenmişti, değilse ekle.
          _gonderiler.addAll(fetchedPosts);
        });
      }
    } catch (e, s) {
      print("AkisSayfasi - HATA (_loadPosts): $e \n$s");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gönderiler yüklenemedi.")));
    } finally {
      if (mounted) {
        setState(() {
          if (initialLoad) _isLoadingFirstTime = false;
          if (loadMore) _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts(initialLoad: true);
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message = "Keşfedilecek yeni gönderi yok.\nİlk paylaşımı sen yapabilirsin!";
    IconData icon = Icons.explore_off_outlined;
    if (widget.selectedFilter == 1) {
      message = "Takip ettiklerinden henüz gönderi yok.";
      if (_aktifKullaniciId == null) {
        message = "Takip ettiklerini görmek için giriş yapmalısın.";
      }
      icon = Icons.group_add_outlined; // Daha uygun bir ikon
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 65, color: Colors.grey[500]),
          SizedBox(height: 18),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16.5, color: Colors.grey[600], height: 1.45)),
          SizedBox(height: 22),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh_rounded, size: 20),
            label: Text("Yeniden Dene"),
            onPressed: _refreshPosts,
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_isLoadingFirstTime && _gonderiler.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor.withOpacity(0.9), strokeWidth: 3.0));
    }
    if (_gonderiler.isEmpty && !_isLoadingFirstTime) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: _gonderiler.length +
            (widget.selectedFilter == 0 && _hasMore && !_isLoadingMore && _gonderiler.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (widget.selectedFilter == 0 && index == _gonderiler.length) {
            return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.primaryColor.withOpacity(0.7))));
          }

          final gonderi = _gonderiler[index];
          double scale = _maxScaleFactor;
          double yOffset = 0;
          double opacity = 1.0;

          if (_pageController.position.haveDimensions) {
            double page = _pageController.page ?? _currentPageValue;
            double pageOffset = page - index;

            scale = (_maxScaleFactor - (pageOffset.abs() * (_maxScaleFactor - _minScaleFactor))).clamp(_minScaleFactor, _maxScaleFactor);
            yOffset = (pageOffset.abs() * 15.0).clamp(0.0, 15.0);
            opacity = (1 - (pageOffset.abs() * 0.20)).clamp(0.6, 1.0);
          }

          return Transform.translate(
            offset: Offset(0, yOffset),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _cardHorizontalPadding,
                    vertical: 12.0 + (1 - scale) * 30,
                  ),
                  child: ContentCard(
                    key: ValueKey("${gonderi.id}_filter${widget.selectedFilter}_idx${index}"),
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
                    yayinlayanKullanici: gonderi.yayinlayanKullanici,
                    onProfileTap: () {
                      if (gonderi.yayinlayanKullanici != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Profil(aktifKullanici: gonderi.yayinlayanKullanici!)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kullanıcı profiline ulaşılamadı.")));
                      }
                    },
                    onCommentTap: (gonderiId) => Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: gonderiId))),
                    onDetailsTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: gonderi))),
                    onMoreTap: () {
                      print("Akis - Daha Fazla Tıklandı: ${gonderi.id}");
                      // TODO: Daha fazla seçenekler menüsü (raporla, engelle vb.)
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}