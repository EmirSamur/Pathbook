// lib/sayfalar/profil.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/sayfalar/profili_duzenle_sayfasi.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';
import 'package:pathbooks/sayfalar/takip_listesi_sayfasi.dart';
import 'package:pathbooks/sayfalar/gezi_haritasi_sayfasi.dart';
import 'package:pathbooks/veri/gezi_ozeti.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';
import 'package:pathbooks/widgets/takip_butonu.dart';

class Profil extends StatefulWidget {
  final Kullanici? aktifKullanici; // Görüntülenen kullanıcı

  const Profil({
    Key? key,
    this.aktifKullanici,
  }) : super(key: key);

  @override
  _ProfilState createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  static const String _fontFamilyBebas = 'Bebas';

  Kullanici? _kullanici;
  bool _profilBilgileriYukleniyor = true;

  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;

  List<Gonderi> _tumGonderiler = [];
  List<String> _kullanicininSehirleri = [];
  String? _seciliSehirFiltresi;
  GeziOzeti _geziOzeti = GeziOzeti.hesapla(const []);

  int _seciliSekme = 0; // 0: Paylaşımlar, 1: Kaydedilenler (yalnızca kendi profilinde)
  Future<List<Gonderi>>? _kaydedilenlerFuture;
  bool _engellendi = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _gonderiStream;
  String? _gonderiStreamAnahtari;

