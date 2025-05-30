// lib/sayfalar/duyurular_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/oneri_modeli.dart'; // OneriModeli'ni import et
// import 'package:share_plus/share_plus.dart'; // Paylaşım için (pubspec.yaml'a eklemeyi unutmayın)

class DuyurularSayfasi extends StatelessWidget {
  final OneriModeli secilenOneri;

  const DuyurularSayfasi({
    Key? key,
    required this.secilenOneri,
  }) : super(key: key);

  // Paylaşım fonksiyonu (isterseniz ayrı bir service dosyasına taşıyabilirsiniz)
  Future<void> _paylasOneri(BuildContext context) async {
    final String paylasimMetni =
        "${secilenOneri.yerAdi}\n\n${secilenOneri.ipucuMetni}\n\nPathBooks ile keşfet!";
    // Eğer görsel URL'si varsa ve paylaşmak isterseniz, share_plus bunu destekleyebilir
    // ancak dosya olarak paylaşım daha karmaşık olabilir. Şimdilik metin odaklı.
    // await Share.share(paylasimMetni, subject: secilenOneri.yerAdi);

    // Basit bir SnackBar ile simüle edelim:
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("'${secilenOneri.yerAdi}' paylaşılıyor... (Özellik yakında!)"),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
    print("Paylaşılacak metin: $paylasimMetni");
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    // Hero animasyonu için benzersiz bir tag. Modelinizde id varsa onu kullanın.
    // Yoksa yerAdi da geçici bir çözüm olabilir.
    final String heroTagImage = 'oneri-gorsel-${secilenOneri.yerAdi}-${secilenOneri.gorselUrl ?? ""}';
    final String heroTagTitle = 'oneri-baslik-${secilenOneri.yerAdi}';

    return Scaffold(
      appBar: AppBar(
        title: Hero( // AppBar başlığına da Hero ekleyebiliriz
          tag: heroTagTitle,
          // Hero widget'ı doğrudan Text stillerini etkilemez, bu yüzden Material widget'ı ile sarmalamak gerekebilir
          // veya Text'in stilini AppBar'ın varsayılanına bırakmak daha iyi olabilir.
          // Şimdilik basit tutalım ve AppBar'ın kendi stil yönetimini kullanalım.
          // Material'a sarmak gerekirse:
          // child: Material(
          //   color: Colors.transparent, // Arka planı şeffaf yap
          //   child: Text(secilenOneri.yerAdi, style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
          // ),
          child: Text(
            secilenOneri.yerAdi,
            style: TextStyle(fontSize: 18, color: colorScheme.onPrimary),
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 2, // Hafif bir gölge
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (secilenOneri.gorselUrl != null && secilenOneri.gorselUrl!.isNotEmpty)
              Hero(
                tag: heroTagImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    secilenOneri.gorselUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: colorScheme.errorContainer,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined, // Daha belirgin bir ikon
                            size: 60,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (secilenOneri.gorselUrl != null && secilenOneri.gorselUrl!.isNotEmpty)
              const SizedBox(height: 24),

            // İçeriği bir Card içinde sunabiliriz
            Card(
              elevation: 2.0, // Hafif bir gölge
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              color: colorScheme.surfaceVariant, // Kart arka planı
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      secilenOneri.yerAdi,
                      style: textTheme.headlineMedium?.copyWith( // Biraz daha büyük bir başlık
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant, // Kart üzerindeki metin rengi
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      color: colorScheme.outline.withOpacity(0.5),
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),
                    Row( // İpucu ikonu ve metni
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: colorScheme.secondary, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            secilenOneri.ipucuMetni,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.6, // Satır yüksekliğini biraz artırabiliriz
                              color: colorScheme.onSurfaceVariant.withOpacity(0.85), // Hafif soluk
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ek Bilgiler Bölümü (Örnek)
            // if (secilenOneri.kategori != null || secilenOneri.tarih != null) ...[
            //   Text(
            //     "Ek Bilgiler",
            //     style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            //   ),
            //   const SizedBox(height: 8),
            //   if (secilenOneri.kategori != null)
            //     Chip(
            //       avatar: Icon(Icons.category_outlined, color: colorScheme.onSecondaryContainer),
            //       label: Text(secilenOneri.kategori!),
            //       backgroundColor: colorScheme.secondaryContainer,
            //       labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSecondaryContainer),
            //     ),
            //   // Diğer ek bilgiler...
            //   const SizedBox(height: 24),
            // ],


            // Eylem Butonları
            Wrap( // Butonlar sığmazsa alt satıra geçsin
              spacing: 12.0, // Yatay boşluk
              runSpacing: 8.0, // Dikey boşluk (alt satıra geçerse)
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.search_outlined),
                  label: Text("${secilenOneri.yerAdi} için Ara"),
                  onPressed: () {
                    print("${secilenOneri.yerAdi} için arama yapılacak.");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${secilenOneri.yerAdi} için arama özelliği yakında!",
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface),
                        ),
                        backgroundColor: colorScheme.inverseSurface, // SnackBar için farklı bir renk
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        margin: EdgeInsets.all(10),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0), // Daha yuvarlak buton
                    ),
                  ),
                ),
                OutlinedButton.icon( // Paylaş butonu için OutlinedButton
                  icon: Icon(Icons.share_outlined, color: colorScheme.secondary),
                  label: Text("Paylaş", style: TextStyle(color: colorScheme.secondary)),
                  onPressed: () => _paylasOneri(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.secondary, width: 1.5),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Alt boşluk
          ],
        ),
      ),
    );
  }
}