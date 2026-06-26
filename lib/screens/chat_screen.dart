import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;
  final String chatName;
  final String senderName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.chatName,
    required this.senderName,

  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    markMessagesAsRead();
  }

  final TextEditingController messageController = TextEditingController();

  // --------------------------
  // FORMAT TIME
  // --------------------------
  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // --------------------------
  // MARK MESSAGES AS READ
  // --------------------------
  Future<void> markMessagesAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where(
          'receiverId',
          isEqualTo: widget.senderId,
        )
        .where(
          'isRead',
          isEqualTo: false,
        )
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'isDelivered': true,
        'isRead': true,
      });
    }
  }

// ADD HERE
  Future<void> sendMessage() async {
    final message = messageController.text.trim();

    if (message.isEmpty) return;

    try {
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      await chatRef.collection('messages').add({
  'senderId': widget.senderId,
  'senderName': widget.senderName,
  'receiverId': widget.receiverId,
  'message': message,
  'timestamp': FieldValue.serverTimestamp(),
  'isDelivered': false,
  'isRead': false,
});

      await chatRef.set({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('messages').add({
  'senderId': widget.senderId,
  'senderName': widget.senderName,
  'receiverId': widget.receiverId,
  'message': message,
  'timestamp': FieldValue.serverTimestamp(),
});

      messageController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sending message: $e"),
        ),
      );
    }
  }
  // existing sendMessage code

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
      ),
      body: Column(
        children: [
          // =========================
          // MESSAGES LIST
          // =========================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (data['receiverId'] == widget.senderId &&
                      data['isRead'] == false) {
                    doc.reference.update({
                      'isRead': true,
                    });
                  }
                }
                if (docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final isMe = data['senderId'] == widget.senderId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['message'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  data['timestamp'] != null
                                      ? _formatTime(
                                          data['timestamp'] as Timestamp)
                                      : '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isMe ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                if (isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      data['isRead'] == true
                                          ? Icons.done_all
                                          : data['isDelivered'] == true
                                              ? Icons.done_all
                                              : Icons.done,
                                      size: 16,
                                      color: data['isRead'] == true
                                          ? Colors.blue
                                          : Colors.white70,
                                    ),
                                  ),
                              ],
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

          // =========================
          // INPUT BOX
          // =========================
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
