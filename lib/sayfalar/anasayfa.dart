// lib/sayfalar/anasayfa.dart
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Eğer _AnasayfaState içinde kullanacaksanız açın
// import 'package:pathbooks/servisler/yetkilendirmeservisi.dart'; // Eğer _AnasayfaState içinde kullanacaksanız açın
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/sayfalar/yukle.dart';
import 'package:pathbooks/sayfalar/akis.dart';
import 'package:pathbooks/sayfalar/ara.dart';

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

  @override
  void initState() {
    super.initState();
    _sayfaKumandasiAnasayfa = PageController(initialPage: _aktifSayfaNo);
    if (widget.aktifKullanici.fotoUrl != null && widget.aktifKullanici.fotoUrl!.isNotEmpty) {
      _aktifKullaniciProfilFotoUrl = widget.aktifKullanici.fotoUrl;
    }
  }

  @override
  void dispose() {
    _sayfaKumandasiAnasayfa?.dispose();
    super.dispose();
  }

  Widget _buildPageHeader(BuildContext context) {
    final theme = Theme.of(context);
    if (_aktifSayfaNo == 0) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          color: theme.appBarTheme.backgroundColor?.withOpacity(0.85) ?? Colors.black.withOpacity(0.6),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 8.0,
            left: 16,
            right: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterChip("Keşfet", _selectedFilterInAkis == 0, () {
                if (mounted) setState(() => _selectedFilterInAkis = 0);
              }, theme),
              const SizedBox(width: 10),
              _buildFilterChip("Takip Edilenler", _selectedFilterInAkis == 1, () {
                if (mounted) setState(() => _selectedFilterInAkis = 1);
              }, theme),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> _sayfalar = [
      Akis(selectedFilter: _selectedFilterInAkis),
      const AraSayfasi(),
      GonderiEkleSayfasi(),
      const Center(child: Text('Gelen Kutusu')),
      Profil(aktifKullanici: widget.aktifKullanici),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _sayfaKumandasiAnasayfa,
              onPageChanged: (int acilanSayfaNo) {
                if (mounted) setState(() => _aktifSayfaNo = acilanSayfaNo);
              },
              children: _sayfalar,
            ),
            _buildPageHeader(context),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ?? const Color(0xFF121212),
          border: Border(
            top: BorderSide(color: Colors.grey[800]!, width: 0.5),
          ),
        ),
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
          selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle, // Temadan al
          unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle, // Temadan al
          elevation: 0,
          items: [
            _buildNavBarItem(
              iconData: Icons.home_outlined,
              activeIconData: Icons.home_filled,
              label: 'Ana Sayfa',
              index: 0,
              theme: theme,
            ),
            _buildNavBarItem(
              iconData: Icons.search_outlined,
              activeIconData: Icons.search,
              label: 'Ara',
              index: 1,
              theme: theme,
            ),
            _buildNavBarItem( // Yükle ikonu
              iconData: Icons.add_circle_outline_rounded,
              activeIconData: Icons.add_circle_rounded,
              label: 'Yükle',
              index: 2,
              iconSize: 27,
              theme: theme,
              isSpecial: true, // Özel item olarak işaretle
              specialColor: Colors.red[600], // Kırmızı rengi ata
            ),
            _buildNavBarItem(
              iconData: Icons.inbox_outlined,
              activeIconData: Icons.inbox_rounded,
              label: 'Gelen Kutusu',
              index: 3,
              theme: theme,
            ),
            BottomNavigationBarItem(
              icon: _buildProfileIconForNavBar(
                isSelected: _aktifSayfaNo == 4,
                profileImageUrl: _aktifKullaniciProfilFotoUrl,
                theme: theme,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavBarItem({
    required IconData iconData,
    required IconData activeIconData,
    required String label,
    required int index,
    required ThemeData theme,
    double? iconSize,
    bool isSpecial = false,
    Color? specialColor,
  }) {
    bool isSelected = _aktifSayfaNo == index;
    Color itemColor;

    if (isSpecial) {
      itemColor = specialColor ?? (isSelected
          ? (theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary)
          : (theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[600]!));
    } else {
      itemColor = isSelected
          ? (theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary)
          : (theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[600]!);
    }
    // Not: BottomNavigationBar'ın selectedItemColor ve unselectedItemColor özellikleri
    // zaten ikon ve label renklerini yönetir. Buradaki itemColor ataması,
    // eğer daha granüler bir kontrol isteniyorsa veya isSpecial durumu için farklı bir mantık
    // gerekiyorsa faydalı olabilir. Aksi takdirde, doğrudan temanın renklerini kullanması için
    // color parametresini Icon widget'ından kaldırabilirsiniz.
    return BottomNavigationBarItem(
    icon: Icon(
    isSelected ? activeIconData : iconData,
    size: iconSize ?? (isSelected ? 25 : 23),
    // color: itemColor, // Temadan alması için bu satırı yorumlayabilirsiniz.
    ),
    label: label,
    );
  }

  Widget _buildProfileIconForNavBar({
    required bool isSelected,
    String? profileImageUrl,
    required ThemeData theme,
  }) {
    double avatarRadius = 12.5;
    Color borderColor = isSelected
        ? (theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary)
        : Colors.grey[700]!;

    return Container(
      padding: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withOpacity(isSelected ? 1.0 : 0.7),
          width: isSelected ? 1.8 : 1.2,
        ),
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
            ? NetworkImage(profileImageUrl)
            : null,
        backgroundColor: theme.colorScheme.surface,
        child: (profileImageUrl == null || profileImageUrl.isEmpty)
            ? Icon(
          Icons.person_outline_rounded,
          size: avatarRadius + 3,
          // color: isSelected // Renk temanın un/selectedItemColor'ından gelecektir.
          //     ? (theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary)
          //     : (theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[400]),
        )
            : null,
      ),
    );
  }
}