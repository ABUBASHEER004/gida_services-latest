import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_thumbnail/video_thumbnail.dart';


class ChatMediaService {
  static final ImagePicker _picker = ImagePicker();

  // =====================================================
  // IMAGE SECTION
  // =====================================================

  static Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      debugPrint("Gallery Error: $e");
      return null;
    }
  }

  static Future<File?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      debugPrint("Camera Error: $e");
      return null;
    }
  }

  static Future<File?> compressImage(File image) async {
    try {
      final tempDir = await getTemporaryDirectory();

      final targetPath =
          "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

      final XFile? compressed =
          await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (compressed == null) {
        return image;
      }

      return File(compressed.path);
    } catch (e) {
      debugPrint("Compression Error: $e");
      return image;
    }
  }

  static Future<String?> uploadImage({
    required String chatId,
    required File image,
  }) async {
    try {
      final compressed = await compressImage(image);

      if (compressed == null) return null;

      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}.jpg";

      final ref = FirebaseStorage.instance
          .ref()
          .child("chat_images")
          .child(chatId)
          .child(fileName);

      await ref.putFile(compressed);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload Image Error: $e");
      return null;
    }
  }

  static Future<String?> pickGalleryAndUpload(
    String chatId,
  ) async {
    final image = await pickFromGallery();

    if (image == null) return null;

    return uploadImage(
      chatId: chatId,
      image: image,
    );
  }

  static Future<String?> pickCameraAndUpload(
    String chatId,
  ) async {
    final image = await pickFromCamera();

    if (image == null) return null;

    return uploadImage(
      chatId: chatId,
      image: image,
    );
  }
  // ==========================
// Pick Video From Gallery
// ==========================
static Future<File?> pickVideoFromGallery() async {
  try {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video == null) return null;

    return File(video.path);
  } catch (e) {
    debugPrint("Gallery Video Error: $e");
    return null;
  }
}
// ==========================
// Record Video
// ==========================
static Future<File?> recordVideo() async {
  try {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );

    if (video == null) return null;

    return File(video.path);
  } catch (e) {
    debugPrint("Camera Video Error: $e");
    return null;
  }
}
// ==========================
// Generate Video Thumbnail
// ==========================
static Future<File?> generateThumbnail(File video) async {
  try {
    final tempDir = await getTemporaryDirectory();

    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: video.path,
      thumbnailPath: tempDir.path,
      imageFormat: ImageFormat.JPEG,
      quality: 70,
    );

    if (thumbPath == null) return null;

    return File(thumbPath);
  } catch (e) {
    debugPrint("Thumbnail Error: $e");
    return null;
  }
}
// ==========================
// Upload Video
// ==========================
static Future<Map<String, String>?> uploadVideo({
  required String chatId,
  required File video,
}) async {
  try {
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.mp4";

    final videoRef = FirebaseStorage.instance
        .ref()
        .child("chat_videos")
        .child(chatId)
        .child(fileName);

    await videoRef.putFile(video);

    final videoUrl =
        await videoRef.getDownloadURL();

    final thumbnail = await generateThumbnail(video);

    String thumbnailUrl = "";

    if (thumbnail != null) {
      final thumbRef = FirebaseStorage.instance
          .ref()
          .child("chat_video_thumbnails")
          .child(chatId)
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

      await thumbRef.putFile(thumbnail);

      thumbnailUrl =
          await thumbRef.getDownloadURL();
    }

    return {
      "videoUrl": videoUrl,
      "thumbnailUrl": thumbnailUrl,
    };
  } catch (e) {
    debugPrint("Video Upload Error: $e");
    return null;
  }
}
// ==========================
// Pick Gallery Video + Upload
// ==========================
static Future<Map<String, String>?> pickVideoGalleryAndUpload(
    String chatId) async {
  final video = await pickVideoFromGallery();

  if (video == null) return null;

  return uploadVideo(
    chatId: chatId,
    video: video,
  );
}// ==========================
// Record Video + Upload
// ==========================
static Future<Map<String, String>?> recordVideoAndUpload(
    String chatId) async {
  final video = await recordVideo();

  if (video == null) return null;

  return uploadVideo(
    chatId: chatId,
    video: video,
  );
}

  
  // =====================================================
  // VIDEO THUMBNAIL
  // =====================================================

  static Future<String?> createVideoThumbnail(
    String videoUrl,
  ) async {
    try {
      final dir = await getTemporaryDirectory();

      final thumbnail =
          await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );

      return thumbnail;
    } catch (e) {
      debugPrint("Thumbnail Error: $e");
      return null;
    }
  }
}