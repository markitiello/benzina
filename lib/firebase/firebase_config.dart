import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configurazione Firebase passata al build con `--dart-define` (vedi
/// README, "Notifiche push"), così nel repository non ci sono file del
/// progetto Firebase. Senza questi valori l'app funziona senza notifiche push.
///
///   flutter run \
///     --dart-define=FIREBASE_PROJECT_ID=benzina-app \
///     --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789012 \
///     --dart-define=FIREBASE_ANDROID_API_KEY=... \
///     --dart-define=FIREBASE_ANDROID_APP_ID=1:123456789012:android:... \
///     --dart-define=FIREBASE_IOS_API_KEY=... \
///     --dart-define=FIREBASE_IOS_APP_ID=1:123456789012:ios:...
class FirebaseConfig {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  /// Opzioni per la piattaforma corrente, oppure `null` se mancano.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb || _projectId.isEmpty || _senderId.isEmpty) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android
          when _androidApiKey.isNotEmpty && _androidAppId.isNotEmpty =>
        const FirebaseOptions(
          apiKey: _androidApiKey,
          appId: _androidAppId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        ),
      TargetPlatform.iOS when _iosApiKey.isNotEmpty && _iosAppId.isNotEmpty =>
        const FirebaseOptions(
          apiKey: _iosApiKey,
          appId: _iosAppId,
          messagingSenderId: _senderId,
          projectId: _projectId,
          iosBundleId: 'it.benzina.benzina',
        ),
      _ => null,
    };
  }
}
