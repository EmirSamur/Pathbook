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
import 'package:pathbooks/sayfalar/gelen_kutusu_sayfasi.dart'; // Gelen Kutusu importu

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
  OneriModeli? _sonGosterilenDuyuruKutusuOnerisi; // Son gösterileni saklamak için
  bool _onerilerYukleniyor = true;
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
    _onerileriCekVeGoster();
  }

  Future<void> _onerileriCekVeGoster() async {
    if (!mounted) return;
    if (_gosterilecekOneri != null) return; // Zaten bir öneri gösteriliyorsa tekrar çekme

    setState(() {
      _onerilerYukleniyor = true;
      // _gosterilecekOneri = null; // Zaten yukarıdaki if ile kontrol ediliyor
    });
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
            _sonGosterilenDuyuruKutusuOnerisi = _gosterilecekOneri; // Son gösterileni sakla
            _onerilerYukleniyor = false;
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
        if (mounted) setState(() => _onerilerYukleniyor = false);
      }
    } catch (e) {
      print("Anasayfa - Öneriler çekilirken hata: $e");
      if (mounted) setState(() => _onerilerYukleniyor = false);
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
            axisAlignment: -1.0, // Üstten aşağı doğru açılma
            child: child,
          ),
        );
      },
      child: _gosterilecekOneri == null
          ? SizedBox.shrink(key: const ValueKey('bosDuyuruAnasayfa'))
          : Material(
        key: ValueKey(_gosterilecekOneri!.id),
        color: theme.cardTheme.color ?? theme.colorScheme.surfaceVariant,
        elevation: 2.0,
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
              top: MediaQuery.of(context).padding.top + 12.0,
              bottom: 12.0,
              left: 16.0,
              right: 16.0,
            ),
            constraints: BoxConstraints(minHeight: 70),
            child: Row(
              children: [
                if (_gosterilecekOneri!.gorselUrl != null && _gosterilecekOneri!.gorselUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        _gosterilecekOneri!.gorselUrl!,
                        width: 40, height: 40, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 30, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        _gosterilecekOneri!.ipucuMetni,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: (isSelected
                ? theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)
                : theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8))
            )?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final theme = Theme.of(context);
    if (_aktifSayfaNo == 0) {
      return Positioned(
        top: 0, left: 0, right: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDuyuruKutusu(context),
            Container(
              color: theme.appBarTheme.backgroundColor?.withOpacity(0.95) ?? Colors.black.withOpacity(0.8),
              padding: EdgeInsets.only(
                top: (_gosterilecekOneri == null) ? MediaQuery.of(context).padding.top + 8.0 : 8.0,
                bottom: 8.0, left: 16, right: 16,
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
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> _sayfalar = [
      Akis(selectedFilter: _selectedFilterInAkis),
      const AraSayfasi(),
      GonderiEkleSayfasi(),
      GelenKutusuSayfasi(sonOneri: _sonGosterilenDuyuruKutusuOnerisi), // Gelen Kutusu sayfası
      Profil(aktifKullanici: widget.aktifKullanici),
    ];

    // Header'ın yaklaşık yüksekliğini hesaplama (DİKKATLİCE AYARLANMALI)
    double topPaddingForPageView = 0;
    if (_aktifSayfaNo == 0) {
      double filterHeight = 56.0; // Filtrelerin yaklaşık yüksekliği (paddingler dahil)
      if (_gosterilecekOneri != null) {
        // Duyuru kutusu varken (yaklaşık 70-90px + status bar) + filtreler
        topPaddingForPageView = (MediaQuery.of(context).padding.top + 80.0) + filterHeight - MediaQuery.of(context).padding.top ; //Duyuru+filtre - status_bar (çünkü filtreler duyurunun altında)
      } else {
        // Sadece filtreler varken (status bar + filtreler)
        topPaddingForPageView = MediaQuery.of(context).padding.top + filterHeight;
      }
    }
    // En basit haliyle sabit bir padding vermek daha az sorunlu olabilir başlangıçta.
    // Ya da header'ı bir `PreferredSizeWidget` yapıp AppBar gibi kullanmak.
    // Şimdilik örnek bir padding:
    if (_aktifSayfaNo == 0) {
      topPaddingForPageView = 56.0; // Filtrelerin yüksekliği
      if (_gosterilecekOneri != null) {
        topPaddingForPageView += (MediaQuery.of(context).padding.top + 80); // Duyuru yüksekliği + status bar
      } else {
        topPaddingForPageView += MediaQuery.of(context).padding.top; // Sadece status bar
      }
    }


    return Scaffold(
      body: SafeArea( // SafeArea'yı Stack'in dışına almak daha iyi olabilir.
        top: false, // Header'lar kendi padding'ini yönetecek
        bottom: false,
        child: Stack(
          children: [
            Padding(
              // TODO: Bu top padding değerini kendi UI'nıza göre dikkatlice ayarlayın!
              // Duyuru kutusu ve filtrelerin toplam yüksekliği kadar olmalı.
              // Örnek: (_aktifSayfaNo == 0) ? 130.0 : 0 (Bu değerler sizin UI'ınıza göre değişir)
              padding: EdgeInsets.only(top: topPaddingForPageView),
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _sayfaKumandasiAnasayfa,
                onPageChanged: (int acilanSayfaNo) {
                  if (mounted) {
                    setState(() => _aktifSayfaNo = acilanSayfaNo);
                    if (acilanSayfaNo == 0) {
                      _onerileriCekVeGoster();
                    } else {
                      _duyuruTimer?.cancel();
                      if (_gosterilecekOneri != null && _aktifSayfaNo != 0) { // Sadece akış dışındaysa gizle
                        // Gelen kutusuna geçildiğinde _gosterilecekOneri null olmamalı ki
                        // _sonGosterilenDuyuruKutusuOnerisi doğru kalsın.
                        // Bu mantık biraz daha detaylı düşünülmeli.
                        // Şimdilik, diğer sayfalara geçince ana sayfadaki geçici duyuruyu kaldıralım.
                        // setState(() { _gosterilecekOneri = null; });
                      }
                    }
                  }
                },
                children: _sayfalar,
              ),
            ),
            _buildPageHeader(context),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        // ... (BottomNavigationBar kodu aynı) ...
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