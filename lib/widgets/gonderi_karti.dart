// lib/widgets/content_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // Firestore servisinizi doğru import ettiğinizden emin olun

class ContentCard extends StatefulWidget {
  final String gonderiId;
  final String imageUrl;
  final String profileUrl;
  final String userName;
  final String location; // Bu artık 'konum' bilgisini tutacak
  final String? description; // YENİ: Gönderi açıklaması (opsiyonel)
  final String? category;    // YENİ: Gönderi kategorisi (opsiyonel)
  final int initialLikeCount;
  final int initialCommentCount;
  final String aktifKullaniciId;

  final VoidCallback? onProfileTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;
  final Function(String gonderiId)? onCommentTap;

  const ContentCard({
    Key? key,
    required this.gonderiId,
    required this.imageUrl,
    required this.profileUrl,
    required this.userName,
    required this.location,   // Bu parametre artık 'konum' için kullanılacak
    this.description,       // YENİ eklendi
    this.category,          // YENİ eklendi
    required this.initialLikeCount,
    required this.initialCommentCount,
    required this.aktifKullaniciId,
    this.onProfileTap,
    this.onShareTap,
    this.onMoreTap,
    this.onCommentTap,
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
      // description ve category gibi yeni alanlar için de güncelleme gerekebilir,
      // ancak bunlar genellikle gönderi ile sabit kalır, beğeni/yorum gibi dinamik değişmez.
      needsRecheck = true;
    } else {
      if (widget.initialLikeCount != _likeCount) {
        if(mounted) setState(() => _likeCount = widget.initialLikeCount);
      }
      if (widget.initialCommentCount != _commentCount) {
        if(mounted) setState(() => _commentCount = widget.initialCommentCount);
      }
    }

    if (widget.aktifKullaniciId != oldWidget.aktifKullaniciId) {
      needsRecheck = true;
    }

    if (needsRecheck) {
      if (widget.aktifKullaniciId.isNotEmpty) {
        _checkIfLiked();
      } else {
        if(mounted) setState(() => _isLiked = false);
      }
    }
  }

