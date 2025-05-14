// lib/sayfalar/ara.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/dosya_modeli.dart'; // OLUŞTURDUĞUNUZ MODEL
import 'package:pathbooks/servisler/firestoreseervisi.dart';
// import 'package:pathbooks/servisler/yetkilendirmeservisi.dart'; // Bu sayfada doğrudan kullanılmıyor gibi
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart'; // YENİ OLUŞTURULACAK SAYFA

class AraSayfasi extends StatefulWidget {
  const AraSayfasi({Key? key}) : super(key: key);

  @override
  _AraSayfasiState createState() => _AraSayfasiState();
}

class _AraSayfasiState extends State<AraSayfasi> {
  late FirestoreServisi _firestoreServisi;
  List<DosyaModeli> _dosyalar = [];
  bool _isLoading = true;
  String _selectedFilter = "All"; // Varsayılan filtre
  String _selectedSort = "Last update"; // Varsayılan sıralama
  TextEditingController _aramaController = TextEditingController();
  String _aramaSorgusu = "";

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _dosyalariYukle();

    _aramaController.addListener(() {
      if (_aramaSorgusu != _aramaController.text) {
        // Anlık arama için debounce eklenebilir veya onSubmitted beklenebilir.
        // Şimdilik basit bir state güncellemesi ve filtreleme için placeholder.
        setState(() {
          _aramaSorgusu = _aramaController.text;
        });
        // TODO: _aramaSorgusu'na göre _dosyalar listesini filtrele veya yeni sorgu yap
      }
    });
  }

  Future<void> _dosyalariYukle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // TODO: FirestoreServisi'ne _selectedFilter ve _selectedSort'a göre
      // dosya getirme metodu ekleyin. Şimdilik tümünü getiriyor.
      // Örnek: List<DosyaModeli> gelenDosyalar = await _firestoreServisi.dosyalariGetir(filtre: _selectedFilter, siralama: _selectedSort).first;
      List<DosyaModeli> gelenDosyalar = await _firestoreServisi.tumDosyalariGetir().first;

      if (mounted) {
        setState(() {
          _dosyalar = gelenDosyalar;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("AraSayfasi - Dosya yükleme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Arama sorgusuna göre dosyaları filtrele (basit lokal filtreleme örneği)
  List<DosyaModeli> get _filtrelenmisDosyalar {
    if (_aramaSorgusu.isEmpty) {
      return _dosyalar;
    }
    return _dosyalar.where((dosya) {
      return dosya.ad.toLowerCase().contains(_aramaSorgusu.toLowerCase());
    }).toList();
  }


  @override
  void dispose(){
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF181818), // Pinterest koyu tema
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF181818),
        elevation: 0,
        titleSpacing: 16.0, // Başlık için sol boşluk
        title: Text(
          "Arama", // Veya "Keşfet"
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w500),
        ),
        bottom: PreferredSize( // AppBar altına filtre barını eklemek için
          preferredSize: Size.fromHeight(50.0),
          child: _buildFiltreVeAramaBar(),
        ),
      ),
      body: _buildDosyaGridi(),
    );
  }

  Widget _buildFiltreVeAramaBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
      child: Row(
        children: [
          _buildDropdownFilter(_selectedFilter, ["All", "Boards", "Pins"], (newValue) { // "People" şimdilik kaldırıldı
            if (mounted) setState(() => _selectedFilter = newValue!);
            _dosyalariYukle(); // Filtre değişince yeniden yükle
          }),
          SizedBox(width: 10),
          _buildDropdownFilter(_selectedSort, ["Last update", "A-Z"], (newValue) {
            if (mounted) setState(() => _selectedSort = newValue!);
            _dosyalariYukle(); // Sıralama değişince yeniden yükle
          }),
          Spacer(),
          // Arama çubuğu için IconButton yerine direkt TextField olabilir
          // veya bir arama ikonuna tıklanınca açılan bir yapı.
          // Şimdilik arama ikonuyla bırakıyorum, tıklanınca arama çubuğu gösterilebilir.
          IconButton(
            icon: Icon(Icons.search, color: Colors.white, size: 26),
            onPressed: () {
              // TODO: Gelişmiş arama arayüzünü göster/gizle
              // Şimdilik basit bir arama alanı AppBar'a eklenebilir.
              // Veya bu butona tıklayınca bir TextField görünür olabilir.
              // Örnek: showSearch(context: context, delegate: DosyaSearchDelegate())
              print("Arama ikonuna tıklandı");
            },
          )
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.grey[850], // Arka plan rengi
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: Colors.grey[850],
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.7), size: 20),
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDosyaGridi() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final gosterilecekDosyalar = _filtrelenmisDosyalar; // Arama filtresini uygula

    if (gosterilecekDosyalar.isEmpty) {
      return Center(
        child: Text(
          _aramaSorgusu.isNotEmpty ? "Arama sonucu bulunamadı." : "Gösterilecek dosya bulunamadı.",
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: gosterilecekDosyalar.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.78, // Kartların en-boy oranı biraz daha dikey
      ),
      itemBuilder: (context, index) {
        final dosya = gosterilecekDosyalar[index];
        return _buildDosyaKarti(dosya);
      },
    );
  }

  Widget _buildDosyaKarti(DosyaModeli dosya) {
    List<String> kapakResimleri = dosya.kapakResimleri;
    // En az 1, en fazla 4 kapak resmi gösterelim
    if (kapakResimleri.isEmpty) { // Hiç kapak resmi yoksa placeholder
      kapakResimleri = List.generate(4, (index) => "https://via.placeholder.com/150/2d2d2d/FFFFFF?Text=Path+${index+1}");
    }
    // Kapak resimlerini 2x2 grid için hazırla
    Widget resimGrubu;
    if (kapakResimleri.length >= 4) {
      resimGrubu = Column(children: [
        Expanded(child: Row(children: [
          Expanded(child: _buildKapakResmi(kapakResimleri[0], topLeft: true)),
          Expanded(child: _buildKapakResmi(kapakResimleri[1], topRight: true)),
        ])),
        Expanded(child: Row(children: [
          Expanded(child: _buildKapakResmi(kapakResimleri[2], bottomLeft: true)),
          Expanded(child: _buildKapakResmi(kapakResimleri[3], bottomRight: true)),
        ])),
      ]);
    } else if (kapakResimleri.length == 3) {
      resimGrubu = Column(children: [
        Expanded(child: Row(children: [
          Expanded(child: _buildKapakResmi(kapakResimleri[0], topLeft: true)),
          Expanded(child: _buildKapakResmi(kapakResimleri[1], topRight: true)),
        ])),
        Expanded(child: _buildKapakResmi(kapakResimleri[2], bottomLeft: true, bottomRight: true)), // Alt tek resim tüm genişliği kaplasın
      ]);
    } else if (kapakResimleri.length == 2) {
      resimGrubu = Row(children: [
        Expanded(child: _buildKapakResmi(kapakResimleri[0], topLeft: true, bottomLeft: true)),
        Expanded(child: _buildKapakResmi(kapakResimleri[1], topRight: true, bottomRight: true)),
      ]);
    } else { // 1 resim varsa
      resimGrubu = _buildKapakResmi(kapakResimleri[0], allCorners: true);
    }


    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DosyaDetaySayfasi(dosya: dosya)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                color: Colors.grey[850], // Resimler yüklenene kadar
                child: resimGrubu,
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  dosya.ad,
                  style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if(dosya.gizliMi)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Icon(Icons.lock_outline, color: Colors.grey[500], size: 16),
                )
            ],
          ),
          SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${dosya.gonderiSayisi} pins",
                style: TextStyle(color: Colors.grey[400], fontSize: 12.5),
              ),
              if (dosya.sonGuncelleme != null) ...[
                SizedBox(width: 4),
                Text("·", style: TextStyle(color: Colors.grey[400], fontSize: 12.5)),
                SizedBox(width: 4),
                Text(
                  _formatRelativeTime(dosya.sonGuncelleme!),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12.5),
                ),
              ],
              Spacer(),
              if (dosya.katkidaBulunanlarProfilResimleri.isNotEmpty)
                _buildKatkidaBulunanAvatarlar(dosya.katkidaBulunanlarProfilResimleri),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKapakResmi(String url, {bool topLeft = false, bool topRight = false, bool bottomLeft = false, bool bottomRight = false, bool allCorners = false}) {
    // URL'nin geçerli olup olmadığını kontrol et (basit kontrol)
    bool isValidUrl = Uri.tryParse(url)?.hasAbsolutePath ?? false;

    return Container(
      margin: EdgeInsets.all(0.75), // Resimler arası çok ince boşluk
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(allCorners || topLeft ? 8.0 : 0.0),
          topRight: Radius.circular(allCorners || topRight ? 8.0 : 0.0),
          bottomLeft: Radius.circular(allCorners || bottomLeft ? 8.0 : 0.0),
          bottomRight: Radius.circular(allCorners || bottomRight ? 8.0 : 0.0),
        ),
        image: isValidUrl ? DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          // Hata durumunda placeholder göstermek için errorBuilder eklenebilir
          onError: (exception, stackTrace) {
            // print("Kapak resmi yüklenemedi: $url, Hata: $exception");
          },
        ) : null, // Geçersiz URL ise image null olsun
        color: !isValidUrl ? Colors.grey[700] : null, // Geçersiz URL ise placeholder rengi
      ),
      child: !isValidUrl ? Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[500], size: 20)) : null,
    );
  }

  Widget _buildKatkidaBulunanAvatarlar(List<String> avatarUrls) {
    const double avatarRadius = 8.0; // Daha küçük avatarlar
    const double overlapFactor = 0.4; // Ne kadar üst üste binecekleri (0.0 - 1.0)
    int maxAvatars = 3; // Maksimum gösterilecek avatar sayısı

    List<Widget> avatarWidgets = [];
    double currentLeft = 0;

    for (int i = 0; i < avatarUrls.length && i < maxAvatars; i++) {
      avatarWidgets.add(
        Positioned(
          left: currentLeft,
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.black, // Çerçeve efekti için
            child: CircleAvatar( // İçteki asıl avatar
              radius: avatarRadius - 1, // Çerçeve kalınlığı
              backgroundImage: NetworkImage(avatarUrls[i]),
              backgroundColor: Colors.grey[700], // Resim yoksa
            ),
          ),
        ),
      );
      currentLeft += avatarRadius * 2 * (1 - overlapFactor); // Bir sonraki avatarın konumu
    }
    return Container(
      width: currentLeft + (avatarRadius * 2 * overlapFactor) - (avatarRadius * 2 * (1-overlapFactor) * (1-overlapFactor) ) , // Stack genişliğini hesapla
      height: avatarRadius * 2,
      child: Stack(children: avatarWidgets.reversed.toList()), // Sondan başlayarak ekle, ilki en üstte olsun
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    // ... (Bu fonksiyon bir önceki cevaptaki gibi kalabilir) ...
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 6) {
      int weeks = (difference.inDays / 7).floor();
      if (weeks > 3) { // 4 haftadan sonra ay olarak göster
        int months = (difference.inDays / 30).floor(); // Ortalama ay
        if (months > 11) { // 12 aydan sonra yıl olarak göster
          int years = (difference.inDays / 365).floor();
          return "$years y"; // yıl
        }
        return "$months a"; // ay
      }
      return "$weeks hf"; // hafta
    } else if (difference.inDays > 0) {
      return "${difference.inDays} g"; // gün
    } else if (difference.inHours > 0) {
      return "${difference.inHours} sa"; // saat
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} dk"; // dakika
    } else {
      return "şimdi";
    }
  }
}