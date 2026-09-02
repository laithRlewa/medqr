/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/11.0.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyByP5XEM0whHw3saIYhPDmZL3YvsecEYqQ',
  appId: '1:796628489837:web:8a00590113684c8268d164',
  messagingSenderId: '796628489837',
  projectId: 'medqr-990bc',
  authDomain: 'medqr-990bc.firebaseapp.com',
  storageBucket: 'medqr-990bc.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const title = (payload.data && payload.data.title) || 'MED QR';
  const body = (payload.data && (payload.data.body || payload.data.message)) || '';
  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  });
});
