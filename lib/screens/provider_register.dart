import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool loading = false;
  bool acceptedTerms = false;

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
    "Fabrics(shadda/yadi) Dealer ",
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
    "Rubber Home Equipment Seller ",
    "Palm oil/Groundnut oil Seller",
    "Petrol Black Marketer",
    "Women Beauty Products Seller",
    "Painter",



  
  ];

  String selectedService = "Waste Pickup";

  // ========================= TERMS DIALOG (FIXED LOCATION)
  void showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Conditions"),
        content: const SingleChildScrollView(
          child: Text("""
📌 PROVIDER TERMS & CONDITIONS

1. You must provide accurate information.
2. Fake accounts or fake services are not allowed.
3. Be respectful to customers.
4. Cancelled jobs without reason may lead to suspension.
5. Payments must follow platform rules.
6. Fraud or abuse leads to permanent ban.
7. Admin can suspend accounts at any time.

By registering, you agree to follow these rules.
"""),
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
  Future<void> registerProvider() async {
    if (loading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    // OLD VALIDATION (kept)
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        phone.isEmpty ||
        address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // NEW TERMS VALIDATION (added)
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept Terms & Conditions")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // =========================
      // PROVIDER COLLECTION (OLD + NEW MERGED)
      // =========================
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'service': selectedService,

        // OLD + NEW location fields
        'address': address,
        'location': address,

        // role & status
        'role': 'provider',
        'isOnline': false,
        'isApproved': false,
        'isSuspended': false,

        // stats
        'rating': 0.0,
        'earnings': 0.0,
        'totalJobs': 0,

        'createdAt': FieldValue.serverTimestamp(),
      });

      // =========================
      // USERS COLLECTION (OLD + NEW MERGED)
      // =========================
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,

        'address': address,
        'location': address,

        'role': 'provider',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider Registered Successfully")),
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
        SnackBar(content: Text(e.message ?? "Registration failed")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name or Business Name"),
            ),
            const SizedBox(height: 10),

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
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedService,
              items: serviceCategories
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedService = v!),
              decoration: const InputDecoration(labelText: "Service"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Location"),
            ),

            const SizedBox(height: 10),


             // ========================= TERMS CHECKBOX (FIXED)
            Row(
              children: [
                Checkbox(
                  value: acceptedTerms,
                  onChanged: (v) {
                    setState(() => acceptedTerms = v ?? false);
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

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: registerProvider,
                      child: const Text("Register as Provider"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}



