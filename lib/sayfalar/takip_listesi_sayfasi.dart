// lib/sayfalar/takip_listesi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';
import 'package:pathbooks/widgets/takip_butonu.dart';

/// Bir kullanıcının takipçilerini ve takip ettiklerini sekmeli olarak gösterir.
class TakipListesiSayfasi extends StatelessWidget {
  final Kullanici kullanici;
  final int baslangicSekmesi; // 0: Takipçiler, 1: Takip

  const TakipListesiSayfasi({super.key, required this.kullanici, this.baslangicSekmesi = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: baslangicSekmesi,
      child: Scaffold(
        appBar: AppBar(
          title: Text(kullanici.kullaniciAdi ?? "Kullanıcı"),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(fontFamily: 'Bebas', fontSize: 16),
            tabs: const [Tab(text: "Takipçiler"), Tab(text: "Takip Edilenler")],
          ),
        ),
        body: TabBarView(children: [
          _KullaniciListesi(kullaniciId: kullanici.id, takipciler: true),
          _KullaniciListesi(kullaniciId: kullanici.id, takipciler: false),
        ]),
      ),
    );
  }
}

class _KullaniciListesi extends StatefulWidget {
  final String kullaniciId;
  final bool takipciler;

  const _KullaniciListesi({required this.kullaniciId, required this.takipciler});

  @override
  State<_KullaniciListesi> createState() => _KullaniciListesiState();
}

class _KullaniciListesiState extends State<_KullaniciListesi> with AutomaticKeepAliveClientMixin {
  late Future<List<Kullanici>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = Provider.of<FirestoreServisi>(context, listen: false)
        .takipListesiGetir(kullaniciId: widget.kullaniciId, takipciler: widget.takipciler);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Kullanici>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => ListTile(
              leading: IskeletKutu(genislik: 44, yukseklik: 44, borderRadius: BorderRadius.circular(22)),
              title: Align(alignment: Alignment.centerLeft, child: IskeletKutu(genislik: 120, yukseklik: 12, borderRadius: BorderRadius.circular(6))),
            ),
          );
        }
        final liste = snapshot.data ?? [];
        if (liste.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline_rounded, size: 52, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(widget.takipciler ? "Henüz takipçi yok." : "Henüz kimse takip edilmiyor.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: liste.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[900]),
          itemBuilder: (context, i) {
            final k = liste[i];
            return ListTile(
              leading: KullaniciAvatari(fotoUrl: k.fotoUrl, kullaniciAdi: k.kullaniciAdi, yaricap: 22),
              title: Row(children: [
                Flexible(child: Text(k.kullaniciAdi ?? "Kullanıcı", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17))),
                if (k.isVerified == true) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, size: 15, color: Colors.redAccent[400])),
              ]),
              subtitle: (k.hakkinda?.isNotEmpty ?? false)
                  ? Text(k.hakkinda!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12))
                  : null,
              trailing: TakipButonu(hedefKullaniciId: k.id),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Profil(aktifKullanici: k))),
            );
          },
        );
      },
    );
  }
}
