import 'push_gateway.dart';
import 'push_topics.dart';

/// Allinea le iscrizioni ai topic con quelle volute: iscrive ai topic in
/// [desired] e disiscrive da tutti gli altri topic di tendenza (ad esempio
/// quello del carburante scelto in precedenza).
///
/// Restituisce `false` se servono notifiche ma l'utente non le ha permesse.
Future<bool> syncTrendTopics(PushGateway gateway, Set<String> desired) async {
  if (!gateway.isAvailable) return true;
  var allowed = true;
  if (desired.isNotEmpty) {
    allowed = await gateway.requestPermission();
  }
  for (final topic in allTrendTopics) {
    if (desired.contains(topic)) {
      await gateway.subscribe(topic);
    } else {
      await gateway.unsubscribe(topic);
    }
  }
  return allowed;
}
