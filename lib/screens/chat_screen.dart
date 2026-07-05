import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/chat_media_service.dart';
import '../services/chat_audio_service.dart';
import 'dart:async';
import '../widgets/audio_message_widget.dart';
import '../services/typing_service.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

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
  final TextEditingController messageController =
      TextEditingController();

  bool uploadingImage = false;
  bool uploadingVideo = false;
  bool uploadingAudio = false;
  bool recordingAudio = false;

Map<String, dynamic>? replyingTo;
Timer? _typingTimer;
bool _isTyping = false;
  @override
  void initState() {
    super.initState();
    markMessagesAsRead();
  }

 @override
void dispose() {
  _typingTimer?.cancel();

  TypingService.setTyping(
    chatId: widget.chatId,
    userId: widget.senderId,
    isTyping: false,
  );

  messageController.dispose();

  super.dispose();
}

Future<void> _onTyping(String value) async {
  // User started typing
  if (!_isTyping && value.trim().isNotEmpty) {
    _isTyping = true;

    await TypingService.setTyping(
      chatId: widget.chatId,
      userId: widget.senderId,
      isTyping: true,
    );
  }

  // Restart timer after each keystroke
  _typingTimer?.cancel();

  _typingTimer = Timer(
    const Duration(seconds: 2),
    () async {
      _isTyping = false;

      await TypingService.setTyping(
        chatId: widget.chatId,
        userId: widget.senderId,
        isTyping: false,
      );
    },
  );
}
  // =============================
  // FORMAT TIME
  // =============================
  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // =============================
  // MARK AS READ
  // =============================
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

  // =============================
