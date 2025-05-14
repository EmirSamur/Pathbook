// lib/sayfalar/yorumlar_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/yorum.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class YorumlarSayfasi extends StatefulWidget {
  final String gonderiId;

  const YorumlarSayfasi({Key? key, required this.gonderiId}) : super(key: key);

  @override
  _YorumlarSayfasiState createState() => _YorumlarSayfasiState();
}

class _YorumlarSayfasiState extends State<YorumlarSayfasi> {
  late FirestoreServisi _firestoreServisi;
  late YetkilendirmeServisi _yetkilendirmeServisi;
  final TextEditingController _yorumController = TextEditingController();
  bool _isYorumGonderiliyor = false;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);
  }

  @override
  void dispose() {
    _yorumController.dispose();
    super.dispose();
  }

  Future<void> _yorumGonder() async {
    if (_yorumController.text.trim().isEmpty) {
      return; // Boş yorum gönderme
    }
    if (_yetkilendirmeServisi.aktifKullaniciId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yorum yapmak için giriş yapmalısınız.")),
      );
      return;
    }

    setState(() {
      _isYorumGonderiliyor = true;
    });

    try {
      await _firestoreServisi.yorumEkle(
        aktifKullaniciId: _yetkilendirmeServisi.aktifKullaniciId!,
        gonderiId: widget.gonderiId,
        yorumMetni: _yorumController.text,
      );
      _yorumController.clear(); // Yorum alanını temizle
      // Gönderi kartındaki yorum sayısının güncellenmesi için AkisSayfasi'nın
      // state'ini güncellemek gerekebilir (event bus, callback veya provider ile).
      // Şimdilik bu sayfada yorum eklendiğinde AkisSayfasi'ndaki sayaç anında güncellenmeyecek.
      // Kullanıcı geri döndüğünde veya sayfa yenilendiğinde güncellenir.
    } catch (e) {
      print("Yorum gönderme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yorum gönderilirken bir hata oluştu.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isYorumGonderiliyor = false;
        });
      }
    }
  }

  Widget _buildYorumKarti(Yorum yorum) {
    // Tema renkleri için
    // final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[300],
        backgroundImage: (yorum.yorumuYapanKullanici?.fotoUrl != null && yorum.yorumuYapanKullanici!.fotoUrl!.isNotEmpty)
            ? NetworkImage(yorum.yorumuYapanKullanici!.fotoUrl!)
            : null,
        child: (yorum.yorumuYapanKullanici?.fotoUrl == null || yorum.yorumuYapanKullanici!.fotoUrl!.isEmpty)
            ? Icon(Icons.person, size: 18, color: Colors.grey[600])
            : null,
      ),
      title: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color), // Temadan al
          children: [
            TextSpan(
              text: "${yorum.yorumuYapanKullanici?.kullaniciAdi ?? 'Kullanıcı'}  ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: yorum.yorumMetni),
          ],
        ),
      ),
      subtitle: Text(
        // locale parametresini kaldır, varsayılan lokal (main.dart'ta ayarlanan) kullanılacak
        timeago.format(yorum.olusturulmaZamani.toDate()),
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
      // TODO: Yoruma cevap verme, beğenme gibi özellikler eklenebilir
    );
  }

  @override
  Widget build(BuildContext context) {
    Kullanici? aktifKullanici = _yetkilendirmeServisi.aktifKullaniciDetaylari; // Giriş yapmış kullanıcı bilgileri

    return Scaffold(
      appBar: AppBar(
        title: Text("Yorumlar"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreServisi.yorumlariGetir(widget.gonderiId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Yorumlar stream hatası: ${snapshot.error}");
                  return Center(child: Text("Yorumlar yüklenirken bir hata oluştu."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Bu gönderiye henüz yorum yapılmamış.\nİlk yorumu sen yap!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                final yorumDocs = snapshot.data!.docs;

                // Yorumları Yorum modeline dönüştürürken kullanıcı bilgilerini de çekiyoruz.
                // Bu, her yorum kartı için ayrı FutureBuilder kullanmaktan daha performanslı olabilir.
                // Ancak çok fazla yorum varsa ilk yükleme süresini etkileyebilir.
                // Alternatif olarak, YorumKarti içinde FutureBuilder ile kullanıcı bilgisi çekilebilir.
                return FutureBuilder<List<Yorum>>(
                  future: Future.wait(yorumDocs.map((doc) async {
                    final yorumData = doc.data();
                    Kullanici? yorumuYapan;
                    if (yorumData['kullaniciId'] != null && (yorumData['kullaniciId'] as String).isNotEmpty) {
                      yorumuYapan = await _firestoreServisi.kullaniciGetir(yorumData['kullaniciId'] as String);
                    }
                    return Yorum.dokumandanUret(doc, yapanKullanici: yorumuYapan);
                  }).toList()),
                  builder: (context, yorumSnapshot) {
                    if (yorumSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (yorumSnapshot.hasError) {
                      print("Yorum kullanıcı bilgisi çekme hatası: ${yorumSnapshot.error}");
                      return Center(child: Text("Yorum detayları yüklenemedi."));
                    }
                    if (!yorumSnapshot.hasData || yorumSnapshot.data!.isEmpty) {
                      return Center(child: Text("Yorum bulunamadı (detaylı).")); // Bu durum pek olası değil
                    }

                    final yorumlar = yorumSnapshot.data!;
                    return ListView.builder(
                      padding: EdgeInsets.only(bottom: 80), // Yorum yazma alanı için boşluk
                      itemCount: yorumlar.length,
                      itemBuilder: (context, index) {
                        final yorum = yorumlar[index];
                        return _buildYorumKarti(yorum);
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Yorum Yazma Alanı
          if (_yetkilendirmeServisi.aktifKullaniciId != null) // Sadece giriş yapmışsa göster
            SafeArea( // Ekranın altındaki sistem UI'larından etkilenmemek için
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  // color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (aktifKullanici?.fotoUrl != null && aktifKullanici!.fotoUrl!.isNotEmpty)
                          ? NetworkImage(aktifKullanici.fotoUrl!)
                          : null,
                      child: (aktifKullanici?.fotoUrl == null || aktifKullanici!.fotoUrl!.isEmpty)
                          ? Icon(Icons.person, size: 18, color: Colors.grey[600])
                          : null,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _yorumController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                            hintText: "Yorum ekle...",
                            border: InputBorder.none, // Veya OutlineInputBorder vb.
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0)
                        ),
                        onSubmitted: (value) => _yorumGonder(), // Enter ile gönderme
                      ),
                    ),
                    _isYorumGonderiliyor
                        ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0)),
                    )
                        : IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                      onPressed: _yorumGonder,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}