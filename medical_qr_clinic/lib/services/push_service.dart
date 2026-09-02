import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/models.dart';

const _channelId = 'medqr_alerts';
const _channelName = 'تنبيهات MED QR';
const _channelDesc = 'المواعيد والرسائل والسجل الطبي ومتابعة العيادة';

/// مفتاح Web Push العام. يُترك فارغاً إن لم يُضبط — أندرويد لا يحتاجه.
const webVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

class PushService {
  PushService._();
  static final instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  Future<void> Function(String token, {String platform})? registerToken;
  Future<void> Function(String token)? unregisterToken;
  Future<void> Function()? refreshInbox;
  void Function(String type, String link)? openNotification;
  bool Function()? isLoggedIn;
  String? _token;
  String? _pendingType;
  String? _pendingLink;
  bool _ready = false;

  static bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> bootstrap() async {
    if (!isSupported) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocal();
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _requestPermission();
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _token = token;
        if (isLoggedIn?.call() == true) {
          registerToken?.call(token, platform: _platformName);
        }
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _pendingType = initial.data['type'] ?? initial.data['notificationType'];
        _pendingLink = initial.data['link'];
      }
      _ready = true;
    } catch (error, stack) {
      debugPrint('Push bootstrap failed: $error\n$stack');
    }
  }

  Future<void> onLoggedIn() async {
    if (!isSupported || !_ready) return;
    await _syncToken();
    _flushPending();
  }

  Future<void> onLoggedOut() async {
    if (!isSupported) return;
    final token = _token;
    _token = null;
    try {
      if (token != null) {
        await unregisterToken?.call(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Push logout failed: $error');
    }
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _open(data['type']?.toString(), data['link']?.toString());
        } catch (_) {
          _open(null, payload);
        }
      },
    );
    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      provisional: false,
    );
    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> _syncToken() async {
    try {
      String? token;
      if (kIsWeb) {
        token = webVapidKey.isEmpty
            ? await FirebaseMessaging.instance.getToken()
            : await FirebaseMessaging.instance.getToken(vapidKey: webVapidKey);
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }
      if (token == null || token.isEmpty) return;
      _token = token;
      await registerToken?.call(token, platform: _platformName);
    } catch (error) {
      debugPrint('FCM token failed: $error');
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  Future<void> _onForeground(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'MED QR';
    final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode({
        'type': message.data['type'] ?? '',
        'link': message.data['link'] ?? '',
        'notificationId': message.data['notificationId'] ?? '',
      }),
    );
    try {
      await refreshInbox?.call();
    } catch (_) {}
  }

  void _onOpened(RemoteMessage message) {
    _open(message.data['type'], message.data['link']);
    refreshInbox?.call();
  }

  void _flushPending() {
    if (_pendingType == null && _pendingLink == null) return;
    _open(_pendingType, _pendingLink);
    _pendingType = null;
    _pendingLink = null;
  }

  void _open(String? type, String? link) {
    if (isLoggedIn?.call() != true) {
      _pendingType = type;
      _pendingLink = link;
      return;
    }
    openNotification?.call(type ?? '', link ?? '');
  }
}

ClinicPage pageFromNotification({required String type, required String link}) {
  final path = link.toLowerCase();
  if (path.contains('appointment')) return ClinicPage.appointments;
  if (path.contains('message')) return ClinicPage.messages;
  if (path.contains('record') || path.contains('my-records')) return ClinicPage.myRecords;
  if (path.contains('social') || path.contains('post')) return ClinicPage.social;
  if (path.contains('profile')) return ClinicPage.profile;
  if (path.contains('map')) return ClinicPage.doctorsMap;
  return switch (type) {
    'appointment' => ClinicPage.appointments,
    'message' => ClinicPage.messages,
    'diagnosis' || 'prescription' || 'file' || 'visit' => ClinicPage.myRecords,
    'post' => ClinicPage.social,
    'system' || 'welcome' || 'access_granted' => ClinicPage.profile,
    _ => ClinicPage.notifications,
  };
}
