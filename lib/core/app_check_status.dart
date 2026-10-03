/// Ultimo problema nell'ottenere il token App Check, mostrato sotto l'errore
/// 401 ("token App Check assente") per capire cosa manca sul telefono:
/// Firebase non configurato nella build, Play Integrity / App Attest non
/// registrati in Firebase, app non installata dallo store, ...
abstract final class AppCheckStatus {
  static String? problem;
}
