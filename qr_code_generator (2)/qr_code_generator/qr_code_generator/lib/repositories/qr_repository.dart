import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/qr_profile.dart';
import '../models/saved_qr_code.dart';
import '../utils/history_storage.dart';

abstract class QrRepository {
  Future<String> saveProfile(QrProfile profile);
  Future<String> updateProfile(String docId, QrProfile profile);
  Future<QrProfile> fetchProfile(String identifier);
  Future<List<SavedQrCode>> fetchAllProfiles();
  Stream<List<SavedQrCode>> watchAllProfiles();
  Future<void> deleteProfile(String id);
  Future<void> incrementViewCount(String docId);
  Future<void> incrementTabClick(String docId, String tabType);
  Future<void> submitFeedback(String docId, Map<String, dynamic> feedback);
  Stream<List<Map<String, dynamic>>> watchFeedbacks(String docId);
  Future<List<Map<String, dynamic>>> fetchFeedbacks(String docId);
  Future<void> addGalleryPhoto(String docId, Map<String, dynamic> photoData);
  Future<void> addGalleryPhotos(String docId, List<Map<String, dynamic>> photosData);
  Future<void> deleteGalleryPhoto(String docId, String photoId);
  Stream<List<Map<String, dynamic>>> watchGallery(String docId);
  Future<List<Map<String, dynamic>>> fetchGallery(String docId);
}

/// A pure local/serverless implementation. It packs the complete profile payload
/// inside a compact Base64 query parameter in the scanned URL.
/// No backend or internet access is required to generate or read these codes.
class LocalQrRepository implements QrRepository {
  static final Map<String, List<Map<String, dynamic>>> _localFeedbacks = {};

  @override
  Future<String> saveProfile(QrProfile profile) async {
    // Simulate database save lag
    await Future.delayed(const Duration(milliseconds: 600));
    final payload = profile.toBase64();
    return 'https://scan.page/preview?data=$payload';
  }

  @override
  Future<String> updateProfile(String docId, QrProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final payload = profile.toBase64();
    return 'https://scan.page/preview?data=$payload';
  }

  @override
  Future<QrProfile> fetchProfile(String identifier) async {
    try {
      final uri = Uri.parse(identifier);
      final dataParam = uri.queryParameters['data'];
      if (dataParam != null) {
        return QrProfile.fromBase64(dataParam);
      }
      return QrProfile.fromBase64(identifier);
    } catch (_) {
      return QrProfile();
    }
  }

  @override
  Future<List<SavedQrCode>> fetchAllProfiles() async {
    return await HistoryStorage.loadHistory();
  }

  @override
  Stream<List<SavedQrCode>> watchAllProfiles() async* {
    yield await HistoryStorage.loadHistory();
  }

  @override
  Future<void> deleteProfile(String id) async {
    await HistoryStorage.deleteQrCode(id);
  }

  @override
  Future<void> incrementViewCount(String docId) async {}

  @override
  Future<void> incrementTabClick(String docId, String tabType) async {}

