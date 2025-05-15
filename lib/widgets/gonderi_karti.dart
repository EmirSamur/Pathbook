// lib/widgets/content_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart';

class ContentCard extends StatefulWidget {
  final String gonderiId;
  final List<String> resimUrls; // DEĞİŞTİ: Tek URL yerine URL listesi
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
    required this.resimUrls, // DEĞİŞTİ
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
      print("ContentCard - Beğeni toggle hatası: $e");
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

    // Gösterilecek ana resim URL'si (listenin ilki, eğer liste boş değilse)
    String? anaResimUrl;
    if (widget.resimUrls.isNotEmpty) {
      anaResimUrl = widget.resimUrls[0];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12.0),
        elevation: 2.0, // Önceki saydamlık denemesinden kalma, isteğe bağlı
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        clipBehavior: Clip.antiAlias,
        color: (theme.cardTheme.color ?? theme.cardColor).withOpacity(0.85), // Önceki saydamlık denemesi
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Kullanıcı Başlığı
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 8.0, 8.0),
              child: Row( /* ... (Kullanıcı başlığı aynı) ... */
                children: <Widget>[
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      backgroundImage: widget.profileUrl.isNotEmpty ? NetworkImage(widget.profileUrl) : null,
                      child: widget.profileUrl.isEmpty ? Icon(Icons.person, size: 22, color: theme.colorScheme.onSurfaceVariant) : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.userName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.8)),
                    onPressed: widget.onMoreTap ?? () { print("More tıklandı: ${widget.gonderiId}"); },
                    splashRadius: 20,
                    tooltip: "Daha fazla seçenek",
                  ),
                ],
              ),
            ),

            // 2. Gönderi Görseli ve Çoklu Resim Göstergesi
            if (anaResimUrl != null) // Sadece ana resim varsa göster
              GestureDetector(
                onDoubleTap: _isLiking ? null : _toggleLike,
                onTap: widget.onDetailsTap,
                child: Stack( // Görseli ve göstergeyi üst üste bindirmek için Stack
                  alignment: Alignment.topRight,
                  children: [
                    AspectRatio(
                      aspectRatio: 1/1, // Görselin dikey oranı (isteğe bağlı değiştirilebilir)
                      child: Image.network(
                        anaResimUrl, // Ana görsel olarak ilk resmi göster
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          child: Center(child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), size: 60)),
                        ),
                      ),
                    ),
                    // Çoklu resim göstergesi (eğer birden fazla resim varsa)
                    if (widget.resimUrls.length > 1)
                      Positioned(
                        top: 8.0,
                        right: 8.0,
                        child: Container( // Chip yerine Container + Text ile daha sade bir görünüm
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            "${widget.resimUrls.length} resim",
                            style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Container( // Görsel yoksa placeholder
                height: MediaQuery.of(context).size.width * (4 / 3), // Orana göre bir yükseklik
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                child: Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))),
              ),

            // 3. Konum ve Kategori
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 6.0),
              child: Wrap( /* ... (Konum ve Kategori aynı) ... */
                spacing: 8.0, runSpacing: 4.0, crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.location.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.secondary),
                        const SizedBox(width: 4),
                        Flexible(child: Text(widget.location, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  if (widget.category != null && widget.category!.isNotEmpty)
                    Chip(
                      avatar: Icon(_getCategoryIcon(widget.category!), size: 16, color: theme.colorScheme.onSecondaryContainer),
                      label: Text(widget.category!),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                      backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),

            // 4. Açıklama Kırpıntısı
            if (widget.description != null && widget.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
                child: GestureDetector( /* ... (Açıklama aynı) ... */
                  onTap: widget.onDetailsTap,
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: <TextSpan>[
                        TextSpan(text: widget.description!.length > 100 ? widget.description!.substring(0, 100) : widget.description!),
                        if (widget.description!.length > 100)
                          TextSpan(text: "... daha fazla gör", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            Divider(height: 1, thickness: 0.5, indent: 12, endIndent: 12),

            // 5. Etkileşim Butonları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0), // Dikey padding 0 yapıldı
              child: Row( /* ... (Etkileşim butonları aynı, padding düzenlemeleri uygulanmıştı) ... */
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton.icon(
                    icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? theme.colorScheme.error : theme.iconTheme.color, size: 22),
                    label: Text(_likeCount > 0 ? _likeCount.toString() : "Beğen", style: theme.textTheme.labelLarge),
                    onPressed: _isLiking ? null : _toggleLike,
                    style: TextButton.styleFrom(foregroundColor: theme.textTheme.labelLarge?.color, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 22, color: theme.iconTheme.color),
                    label: Text(_commentCount > 0 ? _commentCount.toString() : "Yorum", style: theme.textTheme.labelLarge),
                    onPressed: () => widget.onCommentTap?.call(widget.gonderiId),
                    style: TextButton.styleFrom(foregroundColor: theme.textTheme.labelLarge?.color, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ),
                  IconButton(
                    icon: Icon(Icons.read_more_outlined, size: 24, color: theme.iconTheme.color),
                    onPressed: widget.onDetailsTap, tooltip: "Detayları Gör", padding: EdgeInsets.zero, constraints: BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(Icons.send_outlined, size: 24, color: theme.iconTheme.color),
                    onPressed: widget.onShareTap, tooltip: "Paylaş", padding: EdgeInsets.zero, constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            // En alttaki SizedBox kaldırılmıştı, bu şekilde boşluk daha az olmalı.
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'doğa': return Icons.eco_outlined;
      case 'tarih': return Icons.account_balance_outlined;
      case 'kültür': return Icons.palette_outlined;
      case 'yeme-içme': return Icons.restaurant_menu_outlined;
      default: return Icons.label_outline;
    }
  }
}