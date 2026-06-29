import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class NotificationService {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<QuerySnapshot>? _chatSub;
  static StreamSubscription<QuerySnapshot>? _adminSub;
  static StreamSubscription<QuerySnapshot>? _requestSub;

  // =========================
  // INITIALIZE
  // =========================
 static Future<void> initialize() async {
  try {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: android,
    );

    await notifications.initialize(settings);

    final androidPlugin =
        notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'gida_chat_channel',
        'Chat Notifications',
        description: 'Notifications for chat messages',
        importance: Importance.high,
      ),
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final title =
          message.notification?.title ??
          message.data['title'] ??
          "New Message";

      final body =
          message.notification?.body ??
          message.data['body'] ??
          "";

      showNotification(title, body);
    });
  } catch (e) {
    debugPrint("Notification initialization failed: $e");
  }
}
  // =========================
  // SHOW LOCAL NOTIFICATION
  // =========================
 static Future<void> showNotification(
    String title,
    String body,
) async {

  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'gida_chat_channel',
    'Chat Notifications',
    channelDescription: 'Chat notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await notifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
  );
}
  // =========================
  // USER / PROVIDER CHATS
  // =========================
  static void listenForChats(String receiverId) {
  _chatSub?.cancel();

  _chatSub = FirebaseFirestore.instance
      .collectionGroup('messages')
      .where('receiverId', isEqualTo: receiverId)
      .snapshots()
      .listen((snapshot) async {
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final data = change.doc.data();

      if (data == null) continue;

      if (data['senderId'] == receiverId) continue;

      String senderName = "New Message";

      try {
        final senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['senderId'])
            .get();

        if (senderDoc.exists) {
          senderName = senderDoc.data()?['name'] ?? senderName;
        }
      } catch (_) {}

      await showNotification(
        senderName,
        data['message'] ?? '',
      );
    }
  });
}
  // =========================
  // ADMIN SUPPORT CHAT
  // =========================
 static void listenForAdminChats(String receiverId) {
  _adminSub?.cancel();

  _adminSub = FirebaseFirestore.instance
      .collectionGroup('messages')
      .where('receiverId', isEqualTo: receiverId)
      .snapshots()
      .listen((snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final data = change.doc.data();

      if (data == null) continue;

      if (data['chatType'] != 'admin_support') continue;

      showNotification(
        "Admin Support",
        data['message'] ?? '',
      );
    }
  });
}

  // =========================
  // REQUEST STATUS CHANGES
  // =========================
  static void listenForRequestUpdates(String providerId) {
    _requestSub?.cancel();

    _requestSub = FirebaseFirestore.instance
        .collection('requests')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.modified) {
          continue;
        }

        final data =
            change.doc.data() as Map<String, dynamic>?;

        if (data == null) continue;

        final status =
            data['status']?.toString() ?? 'updated';

        showNotification(
          "Request Update",
          "Request status changed to $status",
        );
      }
    });
  }

  // =========================
  // SAVE DEVICE TOKEN
  // =========================
 



static Future<String?> getToken() async {

  if (kIsWeb) {

    return await FirebaseMessaging.instance.getToken(

      vapidKey: "BIbm1dX1QeWGL4nkDkb7G5dAN0bkxl_XbliKx8nlA7bEH8lB81w3MKQW8IG1uzcJMbWPydr0_GGNjQvHV-yOna8",

    );

  }



  return await FirebaseMessaging.instance.getToken();

}

  // =========================
  // CLEANUP
  // =========================
  static void dispose() {
    _chatSub?.cancel();
    _adminSub?.cancel();
    _requestSub?.cancel();

    _chatSub = null;
    _adminSub = null;
    _requestSub = null;
  }
}