  @override
  Future<void> submitFeedback(
    String docId,
    Map<String, dynamic> feedback,
  ) async {
    final list = _localFeedbacks.putIfAbsent(docId, () => []);
    final data = Map<String, dynamic>.from(feedback);
    data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    data['timestamp'] =
        feedback['timestamp'] ?? DateTime.now().toIso8601String();
    data['createdAt'] = DateTime.now().toIso8601String();
    list.insert(0, data);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchFeedbacks(String docId) async* {
    yield _localFeedbacks[docId] ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFeedbacks(String docId) async {
    return _localFeedbacks[docId] ?? [];
  }

  static final Map<String, List<Map<String, dynamic>>> _localGallery = {};

  @override
  Future<void> addGalleryPhoto(
    String docId,
    Map<String, dynamic> photoData,
  ) async {
    final list = _localGallery.putIfAbsent(docId, () => []);
    final data = Map<String, dynamic>.from(photoData);
    data['id'] = data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    data['timestamp'] =
        data['timestamp'] ?? DateTime.now().toIso8601String();
    data['createdAt'] = DateTime.now().toIso8601String();
    list.insert(0, data);
  }

  @override
  Future<void> addGalleryPhotos(
    String docId,
    List<Map<String, dynamic>> photosData,
  ) async {
    final list = _localGallery.putIfAbsent(docId, () => []);
    final availableSlots = (80 - list.length).clamp(0, 80);
    if (availableSlots <= 0) return;
    for (final p in photosData.take(availableSlots)) {
      await addGalleryPhoto(docId, p);
    }
  }

  @override
  Future<void> deleteGalleryPhoto(String docId, String photoId) async {
    final list = _localGallery[docId];
    if (list != null) {
      list.removeWhere((item) => item['id'] == photoId);
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchGallery(String docId) async* {
    yield _localGallery[docId] ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGallery(String docId) async {
    return _localGallery[docId] ?? [];
  }
}

/// Active Firebase Firestore Repository integration.
/// Saves profiles to Firestore and retrieves them dynamically on scan.
class FirebaseQrRepository implements QrRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _apiKey = 'AIzaSyBYYtUwfZyW1f53E27HrT3asoLgP_UxJXo';
  static const String _projectId = 'qr-code-generator-d6358';

  static String buildScanUrl(String docId) {
    final uri = Uri.base;

    // Force https and production domain if the page is opened locally as a file (file:// scheme)
    final scheme = (uri.scheme == 'file' || uri.scheme.isEmpty)
        ? 'https'
        : uri.scheme;
    final host = (uri.host.isEmpty || uri.scheme == 'file')
        ? 'contact-us-profile.web.app'
        : uri.host;
    final port = (uri.hasPort && uri.scheme != 'file') ? ':${uri.port}' : '';

    return '$scheme://$host$port/scan?id=$docId';
  }

  static String _extractDocId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'default_profile';

    // 1. Direct Regex match for ?id= or &id= anywhere in the string or hash fragment
    final idMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (idMatch != null && idMatch.group(1)!.isNotEmpty) {
      return idMatch.group(1)!;
    }

    // 2. Parse URI and fragment
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        final idParam = uri.queryParameters['id'];
        if (idParam != null && idParam.isNotEmpty) return idParam;
        if (uri.hasFragment) {
          final fragUri = Uri.parse(uri.fragment);
          final fragId = fragUri.queryParameters['id'];
          if (fragId != null && fragId.isNotEmpty) return fragId;
        }
      } catch (_) {}
    }

    // 3. Fallback
    return trimmed;
  }

  @override
  Future<String> saveProfile(QrProfile profile) async {
    String docId = '';
    String scanUrl = '';
    try {
      final docRef = _firestore.collection('qr_profiles').doc();
      docId = docRef.id;
      scanUrl = buildScanUrl(docId);

      final data = profile.toMap();
      data['id'] = docId;
      data['url'] = scanUrl;
      data['viewCount'] = 0;
      data['createdAt'] = FieldValue.serverTimestamp();
      await docRef.set(data).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint("Firestore SDK save error ($e), attempting REST fallback...");
      try {
        if (docId.isEmpty) {
          docId = DateTime.now().millisecondsSinceEpoch.toString();
          scanUrl = buildScanUrl(docId);
        }
        final restUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles?documentId=$docId&key=$_apiKey',
        );
        final restBody = json.encode({
          'fields': _convertToRestFields({
            ...profile.toMap(),
            'id': docId,
            'url': scanUrl,
            'viewCount': 0,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        });
        await http
            .post(
              restUrl,
              headers: {'Content-Type': 'application/json'},
              body: restBody,
            )
            .timeout(const Duration(seconds: 5));
      } catch (restErr) {
        debugPrint("REST save fallback failed: $restErr");
      }
    }

    if (docId.isNotEmpty) {
      return scanUrl.isNotEmpty ? scanUrl : buildScanUrl(docId);
    } else {
      throw Exception(
        'Failed to generate QR Code. Please check your internet connection.',
      );
    }
  }

  @override
  Future<String> updateProfile(String docId, QrProfile profile) async {
    final scanUrl = buildScanUrl(docId);
    bool updated = false;

    // 1. Try Firestore SDK update with merge option
    try {
      final docRef = _firestore.collection('qr_profiles').doc(docId);
      final data = profile.toMap();
      data['id'] = docId;
      data['url'] = scanUrl;
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['welcomeUrl'] = FieldValue.delete();
      data['wel'] = FieldValue.delete();
      await docRef
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
      updated = true;
    } catch (e) {
      debugPrint(
        "Firestore SDK update error ($e), attempting REST update fallback...",
      );
    }

    // 2. If SDK fails or times out, use Firestore REST API PATCH
    if (!updated) {
      try {
        final patchUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$docId?key=$_apiKey',
        );
        final restBody = json.encode({
          'fields': _convertToRestFields({
            ...profile.toMap(),
            'id': docId,
            'url': scanUrl,
            'updatedAt': DateTime.now().toIso8601String(),
          }),
        });
        final response = await http
            .patch(
              patchUrl,
              headers: {'Content-Type': 'application/json'},
              body: restBody,
            )
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          updated = true;
        }
      } catch (restErr) {
        debugPrint("REST update fallback failed: $restErr");
      }
    }

    return scanUrl;
  }

