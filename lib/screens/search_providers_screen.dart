import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'request_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchProvidersScreen extends StatefulWidget {
  const SearchProvidersScreen({super.key});

  @override
  State<SearchProvidersScreen> createState() =>
      _SearchProvidersScreenState();
}

class _SearchProvidersScreenState
    extends State<SearchProvidersScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String searchLocation = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void searchProvider() {
    setState(() {
      searchLocation =
          searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Providers"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => searchProvider(),
                    decoration: const InputDecoration(
                      hintText: "Enter location...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: searchProvider,
                  child: const Text("Search"),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Failed to load providers",
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      "No providers available",
                    ),
                  );
                }

                final providers =
                    snapshot.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final location =
                      (data['location'] ?? '')
                          .toString()
                          .toLowerCase();

                  if (searchLocation.isEmpty) {
                    return false;
                  }

                  return location.contains(
                    searchLocation,
                  );
                }).toList();

                if (searchLocation.isEmpty) {
                  return const Center(
                    child: Text(
                      "Search providers by location",
                    ),
                  );
                }

                if (providers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No providers found",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final data =
                        providers[index].data()
                            as Map<String, dynamic>;

                    return Card(
  margin: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  ),
  child: ListTile(
    leading: CircleAvatar(
      backgroundColor:
          (data['isOnline'] ?? false)
              ? Colors.green
              : Colors.grey,
      child: const Icon(
        Icons.person,
        color: Colors.white,
      ),
    ),

    title: Text(
      data['name'] ?? 'Provider',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Service: ${data['service'] ?? ''}",
        ),
        Text(
          "Location: ${data['location'] ?? ''}",
        ),
        Text(
          "Phone: ${data['phone'] ?? ''}",
        ),

        const SizedBox(height: 5),

        Row(
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: (data['isOnline'] ?? false)
                  ? Colors.green
                  : Colors.grey,
            ),
            const SizedBox(width: 5),

            Text(
              (data['isOnline'] ?? false)
                  ? "Online"
                  : "Offline",
              style: TextStyle(
                color: (data['isOnline'] ?? false)
                    ? Colors.green
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        if (!(data['isOnline'] ?? false) &&
            data['lastSeen'] != null)
          Text(
            "Last seen: ${(
              data['lastSeen'] as Timestamp
            ).toDate()}",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
      ],
    ),

    trailing: const Icon(
      Icons.arrow_forward_ios,
    ),

    onTap: () {
      final currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please login first",
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
            userId: currentUser.uid,
            providerId: data['uid'] ?? '',
            providerName: data['name'] ?? '',
            category: data['service'] ?? '',
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
          ),
        ],
      ),
    );
  }
}


