import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class UserClickTrackerPlatform {
  static final Set<String> _clickedKeys = {};
  static bool _loaded = false;
  static const String _fileName = 'user_clicked_tabs.json';

  static String _buildKey(String docId, String tabType) {
    final cleanDoc = docId.trim().isEmpty ? 'default_profile' : docId.trim();
    final cleanTab =
        tabType.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    return '$cleanDoc:$cleanTab';
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded || kIsWeb) return;
    _loaded = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = json.decode(content);
        _clickedKeys.addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}
  }

  static Future<void> init() async {
    await _ensureLoaded();
  }

  static bool hasClicked(String docId, String tabType) {
    return _clickedKeys.contains(_buildKey(docId, tabType));
  }

  static Future<bool> recordClickOnce(String docId, String tabType) async {
    await _ensureLoaded();
    final key = _buildKey(docId, tabType);
    if (_clickedKeys.contains(key)) {
      return false;
    }
    _clickedKeys.add(key);
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_fileName');
        await file.writeAsString(json.encode(_clickedKeys.toList()));
      } catch (_) {}
    }
    return true;
  }
}
