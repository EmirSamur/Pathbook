// lib/sayfalar/ara.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/widgets/gonderi_karti.dart'; // VEYA content_card.dart (doğru dosya adı)
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart'; // YENİ IMPORT

class AraSayfasi extends StatefulWidget {
  const AraSayfasi({Key? key}) : super(key: key);

  @override
  _AraSayfasiState createState() => _AraSayfasiState();
}

class _AraSayfasiState extends State<AraSayfasi> {
  // ... (initState, _gonderileriYukle, _gosterilecekGonderiler, dispose, build metodunun başı, _buildTemaVeSiralamaFiltreBar, _buildDropdown metodları aynı kalacak)
  // Bu metodların içeriğini bir önceki cevaptan veya kendi dosyanızdan alabilirsiniz.
  // Aşağıda sadece _buildGonderiListesi metodu güncelleniyor.

  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;
  List<Gonderi> _gonderiler = [];
  bool _isLoading = true;
  String? _aktifKullaniciId;

  String _selectedTheme = "Doğa";
  final List<String> _temalar = ["Doğa", "Tarih", "Kültür", "Yeme-İçme"];

  final Map<String, Map<String, dynamic>> _sortOptions = {
    "Son Yüklenenler": {"alan": "olusturulmaZamani", "azalan": true},
    "En Popülerler": {"alan": "begeniSayisi", "azalan": true},
    "En Çok Yorum Alanlar": {"alan": "yorumSayisi", "azalan": true},
    "En Eskiler": {"alan": "olusturulmaZamani", "azalan": false},
  };
  late String _selectedSortKey;

  TextEditingController _aramaController = TextEditingController();
  String _aramaSorgusu = "";

