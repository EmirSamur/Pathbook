// lib/widgets/gonderi_secenekleri.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pathbooks/modeller/gonderi.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';

/// Gönderideki "•••" menüsü.
/// Sahibine: Düzenle / Sil. Diğerlerine: Şikayet et / Kullanıcıyı engelle.
Future<void> gonderiSecenekleriniGoster(
  BuildContext context, {
  required Gonderi gonderi,
  VoidCallback? onSilindi,
  ValueChanged<String>? onGuncellendi,
  VoidCallback? onEngellendi,
}) async {
  final String? aktifId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
  final bool sahibi = aktifId != null && aktifId == gonderi.kullaniciId;

  final String? secim = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 38,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
          ),
          if (sahibi) ...[
            _secenek(sheetContext, 'duzenle', Icons.edit_outlined, "Açıklamayı Düzenle"),
            _secenek(sheetContext, 'sil', Icons.delete_outline_rounded, "Gönderiyi Sil", renk: Colors.redAccent),
          ] else ...[
            _secenek(sheetContext, 'sikayet', Icons.flag_outlined, "Şikayet Et", renk: Colors.orangeAccent),
            _secenek(sheetContext, 'engelle', Icons.block_rounded, "Kullanıcıyı Engelle", renk: Colors.redAccent),
          ],
          _secenek(sheetContext, 'paylas', Icons.share_outlined, "Paylaş"),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (secim == null || !context.mounted) return;

  final firestore = Provider.of<FirestoreServisi>(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);

  switch (secim) {
    case 'duzenle':
      final String? yeniAciklama = await _aciklamaDuzenleDialog(context, gonderi.aciklama);
      if (yeniAciklama == null || yeniAciklama == gonderi.aciklama) return;
      try {
        await firestore.gonderiGuncelle(gonderiId: gonderi.id, aciklama: yeniAciklama);
        onGuncellendi?.call(yeniAciklama);
        messenger.showSnackBar(const SnackBar(content: Text("Gönderi güncellendi.")));
      } catch (e) {
        messenger.showSnackBar(const SnackBar(content: Text("Gönderi güncellenemedi.")));
      }
      break;
    case 'sil':
      final bool onay = await _onayDialog(context, "Gönderiyi Sil", "Bu paylaşımı kalıcı olarak silmek istediğine emin misin?", "Sil");
      if (!onay) return;
      try {
        await firestore.gonderiSil(gonderiId: gonderi.id, kullaniciId: gonderi.kullaniciId);
        onSilindi?.call();
        messenger.showSnackBar(const SnackBar(content: Text("Gönderi silindi.")));
      } catch (e) {
        messenger.showSnackBar(const SnackBar(content: Text("Gönderi silinemedi.")));
      }
      break;
    case 'sikayet':
      if (aktifId == null) return;
      final String? sebep = await _sikayetSebebiSec(context);
      if (sebep == null) return;
      try {
        await firestore.gonderiSikayetEt(gonderiId: gonderi.id, sikayetEdenId: aktifId, sebep: sebep);
        messenger.showSnackBar(const SnackBar(content: Text("Şikayetin alındı. Teşekkürler!")));
      } catch (e) {
        messenger.showSnackBar(const SnackBar(content: Text("Şikayet gönderilemedi.")));
      }
      break;
    case 'engelle':
      if (aktifId == null) return;
      final String ad = gonderi.yayinlayanKullanici?.kullaniciAdi ?? "Bu kullanıcı";
      final bool onay = await _onayDialog(context, "Kullanıcıyı Engelle",
          "$ad engellensin mi? Gönderileri artık akışında görünmeyecek ve takibi bırakılacak.", "Engelle");
      if (!onay) return;
      try {
        await firestore.kullaniciEngelle(aktifKullaniciId: aktifId, hedefKullaniciId: gonderi.kullaniciId);
        onEngellendi?.call();
        messenger.showSnackBar(SnackBar(content: Text("$ad engellendi.")));
      } catch (e) {
        messenger.showSnackBar(const SnackBar(content: Text("Kullanıcı engellenemedi.")));
      }
      break;
    case 'paylas':
      await gonderiyiPaylas(gonderi);
      break;
  }
}

Future<void> gonderiyiPaylas(Gonderi gonderi) async {
  final buffer = StringBuffer("Pathbook'ta harika bir keşif!\n");
  final String? ad = gonderi.yayinlayanKullanici?.kullaniciAdi;
  if (ad != null && ad.isNotEmpty) buffer.write("$ad paylaştı: ");
  if (gonderi.aciklama.isNotEmpty) {
    buffer.writeln("\"${gonderi.aciklama.length > 80 ? "${gonderi.aciklama.substring(0, 80)}..." : gonderi.aciklama}\"");
  }
  final konum = [gonderi.konum, gonderi.sehir, gonderi.ulke].where((e) => e != null && e.trim().isNotEmpty).toSet().join(", ");
  if (konum.isNotEmpty) buffer.writeln("📍 $konum");
  buffer.write("\n#Pathbook");
  await Share.share(buffer.toString(), subject: "Pathbook'tan Bir Keşif!");
}

Widget _secenek(BuildContext context, String deger, IconData ikon, String baslik, {Color renk = Colors.white}) {
  return ListTile(
    leading: Icon(ikon, color: renk),
    title: Text(baslik, style: TextStyle(color: renk, fontSize: 16)),
    onTap: () => Navigator.pop(context, deger),
  );
}

Future<bool> _onayDialog(BuildContext context, String baslik, String mesaj, String onayMetni) async {
  final bool? sonuc = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      title: Text(baslik),
      content: Text(mesaj, style: TextStyle(color: Colors.grey[300])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text("Vazgeç", style: TextStyle(color: Colors.grey[400]))),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(onayMetni, style: const TextStyle(color: Colors.redAccent))),
      ],
    ),
  );
  return sonuc ?? false;
}

Future<String?> _aciklamaDuzenleDialog(BuildContext context, String mevcut) {
  final controller = TextEditingController(text: mevcut);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      title: const Text("Açıklamayı Düzenle"),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: "Açıklama yaz..."),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text("Vazgeç", style: TextStyle(color: Colors.grey[400]))),
        TextButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text("Kaydet")),
      ],
    ),
  );
}

Future<String?> _sikayetSebebiSec(BuildContext context) {
  const sebepler = ["Uygunsuz içerik", "Spam veya yanıltıcı", "Şiddet veya nefret söylemi", "Telif hakkı ihlali", "Diğer"];
  return showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      title: const Text("Neden şikayet ediyorsun?"),
      children: sebepler
          .map((s) => SimpleDialogOption(
                onPressed: () => Navigator.pop(c, s),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(s, style: const TextStyle(fontSize: 15))),
              ))
          .toList(),
    ),
  );
}