  @override
  Future<QrProfile> fetchProfile(String identifier) async {
    try {
      String docId = _extractDocId(identifier);
      if (docId == 'default_profile' || docId.contains('data=')) {
        docId = '';
      }

      // 1. Try to fetch from Firestore first if we have a valid document ID
      if (docId.isNotEmpty) {
        try {
          final docSnapshot = await _firestore
              .collection('qr_profiles')
              .doc(docId)
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 3));
          if (docSnapshot.exists && docSnapshot.data() != null) {
            final data = Map<String, dynamic>.from(docSnapshot.data()!);
            data['id'] = docSnapshot.id;
            return QrProfile.fromMap(data);
          }
        } catch (dbError) {
          debugPrint("Firestore SDK fetch error: $dbError. Trying REST...");
          try {
            final restProfile = await _fetchSingleProfileViaRest(docId);
            if (restProfile != null) return restProfile;
          } catch (_) {}

          try {
            final docSnapshot = await _firestore
                .collection('qr_profiles')
                .doc(docId)
                .get(const GetOptions(source: Source.cache));
            if (docSnapshot.exists && docSnapshot.data() != null) {
              final data = Map<String, dynamic>.from(docSnapshot.data()!);
              data['id'] = docSnapshot.id;
              return QrProfile.fromMap(data);
            }
          } catch (_) {}
        }
      }

      // 2. Fallback to decoding the Base64 payload inside the URL parameters if Firestore is offline
      if (identifier.contains('data=')) {
        final uri = Uri.parse(identifier);
        final dataParam = uri.queryParameters['data'];
        if (dataParam != null && dataParam.isNotEmpty) {
          return QrProfile.fromBase64(dataParam);
        }
      }

      // If it is just a raw base64 string, decode it directly
      if (!identifier.startsWith('http://') &&
          !identifier.startsWith('https://') &&
          identifier.length > 20) {
        try {
          final decoded = QrProfile.fromBase64(identifier);
          if (decoded.name.isNotEmpty) {
            return decoded;
          }
        } catch (_) {}
      }

