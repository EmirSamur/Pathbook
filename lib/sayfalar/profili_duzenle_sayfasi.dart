// lib/sayfalar/profili_duzenle_sayfasi.dart
import 'dart:io'; // File için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ProfiliDuzenleSayfasi extends StatefulWidget {
  final Kullanici mevcutKullanici;

  const ProfiliDuzenleSayfasi({
    Key? key,
    required this.mevcutKullanici,
  }) : super(key: key);

  @override
  _ProfiliDuzenleSayfasiState createState() => _ProfiliDuzenleSayfasiState();
}

class _ProfiliDuzenleSayfasiState extends State<ProfiliDuzenleSayfasi> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kullaniciAdiController;
  late TextEditingController _hakkindaController;
  File? _secilenResim;
  String _mevcutAvatarUrl = "";
  bool _isProcessing = false;

  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;

  // Cloudinary bilgileri (bunları güvenli bir yerden çekmek daha iyi olabilir)
  final String cloudinaryCloudName = "dt4jjawbe"; // Kendi Cloudinary Cloud Name'iniz
  final String cloudinaryUploadPreset = "pathbooks";  // Kendi Cloudinary Upload Preset'iniz

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);

    _kullaniciAdiController = TextEditingController(text: widget.mevcutKullanici.kullaniciAdi ?? "");
    _hakkindaController = TextEditingController(text: widget.mevcutKullanici.hakkinda ?? "");
    _mevcutAvatarUrl = widget.mevcutKullanici.fotoUrl ?? "";
  }

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _hakkindaController.dispose();
    super.dispose();
  }

  Future<String?> _profilResminiCloudinaryeYukle(File resimDosyasi) async {
    try {
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset, cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(resimDosyasi.path, resourceType: CloudinaryResourceType.Image, folder: "profil_resimleri"),
      );
      if (response.secureUrl.isNotEmpty) {
        print("Profil resmi Cloudinary'e yüklendi: ${response.secureUrl}");
        return response.secureUrl;
      }
      print("Cloudinary profil resmi yükleme hatası (secureUrl boş)");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim URL'i alınamadı.")));
      return null;
    } catch (e) {
      print("Cloudinary profil resmi yükleme istisnası: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim yüklenirken bir hata oluştu.")));
      return null;
    }
  }

  Future<void> _resimSec(ImageSource source) async {
    if (_isProcessing) return; // İşlem devam ediyorsa yeni resim seçmeyi engelle
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 800);
      if (pickedFile != null) {
        setState(() {
          _secilenResim = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Resim seçme hatası: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resim seçilirken bir hata oluştu: $e")));
    }
  }

  void _resimSecmeMenusuGoster() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor ?? Colors.grey[850],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: theme.iconTheme.color?.withOpacity(0.8) ?? Colors.white70),
                  title: Text('Galeriden Seç', style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.white)),
                  onTap: () { _resimSec(ImageSource.gallery); Navigator.of(context).pop(); },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: theme.iconTheme.color?.withOpacity(0.8) ?? Colors.white70),
                  title: Text('Kameradan Çek', style: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.white)),
                  onTap: () { _resimSec(ImageSource.camera); Navigator.of(context).pop(); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _profiliKaydet() async {
    if (_formKey.currentState!.validate() && !_isProcessing) {
      setState(() => _isProcessing = true);

      String yeniKullaniciAdi = _kullaniciAdiController.text.trim();
      String yeniHakkinda = _hakkindaController.text.trim();
      String? guncellenecekFotoUrl = _mevcutAvatarUrl;

      try {
        if (_secilenResim != null) {
          print("Yeni profil resmi seçildi, Cloudinary'e yükleniyor...");
          guncellenecekFotoUrl = await _profilResminiCloudinaryeYukle(_secilenResim!);
          if (guncellenecekFotoUrl == null) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profil resmi yüklenirken bir sorun oluştu.")));
            if (mounted) setState(() => _isProcessing = false);
            return;
          }
          print("Profil resmi Cloudinary'e yüklendi, URL: $guncellenecekFotoUrl");
        }

        Map<String, dynamic> guncellenecekVeri = {
          'kullaniciAdi': yeniKullaniciAdi,
          'hakkinda': yeniHakkinda,
          'fotoUrl': guncellenecekFotoUrl, // Null olsa bile gönderilir, Firestore'da null olur
        };

        print("Firestore'a güncellenecek veri: $guncellenecekVeri");
        await _firestoreServisi.kullaniciGuncelle(
          id: widget.mevcutKullanici.id,
          veri: guncellenecekVeri,
        );
        print("Kullanıcı başarıyla güncellendi.");

        Kullanici? guncelAuthKullanici = await _firestoreServisi.kullaniciGetir(widget.mevcutKullanici.id);
        if (guncelAuthKullanici != null) {
          _yetkilendirmeServisi.aktifKullaniciGuncelleVeYenidenYukle(guncelAuthKullanici);
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profil başarıyla güncellendi!"), backgroundColor: Colors.green[700]));
        if (mounted) Navigator.of(context).pop(true); // Profil sayfasına güncelleme olduğunu bildir

      } catch (e) {
        print("Profil kaydetme hatası: $e");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profil güncellenirken bir hata oluştu: $e"), backgroundColor: Colors.red[700]));
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Temayı alıyoruz

    // İstenen Kırmızı Rengi Tanımla
    final Color kirmiziVurguRengi = Colors.redAccent[400]!; // Veya Colors.red, Colors.red[700]! vs.
    final Color odaklanmisBorderRengi = kirmiziVurguRengi.withOpacity(0.85);
    final Color textFieldIconColor = Colors.grey[500]!; // İkonlar için biraz daha açık gri

    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A), // Koyu arka plan
      appBar: AppBar(
        backgroundColor: Color(0xFF121212), // AppBar için biraz daha açık koyu
        elevation: 0.3, // Hafif bir gölge
        iconTheme: IconThemeData(color: Colors.white.withOpacity(0.8)), // Geri butonu rengi
        title: Text(
          "Profili Düzenle",
          style: TextStyle(color: Colors.white, fontFamily: 'Bebas', fontSize: 21, letterSpacing: 0.5), // Font ayarlandı
        ),
        centerTitle: true,
        actions: [
          _isProcessing
              ? Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white70))),
          )
              : IconButton(
            icon: Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent[400], size: 25),
            onPressed: _profiliKaydet,
            tooltip: "Kaydet",
            splashRadius: 22,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: _isProcessing ? null : _resimSecmeMenusuGoster,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60, // Avatar boyutu
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _secilenResim != null
                          ? FileImage(_secilenResim!)
                          : (_mevcutAvatarUrl.isNotEmpty
                          ? NetworkImage(_mevcutAvatarUrl)
                          : null)
                      as ImageProvider?,
                      child: (_secilenResim == null && _mevcutAvatarUrl.isEmpty)
                          ? Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey[500]) // Önerilen ikon
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: kirmiziVurguRengi, // KIRMIZI RENK
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(0xFF0A0A0A), width: 2.0) // Arka planla uyumlu çerçeve
                        ),
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _kullaniciAdiController,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı",
                  labelStyle: TextStyle(color: textFieldIconColor, fontSize: 14),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: textFieldIconColor, size: 19),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: odaklanmisBorderRengi, width: 1.2),  borderRadius: BorderRadius.circular(8)),
                  errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent[100]!.withOpacity(0.8)),  borderRadius: BorderRadius.circular(8)),
                  focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent[100]!, width: 1.2),  borderRadius: BorderRadius.circular(8)),
                  errorStyle: TextStyle(color: Colors.redAccent[100], fontSize: 11.5),
                  filled: true,
                  fillColor: Colors.grey[900]?.withOpacity(0.6),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Kullanıcı adı gerekli.";
                  if (value.trim().length < 3) return "En az 3 karakter olmalı.";
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _hakkindaController,
                style: TextStyle(color: Colors.white, fontSize: 14.5),
                decoration: InputDecoration(
                  labelText: "Hakkında",
                  labelStyle: TextStyle(color: textFieldIconColor, fontSize: 14),
                  prefixIcon: Icon(Icons.info_outline_rounded, color: textFieldIconColor, size: 19),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: odaklanmisBorderRengi, width: 1.2), borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[900]?.withOpacity(0.6),
                  contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
                  alignLabelWithHint: true, // Label'ı yukarıda tutar
                ),
                maxLines: 3, // Max satır sayısı
                maxLength: 150, // Karakter limiti
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text("${currentLength}/${maxLength}", style: TextStyle(color: Colors.grey[600], fontSize: 10.5)),
                    ),
              ),
              SizedBox(height: 25), // Buton için boşluk
            ],
          ),
        ),
      ),
    );
  }
}