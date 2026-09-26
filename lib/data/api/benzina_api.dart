import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Token Firebase App Check; `forceRefresh` ne chiede uno nuovo.
typedef AppCheckTokenSource = Future<String?> Function({bool forceRefresh});

/// Errore delle API (risposta `application/problem+json`, RFC 9457) oppure
/// di rete (`status` 0).
class ApiException implements Exception {
  const ApiException(this.status, this.title, [this.detail]);

  final int status;
  final String title;
  final String? detail;

  @override
  String toString() =>
      'ApiException($status): $title${detail == null ? '' : ' — $detail'}';
}

/// Client HTTP del backend Benzina (vedi docs/openapi.yaml nel repository
/// del backend).
///
/// Ogni richiesta porta il token App Check (`X-Firebase-AppCheck`), che
/// dimostra al backend che arriva dall'app originale. In sviluppo si può usare
/// una chiave statica (`X-API-Key`), che non va mai inserita nelle build
/// pubblicate: dall'app si estrae facilmente.
class BenzinaApi {
  BenzinaApi({
    required Uri baseUrl,
    http.Client? client,
    this.appCheckToken,
    this.apiKey,
    this.timeout = const Duration(seconds: 15),
  }) : _base = baseUrl,
       _client = client ?? http.Client();

  final Uri _base;
  final http.Client _client;
  final AppCheckTokenSource? appCheckToken;
  final String? apiKey;
  final Duration timeout;

  /// GET di [path] (es. `/v1/stations/nearby`). Con [nullOn404] una risposta
  /// 404 restituisce `null` invece di un errore.
  Future<Map<String, dynamic>?> get(
    String path, {
    Map<String, String> query = const {},
    bool nullOn404 = false,
  }) async {
    final basePath = _base.path.endsWith('/')
        ? _base.path.substring(0, _base.path.length - 1)
        : _base.path;
    final url = _base.replace(
      path: '$basePath$path',
      queryParameters: query.isEmpty ? null : query,
    );

    var response = await _send(url, forceRefresh: false);
    // Token scaduto o revocato: un solo nuovo tentativo con un token nuovo.
    if (response.statusCode == 401 && appCheckToken != null) {
      response = await _send(url, forceRefresh: true);
    }

    if (response.statusCode == 404 && nullOn404) return null;
    if (response.statusCode != 200) throw _problem(response);
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(response.statusCode, 'Risposta non valida');
    }
  }

  Future<http.Response> _send(Uri url, {required bool forceRefresh}) async {
    final headers = {'Accept': 'application/json'};
    try {
      final token = await appCheckToken?.call(forceRefresh: forceRefresh);
      if (token != null && token.isNotEmpty) {
        headers['X-Firebase-AppCheck'] = token;
      }
    } catch (_) {
      // Senza token si prova lo stesso: con la chiave di sviluppo, o per
      // ricevere un 401 chiaro dal backend.
    }
    if (apiKey case final key? when key.isNotEmpty) headers['X-API-Key'] = key;

    try {
      return await _client.get(url, headers: headers).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(0, 'Il server non risponde');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Connessione non riuscita', e.message);
    }
  }

  static ApiException _problem(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      return ApiException(
        response.statusCode,
        json['title'] as String? ?? 'Errore ${response.statusCode}',
        json['detail'] as String?,
      );
    } catch (_) {
      return ApiException(response.statusCode, 'Errore ${response.statusCode}');
    }
  }

  void close() => _client.close();
}
