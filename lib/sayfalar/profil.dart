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
  final Kullanici? aktifKullanici; // Görüntülenen kullanıcının bilgisi

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
  int _takipciSayisi = 0;
  int _takipEdilenSayisi = 0;

  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);
    _kullaniciVerileriniYukle();
  }

  @override
  void didUpdateWidget(covariant Profil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aktifKullanici != oldWidget.aktifKullanici) {
      _kullaniciVerileriniYukle();
    }
  }

  void _resetKullaniciVerileri() {
    if (!mounted) return;
    setState(() {
      _kullaniciAdi = "Kullanıcı Yok";
      _hakkinda = "-";
      _avatarUrl = "";
      _gonderiSayisi = 0;
      _takipciSayisi = 0;
      _takipEdilenSayisi = 0;
    });
  }

  Future<void> _kullaniciVerileriniYukle() async {
    if (widget.aktifKullanici == null) {
      _resetKullaniciVerileri();
      return;
    }
    // widget.aktifKullanici'dan temel bilgileri al, gerekirse Firestore'dan tam veriyi çek
    Kullanici? kullaniciToDisplay = widget.aktifKullanici;
    if (widget.aktifKullanici!.kullaniciAdi == null || widget.aktifKullanici!.hakkinda == null) { // Örnek eksik bilgi kontrolü
      kullaniciToDisplay = await _firestoreServisi.kullaniciGetir(widget.aktifKullanici!.id);
    }
    final kullanici = kullaniciToDisplay ?? widget.aktifKullanici!;


    if (!mounted) return;
    setState(() {
      _kullaniciAdi = kullanici.kullaniciAdi?.isNotEmpty == true
          ? kullanici.kullaniciAdi!
          : (kullanici.email?.split('@')[0] ?? "Bilinmiyor");
      _hakkinda = kullanici.hakkinda?.isNotEmpty == true
          ? kullanici.hakkinda!
          : "Henüz hakkında bilgisi eklenmemiş.";
      _avatarUrl = kullanici.fotoUrl ?? "";

    });
  }

  void _cikisYap() {
    _yetkilendirmeServisi.cikisYap();
  }

  void _profiliDuzenle() async {
    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    if (widget.aktifKullanici == null || oAnkiAktifKullaniciId != widget.aktifKullanici!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bu profili düzenleme yetkiniz yok.")));
      return;
    }

    final bool? guncellemeOldu = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfiliDuzenleSayfasi(mevcutKullanici: widget.aktifKullanici!),
      ),
    );

    if (guncellemeOldu == true && mounted) {
      Kullanici? guncellenmisKullanici = await _firestoreServisi.kullaniciGetir(widget.aktifKullanici!.id);
      if (guncellenmisKullanici != null) {
        _yetkilendirmeServisi.aktifKullaniciGuncelleVeYenidenYukle(guncellenmisKullanici);
        if (mounted) {
          setState(() {
            _kullaniciAdi = guncellenmisKullanici.kullaniciAdi?.isNotEmpty == true ? guncellenmisKullanici.kullaniciAdi! : (guncellenmisKullanici.email?.split('@')[0] ?? "Bilinmiyor");
            _hakkinda = guncellenmisKullanici.hakkinda ?? "Henüz hakkında bilgisi eklenmemiş.";
            _avatarUrl = guncellenmisKullanici.fotoUrl ?? "";

          });
        }
      }
    }
  }

  Future<void> _gonderiyiSilOnayiGoster(Gonderi gonderi) async {
    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    if (oAnkiAktifKullaniciId == null || oAnkiAktifKullaniciId != gonderi.kullaniciId) {
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text('Gönderiyi Sil', style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 20)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bu gönderiyi kalıcı olarak silmek istediğinizden emin misiniz?', style: TextStyle(color: Colors.grey[300], fontSize: 14)),
                SizedBox(height: 15),
                if (gonderi.resimUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(gonderi.resimUrls[0], height: 120, fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(height:100, child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600])),
                    ),
                  ),
                if (gonderi.aciklama.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text("\"${gonderi.aciklama.length > 60 ? gonderi.aciklama.substring(0, 60) + "..." : gonderi.aciklama}\"",
                        style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic, fontSize: 13)),
                  ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          actions: <Widget>[
            TextButton(
              child: Text('İptal', style: TextStyle(color: Colors.grey[400], fontFamily: _fontFamilyBebas, fontSize: 15)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Sil', style: TextStyle(color: Colors.redAccent, fontFamily: _fontFamilyBebas, fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _firestoreServisi.gonderiSil(gonderiId: gonderi.id, kullaniciId: oAnkiAktifKullaniciId);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi başarıyla silindi.'), backgroundColor: Colors.green[700]));
                  if (mounted) {
                    setState(() { _gonderiSayisi = _gonderiSayisi > 0 ? _gonderiSayisi - 1 : 0; });
                    // Eğer Kullanici modelini YetkilendirmeServisi üzerinden güncelliyorsanız,
                    // ve o da Provider ile dinleniyorsa, _kullaniciVerileriniYukle'yi çağırmak
                    // veya YetkilendirmeServisi'ndeki kullanıcıyı yenilemek daha doğru olabilir.
                    // Şimdilik sadece sayacı azaltıyoruz, StreamBuilder listeyi güncelleyecek.
                    Kullanici? guncelKullanici = await _firestoreServisi.kullaniciGetir(oAnkiAktifKullaniciId);
                    if(guncelKullanici != null) _yetkilendirmeServisi.aktifKullaniciGuncelleVeYenidenYukle(guncelKullanici);

                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderi silinirken bir hata oluştu.'), backgroundColor: Colors.red[700]));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color iconColor = Colors.white,
    Color iconBackgroundColor = const Color(0xFF2C2C2E), // Daha koyu
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconBackgroundColor,
        child: Icon(icon, color: iconColor, size: 20), // İkon boyutu
        radius: 20, // Radius
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 17, fontFamily: _fontFamilyBebas), // Font boyutu
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14, fontFamily: _fontFamilyBebas)) // Font boyutu
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0), // Dikey padding
    );
  }

  Widget _sosyalSayac({required String baslik, required int sayi}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          sayi.toString(),
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: _fontFamilyBebas),
        ),
        SizedBox(height: 2.0),
        Text(
          baslik,
          style: TextStyle(fontSize: 13.0, color: Colors.grey[400], fontFamily: _fontFamilyBebas),
        ),
      ],
    );
  }

  Widget _buildGonderiIzgarasi() {
    if (widget.aktifKullanici == null || widget.aktifKullanici!.id.isEmpty) {
      return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Kullanıcı bilgisi bulunamadı.", style: TextStyle(color: Colors.grey[500])))));
    }

    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    final bool isOwnProfile = oAnkiAktifKullaniciId == widget.aktifKullanici!.id;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestoreServisi.kullaniciGonderileriniGetir(widget.aktifKullanici!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          String errorMessage = 'Gönderiler yüklenirken bir hata oluştu.';
          if (snapshot.error.toString().contains("FAILED_PRECONDITION") && snapshot.error.toString().contains("index")) {
            errorMessage = 'Veritabanı yapılandırması gerekiyor. Lütfen daha sonra tekrar deneyin.';
            print("Firestore Index Hatası: ${snapshot.error}"); // Geliştirici için log
          }
          return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20.0), child: Center(child: Text(errorMessage, style: TextStyle(color: Colors.orangeAccent, fontSize: 14), textAlign: TextAlign.center))));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Theme.of(context).primaryColor))));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _gonderiSayisi != 0) { // Sadece kendi profilindeyse değil, her zaman sıfırla
              setState(() { _gonderiSayisi = 0; });
            }
          });
          return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.grid_off_rounded, size: 40, color: Colors.grey[600]), SizedBox(height: 12), Text('Henüz hiç paylaşım yok.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontFamily: _fontFamilyBebas, fontSize: 18))]))));
        }

        final gonderiDocs = snapshot.data!.docs;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _gonderiSayisi != gonderiDocs.length) {
            setState(() { _gonderiSayisi = gonderiDocs.length; });
          }
        });

        return SliverPadding(
          padding: const EdgeInsets.all(1.0), // Daha sıkı
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0, childAspectRatio: 1.0),
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                try {
                  final gonderiDoc = gonderiDocs[index] as DocumentSnapshot<Map<String, dynamic>>;
                  final Gonderi gonderi = Gonderi.dokumandanUret(gonderiDoc, yayinlayan: widget.aktifKullanici);

                  String? ilkResimUrl = gonderi.resimUrls.isNotEmpty ? gonderi.resimUrls[0] : null;

                  if (ilkResimUrl == null || ilkResimUrl.isEmpty) {
                    return Container(decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(2)), child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[700], size: 20));
                  }
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: gonderi))),
                    onLongPress: isOwnProfile && gonderi.kullaniciId == oAnkiAktifKullaniciId ? () => _gonderiyiSilOnayiGoster(gonderi) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2.0), // Daha az yuvarlaklık
                      child: Hero(
                        tag: "profil_gonderi_resim_${gonderi.id}_${widget.aktifKullanici!.id}",
                        child: Image.network(ilkResimUrl, fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Container(color: Colors.grey[800]),
                          errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[850], child: Icon(Icons.broken_image_outlined, color: Colors.grey[600], size: 20)),
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  return Container(decoration: BoxDecoration(color: Colors.red[900]?.withOpacity(0.4), borderRadius: BorderRadius.circular(2)), child: Icon(Icons.error_outline, color: Colors.white60, size: 20));
                }
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
    if (widget.aktifKullanici == null) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0A0A), // Daha da koyu bir arka plan
        appBar: AppBar(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          title: Text("Profil", style: TextStyle(color: Colors.white70, fontFamily: _fontFamilyBebas, fontSize: 22)),
        ),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Theme.of(context).primaryColor.withOpacity(0.7)), SizedBox(height: 18), Text("Kullanıcı bekleniyor...", style: TextStyle(color: Colors.white54, fontFamily: _fontFamilyBebas, fontSize: 16))])),
      );
    }

    final String? oAnkiAktifKullaniciId = _yetkilendirmeServisi.aktifKullaniciId;
    final bool isCurrentUserProfile = oAnkiAktifKullaniciId == widget.aktifKullanici!.id;

    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: RefreshIndicator(
        onRefresh: () async {
          await _kullaniciVerileriniYukle();
          if (mounted) setState(() {}); // StreamBuilder'ı tetikle
        },
        color: Theme.of(context).primaryColor,
        backgroundColor: Color(0xFF121212),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Color(0xFF121212),
              elevation: 0, // AppBar altı çizgi olmasın
              pinned: true,
              floating: true,
              automaticallyImplyLeading: false,
              title: Text(_kullaniciAdi, style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 20, fontWeight: FontWeight.w500)),
              centerTitle: true,
              actions: <Widget>[
                if (isCurrentUserProfile)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.white70), // Daha belirgin ikon
                    color: Color(0xFF1E1E1E), // Menü arka planı
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(value: 'duzenle', child: Row(children: [Icon(Icons.edit_outlined, color: Colors.white70, size: 18), SizedBox(width: 8), Text('Profili Düzenle', style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 15))])),
                      PopupMenuItem<String>(value: 'cikis', child: Row(children: [Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 18), SizedBox(width: 8), Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent, fontFamily: _fontFamilyBebas, fontSize: 15))])),
                    ],
                    onSelected: (String value) {
                      if (value == 'duzenle') _profiliDuzenle();
                      else if (value == 'cikis') _cikisYap();
                    },
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50.0,
                          backgroundColor: Colors.grey[850],
                          backgroundImage: _avatarUrl.isNotEmpty && _avatarUrl.startsWith("http") ? NetworkImage(_avatarUrl) : null,
                          child: _avatarUrl.isEmpty || !_avatarUrl.startsWith("http") ? Icon(Icons.person_outline_rounded, size: 50, color: Colors.grey[700]) : null,
                        ),
                        if (isCurrentUserProfile)
                          Positioned(
                            bottom: -2, right: -2, // Daha iyi konumlandırma
                            child: Material(
                              color: Theme.of(context).primaryColor.withOpacity(0.9),
                              shape: CircleBorder(side: BorderSide(color: Color(0xFF0A0A0A), width: 2.5)), // Çerçeve
                              elevation: 3.0,
                              child: InkWell(
                                onTap: _profiliDuzenle, customBorder: CircleBorder(),
                                child: Padding(padding: const EdgeInsets.all(6.0), child: Icon(Icons.edit_rounded, color: Colors.white, size: 16.0)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Text(_kullaniciAdi, style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold, fontFamily: _fontFamilyBebas)),
                    SizedBox(height: 5.0),
                    if (_hakkinda.isNotEmpty && _hakkinda != "Henüz hakkında bilgisi eklenmemiş.")
                      Text(_hakkinda, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 13.0, fontFamily: _fontFamilyBebas, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          _sosyalSayac(baslik: "Paylaşım", sayi: _gonderiSayisi),
                          _sosyalSayac(baslik: "Takipçi", sayi: _takipciSayisi),
                          _sosyalSayac(baslik: "Takip", sayi: _takipEdilenSayisi),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    if (isCurrentUserProfile)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6, // Genişliği ayarla
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.edit_note_outlined, color: Colors.white, size: 18),
                          onPressed: _profiliDuzenle,
                          label: Text("Profili Düzenle", style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Daha yuvarlak
                            elevation: 2,
                          ),
                        ),
                      ),
                    SizedBox(height: isCurrentUserProfile ? 16.0 : 0),
                    Divider(color: Colors.grey[850], height: 25, thickness: 0.5),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 0.0, bottom: 8.0),
                child: Text("Paylaşımlar", style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: _fontFamilyBebas, fontWeight: FontWeight.w500)),
              ),
            ),
            _buildGonderiIzgarasi(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(children: [

                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}