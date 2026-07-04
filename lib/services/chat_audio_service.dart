import 'dart:io';

import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ChatAudioService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer player = AudioPlayer();

  static String? _currentPath;

  // ==========================
  // START RECORDING
  // ==========================
  static Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        return false;
      }

      final dir = await getTemporaryDirectory();

      _currentPath =
          "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _recorder.start(
        const RecordConfig(),
        path: _currentPath!,
      );

      return true;
    } catch (e) {
      debugPrint("Record Error: $e");
      return false;
    }
  }

  // ==========================
  // STOP RECORDING
  // ==========================
  static Future<File?> stopRecording() async {
    try {
      final path = await _recorder.stop();

      if (path == null) {
        return null;
      }

      return File(path);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ==========================
  // UPLOAD AUDIO
  // ==========================
  static Future<String?> uploadAudio({
    required String chatId,
    required File audio,
  }) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("chat_audio")
          .child(chatId)
          .child("${DateTime.now().millisecondsSinceEpoch}.m4a");

      await ref.putFile(audio);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ==========================
  // RECORD + UPLOAD
  // ==========================
  static Future<String?> stopAndUpload(
    String chatId,
  ) async {
    final file = await stopRecording();

    if (file == null) return null;

    return uploadAudio(
      chatId: chatId,
      audio: file,
    );
  }

  // ==========================
  // PLAY AUDIO
  // ==========================
  static Future<void> play(String url) async {
    await player.stop();
    await player.play(UrlSource(url));
  }

  static Future<void> pause() async {
    await player.pause();
  }

  static Future<void> stop() async {
    await player.stop();
  }
}