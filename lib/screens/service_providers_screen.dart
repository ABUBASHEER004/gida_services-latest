import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gida_services/screens/request_screen.dart';

class ServiceProvidersScreen extends StatelessWidget {
  final String category;

  const ServiceProvidersScreen({
    super.key,
    required this.category,
  });

  /// Normalize text for safe comparison
  String normalize(String value) {
    return value.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final selectedCategory = normalize(category);

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading providers"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          final providers = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final service =
                normalize(data['service'] ?? '');

            return service == selectedCategory;
          }).toList();

          if (providers.isEmpty) {
            return const Center(
              child: Text(
                "No providers available for this category",
              ),
            );
          }

          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final doc = providers[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              final isOnline =
                  data['isOnline'] == true;

              final String locationText =
                  (data['location'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty
                      ? data['location']
                      : "Location not available";

              final String photoUrl =
                  (data['photoUrl'] ?? '')
                      .toString();

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                elevation: 3,
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            Colors.grey.shade200,
                        backgroundImage:
                            photoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    photoUrl,
                                  )
                                : null,
                        child: photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 30,
                              )
                            : null,
                      ),

                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  title: Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['service'] ?? '',
                      ),

                      const SizedBox(height: 2),

                      Text(
                        isOnline
                            ? "🟢 Available Now"
                            : "⚪ Offline",
                        style: TextStyle(
                          color: isOnline
                              ? Colors.green
                              : Colors.grey,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "📍 $locationText",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),

                  onTap: () {
                    if (user == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please login to continue",
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestScreen(
                          providerPhoto: data['photoUrl'] ?? '',
                          userId: user.uid,
                          providerId: doc.id,
                          providerName:
                              data['name'] ?? '',
                          category:
                              data['service'] ??
                                  category,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}