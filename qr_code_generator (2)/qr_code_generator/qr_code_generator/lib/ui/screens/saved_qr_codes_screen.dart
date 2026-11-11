import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../theme.dart';
import '../../models/saved_qr_code.dart';
import '../../providers/qr_provider.dart';
import 'preview_screen.dart';

class SavedQrCodesScreen extends StatefulWidget {
  const SavedQrCodesScreen({super.key});

  @override
  State<SavedQrCodesScreen> createState() => _SavedQrCodesScreenState();
}

class _SavedQrCodesScreenState extends State<SavedQrCodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SavedQrCode> _allList = [];
  List<SavedQrCode> _filteredList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQrCodes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(_allList);
      } else {
        _filteredList = _allList.where((item) {
          final nameMatch = item.name.toLowerCase().contains(query);
          final headlineMatch = item.profile.headline.toLowerCase().contains(
            query,
          );
          final qrNameMatch = item.profile.qrName.toLowerCase().contains(query);
          final phone = item.profile.whatsapp.isNotEmpty
              ? item.profile.whatsapp
              : item.profile.contactUs;
          final phoneMatch = phone.toLowerCase().contains(query);
          return nameMatch || headlineMatch || qrNameMatch || phoneMatch;
        }).toList();
      }
    });
  }

  Future<void> _loadQrCodes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<QrProvider>();
      final list = await provider.fetchSavedQrCodes();
      if (!mounted) return;
      setState(() {
        _allList = list;
        _isLoading = false;
      });
      log('firebase data : $_allList');
      _onSearchChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteQrCode(SavedQrCode item) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Top Red Delete Icon
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Dialog Title
                const Text(
                  'Delete QR Code?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                const Text(
                  'This action is irreversible. The QR code and profile data will be permanently removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Item Preview Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.borderGrey.withValues(alpha: 0.8),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppTheme.primaryPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name.isNotEmpty ? item.name : 'Untitled QR',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.viewCount} ${item.viewCount == 1 ? "scan" : "scans"} recorded',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: AppTheme.textDark,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      try {
        final provider = context.read<QrProvider>();
        await provider.deleteSavedQrCode(item.id);
        setState(() {
          _allList.removeWhere((x) => x.id == item.id);
        });
        _onSearchChanged();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${item.name}"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: AppTheme.badgeRedBg,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _editProfile(SavedQrCode item) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading profile "${item.name}"...'),
        duration: const Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final provider = context.read<QrProvider>();
      final fullProfile = await provider.repository.fetchProfile(item.id);
      if (mounted) {
        log('c: $fullProfile');
        Navigator.pop(
          context,
          SavedQrCode(
            id: item.id,
            url: item.url,
            name: fullProfile.name.isNotEmpty ? fullProfile.name : item.name,
            themeColor: fullProfile.themeColor,
            date: item.date,
            profile: fullProfile,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context, item);
      }
    }
  }

  void _showQrCodeDialog(String qrData, {int viewCount = 0, Map<String, int>? tabClicks}) {
    FocusManager.instance.primaryFocus?.unfocus();
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: viewCount > 0
                          ? const Color(0xFF6C5CE7).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_red_eye_rounded,
                          size: 14,
                          color: viewCount > 0
                              ? AppTheme.primaryPurple
                              : AppTheme.textGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$viewCount Total ${viewCount == 1 ? 'Scan / View' : 'Scans / Views'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: viewCount > 0
                                ? AppTheme.primaryPurple
                                : AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tabClicks != null &&
                      tabClicks.isNotEmpty &&
                      tabClicks.values.any((v) => v > 0)) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: tabClicks.entries
                          .where((e) => e.value > 0)
                          .map((e) {
                        final keyName =
                            e.key.replaceAll('_', ' ').toLowerCase();
                        final capitalized = keyName.isEmpty
                            ? ''
                            : '${keyName[0].toUpperCase()}${keyName.substring(1)}';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '$capitalized: ${e.value} ${e.value == 1 ? "open" : "opens"}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderGrey, width: 1),
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
                      size: 240.0,
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
                  const SizedBox(height: 28),
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
                            backgroundColor: const Color(0xFF25D366),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('QR Link copied to clipboard!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Future.delayed(const Duration(seconds: 2), () {
                              if (sheetContext.mounted) {
                                setSheetState(() {
                                  isCopied = false;
                                });
                              }
                            });
                          },
                          icon: Icon(
                            isCopied
                                ? Icons.check_circle_rounded
                                : Icons.copy_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            isCopied ? 'Copied!' : 'Copy Link',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
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

  Future<void> _shareQrCode(String qrData, {bool isDownload = false}) async {
    if (!kIsWeb) {
      try {
        final qrPainter = QrPainter(
          data: qrData,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.Q,
          gapless: true,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF1A1C29),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF1A1C29),
          ),
        );

        final double qrSize = 3000.0;
        final double padding = 240.0;
        final double totalSize = qrSize + (padding * 2);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
        canvas.drawRect(Rect.fromLTWH(0, 0, totalSize, totalSize), bgPaint);

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('QR Code downloaded to your Gallery!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
            } catch (_) {}
          }

          final xFile = XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'qrcode_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await Share.shareXFiles([
            xFile,
          ], text: 'Here is my QR code profile!\n$qrData');
          return;
        }
      } catch (_) {}
    }

    Share.share('Check out my QR Profile: $qrData');
  }

  Widget _buildInitialAvatar(
    String initials,
    List<Color> themeColors,
    Color accentColor,
  ) {
    return Container(
      width: 48,
      height: 48,
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
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey, width: 1),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textDark,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved QR Codes',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.cloud_done_rounded,
                  size: 13,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 4),
                Text(
                  _isLoading
                      ? 'Syncing saved QR codes...'
                      : '${_allList.length} ${_allList.length == 1 ? "QR Code" : "QR Codes"} saved',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderGrey, width: 1),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryPurple,
                size: 22,
              ),
              tooltip: 'Refresh saved QR codes',
              onPressed: _loadQrCodes,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderGrey, width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Search by profile name or title...',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textGrey,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textGrey,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textGrey,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Main Body Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Loading your saved QR codes...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null && _allList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: AppTheme.badgeRedText,
                            size: 54,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to load saved QR codes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _loadQrCodes,
                          ),
                        ],
                      ),
                    ),
                  )
                : _filteredList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.cloud_queue_rounded,
                              color: AppTheme.primaryPurple,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No Matching QR Codes'
                                : 'No Saved QR Codes Yet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Try searching with a different name or keyword.'
                                : 'Create a QR profile and tap "Generate QR Code" to save it here automatically.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.primaryPurple,
                    onRefresh: _loadQrCodes,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: _filteredList.length,
                      itemBuilder: (context, index) {
                        final item = _filteredList[index];
                        final themeColors = AppTheme.parseThemeColors(
                          item.themeColor,
                        );
                        final accentColor = themeColors.first;

                        final dateStr =
                            "${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}";

                        final initials = item.name.isNotEmpty
                            ? item.name.substring(0, 1).toUpperCase()
                            : 'Q';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.borderGrey,
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                _buildInitialAvatar(
                                  initials,
                                  themeColors,
                                  accentColor,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      if (item.profile.headline.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            item.profile.headline,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textGrey,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (context) {
                                          final phone =
                                              item.profile.whatsapp
                                                  .trim()
                                                  .isNotEmpty
                                              ? item.profile.whatsapp.trim()
                                              : item.profile.contactUs.trim();
                                          final bool hasPhone =
                                              phone.isNotEmpty;

                                          return Row(
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.whatsapp,
                                                size: 13,
                                                color: hasPhone
                                                    ? const Color(0xFF25D366)
                                                    : AppTheme.textGrey
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  hasPhone
                                                      ? phone
                                                      : 'WhatsApp number not provided',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: hasPhone
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    fontStyle: hasPhone
                                                        ? FontStyle.normal
                                                        : FontStyle.italic,
                                                    color: hasPhone
                                                        ? AppTheme.textDark
                                                        : AppTheme.textGrey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.viewCount > 0
                                                  ? const Color(
                                                      0xFF6C5CE7,
                                                    ).withValues(alpha: 0.1)
                                                  : Colors.grey.withValues(
                                                      alpha: 0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.remove_red_eye_outlined,
                                                  size: 11,
                                                  color: item.viewCount > 0
                                                      ? AppTheme.primaryPurple
                                                      : AppTheme.textGrey,
                                                ),
                                                const SizedBox(width: 3.5),
                                                Text(
                                                  '${item.viewCount} ${item.viewCount == 1 ? 'view' : 'views'}',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: item.viewCount > 0
                                                        ? AppTheme.primaryPurple
                                                        : AppTheme.textGrey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.cloud_outlined,
                                                  size: 11,
                                                  color: AppTheme.textGrey,
                                                ),
                                                const SizedBox(width: 3.5),
                                                Expanded(
                                                  child: Text(
                                                    dateStr,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      color: AppTheme.textGrey,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // View QR
                                    IconButton(
                                      icon: const Icon(
                                        Icons.qr_code_rounded,
                                        color: AppTheme.primaryPurple,
                                        size: 20,
                                      ),
                                      onPressed: () => _showQrCodeDialog(
                                        item.url,
                                        viewCount: item.viewCount,
                                        tabClicks: item.profile.tabClicks,
                                      ),
                                      tooltip: 'View QR Code',
                                    ),
                                    // Edit Profile
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: AppTheme.textGrey,
                                        size: 20,
                                      ),
                                      onPressed: () => _editProfile(item),
                                      tooltip: 'Edit Profile',
                                    ),
                                    // Delete QR
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.badgeRedText,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteQrCode(item),
                                      tooltip: 'Delete QR Code',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
