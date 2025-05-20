// lib/sayfalar/duyurular_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/oneri_modeli.dart'; // OneriModeli'ni import et

class DuyurularSayfasi extends StatelessWidget {
  final OneriModeli secilenOneri;

  const DuyurularSayfasi({
    Key? key,
    required this.secilenOneri,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Temayı alıyoruz
    final ColorScheme colorScheme = theme.colorScheme; // Renk şemasını alıyoruz
    final TextTheme textTheme = theme.textTheme; // Metin stillerini alıyoruz

    return Scaffold(
      // AppBar'ın rengi ve metin stili varsayılan olarak temadan gelir.
      // Arka plan rengi colorScheme.primary (veya surface/background, temaya göre)
      // Başlık rengi colorScheme.onPrimary (veya onSurface/onBackground)
      appBar: AppBar(
        title: Text(
          secilenOneri.yerAdi,
          // İsterseniz AppBar başlığı için özel bir tema stili kullanabilirsiniz:
          // style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
          // Veya mevcut stiliniz iyiyse koruyabilirsiniz:
          style: TextStyle(fontSize: 18, color: colorScheme.onPrimary), // Veya sadece fontSize: 18
        ),
        backgroundColor: colorScheme.primary, // AppBar arka planını tema birincil rengi yapalım
        iconTheme: IconThemeData(color: colorScheme.onPrimary), // Geri butonu rengi
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (secilenOneri.gorselUrl != null && secilenOneri.gorselUrl!.isNotEmpty)
              ClipRRect(
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
                      // Arka planı biraz daha tematik yapabiliriz
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      child: Center(
                        child: CircularProgressIndicator(
                          // Yükleme göstergesinin rengini tema ikincil rengi yapalım
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      // Hata durumunda arka planı tema yüzey renginin bir varyantı yapalım
                      color: colorScheme.errorContainer, // veya colorScheme.surfaceVariant
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          // İkon rengini tema hata rengi üzerine uygun bir renk yapalım
                          color: colorScheme.onErrorContainer, // veya colorScheme.onSurfaceVariant
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (secilenOneri.gorselUrl != null && secilenOneri.gorselUrl!.isNotEmpty)
              const SizedBox(height: 20),

            Text(
              secilenOneri.yerAdi,
              // headlineSmall zaten iyi bir seçim, rengini tema birincil rengi yapmak güzel bir vurgu
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              secilenOneri.ipucuMetni,
              // bodyLarge iyi bir temel, rengi varsayılan olarak colorScheme.onSurface/onBackground olacaktır.
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16, // Bu özel ayar kalabilir
                height: 1.5,   // Bu özel ayar kalabilir
                color: colorScheme.onSurface, // Metin rengini açıkça belirtebiliriz
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.explore_outlined), // İkon rengi otomatik olarak foregroundColor'u alır
              label: Text("${secilenOneri.yerAdi} ile ilgili gönderileri ara"),
              onPressed: () {
                print("${secilenOneri.yerAdi} için arama yapılacak.");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${secilenOneri.yerAdi} için arama özelliği yakında!"),
                    // SnackBar'ın da tema renklerini kullanmasını sağlayabiliriz
                    backgroundColor: colorScheme.secondaryContainer,
                    behavior: SnackBarBehavior.floating,
                      //contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondaryContainer),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                // Butonun arka plan rengini tema birincil rengi yapalım
                backgroundColor: colorScheme.primary,
                // Butonun üzerindeki metin ve ikon rengini tema birincil rengi üzerine uygun renk yapalım
                foregroundColor: colorScheme.onPrimary,
                minimumSize: Size(double.infinity, 45),
                textStyle: textTheme.labelLarge, // Buton metni için tema stilini kullanalım
                shape: RoundedRectangleBorder( // Buton kenarlarını biraz yuvarlayalım
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}