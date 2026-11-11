import 'user_click_tracker_io.dart'
    if (dart.library.html) 'user_click_tracker_web.dart';

class UserClickTracker {
  /// Pre-loads any previously recorded card clicks for this user.
  static Future<void> init() => UserClickTrackerPlatform.init();

  /// Returns true if the user has already clicked this specific card for this profile.
  static bool hasClicked(String docId, String tabType) =>
      UserClickTrackerPlatform.hasClicked(docId, tabType);

  /// Records the click if it has not been recorded before.
  /// Returns `true` on the FIRST click (meaning it should increment count).
  /// Returns `false` on SUBSEQUENT clicks by the same user (meaning it should NOT increment).
  static Future<bool> recordClickOnce(String docId, String tabType) =>
      UserClickTrackerPlatform.recordClickOnce(docId, tabType);
}
