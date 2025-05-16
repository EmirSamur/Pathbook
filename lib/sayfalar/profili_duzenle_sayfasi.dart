// lib/sayfalar/profili_duzenle_sayfasi.dart
import 'dart:io'; // File için
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // Cloudinary importu

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

  // Cloudinary bilgileri (yukle.dart'tan alındı)
  final String cloudinaryCloudName = "dt4jjawbe";
  final String cloudinaryUploadPreset = "pathbooks";

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);

    _kullaniciAdiController = TextEditingController(text: widget.mevcutKullanici.kullaniciAdi);
    _hakkindaController = TextEditingController(text: widget.mevcutKullanici.hakkinda);
    _mevcutAvatarUrl = widget.mevcutKullanici.fotoUrl ?? "";
  }

  // yukle.dart'tan alınan _resmiCloudinaryeYukle metodu
  Future<String?> _profilResminiCloudinaryeYukle(File resimDosyasi) async {
    // Profil resmi için farklı bir klasör veya tag kullanmak isteyebilirsiniz.
    // Şimdilik yukle.dart'taki mantıkla aynı.
    try {
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset, cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(resimDosyasi.path, resourceType: CloudinaryResourceType.Image, folder: "profil_resimleri"), // Opsiyonel: profil resimleri için ayrı klasör
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
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 800);
      if (pickedFile != null) {
        setState(() {
          _secilenResim = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Resim seçme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resim seçilirken bir hata oluştu: $e")));
    }
  }

  void _resimSecmeMenusuGoster() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galeriden Seç'),
                onTap: () {
                  _resimSec(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Kameradan Çek'),
                onTap: () {
                  _resimSec(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
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
      String? guncellenecekFotoUrl = _mevcutAvatarUrl; // Başlangıçta mevcut URL'i koru

      try {
        // 1. Eğer yeni resim seçildiyse Cloudinary'e yükle
        if (_secilenResim != null) {
          print("Yeni profil resmi seçildi, Cloudinary'e yükleniyor...");
          guncellenecekFotoUrl = await _profilResminiCloudinaryeYukle(_secilenResim!); // Cloudinary'e yükle

          if (guncellenecekFotoUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Profil resmi yüklenirken bir sorun oluştu.")));
            if(mounted) setState(() => _isProcessing = false);
            return; // Resim yüklenemediyse işlemi durdur
          }
          print("Profil resmi Cloudinary'e yüklendi, URL: $guncellenecekFotoUrl");
        }

        // 2. Firestore'da kullanıcı verilerini güncelle
        Map<String, dynamic> guncellenecekVeri = {
          'kullaniciAdi': yeniKullaniciAdi,
          'hakkinda': yeniHakkinda,
          // fotoUrl sadece yeni bir resim yüklendiyse veya mevcut resimden farklıysa güncellenir.
          // Eğer _secilenResim null ise guncellenecekFotoUrl zaten _mevcutAvatarUrl olacak.
          // Eğer kullanıcı resmini silmek isterse (bu UI'da yok ama), o zaman null göndermek gerekir.
          'fotoUrl': guncellenecekFotoUrl,
        };

        // Sadece değişen alanları göndermek daha verimli olabilir ama şimdilik tümünü gönderiyoruz.
        // if (yeniKullaniciAdi != widget.mevcutKullanici.kullaniciAdi) guncellenecekVeri['kullaniciAdi'] = yeniKullaniciAdi;
        // if (yeniHakkinda != widget.mevcutKullanici.hakkinda) guncellenecekVeri['hakkinda'] = yeniHakkinda;
        // if (guncellenecekFotoUrl != widget.mevcutKullanici.fotoUrl) guncellenecekVeri['fotoUrl'] = guncellenecekFotoUrl;


        print("Firestore'a güncellenecek veri: $guncellenecekVeri");
        await _firestoreServisi.kullaniciGuncelle(
          id: widget.mevcutKullanici.id,
          veri: guncellenecekVeri,
        );
        print("Kullanıcı başarıyla güncellendi.");

        // 3. YetkilendirmeServisi'ndeki aktifKullanici'yı güncelle
        _yetkilendirmeServisi.aktifKullaniciGuncelleVeYenidenYukle();


        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profil başarıyla güncellendi!")));

        if (mounted) Navigator.of(context).pop(true); // Profil sayfasına geri dön ve güncelleme olduğunu belirt

      } catch (e) {
        print("Profil kaydetme hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profil güncellenirken bir hata oluştu: $e")));
      } finally {
        if(mounted) setState(() => _isProcessing = false);
      }
    }
  }


  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _hakkindaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (build metodu bir önceki cevaptaki gibi kalabilir,
    // CircleAvatar'daki backgroundImage kısmı _mevcutAvatarUrl'e göre güncellenmişti zaten)
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Profili Düzenle",
          style: TextStyle(color: Colors.white, fontFamily: 'Bebas', fontSize: 24),
        ),
        actions: [
          _isProcessing
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          )
              : IconButton(
            icon: Icon(Icons.check_rounded, color: Colors.white, size: 28),
            onPressed: _profiliKaydet,
            tooltip: "Kaydet",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              GestureDetector(
                onTap: _resimSecmeMenusuGoster,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _secilenResim != null
                          ? FileImage(_secilenResim!)
                          : (_mevcutAvatarUrl.isNotEmpty
                          ? NetworkImage(_mevcutAvatarUrl)
                          : null) as ImageProvider?,
                      child: (_secilenResim == null && _mevcutAvatarUrl.isEmpty)
                          ? Icon(Icons.person, size: 70, color: Colors.grey[600])
                          : null,
                    ),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2)
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _kullaniciAdiController,
                style: TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı",
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  errorStyle: TextStyle(color: Colors.redAccent),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Kullanıcı adı boş bırakılamaz.";
                  }
                  if (value.trim().length < 3) {
                    return "Kullanıcı adı en az 3 karakter olmalıdır.";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _hakkindaController,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Hakkında",
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.info_outline, color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
                ),
                maxLines: 4,
                maxLength: 150,
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}