// SEND TEXT MESSAGE
// =============================
Future<void> sendMessage() async {
  final text = messageController.text.trim();

  if (text.isEmpty) return;

  final chatRef = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId);

  try {
    final newMessage = await chatRef
        .collection('messages')
        .add({
      'senderId': widget.senderId,
      'senderName': widget.senderName,
      'receiverId': widget.receiverId,

      'message': text,
      'type': 'text',

      'timestamp': FieldValue.serverTimestamp(),

      'isDelivered': false,
      'isRead': false,

      'deleted': false,
      'deletedFor': [],

      'replyMessage': replyingTo?['message'],
      'replyType': replyingTo?['type'],
      'replyMediaUrl': replyingTo?['mediaUrl'],
      'replySenderId': replyingTo?['senderId'],
    });

    await chatRef.set({
      'lastMessage': text,
      'lastMessageId': newMessage.id,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('messages')
        .add({
      'senderId': widget.senderId,
      'senderName': widget.senderName,
      'receiverId': widget.receiverId,
      'message': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    messageController.clear();

    replyingTo = null;

    _typingTimer?.cancel();
    _isTyping = false;

    await TypingService.setTyping(
      chatId: widget.chatId,
      userId: widget.senderId,
      isTyping: false,
    );

    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  // =============================
// SEND IMAGE
// =============================
Future<void> sendImage({
  required bool fromCamera,
}) async {
  try {
    setState(() {
      uploadingImage = true;
    });

    String? imageUrl;

    if (fromCamera) {
      imageUrl = await ChatMediaService.pickCameraAndUpload(
        widget.chatId,
      );
    } else {
      imageUrl = await ChatMediaService.pickGalleryAndUpload(
        widget.chatId,
      );
    }

    if (imageUrl == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    final newMessage = await chatRef
        .collection('messages')
        .add({
      'senderId': widget.senderId,
      'senderName': widget.senderName,
      'receiverId': widget.receiverId,

      'type': 'image',
      'mediaUrl': imageUrl,
      'message': '',

      'timestamp': FieldValue.serverTimestamp(),

      'isDelivered': false,
      'isRead': false,

      'deleted': false,
      'deletedFor': [],

      'replyMessage': replyingTo?['message'],
      'replyType': replyingTo?['type'],
      'replyMediaUrl': replyingTo?['mediaUrl'],
      'replySenderId': replyingTo?['senderId'],
    });

    await chatRef.set({
      'lastMessage': '📷 Image',
      'lastMessageId': newMessage.id,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    replyingTo = null;

    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        uploadingImage = false;
      });
    }
  }
}
   // =============================
// SEND VIDEO
// =============================
Future<void> sendVideo({
  required bool fromCamera,
}) async {
  try {
    setState(() {
      uploadingVideo = true;
    });

    final result = fromCamera
        ? await ChatMediaService.recordVideoAndUpload(
            widget.chatId,
          )
        : await ChatMediaService.pickVideoGalleryAndUpload(
            widget.chatId,
          );

    if (result == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    final newMessage = await chatRef
        .collection('messages')
        .add({
      'senderId': widget.senderId,
      'senderName': widget.senderName,
      'receiverId': widget.receiverId,

      'type': 'video',
      'mediaUrl': result['videoUrl'],
      'thumbnailUrl': result['thumbnailUrl'],
      'message': '',

      'timestamp': FieldValue.serverTimestamp(),

      'isDelivered': false,
      'isRead': false,

      'deleted': false,
      'deletedFor': [],

      'replyMessage': replyingTo?['message'],
      'replyType': replyingTo?['type'],
      'replyMediaUrl': replyingTo?['mediaUrl'],
      'replySenderId': replyingTo?['senderId'],
    });

    await chatRef.set({
      'lastMessage': '🎥 Video',
      'lastMessageId': newMessage.id,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    replyingTo = null;

    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        uploadingVideo = false;
      });
    }
  }
}
  // =============================
// SEND VOICE MESSAGE
// =============================
Future<void> sendVoiceMessage() async {
  try {
    setState(() {
      uploadingAudio = true;
    });

    final audioUrl = await ChatAudioService.stopAndUpload(
      widget.chatId,
    );

    if (audioUrl == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    final newMessage = await chatRef
        .collection('messages')
        .add({
      'senderId': widget.senderId,
      'senderName': widget.senderName,
      'receiverId': widget.receiverId,

      'type': 'audio',
      'mediaUrl': audioUrl,
      'message': '',

      'timestamp': FieldValue.serverTimestamp(),

      'isDelivered': false,
      'isRead': false,

      'deleted': false,
      'deletedFor': [],

      'replyMessage': replyingTo?['message'],
      'replyType': replyingTo?['type'],
      'replyMediaUrl': replyingTo?['mediaUrl'],
      'replySenderId': replyingTo?['senderId'],
    });

    await chatRef.set({
      'lastMessage': '🎤 Voice message',
      'lastMessageId': newMessage.id,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    replyingTo = null;

    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        uploadingAudio = false;
      });
    }
  }
}

 // =============================
// DELETE FOR ME
// =============================
Future<void> deleteForMe(
  DocumentReference messageRef,
) async {
  await messageRef.update({
    'deletedFor': FieldValue.arrayUnion([
      widget.senderId,
    ]),
  });
}
// =============================
// DELETE FOR EVERYONE
// =============================
Future<void> deleteForEveryone(
  DocumentReference messageRef,
) async {

  final messageSnap = await messageRef.get();

  if (!messageSnap.exists) return;

  await messageRef.update({

    'deleted': true,

    'message': '',

    'mediaUrl': '',

    'thumbnailUrl': '',

    'replyMessage': '',

    'replyMediaUrl': '',

    'replyType': '',

    'replySenderId': '',

  });

  final chatRef = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId);

  final chatSnap = await chatRef.get();

  if (!chatSnap.exists) return;

  final chat =
      chatSnap.data() as Map<String, dynamic>;

  if (chat['lastMessageId'] == messageRef.id) {

    await chatRef.update({
  'lastMessage': '🚫 This message was deleted',
  'lastMessageType': 'deleted',
});

  }
}

// =============================
// DELETE OPTIONS
// =============================
Future<void> _showDeleteOptions({
  required DocumentReference messageRef,
  required Map<String, dynamic> data,
}) async {

  final currentUserId =
    FirebaseAuth.instance.currentUser?.uid ?? '';

final bool isMe =
    data['senderId'] == currentUserId;

  await showModalBottomSheet(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 12),

            const Text(
              "Delete Message",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(
                Icons.delete_outline,
              ),
              title: const Text(
                "Delete for Me",
              ),
              onTap: () async {

                Navigator.pop(context);

                await deleteForMe(
                  messageRef,
                );
              },
            ),

            if (isMe)
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                ),
                title: const Text(
                  "Delete for Everyone",
                ),
                onTap: () async {

                  Navigator.pop(context);

                  await deleteForEveryone(
                    messageRef,
                  );
                },
              ),

            ListTile(
              leading: const Icon(
                Icons.close,
              ),
              title: const Text(
                "Cancel",
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),

          ],
        ),
      );
    },
  );
}
  // ==========================================================
  // BUILD
  // ==========================================================

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .snapshots(),
        builder: (context, snapshot) {
          bool typing = false;

          if (snapshot.hasData) {
            final data =
                snapshot.data!.data() as Map<String, dynamic>?;

            if (data != null && data['typing'] != null) {
              typing =
                  data['typing'][widget.receiverId] == true;
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                widget.chatName,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              if (typing)
                const Text(
                  "Typing...",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          );
        },
      ),
    ),

    body: Column(
      children: [

        // =====================================
        // MESSAGE LIST
        // =====================================

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .collection('messages')
                .orderBy(
                  'timestamp',
                  descending: true,
                )
                .snapshots(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No messages yet"),
                );
              }

              return ListView.builder(
                reverse: true,
                itemCount: docs.length,

                itemBuilder: (context, index) {

                   final doc = docs[index];

final data =
    doc.data() as Map<String, dynamic>;

final isMe =
    data['senderId'] == widget.senderId;

final deleted =
    data['deleted'] == true;

final deletedFor =
    List<String>.from(
      data['deletedFor'] ?? [],
    );

if (deletedFor.contains(widget.senderId)) {
  return const SizedBox.shrink();
}

if (data['receiverId'] == widget.senderId &&
    data['isRead'] == false) {
  doc.reference.update({
    'isRead': true,
    'isDelivered': true,
  });
}

return Dismissible(
  key: ValueKey(doc.id),

  direction: DismissDirection.startToEnd,

  dismissThresholds: const {
    DismissDirection.startToEnd: 0.25,
  },

  confirmDismiss: (_) async {
    setState(() {
      replyingTo = data;
    });

    return false;
  },

  background: Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 20),
    child: const Icon(
      Icons.reply,
      color: Colors.green,
      size: 30,
    ),
  ),

  child: GestureDetector(
    onLongPress: () {
      _showDeleteOptions(
        messageRef: doc.reference,
        data: data,
      );
    },

    child: Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),

        padding: const EdgeInsets.all(10),

        constraints: const BoxConstraints(
          maxWidth: 280,
        ),

        decoration: BoxDecoration(
          color: isMe
              ? Colors.green
              : Colors.grey.shade300,

          borderRadius: BorderRadius.circular(14),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
// =====================================
// REPLY PREVIEW
// =====================================

if (!deleted &&
    data['replyType'] != null)
  Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: isMe
          ? Colors.white24
          : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      border: Border(
        left: BorderSide(
          color: Colors.green,
          width: 3,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          "Reply",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),

        if (data['replyType'] == 'text')
          Text(
            data['replyMessage'] ?? '',
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
          )
        else if (data['replyType'] ==
            'image')
          const Text("📷 Image")
        else if (data['replyType'] ==
            'video')
          const Text("🎥 Video")
        else if (data['replyType'] ==
            'audio')
          const Text(
              "🎤 Voice message"),
      ],
    ),
  ),

// =====================================
// DELETED MESSAGE
// =====================================

if (deleted)

  Row(
    mainAxisSize: MainAxisSize.min,
    children: const [

      Icon(
        Icons.block,
        color: Colors.grey,
        size: 16,
      ),

      SizedBox(width: 6),

      Text(
        "This message was deleted",
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),

    ],
  )

// =====================================
// IMAGE
// =====================================

else if ((data['type'] ?? 'text') ==
    'image')

  GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ImageViewerScreen(
            imageUrl:
                data['mediaUrl'],
          ),
        ),
      );
    },

    child: Hero(
      tag: doc.id,

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(12),

        child: CachedNetworkImage(
          imageUrl:
              data['mediaUrl'],

          width: 220,
          height: 220,

          fit: BoxFit.contain,
        ),
      ),
    ),
  )

