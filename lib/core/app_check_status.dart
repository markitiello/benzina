/// Ultimo problema nell'ottenere il token App Check, mostrato sotto l'errore
/// 401 ("token App Check assente") per capire cosa manca sul telefono:
/// Firebase non configurato nella build, Play Integrity / App Attest non
/// registrati in Firebase, app non installata dallo store, ...
abstract final class AppCheckStatus {
  static String? problem;

  /// Errore del primo tentativo dopo l'avvio. Dopo un rifiuto dei server di
  /// Google l'SDK risponde solo "Too many attempts": il motivo vero è qui.
  static String? firstError;

  /// Testo da mostrare: il problema attuale e, se diverso, il primo errore.
  static String? get summary {
    final now = problem;
    if (now == null) return null;
    final first = firstError;
    return first == null || first == now ? now : '$now (primo errore: $first)';
  }
}
