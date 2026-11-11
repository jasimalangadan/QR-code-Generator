import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class VideoHelper {
  static const int maxVideoSizeBytes = 15 * 1024 * 1024; // 15 MB limit for 15-second video

  /// Uploads a video to Firebase Storage and returns its public streaming download URL.
  static Future<String> uploadVideo({
    required String profileId,
    required XFile videoFile,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final bytes = await videoFile.readAsBytes();

      if (bytes.length > maxVideoSizeBytes) {
        throw Exception(
          'Video size (${(bytes.length / (1024 * 1024)).toStringAsFixed(1)}MB) exceeds the 15MB limit. Please select a clip under 15 seconds.',
        );
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${videoFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('videos')
          .child(profileId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'profileId': profileId,
        },
      );

      final uploadTask = storageRef.putData(bytes, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress.clamp(0.0, 1.0));
          }
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("VideoHelper.uploadVideo error: $e");
      rethrow;
    }
  }
}
