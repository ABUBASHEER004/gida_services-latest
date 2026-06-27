importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");

importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");



firebase.initializeApp({

  apiKey: 'AIzaSyAIdroChtYxw1qI3kSA6aeZc40x1_ezIcU', 

  authDomain: 'gida-service.firebaseapp.com',

  projectId: 'gida-service',

  storageBucket: 'gida-service.firebasestorage.app',

  messagingSenderId: '880257631582', 

  appId: '1:880257631582:web:ce99a6b5a47df25a64bbcf',

});



const messaging = firebase.messaging();
messaging.onBackgroundMessage(function(payload) {
  console.log("Background message:", payload);

  self.registration.showNotification(
    payload.notification?.title || "New Message",
    {
      body: payload.notification?.body || "",
      icon: "/icons/Icon-192.png",
    }
  );
});