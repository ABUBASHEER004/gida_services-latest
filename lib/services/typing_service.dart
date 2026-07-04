import 'package:cloud_firestore/cloud_firestore.dart';

class TypingService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .set({
      'typing': {
        userId: isTyping,
      }
    }, SetOptions(merge: true));
  }
}