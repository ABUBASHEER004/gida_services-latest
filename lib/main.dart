import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/presence_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

  final title =
      message.notification?.title ??
      message.data['title'] ??
      "New Message";

  final body =
      message.notification?.body ??
      message.data['body'] ??
      "";

  await NotificationService.showNotification(
    title,
    body,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await NotificationService.initialize();

  // Run lifecycle wrapper
  runApp(const AppLifecycleHandler());
}

class AppLifecycleHandler extends StatefulWidget {
  const AppLifecycleHandler({super.key});

  @override
  State<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState
    extends State<AppLifecycleHandler>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    PresenceService.setOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    PresenceService.setOffline();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {

    switch (state) {
      case AppLifecycleState.resumed:
        PresenceService.setOnline();
        break;

      case AppLifecycleState.inactive:
        PresenceService.updateLastSeen();
        break;

      case AppLifecycleState.paused:
        PresenceService.setOffline();
        break;

      case AppLifecycleState.detached:
        PresenceService.setOffline();
        break;

      case AppLifecycleState.hidden:
        PresenceService.setOffline();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const GidaServicesApp();
  }
}

class GidaServicesApp extends StatelessWidget {
  const GidaServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gida Services',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}