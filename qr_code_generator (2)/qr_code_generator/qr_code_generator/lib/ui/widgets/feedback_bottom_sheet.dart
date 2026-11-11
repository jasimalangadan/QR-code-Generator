import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../../repositories/qr_repository.dart';
import '../../utils/image_helper.dart';
import '../../utils/video_helper.dart';
import 'video_player_dialog.dart';

class FeedbackBottomSheet extends StatefulWidget {
  final String docId;
  final String profileName;
  final QrRepository repository;

  const FeedbackBottomSheet({
    super.key,
    required this.docId,
    required this.profileName,
    required this.repository,
  });

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  bool _isWritingReview = false;
  int _selectedRating = 5;
  late final TextEditingController _nameController;
  late final TextEditingController _commentController;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  late Stream<List<Map<String, dynamic>>> _feedbackStream;
  String? _selectedPhotoBase64;
  Uint8List? _selectedPhotoBytes;
  bool _isProcessingPhoto = false;
  XFile? _selectedVideoFile;
  String? _selectedVideoName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _commentController = TextEditingController();
    _feedbackStream = widget.repository.watchFeedbacks(widget.docId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    _nameFocusNode.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 60,
      );
      if (pickedFile == null) return;

      setState(() {
        _isProcessingPhoto = true;
      });

      final bytes = await pickedFile.readAsBytes();
      // Maximum low compression for customer reviews:
      // Limits to 360x360 with quality 55 (~6-9 KB per photo)
      // to keep Firestore profile documents and REST payloads lightweight.
      final compressedBytes = ImageHelper.compressAndResize(
        bytes,
        360,
        360,
        quality: 55,
      );
      final base64String = ImageHelper.convertToBase64DataUrl(compressedBytes);

