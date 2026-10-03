/// Richieste di permesso una alla volta.
///
/// Android gestisce una sola richiesta di permesso per volta: se all'avvio
/// partono insieme quella della posizione e quella delle notifiche, la
/// risposta alla prima va persa e l'app resta in attesa (splash ferma su
/// "Cerco la tua posizione…"). Tutte le richieste passano da qui.
abstract final class PermissionQueue {
  static Future<void> _last = Future.value();

  /// Esegue [request] dopo che le richieste precedenti sono terminate.
  static Future<T> run<T>(Future<T> Function() request) {
    final result = _last.then((_) => request());
    _last = result.then((_) {}, onError: (Object _) {});
    return result;
  }
}
