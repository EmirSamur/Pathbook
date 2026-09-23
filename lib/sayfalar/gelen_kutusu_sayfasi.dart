// lib/sayfalar/gelen_kutusu_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pathbooks/modeller/bildirim.dart';
import 'package:pathbooks/modeller/oneri_modeli.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/sayfalar/duyurular.dart';
import 'package:pathbooks/sayfalar/gonderi_detay_sayfasi.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';

/// Bildirimler (beğeni, yorum, takip) ve gezi önerileri.
class GelenKutusuSayfasi extends StatefulWidget {
  final OneriModeli? sonOneri; // Anasayfa'da en son gösterilen öneri

  const GelenKutusuSayfasi({Key? key, this.sonOneri}) : super(key: key);

  @override
  _GelenKutusuSayfasiState createState() => _GelenKutusuSayfasiState();
}

class _GelenKutusuSayfasiState extends State<GelenKutusuSayfasi> {
  late final FirestoreServisi _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
  late final String? _aktifId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
  late final Stream<List<Bildirim>> _bildirimStream = _firestoreServisi.bildirimleriGetir(_aktifId ?? '');
  late Future<List<OneriModeli>> _onerilerFuture = _firestoreServisi.tumOnerileriGetir();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Gelen Kutusu"),
          actions: [
            IconButton(
              tooltip: "Tümünü okundu say",
              icon: const Icon(Icons.done_all_rounded),
              onPressed: _aktifId == null ? null : () => _firestoreServisi.bildirimleriOkunduYap(_aktifId),
            ),
          ],
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelStyle: const TextStyle(fontFamily: 'Bebas', fontSize: 16),
            tabs: const [Tab(text: "Bildirimler"), Tab(text: "Öneriler")],
          ),
        ),
        body: TabBarView(children: [
          _bildirimler(),
          _oneriler(),
        ]),
      ),
    );
  }

  Widget _bildirimler() {
    return StreamBuilder<List<Bildirim>>(
      stream: _bildirimStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _bos(Icons.cloud_off_rounded, "Bildirimler yüklenemedi.", "Bağlantını kontrol edip tekrar dene.");
        }
        if (!snapshot.hasData) {
          return ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => ListTile(
              leading: IskeletKutu(genislik: 44, yukseklik: 44, borderRadius: BorderRadius.circular(22)),
              title: Align(alignment: Alignment.centerLeft, child: IskeletKutu(genislik: 200, yukseklik: 12, borderRadius: BorderRadius.circular(6))),
            ),
          );
        }
        final liste = snapshot.data!;
        if (liste.isEmpty) {
          return _bos(Icons.notifications_none_rounded, "Henüz bildirimin yok.", "Biri gönderini beğendiğinde, yorum yaptığında\nveya seni takip ettiğinde burada göreceksin.");
        }
        return ListView.separated(
          itemCount: liste.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[900]),
          itemBuilder: (context, i) => _bildirimSatiri(liste[i]),
        );
      },
    );
  }

  Widget _bildirimSatiri(Bildirim b) {
    final IconData turIkonu = switch (b.tur) {
      Bildirim.turBegeni => Icons.favorite_rounded,
      Bildirim.turYorum => Icons.mode_comment_rounded,
      _ => Icons.person_add_alt_1_rounded,
    };
    final Color turRengi = switch (b.tur) {
      Bildirim.turBegeni => Colors.redAccent,
      Bildirim.turYorum => Colors.lightBlueAccent,
      _ => Colors.greenAccent,
    };

    return Container(
      color: b.okundu ? null : Theme.of(context).colorScheme.primary.withOpacity(0.08),
      child: ListTile(
        onTap: () => _bildirimeGit(b),
        leading: Stack(clipBehavior: Clip.none, children: [
          KullaniciAvatari(fotoUrl: b.yapanFotoUrl, kullaniciAdi: b.yapanKullaniciAdi, yaricap: 22),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
              child: Icon(turIkonu, size: 12, color: turRengi),
            ),
          ),
        ]),
        title: RichText(
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: const TextStyle(fontSize: 14, height: 1.3, color: Colors.white),
            children: [
              TextSpan(text: "${b.yapanKullaniciAdi ?? 'Bir gezgin'} ", style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: b.aciklama),
            ],
          ),
        ),
        subtitle: Text(timeago.format(b.olusturulmaZamani.toDate()), style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
        trailing: b.gonderiResimUrl != null
            ? ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 44, height: 44, child: AgGorseli(url: b.gonderiResimUrl!)))
            : null,
      ),
    );
  }

  Future<void> _bildirimeGit(Bildirim b) async {
    if (b.gonderiId != null) {
      final gonderi = await _firestoreServisi.gonderiGetir(b.gonderiId!);
      if (!mounted) return;
      if (gonderi == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu gönderi artık mevcut değil.")));
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => GonderiDetaySayfasi(gonderi: gonderi)));
    } else {
      final kullanici = await _firestoreServisi.kullaniciGetir(b.yapanId);
      if (!mounted || kullanici == null) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => Profil(aktifKullanici: kullanici)));
    }
  }

  Widget _oneriler() {
    return RefreshIndicator(
      onRefresh: () async {
        final f = _firestoreServisi.tumOnerileriGetir();
        setState(() => _onerilerFuture = f);
        await f;
      },
      child: FutureBuilder<List<OneriModeli>>(
        future: _onerilerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView.builder(
              itemCount: 3,
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IskeletKutu(yukseklik: 150, borderRadius: BorderRadius.circular(14)),
              ),
            );
          }
          final liste = [...?snapshot.data];
          // Ana sayfada en son gösterilen öneri en üstte dursun.
          if (widget.sonOneri != null) {
            liste.removeWhere((o) => o.id == widget.sonOneri!.id);
            liste.insert(0, widget.sonOneri!);
          }
          if (liste.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 120),
              _bos(Icons.lightbulb_outline_rounded, "Görüntülenecek öneri bulunmuyor.", "Yeni öneriler eklendiğinde burada görünecek."),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: liste.length,
            itemBuilder: (context, i) => _oneriKarti(liste[i]),
          );
        },
      ),
    );
  }

  Widget _oneriKarti(OneriModeli oneri) {
    final bool gorselVar = oneri.gorselUrl?.isNotEmpty == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DuyurularSayfasi(secilenOneri: oneri))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 150,
            child: Stack(fit: StackFit.expand, children: [
              gorselVar ? AgGorseli(url: oneri.gorselUrl!) : Container(color: const Color(0xFF1C1C1E)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(oneri.yerAdi, style: const TextStyle(fontSize: 20, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(oneri.ipucuMetni, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: Colors.grey[300])),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _bos(IconData ikon, String baslik, String altMetin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(baslik, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(altMetin, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.4)),
        ]),
      ),
    );
  }
}
