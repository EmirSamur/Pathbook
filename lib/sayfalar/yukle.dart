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
  String? _secilenKategori; // Değişken adı daha genel "Kategori" oldu
  final List<String> _kategoriSecenekleri = const [ // Seçenekler
    "Doğa", "Tarih", "Kültür", "Yeme-İçme"
  ];

  final ImagePicker _picker = ImagePicker();
  bool _yukleniyor = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _konumController = TextEditingController();
  final TextEditingController _ulkeController = TextEditingController(); // YENİ
  final TextEditingController _sehirController = TextEditingController(); // YENİ

  final String cloudinaryCloudName = "dt4jjawbe"; // Güvenli bir yerden çekilmeli
  final String cloudinaryUploadPreset = "pathbooks"; // Güvenli bir yerden çekilmeli

  @override
  void dispose() {
    _aciklamaController.dispose();
    _konumController.dispose();
    _ulkeController.dispose(); // YENİ
    _sehirController.dispose(); // YENİ
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
        if (_secilenResimler.length >= _maxResimSayisi) {
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
    if (_secilenKategori == null || _secilenKategori!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir kategori seçin.")));
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

      // FirestoreServisi'ne ülke ve şehir bilgileri de gönderilecek
      await Provider.of<FirestoreServisi>(context, listen: false).gonderiOlustur(
        yayinlayanId: aktifKullaniciId,
        gonderiResmiUrls: yuklenenResimUrls,
        aciklama: _aciklamaController.text.trim(),
        kategori: _secilenKategori!,
        konum: _konumController.text.trim().isNotEmpty ? _konumController.text.trim() : null,
        ulke: _ulkeController.text.trim().isNotEmpty ? _ulkeController.text.trim() : null,   // YENİ
        sehir: _sehirController.text.trim().isNotEmpty ? _sehirController.text.trim() : null, // YENİ
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Paylaşım başarıyla oluşturuldu!"), backgroundColor: Colors.green),
        );
        setState(() {
          _secilenResimler.clear();
          _secilenKategori = null;
          _aciklamaController.clear();
          _konumController.clear();
          _ulkeController.clear();    // YENİ
          _sehirController.clear();   // YENİ
          _formKey.currentState?.reset();
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print("Gönderi oluşturma sürecinde hata: $e");
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

  Widget _buildImagePreviewsAndPicker() {
    return Column(
      children: [
        if (_secilenResimler.isNotEmpty)
          Container(
            height: 100, // Biraz daha kompakt
            margin: const EdgeInsets.only(bottom: 16.0, top:10.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _secilenResimler.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8), // Daha az yuvarlak
                        child: Image.file(_secilenResimler[index], width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: -8, right: -8,
                        child: InkWell(
                          onTap: _yukleniyor ? null : () => _resimKaldir(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(3), // padding ayarlandı
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle), // opacity ayarlandı
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 14), // boyut ayarlandı
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
              radius: const Radius.circular(12), dashPattern: const [6, 5],
              child: Container(
                height: _secilenResimler.isEmpty ? 140 : 60, // Yükseklik ayarlandı
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11)),
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: _secilenResimler.isEmpty ? 32 : 22), // boyut ayarlandı
                    SizedBox(height: _secilenResimler.isEmpty ? 8 : 2),
                    Text(
                        _secilenResimler.isEmpty ? "Resim Ekle (Max: $_maxResimSayisi)" : "+ Ekle (${_maxResimSayisi - _secilenResimler.length})",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: _secilenResimler.isEmpty ? 13 : 11, fontWeight: FontWeight.w500) // boyut ayarlandı
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
        const SizedBox(height: 18), // Boşluk ayarlandı
      ],
    );
  }

  TextStyle _getLabelStyle() => TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.w500); // Boyut ayarlandı

  Widget _buildTextFieldWrapper({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0), // Boşluk ayarlandı
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _getLabelStyle()),
        const SizedBox(height: 6.0), // Boşluk ayarlandı
        child,
      ]),
    );
  }

  InputDecoration _getInputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14.5), // Renk ve boyut ayarlandı
      filled: true,
      fillColor: Colors.grey[850]?.withOpacity(0.75), // Renk ve opaklık ayarlandı
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), // Radius ayarlandı
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.redAccent[100]!.withOpacity(0.7), width: 1.0)), // Renk ve kalınlık ayarlandı
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Padding ayarlandı
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0.3, // Hafif bir elevation
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.grey[300], size: 24), // Boyut ayarlandı
          onPressed: _yukleniyor
              ? null
              : () {
            if (_aciklamaController.text.isNotEmpty ||
                _konumController.text.isNotEmpty ||
                _ulkeController.text.isNotEmpty ||    // YENİ
                _sehirController.text.isNotEmpty ||   // YENİ
                _secilenResimler.isNotEmpty ||
                _secilenKategori != null) {
              showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: Text("Değişiklikler Kaydedilmeyecek", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)), // Font ayarlandı
                    content: Text("Bu sayfadan çıkarsanız girdiğiniz bilgiler silinecektir. Emin misiniz?", style: TextStyle(color: Colors.grey[300], fontSize: 13.5)), // Font ayarlandı
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text("İptal", style: TextStyle(color: Colors.grey[400], fontSize: 14))), // Font ayarlandı
                      TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pop();
                          },
                          child: Text("Çık", style: TextStyle(color: Colors.redAccent[100], fontSize: 14, fontWeight: FontWeight.bold))), // Font ayarlandı
                    ],
                  ));
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text("Yeni Paylaşım Oluştur", style: TextStyle(color: Colors.grey[100], fontWeight: FontWeight.w500, fontSize: 16)), // Başlık ve font ayarlandı
        centerTitle: true,
      ),
      body: Stack(children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0), // Padding ayarlandı
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                _buildImagePreviewsAndPicker(),
                _buildTextFieldWrapper(
                  label: "Açıklama", // "İsteğe Bağlı" kaldırıldı, ama validator yok
                  child: TextFormField(
                    controller: _aciklamaController,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    decoration: _getInputDecoration("Bu yer veya deneyim hakkında bir şeyler yaz..."),
                    maxLines: 4, // Satır sayısı ayarlandı
                    maxLength: 300, // Karakter limiti ayarlandı
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                    (maxLength != null && currentLength > maxLength - 30) || currentLength > 0 ?
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text("${currentLength}/${maxLength}", style: TextStyle(color: Colors.grey[600], fontSize: 10.5)),
                    ) : null,
                    validator: (value) {
                      if (value != null && value.trim().length > 300) return 'Açıklama 300 karakteri geçemez.';
                      return null; // Açıklama boş olabilir
                    },
                  ),
                ),
                _buildTextFieldWrapper(
                  label: "Konum Etiketi", // Daha genel bir ifade
                  child: TextFormField(
                    controller: _konumController,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    decoration: _getInputDecoration("Örn: Sultanahmet Camii, Kapadokya", suffixIcon: Icon(Icons.location_pin, color: Colors.grey[500], size: 17,)), // İkon ve hint ayarlandı
                    validator: (value) => null,
                  ),
                ),
                _buildTextFieldWrapper(
                  label: "Ülke", // "İsteğe Bağlı" kaldırıldı, ama validator yok
                  child: TextFormField(
                    controller: _ulkeController,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    decoration: _getInputDecoration("Örn: Türkiye", suffixIcon: Icon(Icons.public_rounded, color: Colors.grey[500], size: 17,)), // İkon ayarlandı
                    validator: (value) => null,
                  ),
                ),
                _buildTextFieldWrapper(
                  label: "Şehir", // "İsteğe Bağlı" kaldırıldı, ama validator yok
                  child: TextFormField(
                    controller: _sehirController,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    decoration: _getInputDecoration("Örn: İstanbul", suffixIcon: Icon(Icons.location_city_rounded, color: Colors.grey[500], size: 17,)), // İkon ayarlandı
                    validator: (value) => null,
                  ),
                ),
                _buildTextFieldWrapper(
                  label: "Kategori*",
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    decoration: BoxDecoration(color: Colors.grey[850]?.withOpacity(0.75), borderRadius: BorderRadius.circular(10)), // Renk ve radius ayarlandı
                    child: DropdownButtonFormField<String>(
                      value: _secilenKategori,
                      items: _kategoriSecenekleri.map((String kategori) => DropdownMenuItem<String>(value: kategori, child: Text(kategori, style: const TextStyle(fontSize: 14.5)))).toList(),
                      onChanged: (String? newValue) => setState(() => _secilenKategori = newValue),
                      decoration: InputDecoration(
                        hintText: "Kategori seçin...", // Hint ayarlandı
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14.5),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), // Padding ayarlandı
                      ),
                      dropdownColor: Colors.grey[800],
                      iconEnabledColor: Colors.grey[400],
                      iconSize: 24, // İkon boyutu ayarlandı
                      style: const TextStyle(color: Colors.white, fontSize: 14.5),
                      validator: (value) => (value == null || value.isEmpty) ? 'Lütfen bir kategori seçin.' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Buton için altta daha fazla boşluk
              ]),
            ),
          ),
        ),
        if (_yukleniyor) _buildLoadingOverlay(),
      ]),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: EdgeInsets.only(
            left: 16.0, right: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 10.0, // Boşluk ayarlandı
            top: 8.0 // Boşluk ayarlandı
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent[200]?.withOpacity(0.9), // Renk ve opaklık ayarlandı
              padding: const EdgeInsets.symmetric(vertical: 12), // Yükseklik ayarlandı
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Radius ayarlandı
              disabledBackgroundColor: Colors.redAccent[100]?.withOpacity(0.3),
              disabledForegroundColor: Colors.white.withOpacity(0.5)
          ),
          onPressed: (_yukleniyor || _secilenResimler.isEmpty || _secilenKategori == null) ? null : _gonderiOlustur,
          child: const Text("Pathbook'ta Paylaş", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)), // Font ayarlandı
        ),
      ),
    );
  }
}