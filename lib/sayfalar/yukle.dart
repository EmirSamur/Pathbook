// lib/sayfalar/yukle.dart (veya GonderiEkleSayfasi.dart)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
// Gonderi modeline burada ihtiyacımız yok, FirestoreServisi hallediyor.
// import 'package:pathbooks/modeller/gonderi.dart';
import 'package:dotted_border/dotted_border.dart';

class GonderiEkleSayfasi extends StatefulWidget {
  const   GonderiEkleSayfasi({Key? key}) : super(key: key);

  @override
  _GonderiEkleSayfasiState createState() => _GonderiEkleSayfasiState();
}

class _GonderiEkleSayfasiState extends State<GonderiEkleSayfasi> {
  File? _secilenResim;
  final ImagePicker _picker = ImagePicker();
  bool _yukleniyor = false;
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _konumController = TextEditingController();

  // Cloudinary bilgileri (Bunları güvenli bir yerde saklamak daha iyi olabilir)
  final String cloudinaryCloudName = "dt4jjawbe"; // ÖRNEK DEĞERLER, KENDİ BİLGİLERİNİZİ GİRİN
  final String cloudinaryUploadPreset = "pathbooks"; // ÖRNEK DEĞERLER

  @override
  void dispose() {
    _aciklamaController.dispose();
    _konumController.dispose();
    super.dispose();
  }

