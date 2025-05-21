// lib/sayfalar/yukle.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';

class GonderiEkleSayfasi extends StatefulWidget {
  const GonderiEkleSayfasi({Key? key}) : super(key: key);

  @override
  _GonderiEkleSayfasiState createState() => _GonderiEkleSayfasiState();
}

class _GonderiEkleSayfasiState extends State<GonderiEkleSayfasi> {
  List<File> _secilenResimler = [];
  final int _maxResimSayisi = 5;
  String? _secilenPano;
  final List<String> _panoSecenekleri = const [
    "Doğa", "Tarih", "Kültür", "Yeme-İçme"
  ];

  final ImagePicker _picker = ImagePicker();
  bool _yukleniyor = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _konumController = TextEditingController();

  // Cloudinary bilgileri (bunları güvenli bir yerden çekmek daha iyi olabilir)
  final String cloudinaryCloudName = "dt4jjawbe";
  final String cloudinaryUploadPreset = "pathbooks";

  @override
  void dispose() {
    _aciklamaController.dispose();
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
        final List<XFile>? pickedFiles = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1080);
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
        if (_secilenResimler.length >= _maxResimSayisi) { // Bu kontrol _resimSecimMenusuGoster içinde de var ama burada da olması iyi.
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("En fazla $_maxResimSayisi resim ekleyebilirsiniz.")));
          return;
        }
        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1080);
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
    if (_yukleniyor) return;
    if (_secilenResimler.length >= _maxResimSayisi) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Maksimum resim sayısına ulaştınız.")));
      return;
    }
    showModalBottomSheet(
      context: context, backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                title: const Text('Galeriden Seç (Çoklu)', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.of(context).pop(); _resimSec(sourceFromButton: ImageSource.gallery); },
              ),
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
  }

  void _resimKaldir(int index) {
    if (_yukleniyor) return;
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
      return response.secureUrl.isNotEmpty ? response.secureUrl : null;
    } catch (e) {
      print("Cloudinary yükleme istisnası: $e");
      return null;
    }
  }

  Future<void> _gonderiOlustur() async {
    if (!_formKey.currentState!.validate()) return;
    if (_secilenResimler.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen en az bir resim seçin.")));
      return;
    }
    if (_secilenPano == null || _secilenPano!.isEmpty) { // Pano seçimi kontrolü
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir pano seçin.")));
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
          throw Exception("Bir resim yüklenemedi. Lütfen internet bağlantınızı kontrol edin.");
        }
      }

      if (yuklenenResimUrls.length != _secilenResimler.length) {
        throw Exception("Tüm resimler yüklenemedi.");
      }

      final String? aktifKullaniciId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
      if (aktifKullaniciId == null) {
        throw Exception("Oturum hatası. Lütfen tekrar giriş yapın.");
      }

      await Provider.of<FirestoreServisi>(context, listen: false).gonderiOlustur(
        yayinlayanId: aktifKullaniciId,
        gonderiResmiUrls: yuklenenResimUrls,
        aciklama: _aciklamaController.text.trim(),
        kategori: _secilenPano!,
        konum: _konumController.text.trim().isNotEmpty ? _konumController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Paylaşım başarıyla oluşturuldu!"), backgroundColor: Colors.green),
        );
        // Formu ve state'i temizle
        setState(() {
          _secilenResimler.clear();
          _secilenPano = null;
          _aciklamaController.clear();
          _konumController.clear();
          _formKey.currentState?.reset(); // Dropdown'ı da sıfırlar
        });
        // Bir önceki sayfaya başarı bilgisiyle dön
        // Kısa bir gecikme, SnackBar'ın görünmesi için
        await Future.delayed(const Duration(milliseconds: 1200));
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true); // true değeri, bir önceki sayfanın yenileme yapması gerektiğini belirtir
        }
      }
    } catch (e) {
      print("Pin oluşturma sürecinde hata: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gönderi oluşturulamadı: ${e.toString().length > 100 ? e.toString().substring(0,100) + "..." : e.toString()}"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10)
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent[100]!)),
            const SizedBox(height: 18),
            Text("Paylaşılıyor...", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _buildImagePreviewsAndPicker() { /* ... (Bir önceki mesajdaki gibi, tam haliyle) ... */
    return Column(
      children: [
        if (_secilenResimler.isNotEmpty)
          Container(
            height: 110, // Biraz daha kompakt
            margin: const EdgeInsets.only(bottom: 16.0, top:10.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _secilenResimler.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0), // Resimler arası boşluk
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10), // Daha az yuvarlak
                        child: Image.file(_secilenResimler[index], width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: -10, right: -10, // Konum ayarlandı
                        child: InkWell(
                          onTap: _yukleniyor ? null : () => _resimKaldir(index),
                          borderRadius: BorderRadius.circular(12), // Tıklama alanı için
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 16), // İkon boyutu
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_secilenResimler.length < _maxResimSayisi)
          GestureDetector(
            onTap: _yukleniyor ? null : _resimSecimMenusuGoster,
            child: DottedBorder(
              color: Colors.grey[700]!, strokeWidth: 1.2, borderType: BorderType.RRect,
              radius: const Radius.circular(12), dashPattern: const [6, 5], // Desen ayarlandı
              child: Container(
                height: _secilenResimler.isEmpty ? 150 : 70, // Yükseklik ayarlandı
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: _secilenResimler.isEmpty ? 35 : 25),
                    SizedBox(height: _secilenResimler.isEmpty ? 8 : 3),
                    Text(
                        _secilenResimler.isEmpty ? "Resim Ekle (Max: $_maxResimSayisi)" : "+ Ekle (${_maxResimSayisi - _secilenResimler.length})",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: _secilenResimler.isEmpty ? 14 : 12, fontWeight: FontWeight.w500)
                    ),
                  ]),
                ),
              ),
            ),
          ),
        if (_secilenResimler.length >= _maxResimSayisi && _secilenResimler.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
            child: Text("Maksimum resim sayısına ulaştınız.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  TextStyle _getLabelStyle() => TextStyle(color: Colors.grey[300], fontSize: 13.5, fontWeight: FontWeight.w500); // Boyut ayarlandı

  Widget _buildTextFieldWrapper({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Boşluk ayarlandı
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _getLabelStyle()),
        const SizedBox(height: 7.0), // Boşluk ayarlandı
        child,
      ]),
    );
  }

  InputDecoration _getInputDecoration(String hintText, {Widget? suffixIcon}) { // suffixIcon eklendi
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[650], fontSize: 15), // Renk ve boyut ayarlandı
      filled: true,
      fillColor: Colors.grey[850]?.withOpacity(0.8), // Renk ve opaklık ayarlandı
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), // Radius ayarlandı
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.redAccent[100]!.withOpacity(0.8), width: 1.2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // Padding ayarlandı
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Temayı al
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0.5, // Hafif bir elevation
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.grey[300], size: 26), // Geri yerine kapat ikonu
          onPressed: _yukleniyor
              ? null
              : () {
            // Kullanıcı bir şeyler yazdıysa veya resim seçtiyse onay sor
            if (_aciklamaController.text.isNotEmpty ||
                _konumController.text.isNotEmpty ||
                _secilenResimler.isNotEmpty ||
                _secilenPano != null) {
              showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: Text("Değişiklikler Kaydedilmeyecek", style: TextStyle(color: Colors.white, fontSize: 18)),
                    content: Text("Bu sayfadan çıkarsanız girdiğiniz bilgiler silinecektir. Emin misiniz?", style: TextStyle(color: Colors.grey[300], fontSize: 14)),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text("İptal", style: TextStyle(color: Colors.grey[400]))),
                      TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(); // Diyaloğu kapat
                            Navigator.of(context).pop();     // Sayfayı kapat
                          },
                          child: Text("Çık", style: TextStyle(color: Colors.redAccent[100]))),
                    ],
                  ));
            } else {
              Navigator.of(context).pop(); // Değişiklik yoksa direkt çık
            }
          },
        ),
        title: Text("Yeni Paylaşım", style: TextStyle(color: Colors.grey[100], fontWeight: FontWeight.bold, fontSize: 17)), // Başlık ayarlandı
        centerTitle: true,
      ),
      body: Stack(children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0), // Padding ayarlandı
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                _buildImagePreviewsAndPicker(),
                _buildTextFieldWrapper(
                  label: "Açıklama (İsteğe Bağlı)",
                  child: TextFormField(
                    controller: _aciklamaController,
                    style: const TextStyle(color: Colors.white, fontSize: 15), // Boyut ayarlandı
                    decoration: _getInputDecoration("Bu yer hakkında bir şeyler yaz..."),
                    maxLines: 5, // Biraz daha fazla satır
                    maxLength: 500, // Karakter limiti göstergesi
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                    (maxLength != null && currentLength > maxLength - 50) || currentLength > 0 ?
                    Text("${currentLength}/${maxLength}", style: TextStyle(color: Colors.grey[500], fontSize: 11)) : null,
                    validator: (value) {
                      if (value != null && value.trim().length > 500) return 'Açıklama 500 karakteri geçemez.';
                      return null;
                    },
                  ),
                ),
                _buildTextFieldWrapper(
                  label: "Konum (İsteğe Bağlı)",
                  child: TextFormField(
                    controller: _konumController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: _getInputDecoration("Örn: Van Gölü, Türkiye", suffixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 18,)),
                    validator: (value) => null,
                  ),
                ),
                _buildTextFieldWrapper(
                  label: "Kategori*",
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // İç padding Dropdown'a bırakıldı
                    decoration: BoxDecoration(color: Colors.grey[850]?.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonFormField<String>(
                      value: _secilenPano,
                      items: _panoSecenekleri.map((String pano) => DropdownMenuItem<String>(value: pano, child: Text(pano, style: const TextStyle(fontSize: 15)))).toList(),
                      onChanged: (String? newValue) => setState(() => _secilenPano = newValue),
                      decoration: InputDecoration(
                        hintText: "Kategori seçin",
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                        border: InputBorder.none, // Dış çerçeveyi kaldır
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), // İç padding
                      ),
                      dropdownColor: Colors.grey[800],
                      iconEnabledColor: Colors.grey[400],
                      iconSize: 26, // İkon boyutu
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (value) => (value == null || value.isEmpty) ? 'Lütfen bir kategori seçin.' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 70), // Buton için altta boşluk
              ]),
            ),
          ),
        ),
        if (_yukleniyor) _buildLoadingOverlay(),
      ]),
      bottomNavigationBar: Container(
        color: Colors.black, // Arka plan rengi
        padding: EdgeInsets.only(
            left: 18.0, right: 18.0,
            bottom: MediaQuery.of(context).padding.bottom + 12.0, // Alt SafeArea + ekstra boşluk
            top: 10.0
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent[200], // Renk ayarlandı
              padding: const EdgeInsets.symmetric(vertical: 14), // Yükseklik ayarlandı
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Daha yuvarlak
              disabledBackgroundColor: Colors.redAccent[100]?.withOpacity(0.4),
              disabledForegroundColor: Colors.white.withOpacity(0.6)
          ),
          onPressed: (_yukleniyor || _secilenResimler.isEmpty || _secilenPano == null) ? null : _gonderiOlustur, // Pano seçimi de kontrol ediliyor
          child: const Text("Paylaş", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), // Font ayarlandı
        ),
      ),
    );
  }
}