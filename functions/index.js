const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

async function sendPushNotification(token, title, body, data = {}) {
  if (!token) return;

  const message = {
    token,

    notification: {
      title,
      body,
    },

    android: {
      priority: "high",
      notification: {
        channelId: "chat_channel",
        sound: "default",
      },
    },

    webpush: {
      headers: {
        Urgency: "high",
      },
      notification: {
        title,
        body,
        icon: "/icons/Icon-192.png",
        badge: "/icons/Icon-192.png",
      },
    },

    data,
  };

  try {
    await messaging.send(message);
    logger.info("Notification sent");
  } catch (e) {
    logger.error(e);

    if (e.code === "messaging/registration-token-not-registered") {
      logger.info("Invalid FCM token");
    }
  }
}

exports.chatNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();

    if (!message) return;

    logger.info("Message document:");
    logger.info(JSON.stringify(message));

    const receiverId = message.receiverId;
    const senderName = message.senderName || "New Message";
    const body = message.message || message.text || "";

    if (!receiverId) {
      logger.info("receiverId missing");
      return;
    }

    let token = null;

    // Users
    const userDoc = await db.collection("users").doc(receiverId).get();

    if (userDoc.exists) {
      token = userDoc.data().fcmToken;
    }

    // Providers
    if (!token) {
      const providerDoc = await db
          .collection("providers")
          .doc(receiverId)
          .get();

      if (providerDoc.exists) {
        token = providerDoc.data().fcmToken;
      }
    }

    // Admin
    if (!token) {
      const adminDoc = await db
          .collection("admins")
          .doc(receiverId)
          .get();

      if (adminDoc.exists) {
        token = adminDoc.data().fcmToken;
      }
    }

    if (!token) {
      logger.info(`No FCM token found for ${receiverId}`);
      return;
    }

    await sendPushNotification(
      token,
      senderName,
      body,
      {
        type: "chat",
        chatId: event.params.chatId,
      }
    );
  }
);