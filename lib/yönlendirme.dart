// yönlendirme.dart (Provider ile Düzenlenmiş Hali)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider paketini import et
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelini import et
import 'package:pathbooks/sayfalar/anasayfa.dart';    // Anasayfa widget'ını import et
import 'package:pathbooks/sayfalar/girissayfasi.dart'; // Girissayfasi widget'ını import et
// import 'package:pathbooks/servisler/yetkilendirmeservisi.dart'; // <- Provider kullanıldığı için burada servise direkt erişime gerek yok

class Yonlendirme extends StatelessWidget {
  // State almadığı için const constructor kullanabiliriz.
  const Yonlendirme({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Provider'dan Kullanıcı Durumunu Dinle ---
    // StreamProvider<Kullanici?> tarafından sağlanan en son Kullanici? değerini alır.
    // `watch` kullanıldığı için, bu değer her değiştiğinde (giriş/çıkış/kayıt)
    // bu build metodu otomatik olarak tekrar çalışır.
    final Kullanici? aktifKullanici = context.watch<Kullanici?>();

    // Konsola log ekleyerek state değişikliğini takip edelim (Debug amaçlı)
    print("--- Yonlendirme Build --- Kullanıcı ID: ${aktifKullanici?.id ?? 'Giriş Yapılmamış'}");

    // Kullanıcı state'ine göre hangi sayfayı göstereceğimize karar verelim
    if (aktifKullanici == null) {
      // Eğer aktif kullanıcı yoksa (null ise), Giriş Sayfasını göster.
      // Bu, uygulamanın ilk açılış durumu veya çıkış yapıldıktan sonraki durumdur.
      return const Girissayfasi();
    } else {
      // Eğer aktif kullanıcı varsa (null değilse), Ana Sayfayı göster.
      // ÖNEMLİ: Anasayfa widget'ının constructor'ında 'aktifKullanici'
      // parametresini aldığından emin olun.
      return Anasayfa(aktifKullanici: aktifKullanici);
    }

    // Not: StreamProvider'ın initialData'sı sayesinde genellikle ayrı bir
    // yüklenme (loading) durumu göstermeye gerek kalmaz, ancak isterseniz
    // daha karmaşık bir state (örn. enum veya sealed class) kullanarak
    // 'bekleniyor', 'giriş yapılmış', 'giriş yapılmamış', 'hata' gibi
    // durumları yönetebilirsiniz. Şimdilik null kontrolü yeterlidir.
  }
}