  String? get _oturumId => _yetkilendirmeServisi.aktifKullaniciId;
  bool get _kendiProfili => widget.aktifKullanici != null && _oturumId == widget.aktifKullanici!.id;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);
    _verileriYukle();
  }

  @override
  void didUpdateWidget(covariant Profil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aktifKullanici?.id != oldWidget.aktifKullanici?.id) {
      _seciliSehirFiltresi = null;
      _verileriYukle();
    }
  }

  Future<void> _verileriYukle() async {
    final String? id = widget.aktifKullanici?.id;
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _profilBilgileriYukleniyor = false);
      return;
    }
    if (mounted && _kullanici == null) setState(() => _profilBilgileriYukleniyor = true);

    final sonuclar = await Future.wait([
      _firestoreServisi.kullaniciGetir(id, onbellekKullan: false),
      _firestoreServisi.kullanicininTumGonderileriniGetir(id),
      if (!_kendiProfili && _oturumId != null) _firestoreServisi.engellenenleriGetir(_oturumId!),
    ]);
    if (!mounted) return;

    final Kullanici? kullanici = sonuclar[0] as Kullanici?;
    final List<Gonderi> gonderiler = sonuclar[1] as List<Gonderi>;
    final List<String> engellenenler = sonuclar.length > 2 ? sonuclar[2] as List<String> : const [];
    final ozet = GeziOzeti.hesapla(gonderiler);

    setState(() {
      // Firestore'dan okunamazsa (ör. ağ hatası) elimizdeki bilgiyle devam et.
      _kullanici = kullanici ?? _kullanici ?? widget.aktifKullanici;
      _tumGonderiler = gonderiler;
      _geziOzeti = ozet;
      _kullanicininSehirleri = ozet.sehirler.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (_seciliSehirFiltresi != null && !_kullanicininSehirleri.contains(_seciliSehirFiltresi)) _seciliSehirFiltresi = null;
      _engellendi = engellenenler.contains(id);
      _profilBilgileriYukleniyor = false;
      if (_kendiProfili && _seciliSekme == 1) _kaydedilenlerFuture = _firestoreServisi.kaydedilenGonderileriGetir(id);
    });
  }

  String get _kullaniciAdi {
    final k = _kullanici;
    if (k == null) return "Profil";
    if (k.kullaniciAdi?.isNotEmpty == true) return k.kullaniciAdi!;
    return k.email?.split('@')[0] ?? "Bilinmiyor";
  }

  void _cikisYap() {
    _firestoreServisi.kullaniciOnbelleginiTemizle();
    _yetkilendirmeServisi.cikisYap();
  }

  void _profiliDuzenle() async {
    if (!_kendiProfili) return;
    final bool? guncellemeOldu = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfiliDuzenleSayfasi(mevcutKullanici: _kullanici ?? widget.aktifKullanici!)));
    if (guncellemeOldu == true && mounted) {
      await _verileriYukle();
    }
  }

  Future<void> _engelDegistir() async {
    final String? oturum = _oturumId;
    final String? hedef = widget.aktifKullanici?.id;
    if (oturum == null || hedef == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_engellendi) {
        await _firestoreServisi.engeliKaldir(aktifKullaniciId: oturum, hedefKullaniciId: hedef);
        messenger.showSnackBar(SnackBar(content: Text("$_kullaniciAdi kullanıcısının engeli kaldırıldı.")));
      } else {
        await _firestoreServisi.kullaniciEngelle(aktifKullaniciId: oturum, hedefKullaniciId: hedef);
        messenger.showSnackBar(SnackBar(content: Text("$_kullaniciAdi engellendi.")));
      }
      await _verileriYukle();
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text("İşlem gerçekleştirilemedi.")));
    }
  }

  Future<void> _gonderiyiSilOnayiGoster(Gonderi gonderi) async {
    final String? oAnkiAktifKullaniciId = _oturumId;
    if (oAnkiAktifKullaniciId == null || oAnkiAktifKullaniciId != gonderi.kullaniciId) return;
    bool? silOnaylandi = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xFF2C2C2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text('Gönderiyi Sil', style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 18)),
          content: SingleChildScrollView(child: ListBody(children: <Widget>[
            Text('Bu paylaşımı kalıcı olarak silmek istediğinizden emin misiniz?', style: TextStyle(color: Colors.grey[300], fontSize: 13.5)),
            SizedBox(height: 12),
            if (gonderi.resimUrls.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(6.0), child: SizedBox(height: 100, child: AgGorseli(url: gonderi.resimUrls[0], fit: BoxFit.contain))),
            if (gonderi.aciklama.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("\"${gonderi.aciklama.length > 50 ? gonderi.aciklama.substring(0, 50) + "..." : gonderi.aciklama}\"", style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic, fontSize: 12.5))),
          ])),
          actionsPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          actions: <Widget>[
            TextButton(child: Text('İptal', style: TextStyle(color: Colors.grey[400], fontFamily: _fontFamilyBebas, fontSize: 14)), onPressed: () => Navigator.of(dialogContext).pop(false)),
            TextButton(child: Text('Sil', style: TextStyle(color: Colors.redAccent[100], fontFamily: _fontFamilyBebas, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => Navigator.of(dialogContext).pop(true)),
          ],
        );
      },
    );
    if (silOnaylandi == true && mounted) {
      try {
        await _firestoreServisi.gonderiSil(gonderiId: gonderi.id, kullaniciId: oAnkiAktifKullaniciId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi başarıyla silindi.'), backgroundColor: Colors.green[600]));
        await _verileriYukle();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi silinirken bir hata oluştu.'), backgroundColor: Colors.red[600]));
      }
    }
  }

  void _yardimGoster() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text("Yardım & Destek", style: TextStyle(fontSize: 22)),
            SizedBox(height: 14),
            _YardimMaddesi(ikon: Icons.favorite_border_rounded, metin: "Bir fotoğrafa çift dokunarak gönderiyi beğenebilirsin."),
            _YardimMaddesi(ikon: Icons.bookmark_border_rounded, metin: "Kaydettiğin gönderiler profilindeki \"Kaydedilenler\" sekmesinde durur."),
            _YardimMaddesi(ikon: Icons.label_outline_rounded, metin: "Kategori, şehir veya ülke etiketine dokunarak o yerdeki tüm paylaşımları görebilirsin."),
            _YardimMaddesi(ikon: Icons.map_outlined, metin: "Paylaşım yaparken şehir ve ülke eklersen gezi haritanda iğne olarak görünür."),
            _YardimMaddesi(ikon: Icons.flag_outlined, metin: "Uygunsuz bir içerik görürsen gönderideki ••• menüsünden şikayet edebilirsin."),
          ]),
        ),
      ),
    );
  }

  void _hakkindaGoster() {
    showAboutDialog(
      context: context,
      applicationName: "Pathbook",
      applicationVersion: "1.0.0",
      applicationIcon: Icon(Icons.public, color: Theme.of(context).colorScheme.primary, size: 40),
      children: const [Text("Gezdiğin yerleri paylaş, yeni rotalar keşfet.")],
    );
  }

  Widget _buildOptionListTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap, Color iconColor = Colors.white, Color iconBackgroundColor = const Color(0xFF2C2C2E)}) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: iconBackgroundColor, child: Icon(icon, color: iconColor, size: 19), radius: 19),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: _fontFamilyBebas)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontFamily: _fontFamilyBebas)) : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
    );
  }

  Widget _sosyalSayac({required String baslik, required int sayi, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(sayi.toString(), style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: _fontFamilyBebas)),
          SizedBox(height: 1.5),
          Text(baslik, style: TextStyle(fontSize: 12.5, color: Colors.grey[400], fontFamily: _fontFamilyBebas)),
        ]),
      ),
    );
  }

  void _takipListesiAc(int sekme) {
    final k = _kullanici ?? widget.aktifKullanici;
    if (k == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => TakipListesiSayfasi(kullanici: k, baslangicSekmesi: sekme)))
        .then((_) => _verileriYukle()); // Listede takip değişmiş olabilir
  }

  Widget _buildGeziOzeti(ThemeData theme) {
    final ozet = _geziOzeti;
    final rozetler = ozet.rozetler;
    final int kazanilan = rozetler.where((r) => r.kazanildi).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF1E1E1E), theme.colorScheme.primary.withOpacity(0.18)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.travel_explore_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${ozet.sehirler.length} şehir · ${ozet.ulkeler.length} ülke · ${ozet.kategoriler.length} kategori",
              style: const TextStyle(fontFamily: _fontFamilyBebas, fontSize: 16, color: Colors.white),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GeziHaritasiSayfasi(gonderiler: _tumGonderiler, kullaniciAdi: _kullaniciAdi))),
            icon: const Icon(Icons.map_outlined, size: 17),
            label: const Text("Harita", style: TextStyle(fontFamily: _fontFamilyBebas, fontSize: 15)),
            style: TextButton.styleFrom(foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
          ),
        ]),
        const SizedBox(height: 8),
        Text("Rozetler ($kazanilan/${rozetler.length})", style: TextStyle(color: Colors.grey[400], fontSize: 12.5, fontFamily: _fontFamilyBebas)),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rozetler.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final r = rozetler[i];
              return Tooltip(
                message: "${r.ad}: ${r.aciklama}",
                triggerMode: TooltipTriggerMode.tap,
                child: Opacity(
                  opacity: r.kazanildi ? 1 : 0.3,
                  child: Container(
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: r.kazanildi ? r.renk.withOpacity(0.18) : Colors.grey[850],
                      border: Border.all(color: r.kazanildi ? r.renk : Colors.grey[700]!, width: 1.5),
                    ),
                    child: Icon(r.kazanildi ? r.ikon : Icons.lock_outline_rounded, color: r.kazanildi ? r.renk : Colors.grey[500], size: 20),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildSekmeler(ThemeData theme) {
    Widget sekme(int index, IconData ikon, String baslik) {
      final bool secili = _seciliSekme == index;
      return Expanded(
        child: InkWell(
          onTap: () {
            if (_seciliSekme == index) return;
            setState(() {
              _seciliSekme = index;
              if (index == 1 && _oturumId != null) _kaydedilenlerFuture = _firestoreServisi.kaydedilenGonderileriGetir(_oturumId!);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: secili ? theme.colorScheme.primary : Colors.grey[850]!, width: secili ? 2 : 1))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ikon, size: 18, color: secili ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(baslik, style: TextStyle(fontFamily: _fontFamilyBebas, fontSize: 15, color: secili ? Colors.white : Colors.grey[600])),
            ]),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Row(children: [
        sekme(0, Icons.grid_on_rounded, "Paylaşımlar"),
        sekme(1, Icons.bookmark_border_rounded, "Kaydedilenler"),
      ]),
    );
  }

  Widget _buildSehirFiltreBar(ThemeData theme) {
    if (_kullanicininSehirleri.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }
    Widget cip(String? sehir) {
      final bool secili = _seciliSehirFiltresi == sehir;
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 3.0), child: ChoiceChip(
        label: Text(sehir ?? "Tümü", style: TextStyle(fontSize: 12, color: secili ? Colors.white : Colors.grey[350], fontWeight: secili ? FontWeight.bold : FontWeight.normal)),
        selected: secili,
        onSelected: (selected) { if (mounted && selected) setState(() => _seciliSehirFiltresi = sehir); },
        avatar: sehir == null ? null : Icon(Icons.location_city_rounded, size: 14, color: secili ? Colors.white70 : Colors.grey[500]),
        backgroundColor: Colors.grey[800]?.withOpacity(0.7), selectedColor: theme.primaryColor, showCheckmark: false,
        labelPadding: EdgeInsets.symmetric(horizontal: sehir == null ? 10 : 4), padding: EdgeInsets.only(left: sehir == null ? 0 : 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.transparent)), visualDensity: VisualDensity.compact,
      ));
    }
    return SliverToBoxAdapter(child: Container(height: 38, margin: const EdgeInsets.only(bottom: 6.0, top: 8.0), child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12.0), children: [
      cip(null),
      ..._kullanicininSehirleri.map(cip),
    ])));
  }

  Widget _izgaraHucresi(Gonderi gonderi, {VoidCallback? onLongPress}) {
    String? ilkResimUrl = gonderi.resimUrls.isNotEmpty ? gonderi.resimUrls[0] : null;
    if (ilkResimUrl == null) return Container(color: Colors.grey[850], child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[700], size: 18));
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: gonderi))).then((_) {
        if (mounted) _verileriYukle();
      }),
      onLongPress: onLongPress,
      child: Stack(fit: StackFit.expand, children: [
        AgGorseli(url: ilkResimUrl),
        if (gonderi.resimUrls.length > 1)
          const Positioned(top: 5, right: 5, child: Icon(Icons.collections_rounded, size: 15, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
      ]),
    );
  }

  SliverGridDelegate get _izgara => const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.5, mainAxisSpacing: 1.5);

  Widget _bosDurum(IconData ikon, String mesaj) {
    return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(ikon, size: 35, color: Colors.grey[600]), SizedBox(height: 10), Text(mesaj, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontFamily: _fontFamilyBebas, fontSize: 17))]))));
  }

  Widget _buildGonderiIzgarasi() {
    if (widget.aktifKullanici == null || widget.aktifKullanici!.id.isEmpty) {
      return _bosDurum(Icons.person_off_outlined, "Kullanıcı bilgisi yüklenemedi.");
    }

    // Stream her build'de yeniden oluşturulursa ızgara sürekli baştan yüklenir;
    // bu yüzden yalnızca kullanıcı veya şehir filtresi değişince yenilenir.
    final String anahtar = "${widget.aktifKullanici!.id}|${_seciliSehirFiltresi ?? ''}";
    if (_gonderiStream == null || _gonderiStreamAnahtari != anahtar) {
      _gonderiStreamAnahtari = anahtar;
      _gonderiStream = (_seciliSehirFiltresi != null && _seciliSehirFiltresi!.isNotEmpty)
          ? _firestoreServisi.kullanicininSehirGonderileriniGetir(kullaniciId: widget.aktifKullanici!.id, sehir: _seciliSehirFiltresi!)
          : _firestoreServisi.kullaniciGonderileriniGetir(widget.aktifKullanici!.id);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _gonderiStream,
      builder: (context, snapshot) {
        List<Gonderi> gonderiler;
        if (snapshot.hasError) {
          // Index henüz oluşturulmadıysa sorgu hata verir; bu durumda
          // sıralamasız çekilmiş listeyle devam ederiz.
          gonderiler = _seciliSehirFiltresi == null
              ? _tumGonderiler
              : _tumGonderiler.where((g) => g.sehir?.trim() == _seciliSehirFiltresi).toList();
        } else if (!snapshot.hasData) {
          return SliverPadding(
            padding: const EdgeInsets.all(1.5),
            sliver: SliverGrid(gridDelegate: _izgara, delegate: SliverChildBuilderDelegate((_, __) => const IskeletKutu(), childCount: 9)),
          );
        } else {
          gonderiler = snapshot.data!.docs.map((d) => Gonderi.dokumandanUret(d, yayinlayan: _kullanici ?? widget.aktifKullanici)).toList();
        }
        if (gonderiler.isEmpty) {
          return _bosDurum(Icons.dynamic_feed_outlined, _seciliSehirFiltresi != null ? "'$_seciliSehirFiltresi' şehrinde hiç paylaşım yok." : 'Henüz hiç paylaşım yapılmamış.');
        }
        return SliverPadding(
          padding: const EdgeInsets.all(1.5),
          sliver: SliverGrid(
            gridDelegate: _izgara,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final gonderi = gonderiler[index];
                return _izgaraHucresi(gonderi, onLongPress: _kendiProfili ? () => _gonderiyiSilOnayiGoster(gonderi) : null);
              },
              childCount: gonderiler.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildKaydedilenler() {
    return FutureBuilder<List<Gonderi>>(
      future: _kaydedilenlerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SliverPadding(
            padding: const EdgeInsets.all(1.5),
            sliver: SliverGrid(gridDelegate: _izgara, delegate: SliverChildBuilderDelegate((_, __) => const IskeletKutu(), childCount: 6)),
          );
        }
        final liste = snapshot.data ?? [];
        if (liste.isEmpty) {
          return _bosDurum(Icons.bookmark_border_rounded, "Henüz kaydettiğin bir gönderi yok.\nBeğendiğin yerleri kaydetmek için gönderideki yer işaretine dokun.");
        }
        return SliverPadding(
          padding: const EdgeInsets.all(1.5),
          sliver: SliverGrid(
            gridDelegate: _izgara,
            delegate: SliverChildBuilderDelegate((context, i) => _izgaraHucresi(liste[i]), childCount: liste.length),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool geriGidebilir = Navigator.of(context).canPop();

    if (_profilBilgileriYukleniyor || widget.aktifKullanici == null) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        appBar: AppBar(backgroundColor: Color(0xFF121212), elevation: 0, automaticallyImplyLeading: geriGidebilir, title: Text("Profil", style: TextStyle(color: Colors.white70, fontFamily: _fontFamilyBebas, fontSize: 20))),
        body: Column(children: [
          const SizedBox(height: 16),
          IskeletKutu(genislik: 96, yukseklik: 96, borderRadius: BorderRadius.circular(48)),
          const SizedBox(height: 12),
          IskeletKutu(genislik: 140, yukseklik: 14, borderRadius: BorderRadius.circular(7)),
          const SizedBox(height: 24),
          IskeletKutu(genislik: 240, yukseklik: 30, borderRadius: BorderRadius.circular(8)),
        ]),
      );
    }

    final bool isCurrentUserProfile = _kendiProfili;
    final Kullanici kullanici = _kullanici ?? widget.aktifKullanici!;
    final bool dogrulanmis = kullanici.isVerified ?? false;
    final String hakkinda = kullanici.hakkinda?.trim() ?? "";

    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: RefreshIndicator(
        onRefresh: _verileriYukle,
        color: theme.primaryColor,
        backgroundColor: Color(0xFF121212),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Color(0xFF121212), elevation: 0, pinned: true, floating: true, automaticallyImplyLeading: geriGidebilir,
              title: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(_kullaniciAdi, style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 20, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                if (dogrulanmis) Padding(padding: const EdgeInsets.only(left: 6.0), child: Icon(Icons.verified_rounded, color: Colors.redAccent[400], size: 18)),
              ]),
              centerTitle: true,
              actions: <Widget>[
                if (isCurrentUserProfile)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.white70),
                    color: Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(value: 'duzenle', child: Row(children: [Icon(Icons.edit_outlined, color: Colors.white70, size: 18), SizedBox(width: 8), Text('Profili Düzenle', style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 15))])),
                      PopupMenuItem<String>(value: 'cikis', child: Row(children: [Icon(Icons.exit_to_app_rounded, color: Colors.redAccent[100], size: 18), SizedBox(width: 8), Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent[100], fontFamily: _fontFamilyBebas, fontSize: 15))])),
                    ],
                    onSelected: (String value) {
                      if (value == 'duzenle') _profiliDuzenle();
                      else if (value == 'cikis') _cikisYap();
                    },
                  )
                else if (_oturumId != null)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.white70),
                    color: Color(0xFF1E1E1E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(value: 'engel', child: Row(children: [Icon(_engellendi ? Icons.lock_open_rounded : Icons.block_rounded, color: Colors.redAccent[100], size: 18), SizedBox(width: 8), Text(_engellendi ? 'Engeli Kaldır' : 'Kullanıcıyı Engelle', style: TextStyle(color: Colors.redAccent[100], fontFamily: _fontFamilyBebas, fontSize: 15))])),
                    ],
                    onSelected: (_) => _engelDegistir(),
                  ),
              ],
            ),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 6.0), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              Stack(clipBehavior: Clip.none, alignment: Alignment.bottomRight, children: [
                KullaniciAvatari(fotoUrl: kullanici.fotoUrl, kullaniciAdi: _kullaniciAdi, yaricap: 48),
                if (isCurrentUserProfile) Positioned(bottom: -3, right: -3, child: Material(color: theme.primaryColor, shape: CircleBorder(side: BorderSide(color: Color(0xFF0A0A0A), width: 2.2)), elevation: 2.0, child: InkWell(onTap: _profiliDuzenle, customBorder: CircleBorder(), child: Padding(padding: const EdgeInsets.all(5.0), child: Icon(Icons.edit_rounded, color: Colors.white, size: 15.0))))),
              ]),
              SizedBox(height: 8.0),
              Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(_kullaniciAdi, style: TextStyle(color: Colors.white, fontSize: 17.0, fontWeight: FontWeight.bold, fontFamily: _fontFamilyBebas), overflow: TextOverflow.ellipsis)),
                if (dogrulanmis) Padding(padding: const EdgeInsets.only(left: 5.0), child: Icon(Icons.verified_user_rounded, color: Colors.redAccent[400], size: 16)),
              ]),
              SizedBox(height: 4.0),
              if (hakkinda.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(hakkinda, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 12.5, fontFamily: _fontFamilyBebas, height: 1.35), maxLines: 3, overflow: TextOverflow.ellipsis)),
              SizedBox(height: 12.0),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                _sosyalSayac(baslik: "Paylaşım", sayi: _tumGonderiler.isNotEmpty ? _tumGonderiler.length : (kullanici.gonderiSayisi ?? 0)),
                _sosyalSayac(baslik: "Takipçi", sayi: kullanici.takipciSayisi ?? 0, onTap: () => _takipListesiAc(0)),
                _sosyalSayac(baslik: "Takip", sayi: kullanici.takipEdilenSayisi ?? 0, onTap: () => _takipListesiAc(1)),
              ])),
              SizedBox(height: 14.0),
              if (isCurrentUserProfile)
                SizedBox(width: MediaQuery.of(context).size.width * 0.55, child: ElevatedButton.icon(icon: Icon(Icons.edit_note_outlined, color: Colors.white, size: 17), onPressed: _profiliDuzenle, label: Text("Profili Düzenle", style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 14)), style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor.withOpacity(0.75), padding: EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)), elevation: 1)))
              else if (_engellendi)
                OutlinedButton.icon(onPressed: _engelDegistir, icon: const Icon(Icons.lock_open_rounded, size: 17), label: const Text("Engeli Kaldır"), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent[100]))
              else
                SizedBox(width: MediaQuery.of(context).size.width * 0.55, child: TakipButonu(hedefKullaniciId: kullanici.id, genis: true, onDegisti: (_) => _verileriYukle())),
              SizedBox(height: 10.0),
            ]))),
            SliverToBoxAdapter(child: _buildGeziOzeti(theme)),
            if (isCurrentUserProfile) _buildSekmeler(theme) else SliverToBoxAdapter(child: Divider(color: Colors.grey[800]?.withOpacity(0.7), height: 12, thickness: 0.6, indent: 20, endIndent: 20)),
            if (_seciliSekme == 0 || !isCurrentUserProfile) ...[
              _buildSehirFiltreBar(theme),
              _buildGonderiIzgarasi(),
            ] else
              _buildKaydedilenler(),
            if (isCurrentUserProfile)
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 16.0, bottom: 20.0), child: Column(children: [
                _buildOptionListTile(icon: Icons.help_outline_rounded, title: "Yardım & Destek", onTap: _yardimGoster),
                _buildOptionListTile(icon: Icons.info_outline_rounded, title: "Uygulama Hakkında", onTap: _hakkindaGoster),
              ])))
            else
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _YardimMaddesi extends StatelessWidget {
  final IconData ikon;
  final String metin;

  const _YardimMaddesi({required this.ikon, required this.metin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ikon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(metin, style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.35))),
      ]),
    );
  }
}