// =====================================
// VIDEO
// =====================================

else if ((data['type'] ?? 'text') ==
    'video')

  GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VideoPlayerScreen(
            videoUrl:
                data['mediaUrl'],
          ),
        ),
      );
    },

    child: Stack(
      alignment: Alignment.center,

      children: [

        ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: CachedNetworkImage(
    imageUrl: data['thumbnailUrl'] ?? '',
    width: 220,
    height: 220,
    fit: BoxFit.cover,

    placeholder: (context, url) =>
        const Center(
          child: CircularProgressIndicator(),
        ),

    errorWidget: (context, url, error) {
      debugPrint("Thumbnail error: $error");

      return Container(
        width: 220,
        height: 220,
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 60,
          ),
        ),
      );
    },
  ),
),

        const CircleAvatar(
          radius: 28,
          backgroundColor:
              Colors.black54,

          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 36,
          ),
        ),
      ],
    ),
  )

// =====================================
// AUDIO
// =====================================

else if ((data['type'] ?? 'text') ==
    'audio')

  AudioMessageWidget(
    audioUrl: data['mediaUrl'],
    isMe: isMe,
  )

// =====================================
// TEXT
// =====================================

else

  Text(
    data['message'] ?? '',
    style: TextStyle(
      fontSize: 16,
      color: isMe
          ? Colors.white
          : Colors.black,
    ),
  ),

