import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileImageService {
  static final ImagePicker _picker = ImagePicker();

  // ==========================================
  // PICK FROM GALLERY
  // ==========================================
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

  // ==========================================
  // TAKE PHOTO
  // ==========================================
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

  // ==========================================
  // COMPRESS IMAGE
  // ==========================================
  static Future<File> compress(File image) async {
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

  // ==========================================
  // UPLOAD PROFILE IMAGE
  // ==========================================
  static Future<String?> uploadProfileImage({
    required String uid,
    required File image,
  }) async {
    try {
      final compressed = await compress(image);

      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child(uid)
          .child("profile.jpg");

      await ref.putFile(compressed);

      final url = await ref.getDownloadURL();

      debugPrint("Profile Image Uploaded:");
      debugPrint(url);

      return url;
    } catch (e) {
      debugPrint("Profile Upload Error: $e");
      return null;
    }
  }
}