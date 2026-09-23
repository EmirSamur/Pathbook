// lib/sayfalar/gonderi_detay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/gonderi.dart'; // Gonderi modelinin ulke ve sehir içerdiğinden emin ol
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:intl/date_symbol_data_local.dart'; // Türkçe tarih için
import 'package:pathbooks/sayfalar/etiket_sayfasi.dart';
import 'package:pathbooks/sayfalar/tam_ekran_resim_sayfasi.dart';
import 'package:pathbooks/widgets/gonderi_secenekleri.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';
import 'package:pathbooks/widgets/takip_butonu.dart';

class GonderiDetaySayfasi extends StatefulWidget {
  final Gonderi gonderi;

  const GonderiDetaySayfasi({
    Key? key,
    required this.gonderi,
  }) : super(key: key);

  @override
  _GonderiDetaySayfasiState createState() => _GonderiDetaySayfasiState();
}

class _GonderiDetaySayfasiState extends State<GonderiDetaySayfasi> {
  late Gonderi _gonderi;
  Kullanici? _yayinlayanKullanici;
  bool _kullaniciYukleniyor = true;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLiking = false;
  String? _aktifKullaniciId;
  late FirestoreServisi _firestoreServisi;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController(); // Resim galerisi için
  final GlobalKey<BegeniKalbiState> _kalpKey = GlobalKey<BegeniKalbiState>();

