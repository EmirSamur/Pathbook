// lib/modeller/oneri_modeli.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart'; // equatable paketini pubspec.yaml'a ekleyin: equatable: ^2.0.5

class OneriModeli extends Equatable {
  final String id;          // Firestore belgesinin ID'si
  final String yerAdi;
  final String ipucuMetni;
  final String? gorselUrl;   // Opsiyonel

  const OneriModeli({ // const constructor, Equatable ve performans için iyi
    required this.id,
    required this.yerAdi,
    required this.ipucuMetni,
    this.gorselUrl,
  });

  // Firestore DocumentSnapshot'tan OneriModeli nesnesi üreten fabrika metodu
  factory OneriModeli.dokumandanUret(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      print("UYARI: OneriModeli.dokumandanUret - Belge verisi null geldi. ID: ${doc.id}. Varsayılan model oluşturuluyor.");
      return OneriModeli(
        id: doc.id,
        yerAdi: "Bilinmeyen Yer",
        ipucuMetni: "Harika bir keşif seni bekliyor!",
        gorselUrl: null,
      );
    }

    // Alanları daha güvenli bir şekilde almak için yardımcı fonksiyonlar
    String _getString(Map<String, dynamic> data, String key, String defaultValue, String docId) {
      final value = data[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        // Eğer değer null değil ama String de değilse, bir uyarı logla
        print("UYARI: OneriModeli.dokumandanUret (ID: $docId) - '$key' alanı String tipinde bekleniyordu ancak '${value.runtimeType}' tipinde geldi. Varsayılan değer ('$defaultValue') kullanılacak.");
      }
      return defaultValue;
    }

    String? _getNullableString(Map<String, dynamic> data, String key, String docId) {
      final value = data[key];
      if (value is String) {
        return value;
      }
      if (value == null) {
        // Değer null ise bu geçerli bir durumdur nullable String için
        return null;
      }
      // Null değil ve String de değilse, uyarı logla ve null döndür
      print("UYARI: OneriModeli.dokumandanUret (ID: $docId) - '$key' alanı String? (nullable String) tipinde bekleniyordu ancak '${value.runtimeType}' tipinde geldi. Null değeri kullanılacak.");
      return null;
    }

    return OneriModeli(
      id: doc.id, // Belgenin kendi ID'sini kullanıyoruz
      yerAdi: _getString(data, 'yerAdi', 'Başlıksız Öneri', doc.id),
      ipucuMetni: _getString(data, 'ipucuMetni', 'Keşfetmek için dokun...', doc.id),
      gorselUrl: _getNullableString(data, 'gorselUrl', doc.id),
    );
  }

  // Modeli Firestore'a yazmak veya API'ye göndermek için JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      // 'id' genellikle Firestore belgesinin adı olduğu için data kısmına yazılmaz.
      // Eğer data içinde de saklamak isterseniz ekleyebilirsiniz: 'id': id,
      'yerAdi': yerAdi,
      'ipucuMetni': ipucuMetni,
      if (gorselUrl != null) 'gorselUrl': gorselUrl, // Sadece null değilse ekle
    };
  }

  // Modelin bir kopyasını bazı alanları güncelleyerek oluşturmak için
  OneriModeli copyWith({
    String? id,
    String? yerAdi,
    String? ipucuMetni,
    String? gorselUrl, // Nullable yapmak için `String?` veya özel bir değer (örn. Object())
    bool? clearGorselUrl, // gorselUrl'i null yapmak için
  }) {
    return OneriModeli(
      id: id ?? this.id,
      yerAdi: yerAdi ?? this.yerAdi,
      ipucuMetni: ipucuMetni ?? this.ipucuMetni,
      gorselUrl: clearGorselUrl == true ? null : (gorselUrl ?? this.gorselUrl),
    );
  }

  // Equatable için hangi alanların karşılaştırılacağını belirtir
  @override
  List<Object?> get props => [id, yerAdi, ipucuMetni, gorselUrl];

// Eğer Equatable kullanmak istemezseniz, hashCode ve == operatörünü manuel olarak override edebilirsiniz:
/*
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OneriModeli &&
        other.id == id &&
        other.yerAdi == yerAdi &&
        other.ipucuMetni == ipucuMetni &&
        other.gorselUrl == gorselUrl;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      yerAdi.hashCode ^
      ipucuMetni.hashCode ^
      gorselUrl.hashCode;
  */
}