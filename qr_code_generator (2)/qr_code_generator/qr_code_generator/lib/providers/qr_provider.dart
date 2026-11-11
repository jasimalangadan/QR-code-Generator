import 'package:flutter/material.dart';
import '../models/qr_profile.dart';
import '../models/saved_qr_code.dart';
import '../repositories/qr_repository.dart';
import '../utils/history_storage.dart';

class QrProvider with ChangeNotifier {
  final QrRepository _repository;
  QrRepository get repository => _repository;

  QrProvider({required QrRepository repository}) : _repository = repository;

  QrProfile _profile = QrProfile();
  QrProfile get profile => _profile;

  String? _generatedUrl;
  String? get generatedUrl => _generatedUrl;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Progress indicators matching the layout
  int get completedSteps {
    int steps = 0;
    // Step 1: Profile Name entered
    if (_profile.name.trim().isNotEmpty) steps++;
    // Step 2: At least one brand redirection link added (Instagram, Google Review, WhatsApp, WhatsApp Group, Facebook, YouTube, Website)
    if (_profile.instagram.trim().isNotEmpty ||
        _profile.telegram.trim().isNotEmpty ||
        _profile.whatsapp.trim().isNotEmpty ||
        _profile.whatsappGroup.trim().isNotEmpty ||
        _profile.googleReview.trim().isNotEmpty ||
        _profile.facebook.trim().isNotEmpty ||
        _profile.youtube.trim().isNotEmpty ||
        _profile.linkedin.trim().isNotEmpty ||
        _profile.email.trim().isNotEmpty ||
        _profile.tiktok.trim().isNotEmpty ||
        _profile.xTwitter.trim().isNotEmpty ||
        _profile.threads.trim().isNotEmpty ||
        _profile.pinterest.trim().isNotEmpty ||
        _profile.customLinkUrl.trim().isNotEmpty ||
        _profile.feedback.trim().isNotEmpty ||
        _profile.locationShare.trim().isNotEmpty ||
        _profile.contactUs.trim().isNotEmpty) {
      steps++;
    }
    return steps;
  }

  double get progressPercentage => completedSteps / 2.0;

  bool get canGenerate => completedSteps >= 2;

  // -- State Updates --

  void updateThemeColor(String colorHex) {
    _profile = _profile.copyWith(themeColor: colorHex);
    notifyListeners();
  }

  void updateBackgroundBrightness(double brightness) {
    _profile = _profile.copyWith(backgroundBrightness: brightness);
    notifyListeners();
  }

  void updateBasicInfo({required String name, String headline = ''}) {
    _profile = _profile.copyWith(name: name, headline: headline);
    notifyListeners();
  }

  void updateProfileImages({
    required String avatarUrl,
    required String bannerUrl,
  }) {
    _profile = _profile.copyWith(avatarUrl: avatarUrl, bannerUrl: bannerUrl);
    notifyListeners();
  }

  void updateAvatarBorderColor(String colorHex) {
    _profile = _profile.copyWith(avatarBorderColor: colorHex);
    notifyListeners();
  }

  void updateAvatarBorderWidth(double width) {
    _profile = _profile.copyWith(avatarBorderWidth: width);
    notifyListeners();
  }

  void updateAvatarPosition(String position) {
    _profile = _profile.copyWith(avatarPosition: position);
    notifyListeners();
  }

  void updateCustomLink({required String label, required String url}) {
    _profile = _profile.copyWith(customLinkLabel: label, customLinkUrl: url);
    notifyListeners();
  }

  void updateSocialNetworks({
    required String instagram,
    List<String>? instagramList,
    String telegram = '',
    required String googleReview,
    required String whatsapp,
    List<String>? whatsappList,
    required String whatsappGroup,
    required String facebook,
    required String youtube,
    String linkedin = '',
    String email = '',
    String tiktok = '',
    String xTwitter = '',
    String threads = '',
    String pinterest = '',
    String locationShare = '',
    String contactUs = '',
    List<String>? contactList,
    String customLinkUrl = '',
    String customLinkLabel = 'Website',
    String feedback = '',
    String gallery = '',
    String protectionPassword = '',
  }) {
    _profile = _profile.copyWith(
      instagram: instagram,
      instagramList: instagramList,
      telegram: telegram,
      googleReview: googleReview,
      whatsapp: whatsapp,
      whatsappList: whatsappList,
      whatsappGroup: whatsappGroup,
      facebook: facebook,
      youtube: youtube,
      linkedin: linkedin,
      email: email,
      tiktok: tiktok,
      xTwitter: xTwitter,
      threads: threads,
      pinterest: pinterest,
      locationShare: locationShare,
      contactUs: contactUs,
      contactList: contactList,
      customLinkUrl: customLinkUrl,
      customLinkLabel: customLinkLabel,
      feedback: feedback,
      gallery: gallery,
      protectionPassword: protectionPassword.isNotEmpty
          ? protectionPassword
          : _profile.protectionPassword,
    );
    notifyListeners();
  }

  void updateProtectionPassword(String password) {
    _profile = _profile.copyWith(protectionPassword: password);
    notifyListeners();
  }

  void updateAdvancedSettings({
    required String qrName,
    required String password,
  }) {
    _profile = _profile.copyWith(qrName: qrName, protectionPassword: password);
    notifyListeners();
  }

  // -- Operations --

  Future<void> generateQrCode({String? existingDocId}) async {
    if (!canGenerate) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (existingDocId != null && existingDocId.isNotEmpty) {
        final url = await _repository.updateProfile(existingDocId, _profile);
        _generatedUrl = url;
      } else {
        final url = await _repository.saveProfile(_profile);
        _generatedUrl = url;
      }
    } catch (e) {
      debugPrint("Error generating/updating QR code: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQrCode(String existingDocId) async {
    return generateQrCode(existingDocId: existingDocId);
  }

  void clearGeneration() {
    _generatedUrl = null;
    notifyListeners();
  }

  void loadProfile(QrProfile profile) {
    _profile = profile;
    _generatedUrl = null;
    notifyListeners();
  }

  void resetAll() {
    _profile = QrProfile();
    _generatedUrl = null;
    _isLoading = false;
    notifyListeners();
  }

  // -- Saved QR Codes (Firebase & Local) --

  List<SavedQrCode> _savedQrCodes = [];
  List<SavedQrCode> get savedQrCodes => _savedQrCodes;

  bool _isLoadingSaved = false;
  bool get isLoadingSaved => _isLoadingSaved;

  Stream<List<SavedQrCode>> watchSavedQrCodes() {
    return _repository.watchAllProfiles();
  }

  Future<List<SavedQrCode>> fetchSavedQrCodes() async {
    _isLoadingSaved = true;
    notifyListeners();
    try {
      final list = await _repository.fetchAllProfiles();
      _savedQrCodes = list;
      await HistoryStorage.saveHistory(list);
      return list;
    } catch (e) {
      debugPrint("Error fetching saved QR codes from Firebase: $e");
      final local = await HistoryStorage.loadHistory();
      _savedQrCodes = local;
      return local;
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  Future<void> deleteSavedQrCode(String id) async {
    try {
      await _repository.deleteProfile(id);
    } catch (e) {
      debugPrint("Error deleting QR code from repository: $e");
    }
    await HistoryStorage.deleteQrCode(id);
    _savedQrCodes.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}

