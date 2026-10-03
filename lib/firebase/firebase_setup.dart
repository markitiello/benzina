import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/app_check_status.dart';
import 'firebase_config.dart';

/// Inizializza Firebase e App Check. Restituisce `false` se Firebase non è
/// configurato (vedi [FirebaseConfig]) o non si avvia: l'app funziona lo
/// stesso, senza notifiche push e senza token App Check.
///
/// App Check attesta al backend che le richieste arrivano dall'app originale:
/// - Android: Play Integrity (app installata dal Play Store);
/// - iOS: App Attest, con DeviceCheck sui dispositivi che non lo supportano.
///
/// Nelle build di debug si usa il provider di debug: al primo avvio il token
/// di debug compare nel log (Logcat o console di Xcode) e va registrato nella
/// console Firebase, App Check → Gestisci token di debug.
Future<bool> initFirebase() async {
  final options = FirebaseConfig.currentPlatform;
  if (options == null) {
    AppCheckStatus.problem =
        'Firebase non configurato nella build (config/release.json)';
    return false;
  }
  try {
    await Firebase.initializeApp(options: options);
  } catch (e) {
    debugPrint('Firebase non disponibile: $e');
    AppCheckStatus.problem = 'Firebase non si avvia: $e';
    return false;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (e) {
    debugPrint('App Check non disponibile: $e');
    AppCheckStatus.problem = 'App Check non si attiva: $e';
  }
  return true;
}

/// Token App Check per le chiamate al backend. L'SDK lo tiene in cache e lo
/// rinnova prima della scadenza.
Future<String?> appCheckToken({bool forceRefresh = false}) async {
  try {
    final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
    AppCheckStatus.problem = token == null || token.isEmpty
        ? 'Firebase non ha restituito il token'
        : null;
    return token;
  } catch (e) {
    AppCheckStatus.problem = 'token non ottenuto: ${_describe(e)}';
    rethrow;
  }
}

String _describe(Object e) => e is FirebaseException
    ? '${e.code}${e.message == null ? '' : ' — ${e.message}'}'
    : '$e';
