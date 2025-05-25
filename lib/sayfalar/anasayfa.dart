// lib/sayfalar/anasayfa.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/modeller/oneri_modeli.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/sayfalar/yukle.dart';
import 'package:pathbooks/sayfalar/akis.dart';
import 'package:pathbooks/sayfalar/ara.dart';
import 'package:pathbooks/sayfalar/duyurular.dart';
import 'package:pathbooks/sayfalar/gelen_kutusu_sayfasi.dart';

class Anasayfa extends StatefulWidget {
  final Kullanici aktifKullanici;

  const Anasayfa({
    super.key,
    required this.aktifKullanici,
  });

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  int _aktifSayfaNo = 0;
  PageController? _sayfaKumandasiAnasayfa;
  String? _aktifKullaniciProfilFotoUrl;
  int _selectedFilterInAkis = 0;

  late FirestoreServisi _firestoreServisi;
  List<OneriModeli> _onerilerListesi = [];
  OneriModeli? _gosterilecekOneri;
  OneriModeli? _sonGosterilenDuyuruKutusuOnerisi;
  final Random _random = Random();
  Timer? _duyuruTimer;

  @override
  void initState() {
    super.initState();
    _sayfaKumandasiAnasayfa = PageController(initialPage: _aktifSayfaNo);
    _aktifKullaniciProfilFotoUrl = widget.aktifKullanici.fotoUrl?.isNotEmpty == true
        ? widget.aktifKullanici.fotoUrl
        : null;
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _fetchSuggestionWhenNeeded();
  }

