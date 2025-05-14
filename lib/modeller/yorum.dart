// pathbooks/modeller/yorum.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Yorumu yapan kullanıcı bilgisi için

class Yorum {
  final String id; // Firestore'daki yorum döküman ID'si
  final String yorumMetni;
  final String kullaniciId; // Yorumu yapan kullanıcının ID'si
  final String gonderiId;   // Yorumun ait olduğu gönderinin ID'si
  final Timestamp olusturulmaZamani;

  // Opsiyonel: Yorumu yapan kullanıcının bilgilerini de burada tutabiliriz
  final Kullanici? yorumuYapanKullanici;

  Yorum({
    required this.id,
    required this.yorumMetni,
    required this.kullaniciId,
    required this.gonderiId,
    required this.olusturulmaZamani,
    this.yorumuYapanKullanici,
  });

  factory Yorum.dokumandanUret(DocumentSnapshot<Map<String, dynamic>> doc, {Kullanici? yapanKullanici}) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Yorum doküman verisi bulunamadı: ${doc.id}");
    }

    return Yorum(
      id: doc.id,
      yorumMetni: data['yorumMetni'] as String? ?? '',
      kullaniciId: data['kullaniciId'] as String? ?? '',
      gonderiId: data['gonderiId'] as String? ?? '', // Firestore'da bu alan olmayabilir, yorumlar gönderi altında olabilir
      olusturulmaZamani: data['olusturulmaZamani'] as Timestamp? ?? Timestamp.now(),
      yorumuYapanKullanici: yapanKullanici,
    );
  }
}