  Future<void> _checkIfLiked() async {
    if (widget.gonderiId.isEmpty || widget.aktifKullaniciId.isEmpty) {
      if(mounted) setState(() => _isLiked = false);
      return;
    }
    if (!mounted) return;
    bool liked = await _firestoreServisi.kullaniciGonderiyiBegendiMi(
      gonderiId: widget.gonderiId,
      aktifKullaniciId: widget.aktifKullaniciId,
    );
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (widget.aktifKullaniciId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Beğenmek için giriş yapmalısınız.")),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Beğeni işlemi sırasında bir hata oluştu.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Arka plan rengi
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ana İçerik Resmi
          GestureDetector(
            onDoubleTap: _isLiking ? null : _toggleLike,
            child: widget.imageUrl.isNotEmpty
                ? Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)));
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[900],
                child: Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[700], size: 60)),
              ),
            )
                : Container( // Resim URL'i boşsa veya yüklenemediyse
              color: Colors.grey[900],
              child: Center(child: Icon(Icons.hide_image_outlined, color: Colors.grey[700], size: 60)),
            ),
          ),

          // Sağ Kenar Eylem Butonları
          Positioned(
            right: 10,
            bottom: MediaQuery.of(context).size.height * 0.10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[700],
                          backgroundImage: widget.profileUrl.isNotEmpty ? NetworkImage(widget.profileUrl) : null,
                          child: widget.profileUrl.isEmpty ? Icon(Icons.person, color: Colors.white70, size: 30) : null,
                        ),
                      ),
                    ),
                    Positioned(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.8),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20),
                _buildActionIconButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                  label: _likeCount > 0 ? _likeCount.toString() : " ",
                  color: _isLiked ? Colors.redAccent[400] : Colors.white,
                  onTap: _isLiking ? null : _toggleLike,
                ),
                SizedBox(height: 22),
                _buildActionIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _commentCount > 0 ? _commentCount.toString() : " ",
                  color: Colors.white,
                  onTap: () {
                    if (widget.onCommentTap != null) {
                      widget.onCommentTap!(widget.gonderiId);
                    }
                  },
                ),
                SizedBox(height: 22),
                _buildActionIconButton( // Kaydet butonu
                  icon: Icons.bookmark_border_outlined,
                  color: Colors.white,
                  onTap: () {
                    print("Kaydet tıklandı: ${widget.gonderiId}");
                    // TODO: Kaydetme fonksiyonelliği
                  },
                ),
                SizedBox(height: 22),
                _buildActionIconButton(
                  icon: Icons.send_outlined,
                  color: Colors.white,
                  onTap: widget.onShareTap,
                ),
              ],
            ),
          ),

          // Alt Metin Bloğu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(15, 15, 10, 15), // Üst padding biraz azaltıldı
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.95)], // Gradyan biraz daha yoğun
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.6], // Gradyan başlangıç noktası ayarlandı
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "@${widget.userName}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Boyut sabitlendi
                            shadows: [Shadow(blurRadius: 1.5, color: Colors.black87, offset: Offset(0,1))],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4), // Kullanıcı adı ile açıklama/konum arası boşluk
                        // YENİ: Açıklamayı (description) göster
                        if (widget.description != null && widget.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3.0), // Açıklama ile konum arası boşluk için
                            child: Text(
                              widget.description!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9), // Biraz daha opak
                                fontSize: 14, // Boyut sabitlendi
                                shadows: [Shadow(blurRadius: 1, color: Colors.black54, offset: Offset(0,1))],
                              ),
                              maxLines: 2, // Açıklama için 2 satır
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        // Mevcut 'location' parametresi artık 'konum'u gösteriyor
                        if (widget.location.isNotEmpty)
                          Row( // Konum ve Kategori için Row
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.white70, size: 15),
                              SizedBox(width: 4),
                              Expanded( // Konum metni uzunsa sığması için
                                child: Text(
                                  widget.location,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8), // Biraz daha az opak
                                    fontSize: 13, // Boyut sabitlendi
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        // YENİ: Kategoriyi göster (eğer varsa)
                        if (widget.category != null && widget.category!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3.0), // Konum ile kategori arası boşluk
                            child: Row(
                              children: [
                                Icon(
                                    _getCategoryIcon(widget.category!), // Kategoriye göre ikon
                                    color: Colors.white70,
                                    size: 15
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.category!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic, // Kategoriyi italik yapabiliriz
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: GestureDetector(
                      onTap: widget.onMoreTap,
                      child: Icon(Icons.more_horiz, color: Colors.white, size: 30), // Boyut sabitlendi
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

  // Kategoriye göre ikon döndüren yardımcı metod
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'doğa':
        return Icons.park_outlined;
      case 'tarih':
        return Icons.museum_outlined;
      case 'kültür':
        return Icons.palette_outlined;
      case 'yeme-içme':
        return Icons.restaurant_outlined;
      default:
        return Icons.category_outlined; // Varsayılan ikon
    }
  }

  Widget _buildActionIconButton({
    required IconData icon,
    String? label,
    Color? color,
    VoidCallback? onTap,
    bool flipIconHorizontal = false,
    double iconSize = 32, // Boyut sabitlendi
    double labelSize = 12.5, // Boyut sabitlendi
  }) {
    Widget iconWidget = Icon(icon, color: color ?? Colors.white, size: iconSize,
      shadows: [
        Shadow(blurRadius: 3, color: Colors.black.withOpacity(0.6), offset: Offset(0,1))
      ],
    );
    if (flipIconHorizontal) {
      iconWidget = Transform.flip(flipX: true, child: iconWidget);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3.0), // Dikey padding ayarlandı
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (label != null && label.isNotEmpty && label != " ") SizedBox(height: 2.5), // Yükseklik ayarlandı
            if (label != null && label.isNotEmpty && label != " ")
              Text(
                label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.7), offset: Offset(0,1))
                    ]
                ),
              ),
          ],
        ),
      ),
    );
  }
}