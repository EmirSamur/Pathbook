// lib/widgets/content_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathbooks/servisler/firestoreseervisi.dart'; // Firestore servisinizi doğru import ettiğinizden emin olun

class ContentCard extends StatefulWidget {
  final String gonderiId;
  final String imageUrl;
  final String profileUrl; // Gönderiyi paylaşanın profil resmi
  final String userName;   // Gönderiyi paylaşanın kullanıcı adı
  final String location;   // Gönderi açıklaması veya konumu
  final int initialLikeCount;
  final int initialCommentCount;
  final String aktifKullaniciId; // Mevcut aktif kullanıcının ID'si

  final VoidCallback? onProfileTap; // Sağdaki profil resmine tıklandığında
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;  // Alt metin bloğundaki üç nokta
  final Function(String gonderiId)? onCommentTap; // Yorum ikonuna tıklandığında

  const ContentCard({
    Key? key,
    required this.gonderiId,
    required this.imageUrl,
    required this.profileUrl,
    required this.userName,
    required this.location,
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
    // DÜZELTİLMİŞ DEĞİŞKEN ADI:
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
      // DÜZELTİLMİŞ DEĞİŞKEN ADI:
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
      color: Colors.black,
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
                : Container(
              color: Colors.grey[900],
              child: Center(child: Icon(Icons.hide_image_outlined, color: Colors.grey[700], size: 60)),
            ),
          ),

          // Sağ Kenar Eylem Butonları (Profil resmi en üste alındı)
          Positioned(
            right: 10,
            bottom: MediaQuery.of(context).size.height * 0.10, // Dikey konumu ayarlayın
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GÖNDERİYİ PAYLAŞANIN PROFİL RESMİ VE TAKİP BUTONU
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[700], // Profil resmi yüklenemezse
                          backgroundImage: widget.profileUrl.isNotEmpty ? NetworkImage(widget.profileUrl) : null,
                          child: widget.profileUrl.isEmpty ? Icon(Icons.person, color: Colors.white70, size: 30) : null,
                        ),
                      ),
                    ),
                    // Takip Et "+" Butonu
                    Positioned(
                      child: Container(
                        width: 22, // Boyut biraz artırıldı
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent, // Renk değiştirildi
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.8), // Arka plan siyah olduğu için border siyah
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 18), // Boyut artırıldı
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20), // Profil resmi ile ilk eylem butonu arası

                // BEĞEN BUTONU VE SAYACI
                _buildActionIconButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border_outlined, //favorite_border_outlined daha belirgin
                  label: _likeCount > 0 ? _likeCount.toString() : " ", // Sayı 0 ise boşluk bırakarak yerini koru
                  color: _isLiked ? Colors.redAccent[400] : Colors.white,
                  onTap: _isLiking ? null : _toggleLike,
                ),
                SizedBox(height: 22),

                // YORUM BUTONU VE SAYACI
                _buildActionIconButton(
                  icon: Icons.chat_bubble_outline_rounded, // Daha dolgun bir ikon
                  label: _commentCount > 0 ? _commentCount.toString() : " ",
                  color: Colors.white,
                  onTap: () {
                    if (widget.onCommentTap != null) {
                      widget.onCommentTap!(widget.gonderiId);
                    }
                  },
                ),
                SizedBox(height: 22),

                // KAYDET BUTONU
                _buildActionIconButton(
                  icon: Icons.bookmark_border_outlined, // Daha belirgin
                  color: Colors.white,
                  onTap: () { print("Kaydet tıklandı: ${widget.gonderiId}"); },
                ),
                SizedBox(height: 22),

                // PAYLAŞ BUTONU
                _buildActionIconButton(
                  icon: Icons.send_outlined, // Daha standart bir paylaşım ikonu
                  // flipIconHorizontal: true, // send_outlined için çevirmeye gerek yok
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
              padding: EdgeInsets.fromLTRB(15, 20, 10, 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.9)], // Gradyan biraz daha koyu
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.65],
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
                            fontSize: 16.5, // Biraz daha büyük
                            shadows: [Shadow(blurRadius: 1.5, color: Colors.black87, offset: Offset(0,1))], // Daha belirgin gölge
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        if (widget.location.isNotEmpty)
                          Text(
                            widget.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 14.5, // Biraz daha büyük
                              shadows: [Shadow(blurRadius: 1, color: Colors.black54, offset: Offset(0,1))],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: GestureDetector(
                      onTap: widget.onMoreTap,
                      child: Icon(Icons.more_horiz, color: Colors.white, size: 32), // İkon boyutu artırıldı
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

  Widget _buildActionIconButton({
    required IconData icon,
    String? label,
    Color? color,
    VoidCallback? onTap,
    bool flipIconHorizontal = false,
    double iconSize = 33, // İKON BOYUTU ARTIRILDI
    double labelSize = 13, // ETİKET BOYUTU ARTIRILDI
  }) {
    Widget iconWidget = Icon(icon, color: color ?? Colors.white, size: iconSize,
      // İkona gölge ekleyerek daha belirgin hale getirebiliriz
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
        padding: const EdgeInsets.symmetric(vertical: 4.0), // Dikey padding biraz azaltıldı
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            if (label != null && label.isNotEmpty && label != " ") SizedBox(height: 2), // Etiket varsa ve sadece boşluk değilse
            if (label != null && label.isNotEmpty && label != " ")
              Text(
                label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600, // Biraz daha kalın
                    shadows: [ // Metne de gölge
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