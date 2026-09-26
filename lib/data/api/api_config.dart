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
}
