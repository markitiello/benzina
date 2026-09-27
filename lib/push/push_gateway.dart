import 'push_message.dart';

/// Accesso alle notifiche push del sistema (Firebase Cloud Messaging su
/// Android e iOS). Un'interfaccia permette di usare un'implementazione finta
/// nei test e nelle build senza Firebase configurato.
abstract interface class PushGateway {
  /// `false` se questa build non ha Firebase configurato.
  bool get isAvailable;

  /// Chiede il permesso di mostrare notifiche (iOS, Android 13+).
  Future<bool> requestPermission();

  Future<void> subscribe(String topic);

  Future<void> unsubscribe(String topic);

  /// Notifiche arrivate con l'app aperta.
  Stream<PushMessage> get received;

  /// Notifiche toccate dall'utente con l'app in background.
  Stream<PushMessage> get opened;

  /// La notifica che ha avviato l'app, se l'app era chiusa.
  Future<PushMessage?> launchMessage();

  /// Token FCM del dispositivo, per mandare una notifica di prova solo a
  /// questo telefono (console Firebase → Messaging → Invia messaggio di prova).
  Future<String?> deviceToken();
}

/// Nessuna notifica push: Firebase non configurato o test.
class DisabledPushGateway implements PushGateway {
  const DisabledPushGateway();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> subscribe(String topic) async {}

  @override
  Future<void> unsubscribe(String topic) async {}

  @override
  Stream<PushMessage> get received => const Stream.empty();

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Future<PushMessage?> launchMessage() async => null;

  @override
  Future<String?> deviceToken() async => null;
}
