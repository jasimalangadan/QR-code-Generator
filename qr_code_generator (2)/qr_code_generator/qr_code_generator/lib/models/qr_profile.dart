import 'dart:convert';

class QrProfile {
  final String themeColor; // hex string e.g. "#6C5CE7"
  final String name;
  final String headline;
  final String instagram;
  final List<String> instagramList;
  final String telegram;
  final String googleReview;
  final String whatsapp;
  final List<String> whatsappList;
  final String whatsappGroup;
  final String facebook;
  final String youtube;
  final String linkedin;
  final String email;
  final String tiktok;
  final String xTwitter;
  final String threads;
  final String pinterest;
  final String customLinkLabel;
  final String customLinkUrl;
  final String id; // Profile Document ID in Firebase
  final String feedback; // Feedback option or prompt
  final String gallery; // Gallery option or prompt
  final String qrName;
  final String protectionPassword;
  final String avatarUrl; // Profile Image URL
  final String bannerUrl; // Banner Image URL
  final String welcomeUrl; // Welcome/Wallpaper Image URL
  final String avatarBorderColor; // Avatar Border Color hex e.g. '#FF3B30'
  final double avatarBorderWidth; // Avatar Border Width (default 5.0)
  final double
  backgroundBrightness; // Brightness / white overlay opacity of background (0.0 to 1.0)
  final String locationShare;
  final String contactUs;
  final List<String> contactList;
  final String avatarPosition; // 'left', 'center', 'right'
  final int viewCount;
  final Map<String, int> tabClicks;

  QrProfile({
    this.id = '',
    this.themeColor = '#6C5CE7',
    this.name = '',
    this.headline = '',
    String instagram = '',
    List<String>? instagramList,
    this.telegram = '',
    this.googleReview = '',
    String whatsapp = '',
    List<String>? whatsappList,
    this.whatsappGroup = '',
    this.facebook = '',
    this.youtube = '',
    this.linkedin = '',
    this.email = '',
    this.tiktok = '',
    this.xTwitter = '',
    this.threads = '',
    this.pinterest = '',
    this.customLinkLabel = '',
    this.customLinkUrl = '',
    this.feedback = '',
    this.gallery = '',
    this.qrName = '',
    this.protectionPassword = '',
    this.avatarUrl = '',
    this.bannerUrl = '',
    this.welcomeUrl = '',
    this.avatarBorderColor = '',
    this.avatarBorderWidth = 5.0,
    this.backgroundBrightness = 1.0,
    this.locationShare = '',
    String contactUs = '',
    List<String>? contactList,
    this.avatarPosition = 'left',
    this.viewCount = 0,
    Map<String, int>? tabClicks,
  })  : tabClicks = tabClicks ?? const {},
        instagram = (instagramList != null && instagramList.isNotEmpty)
            ? instagramList.first
            : instagram,
        instagramList = (instagramList != null && instagramList.isNotEmpty)
            ? instagramList
            : (instagram.trim().isNotEmpty ? [instagram.trim()] : const []),
        whatsapp = (whatsappList != null && whatsappList.isNotEmpty)
            ? whatsappList.first
            : whatsapp,
        whatsappList = (whatsappList != null && whatsappList.isNotEmpty)
            ? whatsappList
            : (whatsapp.trim().isNotEmpty ? [whatsapp.trim()] : const []),
        contactUs = (contactList != null && contactList.isNotEmpty)
            ? contactList.first
            : contactUs,
        contactList = (contactList != null && contactList.isNotEmpty)
            ? contactList
            : (contactUs.trim().isNotEmpty ? [contactUs.trim()] : const []);

