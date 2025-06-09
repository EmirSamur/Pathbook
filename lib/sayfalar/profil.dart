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

  String _kullaniciAdi = "Yükleniyor...";
  String _hakkinda = "Yükleniyor...";
  String _avatarUrl = "";
  int _gonderiSayisi = 0;
  int _toplamGonderiSayisiCache = 0;
  int _takipciSayisi = 0;
  int _takipEdilenSayisi = 0;
  bool _isVerifiedAccount = false; // Mavi tik durumu

  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;

  List<String> _kullanicininSehirleri = [];
  String? _seciliSehirFiltresi;
  bool _sehirlerYukleniyor = true;
  bool _profilBilgileriYukleniyor = true;

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

  void _resetKullaniciVerileri() {
    if (!mounted) return;
    setState(() {
      _kullaniciAdi = "Kullanıcı Yok";
      _hakkinda = "-";
      _avatarUrl = "";
      _gonderiSayisi = 0;
      _toplamGonderiSayisiCache = 0;
      _takipciSayisi = 0;
      _takipEdilenSayisi = 0;
      _isVerifiedAccount = false;
      _kullanicininSehirleri = [];
      _seciliSehirFiltresi = null;
      _sehirlerYukleniyor = true;
      _profilBilgileriYukleniyor = true;
    });
  }

  Future<void> _verileriYukle() async {
    if (widget.aktifKullanici == null) {
      _resetKullaniciVerileri();
      return;
    }
    if (!mounted) return;
    setState(() {
      _profilBilgileriYukleniyor = true;
      _sehirlerYukleniyor = true;
    });

    await _kullaniciProfilBilgileriniYukle();
    if (mounted && widget.aktifKullanici != null) {
      await _kullanicininPaylastigiSehirleriGetirServisten();
    }

    if (mounted) {
      setState(() {
        _profilBilgileriYukleniyor = false;
        _sehirlerYukleniyor = false;
      });
    }
  }

  Future<void> _kullaniciProfilBilgileriniYukle() async {
    if (widget.aktifKullanici == null) {
      if (mounted) setState(() => _profilBilgileriYukleniyor = false);
      return;
    }
    Kullanici? kullanici = await _firestoreServisi.kullaniciGetir(widget.aktifKullanici!.id);
    if (kullanici == null) {
      if (mounted) { _resetKullaniciVerileri(); setState(() => _profilBilgileriYukleniyor = false); }
      return;
    }
    if (!mounted) return;
    setState(() {
      _kullaniciAdi = kullanici.kullaniciAdi?.isNotEmpty == true ? kullanici.kullaniciAdi! : (kullanici.email?.split('@')[0] ?? "Bilinmiyor");
      _hakkinda = kullanici.hakkinda?.isNotEmpty == true ? kullanici.hakkinda! : "Henüz hakkında bilgisi eklenmemiş.";
      _avatarUrl = kullanici.fotoUrl ?? "";
      _toplamGonderiSayisiCache = kullanici.gonderiSayisi ?? 0;
      _gonderiSayisi = _seciliSehirFiltresi == null ? _toplamGonderiSayisiCache : _gonderiSayisi;
      _takipciSayisi = kullanici.takipciSayisi ?? 0;
      _takipEdilenSayisi = kullanici.takipEdilenSayisi ?? 0;
      _isVerifiedAccount = kullanici.isVerified ?? false; // Mavi tik durumu alınıyor
    });
  }

  Future<void> _kullanicininPaylastigiSehirleriGetirServisten() async {
    if (widget.aktifKullanici == null || !mounted) return;
    try {
      List<String> sehirler = await _firestoreServisi.kullanicininPaylastigiSehirleriGetir(widget.aktifKullanici!.id);
      if (mounted) {
        setState(() => _kullanicininSehirleri = sehirler);
      }
    } catch (e) {
      if (mounted) setState(() => _kullanicininSehirleri = []);
    }
  }

  void _cikisYap() { _yetkilendirmeServisi.cikisYap(); }

  void _profiliDuzenle() async {
    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    if (widget.aktifKullanici == null || oAnkiAktifKullaniciId != widget.aktifKullanici!.id) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bu profili düzenleme yetkiniz yok.")));
      return;
    }
    final bool? guncellemeOldu = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfiliDuzenleSayfasi(mevcutKullanici: widget.aktifKullanici!)));
    if (guncellemeOldu == true && mounted) {
      await _kullaniciProfilBilgileriniYukle();
    }
  }

  Future<void> _gonderiyiSilOnayiGoster(Gonderi gonderi) async {
    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
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
            if (gonderi.resimUrls.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(6.0), child: Image.network(gonderi.resimUrls[0], height: 100, fit: BoxFit.contain, errorBuilder: (c,e,s) => Container(height:100, child: Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 40)))),
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

  Widget _buildOptionListTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap, Color iconColor = Colors.white, Color iconBackgroundColor = const Color(0xFF2C2C2E)}) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: iconBackgroundColor, child: Icon(icon, color: iconColor, size: 19), radius: 19),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: _fontFamilyBebas)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontFamily: _fontFamilyBebas)) : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
    );
  }

  Widget _sosyalSayac({required String baslik, required int sayi}) {
    return Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Text(sayi.toString(), style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: _fontFamilyBebas)),
      SizedBox(height: 1.5),
      Text(baslik, style: TextStyle(fontSize: 12.5, color: Colors.grey[400], fontFamily: _fontFamilyBebas)),
    ]);
  }

  Widget _buildSehirFiltreBar(ThemeData theme) {
    if (_sehirlerYukleniyor && _kullanicininSehirleri.isEmpty) {
      return SliverToBoxAdapter(child: Container(height: 38, alignment: Alignment.center, child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.8, color: theme.primaryColor.withOpacity(0.6)))));
    }
    if (_kullanicininSehirleri.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }
    List<Widget> filtreCipleri = [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 3.0), child: ChoiceChip(
        label: Text("Tümü", style: TextStyle(fontSize: 12, color: _seciliSehirFiltresi == null ? Colors.white : Colors.grey[350], fontWeight: _seciliSehirFiltresi == null ? FontWeight.bold : FontWeight.normal)),
        selected: _seciliSehirFiltresi == null,
        onSelected: (selected) { if (mounted && selected) setState(() => _seciliSehirFiltresi = null); },
        backgroundColor: Colors.grey[800]?.withOpacity(0.7), selectedColor: theme.primaryColor,
        labelPadding: EdgeInsets.symmetric(horizontal: 10), padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.transparent)), visualDensity: VisualDensity.compact,
      ))
    ];
    for (String sehir in _kullanicininSehirleri) {
      filtreCipleri.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 3.0), child: ChoiceChip(
        label: Text(sehir, style: TextStyle(fontSize: 12, color: _seciliSehirFiltresi == sehir ? Colors.white : Colors.grey[350], fontWeight: _seciliSehirFiltresi == sehir ? FontWeight.bold : FontWeight.normal)),
        selected: _seciliSehirFiltresi == sehir,
        onSelected: (selected) { if (mounted && selected) setState(() => _seciliSehirFiltresi = sehir); },
        avatar: Icon(Icons.location_city_rounded, size: 14, color: _seciliSehirFiltresi == sehir ? Colors.white70 : Colors.grey[500]),
        backgroundColor: Colors.grey[800]?.withOpacity(0.7), selectedColor: theme.primaryColor,
        labelPadding: EdgeInsets.only(left: 1, right: 8), padding: EdgeInsets.only(left: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.transparent)), visualDensity: VisualDensity.compact,
      )));
    }
    return SliverToBoxAdapter(child: Container(height: 38, margin: const EdgeInsets.only(bottom: 6.0, top: 4.0), child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12.0), children: filtreCipleri)));
  }

  Widget _buildGonderiIzgarasi() {
    if (widget.aktifKullanici == null || widget.aktifKullanici!.id.isEmpty) {
      return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Kullanıcı bilgisi yüklenemedi.", style: TextStyle(color: Colors.grey[500])))));
    }
    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    final bool isOwnProfile = oAnkiAktifKullaniciId == widget.aktifKullanici!.id;

    Stream<QuerySnapshot<Map<String, dynamic>>> gonderiStream;
    if (_seciliSehirFiltresi != null && _seciliSehirFiltresi!.isNotEmpty) {
      gonderiStream = _firestoreServisi.kullanicininSehirGonderileriniGetir(kullaniciId: widget.aktifKullanici!.id, sehir: _seciliSehirFiltresi!);
    } else {
      gonderiStream = _firestoreServisi.kullaniciGonderileriniGetir(widget.aktifKullanici!.id);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: gonderiStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          String errorMessage = 'Paylaşımlar yüklenirken bir sorun oluştu.';
          if (snapshot.error.toString().contains("FAILED_PRECONDITION") && snapshot.error.toString().contains("index")) errorMessage = 'Veritabanı yapılandırması gerekiyor. Lütfen tekrar deneyin.';
          return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20.0), child: Center(child: Text(errorMessage, style: TextStyle(color: Colors.orangeAccent[100], fontSize: 13.5), textAlign: TextAlign.center))));
        }
        if (snapshot.connectionState == ConnectionState.waiting && !(snapshot.hasData && snapshot.data!.docs.isNotEmpty)) {
          return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0), child: Center(child: CircularProgressIndicator(strokeWidth: 1.8, color: Theme.of(context).primaryColor.withOpacity(0.8)))));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          String mesaj = _seciliSehirFiltresi != null ? "'$_seciliSehirFiltresi' şehrinde hiç paylaşım yok." : 'Henüz hiç paylaşım yapılmamış.';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _gonderiSayisi != 0) setState(() => _gonderiSayisi = 0);
          });
          return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.dynamic_feed_outlined, size: 35, color: Colors.grey[600]), SizedBox(height: 10), Text(mesaj, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontFamily: _fontFamilyBebas, fontSize: 17))]))));
        }
        final gonderiDocs = snapshot.data!.docs;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _gonderiSayisi != gonderiDocs.length) setState(() => _gonderiSayisi = gonderiDocs.length);
          if (_seciliSehirFiltresi == null && mounted && _toplamGonderiSayisiCache != gonderiDocs.length) {
            // Kullanıcı modelinden gelen toplam sayı daha güvenilir olabilir,
            // ama stream'den gelen tüm gönderiler de bir gösterge.
            // _kullaniciProfilBilgileriniYukle içinde _toplamGonderiSayisiCache güncelleniyor.
            // Bu satır isteğe bağlı olarak kaldırılabilir veya farklı bir mantıkla güncellenebilir.
            // setState(() => _toplamGonderiSayisiCache = gonderiDocs.length);
          }
        });
        return SliverPadding(
          padding: const EdgeInsets.all(1.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0, childAspectRatio: 1.0),
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                final gonderiDoc = gonderiDocs[index];
                final Gonderi gonderi = Gonderi.dokumandanUret(gonderiDoc, yayinlayan: widget.aktifKullanici); // yayinlayan: widget.aktifKullanici (görüntülenen profilin sahibi)
                String? ilkResimUrl = gonderi.resimUrls.isNotEmpty ? gonderi.resimUrls[0] : null;
                if (ilkResimUrl == null) return Container(decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(1.5)), child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[700], size: 18));
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: gonderi))),
                  onLongPress: isOwnProfile && gonderi.kullaniciId == oAnkiAktifKullaniciId ? () => _gonderiyiSilOnayiGoster(gonderi) : null,
                  child: ClipRRect(borderRadius: BorderRadius.circular(1.5), child: Hero(
                    tag: "profil_gonderi_resim_${gonderi.id}_${widget.aktifKullanici?.id ?? 'default'}", // widget.aktifKullanici null olabilir
                    child: Image.network(ilkResimUrl, fit: BoxFit.cover,
                      loadingBuilder: (c, child, progress) => progress == null ? child : Container(color: Colors.grey[800]),
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[850], child: Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 18)),
                    ),
                  )),
                );
              },
              childCount: gonderiDocs.length,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_profilBilgileriYukleniyor || widget.aktifKullanici == null) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        appBar: AppBar(backgroundColor: Color(0xFF121212), elevation: 0, title: Text(_kullaniciAdi == "Yükleniyor..." ? "Profil" : _kullaniciAdi, style: TextStyle(color: Colors.white70, fontFamily: _fontFamilyBebas, fontSize: 20))),
        body: Center(child: CircularProgressIndicator(color: theme.primaryColor.withOpacity(0.7))),
      );
    }

    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    final bool isCurrentUserProfile = oAnkiAktifKullaniciId == widget.aktifKullanici!.id;

    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: RefreshIndicator(
        onRefresh: _verileriYukle,
        color: theme.primaryColor,
        backgroundColor: Color(0xFF121212),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Color(0xFF121212), elevation: 0, pinned: true, floating: true, automaticallyImplyLeading: false,
              title: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(_kullaniciAdi, style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 20, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                if (_isVerifiedAccount) Padding(padding: const EdgeInsets.only(left: 6.0), child: Icon(Icons.verified_rounded, color: Colors.redAccent[400], size: 18)),
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
                  ),
              ],
            ),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 15.0), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(radius: 48.0, backgroundColor: Colors.grey[850], backgroundImage: _avatarUrl.isNotEmpty && _avatarUrl.startsWith("http") ? NetworkImage(_avatarUrl) : null, child: _avatarUrl.isEmpty || !_avatarUrl.startsWith("http") ? Icon(Icons.person_outline_rounded, size: 48, color: Colors.grey[700]) : null),
                if (isCurrentUserProfile) Positioned(bottom: -3, right: -3, child: Material(color: theme.primaryColor, shape: CircleBorder(side: BorderSide(color: Color(0xFF0A0A0A), width: 2.2)), elevation: 2.0, child: InkWell(onTap: _profiliDuzenle, customBorder: CircleBorder(), child: Padding(padding: const EdgeInsets.all(5.0), child: Icon(Icons.edit_rounded, color: Colors.white, size: 15.0))))),
              ]),
              SizedBox(height: 8.0),
              Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(_kullaniciAdi, style: TextStyle(color: Colors.white, fontSize: 17.0, fontWeight: FontWeight.bold, fontFamily: _fontFamilyBebas), overflow: TextOverflow.ellipsis)),
                if (_isVerifiedAccount) Padding(padding: const EdgeInsets.only(left: 5.0), child: Icon(Icons.verified_user_rounded, color: Colors.redAccent[400], size: 16)),
              ]),
              SizedBox(height: 4.0),
              if (_hakkinda.isNotEmpty && _hakkinda != "Henüz hakkında bilgisi eklenmemiş.") Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(_hakkinda, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 12.5, fontFamily: _fontFamilyBebas, height: 1.35), maxLines: 3, overflow: TextOverflow.ellipsis)),
              SizedBox(height: 14.0),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                _sosyalSayac(baslik: "Paylaşım", sayi: _toplamGonderiSayisiCache),
                _sosyalSayac(baslik: "Takipçi", sayi: _takipciSayisi),
                _sosyalSayac(baslik: "Takip", sayi: _takipEdilenSayisi),
              ])),
              SizedBox(height: 16.0),
              if (isCurrentUserProfile) SizedBox(width: MediaQuery.of(context).size.width * 0.55, child: ElevatedButton.icon(icon: Icon(Icons.edit_note_outlined, color: Colors.white, size: 17), onPressed: _profiliDuzenle, label: Text("Profili Düzenle", style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 14)), style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor.withOpacity(0.75), padding: EdgeInsets.symmetric(vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)), elevation: 1))),
              SizedBox(height: isCurrentUserProfile ? 12.0 : 0),
              Divider(color: Colors.grey[800]?.withOpacity(0.7), height: 20, thickness: 0.6, indent: 20, endIndent: 20),
            ]))),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 2.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text(_seciliSehirFiltresi == null ? "Tüm Paylaşımlar" : "'$_seciliSehirFiltresi' Paylaşımları", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, fontFamily: _fontFamilyBebas, fontWeight: FontWeight.w500)),
                  if (!_sehirlerYukleniyor) Text("(${_gonderiSayisi} sonuç)", style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: _fontFamilyBebas)),
                ]),
              ),
            ),
            _buildSehirFiltreBar(theme),
            _buildGonderiIzgarasi(),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 16.0, bottom: 20.0), child: Column(children: [
              _buildOptionListTile(icon: Icons.help_outline_rounded, title: "Yardım & Destek", onTap: () {}),
              _buildOptionListTile(icon: Icons.info_outline_rounded, title: "Uygulama Hakkında", onTap: () {}),
            ]))),
          ],
        ),
      ),
    );
  }
}