// lib/sayfalar/yukle.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart'; // Çoklu resim ekleme alanı için
// LÜTFEN DİKKAT: Servis dosyanızın adı 'firestoreseervisi.dart' ise bu doğru.
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';

class GonderiEkleSayfasi extends StatefulWidget {
  const GonderiEkleSayfasi({Key? key}) : super(key: key);

  @override
  _GonderiEkleSayfasiState createState() => _GonderiEkleSayfasiState();
}

class _GonderiEkleSayfasiState extends State<GonderiEkleSayfasi> {
  List<File> _secilenResimler = []; // ÇOKLU RESİM İÇİN DEĞİŞTİ
  final int _maxResimSayisi = 5;    // Maksimum resim sayısı
  String? _secilenPano;
  final List<String> _panoSecenekleri = const [
    "Doğa", "Tarih", "Kültür", "Yeme-İçme"
  ];

  final ImagePicker _picker = ImagePicker();
  bool _yukleniyor = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _baglantiController = TextEditingController();
  final TextEditingController _konumController = TextEditingController();

  final String cloudinaryCloudName = "dt4jjawbe";
  final String cloudinaryUploadPreset = "pathbooks";

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _baglantiController.dispose();
    _konumController.dispose();
    super.dispose();
  }

  Future<void> _resimSec({ImageSource? sourceFromButton}) async {
    if (_yukleniyor) return;
    if (_secilenResimler.length >= _maxResimSayisi && sourceFromButton != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("En fazla $_maxResimSayisi resim seçebilirsiniz.")));
      return;
    }

    try {
      if (sourceFromButton == ImageSource.gallery) {
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resim limiti doldu. Bazı resimler eklenemedi.")));
                  break;
                }
              }
            });
          }
        }
      } else if (sourceFromButton == ImageSource.camera) {
        if (_secilenResimler.length >= _maxResimSayisi) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("En fazla $_maxResimSayisi resim ekleyebilirsiniz.")));
          return;
        }
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 70, maxWidth: 1080,
        );
        if (pickedFile != null) {
          if (mounted) setState(() => _secilenResimler.add(File(pickedFile.path)));
        }
      }
    } catch (e) {
      print("Resim seçme hatası: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resim seçilirken bir hata oluştu.")));
    }
  }

  void _resimSecimMenusuGoster() {
    // Eğer hiç resim yoksa veya limit dolmadıysa modalı göster
    if (_secilenResimler.isEmpty || _secilenResimler.length < _maxResimSayisi) {
      showModalBottomSheet(
        context: context, backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Wrap(children: <Widget>[
                if (_secilenResimler.length < _maxResimSayisi) // Galeri seçeneğini limit dolmadıysa göster
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                    title: const Text('Galeriden Seç (Çoklu)', style: TextStyle(color: Colors.white)),
                    onTap: () { Navigator.of(context).pop(); _resimSec(sourceFromButton: ImageSource.gallery); },
                  ),
                if (_secilenResimler.length < _maxResimSayisi) // Kamera seçeneğini limit dolmadıysa göster
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined, color: Colors.white70),
                    title: const Text('Kameradan Çek (Tek)', style: TextStyle(color: Colors.white)),
                    onTap: () { Navigator.of(context).pop(); _resimSec(sourceFromButton: ImageSource.camera); },
                  ),
              ]),
            ),
          );
        },
      );
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Maksimum resim sayısına ulaştınız.")));
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
    // Bu fonksiyon değişmeden kalabilir, tek bir dosyayı yükler.
    // _gonderiOlustur içinde döngüyle çağrılacak.
    try {
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset, cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(resimDosyasi.path, resourceType: CloudinaryResourceType.Image),
      );
      if (response.secureUrl.isNotEmpty) return response.secureUrl;
      return null;
    } catch (e) {
      print("Cloudinary yükleme istisnası: $e");
      return null;
    }
  }

  Future<void> _gonderiOlustur() async {
    if (!_formKey.currentState!.validate()) return;
    if (_secilenResimler.isEmpty) { // ÇOKLU RESİM KONTROLÜ
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen en az bir resim seçin.")));
      return;
    }

    if (_yukleniyor) return;
    if (mounted) setState(() => _yukleniyor = true);

    List<String> yuklenenResimUrls = []; // YÜKLENEN TÜM URL'LERİ TOPLA
    try {
      for (File resimDosyasi in _secilenResimler) { // HER BİR RESMİ YÜKLE
        String? url = await _resmiCloudinaryeYukle(resimDosyasi);
        if (url != null) {
          yuklenenResimUrls.add(url);
        } else {
          // Bir resim yüklenemezse işlemi durdur ve kullanıcıyı bilgilendir.
          throw Exception("Bir resim Cloudinary'e yüklenemedi.");
        }
      }

      if (yuklenenResimUrls.isEmpty || yuklenenResimUrls.length != _secilenResimler.length) {
        // Bu durum yukarıdaki throw Exception ile yakalanmalı ama yine de bir kontrol.
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tüm resimler yüklenemedi. Lütfen tekrar deneyin.")));
        if (mounted) setState(() => _yukleniyor = false);
        return;
      }

      final String? aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
      if (aktifKullaniciId == null) {
        // ... (oturum hatası kısmı aynı kalır)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oturum hatası. Lütfen tekrar giriş yapın.")));
          setState(() => _yukleniyor = false);
        }
        return;
      }

      await Provider.of<FirestoreServisi>(context, listen: false).gonderiOlustur(
        yayinlayanId: aktifKullaniciId,
        gonderiResmiUrls: yuklenenResimUrls, // TÜM URL LİSTESİNİ GÖNDER
        aciklama: _aciklamaController.text.trim(),
        kategori: _secilenPano!,
        konum: _konumController.text.trim().isNotEmpty ? _konumController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pin başarıyla oluşturuldu!"), backgroundColor: Colors.green),
        );
        setState(() {
          _secilenResimler.clear(); // TÜM SEÇİLEN RESİMLERİ TEMİZLE
          _secilenPano = null;
          _baslikController.clear();
          _aciklamaController.clear();
          _baglantiController.clear();
          _konumController.clear();
          _formKey.currentState?.reset();
        });
        await Future.delayed(const Duration(seconds: 1));
        if (Navigator.canPop(context)) Navigator.pop(context, true);
      }
    } catch (e) {
      print("Pin oluşturma sürecinde genel hata: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pin oluşturulurken bir hata oluştu: ${e.toString().length > 100 ? e.toString().substring(0,100) : e.toString()}"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Widget _buildLoadingOverlay() { /* ... (değişiklik yok) ... */
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent)),
          const SizedBox(height: 20),
          const Text("Yükleniyor...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildImagePreviewsAndPicker() {
    return Column(
      children: [
        // Seçilen Resimlerin Önizlemesi
        if (_secilenResimler.isNotEmpty)
          Container(
            height: 120, // Önizleme alanının yüksekliği
            margin: const EdgeInsets.only(bottom: 16.0, top:10.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _secilenResimler.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Stack(
                    clipBehavior: Clip.none, // İkonun dışarı taşabilmesi için
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _secilenResimler[index],
                          width: 100, height: 100, fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -8, right: -8,
                        child: InkWell(
                          onTap: _yukleniyor ? null : () => _resimKaldir(index),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Resim Ekleme Alanı
        if (_secilenResimler.length < _maxResimSayisi)
          GestureDetector(
            onTap: _yukleniyor ? null : _resimSecimMenusuGoster,
            child: DottedBorder(
              color: Colors.grey[700]!,
              strokeWidth: 1.5,
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              dashPattern: const [8, 6],
              child: Container(
                height: _secilenResimler.isEmpty ? 180 : 80, // Resim yoksa daha büyük, varsa daha küçük
                // width: double.infinity, // DottedBorder zaten genişliği kaplar
                decoration: BoxDecoration(
                  // color: Colors.grey[850]?.withOpacity(0.7), // Hafif arka plan
                  borderRadius: BorderRadius.circular(15), // DottedBorder ile aynı
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[500], size: _secilenResimler.isEmpty ? 40 : 30),
                      SizedBox(height: _secilenResimler.isEmpty ? 10 : 4),
                      Text(
                          _secilenResimler.isEmpty ? "Resim seçin (En fazla $_maxResimSayisi)" : "Daha fazla resim ekle (${_maxResimSayisi - _secilenResimler.length} kaldı)",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: _secilenResimler.isEmpty ? 15 : 13, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_secilenResimler.length >= _maxResimSayisi && _secilenResimler.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 10.0),
            child: Text("Maksimum resim sayısına ulaştınız.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
          ),
        const SizedBox(height: 24), // Alanlar arası boşluk
      ],
    );
  }

  // _getLabelStyle, _buildTextFieldWrapper, _getInputDecoration, _buildOptionTile olduğu gibi kalır...
  TextStyle _getLabelStyle() => TextStyle(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.w500);

  Widget _buildTextFieldWrapper({
    required String label,
    required Widget child,
    bool isNotSavedToService = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text(label, style: _getLabelStyle()),
            if (isNotSavedToService)
              Text(" (Bu bilgi kaydedilmeyecek)", style: TextStyle(color: Colors.orangeAccent.shade200, fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.normal)),
          ],
        ),
        const SizedBox(height: 8.0),
        child,
      ]),
    );
  }

  InputDecoration _getInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildOptionTile(String title, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 0),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.8))
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: TextStyle(color: Colors.grey[200], fontSize: 16)),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ]),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, elevation: 0,
        leading: IconButton(icon: Icon(Icons.chevron_left, color: Colors.grey[300], size: 30), onPressed: _yukleniyor ? null : () => Navigator.of(context).pop()),
        title: Text("Pin Oluştur", style: TextStyle(color: Colors.grey[100], fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                _buildImagePreviewsAndPicker(), // YENİ RESİM ALANI WIDGET'I



                _buildTextFieldWrapper(
                  label: "Açıklama",
                  child: TextFormField(
                    controller: _aciklamaController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: _getInputDecoration("Pin'iniz hakkında daha fazla bilgi verin..."),
                    maxLines: 4,
                    validator: (value) {
                      if (value != null && value.trim().length > 500) return 'Açıklama en fazla 500 karakter olabilir.';
                      return null;
                    },
                  ),
                ),



                _buildTextFieldWrapper(
                  label: "Konum",
                  child: TextFormField(
                    controller: _konumController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: _getInputDecoration("Konum ekleyin (isteğe bağlı)..."),
                    validator: (value) => null,
                  ),
                ),

                _buildTextFieldWrapper(
                  label: "Pano Seçimi",
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonFormField<String>(
                      value: _secilenPano,
                      items: _panoSecenekleri.map((String pano) => DropdownMenuItem<String>(value: pano, child: Text(pano, style: const TextStyle(color: Colors.white, fontSize: 16)))).toList(),
                      onChanged: (String? newValue) => setState(() => _secilenPano = newValue),
                      decoration: InputDecoration(hintText: "Pano seçin*", hintStyle: TextStyle(color: Colors.grey[600]), border: InputBorder.none),
                      dropdownColor: Colors.grey[800], iconEnabledColor: Colors.grey[400],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      validator: (value) => (value == null || value.isEmpty) ? 'Lütfen bir pano seçin.' : null,
                    ),
                  ),
                ),



                const SizedBox(height: 80),
              ]),
            ),
          ),
        ),
        if (_yukleniyor) _buildLoadingOverlay(),
      ]),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: MediaQuery.of(context).padding.bottom + 16.0, top: 12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              disabledBackgroundColor: Colors.redAccent.withOpacity(0.4), disabledForegroundColor: Colors.white.withOpacity(0.7)
          ),
          onPressed: (_yukleniyor || _secilenResimler.isEmpty) ? null : _gonderiOlustur, // DEĞİŞTİ: _secilenResimler
          child: const Text("Oluştur", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}