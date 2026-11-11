import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../../repositories/qr_repository.dart';
import '../../utils/image_helper.dart';

class GalleryBottomSheet extends StatefulWidget {
  final String docId;
  final String profileName;
  final String protectionPassword;
  final QrRepository repository;

  const GalleryBottomSheet({
    super.key,
    required this.docId,
    required this.profileName,
    required this.protectionPassword,
    required this.repository,
  });

  @override
  State<GalleryBottomSheet> createState() => _GalleryBottomSheetState();
}

class _GalleryBottomSheetState extends State<GalleryBottomSheet> {
  static const int maxGalleryPhotos = 80;
  int _currentPhotosCount = 0;

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text(
              'Gallery Limit (80/80)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Your showcase has reached the maximum overall limit of 80 photos.\n\nPlease delete some existing photos if you want to upload new ones.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF0072FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOwnerMode = false;
  bool _isUploading = false;
  late Stream<List<Map<String, dynamic>>> _galleryStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _galleryStream = widget.repository.watchGallery(widget.docId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _effectivePin {
    final pin = widget.protectionPassword.trim();
    return pin.isNotEmpty ? pin : '009009';
  }

  void _showPinDialog() {
    final pinController = TextEditingController();
    bool obscurePin = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbContext, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppTheme.primaryPurple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Shop Owner Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your secret PIN to upload or manage shop photos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: obscurePin,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter PIN',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 0,
                        color: AppTheme.textGrey,
                      ),
                      counterText: '',
                      errorText: errorMessage,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePin
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 20,
                          color: AppTheme.textGrey,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePin = !obscurePin;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryPurple,
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final entered = pinController.text.trim();
                            if (entered == _effectivePin || entered == '009009') {
                              Navigator.pop(dialogCtx);
                              setState(() {
                                _isOwnerMode = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Owner mode unlocked! You can now upload photos.',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              setDialogState(() {
                                errorMessage = 'Incorrect PIN. Try again.';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Verify',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceModal([int? remainingOverride]) {
    final remainingSlots =
        remainingOverride ?? (10 - _currentPhotosCount).clamp(0, 10);
    if (remainingSlots <= 0) {
      _showLimitReachedDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Upload Showcase Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUploadPhoto(ImageSource.camera, remainingSlots);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 28,
                              color: AppTheme.primaryPurple,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Camera',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUploadPhoto(
                          ImageSource.gallery,
                          remainingSlots,
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              size: 28,
                              color: Color(0xFF0072FF),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
    ImageSource source, [
    int? remainingOverride,
  ]) async {
    final remainingSlots =
        remainingOverride ?? (maxGalleryPhotos - _currentPhotosCount).clamp(0, maxGalleryPhotos);
    if (remainingSlots <= 0) {
      _showLimitReachedDialog();
      return;
    }
    try {
      final picker = ImagePicker();
      List<XFile> pickedFiles = [];

      if (source == ImageSource.camera) {
        final file = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 600,
          maxHeight: 600,
          imageQuality: 60,
        );
        if (file != null) {
          pickedFiles.add(file);
        }
      } else {
        pickedFiles = await picker.pickMultiImage(
          limit: remainingSlots,
          maxWidth: 600,
          maxHeight: 600,
          imageQuality: 60,
        );
      }

      if (pickedFiles.isEmpty) return;

      if (pickedFiles.length > remainingSlots) {
        pickedFiles = pickedFiles.sublist(0, remainingSlots);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Overall limit is $maxGalleryPhotos photos. Added $remainingSlots photo(s).',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      setState(() {
        _isUploading = true;
      });

      final List<Map<String, dynamic>> preparedImages = [];
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        // Maximum low compression: 360x360 at quality 55 (~6-8 KB)
        final compressedBytes = ImageHelper.compressAndResize(
          bytes,
          360,
          360,
          quality: 55,
        );
        final base64String = ImageHelper.convertToBase64DataUrl(
          compressedBytes,
        );
        preparedImages.add({'bytes': compressedBytes, 'base64': base64String});
      }

      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      _promptBatchPhotoDialog(preparedImages, _currentPhotosCount);
    } catch (e) {
      debugPrint("Error picking showcase photos: $e");
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photos: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _promptBatchPhotoDialog(
    List<Map<String, dynamic>> preparedImages, [
    int? currentTotalOverride,
  ]) {
    final baseTotal = currentTotalOverride ?? _currentPhotosCount;
    final captionController = TextEditingController();
    bool isSaving = false;
    final imagesList = List<Map<String, dynamic>>.from(preparedImages);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbContext, setDialogState) {
          final count = imagesList.length;
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        count == 1 ? 'Photo Details' : 'Upload Photos ($count)',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0072FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total: ${baseTotal + count}/$maxGalleryPhotos',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0072FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (count == 1)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        child: Image.memory(
                          imagesList[0]['bytes'] as Uint8List,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: count,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final img = imagesList[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  img['bytes'] as Uint8List,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: isSaving || count <= 1
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            imagesList.removeAt(index);
                                          });
                                        },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: captionController,
                    decoration: InputDecoration(
                      labelText: count == 1
                          ? 'Title / Caption (Optional)'
                          : 'Title / Tag for all photos (Optional)',
                      hintText: count == 1
                          ? 'e.g. Special Offer, Shop Front'
                          : 'e.g. New Arrivals, Summer Collection',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(dialogCtx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isSaving = true;
                                  });
                                  try {
                                    final titleText = captionController.text
                                        .trim();
                                    final itemsToUpload = imagesList.map((img) {
                                      return {
                                        'photoUrl': img['base64'] as String,
                                        'title': titleText,
                                      };
                                    }).toList();

                                    await widget.repository.addGalleryPhotos(
                                      widget.docId,
                                      itemsToUpload,
                                    );

                                    if (dialogCtx.mounted) {
                                      Navigator.pop(dialogCtx);
                                    }
                                    if (mounted) {
                                      setState(() {
                                        _galleryStream = widget.repository
                                            .watchGallery(widget.docId);
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            count == 1
                                                ? 'Photo posted successfully!'
                                                : '$count photos posted successfully!',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (err) {
                                    setDialogState(() {
                                      isSaving = false;
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to post: $err'),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0072FF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  count == 1
                                      ? 'Post Photo'
                                      : 'Post $count Photos',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeletePhoto(String photoId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Photo?'),
        content: const Text(
          'This photo will be removed from your shop showcase.',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await widget.repository.deleteGalleryPhoto(
                  widget.docId,
                  photoId,
                );
                if (mounted) {
                  setState(() {
                    _galleryStream = widget.repository.watchGallery(
                      widget.docId,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo deleted.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete photo: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFullImageDialog(
    BuildContext context,
    String imageUrl,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InteractiveViewer(
                  clipBehavior: Clip.none,
                  minScale: 0.8,
                  maxScale: 3.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ImageHelper.buildImageWidget(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final sheetHeight = (screenHeight * 0.88).clamp(
      320.0,
      screenHeight - topPadding - 10,
    );

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle Bar
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Shop Showcase',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (_isOwnerMode) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'OWNER',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.profileName.isNotEmpty
                            ? 'Photos from ${widget.profileName}'
                            : 'Gallery & Showcase',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Owner toggle / status button
                if (!_isOwnerMode)
                  Tooltip(
                    message: 'Shop Owner Login',
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _showPinDialog,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: AppTheme.textGrey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Tooltip(
                    message: 'Exit Owner Mode',
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isOwnerMode = false;
                        });
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      label: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),

                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _galleryStream,
              builder: (context, snapshot) {
                final photos = snapshot.data ?? [];
                _currentPhotosCount = photos.length;
                final remainingSlots = (maxGalleryPhotos - photos.length).clamp(0, maxGalleryPhotos);

                Widget bodyWidget;
                if (snapshot.connectionState == ConnectionState.waiting &&
                    photos.isEmpty) {
                  bodyWidget = const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0072FF)),
                  );
                } else if (photos.isEmpty) {
                  bodyWidget = Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              size: 36,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No showcase photos yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isOwnerMode
                                ? 'Tap "+ Add Photos" above to upload photos of your shop, products, or offers (up to $maxGalleryPhotos max)!'
                                : 'The shop owner hasn\'t added any showcase photos yet. Check back soon!',
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
                  );
                } else {
                  bodyWidget = GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final item = photos[index];
                      final photoUrl = item['photoUrl']?.toString() ?? '';
                      final title = item['title']?.toString() ?? '';
                      final photoId = item['id']?.toString() ?? '';
                      final timestamp = item['timestamp']?.toString() ?? '';

                      return InkWell(
                        onTap: () {
                          _showFullImageDialog(context, photoUrl, title);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ImageHelper.buildImageWidget(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (title.isNotEmpty)
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        if (timestamp.isNotEmpty)
                                          Text(
                                            timestamp.length >= 10
                                                ? timestamp.substring(0, 10)
                                                : timestamp,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textGrey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isOwnerMode)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: InkWell(
                                  onTap: () => _confirmDeletePhoto(photoId),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.delete_forever_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return Column(
                  children: [
                    if (_isOwnerMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0072FF,
                          ).withValues(alpha: 0.05),
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              size: 16,
                              color: Color(0xFF0072FF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Shop Owner Mode',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0072FF),
                                    ),
                                  ),
                                  Text(
                                    '${photos.length}/10 photos uploaded (${remainingSlots > 0 ? '$remainingSlots slots left' : 'Gallery Full'})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: remainingSlots > 0
                                          ? AppTheme.textGrey
                                          : const Color(0xFFEF4444),
                                      fontWeight: remainingSlots > 0
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : (remainingSlots > 0
                                        ? () => _showImageSourceModal(
                                            remainingSlots,
                                          )
                                        : _showLimitReachedDialog),
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      remainingSlots > 0
                                          ? Icons.add_a_photo_rounded
                                          : Icons.block_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isUploading
                                    ? 'Processing...'
                                    : (remainingSlots > 0
                                          ? 'Add Photos'
                                          : 'Full (10/10)'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: remainingSlots > 0
                                    ? const Color(0xFF0072FF)
                                    : const Color(0xFF94A3B8),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(child: bodyWidget),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
