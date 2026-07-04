import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gida_services/services/notification_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';
import 'provider_dashboard.dart';
import 'provider_login.dart';
import 'admin_dashboard.dart';
import '../services/profile_image_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

Future<void> saveFCMToken(String uid) async {
  final token = await FirebaseMessaging.instance.getToken();

  if (token == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .set({
    'fcmToken': token,
  }, SetOptions(merge: true));
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  // Registration fields
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final locationController = TextEditingController();

  bool loading = false;
  bool isRegister = false;
  bool acceptedTerms = false;

  // =========================
  // PROFILE PICTURE
  // =========================
  File? selectedImage;

  // =========================
  // PICK PROFILE PICTURE
  // =========================
  Future<void> pickProfilePicture() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () async {
                  Navigator.pop(context);

                  final image =
                      await ProfileImageService.pickFromCamera();

                  if (image != null) {
                    setState(() {
                      selectedImage = image;
                    });
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);

                  final image =
                      await ProfileImageService.pickFromGallery();

                  if (image != null) {
                    setState(() {
                      selectedImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // SET USER ONLINE
  // =========================
  Future<void> setOnline(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================
  // TERMS & CONDITIONS
  // =========================
  void showTerms() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Conditions"),
        content: const SingleChildScrollView(
          child: Text(
            """
1. Users must provide accurate information.
2. Do not misuse the platform or fake requests.
3. Payments and transactions are your responsibility.
4. Providers and users must respect each other.
5. Admin has the right to suspend accounts that violate rules.
6. Data may be stored for service improvement.

By continuing, you agree to follow all rules of this platform.
""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // =========================
  // LOGIN
  // =========================
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and password")),
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

      await setOnline(uid);
      await saveFCMToken(uid);

      // Start notification listeners after login
      NotificationService.listenForChats(uid);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data() ?? {};

      final role = (data['role'] ?? 'user')
          .toString()
          .toLowerCase();

      final name = data['name'] ?? 'User';

      final status = (data['status'] ?? 'active')
          .toString()
          .toLowerCase();

      if (status == 'blocked') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() => loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Access Denied: Account blocked by admin",
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      if (status == 'inactive') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() => loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Account deactivated. Contact admin.",
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      if (!mounted) return;

      if (role == 'provider') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDashboard(
              providerId: uid,
              providerName: name,
            ),
          ),
          (route) => false,
        );
      } else if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login failed: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }
  // =========================
  Future<void> adminLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter admin email & password")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      await setOnline(uid);
      await saveFCMToken(uid);

      NotificationService.listenForChats(uid);
      NotificationService.listenForRequestUpdates(uid);

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final role = (doc.data()?['role'] ?? '').toString().toLowerCase();

      if (role != 'admin') {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Not an admin account"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Admin login failed: $e")),
      );
    }

    setState(() => loading = false);
  }

  // =========================
  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    // ✅ TERMS REQUIRED
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept Terms & Conditions")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;
      await saveFCMToken(uid);
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'location': location,
        'role': 'user',
        'status': 'active',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Register failed: $e")),
      );
    }

    setState(() => loading = false);
  }

  // =========================
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRegister ? "Register" : "Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isRegister)
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            if (isRegister)
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number"),
              ),

            if (isRegister)
  TextField(
    controller: addressController,
    decoration: const InputDecoration(labelText: "Address"),
  ),

            if (isRegister)
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),

            const SizedBox(height: 15),

            // =========================
            // ✅ TERMS CHECKBOX (ADDED)
            if (isRegister)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        acceptedTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: showTerms,
                      child: const Text(
                        "I agree to Terms & Conditions",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            if (loading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: isRegister ? register : login,
                child: Text(isRegister ? "Register" : "Login"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Admin Login"),
                onPressed: adminLogin,
              ),
              TextButton(
                onPressed: () => setState(() => isRegister = !isRegister),
                child: Text(isRegister ? "Go to Login" : "Create Account"),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProviderLogin(),
                    ),
                  );
                },
                child: const Text("Provider Login"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


