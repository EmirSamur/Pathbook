// lib/veri/konumlar.dart
// Gönderilerde şehir/ülke serbest metin olarak tutulduğu için harita ve
// istatistiklerde kullanılmak üzere yaklaşık koordinat tablosu.

class Koordinat {
  final double enlem;
  final double boylam;
  const Koordinat(this.enlem, this.boylam);
}

/// "İzmir", "izmir", "IZMIR" gibi yazımları aynı anahtara indirger.
String konumAnahtari(String metin) {
  const Map<String, String> donusum = {
    'ı': 'i', 'İ': 'i', 'I': 'i', 'ş': 's', 'Ş': 's', 'ğ': 'g', 'Ğ': 'g',
    'ü': 'u', 'Ü': 'u', 'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
    'â': 'a', 'î': 'i', 'û': 'u', 'é': 'e', 'è': 'e', 'ä': 'a',
  };
  final buffer = StringBuffer();
  for (final rune in metin.trim().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(donusum[ch] ?? ch.toLowerCase());
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}

/// Türkiye'nin 81 ili (alfabetik).
const List<String> turkiyeIlleri = [
  "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Aksaray", "Amasya", "Ankara", "Antalya", "Ardahan", "Artvin",
  "Aydın", "Balıkesir", "Bartın", "Batman", "Bayburt", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur",
  "Bursa", "Çanakkale", "Çankırı", "Çorum", "Denizli", "Diyarbakır", "Düzce", "Edirne", "Elazığ", "Erzincan",
  "Erzurum", "Eskişehir", "Gaziantep", "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Iğdır", "Isparta", "İstanbul",
  "İzmir", "Kahramanmaraş", "Karabük", "Karaman", "Kars", "Kastamonu", "Kayseri", "Kilis", "Kırıkkale", "Kırklareli",
  "Kırşehir", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa", "Mardin", "Mersin", "Muğla", "Muş",
  "Nevşehir", "Niğde", "Ordu", "Osmaniye", "Rize", "Sakarya", "Samsun", "Şanlıurfa", "Siirt", "Sinop",
  "Sivas", "Şırnak", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Uşak", "Van", "Yalova", "Yozgat", "Zonguldak",
];

const Map<String, Koordinat> _sehirKoordinatlari = {
  // Türkiye
  "adana": Koordinat(37.00, 35.32), "adiyaman": Koordinat(37.76, 38.28), "afyonkarahisar": Koordinat(38.76, 30.54),
  "afyon": Koordinat(38.76, 30.54), "agri": Koordinat(39.72, 43.05), "aksaray": Koordinat(38.37, 34.03),
  "amasya": Koordinat(40.65, 35.83), "ankara": Koordinat(39.93, 32.86), "antalya": Koordinat(36.89, 30.71),
  "ardahan": Koordinat(41.11, 42.70), "artvin": Koordinat(41.18, 41.82), "aydin": Koordinat(37.85, 27.85),
  "balikesir": Koordinat(39.65, 27.88), "bartin": Koordinat(41.64, 32.34), "batman": Koordinat(37.89, 41.13),
  "bayburt": Koordinat(40.26, 40.23), "bilecik": Koordinat(40.14, 29.98), "bingol": Koordinat(38.88, 40.50),
  "bitlis": Koordinat(38.40, 42.11), "bolu": Koordinat(40.74, 31.61), "burdur": Koordinat(37.72, 30.29),
  "bursa": Koordinat(40.19, 29.06), "canakkale": Koordinat(40.15, 26.41), "cankiri": Koordinat(40.60, 33.62),
  "corum": Koordinat(40.55, 34.95), "denizli": Koordinat(37.78, 29.09), "diyarbakir": Koordinat(37.91, 40.24),
  "duzce": Koordinat(40.84, 31.16), "edirne": Koordinat(41.68, 26.56), "elazig": Koordinat(38.67, 39.22),
  "erzincan": Koordinat(39.75, 39.49), "erzurum": Koordinat(39.90, 41.27), "eskisehir": Koordinat(39.78, 30.52),
  "gaziantep": Koordinat(37.07, 37.38), "giresun": Koordinat(40.91, 38.39), "gumushane": Koordinat(40.46, 39.48),
  "hakkari": Koordinat(37.57, 43.74), "hatay": Koordinat(36.20, 36.16), "igdir": Koordinat(39.92, 44.04),
  "isparta": Koordinat(37.76, 30.55), "istanbul": Koordinat(41.01, 28.98), "izmir": Koordinat(38.42, 27.14),
  "kahramanmaras": Koordinat(37.58, 36.94), "karabuk": Koordinat(41.20, 32.62), "karaman": Koordinat(37.18, 33.22),
  "kars": Koordinat(40.60, 43.10), "kastamonu": Koordinat(41.39, 33.78), "kayseri": Koordinat(38.73, 35.49),
  "kilis": Koordinat(36.72, 37.12), "kirikkale": Koordinat(39.85, 33.51), "kirklareli": Koordinat(41.74, 27.23),
  "kirsehir": Koordinat(39.15, 34.16), "kocaeli": Koordinat(40.77, 29.94), "izmit": Koordinat(40.77, 29.94),
  "konya": Koordinat(37.87, 32.48), "kutahya": Koordinat(39.42, 29.98), "malatya": Koordinat(38.35, 38.31),
  "manisa": Koordinat(38.61, 27.43), "mardin": Koordinat(37.31, 40.74), "mersin": Koordinat(36.81, 34.64),
  "mugla": Koordinat(37.22, 28.36), "mus": Koordinat(38.74, 41.49), "nevsehir": Koordinat(38.62, 34.71),
  "kapadokya": Koordinat(38.64, 34.83), "nigde": Koordinat(37.97, 34.68), "ordu": Koordinat(40.98, 37.88),
  "osmaniye": Koordinat(37.07, 36.25), "rize": Koordinat(41.02, 40.52), "sakarya": Koordinat(40.69, 30.44),
  "samsun": Koordinat(41.29, 36.33), "sanliurfa": Koordinat(37.16, 38.79), "urfa": Koordinat(37.16, 38.79),
  "siirt": Koordinat(37.93, 41.94), "sinop": Koordinat(42.03, 35.15), "sivas": Koordinat(39.75, 37.02),
  "sirnak": Koordinat(37.52, 42.46), "tekirdag": Koordinat(40.98, 27.51), "tokat": Koordinat(40.31, 36.55),
  "trabzon": Koordinat(41.00, 39.72), "tunceli": Koordinat(39.11, 39.55), "usak": Koordinat(38.68, 29.41),
  "van": Koordinat(38.49, 43.38), "yalova": Koordinat(40.65, 29.27), "yozgat": Koordinat(39.82, 34.81),
  "zonguldak": Koordinat(41.45, 31.79), "bodrum": Koordinat(37.03, 27.43), "fethiye": Koordinat(36.62, 29.12),
  "alanya": Koordinat(36.54, 31.99), "kas": Koordinat(36.20, 29.64), "marmaris": Koordinat(36.85, 28.27),
  "cesme": Koordinat(38.32, 26.30), "ayvalik": Koordinat(39.32, 26.69), "edremit": Koordinat(39.59, 27.02),
  "pamukkale": Koordinat(37.92, 29.12), "efes": Koordinat(37.94, 27.34), "kusadasi": Koordinat(37.86, 27.26),
  // Dünya
  "berlin": Koordinat(52.52, 13.40), "munih": Koordinat(48.14, 11.58), "munchen": Koordinat(48.14, 11.58),
  "hamburg": Koordinat(53.55, 9.99), "frankfurt": Koordinat(50.11, 8.68), "koln": Koordinat(50.94, 6.96),
  "paris": Koordinat(48.86, 2.35), "marsilya": Koordinat(43.30, 5.37), "lyon": Koordinat(45.76, 4.84),
  "nice": Koordinat(43.70, 7.27), "strazburg": Koordinat(48.57, 7.75), "roma": Koordinat(41.90, 12.50),
  "milano": Koordinat(45.46, 9.19), "venedik": Koordinat(45.44, 12.32), "floransa": Koordinat(43.77, 11.26),
  "napoli": Koordinat(40.85, 14.27), "madrid": Koordinat(40.42, -3.70), "barselona": Koordinat(41.39, 2.17),
  "barcelona": Koordinat(41.39, 2.17), "sevilla": Koordinat(37.39, -5.98), "valensiya": Koordinat(39.47, -0.38),
  "granada": Koordinat(37.18, -3.60), "new york": Koordinat(40.71, -74.01), "los angeles": Koordinat(34.05, -118.24),
  "chicago": Koordinat(41.88, -87.63), "san francisco": Koordinat(37.77, -122.42), "miami": Koordinat(25.76, -80.19),
  "tokyo": Koordinat(35.68, 139.69), "kyoto": Koordinat(35.01, 135.77), "osaka": Koordinat(34.69, 135.50),
  "hirosima": Koordinat(34.39, 132.46), "londra": Koordinat(51.51, -0.13), "london": Koordinat(51.51, -0.13),
  "amsterdam": Koordinat(52.37, 4.90), "viyana": Koordinat(48.21, 16.37), "prag": Koordinat(50.08, 14.44),
  "budapeste": Koordinat(47.50, 19.04), "atina": Koordinat(37.98, 23.73), "lizbon": Koordinat(38.72, -9.14),
  "dubai": Koordinat(25.20, 55.27), "baku": Koordinat(40.41, 49.87),
  "tiflis": Koordinat(41.72, 44.79), "saraybosna": Koordinat(43.86, 18.41), "uskup": Koordinat(41.99, 21.43),
};

const Map<String, Koordinat> _ulkeKoordinatlari = {
  "turkiye": Koordinat(39.0, 35.0), "turkey": Koordinat(39.0, 35.0), "almanya": Koordinat(51.2, 10.4),
  "fransa": Koordinat(46.6, 2.4), "italya": Koordinat(42.8, 12.6), "ispanya": Koordinat(40.2, -3.7),
  "abd": Koordinat(39.8, -98.6), "amerika": Koordinat(39.8, -98.6), "japonya": Koordinat(36.2, 138.3),
  "ingiltere": Koordinat(52.4, -1.5), "hollanda": Koordinat(52.1, 5.3), "avusturya": Koordinat(47.5, 14.6),
  "cekya": Koordinat(49.8, 15.5), "macaristan": Koordinat(47.2, 19.5), "yunanistan": Koordinat(39.1, 22.0),
  "portekiz": Koordinat(39.4, -8.2), "azerbaycan": Koordinat(40.1, 47.6), "gurcistan": Koordinat(42.3, 43.4),
  "bosna hersek": Koordinat(43.9, 17.7), "makedonya": Koordinat(41.6, 21.7), "birlesik arap emirlikleri": Koordinat(23.4, 53.8),
};

/// Şehir bilinmiyorsa ülke koordinatına düşer; ikisi de bilinmiyorsa null.
Koordinat? konumKoordinati({String? sehir, String? ulke}) {
  if (sehir != null && sehir.trim().isNotEmpty) {
    final k = _sehirKoordinatlari[konumAnahtari(sehir)];
    if (k != null) return k;
  }
  if (ulke != null && ulke.trim().isNotEmpty) {
    return _ulkeKoordinatlari[konumAnahtari(ulke)];
  }
  return null;
}
