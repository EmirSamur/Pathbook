// lib/sayfalar/yukle.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:dotted_border/dotted_border.dart';

class GonderiEkleSayfasi extends StatefulWidget {
  const GonderiEkleSayfasi({Key? key}) : super(key: key);

  @override
  _GonderiEkleSayfasiState createState() => _GonderiEkleSayfasiState();
}

class _GonderiEkleSayfasiState extends State<GonderiEkleSayfasi> {
  // File? _secilenResim; // ESKİ
  List<File> _secilenResimler = []; // YENİ: Birden fazla resim için
  String? _secilenKategori; // YENİ: Seçilen kategori
  final List<String> _kategoriler = const ["Doğa", "Kültür", "Tarih", "Yeme-İçme"]; // YENİ: Kategori listesi
  final int _maxResimSayisi = 5; // YENİ: Maksimum resim sayısı

  final ImagePicker _picker = ImagePicker();
  bool _yukleniyor = false;
  final _formKey = GlobalKey<FormState>(); // YENİ: Form validasyonu için
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _konumController = TextEditingController();

  final String cloudinaryCloudName = "dt4jjawbe";
  final String cloudinaryUploadPreset = "pathbooks";

  @override
  void dispose() {
    _aciklamaController.dispose();
    _konumController.dispose();
    super.dispose();
  }