  DocumentSnapshot? _sonGorunenGonderiDoc;
  bool _dahaFazlaYukleniyor = false;
  bool _hepsiYuklendi = false;
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);
    _aktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;

    _selectedSortKey = _sortOptions.keys.first;
    _gonderileriYukle(ilkYukleme: true);

    _aramaController.addListener(() {
      if (mounted && _aramaSorgusu != _aramaController.text) {
        setState(() {
          _aramaSorgusu = _aramaController.text;
        });
        // Arama sorgusu değiştiğinde yeniden yükleme yapabiliriz (opsiyonel, anlık filtreleme için)
        // _gonderileriYukle(ilkYukleme: true);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
          !_dahaFazlaYukleniyor &&
          !_hepsiYuklendi &&
          !_isLoading) {
        print("AraSayfasi: Scroll sonuna yaklaşıldı, daha fazla gönderi yükleniyor...");
        _gonderileriYukle(ilkYukleme: false);
      }
    });
  }

  Future<void> _gonderileriYukle({bool ilkYukleme = false}) async {
    if (!mounted || (ilkYukleme == false && _dahaFazlaYukleniyor) || (ilkYukleme == false && _hepsiYuklendi)) return;

    setState(() {
      if (ilkYukleme) {
        _isLoading = true;
        _gonderiler.clear();
        _sonGorunenGonderiDoc = null;
        _hepsiYuklendi = false;
      } else {
        _dahaFazlaYukleniyor = true;
      }
    });

    try {
      final siralamaAyari = _sortOptions[_selectedSortKey]!;
      Map<String, dynamic> sonuc = await _firestoreServisi.gonderileriGetirFiltreleSirala(
        tema: _selectedTheme,
        siralamaAlani: siralamaAyari["alan"] as String,
        azalan: siralamaAyari["azalan"] as bool,
        limitSayisi: 10, // Daha az gönderi ile daha hızlı test edilebilir: 3-5
        sonGorunenDoc: ilkYukleme ? null : _sonGorunenGonderiDoc,
      );

      List<Gonderi> gelenGonderiler = sonuc['gonderiler'] as List<Gonderi>;
      DocumentSnapshot? yeniSonDoc = sonuc['sonDoc'] as DocumentSnapshot?;

      if (mounted) {
        setState(() {
          _gonderiler.addAll(gelenGonderiler);
          _sonGorunenGonderiDoc = yeniSonDoc;

          if (gelenGonderiler.length < 10 || yeniSonDoc == null) { // Limit ile aynı olmalı
            _hepsiYuklendi = true;
            print("AraSayfasi: Tüm gönderiler yüklendi veya bu sayfada daha fazla gönderi yok.");
          }

          _isLoading = false;
          _dahaFazlaYukleniyor = false;
        });
      }
    } catch (e, s) {
      print("====== ARA SAYFASI - GÖNDERİ YÜKLEME HATASI ======");
      print("İLK YÜKLEME: $ilkYukleme, SEÇİLİ TEMA: $_selectedTheme, SIRALAMA: $_selectedSortKey");
      print("HATA TİPİ: ${e.runtimeType}");
      print("HATA MESAJI: $e");
      print("STACK TRACE: \n$s");
      print("================================================");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dahaFazlaYukleniyor = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gönderiler yüklenirken bir hata oluştu. (Detaylar konsolda)")),
        );
      }
    }
  }

  List<Gonderi> get _gosterilecekGonderiler {
    if (_aramaSorgusu.isEmpty) {
      return _gonderiler;
    }
    final String aramaSorgusuLower = _aramaSorgusu.toLowerCase();
    return _gonderiler.where((gonderi) {
      // Açıklama, başlık (eğer modelde varsa), kategori, konum ve kullanıcı adı içinde arama
      final bool aciklamaEslesiyor = gonderi.aciklama.toLowerCase().contains(aramaSorgusuLower);
      // Eğer Gonderi modelinizde 'baslik' alanı varsa:
      // final bool baslikEslesiyor = gonderi.baslik?.toLowerCase().contains(aramaSorgusuLower) ?? false;
      final bool kategoriEslesiyor = gonderi.kategori?.toLowerCase().contains(aramaSorgusuLower) ?? false;
      final bool konumEslesiyor = gonderi.konum?.toLowerCase().contains(aramaSorgusuLower) ?? false;
      final bool kullaniciAdiEslesiyor = gonderi.yayinlayanKullanici?.kullaniciAdi?.toLowerCase().contains(aramaSorgusuLower) ?? false;

      return aciklamaEslesiyor || kategoriEslesiyor || konumEslesiyor || kullaniciAdiEslesiyor /* || baslikEslesiyor */;
    }).toList();
  }

  @override
  void dispose(){
    _aramaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTemaVeSiralamaFiltreBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
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
              icon: Icons.filter_list_rounded,
            ),
          ),
          SizedBox(width: 10),
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
              icon: Icons.sort_rounded,
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
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: theme.colorScheme.surfaceVariant,
          isExpanded: true,
          icon: Icon(icon ?? Icons.keyboard_arrow_down_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.7), size: 20),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13.5, fontWeight: FontWeight.w500),
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
    final List<Gonderi> gosterilecek = _gosterilecekGonderiler;

    if (_isLoading && gosterilecek.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    if (gosterilecek.isEmpty && !_isLoading) {
      String mesaj = "Keşfedilecek gönderi bulunamadı.";
      if (_aramaSorgusu.isNotEmpty) {
        mesaj = "'$_aramaSorgusu' için sonuç bulunamadı.";
      } else {
        mesaj = "$_selectedTheme temasında henüz gönderi yok.\nFarklı bir tema veya sıralama seçmeyi dene!";
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            mesaj,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 16, height: 1.4),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 0, bottom: 12.0),
      itemCount: gosterilecek.length + (_dahaFazlaYukleniyor ? 1 : 0) + (!_hepsiYuklendi && !_dahaFazlaYukleniyor && gosterilecek.isNotEmpty ? 1 : 0), // "Daha fazla yükle butonu"
      itemBuilder: (context, index) {
        if (index == gosterilecek.length) {
          if (_dahaFazlaYukleniyor) {
            return Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.primary),
            ));
          } else if (!_hepsiYuklendi && gosterilecek.isNotEmpty) {
            // "Daha fazla yükle" butonu veya göstergesi
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                  child: _dahaFazlaYukleniyor
                      ? CircularProgressIndicator(strokeWidth: 2.5, color: theme.colorScheme.primary)
                      : TextButton(
                    onPressed: () => _gonderileriYukle(ilkYukleme: false),
                    child: Text("Daha Fazla Yükle", style: TextStyle(color: theme.colorScheme.primary)),
                  )
              ),
            );
          }
          return SizedBox.shrink();
        }


        final gonderi = gosterilecek[index];
        return ContentCard( // Eğer ContentCard olarak değiştirdiyseniz bu ismi kullanın
          key: ValueKey(gonderi.id + (_aktifKullaniciId ?? "")), // Key güncellendi
          gonderiId: gonderi.id,
          resimUrls: gonderi.resimUrls,
          profileUrl: gonderi.yayinlayanKullanici?.fotoUrl ?? "",
          userName: gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Bilinmeyen Kullanıcı",
          location: gonderi.konum ?? "", // Null ise boş string
          description: gonderi.aciklama,
          category: gonderi.kategori,
          initialLikeCount: gonderi.begeniSayisi,
          initialCommentCount: gonderi.yorumSayisi,
          aktifKullaniciId: _aktifKullaniciId ?? "",
          onProfileTap: () {
            if (gonderi.yayinlayanKullanici != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Profil(aktifKullanici: gonderi.yayinlayanKullanici!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Kullanıcı profili bulunamadı.")),
              );
            }
          },
          onCommentTap: (gonderiId) {
            // TODO: Yorumlar sayfasına/dialog'una yönlendirme
            // Örnek: Navigator.push(context, MaterialPageRoute(builder: (context) => YorumlarSayfasi(gonderiId: gonderiId)));
            print("Yorumlar tıklandı: $gonderiId");
          },
          onDetailsTap: () { // GÜNCELLENDİ
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GonderiDetaySayfasi(gonderi: gonderi),
              ),
            );
          },
          // Diğer callback'ler (onShareTap, onMoreTap) eklenebilir
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_aktifKullaniciId == null && _yetkilendirmeServisi.aktifKullaniciId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) setState(() => _aktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId);
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _aramaController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15.5),
              decoration: InputDecoration(
                hintText: "Pathbook'ta keşfet...",
                hintStyle: TextStyle(color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.5), fontSize: 15.5),
                prefixIcon: Icon(Icons.search_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.7), size: 22),
                suffixIcon: _aramaSorgusu.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.7), size: 20),
                  onPressed: () => _aramaController.clear(),
                  splashRadius: 20,
                ) : null,
                border: InputBorder.none,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.08),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.6), width: 1.5),
                ),
              ),
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