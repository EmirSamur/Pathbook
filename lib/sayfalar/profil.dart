// profil_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/sayfalar/profili_duzenle_sayfasi.dart'; // ProfiliDuzenleSayfasi'nı import et

class Profil extends StatefulWidget {
  final Kullanici? aktifKullanici;

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

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    if (widget.aktifKullanici != null) {
      _kullaniciVerileriniYukle();
    }
  }

  @override
  void didUpdateWidget(covariant Profil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aktifKullanici != oldWidget.aktifKullanici) {
      if (widget.aktifKullanici != null) {
        _kullaniciVerileriniYukle();
      } else {
        setState(() {
          _kullaniciAdi = "Kullanıcı Yok";
          _hakkinda = "-";
          _avatarUrl = "";
          _gonderiSayisi = 0;
          _takipciSayisi = 0;
          _takipEdilenSayisi = 0;
        });
      }
    }
  }

  void _kullaniciVerileriniYukle() {
    final kullanici = widget.aktifKullanici!;
    setState(() {
      _kullaniciAdi = (kullanici.kullaniciAdi!.isNotEmpty // Sizin kodunuzdaki ! operatörü kaldırıldı, null check ile daha güvenli
          ? kullanici.kullaniciAdi
          : (kullanici.email?.split('@')[0] ?? "Bilinmiyor"))!;
      _hakkinda = kullanici.hakkinda?.isNotEmpty == true
          ? kullanici.hakkinda!
          : "Henüz hakkında bilgisi eklenmemiş.";
      _avatarUrl = kullanici.fotoUrl ?? "";

      // Kullanici modelinden sayısal verileri çek

    });
    print("Profil: Kullanıcı verileri yüklendi - Adı: $_kullaniciAdi, Gönderi: $_gonderiSayisi");
  }

  void _cikisYap() {
    Provider.of<YetkilendirmeServisi>(context, listen: false).cikisYap();
  }

  // DÜZELTİLMİŞ VE DOLDURULMUŞ METOD
  void _profiliDuzenle() async {
    print("Profili Düzenle butonuna basıldı - Metodun başı");
    if (widget.aktifKullanici == null) {
      print("HATA: aktifKullanici null, düzenleme sayfasına gidilemiyor.");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kullanıcı bilgileri yüklenemedi, lütfen tekrar deneyin.")));
      return;
    }

    print("Navigator.push çağrılacak. Kullanıcı: ${widget.aktifKullanici!.kullaniciAdi}");
    final bool? guncellemeOldu = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfiliDuzenleSayfasi(mevcutKullanici: widget.aktifKullanici!),
      ),
    );
    print("ProfiliDuzenleSayfasi'ndan dönüldü. guncellemeOldu: $guncellemeOldu");

    if (guncellemeOldu == true && mounted) {
      print("Güncelleme oldu, veriler Profil sayfasında yenileniyor...");
      // YetkilendirmeServisi zaten güncellenmiş olmalı (aktifKullaniciGuncelleVeYenidenYukle ile)
      // Provider'ı dinleyen bu widget (veya bir üstü) güncel veriyi alacaktır.
      // Ancak state'i doğrudan güncellemek de anlık yansıma için iyi olabilir.
      final guncelDetaylar = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciDetaylari;
      if (guncelDetaylar != null) {
        // widget.aktifKullanici'yı direkt değiştiremeyiz, bu yüzden state'i güncelliyoruz.
        // Veya Profil widget'ının kendisinin YetkilendirmeServisi'ni dinlemesi (Consumer/watch ile)
        // ve widget.aktifKullanici yerine Provider'dan gelen güncel kullanıcıyı kullanması daha iyi olurdu.
        setState(() {
          _kullaniciAdi = (guncelDetaylar.kullaniciAdi!.isNotEmpty ? guncelDetaylar.kullaniciAdi : "")!;
          _hakkinda = guncelDetaylar.hakkinda ?? "Henüz hakkında bilgisi eklenmemiş.";
          _avatarUrl = guncelDetaylar.fotoUrl ?? "";

          print("Profil sayfası state'i güncellendi: $_kullaniciAdi");
        });
      } else {
        print("Güncelleme sonrası YetkilendirmeServisi'nden null kullanıcı detayı alındı.");
        // Bu durumda Firestore'dan tekrar çekmeyi deneyebiliriz.
        Kullanici? fallbackKullanici = await _firestoreServisi.kullaniciGetir(widget.aktifKullanici!.id);
        if(fallbackKullanici != null && mounted){
          setState(() {
            _kullaniciAdi = (fallbackKullanici.kullaniciAdi!.isNotEmpty ? fallbackKullanici.kullaniciAdi : "")!;
            _hakkinda = fallbackKullanici.hakkinda ?? "Henüz hakkında bilgisi eklenmemiş.";
            _avatarUrl = fallbackKullanici.fotoUrl ?? "";

          });
        }
      }
    } else {
      print("Güncelleme olmadı veya sayfa unmounted veya kullanıcı null döndü.");
    }
  }

  Widget _buildOptionListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color iconColor = Colors.white,
    Color iconBackgroundColor = const Color(0xFF2C2C2E),
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconBackgroundColor,
        child: Icon(icon, color: iconColor, size: 22),
        radius: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: _fontFamilyBebas,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 15,
          fontFamily: _fontFamilyBebas,
        ),
      )
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
    );
  }

  Widget _sosyalSayac({required String baslik, required int sayi}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          sayi.toString(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: _fontFamilyBebas,
          ),
        ),
        SizedBox(height: 2.0),
        Text(
          baslik,
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.grey[400],
            fontFamily: _fontFamilyBebas,
          ),
        ),
      ],
    );
  }

  Widget _buildGonderiIzgarasi() {
    if (widget.aktifKullanici == null || widget.aktifKullanici!.id.isEmpty) {
      return SliverToBoxAdapter(child: Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Gönderileri yüklemek için kullanıcı bilgisi gerekli.", style: TextStyle(color: Colors.grey)),
      )));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestoreServisi.kullaniciGonderileriniGetir(widget.aktifKullanici!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Profil Sayfası - Gönderi Stream Hata: ${snapshot.error}");
          return SliverToBoxAdapter(child: Center(child: Text('Gönderiler yüklenirken bir hata oluştu.', style: TextStyle(color: Colors.redAccent))));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white70)),
          ));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            child: Text(
              'Bu kullanıcının henüz hiç gönderisi yok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontFamily: _fontFamilyBebas, fontSize: 20),
            ),
          )));
        }

        final gonderiDocs = snapshot.data!.docs;

        // Eğer state'deki gönderi sayısı ile Firestore'dan gelen farklıysa ve bu kendi profilimizse, güncelleyelim.
        // Bu, build metodu içinde setState yapacağı için dikkatli kullanılmalı.
        // En iyisi bu senkronizasyonu farklı bir yolla yapmak (örn: Kullanici modelini de stream ile dinlemek).
        // Şimdilik bu kısmı yorumda bırakıyorum, karmaşıklığı artırmamak için.
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (mounted && _gonderiSayisi != gonderiDocs.length && Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId == widget.aktifKullanici!.id) {
        //     setState(() {
        //       _gonderiSayisi = gonderiDocs.length;
        //     });
        //   }
        // });

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2.0,
              mainAxisSpacing: 2.0,
            ),
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                try {
                  final gonderiDoc = gonderiDocs[index] as DocumentSnapshot<Map<String, dynamic>>;
                  final Gonderi gonderi = Gonderi.dokumandanUret(gonderiDoc);

                  String? ilkResimUrl;
                  if (gonderi.resimUrls.isNotEmpty) {
                    ilkResimUrl = gonderi.resimUrls[0];
                  }

                  if (ilkResimUrl == null || ilkResimUrl.isEmpty) {
                    return Container(color: Colors.grey[850], child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[700]));
                  }

                  return GestureDetector(
                    onTap: () {
                      print("Gönderiye tıklandı: ${gonderi.id}");
                      // TODO: Gönderi detay sayfasına yönlendirme
                      // Örn: Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderiId: gonderi.id)));
                    },
                    child: Hero(
                      tag: "gonderi_resim_${gonderi.id}",
                      child: Image.network(
                        ilkResimUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(color: Colors.grey[850]);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[850], child: Icon(Icons.broken_image_outlined, color: Colors.grey[600]));
                        },
                      ),
                    ),
                  );
                } catch (e) {
                  print("Profil Gonderi Izgara Hatası (index $index): $e");
                  return Container(color: Colors.red[900], child: Icon(Icons.error_outline, color: Colors.white));
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          title: Text("Profil", style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 26)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("Kullanıcı verileri bekleniyor...", style: TextStyle(color: Colors.white70, fontFamily: _fontFamilyBebas, fontSize: 20)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Color(0xFF121212),
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            title: Text(
              _kullaniciAdi,
              style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 26),
            ),
            centerTitle: true,
            actions: <Widget>[
              // Kendi profilindeyse ayarlar butonu eklenebilir
              if (Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId == widget.aktifKullanici!.id)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Colors.white),
                  color: Color(0xFF2C2C2E), // Koyu tema menü arkaplanı
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'ayarlar',
                      child: Text('Ayarlar', style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas)),
                    ),
                    PopupMenuItem<String>(
                      value: 'cikis',
                      child: Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent, fontFamily: _fontFamilyBebas)),
                    ),
                  ],
                  onSelected: (String value) {
                    if (value == 'ayarlar') {
                      // TODO: Ayarlar sayfasına git
                      print("Ayarlar tıklandı");
                    } else if (value == 'cikis') {
                      _cikisYap();
                    }
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60.0,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _avatarUrl.isNotEmpty && _avatarUrl.startsWith("http")
                            ? NetworkImage(_avatarUrl)
                            : null,
                        child: _avatarUrl.isEmpty || !_avatarUrl.startsWith("http")
                            ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                            : null,
                      ),
                      if (Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId == widget.aktifKullanici!.id)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: Colors.blue,
                            shape: CircleBorder(),
                            elevation: 2.0,
                            child: InkWell(
                              onTap: _profiliDuzenle, // Profil resmi için de aynı düzenleme sayfasına yönlendirilebilir.
                              customBorder: CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(Icons.edit, color: Colors.white, size: 20.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  SizedBox(height: 8.0),
                  Text(
                    _hakkinda,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 18.0, fontFamily: _fontFamilyBebas, height: 1.3),
                  ),
                  SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _sosyalSayac(baslik: "Gönderiler", sayi: _gonderiSayisi),
                      _sosyalSayac(baslik: "Takipçi", sayi: _takipciSayisi),
                      _sosyalSayac(baslik: "Takip Edilen", sayi: _takipEdilenSayisi),
                    ],
                  ),
                  SizedBox(height: 24.0),
                  if (Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId == widget.aktifKullanici!.id)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.edit_note, color: Colors.white),
                        onPressed: _profiliDuzenle,
                        label: Text(
                          "Profili Düzenle",
                          style: TextStyle(color: Colors.white, fontFamily: _fontFamilyBebas, fontSize: 22),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                      ),
                    )
                  else
                    SizedBox(height: 0),
                  SizedBox(height: 20.0),
                  Divider(color: Colors.grey[800]),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 10.0, bottom: 8.0),
              child: Text(
                "Gönderiler",
                style: TextStyle(color: Colors.white, fontSize: 22, fontFamily: _fontFamilyBebas, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          _buildGonderiIzgarasi(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: Column(
                children: [
                  _buildOptionListTile(icon: Icons.help_outline, title: "Yardım ve Destek", onTap: () { /* TODO */ }),
                  _buildOptionListTile(icon: Icons.description_outlined, title: "Hakkımızda", onTap: () { /* TODO */ }),
                  // Çıkış yap sadece kendi profilindeyse veya her zaman ayarlar menüsündeyse (yukarıdaki PopupMenuButton'a taşındı)
                  // if (Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId == widget.aktifKullanici!.id)
                  //    _buildOptionListTile(icon: Icons.logout, title: "Çıkış Yap", iconColor: Colors.redAccent, iconBackgroundColor: Colors.redAccent.withOpacity(0.2), onTap: _cikisYap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}