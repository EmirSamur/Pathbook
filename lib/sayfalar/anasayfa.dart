// lib/sayfalar/anasayfa.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
// import 'package:pathbooks/modeller/gonderi.dart'; // Anasayfa doğrudan Gonderi ile ilgilenmiyor
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
// import 'package:pathbooks/servisler/firestoreseervisi.dart'; // Anasayfa doğrudan Firestore ile ilgilenmiyor
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/sayfalar/yukle.dart';
import 'package:pathbooks/sayfalar/akis.dart';
import 'package:pathbooks/sayfalar/ara.dart'; // ARA SAYFASINI İMPORT EDİN
// import 'package:pathbooks/widgets/gonderi_karti.dart'; // Anasayfa doğrudan bu widget'ı kullanmıyor
// import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart'; // Anasayfa doğrudan bu sayfayı kullanmıyor

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

  // --- Akis Sayfası Filtre State'i ---
  int _selectedFilterInAkis = 0; // 0: Önerilen, 1: Senin için
  // --- Akis Sayfası Filtre State'i Bitiş ---

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

  // Ana Sayfa (Akis) için başlık ve filtreler
  Widget _buildPageHeader(BuildContext context) {
    if (_aktifSayfaNo == 0) { // SADECE ANA SAYFA (AKİS - Index 0) İÇİN GÖSTER
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.4), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 1.0], // Gradyan yayılımı
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 15, // Durum çubuğu için güvenli alan + ek boşluk
            bottom: 15.0, // Filtrelerin altında boşluk
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterChip("Önerilen", _selectedFilterInAkis == 0, () {
                if (mounted) setState(() => _selectedFilterInAkis = 0);
                // Akis widget'ı bu değişikliği selectedFilter prop'u üzerinden alacak
                // ve kendi içinde didUpdateWidget ile gönderi listesini güncelleyecek.
                print("Ana Sayfa Filtresi: Önerilen (Değer: $_selectedFilterInAkis)");
              }),
              SizedBox(width: 12),
              _buildFilterChip("Senin için", _selectedFilterInAkis == 1, () {
                if (mounted) setState(() => _selectedFilterInAkis = 1);
                print("Ana Sayfa Filtresi: Senin için (Değer: $_selectedFilterInAkis)");
              }),
            ],
          ),
        ),
      );
    }
    // Diğer sayfalar (Ara, Yükle, Gelen Kutusu, Profil) için Anasayfa'dan bir header gelmeyecek.
    // Bu sayfalar kendi başlıklarını (AppBar vb.) kendileri yönetebilir.
    return SizedBox.shrink();
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25), // Tamamen yuvarlak kenarlar
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Genel arka plan rengi
      body: SafeArea( // Üst ve alt sistem çubukları için genel SafeArea
        top: false,    // Header (Positioned) kendi padding'ini yönetiyor
        bottom: false,   // BottomAppBar zaten en altta ve kendi yüksekliğini yönetiyor
        child: Stack( // Sayfa içeriği ve header'ı üst üste bindirmek için
          children: [
            // Ana Sayfa İçeriği (PageView)
            PageView(
              physics: NeverScrollableScrollPhysics(), // Kaydırarak sayfa geçişini engelle
              controller: _sayfaKumandasiAnasayfa,
              onPageChanged: (int acilanSayfaNo) {
                if (mounted) setState(() => _aktifSayfaNo = acilanSayfaNo);
              },
              children: <Widget>[
                // Index 0: Ana Sayfa (Akis)
                // Akis widget'ına seçilen filtreyi parametre olarak iletiyoruz.
                Akis(selectedFilter: _selectedFilterInAkis),

                // Index 1: Ara Sayfası
                const AraSayfasi(), // Sizin oluşturduğunuz Pinterest benzeri sayfa

                // Index 2: Yükle Sayfası
                GonderiEkleSayfasi(),

                // Index 3: Gelen Kutusu
                Center(child: Text('Gelen Kutusu', style: TextStyle(fontSize: 20, color: Colors.white))),

                // Index 4: Profil Sayfası
                Profil(aktifKullanici: widget.aktifKullanici),
              ],
            ),

            // Üst Başlık (Sadece Akis sayfası aktifken görünecek)
            _buildPageHeader(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _sayfaKumandasiAnasayfa?.jumpToPage(2); // Animasyonsuz geçiş
          if (mounted && _aktifSayfaNo != 2) setState(() => _aktifSayfaNo = 2);
        },
        child: Icon(Icons.add, color: Colors.white, size: 30),
        backgroundColor: Color(0xFFFE2C55), // Canlı kırmızı (TikTok kırmızısı)
        elevation: 2.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Color(0xFF121212), // Koyu alt bar rengi
        child: Container(
          height: kBottomNavigationBarHeight, // Standart yükseklik
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildBottomNavItem(iconData: Icons.home_filled, label: 'Ana Sayfa', index: 0),
              _buildBottomNavItem(iconData: Icons.search, label: 'Ara', index: 1),
              SizedBox(width: 40), // FAB için boşluk
              _buildBottomNavItem(iconData: Icons.chat_bubble_outline_rounded, label: 'Gelen Kutusu', index: 3),
              _buildBottomNavItem(isProfile: true, label: 'Ben', index: 4, profileImageUrl: _aktifKullaniciProfilFotoUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    IconData? iconData,
    required String label,
    required int index,
    bool isProfile = false,
    String? profileImageUrl
  }) {
    bool isSelected = _aktifSayfaNo == index;
    Color selectedColor = Colors.white;
    Color unselectedColor = Colors.grey[700]!; // Biraz daha belirgin bir gri
    Color itemColor = isSelected ? selectedColor : unselectedColor;
    FontWeight itemFontWeight = isSelected ? FontWeight.bold : FontWeight.normal;

    // Profil ikonu için sabit bir radius belirleyelim
    double avatarRadius = 12.0;
    // Diğer ikonlar için seçili ve seçili olmayan durumlarına göre boyut
    double normalIconSize = isSelected ? 26 : 24;

    Widget iconWidget;
    if (isProfile) {
      iconWidget = Container(
        padding: EdgeInsets.all(isSelected ? 0 : 1.5), // Seçili değilken border efekti
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[700]!,
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: CircleAvatar(
          radius: avatarRadius,
          backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty) ? NetworkImage(profileImageUrl) : null,
          backgroundColor: Colors.grey[800], // Fotoğraf yoksa arka plan
          child: (profileImageUrl == null || profileImageUrl.isEmpty)
              ? Icon(Icons.person_outline, size: 14, color: isSelected ? Colors.black : Colors.grey[400]) // Seçiliyse iç ikon siyah
              : null,
        ),
      );
    } else {
      iconWidget = Icon(iconData, color: itemColor, size: normalIconSize);
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_aktifSayfaNo == index) return;
          _sayfaKumandasiAnasayfa?.jumpToPage(index);
          if (mounted) setState(() => _aktifSayfaNo = index);
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: kBottomNavigationBarHeight, // Her bir item'ın yüksekliği BottomAppBar ile aynı
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortala
            mainAxisSize: MainAxisSize.min, // Minimum yer kapla
            children: [
              iconWidget,
              SizedBox(height: 1.5), // İkon ve metin arası boşluk
              Text(
                label,
                style: TextStyle(color: itemColor, fontSize: 9.5, fontWeight: itemFontWeight),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}