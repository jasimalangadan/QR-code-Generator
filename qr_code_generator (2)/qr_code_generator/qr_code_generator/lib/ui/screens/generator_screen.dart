import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_generator/ui/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/saved_qr_code.dart';
import '../../models/qr_profile.dart';
import '../../providers/qr_provider.dart';
import '../../utils/history_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/image_helper.dart';
import '../widgets/expandable_card.dart';
import '../widgets/google_color_picker.dart';
import 'preview_screen.dart';
import 'saved_qr_codes_screen.dart';
import 'package:country_picker/country_picker.dart';

class PhoneNumberEntry {
  final TextEditingController controller;
  String countryCode;
  String countryFlag;

  PhoneNumberEntry({
    required this.controller,
    this.countryCode = '+91',
    this.countryFlag = '🇮🇳',
  });
}

class GeneratorScreen extends StatefulWidget {
  final bool isClientMode;
  final String? clientDocId;
  final QrProfile? initialProfile;

  const GeneratorScreen({
    super.key,
    this.isClientMode = false,
    this.clientDocId,
    this.initialProfile,
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  // Text Editing Controllers for all expandable card fields
  late TextEditingController _nameController;
  late TextEditingController _telegramController;
  final List<TextEditingController> _instagramControllers = [];
  late final TextEditingController _fallbackInstagramController;
  TextEditingController get _instagramController =>
      _instagramControllers.isNotEmpty
      ? _instagramControllers.first
      : _fallbackInstagramController;
  late TextEditingController _googleReviewController;
  late TextEditingController _whatsappGroupController;
  late TextEditingController _facebookController;
  late TextEditingController _youtubeController;
  late TextEditingController _linkedinController;
  late TextEditingController _emailController;
  late TextEditingController _tiktokController;
  late TextEditingController _xTwitterController;
  late TextEditingController _threadsController;
  late TextEditingController _pinterestController;
  late TextEditingController _websiteController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _bannerUrlController;
  late TextEditingController _locationController;
  late TextEditingController _feedbackController;
  late TextEditingController _galleryController;
  late TextEditingController _protectionPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Phone number entries for up to 5 WhatsApp and 5 Contact numbers
  final List<PhoneNumberEntry> _whatsappEntries = [];
  final List<PhoneNumberEntry> _contactEntries = [];
  late final TextEditingController _fallbackWhatsAppController;
  late final TextEditingController _fallbackContactController;

  TextEditingController get _whatsappController => _whatsappEntries.isNotEmpty
      ? _whatsappEntries.first.controller
      : _fallbackWhatsAppController;
  TextEditingController get _contactUsController => _contactEntries.isNotEmpty
      ? _contactEntries.first.controller
      : _fallbackContactController;

  bool _isAvatarLoading = false;
  bool _isBannerLoading = false;

  // Active Social Media tab in Card 4 (Social Networks)
  String _activeSocialTab = 'instagram';

  bool _isCustomColorPickerOpen = false;
  bool _isAvatarColorPickerOpen = false;

  // Dynamic QR Editing State
  String? _editingDocId;
  String? _editingProfileName;

  Map<String, String> _extractCountryAndNumber(String fullNumber) {
    final trimmed = fullNumber.trim();
    String matchedCode = '';
    String matchedFlag = '';
    String numberBody = trimmed;

    final prefixes = {
      '+91': '🇮🇳',
      '+966': '🇸🇦',
      '+971': '🇦🇪',
      '+974': '🇶🇦',
      '+965': '🇰🇼',
      '+968': '🇴🇲',
      '+973': '🇧🇭',
    };

    for (final entry in prefixes.entries) {
      if (trimmed.startsWith(entry.key)) {
        matchedCode = entry.key;
        matchedFlag = entry.value;
        numberBody = trimmed.substring(entry.key.length);
        break;
      }
    }

    if (matchedCode.isEmpty) {
      try {
        final countryList = CountryService().getAll();
        final sortedList = List<Country>.from(countryList)
          ..sort((a, b) => b.phoneCode.length.compareTo(a.phoneCode.length));

        for (final country in sortedList) {
          final prefixWithPlus = '+${country.phoneCode}';
          final prefixWithoutPlus = country.phoneCode;
          if (trimmed.startsWith(prefixWithPlus)) {
            matchedCode = prefixWithPlus;
            matchedFlag = country.flagEmoji;
            numberBody = trimmed.substring(prefixWithPlus.length);
            break;
          } else if (trimmed.startsWith(prefixWithoutPlus) &&
              trimmed.length > 10) {
            matchedCode = prefixWithPlus;
            matchedFlag = country.flagEmoji;
            numberBody = trimmed.substring(prefixWithoutPlus.length);
            break;
          }
        }
      } catch (e) {
        debugPrint("Error parsing country code: $e");
      }
    }

    return {
      'code': matchedCode.isNotEmpty ? matchedCode : '+91',
      'flag': matchedFlag.isNotEmpty ? matchedFlag : '🇮🇳',
      'number': numberBody,
    };
  }

  void _parseWhatsAppList(List<String> list) {
    for (final e in _whatsappEntries) {
      e.controller.removeListener(_updateSocials);
      e.controller.dispose();
    }
    _whatsappEntries.clear();

    final filtered = list.where((s) => s.trim().isNotEmpty).toList();
    if (filtered.isEmpty) {
      final entry = PhoneNumberEntry(
        controller: TextEditingController(),
        countryCode: '+91',
        countryFlag: '🇮🇳',
      );
      entry.controller.addListener(_updateSocials);
      _whatsappEntries.add(entry);
    } else {
      for (final raw in filtered.take(5)) {
        final res = _extractCountryAndNumber(raw);
        final entry = PhoneNumberEntry(
          controller: TextEditingController(text: res['number']),
          countryCode: res['code']!,
          countryFlag: res['flag']!,
        );
        entry.controller.addListener(_updateSocials);
        _whatsappEntries.add(entry);
      }
    }
  }

  void _parseContactList(List<String> list) {
    for (final e in _contactEntries) {
      e.controller.removeListener(_updateSocials);
      e.controller.dispose();
    }
    _contactEntries.clear();

    final filtered = list.where((s) => s.trim().isNotEmpty).toList();
    if (filtered.isEmpty) {
      final entry = PhoneNumberEntry(
        controller: TextEditingController(),
        countryCode: '+91',
        countryFlag: '🇮🇳',
      );
      entry.controller.addListener(_updateSocials);
      _contactEntries.add(entry);
    } else {
      for (final raw in filtered.take(5)) {
        final res = _extractCountryAndNumber(raw);
        final entry = PhoneNumberEntry(
          controller: TextEditingController(text: res['number']),
          countryCode: res['code']!,
          countryFlag: res['flag']!,
        );
        entry.controller.addListener(_updateSocials);
        _contactEntries.add(entry);
      }
    }
  }

  void _addWhatsAppNumber() {
    if (_whatsappEntries.length >= 5) return;
    setState(() {
      final entry = PhoneNumberEntry(
        controller: TextEditingController(),
        countryCode: _whatsappEntries.isNotEmpty
            ? _whatsappEntries.last.countryCode
            : '+91',
        countryFlag: _whatsappEntries.isNotEmpty
            ? _whatsappEntries.last.countryFlag
            : '🇮🇳',
      );
      entry.controller.addListener(_updateSocials);
      _whatsappEntries.add(entry);
    });
    _updateSocials();
  }

  void _removeWhatsAppNumber(int index) {
    if (_whatsappEntries.length <= 1) {
      setState(() {
        _whatsappEntries.first.controller.clear();
      });
      _updateSocials();
      return;
    }
    setState(() {
      final entry = _whatsappEntries.removeAt(index);
      entry.controller.removeListener(_updateSocials);
      entry.controller.dispose();
    });
    _updateSocials();
  }

  void _addContactNumber() {
    if (_contactEntries.length >= 5) return;
    setState(() {
      final entry = PhoneNumberEntry(
        controller: TextEditingController(),
        countryCode: _contactEntries.isNotEmpty
            ? _contactEntries.last.countryCode
            : '+91',
        countryFlag: _contactEntries.isNotEmpty
            ? _contactEntries.last.countryFlag
            : '🇮🇳',
      );
      entry.controller.addListener(_updateSocials);
      _contactEntries.add(entry);
    });
    _updateSocials();
  }

  void _removeContactNumber(int index) {
    if (_contactEntries.length <= 1) {
      setState(() {
        _contactEntries.first.controller.clear();
      });
      _updateSocials();
      return;
    }
    setState(() {
      final entry = _contactEntries.removeAt(index);
      entry.controller.removeListener(_updateSocials);
      entry.controller.dispose();
    });
    _updateSocials();
  }

  void _parseInstagramList(List<String> list) {
    for (final c in _instagramControllers) {
      c.removeListener(_updateSocials);
      c.dispose();
    }
    _instagramControllers.clear();

    final filtered = list.where((s) => s.trim().isNotEmpty).toList();
    if (filtered.isEmpty) {
      final c = TextEditingController();
      c.addListener(_updateSocials);
      _instagramControllers.add(c);
    } else {
      for (final raw in filtered.take(5)) {
        final c = TextEditingController(text: raw);
        c.addListener(_updateSocials);
        _instagramControllers.add(c);
      }
    }
  }

  void _addInstagramAccount() {
    if (_instagramControllers.length >= 5) return;
    setState(() {
      final c = TextEditingController();
      c.addListener(_updateSocials);
      _instagramControllers.add(c);
    });
    _updateSocials();
  }

  void _removeInstagramAccount(int index) {
    if (_instagramControllers.length <= 1) {
      setState(() {
        _instagramControllers.first.clear();
      });
      _updateSocials();
      return;
    }
    setState(() {
      final c = _instagramControllers.removeAt(index);
      c.removeListener(_updateSocials);
      c.dispose();
    });
    _updateSocials();
  }

  OverlayEntry? _currentToastEntry;

  void _showCustomToast(BuildContext context, String message, bool isSuccess) {
    _currentToastEntry?.remove();
    _currentToastEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 24,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, animValue, child) {
              return Opacity(
                opacity: animValue.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1.0 - animValue) * -30),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isSuccess
                      ? const Color(0xFF25D366)
                      : AppTheme.badgeRedText,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: isSuccess
                        ? const Color(0xFF25D366)
                        : AppTheme.badgeRedText,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _currentToastEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      if (_currentToastEntry == entry) {
        if (entry.mounted) {
          entry.remove();
        }
        _currentToastEntry = null;
      }
    });
  }

  Future<void> _shareQrCode(String qrData, {bool isDownload = false}) async {
    if (mounted) {
      _showCustomToast(
        context,
        isDownload
            ? "Downloading QR Code..."
            : "Generating QR Code for sharing...",
        true,
      );
    }

    if (!kIsWeb) {
      try {
        // 1. Create a QrPainter to render the QR code in memory at Ultra-HD (3000 x 3000 px)
        final qrPainter = QrPainter(
          data: qrData,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.Q,
          gapless: true,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF1A1C29), // Dark color for eyes
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF1A1C29), // Dark color for modules
          ),
        );

        // 2. Render with a white border (quiet zone) at high resolution (HD)
        final double qrSize = 3000.0;
        final double padding = 240.0; // Proportional HD quiet zone
        final double totalSize = qrSize + (padding * 2);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Draw white background
        final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
        canvas.drawRect(Rect.fromLTWH(0, 0, totalSize, totalSize), bgPaint);

        // Translate and draw QR
        canvas.translate(padding, padding);
        qrPainter.paint(canvas, Size(qrSize, qrSize));

        final picture = recorder.endRecording();
        final image = await picture.toImage(
          totalSize.toInt(),
          totalSize.toInt(),
        );
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();

          if (isDownload) {
            const channel = MethodChannel(
              'com.example.qr_code_generator/save_image',
            );
            try {
              final success = await channel.invokeMethod<bool>(
                'saveImageToGallery',
                {'bytes': bytes},
              );
              if (success == true) {
                if (mounted) {
                  _showCustomToast(
                    context,
                    "QR Code downloaded to your Gallery!",
                    true,
                  );
                }
                return;
              }
            } catch (e) {
              debugPrint(
                "Native save failed, falling back to system share sheet: $e",
              );
            }
          }

          // 3. Save to a temporary file
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/qr_code.png');
          await tempFile.writeAsBytes(bytes);

          // 4. Share/download the image file
          await Share.shareXFiles([
            XFile(tempFile.path, mimeType: 'image/png', name: 'qr_code.png'),
          ], subject: 'My QR Code');
          return;
        }
      } catch (e) {
        debugPrint("Error generating/sharing QR image: $e");
      }
    }

    // Fallback: Share just the URL link if image sharing is unsupported or fails
    await Share.share(
      'Scan my QR details here: $qrData',
      subject: 'My Scan Profile',
    );
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<QrProvider>(context, listen: false);

    if (widget.isClientMode && widget.initialProfile != null) {
      provider.loadProfile(widget.initialProfile!);
      _editingDocId = widget.clientDocId ?? widget.initialProfile!.id;
      _editingProfileName = widget.initialProfile!.name.isNotEmpty
          ? widget.initialProfile!.name
          : 'My Profile';
    }

    _nameController = TextEditingController(text: provider.profile.name);
    _fallbackInstagramController = TextEditingController();
    _parseInstagramList(
      provider.profile.instagramList.isNotEmpty
          ? provider.profile.instagramList
          : (provider.profile.instagram.isNotEmpty
                ? [provider.profile.instagram]
                : []),
    );
    _telegramController = TextEditingController(
      text: provider.profile.telegram,
    );
    _googleReviewController = TextEditingController(
      text: provider.profile.googleReview,
    );
    _fallbackWhatsAppController = TextEditingController();
    _fallbackContactController = TextEditingController();

    _parseWhatsAppList(
      provider.profile.whatsappList.isNotEmpty
          ? provider.profile.whatsappList
          : (provider.profile.whatsapp.isNotEmpty
                ? [provider.profile.whatsapp]
                : []),
    );
    _whatsappGroupController = TextEditingController(
      text: provider.profile.whatsappGroup,
    );
    _facebookController = TextEditingController(
      text: provider.profile.facebook,
    );
    _youtubeController = TextEditingController(text: provider.profile.youtube);
    _linkedinController = TextEditingController(
      text: provider.profile.linkedin,
    );
    _emailController = TextEditingController(text: provider.profile.email);
    _tiktokController = TextEditingController(text: provider.profile.tiktok);
    _xTwitterController = TextEditingController(
      text: provider.profile.xTwitter,
    );
    _threadsController = TextEditingController(text: provider.profile.threads);
    _pinterestController = TextEditingController(
      text: provider.profile.pinterest,
    );
    _websiteController = TextEditingController(
      text: provider.profile.customLinkUrl,
    );
    _avatarUrlController = TextEditingController(
      text: provider.profile.avatarUrl,
    );
    _bannerUrlController = TextEditingController(
      text: provider.profile.bannerUrl,
    );
    _locationController = TextEditingController(
      text: provider.profile.locationShare,
    );
    _feedbackController = TextEditingController(
      text: provider.profile.feedback,
    );
    _galleryController = TextEditingController(text: provider.profile.gallery);
    final initialPin = provider.profile.protectionPassword.isNotEmpty
        ? provider.profile.protectionPassword
        : '009009';
    _protectionPasswordController = TextEditingController(text: initialPin);
    _confirmPasswordController = TextEditingController(text: initialPin);
    _parseContactList(
      provider.profile.contactList.isNotEmpty
          ? provider.profile.contactList
          : (provider.profile.contactUs.isNotEmpty
                ? [provider.profile.contactUs]
                : []),
    );

    // Setup listeners to update state dynamically for real-time progress calculations
    _nameController.addListener(_updateBasicInfo);
    _telegramController.addListener(_updateSocials);
    _googleReviewController.addListener(_updateSocials);
    _whatsappGroupController.addListener(_updateSocials);
    _facebookController.addListener(_updateSocials);
    _youtubeController.addListener(_updateSocials);
    _linkedinController.addListener(_updateSocials);
    _emailController.addListener(_updateSocials);
    _tiktokController.addListener(_updateSocials);
    _xTwitterController.addListener(_updateSocials);
    _threadsController.addListener(_updateSocials);
    _pinterestController.addListener(_updateSocials);
    _websiteController.addListener(_updateSocials);
    _locationController.addListener(_updateSocials);
    _feedbackController.addListener(_updateSocials);
    _galleryController.addListener(_updateSocials);
    _protectionPasswordController.addListener(_updateSocials);
    _avatarUrlController.addListener(_updateProfileImages);
    _bannerUrlController.addListener(_updateProfileImages);
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _instagramControllers) {
      c.dispose();
    }
    _fallbackInstagramController.dispose();
    _telegramController.dispose();
    _googleReviewController.dispose();
    for (final e in _whatsappEntries) {
      e.controller.dispose();
    }
    _fallbackWhatsAppController.dispose();
    _whatsappGroupController.dispose();
    _facebookController.dispose();
    _youtubeController.dispose();
    _linkedinController.dispose();
    _emailController.dispose();
    _tiktokController.dispose();
    _xTwitterController.dispose();
    _threadsController.dispose();
    _pinterestController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _feedbackController.dispose();
    _galleryController.dispose();
    _protectionPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final e in _contactEntries) {
      e.controller.dispose();
    }
    _fallbackContactController.dispose();
    _avatarUrlController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  void _updateBasicInfo() {
    context.read<QrProvider>().updateBasicInfo(name: _nameController.text);
  }

  void _updateProfileImages() {
    context.read<QrProvider>().updateProfileImages(
      avatarUrl: _avatarUrlController.text,
      bannerUrl: _bannerUrlController.text,
    );
  }

  void _updateSocials() {
    final List<String> instagramList = _instagramControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final String instagramNum = instagramList.isNotEmpty
        ? instagramList.first
        : '';

    final List<String> whatsappList = [];
    for (final entry in _whatsappEntries) {
      final text = entry.controller.text.trim();
      if (text.isNotEmpty) {
        if (text.startsWith('+')) {
          whatsappList.add(text);
        } else {
          whatsappList.add('${entry.countryCode}$text');
        }
      }
    }
    final String whatsappNum = whatsappList.isNotEmpty
        ? whatsappList.first
        : '';

    final List<String> contactList = [];
    for (final entry in _contactEntries) {
      final text = entry.controller.text.trim();
      if (text.isNotEmpty) {
        if (text.startsWith('+')) {
          contactList.add(text);
        } else {
          contactList.add('${entry.countryCode}$text');
        }
      }
    }
    final String contactNum = contactList.isNotEmpty ? contactList.first : '';

    context.read<QrProvider>().updateSocialNetworks(
      instagram: instagramNum,
      instagramList: instagramList,
      telegram: _telegramController.text.trim(),
      googleReview: _googleReviewController.text,
      whatsapp: whatsappNum,
      whatsappList: whatsappList,
      whatsappGroup: _whatsappGroupController.text,
      facebook: _facebookController.text,
      youtube: _youtubeController.text,
      linkedin: _linkedinController.text,
      email: _emailController.text,
      tiktok: _tiktokController.text,
      xTwitter: _xTwitterController.text,
      threads: _threadsController.text,
      pinterest: _pinterestController.text,
      locationShare: _locationController.text,
      contactUs: contactNum,
      contactList: contactList,
      customLinkUrl: _websiteController.text,
      customLinkLabel: 'Website',
      feedback: _feedbackController.text.trim(),
      gallery: _galleryController.text.trim(),
      protectionPassword: _protectionPasswordController.text.trim(),
    );
  }

  Future<void> _pickImageFromDevice({required bool isAvatar}) async {
    try {
      setState(() {
        if (isAvatar) {
          _isAvatarLoading = true;
        } else {
          _isBannerLoading = true;
        }
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        setState(() {
          if (isAvatar) {
            _isAvatarLoading = false;
          } else {
            _isBannerLoading = false;
          }
        });
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      // Compress and resize with higher limits for superior clarity on high-DPI/Retina displays:
      // Avatar: max 600x600 pixels. Banner: max 1200x600 pixels.
      final int maxWidth = isAvatar ? 600 : 1200;
      final int maxHeight = isAvatar ? 600 : 600;

      final compressedBytes = ImageHelper.compressAndResize(
        bytes,
        maxWidth,
        maxHeight,
      );
      final base64String = ImageHelper.convertToBase64DataUrl(compressedBytes);

      setState(() {
        if (isAvatar) {
          _avatarUrlController.text = base64String;
          _isAvatarLoading = false;
        } else {
          _bannerUrlController.text = base64String;
          _isBannerLoading = false;
        }
      });

      _updateProfileImages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvatar
                  ? 'Avatar selected successfully!'
                  : 'Banner background selected successfully!',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        if (isAvatar) {
          _isAvatarLoading = false;
        } else {
          _isBannerLoading = false;
        }
      });
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _loadProfileIntoForm(QrProfile profile) {
    context.read<QrProvider>().loadProfile(profile);

    // Temporarily remove listeners to prevent feedback loops
    _nameController.removeListener(_updateBasicInfo);
    _telegramController.removeListener(_updateSocials);
    for (final c in _instagramControllers) {
      c.removeListener(_updateSocials);
    }
    _googleReviewController.removeListener(_updateSocials);
    for (final e in _whatsappEntries) {
      e.controller.removeListener(_updateSocials);
    }
    _whatsappGroupController.removeListener(_updateSocials);
    _facebookController.removeListener(_updateSocials);
    _youtubeController.removeListener(_updateSocials);
    _linkedinController.removeListener(_updateSocials);
    _emailController.removeListener(_updateSocials);
    _tiktokController.removeListener(_updateSocials);
    _xTwitterController.removeListener(_updateSocials);
    _threadsController.removeListener(_updateSocials);
    _websiteController.removeListener(_updateSocials);
    _locationController.removeListener(_updateSocials);
    _feedbackController.removeListener(_updateSocials);
    _galleryController.removeListener(_updateSocials);
    _protectionPasswordController.removeListener(_updateSocials);
    for (final e in _contactEntries) {
      e.controller.removeListener(_updateSocials);
    }
    _avatarUrlController.removeListener(_updateProfileImages);
    _bannerUrlController.removeListener(_updateProfileImages);

    _nameController.text = profile.name;
    _parseInstagramList(
      profile.instagramList.isNotEmpty
          ? profile.instagramList
          : (profile.instagram.isNotEmpty ? [profile.instagram] : []),
    );
    _telegramController.text = profile.telegram;
    _googleReviewController.text = profile.googleReview;
    _parseWhatsAppList(
      profile.whatsappList.isNotEmpty
          ? profile.whatsappList
          : (profile.whatsapp.isNotEmpty ? [profile.whatsapp] : []),
    );
    _whatsappGroupController.text = profile.whatsappGroup;
    _facebookController.text = profile.facebook;
    _youtubeController.text = profile.youtube;
    _linkedinController.text = profile.linkedin;
    _emailController.text = profile.email;
    _tiktokController.text = profile.tiktok;
    _xTwitterController.text = profile.xTwitter;
    _threadsController.text = profile.threads;
    _websiteController.text = profile.customLinkUrl;
    _locationController.text = profile.locationShare;
    _feedbackController.text = profile.feedback;
    _galleryController.text = profile.gallery;
    final loadedPin = profile.protectionPassword.isNotEmpty
        ? profile.protectionPassword
        : '009009';
    _protectionPasswordController.text = loadedPin;
    _confirmPasswordController.text = loadedPin;
    _parseContactList(
      profile.contactList.isNotEmpty
          ? profile.contactList
          : (profile.contactUs.isNotEmpty ? [profile.contactUs] : []),
    );
    _avatarUrlController.text = profile.avatarUrl;
    _bannerUrlController.text = profile.bannerUrl;

    // Re-attach listeners
    _nameController.addListener(_updateBasicInfo);
    _telegramController.addListener(_updateSocials);
    _googleReviewController.addListener(_updateSocials);
    _whatsappGroupController.addListener(_updateSocials);
    _facebookController.addListener(_updateSocials);
    _youtubeController.addListener(_updateSocials);
    _linkedinController.addListener(_updateSocials);
    _emailController.addListener(_updateSocials);
    _tiktokController.addListener(_updateSocials);
    _xTwitterController.addListener(_updateSocials);
    _threadsController.addListener(_updateSocials);
    _websiteController.addListener(_updateSocials);
    _locationController.addListener(_updateSocials);
    _feedbackController.addListener(_updateSocials);
    _avatarUrlController.addListener(_updateProfileImages);
    _bannerUrlController.addListener(_updateProfileImages);

    setState(() {});
  }

  void _openSavedQrCodesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedQrCodesScreen()),
    );

    if (result != null && mounted) {
      QrProfile profileToLoad;
      String? docId;
      String displayName = 'Selected';

      if (result is SavedQrCode) {
        profileToLoad = result.profile;
        docId = result.id;
        displayName = result.name.isNotEmpty
            ? result.name
            : (profileToLoad.name.isNotEmpty ? profileToLoad.name : 'Selected');
      } else if (result is QrProfile) {
        profileToLoad = result;
        displayName = profileToLoad.name.isNotEmpty
            ? profileToLoad.name
            : 'Selected';
      } else {
        return;
      }

      setState(() {
        _editingDocId = docId;
        _editingProfileName = displayName;
      });

      _loadProfileIntoForm(profileToLoad);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            docId != null
                ? 'Editing QR Code "$displayName"'
                : 'Loaded profile "$displayName"',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleGenerate() async {
    final provider = context.read<QrProvider>();

    // Instant offline check using connectivity_plus
    List<ConnectivityResult> connectivityResult = [ConnectivityResult.wifi];
    try {
      connectivityResult = await (Connectivity().checkConnectivity());
    } catch (_) {
      // If the plugin isn't fully loaded yet (MissingPluginException), default to true so it doesn't block.
    }

    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppTheme.badgeRedText),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No internet connection. Please connect to Wi-Fi or cellular data.',
                    style: TextStyle(
                      color: AppTheme.badgeRedText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.badgeRedBg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.badgeRedText, width: 1.5),
            ),
            margin: const EdgeInsets.only(bottom: 32, left: 20, right: 20),
            elevation: 0,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return; // Stop generation instantly
    }

    final pin = _protectionPasswordController.text.trim();
    final confirmPin = _confirmPasswordController.text.trim();

    if (pin.isNotEmpty && pin.length < 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secret PIN must be at least 4 digits.'),
            backgroundColor: AppTheme.badgeRedText,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (pin != confirmPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secret PIN and Confirm PIN do not match.'),
            backgroundColor: AppTheme.badgeRedText,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final wasEditing = _editingDocId != null && _editingDocId!.isNotEmpty;
      if (wasEditing) {
        await provider.updateQrCode(_editingDocId!);
      } else {
        await provider.generateQrCode();
      }

      if (provider.generatedUrl != null && mounted) {
        // Auto-save the generated/updated QR code to history
        final generatedProfile = provider.profile;

        // Extract Firestore doc id if available
        String qrId =
            _editingDocId ?? DateTime.now().millisecondsSinceEpoch.toString();
        try {
          final uri = Uri.parse(provider.generatedUrl!);
          final idParam = uri.queryParameters['id'];
          if (idParam != null && idParam.isNotEmpty) {
            qrId = idParam;
          }
        } catch (_) {}

        final savedQr = SavedQrCode(
          id: qrId,
          url: provider.generatedUrl!,
          name: generatedProfile.name.isEmpty
              ? (generatedProfile.qrName.isEmpty
                    ? 'User'
                    : generatedProfile.qrName)
              : generatedProfile.name,
          themeColor: generatedProfile.themeColor,
          date: DateTime.now(),
          profile: generatedProfile,
        );
        await HistoryStorage.addQrCode(savedQr);

        // Reset editing state after successful update
        if (!widget.isClientMode) {
          setState(() {
            _editingDocId = null;
            _editingProfileName = null;
          });
        }

        if (wasEditing && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isClientMode
                    ? 'Profile successfully updated!'
                    : 'QR Code successfully updated!',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (widget.isClientMode && mounted) {
          Navigator.pop(context, true);
          return;
        }

        _showQrCodeDialog(provider.generatedUrl!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.badgeRedText,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Something went wrong. Please check your connection and try again.',
                    style: TextStyle(
                      color: AppTheme.badgeRedText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.badgeRedBg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.badgeRedText, width: 1.5),
            ),
            margin: const EdgeInsets.only(bottom: 32, left: 20, right: 20),
            elevation: 0,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showQrCodeDialog(String qrData) {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    bool isCopied = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bottom sheet handle indicator
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.borderGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your QR Code is Ready!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share this code with your customers or test the redirection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 28),

                  // Generated QR Code Box
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.borderGrey,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 250.0,
                        errorCorrectionLevel: QrErrorCorrectLevel.Q,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.textDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Download & Share Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _shareQrCode(qrData, isDownload: true),
                          icon: const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Download',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF25D366,
                            ), // Premium green for downloads
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareQrCode(qrData),
                          icon: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Share QR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: qrData));
                            setSheetState(() {
                              isCopied = true;
                            });
                            _showCustomToast(
                              context,
                              'QR Link copied to clipboard!',
                              true,
                            );
                            Future.delayed(const Duration(seconds: 2), () {
                              if (sheetContext.mounted) {
                                setSheetState(() {
                                  isCopied = false;
                                });
                              }
                            });
                          },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isCopied
                                  ? Icons.check_circle_rounded
                                  : Icons.copy_rounded,
                              key: ValueKey<bool>(isCopied),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                isCopied ? 'Copied!' : 'Copy Link',
                                key: ValueKey<bool>(isCopied),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCopied
                                ? const Color(0xFF25D366)
                                : AppTheme.primaryPurple,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preview / Scan Simulator button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PreviewScreen(scanUrl: qrData),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: AppTheme.primaryPurple,
                      ),
                      label: const Text(
                        'Preview Profile',
                        style: TextStyle(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppTheme.primaryPurple,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridSocialIconButton({
    required String platformKey,
    required String displayName,
    required Widget iconWidget,
    required String currentValue,
  }) {
    final isSelected = _activeSocialTab == platformKey;
    final hasValue = currentValue.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeSocialTab = platformKey;
        });
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withValues(alpha: 0.06)
              : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple
                : AppTheme.borderGrey.withValues(alpha: 0.8),
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icon
            iconWidget,

            // Success dot if configured
            if (hasValue)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCircle(ThemePreset preset, QrProvider provider) {
    final isSelected = provider.profile.themeColor == preset.value;
    final themeColors = preset.colors;
    final accentColor = themeColors.first;

    return GestureDetector(
      onTap: () {
        provider.updateThemeColor(preset.value);
      },
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            width: 2.5,
          ),
        ),
        padding: const EdgeInsets.all(3.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: themeColors.length > 1
                ? LinearGradient(
                    colors: themeColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: themeColors.length > 1 ? null : accentColor,
            image: preset.imageUrl != null
                ? DecorationImage(
                    image: AssetImage(preset.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isSelected
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppTheme.primaryPurple,
                      size: 14,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildAvatarBorderColorOption({
    required BuildContext context,
    required String colorHex,
    required String displayName,
    required QrProvider provider,
    bool isDynamic = false,
  }) {
    final activeColorHex = provider.profile.avatarBorderColor;
    final isSelected = activeColorHex == colorHex;

    // Resolve what color/gradient to show in the circle
    final parsedColors = AppTheme.parseThemeColors(
      colorHex.isEmpty ? provider.profile.themeColor : colorHex,
    );
    final hasMultipleColors = parsedColors.length > 1;

    // White color has a thin border so it doesn't blend into the background card
    final isWhite = colorHex.toLowerCase() == '#ffffff';

    return GestureDetector(
      onTap: () {
        provider.updateAvatarBorderColor(colorHex);
      },
      child: Tooltip(
        message: displayName,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
              width: 2.8,
            ),
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasMultipleColors
                  ? LinearGradient(
                      colors: parsedColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasMultipleColors ? null : parsedColors.first,
              border: isWhite
                  ? Border.all(color: AppTheme.borderGrey, width: 1.2)
                  : (isDynamic
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.8,
                          )
                        : null),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: isSelected
                ? Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: isWhite ? AppTheme.primaryPurple : Colors.white,
                      size: 16,
                    ),
                  )
                : (isDynamic
                      ? const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        )
                      : null),
          ),
        ),
      ),
    );
  }

  Widget _buildBorderThicknessChip(
    QrProvider provider,
    String label,
    double widthVal,
  ) {
    final isSelected =
        (provider.profile.avatarBorderWidth - widthVal).abs() < 0.2;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          provider.updateAvatarBorderWidth(widthVal);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryPurple
                : AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryPurple : AppTheme.borderGrey,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateOptionCard({
    required BuildContext context,
    required String positionKey,
    required String title,
    required String subtitle,
    required QrProvider provider,
  }) {
    final isSelected = provider.profile.avatarPosition == positionKey;
    final themeColors = AppTheme.parseThemeColors(provider.profile.themeColor);
    final accentColor = themeColors.first;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          provider.updateAvatarPosition(positionKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryPurple.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryPurple
                  : AppTheme.borderGrey.withValues(alpha: 0.8),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Miniature Screen Mockup
              Container(
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.borderGrey.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    children: [
                      // Top Banner Mockup
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 38,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: themeColors.length > 1
                                  ? themeColors
                                  : [
                                      accentColor,
                                      accentColor.withValues(alpha: 0.7),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Overlapping Avatar Circle Mockup
                      Positioned(
                        top: 24,
                        left: positionKey == 'center'
                            ? 0
                            : (positionKey == 'right' ? null : 8),
                        right: positionKey == 'center'
                            ? 0
                            : (positionKey == 'right' ? 8 : null),
                        child: Align(
                          alignment: positionKey == 'center'
                              ? Alignment.center
                              : (positionKey == 'right'
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentColor.withValues(alpha: 0.25),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 14,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Mockup "Contact Us" Title Line
                      Positioned(
                        top: 58,
                        left: 8,
                        child: Container(
                          width: 26,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF64748B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Mockup Social Cards
                      Positioned(
                        top: 67,
                        left: 8,
                        right: 8,
                        child: Column(
                          children: [
                            Container(
                              height: 11,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 1.5,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 18,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCBD5E1),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              height: 11,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 1.5,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF25D366),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 22,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCBD5E1),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Template Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppTheme.primaryPurple
                      : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // Selection Radio Indicator
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppTheme.primaryPurple
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryPurple
                        : AppTheme.borderGrey,
                    width: isSelected ? 1.5 : 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QrProvider>(context);
    final brandPresets = AppTheme.brandPresets;
    final imagePresets = brandPresets.where((p) => p.imageUrl != null).toList();
    final solidPresets = brandPresets
        .where((p) => p.imageUrl == null && !p.isGradient)
        .toList();
    final gradientPresets = brandPresets
        .where((p) => p.imageUrl == null && p.isGradient)
        .toList();

    String currentThemeName = 'Vibrant Purple';
    try {
      currentThemeName = brandPresets
          .firstWhere(
            (p) =>
                p.value.toLowerCase() ==
                provider.profile.themeColor.toLowerCase(),
          )
          .name;
    } catch (_) {
      currentThemeName = 'Custom';
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          widget.isClientMode ? 'Edit Profile' : 'QR Profile Generator',
          style: const TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: widget.isClientMode
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textDark,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (!widget.isClientMode)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: TextButton.icon(
                onPressed: _openSavedQrCodesScreen,
                icon: const Icon(
                  Icons.history,
                  color: AppTheme.primaryPurple,
                  size: 18,
                ),
                label: const Text(
                  'History',
                  style: TextStyle(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple.withValues(
                    alpha: 0.08,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main Scrollable Setup Options Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Theme Color Selection
                  ExpandableCard(
                    title: 'Theme Color',
                    description: 'Choose your brand style',
                    icon: Icons.palette_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Theme Name Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryPurple.withValues(
                                alpha: 0.15,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppTheme.primaryPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Active Theme: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                              Text(
                                currentThemeName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Solid Colors',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 52,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: solidPresets.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isCustomColorPickerOpen = true;
                                    });
                                  },
                                  child: Tooltip(
                                    message: 'Custom Colour Picker',
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isCustomColorPickerOpen
                                              ? AppTheme.primaryPurple
                                              : AppTheme.borderGrey,
                                          width: _isCustomColorPickerOpen
                                              ? 2.5
                                              : 1.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(3.0),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: SweepGradient(
                                            colors: [
                                              Color(0xFFFF0000),
                                              Color(0xFFFFA500),
                                              Color(0xFFFFFF00),
                                              Color(0xFF00FF00),
                                              Color(0xFF00FFFF),
                                              Color(0xFF0000FF),
                                              Color(0xFFFF00FF),
                                              Color(0xFFFF0000),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.colorize_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return _buildThemeCircle(
                                solidPresets[index - 1],
                                provider,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gradient Themes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 52,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: gradientPresets.length,
                            itemBuilder: (context, index) {
                              return _buildThemeCircle(
                                gradientPresets[index],
                                provider,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Image Themes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 52,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: imagePresets.length,
                            itemBuilder: (context, index) {
                              return _buildThemeCircle(
                                imagePresets[index],
                                provider,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Background Brightness Adjust',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: AppTheme.textGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppTheme.primaryPurple,
                                  inactiveTrackColor: AppTheme.primaryPurple
                                      .withValues(alpha: 0.15),
                                  thumbColor: AppTheme.primaryPurple,
                                  overlayColor: AppTheme.primaryPurple
                                      .withValues(alpha: 0.12),
                                  valueIndicatorColor: AppTheme.primaryPurple,
                                  valueIndicatorTextStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                child: Slider(
                                  value: provider.profile.backgroundBrightness,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 100,
                                  label:
                                      '${(provider.profile.backgroundBrightness * 100).round()}%',
                                  onChanged: (value) {
                                    provider.updateBackgroundBrightness(value);
                                  },
                                ),
                              ),
                            ),
                            Text(
                              '${(provider.profile.backgroundBrightness * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppTheme.borderGrey),
                        const SizedBox(height: 16),

                        // Custom Colour Picker Accordion Toggle
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCustomColorPickerOpen =
                                  !_isCustomColorPickerOpen;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _isCustomColorPickerOpen
                                  ? const Color(0xFF202124)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isCustomColorPickerOpen
                                    ? Colors.transparent
                                    : AppTheme.borderGrey,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: _isCustomColorPickerOpen
                                        ? 0.08
                                        : 0.03,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isCustomColorPickerOpen
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : AppTheme.primaryPurple.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.colorize_rounded,
                                    color: _isCustomColorPickerOpen
                                        ? Colors.white
                                        : AppTheme.primaryPurple,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Custom Colour Picker',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _isCustomColorPickerOpen
                                              ? Colors.white
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pick any shade with 2D palette & hue slider',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isCustomColorPickerOpen
                                              ? Colors.white70
                                              : AppTheme.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _isCustomColorPickerOpen
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: _isCustomColorPickerOpen
                                      ? Colors.white70
                                      : AppTheme.textGrey,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expandable Google Colour Picker Widget
                        if (_isCustomColorPickerOpen) ...[
                          const SizedBox(height: 14),
                          GoogleColorPicker(
                            initialColorHex: provider.profile.themeColor,
                            onColorChanged: (newHex) {
                              provider.updateThemeColor(newHex);
                            },
                            onShareOrCopy: () {
                              _showCustomToast(
                                context,
                                'Color code copied to clipboard!',
                                true,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Card: UI Template Selection (Total 3 templates: Left, Center, Right)
                  ExpandableCard(
                    title: 'UI Template',
                    description: 'Choose your profile avatar layout',
                    icon: Icons.dashboard_customize_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select your profile layout design:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose where you want your profile avatar positioned (Left, Center, or Right).',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildTemplateOptionCard(
                              context: context,
                              positionKey: 'left',
                              title: 'Left Avatar',
                              subtitle: 'Modern Left',
                              provider: provider,
                            ),
                            const SizedBox(width: 10),
                            _buildTemplateOptionCard(
                              context: context,
                              positionKey: 'center',
                              title: 'Center Avatar',
                              subtitle: 'Classic Center',
                              provider: provider,
                            ),
                            const SizedBox(width: 10),
                            _buildTemplateOptionCard(
                              context: context,
                              positionKey: 'right',
                              title: 'Right Avatar',
                              subtitle: 'Contemporary',
                              provider: provider,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Card 2: Basic Information (Required)
                  ExpandableCard(
                    title: 'Basic Information',
                    description: 'Your profile name and branding images',
                    icon: Icons.info_outline,
                    isRequired: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Profile Name',
                            hintText: 'e.g. User',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.borderGrey),
                        const SizedBox(height: 14),

                        // 1. Profile Picture Picker
                        const Text(
                          'Select Profile Picture (Avatar)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Preview Circle with Dynamic Border
                            Builder(
                              builder: (context) {
                                final activeAvatarBorderHex =
                                    provider.profile.avatarBorderColor
                                        .trim()
                                        .isNotEmpty
                                    ? provider.profile.avatarBorderColor.trim()
                                    : provider.profile.themeColor;
                                final avatarBorderColors =
                                    AppTheme.parseThemeColors(
                                      activeAvatarBorderHex,
                                    );
                                final bool hasGradient =
                                    avatarBorderColors.length > 1;
                                final double borderWidth =
                                    provider.profile.avatarBorderWidth;
                                final double previewBorderThickness =
                                    borderWidth > 0
                                    ? (borderWidth * 0.7).clamp(2.0, 6.0)
                                    : 0.0;

                                return Container(
                                  width: 66,
                                  height: 66,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: (borderWidth > 0 && hasGradient)
                                        ? LinearGradient(
                                            colors: avatarBorderColors,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: borderWidth > 0
                                        ? (hasGradient
                                              ? null
                                              : avatarBorderColors.first)
                                        : AppTheme.borderGrey,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(
                                    previewBorderThickness,
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.all(
                                      borderWidth > 0 ? 1.5 : 0,
                                    ),
                                    child: ClipOval(
                                      child: _isAvatarLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(14.0),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: AppTheme.primaryPurple,
                                              ),
                                            )
                                          : (provider
                                                    .profile
                                                    .avatarUrl
                                                    .isNotEmpty
                                                ? ImageHelper.buildImageWidget(
                                                    provider.profile.avatarUrl,
                                                    fit: BoxFit.cover,
                                                    errorWidget: const Icon(
                                                      Icons.person,
                                                      color: AppTheme.textGrey,
                                                      size: 28,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    color: AppTheme.textGrey,
                                                    size: 28,
                                                  )),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickImageFromDevice(isAvatar: true),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Choose Avatar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryPurple,
                                      side: const BorderSide(
                                        color: AppTheme.primaryPurple,
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  if (provider
                                      .profile
                                      .avatarUrl
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        _avatarUrlController.text = '';
                                        _updateProfileImages();
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          'Remove picture',
                                          style: TextStyle(
                                            color: AppTheme.badgeRedText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Avatar Border Color',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isAvatarColorPickerOpen =
                                      !_isAvatarColorPickerOpen;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.colorize_rounded,
                                      size: 15,
                                      color: _isAvatarColorPickerOpen
                                          ? AppTheme.primaryPurple
                                          : AppTheme.textGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isAvatarColorPickerOpen
                                          ? 'Close Picker'
                                          : 'Custom Color',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _isAvatarColorPickerOpen
                                            ? AppTheme.primaryPurple
                                            : AppTheme.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '', // Fallback to theme
                                displayName: 'Default Theme',
                                provider: provider,
                                isDynamic: true,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#FFFFFF',
                                displayName: 'White',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#000000',
                                displayName: 'Black',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#D63031',
                                displayName: 'Crimson Red',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#6C5CE7',
                                displayName: 'Vibrant Purple',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#0984E3',
                                displayName: 'Electric Blue',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#00B894',
                                displayName: 'Teal Mint',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#E17055',
                                displayName: 'Coral Orange',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#DAA520',
                                displayName: 'Gold Luxury',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#FF1493',
                                displayName: 'Hot Pink',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#A8A5E6',
                                displayName: 'Lavender',
                                provider: provider,
                              ),
                              // ── Gorgeous Gradient Options ──
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#FA709A,#FEE140',
                                displayName: 'Sunset Glow',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#7F00FF,#E100FF',
                                displayName: 'Royal Lavender',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#00C6FF,#0072FF',
                                displayName: 'Ocean Breeze',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#11998E,#38EF7D',
                                displayName: 'Neon Emerald',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#1F1C2C,#928DAB',
                                displayName: 'Deep Cosmos',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#FF758C,#FF7EB3',
                                displayName: 'Pink Lemonade',
                                provider: provider,
                              ),
                              _buildAvatarBorderColorOption(
                                context: context,
                                colorHex: '#FF9F43,#FF5252',
                                displayName: 'Mango Magic',
                                provider: provider,
                              ),
                            ],
                          ),
                        ),

                        if (_isAvatarColorPickerOpen) ...[
                          const SizedBox(height: 12),
                          GoogleColorPicker(
                            initialColorHex:
                                provider.profile.avatarBorderColor.isNotEmpty
                                ? provider.profile.avatarBorderColor
                                : provider.profile.themeColor,
                            onColorChanged: (newHex) {
                              provider.updateAvatarBorderColor(newHex);
                            },
                            onShareOrCopy: () {
                              _showCustomToast(
                                context,
                                'Avatar border color copied!',
                                true,
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Avatar Border Thickness',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${provider.profile.avatarBorderWidth.toStringAsFixed(1)} px',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildBorderThicknessChip(
                              provider,
                              'None (0)',
                              0.0,
                            ),
                            const SizedBox(width: 6),
                            _buildBorderThicknessChip(
                              provider,
                              'Thin (2.5)',
                              2.5,
                            ),
                            const SizedBox(width: 6),
                            _buildBorderThicknessChip(
                              provider,
                              'Medium (5)',
                              5.0,
                            ),
                            const SizedBox(width: 6),
                            _buildBorderThicknessChip(
                              provider,
                              'Bold (7.5)',
                              7.5,
                            ),
                            const SizedBox(width: 6),
                            _buildBorderThicknessChip(
                              provider,
                              'Thick (10)',
                              10.0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.primaryPurple,
                            inactiveTrackColor: AppTheme.primaryPurple
                                .withValues(alpha: 0.15),
                            thumbColor: AppTheme.primaryPurple,
                            overlayColor: AppTheme.primaryPurple.withValues(
                              alpha: 0.12,
                            ),
                            valueIndicatorColor: AppTheme.primaryPurple,
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          child: Slider(
                            value: provider.profile.avatarBorderWidth.clamp(
                              0.0,
                              12.0,
                            ),
                            min: 0.0,
                            max: 12.0,
                            divisions: 24,
                            label:
                                '${provider.profile.avatarBorderWidth.toStringAsFixed(1)} px',
                            onChanged: (val) {
                              provider.updateAvatarBorderWidth(val);
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.borderGrey),
                        const SizedBox(height: 14),

                        // 2. Banner Image Picker
                        const Text(
                          'Select Banner Background',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Preview Rect
                            Container(
                              width: 90,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.borderGrey,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _isBannerLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            color: AppTheme.primaryPurple,
                                          ),
                                        ),
                                      )
                                    : (provider.profile.bannerUrl.isNotEmpty
                                          ? ImageHelper.buildImageWidget(
                                              provider.profile.bannerUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: const Icon(
                                                Icons.image,
                                                color: AppTheme.textGrey,
                                                size: 24,
                                              ),
                                            )
                                          : Container(
                                              color: AppTheme.borderGrey
                                                  .withValues(alpha: 0.3),
                                              child: const Icon(
                                                Icons.image,
                                                color: AppTheme.textGrey,
                                                size: 24,
                                              ),
                                            )),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickImageFromDevice(isAvatar: false),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Choose Banner'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryPurple,
                                      side: const BorderSide(
                                        color: AppTheme.primaryPurple,
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  if (provider
                                      .profile
                                      .bannerUrl
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        _bannerUrlController.text = '';
                                        _updateProfileImages();
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          'Remove banner',
                                          style: TextStyle(
                                            color: AppTheme.badgeRedText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Card 3: Social Networks
                  ExpandableCard(
                    title: 'Social Networks',
                    description: 'Connect your social media profiles',
                    icon: Icons.language_outlined,
                    child: Builder(
                      builder: (context) {
                        // Determine details of active tab
                        Widget activeIconWidget;
                        String activeTitle = '';
                        TextEditingController activeController;
                        String activeLabel = '';
                        String activeHint = '';
                        String activeHelpText = '';
                        TextInputType activeKeyboardType = TextInputType.url;

                        switch (_activeSocialTab) {
                          case 'instagram':
                            activeTitle = 'Instagram';
                            activeController = _instagramController;
                            activeLabel = 'Instagram Username or Link';
                            activeHint = 'https://instagram.com/...';
                            activeHelpText =
                                'Provide your profile username or the direct link to your feed.';
                            break;
                          case 'telegram':
                            activeTitle = 'Telegram';
                            activeController = _telegramController;
                            activeLabel = 'Telegram Username or Link';
                            activeHint =
                                'e.g. https://t.me/yourusername or @yourusername';
                            activeHelpText =
                                'Provide your Telegram username or group/channel invite link.';
                            break;
                          case 'whatsapp':
                            activeTitle = 'WhatsApp';
                            activeController = _whatsappController;
                            activeLabel = 'WhatsApp Number';
                            activeHint = 'e.g. 9876543210';
                            activeHelpText =
                                'Provide your WhatsApp contact number and/or group invitation link.';
                            break;
                          case 'facebook':
                            activeTitle = 'Facebook';
                            activeController = _facebookController;
                            activeLabel = 'Facebook Page or Profile Link';
                            activeHint = 'e.g. https://facebook.com/yourpage';
                            activeHelpText =
                                'Provide the direct URL to your Facebook profile or page.';
                            break;
                          case 'youtube':
                            activeTitle = 'YouTube';
                            activeController = _youtubeController;
                            activeLabel = 'YouTube Channel or Video Link';
                            activeHint = 'e.g. https://youtube.com/@mychannel';
                            activeHelpText =
                                'Provide the URL of your channel or featured video.';
                            break;
                          case 'linkedin':
                            activeTitle = 'LinkedIn';
                            activeController = _linkedinController;
                            activeLabel = 'LinkedIn Profile or Company Link';
                            activeHint =
                                'e.g. https://linkedin.com/in/yourprofile';
                            activeHelpText =
                                'Provide the direct URL to your LinkedIn profile or company page.';
                            break;
                          case 'email':
                            activeTitle = 'Email';
                            activeController = _emailController;
                            activeLabel = 'Email Address';
                            activeHint = 'e.g. contact@yourdomain.com';
                            activeHelpText =
                                'Provide your email address for direct customer inquiries.';
                            activeKeyboardType = TextInputType.emailAddress;
                            break;
                          case 'tiktok':
                            activeTitle = 'TikTok';
                            activeController = _tiktokController;
                            activeLabel = 'TikTok Profile Link';
                            activeHint = 'e.g. https://tiktok.com/@yourhandle';
                            activeHelpText =
                                'Provide the link to your TikTok profile feed.';
                            break;
                          case 'x':
                          case 'twitter':
                            activeTitle = 'X (Twitter)';
                            activeController = _xTwitterController;
                            activeLabel = 'X (Twitter) Profile Link';
                            activeHint = 'e.g. https://x.com/yourhandle';
                            activeHelpText =
                                'Provide your X (Twitter) profile URL or username.';
                            break;
                          case 'threads':
                            activeTitle = 'Threads';
                            activeController = _threadsController;
                            activeLabel = 'Threads Profile Link';
                            activeHint = 'e.g. https://threads.net/@yourhandle';
                            activeHelpText =
                                'Provide your Threads profile URL or handle.';
                            break;
                          case 'pinterest':
                            activeTitle = 'Pinterest';
                            activeController = _pinterestController;
                            activeLabel = 'Pinterest Profile Link';
                            activeHint =
                                'e.g. https://pinterest.com/yourusername';
                            activeHelpText =
                                'Provide your Pinterest profile URL or board link.';
                            break;
                          case 'google':
                            activeTitle = 'Google Review';
                            activeController = _googleReviewController;
                            activeLabel = 'Google Review or GMap Link';
                            activeHint = 'e.g. https://g.page/r/yourlink';
                            activeHelpText =
                                'Provide your Google Review link or location URL.';
                            break;
                          case 'location':
                            activeTitle = 'Location Share';
                            activeController = _locationController;
                            activeLabel = 'Google Maps Link';
                            activeHint = 'e.g. https://maps.app.goo.gl/...';
                            activeHelpText =
                                'Provide a Google Maps location share URL. Scanning the QR code will display a link to open Google Maps.';
                            break;
                          case 'contact':
                            activeTitle = 'Contact Us';
                            activeController = _contactUsController;
                            activeLabel = 'Contact Number';
                            activeHint = '';
                            activeHelpText =
                                'Provide a phone number for customers to call you.';
                            activeKeyboardType = TextInputType.phone;
                            break;
                          case 'feedback':
                            activeTitle = 'Customer Feedback';
                            activeController = _feedbackController;
                            activeLabel = 'Feedback Card Subtitle';
                            activeHint = 'e.g. Share your feedback & reviews';
                            activeHelpText =
                                'When enabled, a Feedback card will appear on your profile. Visitors can tap to read all reviews from Firebase and submit their own feedback.';
                            activeKeyboardType = TextInputType.text;
                            break;
                          case 'gallery':
                            activeTitle = 'Shop Showcase & Gallery';
                            activeController = _galleryController;
                            activeLabel = 'Showcase Card Subtitle';
                            activeHint =
                                'e.g. Browse our shop photos & showcase';
                            activeHelpText =
                                'When enabled, a Showcase card appears on your profile. Shop owners can enter their secret PIN to upload and manage photos, while customers can browse and zoom photos.';
                            activeKeyboardType = TextInputType.text;
                            break;
                          case 'website':
                          default:
                            activeTitle = 'Website';
                            activeController = _websiteController;
                            activeLabel = 'Website Link';
                            activeHint = 'e.g. https://yourwebsite.com';
                            activeHelpText =
                                'Provide the link to your business website or custom URL.';
                            break;
                        }

                        activeIconWidget = SizedBox(
                          width: 44,
                          height: 44,
                          child: ImageHelper.buildSocialLogo(
                            _activeSocialTab,
                            size: 40,
                          ),
                        );

                        final selectedPlatformCard = Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.borderGrey.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  activeIconWidget,
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Active Social Link',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (activeController.text.trim().isNotEmpty ||
                                      (_activeSocialTab == 'whatsapp' &&
                                          (_whatsappGroupController.text
                                                  .trim()
                                                  .isNotEmpty ||
                                              _whatsappEntries.any(
                                                (e) => e.controller.text
                                                    .trim()
                                                    .isNotEmpty,
                                              ))) ||
                                      (_activeSocialTab == 'contact' &&
                                          _contactEntries.any(
                                            (e) => e.controller.text
                                                .trim()
                                                .isNotEmpty,
                                          )) ||
                                      (_activeSocialTab == 'instagram' &&
                                          _instagramControllers.any(
                                            (c) => c.text.trim().isNotEmpty,
                                          )))
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.badgeRedText,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_activeSocialTab == 'whatsapp') {
                                            _whatsappGroupController.clear();
                                            for (
                                              int i =
                                                  _whatsappEntries.length - 1;
                                              i >= 1;
                                              i--
                                            ) {
                                              _removeWhatsAppNumber(i);
                                            }
                                            if (_whatsappEntries.isNotEmpty) {
                                              _whatsappEntries.first.controller
                                                  .clear();
                                              _whatsappEntries
                                                      .first
                                                      .countryCode =
                                                  '+91';
                                              _whatsappEntries
                                                      .first
                                                      .countryFlag =
                                                  '🇮🇳';
                                            }
                                          } else if (_activeSocialTab ==
                                              'contact') {
                                            for (
                                              int i =
                                                  _contactEntries.length - 1;
                                              i >= 1;
                                              i--
                                            ) {
                                              _removeContactNumber(i);
                                            }
                                            if (_contactEntries.isNotEmpty) {
                                              _contactEntries.first.controller
                                                  .clear();
                                              _contactEntries
                                                      .first
                                                      .countryCode =
                                                  '+91';
                                              _contactEntries
                                                      .first
                                                      .countryFlag =
                                                  '🇮🇳';
                                            }
                                          } else if (_activeSocialTab ==
                                              'instagram') {
                                            for (
                                              int i =
                                                  _instagramControllers.length -
                                                  1;
                                              i >= 1;
                                              i--
                                            ) {
                                              _removeInstagramAccount(i);
                                            }
                                            if (_instagramControllers
                                                .isNotEmpty) {
                                              _instagramControllers.first
                                                  .clear();
                                            }
                                          } else {
                                            activeController.clear();
                                          }
                                        });
                                        _updateSocials();
                                      },
                                      tooltip: 'Clear link',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_activeSocialTab == 'whatsapp') ...[
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      int i = 0;
                                      i < _whatsappEntries.length;
                                      i++
                                    ) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showCountryPicker(
                                                  context: context,
                                                  showPhoneCode: true,
                                                  favorite: const [
                                                    'IN',
                                                    'SA',
                                                    'AE',
                                                    'QA',
                                                    'KW',
                                                    'OM',
                                                    'BH',
                                                  ],
                                                  onSelect: (Country country) {
                                                    setState(() {
                                                      _whatsappEntries[i]
                                                              .countryCode =
                                                          '+${country.phoneCode}';
                                                      _whatsappEntries[i]
                                                              .countryFlag =
                                                          country.flagEmoji;
                                                    });
                                                    _updateSocials();
                                                  },
                                                  countryListTheme: CountryListThemeData(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                24,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                24,
                                                              ),
                                                        ),
                                                    inputDecoration: InputDecoration(
                                                      labelText:
                                                          'Search country',
                                                      prefixIcon: const Icon(
                                                        Icons.search,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: AppTheme
                                                                  .borderGrey,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: 52,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF9FAFC,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppTheme.borderGrey,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${_whatsappEntries[i].countryFlag} ${_whatsappEntries[i].countryCode}',
                                                      style: const TextStyle(
                                                        color:
                                                            AppTheme.textDark,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.arrow_drop_down,
                                                      color: AppTheme.textGrey,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _whatsappEntries[i]
                                                    .controller,
                                                keyboardType:
                                                    TextInputType.phone,
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                decoration: InputDecoration(
                                                  labelText:
                                                      _whatsappEntries.length >
                                                          1
                                                      ? 'WhatsApp Number ${i + 1}'
                                                      : 'WhatsApp Number',
                                                  hintText: 'e.g. 9876543210',
                                                  prefixIcon: SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child:
                                                        ImageHelper.buildSocialLogo(
                                                          'whatsapp',
                                                          size: 20,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (_whatsappEntries.length >
                                                1) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons
                                                      .remove_circle_outline_rounded,
                                                  color: AppTheme.badgeRedText,
                                                  size: 22,
                                                ),
                                                tooltip: 'Remove this number',
                                                onPressed: () =>
                                                    _removeWhatsAppNumber(i),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_whatsappEntries.length < 5 &&
                                        _whatsappEntries.every(
                                          (e) => e.controller.text
                                              .trim()
                                              .isNotEmpty,
                                        ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: _addWhatsAppNumber,
                                            icon: const Icon(
                                              Icons.add_circle_outline_rounded,
                                              size: 18,
                                              color: AppTheme.primaryPurple,
                                            ),
                                            label: Text(
                                              '+ Add another WhatsApp number (${_whatsappEntries.length}/5)',
                                              style: const TextStyle(
                                                color: AppTheme.primaryPurple,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _whatsappGroupController,
                                      keyboardType: TextInputType.url,
                                      decoration: InputDecoration(
                                        labelText: 'WhatsApp Group Link',
                                        hintText:
                                            'https://chat.whatsapp.com/...',
                                        prefixIcon: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: ImageHelper.buildSocialLogo(
                                            'whatsapp_group',
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (_activeSocialTab == 'contact') ...[
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      int i = 0;
                                      i < _contactEntries.length;
                                      i++
                                    ) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showCountryPicker(
                                                  context: context,
                                                  showPhoneCode: true,
                                                  favorite: const [
                                                    'IN',
                                                    'SA',
                                                    'AE',
                                                    'QA',
                                                    'KW',
                                                    'OM',
                                                    'BH',
                                                  ],
                                                  onSelect: (Country country) {
                                                    setState(() {
                                                      _contactEntries[i]
                                                              .countryCode =
                                                          '+${country.phoneCode}';
                                                      _contactEntries[i]
                                                              .countryFlag =
                                                          country.flagEmoji;
                                                    });
                                                    _updateSocials();
                                                  },
                                                  countryListTheme: CountryListThemeData(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                24,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                24,
                                                              ),
                                                        ),
                                                    inputDecoration: InputDecoration(
                                                      labelText:
                                                          'Search country',
                                                      prefixIcon: const Icon(
                                                        Icons.search,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: AppTheme
                                                                  .borderGrey,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: 52,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF9FAFC,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppTheme.borderGrey,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${_contactEntries[i].countryFlag} ${_contactEntries[i].countryCode}',
                                                      style: const TextStyle(
                                                        color:
                                                            AppTheme.textDark,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.arrow_drop_down,
                                                      color: AppTheme.textGrey,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _contactEntries[i]
                                                    .controller,
                                                keyboardType:
                                                    TextInputType.phone,
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                decoration: InputDecoration(
                                                  labelText:
                                                      _contactEntries.length > 1
                                                      ? 'Contact Number ${i + 1}'
                                                      : 'Contact Number',
                                                  hintText: 'e.g. 9876543210',
                                                  prefixIcon: SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child:
                                                        ImageHelper.buildSocialLogo(
                                                          'contact',
                                                          size: 20,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (_contactEntries.length > 1) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons
                                                      .remove_circle_outline_rounded,
                                                  color: AppTheme.badgeRedText,
                                                  size: 22,
                                                ),
                                                tooltip: 'Remove this number',
                                                onPressed: () =>
                                                    _removeContactNumber(i),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_contactEntries.length < 5 &&
                                        _contactEntries.every(
                                          (e) => e.controller.text
                                              .trim()
                                              .isNotEmpty,
                                        ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: _addContactNumber,
                                            icon: const Icon(
                                              Icons.add_circle_outline_rounded,
                                              size: 18,
                                              color: AppTheme.primaryPurple,
                                            ),
                                            label: Text(
                                              '+ Add another Contact number (${_contactEntries.length}/5)',
                                              style: const TextStyle(
                                                color: AppTheme.primaryPurple,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ] else if (_activeSocialTab == 'instagram') ...[
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      int i = 0;
                                      i < _instagramControllers.length;
                                      i++
                                    ) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _instagramControllers[i],
                                                keyboardType: TextInputType.url,
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                decoration: InputDecoration(
                                                  labelText:
                                                      _instagramControllers
                                                              .length >
                                                          1
                                                      ? 'Instagram Account ${i + 1}'
                                                      : 'Instagram Username or Link',
                                                  hintText:
                                                      'https://instagram.com/...',
                                                  prefixIcon: SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child:
                                                        ImageHelper.buildSocialLogo(
                                                          'instagram',
                                                          size: 20,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (_instagramControllers.length >
                                                1) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons
                                                      .remove_circle_outline_rounded,
                                                  color: AppTheme.badgeRedText,
                                                  size: 22,
                                                ),
                                                tooltip:
                                                    'Remove this Instagram account',
                                                onPressed: () =>
                                                    _removeInstagramAccount(i),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_instagramControllers.length < 5 &&
                                        _instagramControllers.every(
                                          (c) => c.text.trim().isNotEmpty,
                                        ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: _addInstagramAccount,
                                            icon: const Icon(
                                              Icons.add_circle_outline_rounded,
                                              size: 18,
                                              color: AppTheme.primaryPurple,
                                            ),
                                            label: Text(
                                              '+ Add another Instagram account (${_instagramControllers.length}/5)',
                                              style: const TextStyle(
                                                color: AppTheme.primaryPurple,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ] else if (_activeSocialTab == 'feedback') ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.borderGrey.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 2,
                                    ),
                                    title: const Text(
                                      'Enable Feedback & Reviews',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Show feedback card on profile to view and collect reviews in Firebase',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textGrey,
                                      ),
                                    ),
                                    activeTrackColor: AppTheme.primaryPurple,
                                    activeThumbColor: Colors.white,
                                    value: _feedbackController.text
                                        .trim()
                                        .isNotEmpty,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val) {
                                          _feedbackController.text =
                                              'Share your feedback & reviews';
                                        } else {
                                          _feedbackController.clear();
                                        }
                                      });
                                      _updateSocials();
                                    },
                                  ),
                                ),
                                if (_feedbackController.text
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _feedbackController,
                                    keyboardType: TextInputType.text,
                                    onChanged: (_) => _updateSocials(),
                                    decoration: InputDecoration(
                                      labelText: 'Feedback Subtitle or Prompt',
                                      hintText:
                                          'e.g. Share your feedback & reviews',
                                      prefixIcon: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: ImageHelper.buildSocialLogo(
                                          'feedback',
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ] else if (_activeSocialTab == 'gallery') ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.borderGrey.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 2,
                                    ),
                                    title: const Text(
                                      'Enable Shop Showcase & Gallery',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Show showcase card on profile for shop photos with owner PIN protection',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textGrey,
                                      ),
                                    ),
                                    activeTrackColor: AppTheme.primaryPurple,
                                    activeThumbColor: Colors.white,
                                    value: _galleryController.text
                                        .trim()
                                        .isNotEmpty,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val) {
                                          _galleryController.text =
                                              'Browse our shop photos & showcase';
                                          if (_protectionPasswordController.text
                                              .trim()
                                              .isEmpty) {
                                            _protectionPasswordController.text =
                                                '009009';
                                          }
                                        } else {
                                          _galleryController.clear();
                                        }
                                      });
                                      _updateSocials();
                                    },
                                  ),
                                ),
                                if (_galleryController.text
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _galleryController,
                                    keyboardType: TextInputType.text,
                                    onChanged: (_) => _updateSocials(),
                                    decoration: InputDecoration(
                                      labelText:
                                          'Showcase Subtitle or Description',
                                      hintText:
                                          'e.g. Browse our shop photos & showcase',
                                      prefixIcon: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: ImageHelper.buildSocialLogo(
                                          'gallery',
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.primaryPurple
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.shield_outlined,
                                          color: AppTheme.primaryPurple,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Showcase photo management is protected by your Secret PIN. Set and change your PIN in the "Security & Owner PIN" card below.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textDark,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ] else ...[
                                TextFormField(
                                  controller: activeController,
                                  keyboardType: activeKeyboardType,
                                  decoration: InputDecoration(
                                    labelText: activeLabel,
                                    hintText: activeHint,
                                    prefixIcon: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: ImageHelper.buildSocialLogo(
                                        _activeSocialTab,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  activeHelpText,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textGrey,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        final socialIconsGrid = Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildGridSocialIconButton(
                              platformKey: 'instagram',
                              displayName: 'Instagram',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'instagram',
                                size: 32,
                              ),
                              currentValue:
                                  _instagramControllers.any(
                                    (c) => c.text.trim().isNotEmpty,
                                  )
                                  ? 'has_value'
                                  : '',
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'telegram',
                              displayName: 'Telegram',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'telegram',
                                size: 32,
                              ),
                              currentValue: _telegramController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'google',
                              displayName: 'Google Review',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'google',
                                size: 32,
                              ),
                              currentValue: _googleReviewController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'location',
                              displayName: 'Location Share',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'location',
                                size: 32,
                              ),
                              currentValue: _locationController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'whatsapp',
                              displayName: 'WhatsApp',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'whatsapp',
                                size: 32,
                              ),
                              currentValue:
                                  (_whatsappController.text.trim().isNotEmpty ||
                                      _whatsappGroupController.text
                                          .trim()
                                          .isNotEmpty)
                                  ? 'has_value'
                                  : '',
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'website',
                              displayName: 'Website',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'website',
                                size: 32,
                              ),
                              currentValue: _websiteController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'facebook',
                              displayName: 'Facebook',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'facebook',
                                size: 32,
                              ),
                              currentValue: _facebookController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'youtube',
                              displayName: 'YouTube',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'youtube',
                                size: 32,
                              ),
                              currentValue: _youtubeController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'email',
                              displayName: 'Email',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'email',
                                size: 32,
                              ),
                              currentValue: _emailController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'linkedin',
                              displayName: 'LinkedIn',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'linkedin',
                                size: 32,
                              ),
                              currentValue: _linkedinController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'pinterest',
                              displayName: 'Pinterest',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'pinterest',
                                size: 32,
                              ),
                              currentValue: _pinterestController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'x',
                              displayName: 'X (Twitter)',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'x',
                                size: 32,
                              ),
                              currentValue: _xTwitterController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'tiktok',
                              displayName: 'TikTok',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'tiktok',
                                size: 32,
                              ),
                              currentValue: _tiktokController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'threads',
                              displayName: 'Threads',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'threads',
                                size: 32,
                              ),
                              currentValue: _threadsController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'contact',
                              displayName: 'Contact Us',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'contact',
                                size: 32,
                              ),
                              currentValue: _contactUsController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'feedback',
                              displayName: 'Feedback',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'feedback',
                                size: 32,
                              ),
                              currentValue: _feedbackController.text,
                            ),
                            _buildGridSocialIconButton(
                              platformKey: 'gallery',
                              displayName: 'Showcase',
                              iconWidget: ImageHelper.buildSocialLogo(
                                'gallery',
                                size: 32,
                              ),
                              currentValue: _galleryController.text,
                            ),
                          ],
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            selectedPlatformCard,
                            const SizedBox(height: 20),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                'Select a platform below to configure:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            Center(child: socialIconsGrid),
                          ],
                        );
                      },
                    ),
                  ),

                  // Card 5: Security & Owner PIN
                  ExpandableCard(
                    title: 'Security & Owner PIN',
                    description:
                        'Secret PIN to edit profile & manage shop photos',
                    icon: Icons.lock_outline_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configure Secret Owner PIN:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'This PIN secures your profile editing access (via the 3-dot menu) and allows you to upload photos in the Shop Showcase.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textGrey,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Secret PIN input
                        TextFormField(
                          controller: _protectionPasswordController,
                          keyboardType: TextInputType.number,
                          obscureText: _obscurePassword,
                          maxLength: 8,
                          onChanged: (_) {
                            _updateSocials();
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: 'Secret PIN (4-8 digits)',
                            hintText: 'e.g. 009009',
                            counterText: '',
                            prefixIcon: const Icon(
                              Icons.lock_rounded,
                              color: AppTheme.primaryPurple,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppTheme.textGrey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm Secret PIN input
                        TextFormField(
                          controller: _confirmPasswordController,
                          keyboardType: TextInputType.number,
                          obscureText: _obscureConfirmPassword,
                          maxLength: 8,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Confirm Secret PIN',
                            hintText: 'Re-enter same PIN to confirm',
                            counterText: '',
                            prefixIcon: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppTheme.primaryPurple,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppTheme.textGrey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Real-time Matching Status Indicator
                        Builder(
                          builder: (context) {
                            final pin =
                                _protectionPasswordController.text.trim();
                            final confirm =
                                _confirmPasswordController.text.trim();

                            if (pin.isEmpty && confirm.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            if (pin.length < 4) {
                              return const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 15,
                                      color: AppTheme.badgeRedText,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'PIN must be at least 4 digits.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.badgeRedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final isMatching = pin == confirm;
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    isMatching
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 15,
                                    color: isMatching
                                        ? const Color(0xFF10B981)
                                        : AppTheme.badgeRedText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isMatching
                                        ? 'PINs match! Ready to save.'
                                        : 'PINs do not match. Please verify.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isMatching
                                          ? const Color(0xFF10B981)
                                          : AppTheme.badgeRedText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom Sticky Generate / Update Button View
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_editingDocId != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isClientMode
                              ? Icons.lock_outline_rounded
                              : Icons.edit_note_rounded,
                          color: const Color(0xFF0D9488),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isClientMode
                                ? 'Editing Profile: ${_editingProfileName ?? (_nameController.text.isNotEmpty ? _nameController.text : "Active")}'
                                : 'Editing Dynamic QR: ${_editingProfileName ?? (_nameController.text.isNotEmpty ? _nameController.text : "Active")}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!widget.isClientMode)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _editingDocId = null;
                                _editingProfileName = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Switched to creating a new QR Code',
                                  ),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.badgeRedText,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (provider.canGenerate && !provider.isLoading)
                        ? _handleGenerate
                        : null,
                    icon: provider.isLoading
                    
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _editingDocId != null
                                ? Icons.sync_rounded
                                : Icons.qr_code_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      provider.isLoading
                          ? (_editingDocId != null
                                ? 'Updating...'
                                : 'Generating...')
                          : (_editingDocId != null
                                ? 'Update QR Code'
                                : 'Generate QR Code'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.canGenerate
                          ? (_editingDocId != null
                                ? const Color(0xFF0D9488)
                                : AppTheme.primaryPurple)
                          : const Color(0xFFE4E5EA),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: provider.canGenerate ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
