import 'push_gateway.dart';
import 'push_topics.dart';

/// Allinea le iscrizioni ai topic con quelle volute: iscrive ai topic in
/// [desired] e disiscrive da tutti gli altri topic di tendenza (ad esempio
/// quello del carburante scelto in precedenza).
///
/// Restituisce `false` se servono notifiche ma l'utente non le ha permesse.
/// Gli errori (es. rete, token APNs mancante) vengono propagati.
Future<bool> syncTrendTopics(PushGateway gateway, Set<String> desired) async {
  if (!gateway.isAvailable) return true;
  var allowed = true;
  if (desired.isNotEmpty) {
    allowed = await gateway.requestPermission();
  }
  // Prima le iscrizioni: se una disiscrizione fallisce, quella che serve c'è.
  for (final topic in desired) {
    await gateway.subscribe(topic);
  }
  for (final topic in allTrendTopics.where((t) => !desired.contains(t))) {
    await gateway.unsubscribe(topic);
  }
  return allowed;
}
