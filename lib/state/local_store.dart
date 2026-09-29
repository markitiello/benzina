import 'package:shared_preferences/shared_preferences.dart';

/// Dati salvati sul dispositivo: impostazioni, preferiti, notifiche lette.
///
/// Le letture sono sincrone (i valori sono caricati all'avvio), le scritture
/// avvengono in background.
abstract interface class LocalStore {
  String? getString(String key);
  List<String>? getStringList(String key);
  void setString(String key, String value);
  void setStringList(String key, List<String> value);
}

/// Chiavi usate dall'app (anche per la allowList di SharedPreferences).
abstract final class StoreKeys {
  static const settings = 'settings';
  static const favorites = 'favorites';
  static const readNotifications = 'read_notifications';
  static const apiCache = 'api_cache';

  static const all = {settings, favorites, readNotifications, apiCache};
}

/// In memoria: per i test e se il salvataggio sul dispositivo non è
/// disponibile.
class MemoryStore implements LocalStore {
  MemoryStore([Map<String, Object>? initial]) : _data = {...?initial};

  final Map<String, Object> _data;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  void setString(String key, String value) => _data[key] = value;

  @override
  void setStringList(String key, List<String> value) =>
      _data[key] = List.of(value);
}

/// SharedPreferences (Android: DataStore/SharedPreferences, iOS: UserDefaults).
class DeviceStore implements LocalStore {
  DeviceStore._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<LocalStore> open() async {
    try {
      final prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: StoreKeys.all,
        ),
      );
      return DeviceStore._(prefs);
    } catch (_) {
      return MemoryStore();
    }
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  @override
  void setString(String key, String value) => _prefs.setString(key, value);

  @override
  void setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
}
