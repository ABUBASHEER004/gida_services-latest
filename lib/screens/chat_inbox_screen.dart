import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatelessWidget {
  final String currentUserId;

  const ChatInboxScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text("No chats yet"),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              final participants =
                  List<String>.from(chat['participants'] ?? []);

              final participantNames =
                  Map<String, dynamic>.from(
                chat['participantNames'] ?? {},
              );

              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              final otherUserName =
                  participantNames[otherUserId] ??
                  otherUserId;

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.chat),
                ),

                title: Text(
                  otherUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  chat['lastMessage'] ?? "No messages yet",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
  chatId: chat.id,
  senderId: currentUserId,
  receiverId: otherUserId,
  chatName: otherUserName,
  senderName: participantNames[currentUserId] ?? "User",


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

