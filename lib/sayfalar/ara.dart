// lib/sayfalar/ara.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modeli import edildi
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/widgets/gonderi_karti.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';
import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart'; // YorumlarSayfasi import edildi

class AraSayfasi extends StatefulWidget {
  const AraSayfasi({Key? key}) : super(key: key);

  @override
  _AraSayfasiState createState() => _AraSayfasiState();
}

class _AraSayfasiState extends State<AraSayfasi> {
  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;
  List<Gonderi> _tumGonderilerFiltresiz = [];
  List<Gonderi> _filtrelenmisVeAranmisGonderiler = [];

  bool _isLoading = true;
  String? _aktifKullaniciId;

  String _selectedTheme = "Doğa";
  final List<String> _temalar = ["Tümü", "Doğa", "Tarih", "Kültür", "Yeme-İçme"];

  // YENİ: Ülke ve Şehir Filtreleri için state'ler
  String _selectedCountry = "Tümü";
  List<String> _ulkelerListesi = ["Tümü", "Türkiye", "Almanya", "Fransa", "İtalya", "İspanya", "ABD", "Japonya"]; // Örnek genişletilmiş liste
  String _selectedCity = "Tümü";
  Map<String, List<String>> _sehirlerMap = {
    "Türkiye": ["Tümü", "İstanbul", "Ankara", "İzmir", "Antalya", "Bursa", "Adana", "Van", "Trabzon"],
    "Almanya": ["Tümü", "Berlin", "Münih", "Hamburg", "Frankfurt", "Köln"],
    "Fransa": ["Tümü", "Paris", "Marsilya", "Lyon", "Nice", "Strazburg"],
    "İtalya": ["Tümü", "Roma", "Milano", "Venedik", "Floransa", "Napoli"],
    "İspanya": ["Tümü", "Madrid", "Barselona", "Sevilla", "Valensiya", "Granada"],
    "ABD": ["Tümü", "New York", "Los Angeles", "Chicago", "San Francisco", "Miami"],
    "Japonya": ["Tümü", "Tokyo", "Kyoto", "Osaka", "Hiroşima"],
  };
  List<String> _aktifSehirListesi = ["Tümü"];

  final Map<String, Map<String, dynamic>> _sortOptions = {
    "Son Paylaşılanlar": {"alan": "olusturulmaZamani", "azalan": true},
    "En Popülerler": {"alan": "begeniSayisi", "azalan": true},
    "En Eskiler": {"alan": "olusturulmaZamani", "azalan": false},
  };


  late String _selectedSortKey;

  TextEditingController _aramaController = TextEditingController();
  String _aramaSorgusu = "";
  Timer? _debounceTimer;

