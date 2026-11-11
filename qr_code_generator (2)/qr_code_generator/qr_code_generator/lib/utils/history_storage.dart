import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/saved_qr_code.dart';

class HistoryStorage {
  static const String _fileName = 'saved_qrs.json';

  static Future<File?> _getHistoryFile() async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  static Future<List<SavedQrCode>> loadHistory() async {
    try {
      final file = await _getHistoryFile();
      if (file == null || !await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((e) => SavedQrCode.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHistory(List<SavedQrCode> history) async {
    try {
      final file = await _getHistoryFile();
      if (file == null) return;
      final jsonList = history.map((e) => e.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (_) {}
  }

  static Future<void> addQrCode(SavedQrCode qrCode) async {
    final history = await loadHistory();
    // Prevent duplicate URLs, IDs, or identical profiles - if same URL or same profile data exists, replace/update it
    history.removeWhere(
      (item) =>
          item.id == qrCode.id ||
          item.url == qrCode.url ||
          item.profile.toBase64() == qrCode.profile.toBase64(),
    );
    history.insert(0, qrCode); // Insert at beginning of history (newest first)
    await saveHistory(history);
  }

  static Future<void> deleteQrCode(String id) async {
    final history = await loadHistory();
    history.removeWhere((item) => item.id == id);
    await saveHistory(history);
  }
}