  QrProfile copyWith({
    String? themeColor,
    String? name,
    String? headline,
    String? instagram,
    List<String>? instagramList,
    String? telegram,
    String? googleReview,
    String? whatsapp,
    List<String>? whatsappList,
    String? whatsappGroup,
    String? facebook,
    String? youtube,
    String? linkedin,
    String? email,
    String? tiktok,
    String? xTwitter,
    String? threads,
    String? pinterest,
    String? customLinkLabel,
    String? customLinkUrl,
    String? id,
    String? feedback,
    String? gallery,
    String? qrName,
    String? protectionPassword,
    String? avatarUrl,
    String? bannerUrl,
    String? welcomeUrl,
    String? avatarBorderColor,
    double? avatarBorderWidth,
    double? backgroundBrightness,
    String? locationShare,
    String? contactUs,
    List<String>? contactList,
    String? avatarPosition,
    int? viewCount,
    Map<String, int>? tabClicks,
  }) {
    return QrProfile(
      id: id ?? this.id,
      themeColor: themeColor ?? this.themeColor,
      name: name ?? this.name,
      headline: headline ?? this.headline,
      instagram: instagram ??
          (instagramList != null && instagramList.isNotEmpty
              ? instagramList.first
              : this.instagram),
      instagramList: instagramList ??
          (instagram != null
              ? (instagram.trim().isNotEmpty ? [instagram.trim()] : const [])
              : this.instagramList),
      telegram: telegram ?? this.telegram,
      googleReview: googleReview ?? this.googleReview,
      whatsapp: whatsapp ??
          (whatsappList != null && whatsappList.isNotEmpty
              ? whatsappList.first
              : this.whatsapp),
      whatsappList: whatsappList ??
          (whatsapp != null
              ? (whatsapp.trim().isNotEmpty ? [whatsapp.trim()] : const [])
              : this.whatsappList),
      whatsappGroup: whatsappGroup ?? this.whatsappGroup,
      facebook: facebook ?? this.facebook,
      youtube: youtube ?? this.youtube,
      linkedin: linkedin ?? this.linkedin,
      email: email ?? this.email,
      tiktok: tiktok ?? this.tiktok,
      xTwitter: xTwitter ?? this.xTwitter,
      threads: threads ?? this.threads,
      pinterest: pinterest ?? this.pinterest,
      customLinkLabel: customLinkLabel ?? this.customLinkLabel,
      customLinkUrl: customLinkUrl ?? this.customLinkUrl,
      feedback: feedback ?? this.feedback,
      gallery: gallery ?? this.gallery,
      qrName: qrName ?? this.qrName,
      protectionPassword: protectionPassword ?? this.protectionPassword,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      welcomeUrl: welcomeUrl ?? this.welcomeUrl,
      avatarBorderColor: avatarBorderColor ?? this.avatarBorderColor,
      avatarBorderWidth: avatarBorderWidth ?? this.avatarBorderWidth,
      backgroundBrightness: backgroundBrightness ?? this.backgroundBrightness,
      locationShare: locationShare ?? this.locationShare,
      contactUs: contactUs ??
          (contactList != null && contactList.isNotEmpty
              ? contactList.first
              : this.contactUs),
      contactList: contactList ??
          (contactUs != null
              ? (contactUs.trim().isNotEmpty ? [contactUs.trim()] : const [])
              : this.contactList),
      avatarPosition: avatarPosition ?? this.avatarPosition,
      viewCount: viewCount ?? this.viewCount,
      tabClicks: tabClicks ?? this.tabClicks,
    );
  }

  // Convert to map for Firebase Firestore (uses clear, human-readable field names)
  Map<String, dynamic> toMap() {
    return {
      'themeColor': themeColor,
      'name': name,
      'headline': headline,
      'instagram': instagram,
      'instagramList': instagramList,
      'telegram': telegram,
      'googleReview': googleReview,
      'whatsapp': whatsapp,
      'whatsappList': whatsappList,
      'whatsappGroup': whatsappGroup,
      'facebook': facebook,
      'youtube': youtube,
      'linkedin': linkedin,
      'email': email,
      'tiktok': tiktok,
      'xTwitter': xTwitter,
      'threads': threads,
      'pinterest': pinterest,
      'customLinkLabel': customLinkLabel,
      'customLinkUrl': customLinkUrl,
      'id': id,
      'feedback': feedback,
      'gallery': gallery,
      'qrName': qrName,
      'protectionPassword': protectionPassword,
      'avatarUrl': avatarUrl,
      'bannerUrl': bannerUrl,
      'avatarBorderColor': avatarBorderColor,
      'avatarBorderWidth': avatarBorderWidth,
      'backgroundBrightness': backgroundBrightness,
      'locationShare': locationShare,
      'contactUs': contactUs,
      'contactList': contactList,
      'avatarPosition': avatarPosition,
      'viewCount': viewCount,
      'tabClicks': tabClicks,
      // Short keys for full backward compatibility
      'c': themeColor,
      'n': name,
      'h': headline,
      'i': instagram,
      'inl': instagramList,
      'tg': telegram,
      'g': googleReview,
      'w': whatsapp,
      'wal': whatsappList,
      'wg': whatsappGroup,
      'f': facebook,
      'y': youtube,
      'li': linkedin,
      'em': email,
      'tk': tiktok,
      'x': xTwitter,
      'th': threads,
      'pin': pinterest,
      'cl': customLinkLabel,
      'cu': customLinkUrl,
      'fbk': feedback,
      'gal': gallery,
      'qn': qrName,
      'p': protectionPassword,
      'a': avatarUrl,
      'b': bannerUrl,
      'avb': avatarBorderColor,
      'avbw': avatarBorderWidth,
      'bb': backgroundBrightness,
      'loc': locationShare,
      'con': contactUs,
      'col': contactList,
      'avp': avatarPosition,
      'vc': viewCount,
      'tc': tabClicks,
    };
  }

