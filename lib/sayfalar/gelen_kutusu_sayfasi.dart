// lib/sayfalar/gelen_kutusu_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/oneri_modeli.dart';
import 'package:pathbooks/sayfalar/duyurular.dart'; // Detay için bu sayfayı kullanıyoruz

class GelenKutusuSayfasi extends StatefulWidget {
  final OneriModeli? sonOneri; // Anasayfa'dan bu parametreyi alacak

  const GelenKutusuSayfasi({Key? key, this.sonOneri}) : super(key: key);

  @override
  _GelenKutusuSayfasiState createState() => _GelenKutusuSayfasiState();
}

class _GelenKutusuSayfasiState extends State<GelenKutusuSayfasi> {
  OneriModeli? _mevcutOneri;

  @override
  void initState() {
    super.initState();
    _mevcutOneri = widget.sonOneri;
  }

  // Anasayfa'dan gelen sonOneri güncellendiğinde bu widget'ın da güncellenmesi için
  @override
  void didUpdateWidget(covariant GelenKutusuSayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sonOneri != oldWidget.sonOneri) {
      if (mounted) {
        setState(() {
          _mevcutOneri = widget.sonOneri;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mevcutOneri == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Gelen Kutusu"),
          elevation: 1,
          // Geri butonu olmaması için (çünkü bu bir ana sekme)
          // automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_active_outlined, size: 80, color: Colors.grey[400]),
              SizedBox(height: 20),
              Text(
                "Görüntülenecek yeni bir öneri bulunmuyor.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
              Text(
                "Ana sayfada yeni öneriler belirebilir.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Eğer öneri varsa, DuyurularSayfasi widget'ını kullanarak göster
    // Gelen Kutusu kendi AppBar'ına sahip olduğu için DuyurularSayfasi'nın AppBar'ını kullanmayacağız.
    // Bu yüzden DuyurularSayfasi'nın sadece body'sini alabiliriz veya
    // DuyurularSayfasi'nı AppBar'sız bir seçenekle çağırabiliriz.
    // Şimdilik, direkt DuyurularSayfasi'nı yeni bir Scaffold içinde çağıralım:
    return Scaffold(
      appBar: AppBar(
        title: Text("Son Öneri"), // Veya _mevcutOneri.yerAdi
        elevation: 1,
        // automaticallyImplyLeading: false,
      ),
      body: DuyurularSayfasi(secilenOneri: _mevcutOneri!),
    );
  }
}