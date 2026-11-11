import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qr_profile.dart';

class SavedQrCode {
  final String id;
  final String url;
  final String name;
  final String themeColor;
  final DateTime date;
  final QrProfile profile;
  final int viewCount;

  SavedQrCode({
    required this.id,
    required this.url,
    required this.name,
    required this.themeColor,
    required this.date,
    required this.profile,
    this.viewCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'themeColor': themeColor,
      'date': date.toIso8601String(),
      'profile': profile.toMap(),
      'viewCount': viewCount,
    };
  }

  factory SavedQrCode.fromMap(Map<String, dynamic> map) {
    DateTime date = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      date = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createTime'] != null) {
      date = DateTime.tryParse(map['createTime'].toString()) ?? DateTime.now();
    } else if (map['date'] != null) {
      date = DateTime.tryParse(map['date'].toString()) ?? DateTime.now();
    } else if (map['createdAt'] is String) {
      date = DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
    }

    final profileMap = (map['profile'] is Map)
        ? {
            ...map,
            ...Map<String, dynamic>.from(map['profile'] as Map),
          }
        : map;

    final profile = QrProfile.fromMap(profileMap);

    final name = (map['name'] != null && map['name'].toString().trim().isNotEmpty)
        ? map['name'].toString().trim()
        : (map['n'] != null && map['n'].toString().trim().isNotEmpty)
            ? map['n'].toString().trim()
            : (profile.name.isNotEmpty
                ? profile.name
                : (profile.qrName.isNotEmpty ? profile.qrName : 'Untitled QR'));

    final themeColor = (map['themeColor'] != null && map['themeColor'].toString().trim().isNotEmpty)
        ? map['themeColor'].toString().trim()
        : (map['c'] != null && map['c'].toString().trim().isNotEmpty)
            ? map['c'].toString().trim()
            : profile.themeColor;

    final viewCount = int.tryParse(map['viewCount']?.toString() ?? '') ??
        int.tryParse(map['scanCount']?.toString() ?? '') ??
        int.tryParse(map['views']?.toString() ?? '') ??
        int.tryParse(map['vc']?.toString() ?? '') ??
        0;

    return SavedQrCode(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      name: name,
      themeColor: themeColor.isNotEmpty ? themeColor : '#6C5CE7',
      date: date,
      profile: profile,
      viewCount: viewCount,
    );
  }

  factory SavedQrCode.fromFirestoreDoc(
    String id,
    Map<String, dynamic> map,
    String defaultUrl,
  ) {
    DateTime date = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      date = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      date = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else if (map['createTime'] is String) {
      date = DateTime.tryParse(map['createTime']) ?? DateTime.now();
    } else if (map['date'] is String) {
      date = DateTime.tryParse(map['date']) ?? DateTime.now();
    }

    final profileMap = (map['profile'] is Map)
        ? {
            ...map,
            ...Map<String, dynamic>.from(map['profile'] as Map),
          }
        : map;
    final profile = QrProfile.fromMap(profileMap);

    final name = (map['name'] != null && map['name'].toString().trim().isNotEmpty)
        ? map['name'].toString().trim()
        : (map['n'] != null && map['n'].toString().trim().isNotEmpty)
            ? map['n'].toString().trim()
            : (profile.name.isNotEmpty
                ? profile.name
                : (profile.qrName.isNotEmpty
                    ? profile.qrName
                    : (map['qn'] != null && map['qn'].toString().trim().isNotEmpty
                        ? map['qn'].toString().trim()
                        : 'Untitled QR')));

    final themeColor = (map['themeColor'] != null && map['themeColor'].toString().trim().isNotEmpty)
        ? map['themeColor'].toString().trim()
        : (map['c'] != null && map['c'].toString().trim().isNotEmpty)
            ? map['c'].toString().trim()
            : profile.themeColor;

    final url = (map['url'] != null && map['url'].toString().trim().isNotEmpty)
        ? map['url'].toString().trim()
        : defaultUrl;

    final viewCount = int.tryParse(map['viewCount']?.toString() ?? '') ??
        int.tryParse(map['scanCount']?.toString() ?? '') ??
        int.tryParse(map['views']?.toString() ?? '') ??
        int.tryParse(map['vc']?.toString() ?? '') ??
        0;

    return SavedQrCode(
      id: id,
      url: url,
      name: name,
      themeColor: themeColor.isNotEmpty ? themeColor : '#6C5CE7',
      date: date,
      profile: profile,
      viewCount: viewCount,
    );
  }

  @override
  String toString() {
    return 'SavedQrCode(id: $id, name: $name, url: $url, date: $date, viewCount: $viewCount)';
  }
}

