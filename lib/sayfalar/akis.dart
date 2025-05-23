// lib/sayfalar/akis.dart
import 'dart:async';
import 'dart:math' as math; // Animasyon için math.pi gibi kullanımlar olabilir
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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _sonGorunenGonderi;
  final int _limitPerLoad = 4; // Keşfet için bir seferde yüklenecek gönderi sayısı
  final int _takipEdilenlerLimit = 30; // Takip edilenlerden çekilecek maksimum gönderi

  late PageController _pageController;
  double _currentPageValue = 0.0;

  // Animasyon sabitleri (ContentCard'daki animasyonlar için)
  static const double _viewportFractionValue = 0.9; // Sayfaların ne kadar görüneceği
  static const double _cardHorizontalPadding = 4.0; // Kartlar arası yatay boşluk
  static const double _maxScaleFactor = 1.0; // Aktif kartın ölçeği
  static const double _minScaleFactor = 0.9; // Pasif kartların ölçeği

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;

    _pageController = PageController(
      viewportFraction: _viewportFractionValue,
      initialPage: 0, // Her zaman ilk sayfadan başla
    );

    _pageController.addListener(() {
      if (mounted && _pageController.page != null) {
        setState(() => _currentPageValue = _pageController.page!);
      }
      // Sadece "Keşfet" modunda ve daha fazla gönderi varsa sayfalama yap
      if (widget.selectedFilter == 0 && // Sadece Keşfet filtresinde
          _pageController.hasClients &&
          _pageController.page != null &&
          _gonderiler.isNotEmpty) {
        int nextPage = _pageController.page!.round();
        // Son 2 gönderiye gelindiğinde ve yükleme işlemi yoksa ve daha fazla gönderi varsa
        if (nextPage >= _gonderiler.length - 2 && !_isLoadingMore && _hasMore && !_isLoadingFirstTime) {
          print("Akis: Sayfa sonuna yaklaşıldı, daha fazla gönderi yükleniyor...");
          _loadPosts(loadMore: true);
        }
      }
    });
    _loadPosts(initialLoad: true);
  }

  @override
  void didUpdateWidget(covariant Akis oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Eğer Anasayfa'dan gelen filtre (Keşfet/Takip Edilenler) değişirse, gönderileri yeniden yükle
    if (widget.selectedFilter != oldWidget.selectedFilter) {
      _loadPosts(initialLoad: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool initialLoad = false, bool loadMore = false}) async {
    // "Keşfet" filtresinde değilsek ve "loadMore" true ise bir şey yapma (çünkü "Takip Edilenler" tek seferde yükleniyor)
    if (loadMore && widget.selectedFilter != 0) return;
    // Zaten yükleme yapılıyorsa veya daha fazla gönderi yoksa (ve "Keşfet" modundaysak) bir şey yapma
    if (widget.selectedFilter == 0 && loadMore && (_isLoadingMore || !_hasMore)) return;
    if (!mounted) return;

    setState(() {
      if (initialLoad) {
        _isLoadingFirstTime = true;
        _gonderiler.clear(); // Listeyi temizle
        _sonGorunenGonderi = null; // Sayfalama için sıfırla
        _hasMore = true;         // Yeni yüklemede daha fazla olabileceğini varsay
        _currentPageValue = 0.0; // Sayfa değerini sıfırla
        if (_pageController.hasClients && _pageController.page != 0.0) {
          // Sayfa kontrolcüsünü animasyonsuz başa al
          _pageController.jumpToPage(0);
        }
      }
      // Sadece "Keşfet" modu için "daha fazla yükleniyor" durumu
      if (loadMore && widget.selectedFilter == 0) _isLoadingMore = true;
    });

    try {
      List<Gonderi> fetchedPosts = [];
      if (widget.selectedFilter == 1) { // Takip Edilenler filtresi
        if (_aktifKullaniciId != null && _aktifKullaniciId!.isNotEmpty) {
          fetchedPosts = await _firestoreServisi.takipEdilenlerinGonderileriniGetir(
            aktifKullaniciId: _aktifKullaniciId!,
            limit: _takipEdilenlerLimit, // Belirlenen limit kadar çek
          );
          if (fetchedPosts.isNotEmpty) {
            fetchedPosts.shuffle(math.Random()); // Takip edilenlerin gönderilerini karıştır
          }
          print("Akis: Takip edilen ${fetchedPosts.length} gönderi yüklendi.");
        } else {
          print("Akis: Takip edilenler için aktif kullanıcı ID'si bulunamadı.");
        }
        // Takip edilenler için 'daha fazla yükle' mantığı şimdilik yok, hepsi bir kerede (limitli) çekiliyor.
        if (mounted) setState(() => _hasMore = false); // Bu filtre için daha fazla yok
      } else { // Keşfet filtresi (Tüm Gönderiler)
        // Metot adı akisGonderileriniGetir olarak güncellendi
        Stream<QuerySnapshot<Map<String, dynamic>>> postStream =
        _firestoreServisi.akisGonderileriniGetir( // DEĞİŞTİRİLDİ
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
            // Gelen gönderi sayısı limitten azsa, daha fazla gönderi kalmamıştır.
            _hasMore = fetchedPosts.length == _limitPerLoad;
          }
        }
        print("Akis: Keşfet için ${fetchedPosts.length} gönderi yüklendi. Daha fazla var mı: $_hasMore");
      }

      if (mounted) {
        setState(() {
          // initialLoad ise _gonderiler zaten temizlenmişti, değilse (loadMore ise) ekle.
          _gonderiler.addAll(fetchedPosts);
        });
      }
    } catch (e, s) {
      print("AkisSayfasi - HATA (_loadPosts): $e \n$s");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gönderiler yüklenirken bir sorun oluştu.")));
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
    if (widget.selectedFilter == 1) { // Takip Edilenler
      message = "Takip ettiklerinden henüz yeni bir gönderi yok.";
      if (_aktifKullaniciId == null) {
        message = "Takip ettiklerini görmek için lütfen giriş yapın.";
      }
      icon = Icons.sentiment_dissatisfied_outlined; // Daha uygun bir ikon
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 60, color: Colors.grey[500]), // İkon boyutu ayarlandı
          SizedBox(height: 16), // Boşluk ayarlandı
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4)), // Font ve boşluk ayarlandı
          SizedBox(height: 20), // Boşluk ayarlandı
          if (_aktifKullaniciId != null || widget.selectedFilter == 0) // Giriş yapılmadıysa ve takip edilenlerdeyse gösterme
            ElevatedButton.icon(
              icon: Icon(Icons.refresh_rounded, size: 18), // İkon boyutu
              label: Text("Yeniden Dene"),
              onPressed: _refreshPosts,
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor.withOpacity(0.75), // Opaklık ayarlandı
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 11), // Padding ayarlandı
                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500) // Font ayarlandı
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
      return Center(child: CircularProgressIndicator(color: theme.primaryColor.withOpacity(0.85), strokeWidth: 2.5)); // Renk ve kalınlık ayarlandı
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
            (widget.selectedFilter == 0 && _hasMore && !_isLoadingMore && _gonderiler.isNotEmpty ? 1 : 0), // Sadece Keşfet'te ve daha fazla varsa yükleme göstergesi
        itemBuilder: (context, index) {
          // "Keşfet" modunda ve listenin sonundaysak yükleme göstergesini göster
          if (widget.selectedFilter == 0 && index == _gonderiler.length) {
            return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2.0, color: theme.primaryColor.withOpacity(0.6))));
          }

          final gonderi = _gonderiler[index];
          double scale = _maxScaleFactor;
          double yOffset = 0;
          double opacity = 1.0;

          // Sayfa geçiş animasyonları için hesaplamalar
          if (_pageController.position.haveDimensions) {
            double page = _pageController.page ?? _currentPageValue; // page null ise _currentPageValue kullan
            double pageOffset = page - index;

            // Ölçeklendirme: Ortadaki kart daha büyük, yanlardakiler daha küçük
            scale = (_maxScaleFactor - (pageOffset.abs() * (_maxScaleFactor - _minScaleFactor))).clamp(_minScaleFactor, _maxScaleFactor);
            // Y ekseninde hafif kaydırma (parallax etkisi için)
            yOffset = (pageOffset.abs() * 10.0).clamp(0.0, 10.0); // Kaydırma miktarı azaltıldı
            // Opaklık: Yanlardaki kartlar biraz daha soluk
            opacity = (1 - (pageOffset.abs() * 0.25)).clamp(0.5, 1.0); // Opaklık aralığı ayarlandı
          }

          return Transform.translate(
            offset: Offset(0, yOffset),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Padding(
                  // Dikey padding, kart küçüldükçe artarak ortalanmış gibi görünmesini sağlar
                  padding: EdgeInsets.symmetric(
                    horizontal: _cardHorizontalPadding,
                    vertical: 8.0 + (1 - scale) * 25, // Dikey padding ayarlandı
                  ),
                  child: ContentCard( // gonderi_karti.dart dosyanızdaki widget
                    key: ValueKey("${gonderi.id}_filter${widget.selectedFilter}_idx${index}_akis"), // Key güncellendi
                    gonderiId: gonderi.id,
                    resimUrls: gonderi.resimUrls,
                    profileUrl: gonderi.yayinlayanKullanici?.fotoUrl ?? "",
                    userName: gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Gezgin",
                    location: "${gonderi.sehir ?? ''}${gonderi.sehir != null && gonderi.ulke != null ? ', ' : ''}${gonderi.ulke ?? ''}".replaceAll(RegExp(r'^, |,$'), '').trim().isNotEmpty
                        ? "${gonderi.sehir ?? ''}${gonderi.sehir != null && gonderi.ulke != null ? ', ' : ''}${gonderi.ulke ?? ''}"
                        : gonderi.konum ?? "", // Yeni ülke/şehir gösterimi
                    description: gonderi.aciklama,
                    category: gonderi.kategori,
                    initialLikeCount: gonderi.begeniSayisi,
                    initialCommentCount: gonderi.yorumSayisi,
                    aktifKullaniciId: _aktifKullaniciId ?? "",
                    yayinlayanKullanici: gonderi.yayinlayanKullanici, // ContentCard'a bu parametre eklendi
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
                      // TODO: Daha fazla seçenekler menüsü (raporla, engelle vb.)
                      print("Akis - Daha Fazla Tıklandı: ${gonderi.id}");
                    },
                    // onShareTap: () { ... } // İsteğe bağlı eklenebilir
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