  Future<void> _fetchSuggestionWhenNeeded() async {
    if (!mounted) return;

    if (_aktifSayfaNo == 0) { // Sadece Akış sayfasındayken öneri göster/güncelle
      if (_gosterilecekOneri == null) {
        _duyuruTimer?.cancel();
        try {
          if (_onerilerListesi.isEmpty) {
            _onerilerListesi = await _firestoreServisi.tumOnerileriGetir();
          }
          if (_onerilerListesi.isNotEmpty && mounted) {
            final int randomIndex = _random.nextInt(_onerilerListesi.length);
            setState(() {
              _gosterilecekOneri = _onerilerListesi[randomIndex];
              _sonGosterilenDuyuruKutusuOnerisi = _gosterilecekOneri;
            });
            _duyuruTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _gosterilecekOneri = null;
                });
              }
            });
          }
        } catch (e) {
          print("Anasayfa - Öneriler çekilirken hata: $e");
        }
      }
    } else { // Diğer sayfalarda öneriyi ve timer'ı temizle
      _duyuruTimer?.cancel();
      if (mounted && _gosterilecekOneri != null) {
        setState(() {
          _gosterilecekOneri = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _sayfaKumandasiAnasayfa?.dispose();
    _duyuruTimer?.cancel();
    super.dispose();
  }

  Widget _buildDuyuruKutusu(BuildContext context, ThemeData theme) {
    // Bu metodun içeriği bir önceki cevaptaki gibi kalabilir.
    // Sadece Stack içinde nasıl konumlandırılacağı build metodunda ayarlanacak.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
            axis: Axis.vertical,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: _gosterilecekOneri == null
          ? SizedBox.shrink(key: const ValueKey('bosDuyuruAnasayfaStack')) // Farklı bir key
          : Container(
        key: ValueKey('duyuruKutusuStack_${_gosterilecekOneri!.id}'), // Farklı bir key
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceVariant.withOpacity(0.95), // Opaklık ayarlandı
              theme.colorScheme.surface.withOpacity(0.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // Gölge ayarlandı
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
          // borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)), // Sadece alt köşeler yuvarlak olabilir
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _duyuruTimer?.cancel();
              final OneriModeli? tiklananOneri = _gosterilecekOneri;
              if (mounted) {
                setState(() { _gosterilecekOneri = null; });
              }
              if (tiklananOneri != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DuyurularSayfasi(secilenOneri: tiklananOneri),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10.0, // Status bar için padding
                bottom: 10.0,
                left: 16.0,
                right: 16.0,
              ),
              constraints: const BoxConstraints(minHeight: 60),
              child: Row(
                children: [
                  if (_gosterilecekOneri!.gorselUrl?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.3), width: 0.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5.5),
                          child: Image.network(
                            _gosterilecekOneri!.gorselUrl!,
                            width: 36, height: 36, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.campaign_outlined, size: 28),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _gosterilecekOneri!.yerAdi,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _gosterilecekOneri!.ipucuMetni,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.75), fontSize: 11),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip( // Bu metodun içeriği bir önceki cevaptaki gibi kalabilir
      String label,
      IconData iconData,
      bool isSelected,
      VoidCallback onTap,
      ThemeData theme,
      ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.9)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.9),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SADECE FİLTRELERİ İÇEREN YENİ HEADER WIDGET'I
  Widget _buildFilterHeader(BuildContext context, ThemeData theme) {
    return Container(
      // Arka planı Akış sayfasının arka planıyla uyumlu veya hafif transparan
      color: theme.scaffoldBackgroundColor.withOpacity(0.95), // Veya theme.appBarTheme.backgroundColor
      padding: EdgeInsets.only(
        // Eğer öneri kutusu hiç gösterilmiyorsa veya Stack'te ayrıysa,
        // filtrelerin üst padding'i status bar'ı içermeli.
        // Şimdilik öneri kutusu Stack'te olduğu için bu padding basit kalabilir.
        top: MediaQuery.of(context).padding.top + 8.0, // Status bar + boşluk
        bottom: 8.0,
        left: 12.0,
        right: 12.0,
      ),
      child: Row(
        children: [
          _buildFilterChip(
              "Keşfet",
              Icons.explore_outlined,
              _selectedFilterInAkis == 0,
                  () { if(mounted && _selectedFilterInAkis != 0) setState(() => _selectedFilterInAkis = 0);},
              theme
          ),

          const SizedBox(width: 10),
          _buildFilterChip(
              "Takip Edilenler",
              Icons.people_outline_rounded,
              _selectedFilterInAkis == 1,
                  () { if(mounted && _selectedFilterInAkis != 1) setState(() => _selectedFilterInAkis = 1);},
              theme
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<Widget> _sayfalar = [
      Akis(key: const ValueKey('akisSayfasi'), selectedFilter: _selectedFilterInAkis),
      const AraSayfasi(key: ValueKey('araSayfasi')),
      const GonderiEkleSayfasi(key: ValueKey('gonderiEkleSayfasi')),
      GelenKutusuSayfasi(key: const ValueKey('gelenKutusuSayfasi'), sonOneri: _sonGosterilenDuyuruKutusuOnerisi),
      Profil(key: ValueKey('profilSayfasi_${widget.aktifKullanici.id}'), aktifKullanici: widget.aktifKullanici),
    ];

    return Scaffold(
      // backgroundColor: theme.scaffoldBackgroundColor, // Scaffold'un genel arka planı
      body: Stack( // ANA GÖVDE ARTIK BİR STACK
        children: [
          // 1. Sayfa İçeriği (Tüm alanı kaplar, en altta)
          Column( // PageView'in üstüne filtreleri koymak için Column
            children: [
              // Sadece Akış sayfasındaysa ve öneri kutusu görünmüyorsa filtreleri göster
              // Eğer öneri kutusu da Stack'teyse bu mantık değişir.
              // Şimdilik filtreler her zaman Akış sayfasının üstünde, öneri kutusunun altında.
              if (_aktifSayfaNo == 0) _buildFilterHeader(context, theme),
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _sayfaKumandasiAnasayfa,
                  onPageChanged: (int acilanSayfaNo) {
                    if (mounted) {
                      setState(() {
                        _aktifSayfaNo = acilanSayfaNo;
                      });
                      _fetchSuggestionWhenNeeded(); // Sayfa değiştiğinde öneri mantığını çalıştır
                    }
                  },
                  children: _sayfalar,
                ),
              ),
            ],
          ),

          // 2. Öneri/Duyuru Kutusu (Üstte, sadece Akış sayfasında ve öneri varsa görünür)
          if (_aktifSayfaNo == 0) // Sadece Akış sayfasında göster
            Positioned( // Stack içinde konumlandırma
              top: 0,
              left: 0,
              right: 0,
              child: _buildDuyuruKutusu(context, theme),
            ),
        ],
      ),
      bottomNavigationBar: Container( /* ... (BottomNavigationBar aynı kalır) ... */
        decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor ?? const Color(0xFF0F0F0F),
            border: Border(top: BorderSide(color: Colors.grey[850]!, width: 0.6))),
        child: BottomNavigationBar(
          currentIndex: _aktifSayfaNo,
          onTap: (int secilenSayfaNo) {
            if (_aktifSayfaNo != secilenSayfaNo) {
              _sayfaKumandasiAnasayfa?.jumpToPage(secilenSayfaNo);
            }
          },
          type: theme.bottomNavigationBarTheme.type ?? BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary,
          unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[500],
          selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle?.copyWith(fontWeight: FontWeight.w600) ?? const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle ?? const TextStyle(fontSize: 10),
          items: [
            _buildNavBarItem(iconData: Icons.home_outlined, activeIconData: Icons.home_rounded, label: 'Ana Sayfa', index: 0, theme: theme),
            _buildNavBarItem(iconData: Icons.search_rounded, activeIconData: Icons.search_off_rounded, label: 'Ara', index: 1, theme: theme, iconSize: 24),
            _buildNavBarItem(iconData: Icons.add_box_outlined, activeIconData: Icons.add_box_rounded, label: 'Yükle', index: 2, theme: theme, iconSize: 28, isSpecial: true, specialColor: Colors.redAccent[400]),
            _buildNavBarItem(iconData: Icons.notifications_none_rounded, activeIconData: Icons.notifications_rounded, label: 'Öneriler', index: 3, theme: theme),
            BottomNavigationBarItem(
                icon: _buildProfileIconForNavBar(isSelected: _aktifSayfaNo == 4, profileImageUrl: _aktifKullaniciProfilFotoUrl, theme: theme),
                label: 'Profil'
            ),
          ],
        ),
      ),
    );
  }

  // _buildNavBarItem ve _buildProfileIconForNavBar metodları bir önceki cevaptaki gibi kalabilir.
  BottomNavigationBarItem _buildNavBarItem({ required IconData iconData, required IconData activeIconData, required String label, required int index, required ThemeData theme, double? iconSize, bool isSpecial = false, Color? specialColor }) {
    final bool isSelected = _aktifSayfaNo == index;
    final Color itemColor = isSpecial
        ? (specialColor ?? theme.colorScheme.error)
        : (isSelected
        ? (theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary)
        : (theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[500]!));

    return BottomNavigationBarItem(
        icon: Icon(
            isSelected ? activeIconData : iconData,
            size: iconSize ?? (isSelected ? 26 : 23),
            color: itemColor
        ),
        label: label
    );
  }

  Widget _buildProfileIconForNavBar({ required bool isSelected, String? profileImageUrl, required ThemeData theme }) {
    const double avatarRadius = 12;
    final Color borderColor = isSelected ? (theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary) : Colors.grey[600]!;
    return Container(
      padding: const EdgeInsets.all(0.8),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor.withOpacity(isSelected ? 1.0 : 0.55), width: isSelected ? 2.0 : 1.4)
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty) ? NetworkImage(profileImageUrl) : null,
        backgroundColor: theme.colorScheme.surface.withOpacity(0.75),
        child: (profileImageUrl == null || profileImageUrl.isEmpty)
            ? Icon(Icons.person_outline_rounded, size: avatarRadius + 4, color: theme.iconTheme.color?.withOpacity(0.65))
            : null,
      ),
    );
  }
}