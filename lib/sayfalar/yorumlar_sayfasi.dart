// lib/sayfalar/yorumlar_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/modeller/yorum.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';
import 'package:pathbooks/sayfalar/profil.dart';
import 'package:pathbooks/widgets/ortak_widgetlar.dart';
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
  late Stream<List<Yorum>> _yorumStream;
  final TextEditingController _yorumController = TextEditingController();
  final FocusNode _yorumFocus = FocusNode();
  bool _isYorumGonderiliyor = false;
  Yorum? _yanitlanan; // Cevap verilen yorum

  String? get _aktifId => _yetkilendirmeServisi.aktifKullaniciId;

  @override
  void initState() {
    super.initState();
    _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
    _yetkilendirmeServisi = Provider.of<YetkilendirmeServisi>(context, listen: false);
    // Yorumlar ve yorum sahipleri tek akışta hazırlanır; kullanıcılar önbellekten gelir.
    _yorumStream = _firestoreServisi.yorumlariGetir(widget.gonderiId).asyncMap((snapshot) async {
      final kullanicilar = await Future.wait(snapshot.docs.map((doc) {
        final String id = doc.data()['kullaniciId'] as String? ?? '';
        return id.isNotEmpty ? _firestoreServisi.kullaniciGetir(id) : Future<Kullanici?>.value(null);
      }));
      return [
        for (int i = 0; i < snapshot.docs.length; i++) Yorum.dokumandanUret(snapshot.docs[i], yapanKullanici: kullanicilar[i]),
      ];
    });
  }

  @override
  void dispose() {
    _yorumController.dispose();
    _yorumFocus.dispose();
    super.dispose();
  }

  Future<void> _yorumGonder() async {
    if (_yorumController.text.trim().isEmpty || _isYorumGonderiliyor) return;
    if (_aktifId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum yapmak için giriş yapmalısınız.")));
      return;
    }
    setState(() => _isYorumGonderiliyor = true);
    try {
      await _firestoreServisi.yorumEkle(
        aktifKullaniciId: _aktifId!,
        gonderiId: widget.gonderiId,
        yorumMetni: _yorumController.text,
        // Cevaplar tek seviyeli tutulur: cevaba cevap, ana yoruma bağlanır.
        ustYorumId: _yanitlanan == null ? null : (_yanitlanan!.ustYorumId ?? _yanitlanan!.id),
      );
      _yorumController.clear();
      setState(() => _yanitlanan = null);
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum gönderilirken bir hata oluştu.")));
    } finally {
      if (mounted) setState(() => _isYorumGonderiliyor = false);
    }
  }

  void _yanitla(Yorum yorum) {
    final String ad = yorum.yorumuYapanKullanici?.kullaniciAdi ?? "";
    setState(() => _yanitlanan = yorum);
    if (ad.isNotEmpty && !_yorumController.text.startsWith("@$ad")) {
      _yorumController.text = "@$ad ";
      _yorumController.selection = TextSelection.collapsed(offset: _yorumController.text.length);
    }
    _yorumFocus.requestFocus();
  }

  Future<void> _begen(Yorum yorum) async {
    if (_aktifId == null) return;
    try {
      await _firestoreServisi.yorumBegenToggle(gonderiId: widget.gonderiId, yorumId: yorum.id, aktifKullaniciId: _aktifId!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum beğenilemedi.")));
    }
  }

  Future<void> _sil(Yorum yorum) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("Yorumu Sil"),
        content: Text("Bu yorumu silmek istediğine emin misin?", style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text("Vazgeç", style: TextStyle(color: Colors.grey[400]))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sil", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await _firestoreServisi.yorumSil(gonderiId: widget.gonderiId, yorumId: yorum.id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum silinemedi.")));
    }
  }

  Widget _buildYorumKarti(Yorum yorum, {bool cevap = false}) {
    final Kullanici? yapan = yorum.yorumuYapanKullanici;
    final bool begendim = _aktifId != null && yorum.begenenler.contains(_aktifId);
    final bool benim = _aktifId != null && yorum.kullaniciId == _aktifId;

    return InkWell(
      onLongPress: benim ? () => _sil(yorum) : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(cevap ? 60 : 14, 8, 6, 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: yapan == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => Profil(aktifKullanici: yapan))),
            child: KullaniciAvatari(fotoUrl: yapan?.fotoUrl, kullaniciAdi: yapan?.kullaniciAdi, yaricap: cevap ? 14 : 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, height: 1.35, color: Theme.of(context).textTheme.bodyLarge?.color),
                  children: [
                    TextSpan(text: "${yapan?.kullaniciAdi ?? 'Kullanıcı'}  ", style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: yorum.yorumMetni),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Text(timeago.format(yorum.olusturulmaZamani.toDate()), style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                if (yorum.begenenler.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text("${yorum.begenenler.length} beğeni", style: TextStyle(fontSize: 11.5, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                ],
                if (_aktifId != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _yanitla(yorum),
                    child: Text("Yanıtla", style: TextStyle(fontSize: 11.5, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
            ]),
          ),
          if (_aktifId != null)
            IconButton(
              icon: Icon(begendim ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: begendim ? Colors.redAccent[200] : Colors.grey[500]),
              onPressed: () => _begen(yorum),
              visualDensity: VisualDensity.compact,
              tooltip: "Beğen",
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Kullanici? aktifKullanici = _yetkilendirmeServisi.aktifKullaniciDetaylari;

    return Scaffold(
      appBar: AppBar(title: const Text("Yorumlar")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Yorum>>(
              stream: _yorumStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Yorumlar yüklenirken bir hata oluştu."));
                }
                if (!snapshot.hasData) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) => ListTile(
                      leading: IskeletKutu(genislik: 36, yukseklik: 36, borderRadius: BorderRadius.circular(18)),
                      title: Align(alignment: Alignment.centerLeft, child: IskeletKutu(genislik: 180, yukseklik: 12, borderRadius: BorderRadius.circular(6))),
                    ),
                  );
                }
                final yorumlar = snapshot.data!;
                if (yorumlar.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 52, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text("Bu gönderiye henüz yorum yapılmamış.\nİlk yorumu sen yap!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                    ]),
                  );
                }

                // Ana yorumları ve altlarındaki cevapları grupla. Ana yorumu
                // silinmiş cevaplar ana yorum gibi gösterilir.
                final Set<String> idler = yorumlar.map((y) => y.id).toSet();
                final anaYorumlar = yorumlar.where((y) => y.ustYorumId == null || !idler.contains(y.ustYorumId)).toList();
                final Map<String, List<Yorum>> cevaplar = {};
                for (final y in yorumlar) {
                  if (y.ustYorumId != null && idler.contains(y.ustYorumId)) cevaplar.putIfAbsent(y.ustYorumId!, () => []).add(y);
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 16, top: 4),
                  children: [
                    for (final ana in anaYorumlar) ...[
                      _buildYorumKarti(ana),
                      for (final c in cevaplar[ana.id] ?? const <Yorum>[]) _buildYorumKarti(c, cevap: true),
                    ],
                  ],
                );
              },
            ),
          ),
          if (_aktifId != null)
            SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border(top: BorderSide(color: Colors.grey[850]!, width: 0.5)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (_yanitlanan != null)
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF1C1C1E),
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            "${_yanitlanan!.yorumuYapanKullanici?.kullaniciAdi ?? 'Kullanıcı'} adlı kişiye yanıt veriyorsun",
                            style: TextStyle(color: Colors.grey[400], fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() {
                            _yanitlanan = null;
                            _yorumController.clear();
                          }),
                        ),
                      ]),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        KullaniciAvatari(fotoUrl: aktifKullanici?.fotoUrl, kullaniciAdi: aktifKullanici?.kullaniciAdi, yaricap: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _yorumController,
                            focusNode: _yorumFocus,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: _yanitlanan == null ? "Yorum ekle..." : "Yanıtını yaz...",
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            ),
                            onSubmitted: (_) => _yorumGonder(),
                          ),
                        ),
                        _isYorumGonderiliyor
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0)),
                              )
                            : IconButton(
                                icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.primary),
                                onPressed: _yorumGonder,
                              ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
