import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../ui/theme.dart';

class ImageHelper {
  /// Compresses and resizes the image bytes to stay within [maxWidth] and [maxHeight].
  /// Returns compressed JPEG bytes. Runs inside a compute/background thread if supported,
  /// but standard call is safe since images are small.
  static Uint8List compressAndResize(
    Uint8List bytes,
    int maxWidth,
    int maxHeight, {
    int quality = 80,
  }) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Determine new dimensions maintaining aspect ratio
      int? newWidth;
      int? newHeight;

      if (image.width > image.height) {
        newWidth = maxWidth;
      } else {
        newHeight = maxHeight;
      }

      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic,
      );

      return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
    } catch (e) {
      debugPrint("Error compressing image in ImageHelper: $e");
      return bytes;
    }
  }

  /// Converts raw image bytes into a Base64 data URL string.
  static String convertToBase64DataUrl(Uint8List bytes) {
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// Utility to check if a string is a Base64 image data URL.
  static bool isBase64DataUrl(String pathOrUrl) {
    return pathOrUrl.startsWith('data:image/') && pathOrUrl.contains('base64,');
  }

  /// Universal Image builder supporting:
  /// 1. Base64 encoded JPEG/PNG data URL strings (e.g. data:image/jpeg;base64,...)
  /// 2. Remote HTTP/HTTPS network URLs
  /// 3. In-memory / Assets fallback
  static Widget buildImageWidget(
    String pathOrUrl, {
    required BoxFit fit,
    Widget? errorWidget,
    Widget? loadingWidget,
    double? width,
    double? height,
  }) {
    if (pathOrUrl.trim().isEmpty) {
      return errorWidget ??
          const Icon(Icons.broken_image, color: AppTheme.textGrey);
    }

    if (isBase64DataUrl(pathOrUrl)) {
      try {
        final base64Content = pathOrUrl.split('base64,')[1];
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                const Icon(Icons.broken_image, color: AppTheme.textGrey);
          },
        );
      } catch (e) {
        debugPrint("Error decoding Base64 image in Widget: $e");
        return errorWidget ??
            const Icon(Icons.broken_image, color: AppTheme.textGrey);
      }
    }

    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return loadingWidget ??
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              const Icon(Icons.broken_image, color: AppTheme.textGrey);
        },
      );
    }

    // Default Asset fallback
    return Image.asset(
      pathOrUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            const Icon(Icons.broken_image, color: AppTheme.textGrey);
      },
    );
  }

  /// Returns the logo icon for each platform key using image assets from assets/images/final_images_backup/
  /// with FontAwesome fallback icons.
  static Widget buildSocialLogo(String platform, {double size = 24}) {
    final p = platform.toLowerCase().trim();

    switch (p) {
      case 'instagram':
        return _buildAssetIcon(
          'assets/images/final_images_backup/instagram.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.instagram,
          fallbackColor: const Color(0xFFE1306C),
          scale: 1.0,
        );

      case 'telegram':
      case 'tg':
        return _buildAssetIcon(
          'assets/images/final_images_backup/telegram.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.telegram,
          fallbackColor: const Color(0xFF229ED9),
          scale: 1.0,
        );

      case 'google':
      case 'googlereview':
      case 'google review':
      case 'google_review':
      case 'google_write_review':
      case 'google write review':
        return _buildAssetIcon(
          'assets/images/final_images_backup/google_reviews.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.google,
          fallbackColor: const Color(0xFF4285F4),
          scale: 1.0,
        );
      case 'whatsapp':
        return _buildAssetIcon(
          'assets/images/final_images_backup/whatsapp.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.whatsapp,
          fallbackColor: const Color(0xFF25D366),
          scale: 1.0,
        );
      case 'whatsapp_group':
      case 'whatsapp group':
      case 'whatsappgroup':
        return _buildWhatsAppGroupLogo(size: size);

      case 'custom':
      case 'website':
        return _buildAssetIcon(
          'assets/images/final_images_backup/website.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.globe,
          fallbackColor: const Color(0xFF00A8FF),
          scale: 1.0,
        );

      case 'facebook':
        return _buildAssetIcon(
          'assets/images/final_images_backup/facebook.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.facebook,
          fallbackColor: const Color(0xFF1877F2),
          scale: 1.0,
        );
      case 'linkedin':
        return _buildAssetIcon(
          'assets/images/final_images_backup/linkedIn.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.linkedinIn,
          fallbackColor: const Color(0xFF0A66C2),
          scale: 1.0,
        );
      case 'tiktok':
        return _buildAssetIcon(
          'assets/images/final_images_backup/tiktok.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.tiktok,
          fallbackColor: const Color(0xFF000000),
          scale: 1.0,
        );
      case 'x':
      case 'twitter':
      case 'x(twitter)':
      case 'x (twitter)':
        return _buildAssetIcon(
          'assets/images/final_images_backup/x.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.xTwitter,
          fallbackColor: const Color(0xFF000000),
          scale: 1.0,
        );
      case 'threads':
        return _buildAssetIcon(
          'assets/images/final_images_backup/threads.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.threads,
          fallbackColor: const Color(0xFF000000),
          scale: 1.0,
        );
      case 'pinterest':
        return _buildAssetIcon(
          'assets/images/final_images_backup/pinterest.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.pinterest,
          fallbackColor: const Color(0xFFE60023),
          scale: 1.0,
        );

      case 'location':
      case 'location_share':
      case 'location share':
        return _buildAssetIcon(
          'assets/images/final_images_backup/location.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.locationDot,
          fallbackColor: const Color(0xFFEA4335),
          scale: 1.0,
        );
      case 'contact':
      case 'contact_us':
      case 'contact us':
      case 'phone':
        return _buildAssetIcon(
          'assets/images/final_images_backup/phone.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.phone,
          fallbackColor: const Color(0xFF10B981),
          scale: 0.85,
        );
      case 'email':
      case 'gmail':
        return _buildAssetIcon(
          'assets/images/final_images_backup/email.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.envelope,
          fallbackColor: const Color(0xFFEA4335),
          scale: 1.0,
        );
      case 'youtube':
        return _buildAssetIcon(
          'assets/images/final_images_backup/youtube.png',
          size: size,
          fallbackIcon: FontAwesomeIcons.youtube,
          fallbackColor: const Color(0xFFFF0000),
          scale: 1.0,
        );
      case 'feedback':
      case 'feedback_reviews':
      case 'feedback and reviews':
      case 'review':
      case 'reviews':
        final boxSize = size * 0.84;
        return Center(
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9900), Color(0xFFFF5252)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(boxSize * 0.24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9900).withValues(alpha: 0.3),
                  blurRadius: (boxSize * 0.15).clamp(2.0, 6.0),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.rate_review_rounded,
                size: boxSize * 0.58,
                color: Colors.white,
              ),
            ),
          ),
        );
      case 'gallery':
      case 'photo_gallery':
      case 'photos':
      case 'showcase':
        final boxSize = size * 0.84;
        return Center(
          child: Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(boxSize * 0.24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                  blurRadius: (boxSize * 0.15).clamp(2.0, 6.0),
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.photo_library_rounded,
                size: boxSize * 0.58,
                color: Colors.white,
              ),
            ),
          ),
        );
      default:
        return Center(
          child: FaIcon(
            FontAwesomeIcons.link,
            size: size,
            color: AppTheme.textGrey,
          ),
        );
    }
  }

  static Widget _buildAssetIcon(
    String assetPath, {
    required double size,
    required dynamic fallbackIcon,
    required Color fallbackColor,
    double scale = 1.0,
  }) {
    return Center(
      child: Transform.scale(
        scale: scale,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Transform.scale(
              scale: 1 / scale,
              child: FaIcon(fallbackIcon, size: size, color: fallbackColor),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildWhatsAppGroupLogo({required double size}) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: const _WhatsAppBubblePainter(color: Color(0xFF25D366)),
            ),
            Positioned(
              left: size * 0.02,
              top: 0,
              bottom: size * 0.04,
              right: 0,
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.peopleGroup,
                  size: size * 0.44,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppBubblePainter extends CustomPainter {
  final Color color;

  const _WhatsAppBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final cx = w * 0.50;
    final cy = h * 0.47;
    final r = w * 0.41;

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..moveTo(w * 0.19, h * 0.72)
      ..lineTo(w * 0.10, h * 0.88)
      ..lineTo(w * 0.38, h * 0.85)
      ..close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _WhatsAppBubblePainter oldDelegate) =>
      oldDelegate.color != color;
}