  // Create from map (supports both full-length readable keys and compact keys)
  factory QrProfile.fromMap(Map<String, dynamic> map) {
    final rawIgList = map['instagramList'] ?? map['inl'];
    List<String> parsedIgList = [];
    if (rawIgList is List) {
      parsedIgList = rawIgList
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final singleIg = (map['instagram'] ?? map['i'] ?? '').toString().trim();
    if (parsedIgList.isEmpty && singleIg.isNotEmpty) {
      parsedIgList = [singleIg];
    }

    final rawWaList = map['whatsappList'] ?? map['wal'];
    List<String> parsedWaList = [];
    if (rawWaList is List) {
      parsedWaList = rawWaList
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final singleWa = (map['whatsapp'] ??
            map['w'] ??
            map['wa'] ??
            map['phone'] ??
            map['phoneNumber'] ??
            '')
        .toString()
        .trim();
    if (parsedWaList.isEmpty && singleWa.isNotEmpty) {
      parsedWaList = [singleWa];
    }

    final rawContactList = map['contactList'] ?? map['col'];
    List<String> parsedContactList = [];
    if (rawContactList is List) {
      parsedContactList = rawContactList
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final singleContact = (map['contactUs'] ?? map['con'] ?? '')
        .toString()
        .trim();
    if (parsedContactList.isEmpty && singleContact.isNotEmpty) {
      parsedContactList = [singleContact];
    }

    return QrProfile(
      id: (map['id'] ?? '').toString().trim(),
      themeColor: map['themeColor'] ?? map['c'] ?? '#6C5CE7',
      name: map['name'] ?? map['n'] ?? '',
      headline: map['headline'] ?? map['h'] ?? '',
      instagram: singleIg,
      instagramList: parsedIgList,
      telegram: (map['telegram'] ?? map['tg'] ?? '').toString().trim(),
      googleReview: map['googleReview'] ?? map['g'] ?? '',
      whatsapp: singleWa,
      whatsappList: parsedWaList,
      whatsappGroup: map['whatsappGroup'] ?? map['wg'] ?? '',
      facebook: map['facebook'] ?? map['f'] ?? '',
      youtube: map['youtube'] ?? map['y'] ?? '',
      linkedin: map['linkedin'] ?? map['li'] ?? '',
      email: map['email'] ?? map['em'] ?? '',
      tiktok: map['tiktok'] ?? map['tk'] ?? '',
      xTwitter: map['xTwitter'] ?? map['x'] ?? map['twitter'] ?? '',
      threads: map['threads'] ?? map['th'] ?? '',
      pinterest: map['pinterest'] ?? map['pin'] ?? '',
      customLinkLabel: map['customLinkLabel'] ?? map['cl'] ?? '',
      customLinkUrl: map['customLinkUrl'] ?? map['cu'] ?? '',
      feedback: (map['feedback'] ?? map['fbk'] ?? '').toString().trim(),
      gallery: (map['gallery'] ?? map['gal'] ?? '').toString().trim(),
      qrName: map['qrName'] ?? map['qn'] ?? '',
      protectionPassword: map['protectionPassword'] ?? map['p'] ?? '',
      avatarUrl: map['avatarUrl'] ?? map['a'] ?? '',
      bannerUrl: map['bannerUrl'] ?? map['b'] ?? '',
      welcomeUrl: map['welcomeUrl'] ?? map['wel'] ?? '',
      avatarBorderColor: map['avatarBorderColor'] ?? map['avb'] ?? '',
      avatarBorderWidth: (map['avatarBorderWidth'] ?? map['avbw'] ?? 5.0)
          .toDouble(),
      backgroundBrightness: (map['backgroundBrightness'] ?? map['bb'] ?? 1.0)
          .toDouble(),
      locationShare: map['locationShare'] ?? map['loc'] ?? '',
      contactUs: singleContact,
      contactList: parsedContactList,
      avatarPosition: map['avatarPosition']?.toString() ??
          map['avp']?.toString() ??
          'left',
      viewCount: int.tryParse(map['viewCount']?.toString() ?? '') ??
          int.tryParse(map['scanCount']?.toString() ?? '') ??
          int.tryParse(map['views']?.toString() ?? '') ??
          int.tryParse(map['vc']?.toString() ?? '') ??
          0,
      tabClicks: () {
        final raw = map['tabClicks'] ?? map['tc'];
        final Map<String, int> result = {};
        if (raw is Map) {
          raw.forEach((key, val) {
            final parsedVal = int.tryParse(val?.toString() ?? '') ?? 0;
            result[key.toString()] = parsedVal;
          });
        }
        return result;
      }(),
    );
  }

  // For QR code payload, we exclude massive Base64 strings to stay within size limits
  Map<String, dynamic> toCompactMap() {
    final map = toMap();
    if (avatarUrl.startsWith('data:image/') && avatarUrl.contains('base64,')) {
      map['a'] = '';
    }
    if (bannerUrl.startsWith('data:image/') && bannerUrl.contains('base64,')) {
      map['b'] = '';
    }
    return map;
  }

  // Base64-encoded JSON to pack into a local URL
  String toBase64() {
    final jsonStr = json.encode(toCompactMap());
    final bytes = utf8.encode(jsonStr);
    return base64Url.encode(bytes);
  }

  // Decode profile from Base64
  factory QrProfile.fromBase64(String encoded) {
    try {
      final decodedBytes = base64Url.decode(encoded);
      final jsonStr = utf8.decode(decodedBytes);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return QrProfile.fromMap(map);
    } catch (e) {
      return QrProfile(); // Return default if decoding fails
    }
  }

  // Validation helper
  bool get isValid => name.trim().isNotEmpty;

  @override
  String toString() => 'QrProfile(${toMap()})';
}
