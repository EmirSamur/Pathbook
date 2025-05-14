// profil_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // FirestoreServisi'ni import et (dosya adını kontrol edin)
import 'package:cloud_firestore/cloud_firestore.dart'; // QuerySnapshot için import et

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

  String _kullaniciAdi = "Kullanıcı Adı";
  String _hakkinda = "Hakkımda bilgisi.";
  String _avatarUrl = ""; // Başlangıçta boş olsun, placeholder ile yönetilsin
  int _gonderiSayisi = 0;
  int _takipciSayisi = 0;
  int _takipEdilenSayisi = 0;

  late FirestoreServisi _firestoreServisi;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _kullaniciVerileriniYukle();
  }

  void _kullaniciVerileriniYukle() {
    if (widget.aktifKullanici != null) {
      setState(() {
        _kullaniciAdi = widget.aktifKullanici!.kullaniciAdi?.isNotEmpty == true
            ? widget.aktifKullanici!.kullaniciAdi!
            : (widget.aktifKullanici!.email?.split('@')[0] ?? "Bilinmiyor"); // Email'den kullanıcı adı üretme
        _hakkinda = widget.aktifKullanici!.hakkinda?.isNotEmpty == true
            ? widget.aktifKullanici!.hakkinda!
            : "Henüz hakkında bilgisi eklenmemiş.";
        _avatarUrl = widget.aktifKullanici!.fotoUrl ?? ""; // Null ise boş string

      });
    } else {
      print("Profil: Aktif kullanıcı bilgisi alınamadı.");
      setState(() {
        _kullaniciAdi = "Kullanıcı Adı";
        _hakkinda = "Hakkımda bilgisi.";
        _avatarUrl = "";
        _gonderiSayisi = 0;
        _takipciSayisi = 0;
        _takipEdilenSayisi = 0;
      });
    }
  }

  @override
  void didUpdateWidget(covariant Profil oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aktifKullanici != oldWidget.aktifKullanici) {
      _kullaniciVerileriniYukle();
    }
  }

  void _cikisYap() {
    Provider.of<YetkilendirmeServisi>(context, listen: false).cikisYap();
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
        child: Text("Gönderileri yüklemek için kullanıcı ID'si bulunamadı.", style: TextStyle(color: Colors.grey)),
      )));
    }
    // ... (Bir önceki cevaptaki _buildGonderiIzgarasi metodunun tamamı buraya gelecek, değişiklik yok) ...
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreServisi.kullaniciGonderileriniGetir(widget.aktifKullanici!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Profil Gönderi Stream Hata: ${snapshot.error}");
          return SliverToBoxAdapter(child: Center(child: Text('Gönderiler yüklenirken bir hata oluştu.')));
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
                final gonderiData = gonderiDocs[index].data() as Map<String, dynamic>;
                final String resimUrl = gonderiData['resimUrl'] ?? '';

                if (resimUrl.isEmpty) {
                  return Container(color: Colors.grey[850]);
                }

                return GestureDetector(
                  onTap: () {
                    print("Gönderiye tıklandı: ${gonderiDocs[index].id}");
                  },
                  child: Image.network(
                    resimUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[850],
                        child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white60)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Profil Gonderi Image Hata: $error");
                      return Container(color: Colors.grey[850], child: Icon(Icons.broken_image_outlined, color: Colors.grey[600]));
                    },
                  ),
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
    if (widget.aktifKullanici == null) {
      // Yüklenme ekranı
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          title: Text(
            "Profil",
            style: TextStyle(
              color: Colors.white,
              fontFamily: _fontFamilyBebas,
              fontSize: 26,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Kullanıcı bilgileri yükleniyor...",
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: _fontFamilyBebas,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Giriş yapmış ve aktifKullanici bilgisi olan kullanıcı için profil sayfası
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _kullaniciAdi,
          style: TextStyle(
            color: Colors.white,
            fontFamily: _fontFamilyBebas,
            fontSize: 26,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () { /* TODO */ },
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () { /* TODO */ },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
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
                            : (_avatarUrl.isNotEmpty ? AssetImage(_avatarUrl) : null) as ImageProvider?,
                        child: _avatarUrl.isEmpty
                            ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                            : null,
                      ),
                      // Sadece kullanıcının kendi profilinde düzenleme ikonunu göster
                      if (Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId == widget.aktifKullanici!.id)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: Colors.blue,
                            shape: CircleBorder(),
                            elevation: 2.0,
                            child: InkWell(
                              onTap: () {
                                print("Profil resmi düzenleme ikonuna tıklandı!");
                                // TODO: Profil resmi düzenleme fonksiyonunu çağır
                              },
                              customBorder: CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    _kullaniciAdi, // AppBar'da zaten var, burada olmasa da olurdu.
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: _fontFamilyBebas,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    _hakkinda,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18.0,
                      fontFamily: _fontFamilyBebas,
                    ),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Implement profile edit navigation/action
                      },
                      child: Text(
                        "Profili Düzenle",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: _fontFamilyBebas,
                          fontSize: 22,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Divider(color: Colors.grey[800]),
                ],
              ),
            ),
          ),
          _buildGonderiIzgarasi(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
              child: Column(
                children: [
                  _buildOptionListTile(icon: Icons.lightbulb_outline, title: "Tema", subtitle: "Ideas", iconColor: Colors.yellowAccent, onTap: () {}),
                  _buildOptionListTile(icon: Icons.description_outlined, title: "SSS/Sıkça sorulan sorular", subtitle: "Notes", onTap: () {}),
                  _buildOptionListTile(icon: Icons.folder_copy_outlined, title: "Kullanım Şartları", subtitle: "Organise", onTap: () {}),
                  _buildOptionListTile(icon: Icons.logout, title: "Çıkış yap", subtitle: "Organise", onTap: _cikisYap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}