  // ContentCard'dan esinlenilen sabitler KALDIRILDI
  // static const double _actionIconSize = 25.0;
  // static final Color _highlightColor = Colors.redAccent[200]!;


  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null); // Türkçe tarih formatı için
    _gonderi = widget.gonderi;
    _likeCount = _gonderi.begeniSayisi;
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;

    _yayinlayanKullaniciyiGetir();
    if (_aktifKullaniciId != null && _aktifKullaniciId!.isNotEmpty) {
      _checkIfLiked();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _yayinlayanKullaniciyiGetir() async {
    if (!mounted) return;
    setState(() => _kullaniciYukleniyor = true);

    if (_gonderi.yayinlayanKullanici != null) {
      if (mounted) {
        setState(() {
          _yayinlayanKullanici = _gonderi.yayinlayanKullanici;
          _kullaniciYukleniyor = false;
        });
      }
      return;
    }
    Kullanici? kullanici = await _firestoreServisi.kullaniciGetir(_gonderi.kullaniciId);
    if (mounted) {
      setState(() {
        _yayinlayanKullanici = kullanici;
        _kullaniciYukleniyor = false;
      });
    }
  }

  Future<void> _checkIfLiked() async {
    if (!mounted || _gonderi.id.isEmpty || _aktifKullaniciId == null || _aktifKullaniciId!.isEmpty) {
      if (mounted) setState(() => _isLiked = false);
      return;
    }
    bool liked = await _firestoreServisi.kullaniciGonderiyiBegendiMi(
      gonderiId: _gonderi.id,
      aktifKullaniciId: _aktifKullaniciId!,
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (_aktifKullaniciId == null || _aktifKullaniciId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Beğenmek için giriş yapmalısınız.")));
      return;
    }
    if (_isLiking || !mounted) return;
    setState(() { _isLiking = true; _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
    try {
      await _firestoreServisi.gonderiBegenToggle(gonderiId: _gonderi.id, aktifKullaniciId: _aktifKullaniciId!);
    } catch (e) {
      if (mounted) { setState(() { _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Beğeni işlemi sırasında bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _ciftDokunmaBegeni() {
    _kalpKey.currentState?.oynat();
    if (!_isLiked && !_isLiking) _toggleLike();
  }

  void _etiketeGit(EtiketTuru tur, String? deger) {
    if (deger == null || deger.trim().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => EtiketSayfasi(tur: tur, deger: deger)));
  }

  Widget _buildMetaInfoRow(IconData icon, String? text, ThemeData theme, {VoidCallback? onTap}) {
    if (text == null || text.isEmpty) return SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
            SizedBox(width: 5),
            Flexible(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.5, color: theme.textTheme.bodySmall?.color?.withOpacity(0.9)), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  // _buildInteractiveButton metodu KALDIRILDI
  // Widget _buildInteractiveButton({
  //   required IconData icon,
  //   Color? color,
  //   VoidCallback? onPressed,
  //   String? tooltip,
  // }) {
  //   final theme = Theme.of(context);
  //   return IconButton(
  //     icon: Icon(icon, size: _actionIconSize),
  //     color: color ?? theme.iconTheme.color?.withOpacity(0.8),
  //     onPressed: onPressed,
  //     tooltip: tooltip,
  //     splashRadius: _actionIconSize + 2,
  //     padding: const EdgeInsets.all(8.0),
  //     constraints: const BoxConstraints(),
  //     visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String appBarTitle = "Gönderi Detayı";
    if (_yayinlayanKullanici?.kullaniciAdi?.isNotEmpty == true) {
      appBarTitle = "${_yayinlayanKullanici!.kullaniciAdi}'nın Paylaşımı";
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(appBarTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        elevation: 0.5,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () => gonderiSecenekleriniGoster(
              context,
              gonderi: _gonderi.copyWith(begeniSayisi: _likeCount, yayinlayanKullanici: _yayinlayanKullanici),
              onSilindi: () => Navigator.pop(context),
              onEngellendi: () => Navigator.pop(context),
              onGuncellendi: (yeniAciklama) => setState(() => _gonderi = _gonderi.copyWith(aciklama: yeniAciklama)),
            ),
          ),
        ],
      ),
      body: _kullaniciYukleniyor
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kullanıcı Bilgisi
            if (_yayinlayanKullanici != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Profil(aktifKullanici: _yayinlayanKullanici!))),
                  child: Row(children: [
                    KullaniciAvatari(fotoUrl: _yayinlayanKullanici!.fotoUrl, kullaniciAdi: _yayinlayanKullanici!.kullaniciAdi, yaricap: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text(_yayinlayanKullanici!.kullaniciAdi ?? "Bilinmeyen Kullanıcı", overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5))),
                    TakipButonu(hedefKullaniciId: _yayinlayanKullanici!.id),
                  ]),
                ),
              ),
            if (_yayinlayanKullanici != null) Divider(height: 1, thickness: 0.5, color: theme.dividerColor.withOpacity(0.5)),

            // 2. Görsel Galerisi
            if (_gonderi.resimUrls.isNotEmpty)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 1.1,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _gonderi.resimUrls.length,
                      onPageChanged: (index) {
                        if (mounted) setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TamEkranResimSayfasi(resimUrls: _gonderi.resimUrls, baslangicIndex: index))),
                          onDoubleTap: _ciftDokunmaBegeni,
                          child: AgGorseli(url: _gonderi.resimUrls[index]),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(child: Center(child: BegeniKalbi(key: _kalpKey))),
                  if (_gonderi.resimUrls.length > 1)
                    Positioned(bottom: 12.0, child: SayfaNoktalari(adet: _gonderi.resimUrls.length, aktif: _currentImageIndex)),
                  if (_gonderi.resimUrls.length > 1)
                    Positioned(
                      top: 10.0,
                      right: 10.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
                        child: Text("${_currentImageIndex + 1} / ${_gonderi.resimUrls.length}", style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              )
            else
              Container(height: 200, color: Colors.grey[900], child: Center(child: Text("Görsel bulunmuyor", style: TextStyle(color: Colors.grey[600])))),

            // 3. Etkileşim Butonları (KALDIRILDI)
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     children: [
            //       _buildInteractiveButton(
            //         icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            //         color: _isLiked ? _highlightColor : (theme.iconTheme.color?.withOpacity(0.8)),
            //         onPressed: _isLiking ? null : _toggleLike,
            //         tooltip: "Beğen",
            //       ),
            //       _buildInteractiveButton(
            //         icon: Icons.mode_comment_outlined,
            //         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: _gonderi.id))),
            //         tooltip: "Yorum Yap",
            //       ),
            //       _buildInteractiveButton(
            //         icon: Icons.share_outlined,
            //         onPressed: _handleShare,
            //         tooltip: "Paylaş",
            //       ),
            //     ],
            //   ),
            // ),

            // Beğeni ve Yorum Sayısı (Biraz yukarı boşluk eklendi, ikonlar kalktığı için)
            SizedBox(height: 8.0), // İkonlar kalktığı için boşluk
            Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0), // Üst padding ayarlandı
                child: Row(
                  children: [
                    if (_likeCount > 0)
                      Text("$_likeCount beğeni", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
                    if (_likeCount > 0 && _gonderi.yorumSayisi > 0)
                      Text("  •  ", style: TextStyle(color: Colors.grey[500])),
                    if (_gonderi.yorumSayisi > 0)
                      InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: _gonderi.id))),
                          child: Text("${_gonderi.yorumSayisi} yorum", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]))),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: _gonderi.id))),
                      icon: const Icon(Icons.mode_comment_outlined, size: 16),
                      label: const Text("Yorumlar"),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[300], visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ),


            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4. Açıklama Metni
                  if (_gonderi.aciklama.isNotEmpty)
                    Text(_gonderi.aciklama, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45, fontSize: 14.5, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.95)))
                  else
                    Text("Açıklama yok.", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600])),
                  SizedBox(height: 16),

                  // 5. Kategori, Ülke, Şehir ve Konum Bilgileri
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 6.0,
                    children: [
                      _buildMetaInfoRow(Icons.category_outlined, _gonderi.kategori, theme, onTap: () => _etiketeGit(EtiketTuru.kategori, _gonderi.kategori)),
                      _buildMetaInfoRow(Icons.public_outlined, _gonderi.ulke, theme, onTap: () => _etiketeGit(EtiketTuru.ulke, _gonderi.ulke)),
                      _buildMetaInfoRow(Icons.location_city_outlined, _gonderi.sehir, theme, onTap: () => _etiketeGit(EtiketTuru.sehir, _gonderi.sehir)),
                      _buildMetaInfoRow(Icons.pin_drop_outlined, _gonderi.konum, theme, onTap: () => _etiketeGit(EtiketTuru.konum, _gonderi.konum)),
                    ],
                  ),
                  SizedBox(height: 16),

                  // 6. Tarih/Saat Bilgisi
                  Text(
                    "Paylaşım Tarihi: ${DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(_gonderi.olusturulmaZamani.toDate())}",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 11.5),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}