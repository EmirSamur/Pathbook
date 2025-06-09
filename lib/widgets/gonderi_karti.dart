// lib/widgets/content_card.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pathbooks/modeller/kullanici.dart'; // Kullanici modelinin isVerified içerdiğinden emin ol
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';
import 'package:share_plus/share_plus.dart';

class ContentCard extends StatefulWidget {
  final String gonderiId;
  final List<String> resimUrls;
  final String profileUrl; // Yayınlayanın profil resmi URL'si
  final String userName;   // Yayınlayanın kullanıcı adı
  final String? location; // Genel konum etiketi (örn: "Eiffel Kulesi")
  final String? ulke;     // Gönderinin ülkesi
  final String? sehir;    // Gönderinin şehri
  final String? description;
  final String? category; // Gönderinin kategorisi
  final int initialLikeCount;
  final int initialCommentCount;
  final String aktifKullaniciId; // O anki oturum açmış kullanıcının ID'si
  final Kullanici? yayinlayanKullanici; // Gönderiyi yayınlayan Kullanici nesnesi (isVerified için)

  final VoidCallback? onProfileTap;
  final VoidCallback? onMoreTap;
  final Function(String gonderiId)? onCommentTap;
  final VoidCallback? onDetailsTap;

  const ContentCard({
    Key? key,
    required this.gonderiId,
    required this.resimUrls,
    required this.profileUrl,
    required this.userName,
    this.location,
    this.ulke,
    this.sehir,
    this.description,
    this.category,
    required this.initialLikeCount,
    required this.initialCommentCount,
    required this.aktifKullaniciId,
    this.yayinlayanKullanici, // Bu parametre, mavi tik için gerekli
    this.onProfileTap,
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

  // Stil sabitleri
  static const double _avatarRadius = 18.0;
  static const double _headerFontSize = 13.8;
  static const double _verifiedIconSize = 15.0; // Mavi tik ikon boyutu
  static const double _actionIconSize = 22.0;
  static const double _likeCommentFontSize = 12.8;
  static const double _descriptionFontSize = 13.2;
  static const double _metaIconSize = 13.0;
  static const double _metaFontSize = 11.0;
  static final Color _metaDefaultColor = Colors.grey[600]!;
  static final Color _metaHighlightColor = Colors.redAccent[200]!; // Kategori için vurgu rengi

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
    if (!mounted || widget.gonderiId.isEmpty || widget.aktifKullaniciId.isEmpty) {
      if (mounted) setState(() => _isLiked = false); return;
    }
    try {
      bool liked = await _firestoreServisi.kullaniciGonderiyiBegendiMi(gonderiId: widget.gonderiId, aktifKullaniciId: widget.aktifKullaniciId);
      if (mounted) setState(() => _isLiked = liked);
    } catch (e) { if (mounted) setState(() => _isLiked = false); }
  }

  Future<void> _toggleLike() async {
    if (widget.aktifKullaniciId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beğenmek için giriş yapmalısınız."))); return;
    }
    if (_isLiking || !mounted) return;
    setState(() { _isLiking = true; _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
    try {
      await _firestoreServisi.gonderiBegenToggle(gonderiId: widget.gonderiId, aktifKullaniciId: widget.aktifKullaniciId);
    } catch (e) {
      if (mounted) { setState(() { _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beğeni işlemi sırasında bir hata oluştu.")));}
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _checkIfBookmarked() async {
    if (!mounted || widget.gonderiId.isEmpty || widget.aktifKullaniciId.isEmpty) {
      if (mounted) setState(() => _isBookmarked = false); return;
    }
    // TODO: Firestore'dan kaydetme durumunu çek
    if (mounted) setState(() => _isBookmarked = false);
  }

  Future<void> _toggleBookmark() async {
    if (widget.aktifKullaniciId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydetmek için giriş yapmalısınız."))); return;
    }
    if (_isBookmarking || !mounted) return;
    final bool newBookmarkState = !_isBookmarked;
    setState(() { _isBookmarking = true; _isBookmarked = newBookmarkState; });
    try {
      // TODO: Firestore'a kaydetme/kaldırma işlemi
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newBookmarkState ? "Kaydedildi." : "Kayıt kaldırıldı."), duration: const Duration(seconds: 1)));
    } catch (e) {
      if (mounted) { setState(() => _isBookmarked = !newBookmarkState);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydetme işlemi hatası.")));}
    } finally {
      if (mounted) setState(() => _isBookmarking = false);
    }
  }

  Future<void> _handleShare() async {
    String shareText = "Pathbook'ta harika bir keşif!\n";
    if (widget.userName.isNotEmpty) shareText += "${widget.userName} paylaştı: ";
    if (widget.description != null && widget.description!.isNotEmpty) shareText += "\"${widget.description!.length > 70 ? widget.description!.substring(0, 70) + "..." : widget.description!}\"\n";
    String locationInfo = "";
    if (widget.sehir != null && widget.sehir!.isNotEmpty) locationInfo += widget.sehir!;
    if (widget.ulke != null && widget.ulke!.isNotEmpty) {
      if (locationInfo.isNotEmpty) locationInfo += ", ";
      locationInfo += widget.ulke!;
    }
    if (widget.location != null && widget.location!.isNotEmpty && !locationInfo.toLowerCase().contains(widget.location!.toLowerCase())) {
      if(locationInfo.isNotEmpty) locationInfo = "${widget.location}, $locationInfo"; else locationInfo = widget.location!;
    }
    if (locationInfo.isNotEmpty) shareText += "📍 $locationInfo\n";
    else if (widget.category != null && widget.category!.isNotEmpty) shareText += "Kategori: ${widget.category}\n";
    shareText += "\n#PathbookApp https://pathbook.app/post/${widget.gonderiId}";
    try {
      await Share.share(shareText, subject: "Pathbook'tan Bir Keşif!");
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İçerik paylaşılamadı.'))); }
  }

  Widget _buildCardHeader(ThemeData theme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 8.0, 6.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        GestureDetector(onTap: widget.onProfileTap, child: CircleAvatar(radius: _avatarRadius, backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3), backgroundImage: widget.profileUrl.isNotEmpty ? NetworkImage(widget.profileUrl) : null, child: widget.profileUrl.isEmpty ? Icon(Icons.person_rounded, size: _avatarRadius, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)) : null)),
        const SizedBox(width: 10),
        Expanded(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(widget.userName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: _headerFontSize, letterSpacing: 0.15), overflow: TextOverflow.ellipsis)),
          if (widget.yayinlayanKullanici?.isVerified == true) // MAVİ TİK KONTROLÜ
            Padding(padding: const EdgeInsets.only(left: 5.0), child: Icon(Icons.verified_user_rounded, color: Colors.redAccent[200], size: _headerFontSize)), // MAVİ TİK
        ])),
        if (widget.onMoreTap != null) Material(color: Colors.transparent, child: InkWell(onTap: widget.onMoreTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(6.0), child: Icon(Icons.more_horiz_rounded, color: theme.iconTheme.color?.withOpacity(0.7), size: 22)))),
      ]),
    );
  }

  Widget _buildActionToolbar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0.0),
      child: Row(children: <Widget>[
        _buildInteractiveButton(icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isLiked ? Colors.redAccent[100] : theme.iconTheme.color?.withOpacity(0.8), onPressed: _isLiking ? null : _toggleLike, tooltip: "Beğen"),
        _buildInteractiveButton(icon: Icons.mode_comment_outlined, onPressed: () => widget.onCommentTap?.call(widget.gonderiId), tooltip: "Yorum Yap"),
        _buildInteractiveButton(icon: Icons.send_outlined, onPressed: _handleShare, tooltip: "Paylaş"),
        const Spacer(),
        _buildInteractiveButton(icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _isBookmarked ? theme.colorScheme.primary : theme.iconTheme.color?.withOpacity(0.8), onPressed: _isBookmarking ? null : _toggleBookmark, tooltip: _isBookmarked ? "Kaydedilenlerden Çıkar" : "Kaydet"),
      ]),
    );
  }

  Widget _buildInteractiveButton({required IconData icon, Color? color, VoidCallback? onPressed, String? tooltip}) {
    final theme = Theme.of(context);
    return IconButton(icon: Icon(icon, size: _actionIconSize), color: color ?? theme.iconTheme.color?.withOpacity(0.75), onPressed: onPressed, splashRadius: _actionIconSize + 6, padding: const EdgeInsets.all(9.0), constraints: const BoxConstraints(), visualDensity: VisualDensity.compact, tooltip: tooltip);
  }

  Widget _buildMetaChip({required IconData icon, required String label, required ThemeData theme, Color? chipColor, VoidCallback? onTap}) {
    if (label.isEmpty) return SizedBox.shrink(); // Etiket boşsa gösterme
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0), // Padding ayarlandı
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: _metaIconSize - 2, color: chipColor ?? theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
          const SizedBox(width: 3.5),
          Flexible(child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: _metaFontSize - 1, fontWeight: FontWeight.w500, color: chipColor ?? theme.textTheme.bodySmall?.color?.withOpacity(0.85)), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildMetaSection(ThemeData theme, TextTheme textTheme) {
    bool hasCategory = widget.category != null && widget.category!.isNotEmpty;
    bool hasUlke = widget.ulke != null && widget.ulke!.isNotEmpty;
    bool hasSehir = widget.sehir != null && widget.sehir!.isNotEmpty;
    bool hasLocationTag = widget.location != null && widget.location!.isNotEmpty;

    // Eğer hiçbir meta bilgi yoksa, sadece beğeni/yorum ve açıklama varsa bile az boşluk bırak
    bool hasAnyMetaTag = hasCategory || hasUlke || hasSehir || hasLocationTag;
    if (!hasAnyMetaTag && _likeCount == 0 && widget.initialCommentCount == 0 && (widget.description == null || widget.description!.isEmpty)) {
      return const SizedBox(height: 4.0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 6.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_likeCount > 0)
          Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text("$_likeCount beğeni", style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: _likeCommentFontSize, color: textTheme.bodyLarge?.color?.withOpacity(0.95)))),
        if (widget.description != null && widget.description!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: (widget.initialCommentCount > 0 || hasAnyMetaTag) ? 5.0 : 2.0),
            child: RichText(
                text: TextSpan(style: textTheme.bodyMedium?.copyWith(fontSize: _descriptionFontSize, color: theme.textTheme.bodyMedium?.color, height: 1.4),
                    children: [
                      TextSpan(text: "${widget.userName} ", style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: _descriptionFontSize, color: textTheme.bodyLarge?.color), recognizer: TapGestureRecognizer()..onTap = widget.onProfileTap),
                      TextSpan(text: _showFullDescription || widget.description!.length <= 75 ? widget.description! : widget.description!.substring(0, 75), style: textTheme.bodyMedium?.copyWith(fontSize: _descriptionFontSize, color: textTheme.bodyMedium?.color?.withOpacity(0.9))),
                      if (!_showFullDescription && widget.description!.length > 75)
                        TextSpan(text: " ...devamı", style: textTheme.bodySmall?.copyWith(color: Colors.grey[550], fontWeight: FontWeight.normal, fontSize: _descriptionFontSize - 1.5), recognizer: TapGestureRecognizer()..onTap = () { if(mounted) setState(() => _showFullDescription = true); })
                    ]
                ), maxLines: _showFullDescription ? null : 2, overflow: TextOverflow.ellipsis
            ),
          ),
        if (widget.initialCommentCount > 0)
          Padding(
            padding: EdgeInsets.only(bottom: hasAnyMetaTag ? 5.0 : 2.0),
            child: InkWell(onTap: () => widget.onCommentTap?.call(widget.gonderiId), child: Text(widget.initialCommentCount == 1 ? "1 yorumu görüntüle" : "${widget.initialCommentCount} yorumun tümünü görüntüle", style: textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: _likeCommentFontSize - 1.2))),
          ),
        if (hasAnyMetaTag)
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Wrap(
              spacing: 7.0, runSpacing: 1.0, // runSpacing azaltıldı
              alignment: WrapAlignment.start,
              children: [
                if (hasCategory) _buildMetaChip(icon: _getCategoryIcon(widget.category!), label: widget.category!, theme: theme, chipColor: _metaHighlightColor, onTap: () { print("Kategori: ${widget.category}"); /* TODO */ }),
                if (hasUlke) _buildMetaChip(icon: Icons.public_rounded, label: widget.ulke!, theme: theme, onTap: () { print("Ülke: ${widget.ulke}"); /* TODO */ }),
                if (hasSehir) _buildMetaChip(icon: Icons.location_city_rounded, label: widget.sehir!, theme: theme, onTap: () { print("Şehir: ${widget.sehir}"); /* TODO */ }),
                // Genel Konum Etiketi (location): Sadece şehir ve ülke bilgilerinden farklıysa veya onlar yoksa göster.
                if (hasLocationTag &&
                    !(hasSehir && widget.location!.toLowerCase().contains(widget.sehir!.toLowerCase())) &&
                    !(hasUlke && widget.location!.toLowerCase().contains(widget.ulke!.toLowerCase())))
                  _buildMetaChip(icon: Icons.push_pin_outlined, label: widget.location!, theme: theme, onTap: () { print("Konum Etiketi: ${widget.location}"); /* TODO */ }),
              ],
            ),
          ),
      ]),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'doğa': return Icons.landscape_outlined;
      case 'tarih': return Icons.account_balance_outlined;
      case 'kültür': return Icons.palette_outlined;
      case 'yeme-içme': return Icons.restaurant_menu_outlined;
      default: return Icons.label_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    String? anaResimUrl = widget.resimUrls.isNotEmpty ? widget.resimUrls[0] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.canvasColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.18), width: 0.6)), // Border rengi ayarlandı
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildCardHeader(theme, textTheme),
          if (anaResimUrl != null)
            GestureDetector(
              onDoubleTap: _isLiking ? null : _toggleLike, onTap: widget.onDetailsTap,
              child: AspectRatio(aspectRatio: 1 / 1, child: Stack(fit: StackFit.expand, children: [
                Image.network(anaResimUrl, fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Container(color: theme.colorScheme.surfaceVariant.withOpacity(0.05), child: Center(child: CircularProgressIndicator(strokeWidth: 1.8, valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.6))))),
                  errorBuilder: (context, error, stackTrace) => Container(color: theme.colorScheme.surfaceVariant.withOpacity(0.1), child: Center(child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35), size: 35))),
                ),
                if (widget.resimUrls.length > 1)
                  Positioned(top: 8.0, right: 8.0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12.0)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.photo_library_outlined, color: Colors.white.withOpacity(0.85), size: 10), const SizedBox(width: 3), Text("${widget.resimUrls.length}", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))]))),
              ]),
              ),
            )
          else AspectRatio(aspectRatio: 1.7 / 1, child: Container(color: theme.colorScheme.surfaceVariant.withOpacity(0.05), child: Center(child: Icon(Icons.image_not_supported_outlined, size: 30, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3))))),
          _buildActionToolbar(theme),
          _buildMetaSection(theme, textTheme),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}