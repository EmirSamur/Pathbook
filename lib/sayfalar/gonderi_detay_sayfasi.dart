// lib/sayfalar/gonderi_detay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/sayfalar/yorumlar_sayfasi.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:intl/intl.dart';

class GonderiDetaySayfasi extends StatefulWidget {
  final Gonderi gonderi;

  const GonderiDetaySayfasi({
    Key? key,
    required this.gonderi,
  }) : super(key: key);

  @override
  _GonderiDetaySayfasiState createState() => _GonderiDetaySayfasiState();
}

class _GonderiDetaySayfasiState extends State<GonderiDetaySayfasi> {
  late Gonderi _gonderi;
  Kullanici? _yayinlayanKullanici;
  bool _kullaniciYukleniyor = true;

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLiking = false;
  String? _aktifKullaniciId;
  late FirestoreServisi _firestoreServisi;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _gonderi = widget.gonderi;
    _likeCount = _gonderi.begeniSayisi;

    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;

    _yayinlayanKullaniciyiGetir();
    if (_aktifKullaniciId != null && _aktifKullaniciId!.isNotEmpty) {
      _checkIfLiked();
    }
  }

  Future<void> _yayinlayanKullaniciyiGetir() async {
    if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlem yapma
    setState(() => _kullaniciYukleniyor = true);

    if (_gonderi.yayinlayanKullanici != null) {
      if (mounted) {
        setState(() {
          _yayinlayanKullanici = _gonderi.yayinlayanKullanici;
          _kullaniciYukleniyor = false;
        });
      }
      return;
    }
    Kullanici? kullanici = await _firestoreServisi.kullaniciGetir(_gonderi.kullaniciId);
    if (mounted) {
      setState(() {
        _yayinlayanKullanici = kullanici;
        _kullaniciYukleniyor = false;
      });
    }
  }

  Future<void> _checkIfLiked() async {
    if (_gonderi.id.isEmpty || _aktifKullaniciId == null || _aktifKullaniciId!.isEmpty || !mounted) {
      if (mounted) setState(() => _isLiked = false);
      return;
    }
    bool liked = await _firestoreServisi.kullaniciGonderiyiBegendiMi(
      gonderiId: _gonderi.id,
      aktifKullaniciId: _aktifKullaniciId!,
    );
    if (mounted) {
      setState(() { _isLiked = liked; });
    }
  }

  Future<void> _toggleLike() async {
    if (_aktifKullaniciId == null || _aktifKullaniciId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Beğenmek için giriş yapmalısınız.")));
      return;
    }
    if (_isLiking || !mounted) return;
    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    try {
      await _firestoreServisi.gonderiBegenToggle(
        gonderiId: _gonderi.id,
        aktifKullaniciId: _aktifKullaniciId!,
      );
    } catch (e) {
      print("GonderiDetaySayfasi - Beğeni toggle hatası: $e");
      if (mounted) {
        setState(() { _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Beğeni işlemi sırasında bir hata oluştu.")));
      }
    } finally {
      if (mounted) { setState(() { _isLiking = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Nullable string için güvenli kontrol ve varsayılan değer
    String appBarTitle = "Gönderi Detayı";
    if (_yayinlayanKullanici != null && _yayinlayanKullanici!.kullaniciAdi!.isNotEmpty) {
      appBarTitle = "${_yayinlayanKullanici!.kullaniciAdi}'nın Gönderisi";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: TextStyle(fontSize: 18)),
        elevation: 1.0,
      ),
      body: _kullaniciYukleniyor
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kullanıcı Bilgisi (Avatar ve İsim)
            if (_yayinlayanKullanici != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: GestureDetector(
                  onTap: () {
                    // Kullanıcı null değilse profil sayfasına git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Profil(aktifKullanici: _yayinlayanKullanici!),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.surfaceVariant, // Placeholder rengi
                        backgroundImage: (_yayinlayanKullanici!.fotoUrl != null && _yayinlayanKullanici!.fotoUrl!.isNotEmpty)
                            ? NetworkImage(_yayinlayanKullanici!.fotoUrl!)
                            : null,
                        child: (_yayinlayanKullanici!.fotoUrl == null || _yayinlayanKullanici!.fotoUrl!.isEmpty)
                            ? Icon(Icons.person, size: 24, color: theme.colorScheme.onSurfaceVariant)
                            : null,
                      ),
                      SizedBox(width: 10),
                      Text(
                        _yayinlayanKullanici!.kullaniciAdi!, // kullaniciAdi'nın null olmaması beklenir, ama güvenlik için ?? ""
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            if (_yayinlayanKullanici != null) Divider(height: 1),

            // 2. Görsel Galerisi
            if (_gonderi.resimUrls.isNotEmpty)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.width * (4 / 3), // Veya istediğiniz bir oran
                    child: PageView.builder(
                      itemCount: _gonderi.resimUrls.length,
                      onPageChanged: (index) {
                        if (mounted) {
                          setState(() { _currentImageIndex = index; });
                        }
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          _gonderi.resimUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey[400]));
                          },
                        );
                      },
                    ),
                  ),
                  if (_gonderi.resimUrls.length > 1)
                    Positioned(
                      bottom: 10.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${_currentImageIndex + 1} / ${_gonderi.resimUrls.length}",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(child: Text("Görsel bulunmuyor", style: TextStyle(color: Colors.grey[600]))),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Konum ve Kategori
                  Row(
                    children: [
                      if (_gonderi.konum != null && _gonderi.konum!.isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.secondary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _gonderi.konum!, // Null kontrolü yapıldı
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (_gonderi.konum != null && _gonderi.konum!.isNotEmpty && _gonderi.kategori.isNotEmpty)
                        SizedBox(width: 8), // Konum ve kategori arasında boşluk
                      if (_gonderi.kategori.isNotEmpty)
                        Chip(
                          label: Text(_gonderi.kategori),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 12),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // 4. Açıklama Metni
                  if (_gonderi.aciklama.isNotEmpty)
                    Text(
                      _gonderi.aciklama,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                    )
                  else
                    Text(
                      "Açıklama yok.",
                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                    ),
                  SizedBox(height: 12),

                  // 5. Tarih/Saat Bilgisi
                  Text(
                    DateFormat('dd MMMM yyyy, EEEE HH:mm', 'tr_TR').format(_gonderi.olusturulmaZamani.toDate()),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 10),

                  // 6. Etkileşim Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? theme.colorScheme.error : theme.iconTheme.color,
                        ),
                        label: Text("$_likeCount Beğeni", style: theme.textTheme.labelLarge),
                        onPressed: _toggleLike,
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.chat_bubble_outline),
                        label: Text("${_gonderi.yorumSayisi} Yorum", style: theme.textTheme.labelLarge),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => YorumlarSayfasi(gonderiId: _gonderi.id)),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.send_outlined),
                        tooltip: "Paylaş",
                        onPressed: () {
                          print("Paylaş tıklandı: ${_gonderi.id}");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}