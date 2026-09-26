import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_gateway.dart';
import 'push_message.dart';

/// Notifiche push con Firebase Cloud Messaging (Android e iOS).
///
/// - App chiusa o in background: la notifica la mostra il sistema.
/// - App aperta: iOS la mostra grazie alle opzioni di presentazione; su
///   Android la mostra flutter_local_notifications nel canale `price_trends`.
class FirebasePushGateway implements PushGateway {
  FirebasePushGateway._(this._messaging, this._local);

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;
  final _received = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  /// Canale Android: stesso id usato dal backend (FcmClient::ANDROID_CHANNEL).
  static const channel = AndroidNotificationChannel(
    'price_trends',
    'Andamento prezzi',
    description: 'Avvisi quando i prezzi iniziano a salire o a scendere',
  );

  /// Da chiamare dopo initFirebase(); se fallisce, niente push.
  static Future<PushGateway> create() async {
    try {
      final gateway = FirebasePushGateway._(
        FirebaseMessaging.instance,
        FlutterLocalNotificationsPlugin(),
      );
      await gateway._init();
      return gateway;
    } catch (e) {
      debugPrint('Notifiche push non disponibili: $e');
      return const DisabledPushGateway();
    }
  }

  Future<void> _init() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
        // Su iOS il permesso lo chiede FirebaseMessaging.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _opened.add(_fromPayload(payload));
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((remote) {
      final message = _fromRemote(remote);
      _received.add(message);
      if (defaultTargetPlatform == TargetPlatform.android) {
        _showOnAndroid(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen(
      (remote) => _opened.add(_fromRemote(remote)),
    );
  }

  static PushMessage _fromRemote(RemoteMessage remote) => PushMessage(
    id: remote.messageId,
    title: remote.notification?.title ?? 'Benzina',
    body: remote.notification?.body ?? '',
    data: remote.data.map((k, v) => MapEntry(k, '$v')),
    receivedAt: remote.sentTime ?? DateTime.now(),
  );

  Future<void> _showOnAndroid(PushMessage message) {
    return _local.show(
      id: message.hashCode,
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@drawable/ic_stat_notify',
          color: const Color(0xFFF2B632),
        ),
      ),
      payload: jsonEncode({
        'title': message.title,
        'body': message.body,
        'data': message.data,
      }),
    );
  }

  static PushMessage _fromPayload(String payload) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return PushMessage(
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map).map((k, v) => MapEntry('$k', '$v')),
      receivedAt: DateTime.now(),
    );
  }

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> subscribe(String topic) => _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribe(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  @override
  Stream<PushMessage> get received => _received.stream;

  @override
  Stream<PushMessage> get opened => _opened.stream;

  @override
  Future<PushMessage?> launchMessage() async {
    final remote = await _messaging.getInitialMessage();
    if (remote != null) return _fromRemote(remote);
    final launch = await _local.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    return launch?.didNotificationLaunchApp == true && payload != null
        ? _fromPayload(payload)
        : null;
  }
}