      if (mounted) {
        setState(() {
          _selectedPhotoBytes = compressedBytes;
          _selectedPhotoBase64 = base64String;
          _isProcessingPhoto = false;
        });
      }
    } catch (e) {
      debugPrint("Error picking review photo: $e");
      if (mounted) {
        setState(() {
          _isProcessingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select photo: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 15),
      );
      if (pickedFile == null) return;

      setState(() {
        _selectedVideoFile = pickedFile;
        _selectedVideoName = pickedFile.name;
        // Clear photo so only 1 media attachment is used
        _selectedPhotoBytes = null;
        _selectedPhotoBase64 = null;
      });
    } catch (e) {
      debugPrint("Error picking review video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select video: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                'Attach Photo or Video (Max 15s)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
                        _pickImage(ImageSource.camera);
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
                        _pickImage(ImageSource.gallery);
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
                              color: Color(0xFF10B981),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickVideo(ImageSource.camera);
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
                            Icon(Icons.videocam_rounded, size: 28, color: Color(0xFFEF4444)),
                            SizedBox(height: 8),
                            Text('Record Video (15s)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
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
                        _pickVideo(ImageSource.gallery);
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
                            Icon(Icons.video_library_rounded, size: 28, color: Color(0xFF0072FF)),
                            SizedBox(height: 8),
                            Text('Gallery Video (15s)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
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

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
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
            Positioned(
              top: 10,
              right: 10,
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

  String _formatFeedbackDate(dynamic timestamp) {
    if (timestamp == null) return 'Recent';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (_) {
        return 'Recent';
      }
    } else {
      return 'Recent';
    }

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final maxAvailableHeight = screenHeight - bottomInset - topPadding;
    final sheetHeight = (screenHeight * 0.85).clamp(280.0, maxAvailableHeight);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
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
                        colors: [Color(0xFFFF9900), Color(0xFFFF5252)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9900).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.rate_review_rounded,
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
                        const Text(
                          'Customer Feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.profileName.isNotEmpty
                              ? 'Reviews for ${widget.profileName}'
                              : 'Community ratings & feedback',
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

            // Content Body
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _feedbackStream,
                builder: (context, snapshot) {
                  final feedbacks = snapshot.data ?? [];
                  final double avgRating = feedbacks.isEmpty
                      ? 5.0
                      : (feedbacks
                                .map(
                                  (f) => (f['rating'] is num
                                      ? (f['rating'] as num).toDouble()
                                      : 5.0),
                                )
                                .reduce((a, b) => a + b) /
                            feedbacks.length);

                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary Stats Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF8FAFC),
                                      Color(0xFFF1F5F9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              feedbacks.isEmpty
                                                  ? '5.0'
                                                  : avgRating.toStringAsFixed(
                                                      1,
                                                    ),
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFFB800),
                                              size: 26,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          feedbacks.isEmpty
                                              ? 'No reviews yet'
                                              : '${feedbacks.length} ${feedbacks.length == 1 ? "Review" : "Reviews"}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isWritingReview = !_isWritingReview;
                                          if (!_isWritingReview) {
                                            _selectedPhotoBase64 = null;
                                            _selectedPhotoBytes = null;
                                          }
                                        });
                                        if (_isWritingReview) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (_scrollController
                                                    .hasClients) {
                                                  _scrollController.animateTo(
                                                    0,
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeOut,
                                                  );
                                                }
                                              });
                                        }
                                      },
                                      icon: Icon(
                                        _isWritingReview
                                            ? Icons.close_rounded
                                            : Icons.add_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        _isWritingReview
                                            ? 'Close'
                                            : 'Add Feedback',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isWritingReview
                                            ? const Color(0xFF64748B)
                                            : AppTheme.primaryPurple,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Expandable Write Review Form
                              if (_isWritingReview) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryPurple.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryPurple
                                            .withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Rate your experience',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: List.generate(5, (index) {
                                          final starValue = index + 1;
                                          final isFilled =
                                              starValue <= _selectedRating;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedRating = starValue;
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: Icon(
                                                isFilled
                                                    ? Icons.star_rounded
                                                    : Icons
                                                          .star_outline_rounded,
                                                color: const Color(0xFFFFB800),
                                                size: 34,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _nameController,
                                        focusNode: _nameFocusNode,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          labelText: 'Your Name (Optional)',
                                          hintText: 'e.g. John Doe',
                                          prefixIcon: const Icon(
                                            Icons.person_outline_rounded,
                                            size: 20,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _commentController,
                                        focusNode: _commentFocusNode,
                                        maxLines: 3,
                                        textInputAction: TextInputAction.done,
                                        decoration: InputDecoration(
                                          labelText: 'Feedback / Comment',
                                          hintText:
                                              'Share your thoughts, review, or suggestions...',
                                          alignLabelWithHint: true,
                                          contentPadding: const EdgeInsets.all(
                                            14,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Media Attachment Section
                                      if (_selectedVideoFile != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0072FF).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: const Color(0xFF0072FF).withValues(alpha: 0.2)),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF0072FF),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Row(
                                                        children: [
                                                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
                                                          SizedBox(width: 4),
                                                          Text('Video Attached (Max 15s)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(_selectedVideoName ?? 'video.mp4', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textGrey),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedVideoFile = null;
                                                      _selectedVideoName = null;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else if (_isProcessingPhoto)
                                        Container(
                                          height: 60,
                                          margin: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: const Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: AppTheme
                                                            .primaryPurple,
                                                      ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Processing photo...',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textGrey,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else if (_selectedPhotoBytes != null)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryPurple
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child: Image.memory(
                                                      _selectedPhotoBytes!,
                                                      width: 58,
                                                      height: 58,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: -4,
                                                    right: -4,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedPhotoBytes =
                                                              null;
                                                          _selectedPhotoBase64 =
                                                              null;
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              3,
                                                            ),
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Color(
                                                                0xFFEF4444,
                                                              ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: const Icon(
                                                          Icons.close_rounded,
                                                          size: 12,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .check_circle_rounded,
                                                          color: Color(
                                                            0xFF10B981,
                                                          ),
                                                          size: 15,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Photo Attached',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppTheme
                                                                .textDark,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    const Text(
                                                      'Will be posted with review',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppTheme.textGrey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    GestureDetector(
                                                      onTap:
                                                          _showImageSourceDialog,
                                                      child: const Text(
                                                        'Change photo',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppTheme
                                                              .primaryPurple,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: InkWell(
                                            onTap: _showImageSourceDialog,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFCBD5E1,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme
                                                          .primaryPurple
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.add_a_photo_rounded,
                                                      size: 17,
                                                      color: AppTheme
                                                          .primaryPurple,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Attach Photo or Video (Optional)',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppTheme
                                                                .textDark,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Upload a photo or 15-second video to support your review',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AppTheme
                                                                .textGrey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 20,
                                                    color: AppTheme.textGrey,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isSubmitting
                                              ? null
                                              : () async {
                                                  final messenger =
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      );
                                                  if (_commentController.text
                                                          .trim()
                                                          .isEmpty &&
                                                      _selectedPhotoBase64 ==
                                                          null) {
                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Please enter your feedback or attach a photo before submitting.',
                                                        ),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  setState(() {
                                                    _isSubmitting = true;
                                                  });
                                                  try {
                                                    final Map<String, dynamic>
                                                    feedbackData = {
                                                      'name':
                                                          _nameController.text
                                                              .trim()
                                                              .isEmpty
                                                          ? 'Anonymous Customer'
                                                          : _nameController.text
                                                                .trim(),
                                                      'comment':
                                                          _commentController
                                                              .text
                                                              .trim(),
                                                      'rating': _selectedRating,
                                                      'timestamp': DateTime.now()
                                                          .toIso8601String(),
                                                    };
                                                    if (_selectedPhotoBase64 != null) {
                                                      feedbackData['photoUrl'] = _selectedPhotoBase64;
                                                    }
                                                    if (_selectedVideoFile != null) {
                                                      final videoUrl = await VideoHelper.uploadVideo(
                                                        profileId: widget.docId,
                                                        videoFile: _selectedVideoFile!,
                                                      );
                                                      feedbackData['videoUrl'] = videoUrl;
                                                      feedbackData['mediaType'] = 'video';
                                                    }
                                                    await widget.repository
                                                        .submitFeedback(
                                                          widget.docId,
                                                          feedbackData,
                                                        );
                                                    _nameController.clear();
                                                    _commentController.clear();
                                                    _selectedPhotoBase64 = null;
                                                    _selectedPhotoBytes = null;
                                                    _selectedVideoFile = null;
                                                    _selectedVideoName = null;
                                                    _nameFocusNode.unfocus();
                                                    _commentFocusNode.unfocus();
                                                    if (mounted) {
                                                      setState(() {
                                                        _isSubmitting = false;
                                                        _isWritingReview =
                                                            false;
                                                        _feedbackStream = widget
                                                            .repository
                                                            .watchFeedbacks(
                                                              widget.docId,
                                                            );
                                                      });
                                                      messenger.showSnackBar(
                                                        const SnackBar(
                                                          content: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .check_circle_rounded,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Thank you! Your feedback has been submitted.',
                                                              ),
                                                            ],
                                                          ),
                                                          backgroundColor:
                                                              Color(0xFF10B981),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        ),
                                                      );
                                                    }
                                                  } catch (err) {
                                                    if (mounted) {
                                                      setState(() {
                                                        _isSubmitting = false;
                                                      });
                                                      messenger.showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to submit feedback: $err',
                                                          ),
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                          icon: _isSubmitting
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.send_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                          label: Text(
                                            _isSubmitting
                                                ? 'Submitting...'
                                                : 'Submit Feedback',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryPurple,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              const Text(
                                'All Feedbacks & Reviews',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Reviews List
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          feedbacks.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        )
                      else if (feedbacks.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 40,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.rate_review_outlined,
                                      size: 32,
                                      color: AppTheme.textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'No feedback yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Be the first to share your thoughts and help others!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = feedbacks[index];
                              final name = (item['name'] ?? 'Customer')
                                  .toString();
                              final comment = (item['comment'] ?? '')
                                  .toString();
                              final rating = item['rating'] is num
                                  ? (item['rating'] as num).toInt()
                                  : 5;
                              final dateStr = _formatFeedbackDate(
                                item['createdAt'] ?? item['timestamp'],
                              );
                              final initial = name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'C';
                              final photoUrl =
                                  (item['photoUrl'] ??
                                          item['photo'] ??
                                          item['image'] ??
                                          '')
                                      .toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppTheme
                                              .primaryPurple
                                              .withValues(alpha: 0.12),
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryPurple,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Row(
                                                    children: List.generate(5, (
                                                      starIdx,
                                                    ) {
                                                      return Icon(
                                                        starIdx < rating
                                                            ? Icons.star_rounded
                                                            : Icons
                                                                  .star_outline_rounded,
                                                        size: 14,
                                                        color: const Color(
                                                          0xFFFFB800,
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    dateStr,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.textGrey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (comment.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        comment,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF334155),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    if (item['videoUrl'] != null && item['videoUrl'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      InkWell(
                                        onTap: () => VideoPlayerDialog.show(
                                          context,
                                          videoUrl: item['videoUrl'].toString(),
                                          title: 'Video Review by $name',
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0072FF).withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF0072FF).withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF0072FF),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                              ),
                                              const SizedBox(width: 10),
                                              const Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Watch Video Review',
                                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0072FF)),
                                                  ),
                                                  Text(
                                                    'Tap to play video (Max 15s)',
                                                    style: TextStyle(fontSize: 10, color: AppTheme.textGrey),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (photoUrl.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      GestureDetector(
                                        onTap: () => _showFullImageDialog(
                                          context,
                                          photoUrl,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 180,
                                                    ),
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE2E8F0,
                                                    ),
                                                  ),
                                                ),
                                                child: ImageHelper.buildImageWidget(
                                                  photoUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      const SizedBox.shrink(),
                                                  loadingWidget: Container(
                                                    height: 120,
                                                    color: const Color(
                                                      0xFFF1F5F9,
                                                    ),
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppTheme
                                                                .primaryPurple,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 8,
                                                bottom: 8,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.65,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .fullscreen_rounded,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'View Photo',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }, childCount: feedbacks.length),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
