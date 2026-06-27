import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
const AdminLoginScreen({super.key});

@override
State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
final emailController = TextEditingController();
final passwordController = TextEditingController();

bool loading = false;

Future<void> loginAdmin() async {
final email = emailController.text.trim();
final password = passwordController.text.trim();


if (email.isEmpty || password.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please enter admin email and password"),
    ),
  );
  return;
}

setState(() => loading = true);

try {
  final credential = await FirebaseAuth.instance
      .signInWithEmailAndPassword(
    email: email,
    password: password,
  );

  final uid = credential.user!.uid;
  await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .set({
  'isOnline': true,
  'lastSeen': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
final token = await FirebaseMessaging.instance.getToken();

await FirebaseFirestore.instance
    .collection("admins")
    .doc("ADMIN_SUPPORT")
    .set({
  "uid": uid,
  "name": "ADMIN SUPPORT",
  "email": email,
  "fcmToken": token,
  "isOnline": true,
  "lastSeen": FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();

  // DEBUG POPUP
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Admin Debug"),
      content: SingleChildScrollView(
        child: Text(
          "UID:\n$uid\n\n"
          "DOC EXISTS:\n${doc.exists}\n\n"
          "DOC DATA:\n${doc.data()}",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );

  if (!doc.exists) {
    throw Exception(
      "No Firestore profile found for this account.",
    );
  }

  final data = doc.data() ?? {};

  final role =
      (data['role'] ?? '').toString().trim().toLowerCase();

  if (role != 'admin') {
    throw Exception(
      "Not an admin account. Role found: $role",
    );
  }

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminDashboard(),
    ),
    (route) => false,
  );
} on FirebaseAuthException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        e.message ?? "Admin login failed",
      ),
    ),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
    ),
  );
}

if (mounted) {
  setState(() => loading = false);
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
appBar: AppBar(
title: const Text("Admin Login"),
),
body: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
TextField(
controller: emailController,
decoration: const InputDecoration(
labelText: "Admin Email",
border: OutlineInputBorder(),
),
),
const SizedBox(height: 15),
TextField(
controller: passwordController,
obscureText: true,
decoration: const InputDecoration(
labelText: "Password",
border: OutlineInputBorder(),
),
),
const SizedBox(height: 25),
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: loading ? null : loginAdmin,
child: loading
? const CircularProgressIndicator()
: const Text("Login as Admin"),
),
),
],
),
),
);
}
}


