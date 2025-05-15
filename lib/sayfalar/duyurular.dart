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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(secilenOneri.yerAdi, style: TextStyle(fontSize: 18)),
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
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600])),
                    );
                  },
                ),
              ),
            if (secilenOneri.gorselUrl != null && secilenOneri.gorselUrl!.isNotEmpty)
              const SizedBox(height: 20),

            Text(
              secilenOneri.yerAdi,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              secilenOneri.ipucuMetni,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.explore_outlined),
              label: Text("${secilenOneri.yerAdi} ile ilgili gönderileri ara"),
              onPressed: () {
                print("${secilenOneri.yerAdi} için arama yapılacak.");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${secilenOneri.yerAdi} için arama özelliği yakında!")),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 45),
              ),
            )
          ],
        ),
      ),
    );
  }
}