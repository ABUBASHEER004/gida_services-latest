import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

import 'chat_screen.dart';
import 'login_screen.dart';
import 'provider_edit_profile.dart';
import 'dart:async';

class ProviderDashboard extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderDashboard({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard>
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

 
  bool isOnline = false;
  String address = "Loading location...";

  Future<void> saveFcmToken() async {
    try {
     final token = await NotificationService.getToken();
      debugPrint("FCM TOKEN: $token");

      if (token != null) {
        await _firestore.collection('providers').doc(widget.providerId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));

        debugPrint("Token saved successfully");
      }
    } catch (e) {
      debugPrint("FCM Token Error: $e");
    }
  }

 

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final serviceController = TextEditingController();
  Future<void> addHistory(String requestId, String action) async {
    await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('history')
        .add({
      'action': action,
      'providerId': widget.providerId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    toggleStatus(true);

    loadProviderData();
    saveFcmToken();
    NotificationService.listenForChats(widget.providerId);
    NotificationService.listenForAdminChats(widget.providerId);
    NotificationService.listenForRequestUpdates(widget.providerId);

   
FirebaseMessaging.onMessage.listen((message) {
    NotificationService.showNotification(
      message.notification?.title ?? "New Message",
      message.notification?.body ?? "",
    );
  });
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    toggleStatus(
      state == AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    toggleStatus(false);

    NotificationService.dispose();

    

    nameController.dispose();
    phoneController.dispose();
    serviceController.dispose();

    super.dispose();
  }

  Future<void> openChat(String userId) async {
  if (userId.isEmpty || widget.providerId.isEmpty) return;

  String customerName = "Customer";

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (userDoc.exists) {
    customerName = userDoc.data()?['name'] ?? "Customer";
  }

  final chatId = userId.compareTo(widget.providerId) < 0
      ? "${userId}_${widget.providerId}"
      : "${widget.providerId}_$userId";

  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .set({
    'participants': [
      userId,
      widget.providerId,
    ],
    'participantNames': {
      userId: customerName,
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
        senderId: widget.providerId,
        receiverId: userId,
        chatName: customerName,
        senderName: widget.providerName,
      ),
    ),
  );
}

  Widget earningsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('providerId', isEqualTo: widget.providerId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        double totalEarned = 0;
        double pendingCommission = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          totalEarned += (data['providerEarning'] ?? 0).toDouble();

          if (data['providerMarkedPaid'] != true) {
            pendingCommission += (data['commission'] ?? 0).toDouble();
          }
        }

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Earnings Summary",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text("Total Earned: ₦${totalEarned.toStringAsFixed(0)}"),
                Text(
                    "Pending Commission: ₦${pendingCommission.toStringAsFixed(0)}"),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // LOAD PROFILE
  // =========================
  Future<void> loadProviderData() async {
    final doc =
        await _firestore.collection('providers').doc(widget.providerId).get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      isOnline = data['isOnline'] == true;

      nameController.text = data['name'] ?? '';
      phoneController.text = data['phone'] ?? '';
      serviceController.text = data['service'] ?? '';

      address = data['address'] ??
          data['location']?['address'] ??
          "Location not available";
    });
  }

  // =========================
  // EDIT PROFILE
  // =========================
  Future<void> openEditProfile() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProviderEditProfile(
        providerId: widget.providerId,
      ),
    );

    // Reload provider data
    await loadProviderData();

    // Save latest FCM token
    final token = await NotificationService.getToken();

    await _firestore.collection('providers').doc(widget.providerId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  // =========================
  // ONLINE/OFFLINE
  // =========================
  Future<void> toggleStatus(bool value) async {
    setState(() => isOnline = value);

    await _firestore.collection('providers').doc(widget.providerId).set({
      'isOnline': value,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================
// ADMIN CHAT (FULL HISTORY FIXED)
// =========================
  void openAdminChat() async {
    final providerId = widget.providerId;

    if (providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid provider ID")),
      );
      return;
    }

    final chatId = "ADMIN_SUPPORT_$providerId";

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [
        "ADMIN_SUPPORT",
        widget.providerId,
      ],
      'participantNames': {
        "ADMIN_SUPPORT": "ADMIN SUPPORT",
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
          senderId: providerId,
          receiverId: "ADMIN_SUPPORT",
          chatName: "ADMIN SUPPORT",
          senderName: widget.providerName,
        ),
      ),
    );
  }

  // =========================
  // CHAT WITH USER
  // ======================
  Future<void> acceptRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).set({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addHistory(requestId, "Request accepted");
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).set({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addHistory(requestId, "Request rejected");
  }

  // =========================
  // COMPLETE JOB
  // =========================
  Future<void> markAsDone(String id, double amount) async {
    const commissionRate = 0.30;

    final commission = amount * commissionRate;
    final providerEarning = amount - commission;

    await _firestore.collection('requests').doc(id).set({
      'status': 'completed',
      'completed': true,
      'amount': amount,
      'commission': commission,
      'providerEarning': providerEarning,
      'commissionPaid': false,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addHistory(
      id,
      "Job completed. Earned ₦${providerEarning.toStringAsFixed(0)}, Commission ₦${commission.toStringAsFixed(0)}",
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Earned ₦${providerEarning.toStringAsFixed(0)}"),
      ),
    );
  }

  void showCompleteJobDialog(String requestId) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete Job"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              Navigator.pop(context);
              await markAsDone(requestId, amount);
            },
            child: const Text("Complete"),
          ),
        ],
      ),
    );
  }

  // =========================
  // MARK COMMISSION PAID
  // =========================
  Future<void> markCommissionPaid(String requestId) async {
    final ref = _firestore.collection('requests').doc(requestId);

    await ref.set({
      'providerMarkedPaid': true,
      'providerPaidAt': FieldValue.serverTimestamp(),
      'providerPaymentStatus': 'paid_pending_admin_review',
    }, SetOptions(merge: true));

    await addHistory(requestId, "Commission marked as PAID by provider");

    final chatId = "ADMIN_SUPPORT_${widget.providerId}";
    await _firestore.collection("chats").doc(chatId).set({
      "participants": [
        "ADMIN_SUPPORT",
        widget.providerId,
      ],
      "participantNames": {
        "ADMIN_SUPPORT": "ADMIN SUPPORT",
        widget.providerId: widget.providerName,
      },
      "lastMessage": "Commission marked as paid",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "senderId": widget.providerId,
      "message": "I have paid commission for request $requestId",
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment sent to admin")),
    );
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _firestore.collection('providers').doc(widget.providerId).set({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Provider: ${widget.providerName}"),
        actions: [
          IconButton(
              icon: const Icon(Icons.chat),
              tooltip: "Customer Chats",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Open a customer chat from one of the requests below.",
                    ),
                  ),
                );
              }),
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: "Admin Support",
            onPressed: openAdminChat,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: openEditProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
          Row(
            children: [
              Text(isOnline ? "Online" : "Offline"),
              Switch(
                value: isOnline,
                onChanged: toggleStatus,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Earnings summary goes FIRST
          earningsCard(),

          // =========================
          // COMMISSION ACCOUNT CARD
          // =========================
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Text(
                    "Commission Payment Account",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text("Kuda Microfinance Bank"),
                  SizedBox(height: 6),
                  SelectableText(
                    "2082918233",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Pay commission after completing jobs then tap 'I Have Paid'",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // =========================
          // REQUEST LIST
          // =========================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('requests')
                  .where('providerId', isEqualTo: widget.providerId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No requests"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    final userId = (data['userId'] ?? '').toString();
                    final status = data['status'] ?? 'pending';

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['category'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(data['description'] ?? ''),
                            Text("Amount: ₦${data['amount'] ?? 0}"),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [

                                ElevatedButton.icon(
  onPressed: () => openChat(userId),
  icon: const Icon(Icons.chat),
  label: const Text("Chat"),
),

                                if (status == 'pending')
                                  ElevatedButton(
                                    onPressed: () => acceptRequest(id),
                                    child: const Text("Accept"),
                                  ),
                                if (status == 'pending')
                                  ElevatedButton(
                                    onPressed: () => rejectRequest(id),
                                    child: const Text("Reject"),
                                  ),
                                if (status == 'accepted')
                                  ElevatedButton(
                                    onPressed: () => showCompleteJobDialog(id),
                                    child: const Text("Done"),
                                  ),
                                if (status == 'completed' &&
                                    data['providerMarkedPaid'] != true)
                                  ElevatedButton.icon(
                                    onPressed: () => markCommissionPaid(id),
                                    icon: const Icon(Icons.check),
                                    label: const Text("I Have Paid"),
                                  ),
                              ],
                            )
                          ],
                        ),
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