      throw Exception("Profile not found");
    } catch (e) {
      // 3. Last resort fallback parsing of Base64
      try {
        if (identifier.contains('data=')) {
          final uri = Uri.parse(identifier);
          final dataParam = uri.queryParameters['data'];
          if (dataParam != null && dataParam.isNotEmpty) {
            return QrProfile.fromBase64(dataParam);
          }
        }
      } catch (_) {}

      // Fallback default in case of total loading error
      return QrProfile(
        name: 'Error Loading',
        headline: 'Details could not be fetched.',
      );
    }
  }

  @override
  Future<List<SavedQrCode>> fetchAllProfiles() async {
    // 1. High-speed, lightweight masked fetch via Firestore REST API (under 1 second, skips multi-megabyte base64 images)
    try {
      final restList = await _fetchViaRest();
      if (restList.isNotEmpty) {
        await HistoryStorage.saveHistory(restList);
        return restList;
      }
    } catch (restError) {
      debugPrint(
        "Firestore REST fetch error: $restError. Trying Firestore SDK...",
      );
    }

    // 2. Try Firestore SDK fallback with a 6-second timeout
    try {
      final snapshot = await _firestore
          .collection('qr_profiles')
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 6));

      if (snapshot.docs.isNotEmpty) {
        final List<SavedQrCode> list = [];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            final scanUrl = buildScanUrl(doc.id);
            list.add(SavedQrCode.fromFirestoreDoc(doc.id, data, scanUrl));
          } catch (itemError) {
            debugPrint("Error parsing profile doc ${doc.id}: $itemError");
          }
        }
        list.sort((a, b) => b.date.compareTo(a.date));
        await HistoryStorage.saveHistory(list);
        return list;
      }
    } catch (sdkError) {
      debugPrint("Firestore SDK get failed: $sdkError");
    }

    // 3. Fallback to local device storage
    return await HistoryStorage.loadHistory();
  }

  @override
  Stream<List<SavedQrCode>> watchAllProfiles() async* {
    yield await fetchAllProfiles();
  }

  @override
  Future<void> deleteProfile(String id) async {
    // 1. Delete immediately via REST API (bypasses gRPC socket caching)
    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$id?key=$_apiKey',
      );
      await http.delete(url).timeout(const Duration(seconds: 5));
    } catch (restErr) {
      debugPrint("REST delete error: $restErr");
    }

    // 2. Also delete from Firestore SDK local cache & server
    try {
      await _firestore
          .collection('qr_profiles')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 4));
    } catch (sdkErr) {
      debugPrint("Firestore SDK delete note: $sdkErr");
    }
  }

  @override
  Future<void> incrementViewCount(String docId) async {
    if (docId.isEmpty) return;
    bool updated = false;

    // 1. Try Firestore SDK atomic increment
    try {
      final docRef = _firestore.collection('qr_profiles').doc(docId);
      await docRef
          .update({
            'viewCount': FieldValue.increment(1),
            'lastScannedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 4));
      updated = true;
    } catch (e) {
      debugPrint(
        "Firestore SDK incrementViewCount note: $e, trying REST fallback...",
      );
    }

    // 2. If SDK fails or times out, use Firestore REST commit API with field transform
    if (!updated) {
      try {
        final commitUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:commit?key=$_apiKey',
        );
        final body = json.encode({
          'writes': [
            {
              'transform': {
                'document':
                    'projects/$_projectId/databases/(default)/documents/qr_profiles/$docId',
                'fieldTransforms': [
                  {
                    'fieldPath': 'viewCount',
                    'increment': {'integerValue': '1'},
                  },
                  {
                    'fieldPath': 'lastScannedAt',
                    'setToServerValue': 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        });

        final response = await http
            .post(
              commitUrl,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          updated = true;
        }
      } catch (restErr) {
        debugPrint("REST incrementViewCount fallback failed: $restErr");
      }
    }
  }

  @override
  Future<void> incrementTabClick(String docId, String tabType) async {
    final validDocId = docId.trim().isNotEmpty
        ? docId.trim()
        : 'default_profile';
    if (tabType.trim().isEmpty) return;
    final sanitizedType = tabType
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase();
    bool updated = false;

    // 1. Primary: Firestore SDK atomic increment with SetOptions(merge: true)
    try {
      final docRef = _firestore.collection('qr_profiles').doc(validDocId);
      await docRef
          .set({
            'tabClicks': {sanitizedType: FieldValue.increment(1)},
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
      updated = true;
    } catch (e) {
      debugPrint(
        "Firestore SDK incrementTabClick note: $e, trying REST fallback...",
      );
    }

    // 2. REST commit API fallback with fieldTransforms
    if (!updated) {
      try {
        final commitUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:commit?key=$_apiKey',
        );
        final body = json.encode({
          'writes': [
            {
              'transform': {
                'document':
                    'projects/$_projectId/databases/(default)/documents/qr_profiles/$validDocId',
                'fieldTransforms': [
                  {
                    'fieldPath': 'tabClicks.$sanitizedType',
                    'increment': {'integerValue': '1'},
                  },
                ],
              },
            },
          ],
        });

        final response = await http
            .post(
              commitUrl,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          updated = true;
        }
      } catch (restErr) {
        debugPrint("REST incrementTabClick fallback failed: $restErr");
      }
    }
  }

  @override
  Future<void> submitFeedback(
    String docId,
    Map<String, dynamic> feedback,
  ) async {
    final validDocId = _extractDocId(docId);
    bool saved = false;

    final feedbackData = Map<String, dynamic>.from(feedback);
    feedbackData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    feedbackData['profileId'] = validDocId;
    feedbackData['timestamp'] =
        feedback['timestamp'] ?? DateTime.now().toIso8601String();
    feedbackData['createdAt'] = DateTime.now().toIso8601String();

    // 1. Primary: Save atomically to feedbackList array on qr_profiles/{validDocId}
    try {
      final docRef = _firestore.collection('qr_profiles').doc(validDocId);
      await docRef
          .set({
            'feedbackList': FieldValue.arrayUnion([feedbackData]),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
      saved = true;
    } catch (e) {
      debugPrint("Firestore SDK submitFeedback note: $e, trying REST...");
    }

    // 2. REST API fallback if SDK fails or times out
    if (!saved) {
      try {
        final currentList = await fetchFeedbacks(validDocId);
        currentList.insert(0, feedbackData);

        final patchUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$validDocId?updateMask.fieldPaths=feedbackList&key=$_apiKey',
        );
        final patchBody = json.encode({
          'fields': _convertToRestFields({'feedbackList': currentList}),
        });

        final patchResp = await http
            .patch(
              patchUrl,
              headers: {'Content-Type': 'application/json'},
              body: patchBody,
            )
            .timeout(const Duration(seconds: 5));

        if (patchResp.statusCode == 200) {
          saved = true;
        }
      } catch (restErr) {
        debugPrint("REST submitFeedback fallback error: $restErr");
      }
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchFeedbacks(String docId) async* {
    final validDocId = _extractDocId(docId);

    // 1. Immediately yield current feedbacks from server/REST/cache
    List<Map<String, dynamic>> currentFeedbacks =
        await fetchFeedbacks(validDocId);
    yield currentFeedbacks;

    // 2. Stream real-time updates from Firestore qr_profiles/{validDocId} document
    try {
      final snapshotStream = _firestore
          .collection('qr_profiles')
          .doc(validDocId)
          .snapshots();

      await for (final snapshot in snapshotStream) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final rawList = data['feedbackList'];
          if (rawList is List && rawList.isNotEmpty) {
            final List<Map<String, dynamic>> list = [];
            for (final item in rawList) {
              if (item is Map) {
                list.add(Map<String, dynamic>.from(item));
              }
            }
            list.sort((a, b) {
              final aTime = a['createdAt'] ?? a['timestamp'] ?? '';
              final bTime = b['createdAt'] ?? b['timestamp'] ?? '';
              return bTime.toString().compareTo(aTime.toString());
            });
            currentFeedbacks = list;
            yield list;
          } else if (currentFeedbacks.isNotEmpty) {
            // Keep existing non-empty feedbacks if local cache emits an empty document
            yield currentFeedbacks;
          } else {
            yield [];
          }
        }
      }
    } catch (e) {
      debugPrint("Firestore snapshots stream note: $e, maintaining feedbacks.");
      yield currentFeedbacks;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFeedbacks(String docId) async {
    final validDocId = _extractDocId(docId);

    // 1. Try Firestore SDK
    try {
      final snapshot = await _firestore
          .collection('qr_profiles')
          .doc(validDocId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final rawList = data['feedbackList'];
        if (rawList is List && rawList.isNotEmpty) {
          final List<Map<String, dynamic>> list = [];
          for (final item in rawList) {
            if (item is Map) {
              list.add(Map<String, dynamic>.from(item));
            }
          }
          list.sort((a, b) {
            final aTime = a['createdAt'] ?? a['timestamp'] ?? '';
            final bTime = b['createdAt'] ?? b['timestamp'] ?? '';
            return bTime.toString().compareTo(aTime.toString());
          });
          return list;
        }
      }
    } catch (e) {
      debugPrint("Firestore SDK fetchFeedbacks note: $e. Trying REST...");
    }

    // 2. REST API fallback
    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$validDocId?key=$_apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final doc = json.decode(response.body);
        final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
        if (fields['feedbackList'] != null &&
            fields['feedbackList']['arrayValue'] != null) {
          final values =
              fields['feedbackList']['arrayValue']['values'] as List? ?? [];
          final List<Map<String, dynamic>> list = [];
          for (final v in values) {
            if (v is Map && v['mapValue'] != null) {
              final subFields =
                  (v['mapValue']['fields'] as Map<String, dynamic>?) ?? {};
              list.add(_convertRestFields(subFields));
            }
          }
          list.sort((a, b) {
            final aTime = a['createdAt'] ?? a['timestamp'] ?? '';
            final bTime = b['createdAt'] ?? b['timestamp'] ?? '';
            return bTime.toString().compareTo(aTime.toString());
          });
          return list;
        }
      }
    } catch (restErr) {
      debugPrint("REST fetchFeedbacks error: $restErr");
    }

    return [];
  }

  @override
  Future<void> addGalleryPhotos(
    String docId,
    List<Map<String, dynamic>> photosData,
  ) async {
    if (photosData.isEmpty) return;
    final validDocId = _extractDocId(docId);
    final currentExisting = await fetchGallery(validDocId);
    final availableSlots = (80 - currentExisting.length).clamp(0, 80);
    if (availableSlots <= 0) return;
    final allowedPhotosData = photosData.take(availableSlots).toList();
    bool saved = false;

    final List<Map<String, dynamic>> items = [];
    final now = DateTime.now();
    for (int i = 0; i < allowedPhotosData.length; i++) {
      final p = allowedPhotosData[i];
      final item = Map<String, dynamic>.from(p);
      final photoId = item['id']?.toString().isNotEmpty == true
          ? item['id'].toString()
          : '${now.millisecondsSinceEpoch}_$i';
      item['id'] = photoId;
      item['profileId'] = validDocId;
      item['timestamp'] = p['timestamp'] ?? now.toIso8601String();
      item['createdAt'] = now.toIso8601String();
      items.add(item);
    }

    // 1. Primary: Write to Firestore Subcollection using Batch
    try {
      final batch = _firestore.batch();
      for (final item in items) {
        final photoId = item['id'].toString();
        final docRef = _firestore
            .collection('qr_profiles')
            .doc(validDocId)
            .collection('gallery')
            .doc(photoId);
        batch.set(docRef, item);
      }
      await batch.commit().timeout(const Duration(seconds: 10));
      saved = true;
    } catch (e) {
      debugPrint("Firestore SDK subcollection batch write note: $e, trying single writes / REST...");
    }

    // 2. Fallback: individual doc writes if batch fails
    if (!saved) {
      for (final item in items) {
        try {
          final photoId = item['id'].toString();
          await _firestore
              .collection('qr_profiles')
              .doc(validDocId)
              .collection('gallery')
              .doc(photoId)
              .set(item)
              .timeout(const Duration(seconds: 4));
          saved = true;
        } catch (_) {}
      }
    }

    // 3. Fallback: REST API for Subcollection
    if (!saved) {
      for (final item in items) {
        try {
          final photoId = item['id'].toString();
          final postUrl = Uri.parse(
            'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$validDocId/gallery?documentId=$photoId&key=$_apiKey',
          );
          final postBody = json.encode({
            'fields': _convertToRestFields(item),
          });
          final resp = await http
              .post(
                postUrl,
                headers: {'Content-Type': 'application/json'},
                body: postBody,
              )
              .timeout(const Duration(seconds: 6));
          if (resp.statusCode == 200) {
            saved = true;
          }
        } catch (restErr) {
          debugPrint("REST subcollection write error: $restErr");
        }
      }
    }
  }

  @override
  Future<void> addGalleryPhoto(
    String docId,
    Map<String, dynamic> photoData,
  ) async {
    await addGalleryPhotos(docId, [photoData]);
  }

  @override
  Future<void> deleteGalleryPhoto(
    String docId,
    String photoId,
  ) async {
    final validDocId = _extractDocId(docId);
    bool deleted = false;

    // 1. Delete from Firestore Subcollection
    try {
      await _firestore
          .collection('qr_profiles')
          .doc(validDocId)
          .collection('gallery')
          .doc(photoId)
          .delete()
          .timeout(const Duration(seconds: 4));
      deleted = true;
    } catch (e) {
      debugPrint("Firestore SDK deleteGalleryPhoto subcollection note: $e, trying REST...");
    }

    // 2. Also check and remove from legacy galleryList array in parent document if present
    try {
      final docRef = _firestore.collection('qr_profiles').doc(validDocId);
      final docSnap = await docRef
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 3));
      if (docSnap.exists && docSnap.data()?['galleryList'] is List) {
        final currentLegacy = List<Map<String, dynamic>>.from(
          (docSnap.data()!['galleryList'] as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m)),
        );
        final filteredLegacy =
            currentLegacy.where((item) => item['id'] != photoId).toList();
        if (filteredLegacy.length != currentLegacy.length) {
          await docRef
              .update({'galleryList': filteredLegacy})
              .timeout(const Duration(seconds: 3));
        }
      }
    } catch (_) {}

    // 3. Fallback: REST delete for Subcollection
    if (!deleted) {
      try {
        final deleteUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$validDocId/gallery/$photoId?key=$_apiKey',
        );
        await http.delete(deleteUrl).timeout(const Duration(seconds: 5));
      } catch (restErr) {
        debugPrint("REST deleteGalleryPhoto subcollection error: $restErr");
      }
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchGallery(String docId) async* {
    final validDocId = _extractDocId(docId);
    List<Map<String, dynamic>> currentGallery = await fetchGallery(validDocId);
    yield currentGallery;

    try {
      final subcolStream = _firestore
          .collection('qr_profiles')
          .doc(validDocId)
          .collection('gallery')
          .snapshots();

      await for (final snapshot in subcolStream) {
        final Map<String, Map<String, dynamic>> photoMap = {};
        for (final doc in snapshot.docs) {
          final map = Map<String, dynamic>.from(doc.data());
          map['id'] = map['id'] ?? doc.id;
          photoMap[doc.id] = map;
        }

        // If subcollection has photos or if there are legacy photos
        if (snapshot.docs.isEmpty) {
          for (final legacy in currentGallery) {
            final id = legacy['id']?.toString() ?? '';
            if (id.isNotEmpty && !photoMap.containsKey(id)) {
              photoMap[id] = legacy;
            }
          }
        }

        final list = photoMap.values.toList();
        list.sort((a, b) {
          final aTime = a['createdAt'] ?? a['timestamp'] ?? '';
          final bTime = b['createdAt'] ?? b['timestamp'] ?? '';
          return bTime.toString().compareTo(aTime.toString());
        });
        currentGallery = list;
        yield list;
      }
    } catch (e) {
      debugPrint("Firestore watchGallery subcollection stream note: $e");
      yield currentGallery;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGallery(String docId) async {
    final validDocId = _extractDocId(docId);
    final Map<String, Map<String, dynamic>> photoMap = {};

    // 1. Fetch from Subcollection: qr_profiles/{validDocId}/gallery
    try {
      final subcol = await _firestore
          .collection('qr_profiles')
          .doc(validDocId)
          .collection('gallery')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));

      for (final doc in subcol.docs) {
        final data = doc.data();
        final id = doc.id;
        final map = Map<String, dynamic>.from(data);
        map['id'] = map['id'] ?? id;
        photoMap[id] = map;
      }
    } catch (e) {
      debugPrint("Firestore SDK fetchGallery subcollection note: $e. Trying legacy & REST...");
    }

    // 2. Backward compatibility: also check legacy galleryList array in parent document
    try {
      final doc = await _firestore
          .collection('qr_profiles')
          .doc(validDocId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        final rawList = doc.data()!['galleryList'];
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final id = map['id']?.toString() ?? '';
              if (id.isNotEmpty && !photoMap.containsKey(id)) {
                photoMap[id] = map;
              }
            }
          }
        }
      }
    } catch (_) {}

    // 3. REST fallback for subcollection if photoMap is empty
    if (photoMap.isEmpty) {
      try {
        final listUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$validDocId/gallery?key=$_apiKey',
        );
        final resp = await http.get(listUrl).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final body = json.decode(resp.body);
          final docs = body['documents'] as List? ?? [];
          for (final d in docs) {
            if (d is Map && d['fields'] != null) {
              final fields = d['fields'] as Map<String, dynamic>;
              final map = _convertRestFields(fields);
              final docPath = d['name']?.toString() ?? '';
              final id = docPath.split('/').last;
              map['id'] = map['id'] ?? id;
              photoMap[id] = map;
            }
          }
        }
      } catch (restErr) {
        debugPrint("REST fetchGallery subcollection error: $restErr");
      }
    }

    final list = photoMap.values.toList();
    list.sort((a, b) {
      final aTime = a['createdAt'] ?? a['timestamp'] ?? '';
      final bTime = b['createdAt'] ?? b['timestamp'] ?? '';
      return bTime.toString().compareTo(aTime.toString());
    });
    return list;
  }

  // --- REST API Helpers ---

  Future<List<SavedQrCode>> _fetchViaRest() async {
    final fields = [
      'n',
      'name',
      'c',
      'themeColor',
      'h',
      'headline',
      'qn',
      'qrName',
      'url',
      'createdAt',
      'feedback',
      'fbk',
      'gallery',
      'gal',
      'protectionPassword',
      'p',
      'w',
      'whatsapp',
      'wa',
      'phone',
      'phoneNumber',
      'i',
      'instagram',
      'f',
      'facebook',
      'y',
      'youtube',
      'g',
      'googleReview',
      'loc',
      'locationShare',
      'con',
      'contactUs',
      'profile',
      'viewCount',
      'scanCount',
      'views',
      'vc',
      'tabClicks',
      'tc',
    ];
    final maskParams = fields.map((f) => 'mask.fieldPaths=$f').join('&');

    final List<SavedQrCode> list = [];
    String? pageToken;

    // Follow all pages in Firestore until complete collection is retrieved
    do {
      String urlStr =
          'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles?pageSize=300&$maskParams&key=$_apiKey';
      if (pageToken != null && pageToken.isNotEmpty) {
        urlStr += '&pageToken=$pageToken';
      }

      final response = await http
          .get(Uri.parse(urlStr))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('REST API returned status ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final List<dynamic> documents = data['documents'] ?? [];

      for (final doc in documents) {
        try {
          final docPath = doc['name'] as String;
          final docId = docPath.split('/').last;
          final docFields = (doc['fields'] as Map<String, dynamic>?) ?? {};

          final parsedFields = _convertRestFields(docFields);
          if (doc['createTime'] != null &&
              !parsedFields.containsKey('createTime')) {
            parsedFields['createTime'] = doc['createTime'];
          }

          final scanUrl = buildScanUrl(docId);
          list.add(SavedQrCode.fromFirestoreDoc(docId, parsedFields, scanUrl));
        } catch (e) {
          debugPrint("Error parsing REST document: $e");
        }
      }

      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<QrProfile?> _fetchSingleProfileViaRest(String docId) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/qr_profiles/$docId?key=$_apiKey',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final doc = json.decode(response.body);
      final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
      final parsed = _convertRestFields(fields);
      parsed['id'] = docId;
      return QrProfile.fromMap(parsed);
    }
    return null;
  }

  Map<String, dynamic> _convertRestFields(Map<String, dynamic> fields) {
    final Map<String, dynamic> result = {};
    fields.forEach((key, val) {
      if (val is Map) {
        if (val.containsKey('stringValue')) {
          result[key] = val['stringValue'];
        } else if (val.containsKey('doubleValue')) {
          result[key] = (val['doubleValue'] as num).toDouble();
        } else if (val.containsKey('integerValue')) {
          result[key] = int.tryParse(val['integerValue'].toString()) ?? 0;
        } else if (val.containsKey('booleanValue')) {
          result[key] = val['booleanValue'] == true;
        } else if (val.containsKey('timestampValue')) {
          result[key] = val['timestampValue'];
        } else if (val.containsKey('mapValue')) {
          final subfields =
              (val['mapValue']['fields'] as Map<String, dynamic>?) ?? {};
          result[key] = _convertRestFields(subfields);
        } else if (val.containsKey('arrayValue')) {
          final items = (val['arrayValue']['values'] as List?) ?? [];
          result[key] = items.map((item) {
            if (item is Map && item.containsKey('mapValue')) {
              final sub =
                  (item['mapValue']['fields'] as Map<String, dynamic>?) ?? {};
              return _convertRestFields(sub);
            } else if (item is Map && item.containsKey('stringValue')) {
              return item['stringValue'];
            }
            return item;
          }).toList();
        }
      }
    });
    return result;
  }

  Map<String, dynamic> _convertToRestFields(Map<String, dynamic> map) {
    final Map<String, dynamic> fields = {};
    map.forEach((key, value) {
      if (value == null) {
        fields[key] = {'nullValue': null};
      } else if (value is String) {
        fields[key] = {'stringValue': value};
      } else if (value is bool) {
        fields[key] = {'booleanValue': value};
      } else if (value is num) {
        if (value.toInt() == value) {
          fields[key] = {'integerValue': value.toInt().toString()};
        } else {
          fields[key] = {'doubleValue': value.toDouble()};
        }
      } else if (value is List) {
        final listValues = value.map((v) {
          if (v is Map<String, dynamic>) {
            return {
              'mapValue': {'fields': _convertToRestFields(v)},
            };
          } else if (v is String) {
            return {'stringValue': v};
          } else if (v is num) {
            return {'integerValue': v.toInt().toString()};
          }
          return {'stringValue': v.toString()};
        }).toList();
        fields[key] = {
          'arrayValue': {'values': listValues},
        };
      } else if (value is Map<String, dynamic>) {
        fields[key] = {
          'mapValue': {'fields': _convertToRestFields(value)},
        };
      }
    });
    return fields;
  }
}
