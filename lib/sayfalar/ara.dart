// lib/sayfalar/ara.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/dosya_modeli.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
// GonderiDetaySayfasi importu burada gerekli değil, çünkü doğrudan ona yönlendirmiyoruz.
// Eğer bir dosyaya ait gönderileri listelemek için farklı bir mekanizma kurarsak
// (örneğin Akis sayfasına filtreli yönlendirme), o zaman ilgili sayfaların importu gerekebilir.

class AraSayfasi extends StatefulWidget {
  const AraSayfasi({Key? key}) : super(key: key);

  @override
  _AraSayfasiState createState() => _AraSayfasiState();
}

class _AraSayfasiState extends State<AraSayfasi> {
  late FirestoreServisi _firestoreServisi;
  List<DosyaModeli> _dosyalar = [];
  bool _isLoading = true;
  String _selectedFilter = "Tümü"; // Filtre seçeneklerini güncelledim
  String _selectedSort = "Son Güncelleme"; // Sıralama seçeneklerini güncelledim
  TextEditingController _aramaController = TextEditingController();
  String _aramaSorgusu = "";

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _dosyalariYukle();

    _aramaController.addListener(() {
      if (mounted && _aramaSorgusu != _aramaController.text) {
        setState(() {
          _aramaSorgusu = _aramaController.text;
        });
      }
    });
  }

  Future<void> _dosyalariYukle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // TODO: FirestoreServisi'ne _selectedFilter ve _selectedSort'a göre
      // dosya getirme metodu eklenmeli.
      // Şimdilik FirestoreServisi.tumDosyalariGetir()'in bu parametreleri
      // opsiyonel olarak alabileceğini varsayalım.
      List<DosyaModeli> gelenDosyalar = await _firestoreServisi.tumDosyalariGetir(
        // filtre: _selectedFilter, // Örnek
        // siralama: _selectedSort, // Örnek
      ).first;

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

  List<DosyaModeli> get _filtrelenmisDosyalar {
    if (_aramaSorgusu.isEmpty) {
      return _dosyalar;
    }
    return _dosyalar.where((dosya) {
      final String dosyaAdiLower = dosya.ad.toLowerCase();
      final String aramaSorgusuLower = _aramaSorgusu.toLowerCase();
      return dosyaAdiLower.contains(aramaSorgusuLower);
    }).toList();
  }

  @override
  void dispose(){
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0, // AppBar gölgesini kaldır
        titleSpacing: 0, // Sol ve sağ boşlukları kaldır
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Dikey padding eklendi
          child: SizedBox( // TextField'ın yüksekliğini kontrol etmek için
            height: 42, // TextField yüksekliği
            child: TextField(
              controller: _aramaController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15.5),
              decoration: InputDecoration(
                hintText: "Pathbook'ta ara...",
                hintStyle: TextStyle(color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.5), fontSize: 15.5),
                prefixIcon: Icon(Icons.search_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.7), size: 22),
                suffixIcon: _aramaSorgusu.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.7), size: 20),
                  onPressed: () {
                    _aramaController.clear();
                  },
                  splashRadius: 20,
                )
                    : null,
                border: InputBorder.none,
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.08),
                contentPadding: EdgeInsets.symmetric(vertical: 0), // Dikey content padding'i sıfırla
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0), // Daha yuvarlak kenarlar
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
          _buildFiltreBar(theme), // Filtre barını body'nin başına aldık
          Expanded(child: _buildDosyaGridi(theme)),
        ],
      ),
    );
  }

  Widget _buildFiltreBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
      child: Row(
        children: [
          _buildDropdownFilter(_selectedFilter, ["Tümü", "Panolarım", "Gönderiler"], (newValue) {
            if (mounted) setState(() => _selectedFilter = newValue!);
            // TODO: _selectedFilter'a göre _dosyalariYukle veya farklı bir metot çağrılmalı.
            // Eğer "Gönderiler" seçilirse, _firestoreServisi.tumGonderileriGetir() gibi bir şey çağrılmalı.
            // Şu anki _dosyalar listesi DosyaModeli içeriyor. Bu filtreleme mantığı detaylandırılmalı.
            _dosyalariYukle();
          }, theme),
          SizedBox(width: 10),
          _buildDropdownFilter(_selectedSort, ["Son Güncelleme", "Popüler", "A-Z"], (newValue) {
            if (mounted) setState(() => _selectedSort = newValue!);
            // TODO: Sıralama mantığı _dosyalariYukle içinde veya lokal olarak uygulanmalı.
            _dosyalariYukle();
          }, theme),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String currentValue, List<String> items, ValueChanged<String?> onChanged, ThemeData theme) {
    return Expanded(
      child: Container(
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
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: (theme.textTheme.bodyLarge?.color)?.withOpacity(0.7), size: 20),
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
      ),
    );
  }

  Widget _buildDosyaGridi(ThemeData theme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }
    final gosterilecekDosyalar = _filtrelenmisDosyalar;
    if (gosterilecekDosyalar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _aramaSorgusu.isNotEmpty ? "'$_aramaSorgusu' için sonuç bulunamadı." : "Keşfedilecek içerik bulunamadı.\nFarklı bir şeyler aramayı dene!",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 16, height: 1.4),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
      itemCount: gosterilecekDosyalar.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Sütun sayısı
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.75, // Kartların en-boy oranı (daha dikey)
      ),
      itemBuilder: (context, index) {
        final dosya = gosterilecekDosyalar[index];
        return _buildDosyaKarti(dosya, theme);
      },
    );
  }

  Widget _buildDosyaKarti(DosyaModeli dosya, ThemeData theme) {
    List<String> kapakResimleri = dosya.kapakResimleri;
    if (kapakResimleri.isEmpty) {
      kapakResimleri = [""]; // Placeholder için tek boş string
    }

    Widget resimGrubu;
    // ... (resimGrubu oluşturma mantığı aynı, _buildKapakResmi'ne theme geçilecek)
    if (kapakResimleri.length >= 4) {
      resimGrubu = Column(children: [ Expanded(child: Row(children: [ Expanded(child: _buildKapakResmi(kapakResimleri[0], theme, topLeft: true)), Expanded(child: _buildKapakResmi(kapakResimleri[1], theme, topRight: true)), ])), Expanded(child: Row(children: [ Expanded(child: _buildKapakResmi(kapakResimleri[2], theme, bottomLeft: true)), Expanded(child: _buildKapakResmi(kapakResimleri[3], theme, bottomRight: true)), ])), ]);
    } else if (kapakResimleri.length == 3) {
      resimGrubu = Column(children: [ Expanded(child: Row(children: [ Expanded(child: _buildKapakResmi(kapakResimleri[0], theme, topLeft: true)), Expanded(child: _buildKapakResmi(kapakResimleri[1], theme, topRight: true)), ])), Expanded(child: _buildKapakResmi(kapakResimleri[2], theme, bottomLeft: true, bottomRight: true)), ]);
    } else if (kapakResimleri.length == 2) {
      resimGrubu = Row(children: [ Expanded(child: _buildKapakResmi(kapakResimleri[0], theme, topLeft: true, bottomLeft: true)), Expanded(child: _buildKapakResmi(kapakResimleri[1], theme, topRight: true, bottomRight: true)), ]);
    } else { resimGrubu = _buildKapakResmi(kapakResimleri[0], theme, allCorners: true); }


    return GestureDetector(
      onTap: () {
        // DosyaDetaySayfasi'nı kullanmayacağımız için bu yönlendirmeyi kaldırıyoruz.
        // Kullanıcı bir "Dosya" kartına tıkladığında ne olacağına karar vermeliyiz.
        // Şimdilik sadece print yapalım.
        print("Dosya kartı tıklandı: ${dosya.ad} (ID: ${dosya.id})");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${dosya.ad} dosyası tıklandı. (Detay sayfası devredışı)")),
        );
        // İLERİDE: Belki bu dosyaya ait gönderileri Akis sayfasında filtreleyerek gösterebiliriz.
        // Örneğin: Navigator.push(context, MaterialPageRoute(builder: (_) => Akis(dosyaIdFiltresi: dosya.id)));
        // Bu, Akis widget'ının böyle bir filtreyi kabul etmesini gerektirir.
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                // color: theme.colorScheme.surfaceVariant.withOpacity(0.05),
                child: resimGrubu,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            dosya.ad,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Row(
            children: [
              Text(
                "${dosya.gonderiSayisi} gönderi",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
              if (dosya.sonGuncelleme != null) ...[
                SizedBox(width: 4),
                Text("·", style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 12.5)),
                SizedBox(width: 4),
                Text(
                  _formatRelativeTime(dosya.sonGuncelleme!),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                ),
              ],
              // if(dosya.gizliMi) // Gizlilik ikonu, eğer dosyalar için böyle bir özellik varsa
              //   Padding(
              //     padding: const EdgeInsets.only(left: 6.0),
              //     child: Icon(Icons.lock_outline, color: theme.iconTheme.color?.withOpacity(0.6), size: 14),
              //   )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKapakResmi(String url, ThemeData theme, {bool topLeft = false, bool topRight = false, bool bottomLeft = false, bool bottomRight = false, bool allCorners = false}) {
    bool isValidUrl = url.isNotEmpty && (Uri.tryParse(url)?.hasAbsolutePath ?? false);
    return Container(
      margin: EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(allCorners || topLeft ? 6.0 : 0.0),
          topRight: Radius.circular(allCorners || topRight ? 6.0 : 0.0),
          bottomLeft: Radius.circular(allCorners || bottomLeft ? 6.0 : 0.0),
          bottomRight: Radius.circular(allCorners || bottomRight ? 6.0 : 0.0),
        ),
        image: isValidUrl ? DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ) : null,
        color: !isValidUrl ? theme.colorScheme.surfaceVariant.withOpacity(0.15) : null, // Placeholder rengi biraz daha belirgin
      ),
      child: !isValidUrl ? Center(child: Icon(Icons.photo_library_outlined, color: theme.iconTheme.color?.withOpacity(0.4), size: 24)) : null, // İkon değiştirildi
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now(); final difference = now.difference(dateTime); if (difference.inDays > 30 * 2) { return DateFormat('dd MMM yyyy', 'tr_TR').format(dateTime); } else if (difference.inDays > 6) { int weeks = (difference.inDays / 7).floor(); return "$weeks hf önce"; } else if (difference.inDays > 0) { return "${difference.inDays} g önce"; } else if (difference.inHours > 0) { return "${difference.inHours} sa önce"; } else if (difference.inMinutes > 0) { return "${difference.inMinutes} dk önce"; } else { return "şimdi"; }
  }
}