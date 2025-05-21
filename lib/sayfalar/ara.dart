// lib/sayfalar/ara.dart
import 'dart:async'; // Timer için
import 'package:flutter/material.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/widgets/gonderi_karti.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';

class AraSayfasi extends StatefulWidget {
  const AraSayfasi({Key? key}) : super(key: key);

  @override
  _AraSayfasiState createState() => _AraSayfasiState();
}

class _AraSayfasiState extends State<AraSayfasi> {
  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;
  List<Gonderi> _tumGonderilerFiltresiz = []; // Firestore'dan gelen ham liste
  List<Gonderi> _filtrelenmisVeAranmisGonderiler = []; // Son gösterilecek liste

  bool _isLoading = true;
  String? _aktifKullaniciId;

  String _selectedTheme = "Doğa"; // Firestore'daki kategori adlarıyla eşleşmeli
  final List<String> _temalar = ["Doğa", "Tarih", "Kültür", "Yeme-İçme"];

  final Map<String, Map<String, dynamic>> _sortOptions = {
    "Son Paylaşılanlar": {"alan": "olusturulmaZamani", "azalan": true}, // "Son Yüklenenler" daha iyi olabilir
    "En Popülerler": {"alan": "begeniSayisi", "azalan": true},
    // "En Çok Yorum Alanlar": {"alan": "yorumSayisi", "azalan": true}, // Yorum sayısı için index gerekebilir
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
  final int _limit = 7; // Bir seferde çekilecek gönderi sayısı

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);
    _aktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    _selectedSortKey = _sortOptions.keys.first;

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
    _debounceTimer = Timer(const Duration(milliseconds: 500), () { // 500ms bekle
      if (!mounted) return;
      final yeniAramaSorgusu = _aramaController.text.trim();
      if (_aramaSorgusu != yeniAramaSorgusu) {
        setState(() {
          _aramaSorgusu = yeniAramaSorgusu;
        });
        _uygulaIstemciTarafiFiltrelemeVeArama(); // Sadece istemci tarafı filtrele
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300 &&
        !_dahaFazlaYukleniyor &&
        !_hepsiYuklendi &&
        !_isLoading) {
      _gonderileriYukle(ilkYukleme: false);
    }
  }

  Future<void> _gonderileriYukle({bool ilkYukleme = false}) async {
    if (!mounted || (ilkYukleme == false && _dahaFazlaYukleniyor) || (ilkYukleme == false && _hepsiYuklendi)) {
      return;
    }

    setState(() {
      if (ilkYukleme) {
        _isLoading = true;
        _tumGonderilerFiltresiz.clear(); // Ham listeyi temizle
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
        tema: _selectedTheme, // Firestore'daki kategori adıyla eşleşmeli
        siralamaAlani: siralamaAyari["alan"] as String,
        azalan: siralamaAyari["azalan"] as bool,
        limitSayisi: _limit,
        sonGorunenDoc: ilkYukleme ? null : _sonGorunenGonderiDoc,
      );

      List<Gonderi> gelenGonderiler = sonuc['gonderiler'] as List<Gonderi>;
      DocumentSnapshot? yeniSonDoc = sonuc['sonDoc'] as DocumentSnapshot?;

      if (mounted) {
        setState(() {
          _tumGonderilerFiltresiz.addAll(gelenGonderiler); // Ham listeye ekle
          _sonGorunenGonderiDoc = yeniSonDoc;

          if (gelenGonderiler.length < _limit || yeniSonDoc == null) {
            _hepsiYuklendi = true;
          }
          _uygulaIstemciTarafiFiltrelemeVeArama(); // Arama ve filtrelemeyi uygula
          _isLoading = false;
          _dahaFazlaYukleniyor = false;
        });
      }
    } catch (e, s) {
      print("ARA SAYFASI - HATA: $e\n$s");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dahaFazlaYukleniyor = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gönderiler yüklenemedi.")));
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
        final bool kategoriEslesiyor = gonderi.kategori.toLowerCase().contains(aramaSorgusuLower); // kategori zaten tema ile filtrelendi ama yine de kontrol edilebilir
        final bool konumEslesiyor = gonderi.konum?.toLowerCase().contains(aramaSorgusuLower) ?? false;
        final bool kullaniciAdiEslesiyor = gonderi.yayinlayanKullanici?.kullaniciAdi?.toLowerCase().contains(aramaSorgusuLower) ?? false;
        // Ek olarak başlık, etiketler vb. alanlar da eklenebilir.
        return aciklamaEslesiyor || kategoriEslesiyor || konumEslesiyor || kullaniciAdiEslesiyor;
      }).toList();
    }

    setState(() {
      _filtrelenmisVeAranmisGonderiler = sonGosterilecekler;
    });
  }


  Widget _buildTemaVeSiralamaFiltreBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 10.0), // Padding ayarlandı
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              currentValue: _selectedTheme,
              items: _temalar,
              onChanged: (String? newValue) {
                if (newValue != null && mounted && _selectedTheme != newValue) {
                  setState(() => _selectedTheme = newValue);
                  _gonderileriYukle(ilkYukleme: true);
                }
              },
              theme: theme,
              icon: Icons.category_outlined, // Kategori ikonu
            ),
          ),
          SizedBox(width: 8), // Boşluk azaltıldı
          Expanded(
            child: _buildDropdown(
              currentValue: _selectedSortKey,
              items: _sortOptions.keys.toList(),
              onChanged: (String? newValue) {
                if (newValue != null && mounted && _selectedSortKey != newValue) {
                  setState(() => _selectedSortKey = newValue);
                  _gonderileriYukle(ilkYukleme: true);
                }
              },
              theme: theme,
              icon: Icons.sort_by_alpha_rounded, // Sıralama ikonu
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
    IconData? icon,
  }) {
    return Container(
      height: 40, // Yükseklik biraz artırıldı
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0), // Padding ayarlandı
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface.withOpacity(0.08), // surface daha iyi
        borderRadius: BorderRadius.circular(10), // Daha modern
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: theme.cardColor, // Dropdown açıldığında arka plan
          isExpanded: true,
          icon: Icon(icon ?? Icons.keyboard_arrow_down_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.6), size: 22),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w500), // Font ayarlandı
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGonderiListesi(ThemeData theme) {
    if (_isLoading && _filtrelenmisVeAranmisGonderiler.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ));
    }

    if (_filtrelenmisVeAranmisGonderiler.isEmpty && !_isLoading) {
      String mesaj = "$_selectedTheme temasında gönderi bulunamadı.";
      if (_aramaSorgusu.isNotEmpty) {
        mesaj = "'$_aramaSorgusu' için $_selectedTheme temasında sonuç bulunamadı.";
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[500]),
              SizedBox(height: 16),
              Text(
                mesaj,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 16, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 0, bottom: 16.0),
      itemCount: _filtrelenmisVeAranmisGonderiler.length + (_dahaFazlaYukleniyor ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filtrelenmisVeAranmisGonderiler.length) {
          return _dahaFazlaYukleniyor
              ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: CircularProgressIndicator(strokeWidth: 2.0, color: theme.colorScheme.primary)))
              : SizedBox.shrink(); // Daha fazla yoksa ve yüklenmiyorsa boşluk bırakma
        }

        final gonderi = _filtrelenmisVeAranmisGonderiler[index];
        return ContentCard(
          key: ValueKey(gonderi.id + "_arama_karti_" + (_aktifKullaniciId ?? "")),
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
          onProfileTap: () { /* ... (Profil yönlendirmesi aynı) ... */ },
          onCommentTap: (gonderiId) { /* ... (Yorumlar yönlendirmesi) ... */ },
          onDetailsTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GonderiDetaySayfasi(gonderi: gonderi))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // initState içinde aktifKullaniciId zaten set ediliyor.
    // if (_aktifKullaniciId == null && _yetkilendirmeServisi.aktifKullaniciId != null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if(mounted) setState(() => _aktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId);
    //   });
    // }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0.2, // Çok hafif bir elevation
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), // Padding ayarlandı
          child: SizedBox(
            height: 40, // Yükseklik ayarlandı
            child: TextField(
              controller: _aramaController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15), // Font ayarlandı
              decoration: InputDecoration(
                hintText: "Konum, açıklama, kategori ara...", // Daha açıklayıcı hint
                hintStyle: TextStyle(color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.45), fontSize: 15),
                prefixIcon: Icon(Icons.search_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.6), size: 20), // Boyut ayarlandı
                suffixIcon: _aramaController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.6), size: 18), // Boyut ayarlandı
                  onPressed: () {
                    _aramaController.clear(); // Listener _onAramaDegisti'yi tetikleyecek
                  },
                  splashRadius: 18, // Boyut ayarlandı
                )
                    : null,
                border: InputBorder.none,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface.withOpacity(0.07), // Renk ayarlandı
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0), // İç padding
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none), // Radius ayarlandı
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.0)), // Radius ve border ayarlandı
              ),
              // onSubmitted anlık arama için kaldırıldı, _onAramaDegisti debounce ile hallediyor.
              // İstenirse eklenebilir:
              // onSubmitted: (value) => _uygulaIstemciTarafiFiltrelemeVeArama(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTemaVeSiralamaFiltreBar(theme),
          Expanded(child: _buildGonderiListesi(theme)),
        ],
      ),
    );
  }
}