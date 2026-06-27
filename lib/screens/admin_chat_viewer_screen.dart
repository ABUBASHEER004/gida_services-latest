import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatViewerScreen extends StatefulWidget {
  final String requestId;
  final String userId;
  final String providerId;

  const AdminChatViewerScreen({
    super.key,
    required this.requestId,
    required this.userId,
    required this.providerId,
  });

  @override
  State<AdminChatViewerScreen> createState() =>
      _AdminChatViewerScreenState();
}

class _AdminChatViewerScreenState
    extends State<AdminChatViewerScreen> {
  final TextEditingController messageController =
      TextEditingController();

  static const String adminId = "ADMIN_SUPPORT";

  // =========================
  // SAFE CHAT ID (FIXED)
  // =========================
 String get chatId {
  final userId = widget.userId.trim();
  final providerId = widget.providerId.trim();

  if (userId.isEmpty) {
    throw Exception("User ID is empty");
  }

  // Support chat
  if (providerId.isEmpty) {
    return "ADMIN_SUPPORT_$userId";
  }

  // User ↔ Provider chat
  final ids = [userId, providerId]..sort();
  return ids.join('_');
}

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  bool isUser(String senderId) {
  return senderId == widget.userId;
}

bool isProvider(String senderId) {
  return widget.providerId.isNotEmpty &&
      senderId == widget.providerId;
}
bool isAdmin(String senderId) {
  return senderId == adminId;
}

  // =========================
  // SEND MESSAGE (FIXED)
  // =========================
  Future<void> sendAdminMessage() async {
  final text = messageController.text.trim();

  if (text.isEmpty) return;

  try {
    final safeChatId = chatId;

    // Reply to provider if this is a provider chat,
    // otherwise reply to the customer.
    final receiverId = widget.providerId.isNotEmpty
        ? widget.providerId
        : widget.userId;

    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(safeChatId);

    await ref.collection('messages').add({
      'senderId': adminId,
      'senderName': 'ADMIN SUPPORT',
      'receiverId': receiverId,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isDelivered': false,
      'isRead': false,
    });

    await ref.set({
      'participants': [
        adminId,
        widget.userId,
        if (widget.providerId.isNotEmpty) widget.providerId,
      ],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    messageController.clear();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final safeChatId = chatId;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Support Chat Viewer"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [

          // ================= REQUEST DETAILS =================
          // ================= REQUEST DETAILS =================
if (widget.requestId.isNotEmpty)
  FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const SizedBox();
      }

      final data =
          snapshot.data!.data() as Map<String, dynamic>;

      return Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Request Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Category: ${data['category'] ?? ''}"),
              Text("Status: ${data['status'] ?? ''}"),
              Text("Amount: ₦${data['amount'] ?? 0}"),
              Text("Description: ${data['description'] ?? ''}"),
            ],
          ),
        ),
      );
    },
  ),

          // ================= CHAT =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(safeChatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data() as Map<String, dynamic>;

                    final message = data['message'] ?? '';
                    final sender = data['senderId'] ?? '';
                    final time = data['timestamp'] as Timestamp?;

                    final isU = isUser(sender);
                    final isP = isProvider(sender);
                    bool isAdmin(String senderId) {
                      return senderId == adminId;
                    }
                    final isA = isAdmin(sender);

                    Color bgColor;
                    Alignment align;

                    if (isA) {
                      bgColor = Colors.red.shade100;
                      align = Alignment.center;
                    } else if (isU) {
                      bgColor = Colors.blue.shade100;
                      align = Alignment.centerLeft;
                    } else if (isP) {
                      bgColor = Colors.green.shade100;
                      align = Alignment.centerRight;
                    } else {
                      bgColor = Colors.grey.shade300;
                      align = Alignment.centerLeft;
                    }

                    return Align(
                      alignment: align,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message),
                            const SizedBox(height: 4),
                            Text(
                              isA
                                  ? "Admin"
                                  : isU
                                      ? "User"
                                      : isP
                                          ? "Provider"
                                          : "Unknown",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                            Text(
                              formatTime(time),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ================= INPUT =================
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Reply as Admin...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.red),
                  onPressed: sendAdminMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

