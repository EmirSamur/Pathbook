// lib/widgets/content_card.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/kullanici.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:share_plus/share_plus.dart'; // <<<--- YENİ IMPORT

class ContentCard extends StatefulWidget {
  final String gonderiId;
  final List<String> resimUrls;
  final String profileUrl;
  final String userName;
  final String location;
  final String? description;
  final String? category;
  final int initialLikeCount;
  final int initialCommentCount;
  final String aktifKullaniciId;

  final VoidCallback? onProfileTap;
  // final VoidCallback? onShareTap; // <<<--- BU PARAMETRE KALDIRILDI (veya opsiyonel bırakılabilir)
  final VoidCallback? onMoreTap;
  final Function(String gonderiId)? onCommentTap;
  final VoidCallback? onDetailsTap;

  const ContentCard({
    Key? key,
    required this.gonderiId,
    required this.resimUrls,
    required this.profileUrl,
    required this.userName,
    required this.location,
    this.description,
    this.category,
    required this.initialLikeCount,
    required this.initialCommentCount,
    required this.aktifKullaniciId,
    this.onProfileTap,
    // this.onShareTap, // Kaldırıldı
    this.onMoreTap,
    this.onCommentTap,
    this.onDetailsTap, Kullanici? yayinlayanKullanici,
  }) : super(key: key);

  @override
  _ContentCardState createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  late final FirestoreServisi _firestoreServisi = Provider.of<FirestoreServisi>(context, listen: false);

  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  bool _isBookmarked = false;
  bool _isLiking = false;
  bool _isBookmarking = false;
  bool _showFullDescription = false;

