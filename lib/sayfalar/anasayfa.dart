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
  // bool _onerilerYukleniyor = true; // Artık doğrudan kullanılmıyor gibi
  final Random _random = Random();
  Timer? _duyuruTimer;

  @override
  void initState() {
    super.initState();
    _sayfaKumandasiAnasayfa = PageController(initialPage: _aktifSayfaNo);
    if (widget.aktifKullanici.fotoUrl != null && widget.aktifKullanici.fotoUrl!.isNotEmpty) {
      _aktifKullaniciProfilFotoUrl = widget.aktifKullanici.fotoUrl;
    }
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _fetchSuggestionWhenNeeded(); // initState'te ve sayfa değişiminde çağrılacak
  }

  Future<void> _fetchSuggestionWhenNeeded() async {
    if (!mounted) return;

    if (_aktifSayfaNo == 0) { // Sadece Akış sayfasındayken
      if (_gosterilecekOneri == null) { // Ve zaten bir öneri gösterilmiyorsa
        // setState(() { _onerilerYukleniyor = true; }); // İsteğe bağlı
        _duyuruTimer?.cancel();
        try {
          if (_onerilerListesi.isEmpty) {
            _onerilerListesi = await _firestoreServisi.tumOnerileriGetir();
          }
          if (_onerilerListesi.isNotEmpty) {
            final int randomIndex = _random.nextInt(_onerilerListesi.length);
            if (mounted) {
              setState(() {
                _gosterilecekOneri = _onerilerListesi[randomIndex];
                _sonGosterilenDuyuruKutusuOnerisi = _gosterilecekOneri;
                // _onerilerYukleniyor = false;
              });
              _duyuruTimer = Timer(const Duration(seconds: 5), () {
                if (mounted) {
                  setState(() {
                    _gosterilecekOneri = null;
                  });
                }
              });
            }
          } else {
            // if (mounted) setState(() => _onerilerYukleniyor = false);
          }
        } catch (e) {
          print("Anasayfa - Öneriler çekilirken hata: $e");
          // if (mounted) setState(() => _onerilerYukleniyor = false);
        }
      }
    } else { // Akış sayfasında değilsek, mevcut öneriyi ve timer'ı temizle
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

  Widget _buildDuyuruKutusu(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.vertical,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: _gosterilecekOneri == null
          ? SizedBox.shrink(key: const ValueKey('bosDuyuruAnasayfa'))
          : Material(
        key: ValueKey(_gosterilecekOneri!.id),
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceVariant,
        elevation: 1.0, // Hafif bir gölge
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
              top: MediaQuery.of(context).padding.top + 10.0, // Status bar + iç padding
              bottom: 10.0,
              left: 16.0,
              right: 16.0,
            ),
            constraints: BoxConstraints(minHeight: 60), // Biraz daha kompakt
            child: Row(
              children: [
                if (_gosterilecekOneri!.gorselUrl != null && _gosterilecekOneri!.gorselUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: Image.network(
                        _gosterilecekOneri!.gorselUrl!,
                        width: 36, height: 36, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 28, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1),
                      Text(
                        _gosterilecekOneri!.ipucuMetni,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 11),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, ThemeData theme) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8), // Yüksekliği ayarlayabilirsiniz
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: (isSelected
                ? theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimary) // labelMedium
                : theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 12) // Biraz daha küçük
            )?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
          ),
        ),
      ),
    );
  }

  // Bu metot artık Positioned döndürmüyor, direkt Column'un bir parçası olacak.
  Widget _buildDynamicPageHeader(BuildContext context) {
    final theme = Theme.of(context);
    // Bu Column, _buildDuyuruKutusu ve filtreleri içerir.
    // Kendi padding'lerini ve yüksekliklerini yönetirler.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDuyuruKutusu(context), // Bu, içinde status bar için padding içeriyor
        Container( // Filtreler
          color: theme.appBarTheme.backgroundColor?.withOpacity(0.95) ?? Colors.black.withOpacity(0.85),
          padding: EdgeInsets.only(
            // Eğer _buildDuyuruKutusu görünmüyorsa (SizedBox.shrink ise),
            // filtrelerin üst padding'i status bar'ı içermeli.
            // _buildDuyuruKutusu göründüğünde, o zaten status bar'ı hallettiği için
            // filtrelerin sadece kendi iç padding'i (örn: 8.0) yeterli.
            top: (_gosterilecekOneri == null) ? MediaQuery.of(context).padding.top + 8.0 : 8.0,
            bottom: 8.0,
            left: 16.0,
            right: 16.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterChip("Keşfet", _selectedFilterInAkis == 0, () => setState(() => _selectedFilterInAkis = 0), theme),
              const SizedBox(width: 10),
              _buildFilterChip("Takip Edilenler", _selectedFilterInAkis == 1, () => setState(() => _selectedFilterInAkis = 1), theme),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> _sayfalar = [
      Akis(selectedFilter: _selectedFilterInAkis), // Akis'e ekstra padding parametresi GEÇİLMİYOR
      const AraSayfasi(),
      GonderiEkleSayfasi(),
      GelenKutusuSayfasi(sonOneri: _sonGosterilenDuyuruKutusuOnerisi),
      Profil(aktifKullanici: widget.aktifKullanici),
    ];

    return Scaffold(
      // AppBar kullanmıyoruz, header'ı kendimiz yönetiyoruz.
      // SafeArea'yı burada kullanmak yerine, _buildDuyuruKutusu ve filtreler
      // kendi status bar padding'lerini yönetiyor.
      body: Column( // Ana gövde artık bir Column
        children: [
          // 1. Dinamik Header (Sadece Akış sayfasında görünür)
          if (_aktifSayfaNo == 0)
            _buildDynamicPageHeader(context),

          // 2. Sayfa İçeriği (Geri kalan tüm alanı kaplar)
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(), // Dikey kaydırmayı engelle
              controller: _sayfaKumandasiAnasayfa,
              onPageChanged: (int acilanSayfaNo) {
                if (mounted) {
                  setState(() {
                    _aktifSayfaNo = acilanSayfaNo;
                  });
                  _fetchSuggestionWhenNeeded(); // Sayfa değiştiğinde öneri durumunu güncelle/temizle
                }
              },
              children: _sayfalar,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor ?? const Color(0xFF121212),
            border: Border(top: BorderSide(color: Colors.grey[900]!, width: 0.5))),
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
          unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[600],
          selectedFontSize: theme.bottomNavigationBarTheme.selectedLabelStyle?.fontSize ?? 11,
          unselectedFontSize: theme.bottomNavigationBarTheme.unselectedLabelStyle?.fontSize ?? 10,
          items: [
            _buildNavBarItem(iconData: Icons.home_outlined, activeIconData: Icons.home_filled, label: 'Ana Sayfa', index: 0, theme: theme),
            _buildNavBarItem(iconData: Icons.search_outlined, activeIconData: Icons.search, label: 'Ara', index: 1, theme: theme),
            _buildNavBarItem(iconData: Icons.add_circle_outline_rounded, activeIconData: Icons.add_circle_rounded, label: 'Yükle', index: 2, iconSize: 27, theme: theme, isSpecial: true, specialColor: Colors.red[600]),
            _buildNavBarItem(iconData: Icons.inbox_outlined, activeIconData: Icons.inbox_rounded, label: 'Gelen Kutusu', index: 3, theme: theme),
            BottomNavigationBarItem(icon: _buildProfileIconForNavBar(isSelected: _aktifSayfaNo == 4, profileImageUrl: _aktifKullaniciProfilFotoUrl, theme: theme), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavBarItem({ required IconData iconData, required IconData activeIconData, required String label, required int index, required ThemeData theme, double? iconSize, bool isSpecial = false, Color? specialColor }) {
    bool isSelected = _aktifSayfaNo == index;
    return BottomNavigationBarItem(icon: Icon(isSelected ? activeIconData : iconData, size: iconSize ?? (isSelected ? 25 : 23)), label: label);
  }

  Widget _buildProfileIconForNavBar({ required bool isSelected, String? profileImageUrl, required ThemeData theme }) {
    double avatarRadius = 12.5;
    Color borderColor = isSelected ? (theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary) : Colors.grey[700]!;
    return Container(
      padding: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor.withOpacity(isSelected ? 1.0 : 0.7), width: isSelected ? 1.8 : 1.2)),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty) ? NetworkImage(profileImageUrl) : null,
        backgroundColor: theme.colorScheme.surface,
        child: (profileImageUrl == null || profileImageUrl.isEmpty) ? Icon(Icons.person_outline_rounded, size: avatarRadius + 3) : null,
      ),
    );
  }
}