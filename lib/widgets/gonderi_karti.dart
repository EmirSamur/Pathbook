// lib/widgets/content_card.dart

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
  bool _isLiking = false;

  static const double _smallIconSize = 18.0;
  static const double _actionButtonIconSize = 20.0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.initialLikeCount;
    _commentCount = widget.initialCommentCount;
    if (widget.aktifKullaniciId.isNotEmpty) {
      _checkIfLiked();
    }
  }

  @override
  void didUpdateWidget(covariant ContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needsRecheck = false;
    if (widget.gonderiId != oldWidget.gonderiId) {
      _likeCount = widget.initialLikeCount;
      _commentCount = widget.initialCommentCount;
      needsRecheck = true;
    } else {
      if (widget.initialLikeCount != _likeCount && mounted) {
        setState(() => _likeCount = widget.initialLikeCount);
      }
      if (widget.initialCommentCount != _commentCount && mounted) {
        setState(() => _commentCount = widget.initialCommentCount);
      }
    }
    if (widget.aktifKullaniciId != oldWidget.aktifKullaniciId) {
      needsRecheck = true;
    }
    if (needsRecheck) {
      if (widget.aktifKullaniciId.isNotEmpty) {
        _checkIfLiked();
      } else {
        if (mounted) setState(() => _isLiked = false);
      }
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
    if (mounted) {
      setState(() { _isLiked = liked; });
    }
  }

  Future<void> _toggleLike() async {
    if (widget.aktifKullaniciId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Beğenmek için giriş yapmalısınız.")));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Beğeni işlemi sırasında bir hata oluştu.")));
      }
    } finally {
      if (mounted) {
        setState(() { _isLiking = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    String? anaResimUrl;
    if (widget.resimUrls.isNotEmpty) {
      anaResimUrl = widget.resimUrls[0];
    }

    final TextStyle? smallBodyStyle = textTheme.bodySmall?.copyWith(fontSize: 11.5);
    final TextStyle? verySmallLabelStyle = textTheme.labelSmall?.copyWith(fontSize: 10.5);

    return Padding(
      // Dış Padding: Kartlar arası dikey boşluk için. Alt boşluk azaltıldı.
      padding: EdgeInsets.only(top: 6.0, bottom: 4.0), // ESKİ: symmetric(vertical: 6.0)
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias,
        color: (theme.cardTheme.color ?? theme.cardColor).withOpacity(0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Kullanıcı Başlığı
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 6.0, 6.0),
              child: Row( /* ... (içerik aynı) ... */
                children: <Widget>[
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      backgroundImage: widget.profileUrl.isNotEmpty ? NetworkImage(widget.profileUrl) : null,
                      child: widget.profileUrl.isEmpty ? Icon(Icons.person, size: 20, color: theme.colorScheme.onSurfaceVariant) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.userName,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.7), size: 20),
                    onPressed: widget.onMoreTap ?? () {},
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: "Daha fazla seçenek",
                  ),
                ],
              ),
            ),

            // 2. Gönderi Görseli
            AspectRatio(
              aspectRatio: 1 / 1,
              child: anaResimUrl != null
                  ? GestureDetector( /* ... (içerik aynı) ... */
                onDoubleTap: _isLiking ? null : _toggleLike,
                onTap: widget.onDetailsTap,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.network(
                      anaResimUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: theme.colorScheme.surfaceVariant.withOpacity(0.2), child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)));
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                        child: Center(child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), size: 50)),
                      ),
                    ),
                    if (widget.resimUrls.length > 1)
                      Positioned(
                        top: 6.0,
                        right: 6.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            "${widget.resimUrls.length} resim",
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
              )
                  : Container(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                child: Center(child: Icon(Icons.image_not_supported_outlined, size: 45, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
              ),
            ),

            // 3. Konum ve Kategori
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 4.0),
              child: Wrap( /* ... (içerik aynı) ... */
                spacing: 6.0,
                runSpacing: 2.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.location.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: _smallIconSize - 2, color: theme.colorScheme.secondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            widget.location,
                            style: smallBodyStyle?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  if (widget.category != null && widget.category!.isNotEmpty)
                    Chip(
                      avatar: Icon(_getCategoryIcon(widget.category!), size: _smallIconSize - 4, color: theme.colorScheme.onSecondaryContainer.withOpacity(0.8)),
                      label: Text(widget.category!),
                      labelStyle: verySmallLabelStyle?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w500),
                      backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),

            // 4. Açıklama Kırpıntısı
            if (widget.description != null && widget.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 6.0),
                child: GestureDetector( /* ... (içerik aynı) ... */
                  onTap: widget.onDetailsTap,
                  child: RichText(
                    text: TextSpan(
                      style: smallBodyStyle,
                      children: <TextSpan>[
                        TextSpan(text: widget.description!.length > 65 ? widget.description!.substring(0, 65) : widget.description!),
                        if (widget.description!.length > 65)
                          TextSpan(text: "...", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            if ((widget.description != null && widget.description!.isNotEmpty))
              Divider(height: 0.5, thickness: 0.3, indent: 10, endIndent: 10, color: theme.dividerColor.withOpacity(0.5)),

            // 5. Etkileşim Butonları
            Padding(
              padding: const EdgeInsets.fromLTRB(2.0, 2.0, 2.0, 2.0), // Dikey padding çok az eklendi, simetri için
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _buildActionButton(
                    context: context,
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: _likeCount > 0 ? _likeCount.toString() : "Beğen",
                    color: _isLiked ? theme.colorScheme.error : theme.iconTheme.color,
                    onPressed: _isLiking ? null : _toggleLike,
                    textStyle: verySmallLabelStyle,
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: _commentCount > 0 ? _commentCount.toString() : "Yorum",
                    onPressed: () => widget.onCommentTap?.call(widget.gonderiId),
                    textStyle: verySmallLabelStyle,
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.read_more_outlined,
                    label: "Detay",
                    onPressed: widget.onDetailsTap,
                    textStyle: verySmallLabelStyle,
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.send_outlined,
                    label: "Paylaş",
                    onPressed: widget.onShareTap,
                    textStyle: verySmallLabelStyle,
                  ),
                ],
              ),
            ),
            // SizedBox(height: 4) KALDIRILDI.
            // Eğer kartın altında hala çok az boşluk isteniyorsa (örn: 2px), buraya eklenebilir.
            // Şimdilik en sıkı haliyle bırakıyorum.
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onPressed,
    TextStyle? textStyle,
  }) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? theme.iconTheme.color,
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3), // Dikey padding biraz artırıldı
        minimumSize: Size(40, 36), // Minimum yükseklik ayarlandı
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _actionButtonIconSize - 2, color: color ?? theme.iconTheme.color),
          if (label.isNotEmpty) SizedBox(height: 2), // İkon ve metin arası
          if (label.isNotEmpty)
            Text(
              label,
              style: textStyle?.copyWith(color: color ?? theme.textTheme.bodySmall?.color) ??
                  theme.textTheme.labelSmall?.copyWith(color: color ?? theme.textTheme.bodySmall?.color, fontSize: 9.5),
              textAlign: TextAlign.center, // Metin ortalansın
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'doğa': return Icons.filter_hdr_outlined;
      case 'tarih': return Icons.museum_outlined;
      case 'kültür': return Icons.color_lens_outlined;
      case 'yeme-içme': return Icons.local_cafe_outlined;
      default: return Icons.label_important_outline_rounded;
    }
  }
}