  Future<void> _resimSec(ImageSource source) async {
    if (_yukleniyor) return;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Kaliteyi biraz düşürerek dosya boyutunu optimize et
        maxWidth: 1080, // Maksimum genişlik (Instagram gibi)
      );
      if (pickedFile != null) {
        if (mounted) setState(() => _secilenResim = File(pickedFile.path));
      }
    } catch (e) {
      print("Resim seçme hatası: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim seçilirken bir hata oluştu.")));
    }
  }

  Future<String?> _resmiCloudinaryeYukle(File resimDosyasi) async {
    // ... (Bu metod aynı kalabilir, içindeki print ve SnackBar mesajları yeterli) ...
    try {
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset, cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(resimDosyasi.path, resourceType: CloudinaryResourceType.Image),
      );
      if (response.secureUrl.isNotEmpty) return response.secureUrl;
      print("Cloudinary yükleme hatası (secureUrl boş)");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim URL'i alınamadı.")));
      return null;
    } catch (e) {
      print("Cloudinary yükleme istisnası: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim yüklenirken bir hata oluştu.")));
      return null;
    }
  }

  Future<void> _gonderiOlustur() async {
    if (_secilenResim == null || _yukleniyor) {
      if (_secilenResim == null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lütfen bir resim seçin.")));
      return;
    }

    if (mounted) setState(() => _yukleniyor = true);

    String? resimUrl;
    try {
      resimUrl = await _resmiCloudinaryeYukle(_secilenResim!);
      if (resimUrl == null) return; // Hata mesajı Cloudinary metodunda gösterildi

      final String? aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
      if (aktifKullaniciId == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Oturum hatası. Lütfen tekrar giriş yapın.")));
        return;
      }

      await Provider.of<FirestoreServisi>(context, listen: false).gonderiOlustur(
        yayinlayanId: aktifKullaniciId,
        gonderiResmiUrl: resimUrl,
        aciklama: _aciklamaController.text.trim(),
        konum: _konumController.text.trim().isNotEmpty ? _konumController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gönderi başarıyla oluşturuldu!"), backgroundColor: Theme.of(context).colorScheme.secondary), // Tema rengi
        );
        setState(() { _secilenResim = null; _aciklamaController.clear(); _konumController.clear(); });
        // Sayfayı kapatmadan önce küçük bir gecikme, kullanıcının mesajı görmesi için
        await Future.delayed(const Duration(seconds: 1));
        if (Navigator.canPop(context)) Navigator.pop(context, true); // Başarılı olursa true döndür
      }
    } catch (e) {
      print("Gönderi oluşturma sürecinde genel hata: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gönderi oluşturulurken bir hata oluştu."), backgroundColor: Theme.of(context).colorScheme.error), // Tema rengi
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)), // Tema rengi
            SizedBox(height: 20),
            Text("Yükleniyor...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _secimMenusuGoster(BuildContext context) { // context parametresi eklendi
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface, // Tema surface rengi
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  title: Text('Galeriden Seç', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () { Navigator.of(context).pop(); _resimSec(ImageSource.gallery); },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  title: Text('Kameradan Çek', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () { Navigator.of(context).pop(); _resimSec(ImageSource.camera); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color hintColor = onSurfaceColor.withOpacity(0.5);

    return Scaffold(
      appBar: AppBar(
        // title: Text("Yeni Gönderi"), // main.dart'taki AppBarTheme'den geliyor
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _yukleniyor ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // Sağa biraz boşluk
            child: TextButton(
              onPressed: (_secilenResim == null || _yukleniyor) ? null : _gonderiOlustur,
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // Aktifken tema rengi
                disabledForegroundColor: hintColor.withOpacity(0.7), // Pasifken soluk renk
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                "Paylaş",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      // backgroundColor: Theme.of(context).scaffoldBackgroundColor, // main.dart'tan geliyor
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // Klavyeyi kapatmak için
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // --- RESİM SEÇME ALANI ---
                  GestureDetector(
                    onTap: _yukleniyor ? null : () => _secimMenusuGoster(context), // context eklendi
                    child: DottedBorder(
                      color: onSurfaceColor.withOpacity(0.3),
                      strokeWidth: 1.5,
                      borderType: BorderType.RRect,
                      radius: Radius.circular(16), // Daha yuvarlak
                      dashPattern: [6, 5],
                      child: AspectRatio( // Resim için sabit bir oran sağlar
                        aspectRatio: 1.0, // Kare alan (veya 4/3, 16/9)
                        child: Container(
                          decoration: BoxDecoration(
                            color: surfaceColor.withOpacity(0.5), // Hafif bir arkaplan
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: _secilenResim != null
                              ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(_secilenResim!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                              : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: primaryColor, size: 60),
                                SizedBox(height: 12),
                                Text("Bir resim seçin", style: TextStyle(color: hintColor, fontSize: 17, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // --- AÇIKLAMA ALANI ---
                  TextField(
                    controller: _aciklamaController,
                    style: TextStyle(color: onSurfaceColor, fontSize: 16),
                    maxLines: 4, // Daha az satır
                    minLines: 2,
                    maxLength: 250,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Açıklamanı yaz...",
                      hintStyle: TextStyle(color: hintColor),
                      fillColor: surfaceColor, // Tema surface rengi
                      // border: OutlineInputBorder( // InputTheme'den geliyor
                      //   borderRadius: BorderRadius.circular(12),
                      //   borderSide: BorderSide.none,
                      // ),
                      // focusedBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(12),
                      //   borderSide: BorderSide(color: primaryColor, width: 1.5),
                      // ),
                      // enabledBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(12),
                      //   borderSide: BorderSide(color: onSurfaceColor.withOpacity(0.2)),
                      // ),
                      counterStyle: TextStyle(color: hintColor.withOpacity(0.8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 20),

                  // --- KONUM ALANI ---
                  TextField(
                    controller: _konumController,
                    style: TextStyle(color: onSurfaceColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Konum ekle (isteğe bağlı)",
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.location_on_outlined, color: hintColor, size: 22),
                      fillColor: surfaceColor,
                      // border: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(12),
                      //   borderSide: BorderSide.none,
                      // ),
                      // focusedBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(12),
                      //   borderSide: BorderSide(color: primaryColor, width: 1.5),
                      // ),
                      // enabledBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(12),
                      //   borderSide: BorderSide(color: onSurfaceColor.withOpacity(0.2)),
                      // ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 30),
                  // İsteğe bağlı: Paylaş butonu buraya da eklenebilir
                  // ElevatedButton(
                  //   onPressed: (_secilenResim == null || _yukleniyor) ? null : _gonderiOlustur,
                  //   child: Text("Paylaş"),
                  //   // style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)), // main.dart'tan geliyor
                  // ),
                ],
              ),
            ),
          ),
          if (_yukleniyor) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}