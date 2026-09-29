import 'dart:convert';

import '../../state/local_store.dart';

/// Risposta salvata: il JSON e quando è arrivato dal server.
typedef CachedResponse = ({Map<String, dynamic> json, DateTime savedAt});

/// Ultime risposte del backend salvate sul dispositivo, per mostrare
/// qualcosa quando il server non è raggiungibile.
///
/// La chiave ignora posizione e raggio: senza rete è meglio vedere l'ultima
/// lista di distributori (anche se ci si è spostati di poco) che niente.
class ResponseCache {
  ResponseCache(this._store, {this.maxEntries = 40});

  final LocalStore _store;
  final int maxEntries;

  static const _ignored = {'lat', 'lng', 'radius_km', 'limit'};

  static String keyFor(String path, Map<String, String> query) {
    final params =
        query.entries.where((e) => !_ignored.contains(e.key)).toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return [path, for (final e in params) '${e.key}=${e.value}'].join('|');
  }

  Map<String, dynamic> _all() {
    final raw = _store.getString(StoreKeys.apiCache);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  CachedResponse? get(String key) {
    final entry = _all()[key];
    if (entry is! Map<String, dynamic>) return null;
    final savedAt = DateTime.tryParse(entry['at'] as String? ?? '');
    final json = entry['json'];
    if (savedAt == null || json is! Map<String, dynamic>) return null;
    return (json: json, savedAt: savedAt);
  }

  void put(String key, Map<String, dynamic> json, DateTime savedAt) {
    final all = _all()..[key] = {'at': savedAt.toIso8601String(), 'json': json};
    // Si tengono le più recenti.
    if (all.length > maxEntries) {
      final byAge = all.entries.toList()
        ..sort(
          (a, b) =>
              (b.value['at'] as String).compareTo(a.value['at'] as String),
        );
      all
        ..clear()
        ..addEntries(byAge.take(maxEntries));
    }
    _store.setString(StoreKeys.apiCache, jsonEncode(all));
  }
}
