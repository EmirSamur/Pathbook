// lib/sayfalar/dosya_detay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/dosya_modeli.dart';
// import 'package:pathbooks/modeller/gonderi.dart';
// import 'package:pathbooks/servisler/firestoreseervisi.dart';
// import 'package:provider/provider.dart';
// import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';

class DosyaDetaySayfasi extends StatefulWidget {
  final DosyaModeli dosya;

  const DosyaDetaySayfasi({Key? key, required this.dosya}) : super(key: key);

  @override
  _DosyaDetaySayfasiState createState() => _DosyaDetaySayfasiState();
}

class _DosyaDetaySayfasiState extends State<DosyaDetaySayfasi> {
  // late FirestoreServisi _firestoreServisi;
  // List<Gonderi> _gonderiler = [];
  // bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    // _dosyayaAitGonderileriYukle();
  }

  // Future<void> _dosyayaAitGonderileriYukle() async {
  //   // setState(() => _isLoading = true);
  //   // _gonderiler = await _firestoreServisi.dosyadanGonderileriGetir(widget.dosya.id);
  //   // setState(() => _isLoading = false);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Color(0xFF181818),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(widget.dosya.ad, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // TODO: AppBar'a dosya seçenekleri (düzenle, paylaş vb.) eklenebilir
      ),
      body: /* _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _gonderiler.isEmpty
              ? Center(child: Text("Bu dosyada henüz gönderi yok.", style: TextStyle(color: Colors.grey[400])))
              : */
      Center(
          child: Text(
            "Dosya ID: ${widget.dosya.id} için gönderiler burada listelenecek.\n(GridView Kullanılabilir)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          )),
      // GridView.builder(
      //   padding: EdgeInsets.all(8),
      //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //     crossAxisCount: 2, // Veya 3
      //     crossAxisSpacing: 8,
      //     mainAxisSpacing: 8,
      //     childAspectRatio: 0.8, // Pinterest'te daha dikey kartlar
      //   ),
      //   itemCount: _gonderiler.length,
      //   itemBuilder: (context, index) {
      //     final gonderi = _gonderiler[index];
      //     return GestureDetector(
      //       onTap: () {
      //         // Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderiId: gonderi.id)));
      //       },
      //       child: ClipRRect(
      //         borderRadius: BorderRadius.circular(12.0),
      //         child: Image.network(gonderi.resimUrl, fit: BoxFit.cover),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}