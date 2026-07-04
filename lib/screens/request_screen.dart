import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

import 'login_screen.dart';
import 'chat_screen.dart';

class RequestScreen extends StatefulWidget {
  final String providerPhoto;
  final String userId;
  final String providerId;
  final String providerName;
  final String category;

  const RequestScreen({
    super.key,
    required this.providerPhoto,
    required this.userId,
    required this.providerId,
    required this.providerName,
    required this.category,
  });

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with WidgetsBindingObserver {
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = false;
  bool isOnline = false;
Future<String> getCurrentUserName() async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .get();

  if (!doc.exists) {
    return "Customer";
  }

  final data = doc.data() as Map<String, dynamic>;
  return data['name'] ?? "Customer";
}
  // =========================
  // FORMAT LAST SEEN
  // =========================
  String formatLastSeen(Timestamp? timestamp) {
    if (timestamp == null) return "Offline";

    final diff = DateTime.now().difference(timestamp.toDate());

    if (diff.inSeconds < 60) return "Last seen just now";
    if (diff.inMinutes < 60) return "Last seen ${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "Last seen ${diff.inHours} hr ago";
    return "Last seen ${diff.inDays} day(s) ago";
  }

  // =========================
  // USER STATUS
  // =========================
  Future<void> updateUserStatus(bool value) async {
    if (!mounted) return;

    setState(() => isOnline = value);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .set({
      'isOnline': value,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================
  // PROVIDER STATUS (kept for consistency)
  // =========================
  Future<void> updateProviderStatus(bool value) async {
    await FirebaseFirestore.instance
        .collection('providers')
        .doc(widget.providerId)
        .set({
      'isOnline': value,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
Future<void> saveFcmToken() async {
  try {
    final token = await NotificationService.getToken();

    debugPrint("USER FCM TOKEN: $token");

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'fcmToken': token,
      }, SetOptions(merge: true));

      debugPrint("User token saved successfully");
    }
  } catch (e) {
    debugPrint("FCM Error: $e");
  }
}
 @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addObserver(this);

  updateUserStatus(true);

  saveFcmToken();

}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    updateUserStatus(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updateUserStatus(false);
    descriptionController.dispose();
    super.dispose();
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
  await updateUserStatus(false);

  NotificationService.dispose();

  await _auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // =========================
  // EDIT PROFILE
  // =========================
  void editProfile() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "New Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .set({
                'name': nameController.text.trim(),
              }, SetOptions(merge: true));

              if (!mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile updated")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // =========================
  // SEND REQUEST
  // =========================
  Future<void> sendRequest() async {
    if (descriptionController.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'userId': widget.userId,
        'providerId': widget.providerId,
        'providerName': widget.providerName,
        'category': widget.category,
        'description': descriptionController.text.trim(),
        'status': 'pending',
        'completed': false,
        'amount': 0, 

'serviceFee': 300, 

'serviceFeePaid': false,

'serviceFeePaidAt': null,

'userConfirmedPaid': false,

'providerPaid': false,

        'createdAt': FieldValue.serverTimestamp(),
      });

      descriptionController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  // =========================
  // CHAT WITH PROVIDER
  // =========================
  Future<void> openChat() async {
  final senderName = await getCurrentUserName();

  final chatId = widget.userId.compareTo(widget.providerId) < 0
      ? '${widget.userId}_${widget.providerId}'
      : '${widget.providerId}_${widget.userId}';

  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .set({
    'participants': [
      widget.userId,
      widget.providerId,
    ],
    'participantNames': {
      widget.userId: senderName,
      widget.providerId: widget.providerName,
    },
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  if (!mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        chatId: chatId,
        senderId: widget.userId,
        receiverId: widget.providerId,
        chatName: widget.providerName,
        senderName: senderName,
      ),
    ),
  );
}

  // =========================
  // ADMIN CHAT (FIXED)
  // =========================
  void openAdminChat() async {
    const adminId = "ADMIN_SUPPORT";
final senderName = await getCurrentUserName();
    final chatId = widget.userId.compareTo(adminId) < 0
        ? "${widget.userId}_$adminId"
        : "${adminId}_${widget.userId}";

   await FirebaseFirestore.instance
    .collection('chats')
    .doc(chatId)
    .set({
  'participants': [
    widget.userId,
    adminId,
  ],

  'participantNames': {
  widget.userId: senderName,
  adminId: "ADMIN SUPPORT",
},

  'lastMessage': '',
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
     builder: (_) => ChatScreen(
  chatId: chatId,
  senderId: widget.userId,
  receiverId: adminId,
  chatName: "ADMIN SUPPORT",
  senderName: senderName,

),
      ),
    );
  }

  // =========================
  // CONFIRM PAYMENT
  // =========================
  Future<void> confirmPaid(String requestId) async {
  final amountController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Pay Platform Service Fee"),
      content: const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Text(
      "Your service has been marked as completed.",
    ),

    SizedBox(height: 15),

    Text(
      "Please pay the Gida Services platform fee.",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),

    SizedBox(height: 10),

    SelectableText(
      "Amount: ₦300\n\n"
      "Bank: Kuda Microfinance Bank\n"
      "Account Number: 2082918233",
      style: TextStyle(fontSize: 16),
    ),

    SizedBox(height: 15),

    Text(
      "After making the transfer, tap DONE.",
    ),
  ],
),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
      

            await FirebaseFirestore.instance
    .collection('requests')
    .doc(requestId)
    .set({

  'serviceFee': 300,

  'serviceFeePaid': true,

  'serviceFeePaidAt':
      FieldValue.serverTimestamp(),

  'userConfirmedPaid': true,

}, SetOptions(merge: true));

            // 🔥 ADD THIS (important for admin realtime visibility)
            await FirebaseFirestore.instance
                .collection('requests')
                .doc(requestId)
                .collection('history')
                .add({
              'action': 'User paid ₦300 platform service fee',
              'timestamp': FieldValue.serverTimestamp(),
            });

            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
  content: Text(
    "Thank you! Your ₦300 platform service fee has been recorded.",
  ),
)
            );
          },
          child: const Text("Done"),
        ),
      ],
    ),
  );
}

  // =========================
  // STATUS BADGE
  // =========================
  Widget statusBadge(String status) {
    Color color;

    switch (status) {
      case 'accepted':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Request"),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: openAdminChat,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: editProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROVIDER CARD
            Card(
  child: StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('providers')
        .doc(widget.providerId)
        .snapshots(),
    builder: (context, snapshot) {
      bool online = false;
      Timestamp? lastSeen;

      if (snapshot.hasData && snapshot.data!.exists) {
        final data =
            snapshot.data!.data() as Map<String, dynamic>;

        online = data['isOnline'] ?? false;
        lastSeen = data['lastSeen'];
      }

      return ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),

        title: Text(widget.providerName),

        subtitle: Text(
          online
              ? "Online"
              : formatLastSeen(lastSeen),
          style: TextStyle(
            color: online
                ? Colors.green
                : Colors.grey,
          ),
        ),

        trailing: IconButton(
          icon: const Icon(Icons.chat),
          onPressed: openChat,
        ),
      );
    },
  ),
),

            const SizedBox(height: 10),

            // REQUEST INPUT
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Describe your problem",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              onPressed: loading ? null : sendRequest,
              label: const Text("Send Request"),
            ),

            const SizedBox(height: 20),

            // REQUEST HISTORY (RESTORED FROM OLD VERSION)
            const Text(
              "Request History",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('userId', isEqualTo: widget.userId)
                  .where('providerId', isEqualTo: widget.providerId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';

                    return Card(
                      child: ExpansionTile(
                        title: Text(data['category'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? ''),
                            const SizedBox(height: 5),
                            statusBadge(status),

                            if (status == 'completed') ...[
  const SizedBox(height: 10),

  if (data['serviceFeePaid'] == true)
    const Text(
      "✅ Platform service fee paid (₦300)",
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    )
  else
    ElevatedButton(
      onPressed: () => confirmPaid(doc.id),
      child: const Text(
        "Pay ₦300 Platform Fee",
      ),
    ),
],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