  DocumentSnapshot? _sonGorunenGonderiDoc;
  bool _dahaFazlaYukleniyor = false;
  bool _hepsiYuklendi = false;
  final ScrollController _scrollController = ScrollController();
  final int _limit = 7; // Sayfalama için gönderi limiti

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);
    _aktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    _selectedSortKey = _sortOptions.keys.first;
    _updateAktifSehirListesi();

    _aramaController.addListener(_onAramaDegisti);
    _scrollController.addListener(_onScroll);

    _gonderileriYukle(ilkYukleme: true);
  }

  @override
  void dispose() {
    _aramaController.removeListener(_onAramaDegisti);
    _aramaController.dispose();
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onAramaDegisti() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () { // Gecikme süresi ayarlandı
      if (!mounted) return;
      final yeniAramaSorgusu = _aramaController.text.trim();
      if (_aramaSorgusu != yeniAramaSorgusu) {
        setState(() {
          _aramaSorgusu = yeniAramaSorgusu;
        });
        // Firestore sorgusunu doğrudan tetiklemek yerine, mevcut liste üzerinde filtreleme
        // Firestore'dan veri zaten çekilmiş olduğu için bu daha hızlı olacaktır.
        // Eğer her arama için Firestore'a gitmek isterseniz _gonderileriYukle(ilkYukleme: true) çağrılmalı.
        _uygulaIstemciTarafiFiltrelemeVeArama();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 && // Eşik %90'a çekildi
        !_dahaFazlaYukleniyor &&
        !_hepsiYuklendi &&
        !_isLoading) {
      _gonderileriYukle(ilkYukleme: false);
    }
  }

  void _updateAktifSehirListesi() {
    if (_selectedCountry == "Tümü" || !_sehirlerMap.containsKey(_selectedCountry)) {
      _aktifSehirListesi = ["Tümü"];
    } else {
      _aktifSehirListesi = List.from(_sehirlerMap[_selectedCountry]!); // Kopyasını al
    }
    if (!_aktifSehirListesi.contains(_selectedCity)) {
      _selectedCity = "Tümü";
    }
  }

  Future<void> _gonderileriYukle({bool ilkYukleme = false}) async {
    if (!mounted || (ilkYukleme == false && _dahaFazlaYukleniyor) || (ilkYukleme == false && _hepsiYuklendi)) {
      return;
    }

    setState(() {
      if (ilkYukleme) {
        _isLoading = true;
        _tumGonderilerFiltresiz.clear();
        _filtrelenmisVeAranmisGonderiler.clear();
        _sonGorunenGonderiDoc = null;
        _hepsiYuklendi = false;
      } else {
        _dahaFazlaYukleniyor = true;
      }
    });

    try {
      final siralamaAyari = _sortOptions[_selectedSortKey]!;
      Map<String, dynamic> sonuc = await _firestoreServisi.gonderileriGetirFiltreleSirala(
        // aramaMetni: _aramaSorgusu.isNotEmpty ? _aramaSorgusu : null, // Firestore sorgusuna şimdilik eklemiyoruz
        kategori: _selectedTheme == "Tümü" ? null : _selectedTheme,
        ulke: _selectedCountry == "Tümü" ? null : _selectedCountry,
        sehir: _selectedCity == "Tümü" ? null : _selectedCity,

        siralamaAlani: siralamaAyari["alan"] as String,
        azalan: siralamaAyari["azalan"] as bool,
        limitSayisi: _limit,
        sonGorunenDoc: ilkYukleme ? null : _sonGorunenGonderiDoc,
      );

      List<Gonderi> gelenGonderiler = sonuc['gonderiler'] as List<Gonderi>;
      DocumentSnapshot? yeniSonDoc = sonuc['sonDoc'] as DocumentSnapshot?;

      if (mounted) {
        setState(() {
          _tumGonderilerFiltresiz.addAll(gelenGonderiler);
          _sonGorunenGonderiDoc = yeniSonDoc;
          _hepsiYuklendi = gelenGonderiler.length < _limit || yeniSonDoc == null;
          _uygulaIstemciTarafiFiltrelemeVeArama();
          _isLoading = false;
          _dahaFazlaYukleniyor = false;
        });
      }
    } catch (e, s) {
      print("ARA SAYFASI - GÖNDERİ YÜKLEME HATASI: $e\n$s");
      if (mounted) {
        setState(() { _isLoading = false; _dahaFazlaYukleniyor = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gönderiler yüklenirken bir hata oluştu.")));
      }
    }
  }

  void _uygulaIstemciTarafiFiltrelemeVeArama() {
    if (!mounted) return;
    List<Gonderi> sonGosterilecekler = List.from(_tumGonderilerFiltresiz);

    if (_aramaSorgusu.isNotEmpty) {
      final String aramaSorgusuLower = _aramaSorgusu.toLowerCase();
      sonGosterilecekler = sonGosterilecekler.where((gonderi) {
        final bool aciklamaEslesiyor = gonderi.aciklama.toLowerCase().contains(aramaSorgusuLower);
        final bool kategoriEslesiyor = gonderi.kategori.toLowerCase().contains(aramaSorgusuLower);
        final bool konumEslesiyor = gonderi.konum?.toLowerCase().contains(aramaSorgusuLower) ?? false;
        final bool ulkeEslesiyor = gonderi.ulke?.toLowerCase().contains(aramaSorgusuLower) ?? false;
        final bool sehirEslesiyor = gonderi.sehir?.toLowerCase().contains(aramaSorgusuLower) ?? false;
        final bool kullaniciAdiEslesiyor = gonderi.yayinlayanKullanici?.kullaniciAdi?.toLowerCase().contains(aramaSorgusuLower) ?? false;
        return aciklamaEslesiyor || kategoriEslesiyor || konumEslesiyor || kullaniciAdiEslesiyor || ulkeEslesiyor || sehirEslesiyor;
      }).toList();
    }
    setState(() {
      _filtrelenmisVeAranmisGonderiler = sonGosterilecekler;
    });
  }

  Widget _buildFiltreBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 10.0),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildDropdown(currentValue: _selectedTheme, items: _temalar, onChanged: (val) => _filtreDegisti("tema", val), theme: theme, icon: Icons.category_outlined, hint: "Tema")),
              SizedBox(width: 8),
              Expanded(child: _buildDropdown(currentValue: _selectedCountry, items: _ulkelerListesi, onChanged: (val) => _filtreDegisti("ulke", val), theme: theme, icon: Icons.public_outlined, hint: "Ülke")),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDropdown(currentValue: _selectedCity, items: _aktifSehirListesi, onChanged: (val) => _filtreDegisti("sehir", val), theme: theme, icon: Icons.location_city_rounded, hint: "Şehir")),
              SizedBox(width: 8),
              Expanded(child: _buildDropdown(currentValue: _selectedSortKey, items: _sortOptions.keys.toList(), onChanged: (val) => _filtreDegisti("siralama", val), theme: theme, icon: Icons.sort_rounded, hint: "Sırala")),
            ],
          ),
        ],
      ),
    );
  }

  void _filtreDegisti(String filtreTipi, String? newValue) {
    if (newValue == null || !mounted) return;
    bool veriYenidenYuklensin = false;

    switch (filtreTipi) {
      case "tema": if (_selectedTheme != newValue) { _selectedTheme = newValue; veriYenidenYuklensin = true; } break;
      case "siralama": if (_selectedSortKey != newValue) { _selectedSortKey = newValue; veriYenidenYuklensin = true; } break;
      case "ulke":
        if (_selectedCountry != newValue) {
          _selectedCountry = newValue;
          _updateAktifSehirListesi();
          // Eğer _selectedCity yeni _aktifSehirListesi içinde yoksa, onu "Tümü" yap.
          // _updateAktifSehirListesi bunu zaten yapıyor.
          _selectedCity = _aktifSehirListesi.contains(_selectedCity) ? _selectedCity : "Tümü";
          veriYenidenYuklensin = true;
        }
        break;
      case "ilçe":
        if (_selectedCountry != newValue) {
          _selectedCountry = newValue;
          _updateAktifSehirListesi();
          // Eğer _selectedCity yeni _aktifSehirListesi içinde yoksa, onu "Tümü" yap.
          // _updateAktifSehirListesi bunu zaten yapıyor.
          _selectedCity = _aktifSehirListesi.contains(_selectedCity) ? _selectedCity : "Tümü";
          veriYenidenYuklensin = true;
        }
        break;
      case "sehir": if (_selectedCity != newValue) { _selectedCity = newValue; veriYenidenYuklensin = true; } break;
    }

    if (veriYenidenYuklensin) {
      setState(() {}); // Dropdown'ın güncel değeri göstermesi için
      _gonderileriYukle(ilkYukleme: true);
    }
  }

  Widget _buildDropdown({
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    String? hint,
    IconData? icon,
  }) {
    // Eğer currentValue items listesinde yoksa, "Tümü" varsa onu, yoksa ilk elemanı seç
    String validCurrentValue = currentValue;
    if (!items.contains(currentValue)) {
      if (items.contains("Tümü")) {
        validCurrentValue = "Tümü";
      } else if (items.isNotEmpty) {
        validCurrentValue = items.first;
      }
      // Eğer items boşsa, currentValue olduğu gibi kalır (bu durum olmamalı)
    }

    return Container(
      height: 38,
      padding: EdgeInsets.only(left: icon != null ? 8 : 12, right: 6), // İkon varsa sol padding'i ayarla
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validCurrentValue,
          hint: hint != null ? Text(hint, style: TextStyle(color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.5), fontSize: 12)) : null,
          dropdownColor: theme.cardColor,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.6), size: 20),
          selectedItemBuilder: (BuildContext context) { // Seçili elemanın nasıl görüneceği
            return items.map<Widget>((String item) {
              return Row(
                children: [
                  if (icon != null) Icon(icon, size: 16, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.7)),
                  if (icon != null) SizedBox(width: 6),
                  Expanded(child: Text(item, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 12.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                ],
              );
            }).toList();
          },
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)), // Dropdown menü içindeki stil
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGonderiListesi(ThemeData theme) {
    if (_isLoading && _filtrelenmisVeAranmisGonderiler.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }
    if (_filtrelenmisVeAranmisGonderiler.isEmpty && !_isLoading) {
      String mesaj = "$_selectedTheme temasında gönderi bulunamadı.";
      if(_selectedCountry != "Tümü") mesaj = "$_selectedCountry, $_selectedTheme temasında gönderi bulunamadı.";
      if(_selectedCity != "Tümü") mesaj = "$_selectedCity, $_selectedCountry, $_selectedTheme temasında gönderi bulunamadı.";

      if (_aramaSorgusu.isNotEmpty) {
        mesaj = "'$_aramaSorgusu' için sonuç bulunamadı.";
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.travel_explore_rounded, size: 50, color: Colors.grey[500]),
            SizedBox(height: 16),
            Text(mesaj, textAlign: TextAlign.center, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 15, height: 1.4)),
          ]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0), // Üst padding eklendi
      itemCount: _filtrelenmisVeAranmisGonderiler.length + (_dahaFazlaYukleniyor ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filtrelenmisVeAranmisGonderiler.length) {
          return _dahaFazlaYukleniyor
              ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: CircularProgressIndicator(strokeWidth: 2.0, color: theme.colorScheme.primary)))
              : SizedBox.shrink();
        }
        final gonderi = _filtrelenmisVeAranmisGonderiler[index];
        return ContentCard(
          key: ValueKey("${gonderi.id}_ara_${_aktifKullaniciId ?? UniqueKey().toString()}"), // Daha benzersiz key
          gonderiId: gonderi.id,
          resimUrls: gonderi.resimUrls,
          profileUrl: gonderi.yayinlayanKullanici?.fotoUrl ?? "",
          userName: gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Pathbook",
          location: "${gonderi.sehir ?? ''}${gonderi.sehir != null && gonderi.ulke != null ? ', ' : ''}${gonderi.ulke ?? ''}".replaceAll(RegExp(r'^, |,$'), '').trim().isNotEmpty
              ? "${gonderi.sehir ?? ''}${gonderi.sehir != null && gonderi.ulke != null ? ', ' : ''}${gonderi.ulke ?? ''}"
              : gonderi.konum ?? "", // Eğer şehir/ülke varsa onları, yoksa konumu göster
          description: gonderi.aciklama,
          category: gonderi.kategori,
          initialLikeCount: gonderi.begeniSayisi,
          initialCommentCount: gonderi.yorumSayisi,
          aktifKullaniciId: _aktifKullaniciId ?? "",
          onProfileTap: () {
            if (gonderi.yayinlayanKullanici != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Profil(aktifKullanici: gonderi.yayinlayanKullanici!)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kullanıcı profili yüklenemedi.")));
            }
          },
          onCommentTap: (gonderiId) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => YorumlarSayfasi(gonderiId: gonderiId)));
          },
          onDetailsTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GonderiDetaySayfasi(gonderi: gonderi))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0.3, // Hafif bir elevation
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _aramaController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14.5), // Font boyutu
              decoration: InputDecoration(
                hintText: "Açıklama, kategori, konum, şehir, ülke...", // Hint güncellendi
                hintStyle: TextStyle(color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.5), fontSize: 14.5),
                prefixIcon: Icon(Icons.search_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.65), size: 19), // İkon boyutu
                suffixIcon: _aramaController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.65), size: 19),
                  onPressed: () => _aramaController.clear(), // Listener tetikleyecek
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                )
                    : null,
                border: InputBorder.none,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface.withOpacity(0.1),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4), width: 1.0)),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFiltreBar(theme),
          Expanded(child: _buildGonderiListesi(theme)),
        ],
      ),
    );
  }
}