  Future<void> _resimSec(ImageSource source) async {
    if (_yukleniyor) return;
    if (_secilenResimler.length >= _maxResimSayisi && source == ImageSource.gallery) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("En fazla $_maxResimSayisi resim seçebilirsiniz.")));
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final List<XFile>? pickedFiles = await _picker.pickMultiImage(
          imageQuality: 70,
          maxWidth: 1080,
        );
        if (pickedFiles != null && pickedFiles.isNotEmpty) {
          if (mounted) {
            setState(() {
              for (var pickedFile in pickedFiles) {
                if (_secilenResimler.length < _maxResimSayisi) {
                  _secilenResimler.add(File(pickedFile.path));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim limiti doldu. Bazı resimler eklenemedi.")));
                  break;
                }
              }
            });
          }
        }
      } else { // Kamera
        if (_secilenResimler.length >= _maxResimSayisi) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("En fazla $_maxResimSayisi resim ekleyebilirsiniz.")));
          return;
        }
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1080,
        );
        if (pickedFile != null) {
          if (mounted) setState(() => _secilenResimler.add(File(pickedFile.path)));
        }
      }
    } catch (e) {
      print("Resim seçme hatası: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Resim seçilirken bir hata oluştu.")));
    }
  }

  void _resimKaldir(int index) {
    if (mounted) {
      setState(() {
        _secilenResimler.removeAt(index);
      });
    }
  }

  Future<String?> _resmiCloudinaryeYukle(File resimDosyasi) async {
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
    if (!_formKey.currentState!.validate()) return; // Form validasyonu
    if (_secilenResimler.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lütfen en az bir resim seçin.")));
      return;
    }
    // _secilenKategori zaten DropdownButtonFormField tarafından validate edilecek (eğer validator eklenirse)
    // veya burada manuel kontrol edilebilir:
    if (_secilenKategori == null || _secilenKategori!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lütfen bir kategori seçin.")));
      return;
    }

    if (_yukleniyor) return;
    if (mounted) setState(() => _yukleniyor = true);

    List<String> yuklenenResimUrls = [];
    try {
      for (File resimDosyasi in _secilenResimler) {
        String? url = await _resmiCloudinaryeYukle(resimDosyasi);
        if (url != null) {
          yuklenenResimUrls.add(url);
        } else {
          throw Exception("Bir resim Cloudinary'e yüklenemedi.");
        }
      }

      if (yuklenenResimUrls.isEmpty || yuklenenResimUrls.length != _secilenResimler.length) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tüm resimler yüklenemedi. Lütfen tekrar deneyin.")));
        if (mounted) setState(() => _yukleniyor = false);
        return;
      }

      final String? aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
      if (aktifKullaniciId == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Oturum hatası. Lütfen tekrar giriş yapın.")));
        if (mounted) setState(() => _yukleniyor = false);
        return;
      }

      await Provider.of<FirestoreServisi>(context, listen: false).gonderiOlustur(
        yayinlayanId: aktifKullaniciId,
        gonderiResmiUrls: yuklenenResimUrls, // YENİ
        aciklama: _aciklamaController.text.trim(),
        konum: _konumController.text.trim().isNotEmpty ? _konumController.text.trim() : null,
        kategori: _secilenKategori!, // YENİ
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gönderi başarıyla oluşturuldu!"), backgroundColor: Theme.of(context).colorScheme.secondary),
        );
        setState(() {
          _secilenResimler.clear();
          _secilenKategori = null;
          _aciklamaController.clear();
          _konumController.clear();
          _formKey.currentState?.reset(); // Formu sıfırla
        });
        await Future.delayed(const Duration(seconds: 1));
        if (Navigator.canPop(context)) Navigator.pop(context, true);
      }
    } catch (e) {
      print("Gönderi oluşturma sürecinde genel hata: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gönderi oluşturulurken bir hata oluştu."), backgroundColor: Theme.of(context).colorScheme.error),
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
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)),
            SizedBox(height: 20),
            Text("Yükleniyor...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _secimMenusuGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: <Widget>[
                if (_secilenResimler.length < _maxResimSayisi) // Galeri seçeneğini limit dolmadıysa göster
                  ListTile(
                    leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    title: Text('Galeriden Seç (Çoklu)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    onTap: () { Navigator.of(context).pop(); _resimSec(ImageSource.gallery); },
                  ),
                if (_secilenResimler.length < _maxResimSayisi) // Kamera seçeneğini limit dolmadıysa göster
                  ListTile(
                    leading: Icon(Icons.camera_alt_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    title: Text('Kameradan Çek (Tek)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    onTap: () { Navigator.of(context).pop(); _resimSec(ImageSource.camera); },
                  ),
                if (_secilenResimler.length >= _maxResimSayisi)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Maksimum resim sayısına ulaştınız.", textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreviews() {
    if (_secilenResimler.isEmpty) {
      return SizedBox.shrink(); // Boşsa hiçbir şey gösterme
    }
    return Container(
      height: 120, // Önizleme alanının yüksekliği
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _secilenResimler.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _secilenResimler[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red.shade700, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: _yukleniyor ? null : () => _resimKaldir(index),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color hintColor = onSurfaceColor.withOpacity(0.5);

    bool canAddMoreImages = _secilenResimler.length < _maxResimSayisi;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _yukleniyor ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: (_secilenResimler.isEmpty || _yukleniyor) ? null : _gonderiOlustur,
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                disabledForegroundColor: hintColor.withOpacity(0.7),
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
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form( // YENİ: Form widget'ı eklendi
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // --- RESİM SEÇME ALANI ve ÖNİZLEMELER ---
                    if (_secilenResimler.isNotEmpty) _buildImagePreviews(),

                    if (canAddMoreImages) // Hala resim eklenebiliyorsa butonu göster
                      GestureDetector(
                        onTap: _yukleniyor ? null : () => _secimMenusuGoster(context),
                        child: DottedBorder(
                          color: onSurfaceColor.withOpacity(0.3),
                          strokeWidth: 1.5,
                          borderType: BorderType.RRect,
                          radius: Radius.circular(16),
                          dashPattern: [6, 5],
                          child: Container(
                            height: _secilenResimler.isEmpty ? 200 : 80, // Resim yoksa daha büyük, varsa daha küçük
                            decoration: BoxDecoration(
                              color: surfaceColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: primaryColor, size: _secilenResimler.isEmpty ? 60 : 30),
                                  SizedBox(height: _secilenResimler.isEmpty ? 12 : 4),
                                  Text(
                                      _secilenResimler.isEmpty ? "Resim seçin (En fazla $_maxResimSayisi)" : "Daha fazla resim ekle",
                                      style: TextStyle(color: hintColor, fontSize: _secilenResimler.isEmpty ? 17 : 15, fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!canAddMoreImages && _secilenResimler.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Text("Maksimum resim sayısına ulaştınız.", textAlign: TextAlign.center, style: TextStyle(color: hintColor)),
                      ),
                    SizedBox(height: 24),

                    // --- KATEGORİ SEÇİMİ ---
                    DropdownButtonFormField<String>(
                      value: _secilenKategori,
                      items: _kategoriler.map((String kategori) {
                        return DropdownMenuItem<String>(
                          value: kategori,
                          child: Text(kategori),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _secilenKategori = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Kategori Seçin*",
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.category_outlined, color: hintColor, size: 22),
                        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Temadan alabilir
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen bir kategori seçin.';
                        }
                        return null;
                      },
                      style: TextStyle(color: onSurfaceColor, fontSize: 16),
                      dropdownColor: surfaceColor,
                    ),
                    SizedBox(height: 20),

                    // --- AÇIKLAMA ALANI ---
                    TextFormField( // TextField'ı TextFormField'a çevirdik (validasyon için)
                      controller: _aciklamaController,
                      style: TextStyle(color: onSurfaceColor, fontSize: 16),
                      maxLines: 4,
                      minLines: 2,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Açıklamanı yaz...",
                        hintStyle: TextStyle(color: hintColor),
                        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Temadan alabilir
                        counterStyle: TextStyle(color: hintColor.withOpacity(0.8)),
                      ),
                      // validator: (value) { // Açıklama zorunluysa
                      //   if (value == null || value.trim().isEmpty) {
                      //     return 'Lütfen bir açıklama girin.';
                      //   }
                      //   return null;
                      // },
                    ),
                    SizedBox(height: 20),

                    // --- KONUM ALANI ---
                    TextFormField( // TextField'ı TextFormField'a çevirdik
                      controller: _konumController,
                      style: TextStyle(color: onSurfaceColor, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Konum ekleyebilirsiniz (isteğe bağlı)",
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.location_on_outlined, color: hintColor, size: 22),
                        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Temadan alabilir
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          if (_yukleniyor) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}