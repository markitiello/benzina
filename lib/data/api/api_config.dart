/// Indirizzo del backend, passato al build con `--dart-define` (vedi README,
/// "Backend"). Senza indirizzo l'app usa i dati di prova.
///
///   flutter run --dart-define=BENZINA_API_URL=https://api.example.it
///
/// `BENZINA_API_KEY` è una chiave statica del backend per lo sviluppo, quando
/// App Check non è configurato: non va usata nelle build pubblicate, perché
/// dall'app si estrae facilmente.
class ApiConfig {
  static const baseUrl = String.fromEnvironment('BENZINA_API_URL');
  static const apiKey = String.fromEnvironment('BENZINA_API_KEY');

  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Informativa sulla privacy, pubblicata dal backend (public/privacy.html).
  static Uri? get privacyUrl {
    if (!isConfigured) return null;
    final base = Uri.parse(baseUrl);
    final path = base.path.endsWith('/') ? base.path : '${base.path}/';
    return base.replace(path: '${path}privacy.html', query: null);
  }
}
