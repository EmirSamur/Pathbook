// lib/widgets/content_card.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';

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
  final VoidCallback? onShareTap;
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
    this.onShareTap,
    this.onMoreTap,
    this.onCommentTap,
    this.onDetailsTap,
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
  static const double _actionIconSize = 23.0; // Bir önceki 23'tü, 22'ye çekilebilir
  static const double _likeCountFontSize = 13.0;
  static const double _descriptionFontSize = 13.5;
  static const double _metaIconSize = 13.5; // Kırmızı meta ikonları için boyut
  static const double _metaFontSize = 11.0; // Kırmızı meta metinleri için boyut

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

    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await _firestoreServisi.gonderiBegenToggle(
        gonderiId: widget.gonderiId,
        aktifKullaniciId: widget.aktifKullaniciId,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beğeni işlemi sırasında bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _checkIfBookmarked() async {
    if (widget.gonderiId.isEmpty || widget.aktifKullaniciId.isEmpty || !mounted) {
      if (mounted) setState(() => _isBookmarked = false);
      return;
    }
    if (mounted) setState(() => _isBookmarked = false);
  }

  Future<void> _toggleBookmark() async {
    if (widget.aktifKullaniciId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydetmek için giriş yapmalısınız.")));
      return;
    }
    if (_isBookmarking || !mounted) return;

    setState(() {
      _isBookmarking = true;
      _isBookmarked = !_isBookmarked;
    });

    try {
      print("Bookmark toggled: $_isBookmarked for ${widget.gonderiId}");
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      if (mounted) {
        setState(() => _isBookmarked = !_isBookmarked);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydetme işlemi sırasında bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  Widget _buildCardHeader(ThemeData theme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Dikey padding azaltıldı
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
            child: Text( // Header'da sadece kullanıcı adı için Column'a gerek yok
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
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), // Dikey padding azaltıldı
      child: Row(
        children: <Widget>[
          _buildInteractiveButton(
            icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isLiked ? _highlightColor : theme.iconTheme.color,
            onPressed: _isLiking ? null : _toggleLike,
          ),
          _buildInteractiveButton(
            icon: Icons.maps_ugc_outlined,
            onPressed: () => widget.onCommentTap?.call(widget.gonderiId),
          ),
          _buildInteractiveButton(
            icon: Icons.near_me_outlined,
            onPressed: widget.onShareTap,
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
      splashRadius: _actionIconSize + 2, // Splash radius ayarlandı
      padding: const EdgeInsets.all(8.0), // Padding azaltıldı
      constraints: const BoxConstraints(),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }

  Widget _buildMetaSection(ThemeData theme) {
    final TextStyle metaTextStyle = TextStyle(
      fontSize: _metaFontSize,
      color: _highlightColor,
      fontWeight: FontWeight.w500,
    );

    bool hasLocation = widget.location.isNotEmpty;
    bool hasCategory = widget.category != null && widget.category!.isNotEmpty;

    if (!hasLocation && !hasCategory) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 6.0), // Dikey padding azaltıldı
      child: Row(
        children: [
          if (hasLocation)
            Flexible(
              child: InkWell(
                onTap: (){ /* TODO: Konuma tıklama işlevi */ },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: _metaIconSize, color: _highlightColor),
                    const SizedBox(width: 3),
                    Flexible(child: Text(widget.location, style: metaTextStyle, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
          if (hasLocation && hasCategory)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0), // Boşluk azaltıldı
              child: Text("•", style: TextStyle(color: Colors.grey[500], fontSize: _metaFontSize)),
            ),
          if (hasCategory)
            Flexible(
              child: InkWell(
                onTap: (){ /* TODO: Kategoriye tıklama işlevi */ },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getCategoryIcon(widget.category!), size: _metaIconSize, color: _highlightColor),
                    const SizedBox(width: 3),
                    Flexible(child: Text(widget.category!, style: metaTextStyle, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'doğa': return Icons.landscape_outlined;
      case 'tarih': return Icons.fort_outlined;
      case 'kültür': return Icons.attractions_outlined;
      case 'yeme-içme': return Icons.restaurant_menu_outlined;
      default: return Icons.local_offer_outlined;
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final bool hasDescription = widget.description != null && widget.description!.isNotEmpty;

    // Açıklama metnini ve "daha fazla" linkini oluşturma
    List<InlineSpan> descriptionSpans = [];
    if (hasDescription) {
      descriptionSpans.add(TextSpan(
        text: "${widget.userName} ",
        style: const TextStyle(fontWeight: FontWeight.bold),
        recognizer: TapGestureRecognizer()..onTap = widget.onProfileTap,
      ));

      if (_showFullDescription || widget.description!.length <= 80) { // Kırpma limiti ayarlandı
        descriptionSpans.add(TextSpan(text: widget.description!));
      } else {
        descriptionSpans.add(TextSpan(text: widget.description!.substring(0, 80)));
        descriptionSpans.add(
            TextSpan(
              text: " ...daha fazla",
              style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal),
              recognizer: TapGestureRecognizer()..onTap = () {
                if(mounted) setState(() => _showFullDescription = true);
              },
            )
        );
      }
    }


    String? anaResimUrl = widget.resimUrls.isNotEmpty ? widget.resimUrls[0] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0), // Dikey margin azaltıldı
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.15), width: 0.5), // Daha ince border
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.15), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ÖNEMLİ: Column'un minimum yer kaplamasını sağlar
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
                    Image.network( /* ... (önceki gibi) ... */
                      anaResimUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        child: Center(child: Icon(Icons.sentiment_very_dissatisfied_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), size: 40)),
                      ),
                    ),
                    if (widget.resimUrls.length > 1)
                      Positioned( /* ... (önceki gibi) ... */
                        bottom: 10.0,
                        right: 10.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.collections_rounded, color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.resimUrls.length}",
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            AspectRatio( /* ... (önceki gibi) ... */
              aspectRatio: 1.8 / 1,
              child: Container(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                child: Center(child: Icon(Icons.image_search_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35))),
              ),
            ),

          _buildActionToolbar(theme),

          if (_likeCount > 0)
            Padding( /* ... (önceki gibi, padding ayarlanabilir) ... */
              padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0.0),
              child: Text(
                "$_likeCount kişi beğendi",
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: _likeCountFontSize),
              ),
            ),

          if (hasDescription) // Sadece açıklama varsa bu bölümü göster
            Padding(
              padding: EdgeInsets.fromLTRB(12.0, _likeCount > 0 ? 2.0 : 6.0, 12.0, 2.0), // Üst padding ayarlandı
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodyMedium?.copyWith(fontSize: _descriptionFontSize, color: theme.textTheme.bodyMedium?.color, height: 1.4),
                  children: descriptionSpans,
                ),
                maxLines: _showFullDescription ? null : 2, // Eğer _showFullDescription true ise tüm satırları göster
                overflow: TextOverflow.ellipsis,
              ),
            ),

          if (_commentCount > 0)
            Padding( /* ... (önceki gibi, padding ayarlanabilir) ... */
              padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 4.0), // Dikey padding azaltıldı
              child: InkWell(
                onTap: () => widget.onCommentTap?.call(widget.gonderiId),
                child: Text(
                  _commentCount == 1 ? "1 yorumu görüntüle" : "$_commentCount yorumun tümünü görüntüle", // Metin güncellendi
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[550], fontSize: 12.0), // Renk ve boyut ayarlandı
                ),
              ),
            ),

          _buildMetaSection(theme),

          const SizedBox(height: 8.0), // Kartın altına boşluk azaltıldı
        ],
      ),
    );
  }
}