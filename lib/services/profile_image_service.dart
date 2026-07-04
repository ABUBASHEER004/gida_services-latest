import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick from Gallery
  static Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) return null;

    return File(image.path);
  }

  /// Take Photo
  static Future<File?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) return null;

    return File(image.path);
  }

  /// Compress image
  static Future<File> compress(File file) async {
    final dir = await getTemporaryDirectory();

    final target =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final compressed =
        await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: 70,
    );

    return File(compressed!.path);
  }

  /// Upload image to Firebase Storage
 static Future<String> uploadProfileImage(
  String uid,
  File image, {
  String folder = "users",
}) async {
    final compressed = await compress(image);

    final ref = FirebaseStorage.instance
        .ref()
       .child(folder)
        .child(uid)
        .child("profile.jpg");

    await ref.putFile(compressed);

    return await ref.getDownloadURL();
  }
}