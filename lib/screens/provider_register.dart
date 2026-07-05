import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/profile_image_service.dart';

import 'provider_dashboard.dart';

class ProviderRegister extends StatefulWidget {
  const ProviderRegister({super.key});

  @override
  State<ProviderRegister> createState() => _ProviderRegisterState();
}

class _ProviderRegisterState extends State<ProviderRegister> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // NEW
  final locationController = TextEditingController();

  bool loading = false;
  bool acceptedTerms = false;

  // =========================
  // PROFILE IMAGE
  // =========================

  File? selectedImage;

  final List<String> serviceCategories = const [
    "Waste Pickup",
    "Shoe Seller",
    "Vegetables and Kayan Miya",
    "Meat Seller",
    "Plumber",
    "Tailor",
    "Electrician",
    "Carpenter",
    "Wielding",
    "Gas Refill",
    "Cleaning",
    "Rental Services",
    "Laundry",
    "Lesson Teacher",
    "Book Barbing Queue",
    "Book Saloon Queue",
    "Mai Kitso",
    "Mai Lalle",
    "Car Repair",
    "Car wash",
    "Phone Repair",
    "Gardener",
    "P.o.s Agent",
    "Fish Seller",
    "Order Snacks",
    "Delivery Services",
    "Food Delivery",
    "Napep Booking",
    "Electronic Appliances Repair",
    "Solar Installer",
    "Satellite Dish Repair",
    "Event Centre",
    "Laptop Seller",
    "Phone Seller",
    "TV Repair",
    "Flowers Seller",
    "Animal Clinic",
    "Chicken Booking, Feeds and Drugs",
    "Diagnostic Centre",
    "Hospital",
    "Building Materials",
    "Plumbing Materials Seller",
    "Carpentry Materials Seller",
    "Cement Seller",
    "Pharmacy",
    "Fabrics(shadda/yadi) Dealer",
    "Abaya Seller",
    "Football Kits Seller",
    "Kitchen Utensils Seller",
    "Restaurant",
    "Graphic Designer",
    "Building Labourer",
    "Construction Firms",
    "Real Estate Agent",
    "Pure Water Distributor",
    "Cloths/Baby Cloths Seller",
    "Make-up Saloon",
    "Printing, Writing and Reading Materials(Books)",
    "Electronic Appliances Seller",
    "Islamic Lesson Teacher",
    "Beds Seller",
    "Furniture Seller",
    "Suya Spot",
    "Animals Seller",
    "Rice Seller",
    "Grain Seller",
    "Yam Seller",
    "Fruits Seller",
    "Rubber Home Equipment Seller",
    "Palm oil/Groundnut oil Seller",
    "Petrol Black Marketer",
    "Women Beauty Products Seller",
    "Painter",
  ];

  String selectedService = "Waste Pickup";

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

                  final image = await ProfileImageService.pickFromCamera();

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

                  final image = await ProfileImageService.pickFromGallery();

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

  // ========================= TERMS DIALOG (FIXED LOCATION)
  void showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Conditions"),
        content: const SingleChildScrollView(
          child: Text(
            """
1. Provide accurate information.

2. Fake businesses are prohibited.

3. Treat customers respectfully.

4. Fraud leads to permanent suspension.

5. Admin may suspend providers violating platform rules.

By registering you agree to these conditions.
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
  // REGISTER PROVIDER
  // =========================
  // =========================
// REGISTER PROVIDER
// =========================
  Future<void> registerProvider() async {
    if (loading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final location = locationController.text.trim();

    // Validation
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must accept Terms & Conditions"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // =========================
      // CREATE ACCOUNT
      // =========================

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // =========================
      String? profileImage;

if (selectedImage != null) {
  try {
   profileImage = await ProfileImageService.uploadProfileImage(
  uid: uid,
  image: selectedImage!,
);
  } catch (e) {
    debugPrint("Image upload failed: $e");
  }
}

      // =========================
      // SAVE PROVIDER
      // =========================

      await FirebaseFirestore.instance.collection("providers").doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "phone": phone,
        "service": selectedService,
        "address": address,
        "location": location,
        "profileImage": profileImage,
        "role": "provider",
        "status": "active",
        "isOnline": false,
        "isApproved": false,
        "isSuspended": false,
        "rating": 0.0,
        "earnings": 0.0,
        "totalJobs": 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // =========================
      // SAVE USERS COLLECTION
      // =========================

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "phone": phone,
        "address": address,
        "location": location,
        "profileImage": profileImage,
        "role": "provider",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Provider Registered Successfully"),
        ),
      );

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
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Registration failed",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Registration"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =========================
            // PROFILE PICTURE
            // =========================
            Center(
              child: GestureDetector(
                onTap: pickProfilePicture,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : null,
                      child: selectedImage == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tap to upload profile picture",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =========================
            // NAME
            // =========================
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Business Name / Full Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // EMAIL
            // =========================
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // PASSWORD
            // =========================
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // SERVICE
            // =========================
            DropdownButtonFormField<String>(
              value: selectedService,
              decoration: const InputDecoration(
                labelText: "Service Category",
                prefixIcon: Icon(Icons.design_services),
                border: OutlineInputBorder(),
              ),
              items: serviceCategories
                  .map(
                    (service) => DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedService = value;
                  });
                }
              },
            ),

            const SizedBox(height: 15),

            // =========================
            // PHONE
            // =========================
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // ADDRESS
            // =========================
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Address",
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // =========================
            // LOCATION
            // =========================
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Location",
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // TERMS
            // =========================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Wrap(
                    children: [
                      const Text("I agree to the "),
                      GestureDetector(
                        onTap: showTermsDialog,
                        child: const Text(
                          "Terms & Conditions",
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // =========================
            // REGISTER BUTTON
            // =========================
            loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: registerProvider,
                      icon: const Icon(Icons.app_registration),
                      label: const Text(
                        "Register as Provider",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
