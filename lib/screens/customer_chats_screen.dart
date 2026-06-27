import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart';

class CustomerChatsScreen extends StatelessWidget {
  final String providerId;
  final String providerName;

  const CustomerChatsScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: providerId)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs.where((doc) {
            return !doc.id.startsWith("ADMIN_SUPPORT");
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text("No customer chats"),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final chat =
                  docs[index].data() as Map<String, dynamic>;

              final names =
                  chat['participantNames'] ?? {};

              String customerId = '';

              for (final p in chat['participants']) {
                if (p != providerId) {
                  customerId = p;
                }
              }

              final customerName =
                  names[customerId] ?? "Customer";

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(customerName),
                subtitle: Text(
                  chat['lastMessage'] ?? '',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: docs[index].id,
                        senderId: providerId,
                        receiverId: customerId,
                        chatName: customerName,
                        senderName: providerName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}