// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

class UserClickTrackerPlatform {
  static final Set<String> _clickedKeys = {};
  static bool _loaded = false;
  static const String _storageKey = 'qr_user_clicked_tabs';

  static String _buildKey(String docId, String tabType) {
    final cleanDoc = docId.trim().isEmpty ? 'default_profile' : docId.trim();
    final cleanTab =
        tabType.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    return '$cleanDoc:$cleanTab';
  }

  static void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = html.window.localStorage[_storageKey];
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        _clickedKeys.addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}
  }

  static Future<void> init() async {
    _ensureLoaded();
  }

  static bool hasClicked(String docId, String tabType) {
    _ensureLoaded();
    return _clickedKeys.contains(_buildKey(docId, tabType));
  }

  static Future<bool> recordClickOnce(String docId, String tabType) async {
    _ensureLoaded();
    final key = _buildKey(docId, tabType);
    if (_clickedKeys.contains(key)) {
      return false;
    }
    _clickedKeys.add(key);
    try {
      html.window.localStorage[_storageKey] =
          json.encode(_clickedKeys.toList());
    } catch (_) {}
    return true;
  }
}
