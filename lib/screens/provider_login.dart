import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'provider_dashboard.dart';
import '../services/notification_service.dart';

class ProviderLogin extends StatefulWidget {
  const ProviderLogin({super.key});

  @override
  State<ProviderLogin> createState() => _ProviderLoginState();
}


class _ProviderLoginState extends State<ProviderLogin> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

 Future<void> loginProvider() async {
  if (isLoading) return;

  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields")),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    // 🔐 AUTH LOGIN
    final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception("Login failed: no user returned");
    }

    final uid = user.uid;

// =========================
// SAVE FCM TOKEN
// =========================
final token = await FirebaseMessaging.instance.getToken();

debugPrint("==================================");
debugPrint("PROVIDER FCM TOKEN: $token");
debugPrint("==================================");


NotificationService.listenForChats(uid);
NotificationService.listenForRequestUpdates(uid);
 NotificationService.listenForAdminChats(uid);

await FirebaseFirestore.instance
    .collection('providers')
    .doc(uid)
    .set({
  'fcmToken': token,
  'isOnline': true,
  'lastSeen': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

    // 🔍 GET PROVIDER DATA
    final doc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .get();

    if (!doc.exists) {
      throw Exception("Provider profile not found");
    }

    final data = doc.data() ?? {};

    final providerName = data['name'] ?? 'Provider';

    final status = (data['status'] ?? 'active').toString().toLowerCase();
    final role = (data['role'] ?? 'provider').toString().toLowerCase();

    // ❌ BLOCKED CHECK
    if (status == 'blocked') {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account blocked by admin"),
          backgroundColor: Colors.red,
        ),
      );

      await FirebaseAuth.instance.signOut();
      return;
    }

    // ❌ INACTIVE CHECK
    if (status == 'inactive') {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account deactivated. Contact admin."),
          backgroundColor: Colors.orange,
        ),
      );

      await FirebaseAuth.instance.signOut();
      return;
    }

    // ❌ ROLE CHECK
    if (role != 'provider') {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This is not a provider account"),
        ),
      );

      await FirebaseAuth.instance.signOut();
      return;
    }

    if (!mounted) return;

    // 🚀 GO TO DASHBOARD
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderDashboard(
          providerId: uid,
          providerName: providerName,
        ),
      ),
    );
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Auth error: ${e.message}")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login failed: $e")),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loginProvider,
                  child: const Text("Login"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}




