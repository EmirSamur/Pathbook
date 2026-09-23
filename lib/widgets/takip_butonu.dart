// lib/widgets/takip_butonu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:pathbooks/servisler/yetkilendirmeservisi.dart';

/// "Takip Et" / "Takiptesin" butonu. Durumu kendisi yükler.
class TakipButonu extends StatefulWidget {
  final String hedefKullaniciId;
  final bool genis;
  /// Takip durumu değiştiğinde (true: takip edildi) çağrılır.
  final ValueChanged<bool>? onDegisti;

  const TakipButonu({super.key, required this.hedefKullaniciId, this.genis = false, this.onDegisti});

  @override
  State<TakipButonu> createState() => _TakipButonuState();
}

class _TakipButonuState extends State<TakipButonu> {
  late final FirestoreServisi _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);
  late final String? _aktifId = Provider.of<YetkilendirmeServisi>(context, listen: false).aktifKullaniciId;
  bool? _takipEdiyor;
  bool _isleniyor = false;

  @override
  void initState() {
    super.initState();
    _durumuYukle();
  }

  @override
  void didUpdateWidget(covariant TakipButonu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hedefKullaniciId != widget.hedefKullaniciId) _durumuYukle();
  }

  Future<void> _durumuYukle() async {
    if (_aktifId == null) return;
    final bool durum = await _firestoreServisi.takipEdiyorMu(aktifKullaniciId: _aktifId, hedefKullaniciId: widget.hedefKullaniciId);
    if (mounted) setState(() => _takipEdiyor = durum);
  }

  Future<void> _degistir() async {
    if (_aktifId == null || _takipEdiyor == null || _isleniyor) return;
    final bool yeniDurum = !_takipEdiyor!;
    setState(() {
      _isleniyor = true;
      _takipEdiyor = yeniDurum;
    });
    try {
      if (yeniDurum) {
        await _firestoreServisi.takipEt(aktifKullaniciId: _aktifId, hedefKullaniciId: widget.hedefKullaniciId);
      } else {
        await _firestoreServisi.takibiBirak(aktifKullaniciId: _aktifId, hedefKullaniciId: widget.hedefKullaniciId);
      }
      widget.onDegisti?.call(yeniDurum);
    } catch (e) {
      if (mounted) {
        setState(() => _takipEdiyor = !yeniDurum);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem gerçekleştirilemedi. Lütfen tekrar dene.")));
      }
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_aktifId == null || _aktifId == widget.hedefKullaniciId) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final bool takipte = _takipEdiyor ?? false;
    final Widget icerik = _takipEdiyor == null
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.8))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(takipte ? Icons.check_rounded : Icons.person_add_alt_1_rounded, size: 16),
            const SizedBox(width: 6),
            Text(takipte ? "Takiptesin" : "Takip Et", style: const TextStyle(fontSize: 14)),
          ]);

    return SizedBox(
      width: widget.genis ? double.infinity : null,
      height: widget.genis ? 38 : 32,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: takipte
            ? OutlinedButton(
                key: const ValueKey('takipte'),
                onPressed: _degistir,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[700]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: icerik,
              )
            : ElevatedButton(
                key: const ValueKey('takipEt'),
                onPressed: _degistir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: icerik,
              ),
      ),
    );
  }
}