  static const double _avatarRadius = 18.0;
  static const double _headerFontSize = 14.0;
  static const double _actionIconSize = 23.0;
  static const double _likeCountFontSize = 13.0;
  static const double _descriptionFontSize = 13.5;
  static const double _metaIconSize = 13.5;
  static const double _metaFontSize = 11.0;
  static final Color _highlightColor = Colors.redAccent[200]!;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.initialLikeCount;
    _commentCount = widget.initialCommentCount;
    if (widget.aktifKullaniciId.isNotEmpty) {
      _checkIfLiked();
      _checkIfBookmarked();
    }
  }

  @override
  void didUpdateWidget(covariant ContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsRecheckLike = false;
    bool needsRecheckBookmark = false;

    if (widget.gonderiId != oldWidget.gonderiId) {
      _likeCount = widget.initialLikeCount;
      _commentCount = widget.initialCommentCount;
      _showFullDescription = false;
      needsRecheckLike = true;
      needsRecheckBookmark = true;
    } else {
      if (widget.initialLikeCount != _likeCount && mounted && !_isLiking) {
        setState(() => _likeCount = widget.initialLikeCount);
      }
      if (widget.initialCommentCount != _commentCount && mounted) {
        setState(() => _commentCount = widget.initialCommentCount);
      }
    }

    if (widget.aktifKullaniciId != oldWidget.aktifKullaniciId) {
      needsRecheckLike = true;
      needsRecheckBookmark = true;
    }

    if (needsRecheckLike) {
      if (widget.aktifKullaniciId.isNotEmpty) _checkIfLiked();
      else if (mounted) setState(() => _isLiked = false);
    }
    if (needsRecheckBookmark) {
      if (widget.aktifKullaniciId.isNotEmpty) _checkIfBookmarked();
      else if (mounted) setState(() => _isBookmarked = false);
    }
  }

  Future<void> _checkIfLiked() async {
    if (widget.gonderiId.isEmpty || widget.aktifKullaniciId.isEmpty || !mounted) {
      if (mounted) setState(() => _isLiked = false);
      return;
    }
    bool liked = await _firestoreServisi.kullaniciGonderiyiBegendiMi(
      gonderiId: widget.gonderiId,
      aktifKullaniciId: widget.aktifKullaniciId,
    );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (widget.aktifKullaniciId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beğenmek için giriş yapmalısınız.")));
      return;
    }
    if (_isLiking || !mounted) return;
    setState(() { _isLiking = true; _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
    try {
      await _firestoreServisi.gonderiBegenToggle(gonderiId: widget.gonderiId, aktifKullaniciId: widget.aktifKullaniciId);
    } catch (e) {
      if (mounted) { setState(() { _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beğeni işlemi sırasında bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _checkIfBookmarked() async {
    // TODO: Firestore'dan kaydetme durumunu çek
    if (widget.gonderiId.isEmpty || widget.aktifKullaniciId.isEmpty || !mounted) {
      if (mounted) setState(() => _isBookmarked = false);
      return;
    }
    // Örnek: bool bookmarked = await _firestoreServisi.isGonderiBookmarked(widget.gonderiId, widget.aktifKullaniciId);
    // if(mounted) setState(() => _isBookmarked = bookmarked);
    if (mounted) setState(() => _isBookmarked = false); // Şimdilik false
  }

  Future<void> _toggleBookmark() async {
    if (widget.aktifKullaniciId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydetmek için giriş yapmalısınız.")));
      return;
    }
    if (_isBookmarking || !mounted) return;
    setState(() { _isBookmarking = true; _isBookmarked = !_isBookmarked; });
    try {
      // TODO: Firestore'a kaydetme/kaldırma işlemini yap
      // await _firestoreServisi.toggleGonderiBookmark(widget.gonderiId, widget.aktifKullaniciId, _isBookmarked);
      print("Bookmark toggled: $_isBookmarked for ${widget.gonderiId}");
      await Future.delayed(const Duration(milliseconds: 300)); // Simülasyon
    } catch (e) {
      if (mounted) { setState(() => _isBookmarked = !_isBookmarked);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydetme işlemi sırasında bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  // <<<--- YENİ PAYLAŞMA METODU ---<<<
  Future<void> _handleShare() async {
    String shareText = "${widget.userName} Pathbook'ta harika bir yer paylaştı!\n";
    if (widget.location.isNotEmpty) {
      shareText += "Konum: ${widget.location}\n";
    }
    if (widget.description != null && widget.description!.isNotEmpty) {
      shareText += "\"${widget.description!.length > 80 ? widget.description!.substring(0, 80) + "..." : widget.description!}\"\n";
    }
    // TODO: Uygulamanızın linkini veya gönderiye özel bir deep link ekleyin.
    // Örnek: shareText += "\nDetaylar için: https://pathbook.app/post/${widget.gonderiId}";
    shareText += "\nPathbook'u indir ve sen de keşfet!";

    // İsteğe bağlı: Resmi de paylaşmak isterseniz (daha karmaşık)
    // List<XFile> filesToShare = [];
    // if (widget.resimUrls.isNotEmpty) {
    //   // Resmi indirip geçici dosyaya kaydetme ve XFile listesine ekleme mantığı buraya gelecek.
    //   // Örneğin: http ve path_provider paketleri kullanılabilir.
    // }

    try {
      // if (filesToShare.isNotEmpty) {
      //   await Share.shareXFiles(filesToShare, text: shareText, subject: "Pathbook'tan Bir Keşif!");
      // } else {
      await Share.share(shareText, subject: "Pathbook'tan Bir Keşif!");
      // }
    } catch (e) {
      print("ContentCard - Paylaşma hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İçerik paylaşılamadı.')),
        );
      }
    }
  }
  // <<<--- PAYLAŞMA METODU SONU ---<<<

  Widget _buildCardHeader(ThemeData theme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: widget.onProfileTap,
            child: CircleAvatar(
              radius: _avatarRadius,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              backgroundImage: widget.profileUrl.isNotEmpty ? NetworkImage(widget.profileUrl) : null,
              child: widget.profileUrl.isEmpty ? Icon(Icons.person_rounded, size: _avatarRadius, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.userName,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: _headerFontSize, letterSpacing: 0.2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.onMoreTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onMoreTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(Icons.more_horiz_rounded, color: theme.iconTheme.color?.withOpacity(0.65), size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        children: <Widget>[
          _buildInteractiveButton(
            icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isLiked ? _highlightColor : theme.iconTheme.color,
            onPressed: _isLiking ? null : _toggleLike,
          ),
          _buildInteractiveButton(
            icon: Icons.maps_ugc_outlined, // Yorum ikonu
            onPressed: () => widget.onCommentTap?.call(widget.gonderiId),
          ),
          _buildInteractiveButton(
            icon: Icons.share_outlined, // <<<--- PAYLAŞIM İKONU GÜNCELLENDİ
            onPressed: _handleShare,     // <<<--- YENİ METODU ÇAĞIRIYOR
          ),
          const Spacer(),
          _buildInteractiveButton(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            color: _isBookmarked ? theme.colorScheme.secondary : theme.iconTheme.color,
            onPressed: _isBookmarking ? null : _toggleBookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveButton({
    required IconData icon,
    Color? color,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: _actionIconSize),
      color: color ?? theme.iconTheme.color?.withOpacity(0.7),
      onPressed: onPressed,
      splashRadius: _actionIconSize + 2,
      padding: const EdgeInsets.all(8.0),
      constraints: const BoxConstraints(),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }

  Widget _buildMetaSection(ThemeData theme) {
    final TextStyle metaTextStyle = TextStyle(
      fontSize: _metaFontSize, // _metaFontSize = 11.0 olarak tanımlanmıştı
      color: _highlightColor,   // _highlightColor = Colors.redAccent[200]! olarak tanımlanmıştı
      fontWeight: FontWeight.w500,
    );

    bool hasLocation = widget.location.isNotEmpty;
    bool hasCategory = widget.category != null && widget.category!.isNotEmpty;

    // Eğer hem konum hem de kategori yoksa, boş bir widget döndürerek hiç yer kaplamamasını sağla
    if (!hasLocation && !hasCategory) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 6.0), // Dikey padding azaltılmıştı
      child: Row(
        children: [
          // Konum bilgisi varsa göster
          if (hasLocation)
            Flexible( // Uzun konum isimlerinin taşmasını engellemek için Flexible
              child: InkWell( // Konuma tıklanabilir yapmak için (ileride bir işlev eklenebilir)
                onTap: (){
                  print("Konuma tıklandı: ${widget.location}");
                  // TODO: Konuma tıklandığında harita açma veya filtreleme işlevi eklenebilir
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Row'un içeriği kadar yer kaplamasını sağlar
                  children: [
                    Icon(Icons.location_on, size: _metaIconSize, color: _highlightColor), // _metaIconSize = 13.5
                    const SizedBox(width: 3),
                    Flexible( // Metnin de taşmasını engelle
                      child: Text(
                        widget.location,
                        style: metaTextStyle,
                        overflow: TextOverflow.ellipsis, // Taşarsa "..." ile bitir
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Eğer hem konum hem de kategori varsa, aralarına bir ayırıcı (nokta) koy
          if (hasLocation && hasCategory)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0), // Boşluk azaltılmıştı
              child: Text(
                "•", // Ayırıcı karakter
                style: TextStyle(color: Colors.grey[500], fontSize: _metaFontSize), // Ayırıcı stili
              ),
            ),

          // Kategori bilgisi varsa göster
          if (hasCategory)
            Flexible( // Uzun kategori isimlerinin taşmasını engellemek için Flexible
              child: InkWell( // Kategoriye tıklanabilir yapmak için
                onTap: (){
                  print("Kategoriye tıklandı: ${widget.category}");
                  // TODO: Kategoriye tıklandığında o kategoriye göre filtreleme işlevi eklenebilir
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getCategoryIcon(widget.category!), size: _metaIconSize, color: _highlightColor),
                    const SizedBox(width: 3),
                    Flexible( // Metnin de taşmasını engelle
                      child: Text(
                        widget.category!,
                        style: metaTextStyle,
                        overflow: TextOverflow.ellipsis, // Taşarsa "..." ile bitir
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // _getCategoryIcon metodu da ContentCard içinde bulunmalı:
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'doğa': return Icons.landscape_outlined;
      case 'tarih': return Icons.fort_outlined; // veya Icons.account_balance_outlined
      case 'kültür': return Icons.attractions_outlined; // veya Icons.palette_outlined
      case 'yeme-içme': return Icons.restaurant_menu_outlined;
      default: return Icons.local_offer_outlined; // Varsayılan ikon
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final bool hasDescription = widget.description != null && widget.description!.isNotEmpty;

    List<InlineSpan> descriptionSpans = [];
    if (hasDescription) {
      descriptionSpans.add(TextSpan(
        text: "${widget.userName} ",
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // Renk eklendi
        recognizer: TapGestureRecognizer()..onTap = widget.onProfileTap,
      ));
      if (_showFullDescription || widget.description!.length <= 80) {
        descriptionSpans.add(TextSpan(text: widget.description!, style: TextStyle(color: Colors.grey[300]))); // Renk eklendi
      } else {
        descriptionSpans.add(TextSpan(text: widget.description!.substring(0, 80), style: TextStyle(color: Colors.grey[300])));
        descriptionSpans.add(
            TextSpan(
              text: " ...daha fazla",
              style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal),
              recognizer: TapGestureRecognizer()..onTap = () { if(mounted) setState(() => _showFullDescription = true); },
            )
        );
      }
    }

    String? anaResimUrl = widget.resimUrls.isNotEmpty ? widget.resimUrls[0] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: theme.cardColor, // Tema rengi kullanıldı
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.15), width: 0.5),
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildCardHeader(theme, textTheme),
          if (anaResimUrl != null)
            GestureDetector(
              onDoubleTap: _isLiking ? null : _toggleLike,
              onTap: widget.onDetailsTap,
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(anaResimUrl, fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: theme.colorScheme.surfaceVariant.withOpacity(0.1), child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)))));
                      },
                      errorBuilder: (context, error, stackTrace) => Container(color: theme.colorScheme.surfaceVariant.withOpacity(0.2), child: Center(child: Icon(Icons.sentiment_very_dissatisfied_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), size: 40))),
                    ),
                    if (widget.resimUrls.length > 1)
                      Positioned(bottom: 10.0, right: 10.0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(20.0)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.collections_rounded, color: Colors.white, size: 13), const SizedBox(width: 4), Text("${widget.resimUrls.length}", style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))]))),
                  ],
                ),
              ),
            )
          else
            AspectRatio(aspectRatio: 1.8 / 1, child: Container(color: theme.colorScheme.surfaceVariant.withOpacity(0.1), child: Center(child: Icon(Icons.image_search_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35))))),
          _buildActionToolbar(theme),
          if (_likeCount > 0)
            Padding(padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0.0), child: Text("$_likeCount kişi beğendi", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: _likeCountFontSize, color: textTheme.bodyMedium?.color?.withOpacity(0.9)))), // Renk opaklığı
          if (hasDescription)
            Padding(padding: EdgeInsets.fromLTRB(12.0, _likeCount > 0 ? 2.0 : 6.0, 12.0, 2.0), child: RichText(text: TextSpan(style: textTheme.bodyMedium?.copyWith(fontSize: _descriptionFontSize, color: theme.textTheme.bodyMedium?.color, height: 1.4), children: descriptionSpans), maxLines: _showFullDescription ? null : 2, overflow: TextOverflow.ellipsis)),
          if (_commentCount > 0)
            Padding(padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 4.0), child: InkWell(onTap: () => widget.onCommentTap?.call(widget.gonderiId), child: Text(_commentCount == 1 ? "1 yorumu görüntüle" : "$_commentCount yorumun tümünü görüntüle", style: textTheme.bodySmall?.copyWith(color: Colors.grey[550], fontSize: 12.0)))),
          _buildMetaSection(theme),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}