const SizedBox(height: 6),

// =====================================
// TIME + READ RECEIPTS
// =====================================

Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      data['timestamp'] != null
          ? _formatTime(
              data['timestamp'] as Timestamp,
            )
          : '',
      style: TextStyle(
        fontSize: 10,
        color: isMe
            ? Colors.white70
            : Colors.black54,
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
    ),
  ),
);
                  },
                );
              },
            ),
          ),

        // =====================================
        // REPLY PREVIEW BAR
        // =====================================

        if (replyingTo != null)
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius:
                  BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(
                  color: Colors.green,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Replying to",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      Text(
                        replyingTo!['message']
                                    ?.toString()
                                    .isNotEmpty ==
                                true
                            ? replyingTo!['message']
                            : replyingTo!['type'] ==
                                    'image'
                                ? "📷 Image"
                                : replyingTo![
                                            'type'] ==
                                        'video'
                                    ? "🎥 Video"
                                    : replyingTo![
                                                'type'] ==
                                            'audio'
                                        ? "🎤 Voice message"
                                        : "",
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon:
                      const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      replyingTo = null;
                    });
                  },
                ),
              ],
            ),
          ),

        // =====================================
        // INPUT BAR
        // =====================================

        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [

              IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                ),
                color: Colors.green,
                onPressed: () =>
                    sendImage(
                  fromCamera: true,
                ),
              ),

              IconButton(
                icon:
                    const Icon(Icons.photo),
                color: Colors.green,
                onPressed: () =>
                    sendImage(
                  fromCamera: false,
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.videocam,
                ),
                color: Colors.red,
                onPressed: () =>
                    sendVideo(
                  fromCamera: true,
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.video_library,
                ),
                color: Colors.red,
                onPressed: () =>
                    sendVideo(
                  fromCamera: false,
                ),
              ),

              GestureDetector(
                onLongPressStart: (_) async {
                  final ok =
                      await ChatAudioService
                          .startRecording();

                  if (ok && mounted) {
                    setState(() {
                      recordingAudio = true;
                    });
                  }
                },
                onLongPressEnd: (_) async {
                  if (mounted) {
                    setState(() {
                      recordingAudio = false;
                    });
                  }

                  await sendVoiceMessage();
                },
                child: Icon(
                  Icons.mic,
                  size: 30,
                  color: recordingAudio
                      ? Colors.red
                      : Colors.green,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: TextField(
                  controller:
                      messageController,
                  onChanged: _onTyping,
                  decoration:
                      const InputDecoration(
                    hintText:
                        "Type message...",
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              if (uploadingImage ||
                  uploadingVideo ||
                  uploadingAudio)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.green,
                  ),
                  onPressed: sendMessage,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

}