import 'package:latlong2/latlong.dart';

import 'api/benzina_api.dart';
import 'fuel_repository.dart';
import 'models.dart';

/// [FuelRepository] che legge dal backend Benzina.
class ApiFuelRepository implements FuelRepository {
  ApiFuelRepository(this._api);

  final BenzinaApi _api;

  /// Il backend accetta al massimo 50 id per richiesta.
  static const _maxIds = 50;

  @override
  Future<List<StationOffer>> offersNear({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
  }) async {
    final json = await _api.get(
      '/v1/stations/nearby',
      query: {..._area(center, radiusKm), ..._fuel(fuel, mode), 'limit': '100'},
    );
    return [
      for (final o in _list(json!['offers']))
        StationOffer(
          station: _station(
            o['station'] as Map<String, dynamic>,
            prices: [
              FuelPrice(
                fuel,
                fuel.hasServiceModes
                    ? ServiceMode.values.byName(o['mode'] as String)
                    : ServiceMode.self,
                _num(o['price']),
              ),
            ],
            updatedAt: _dateTime(o['reported_at']),
            details: _servicesOnly(o['services']),
          ),
          price: _num(o['price']),
          distanceKm: _num(o['distance_km']),
        ),
    ];
  }

  @override
  Future<Station?> station(String id) async {
    if (!_isId(id)) return null;
    final json = await _api.get('/v1/stations/$id', nullOn404: true);
    return json == null ? null : _stationWithPrices(json);
  }

  @override
  Future<List<Station>> stationsById(Iterable<String> ids) async {
    final valid = ids.where(_isId).toSet().toList();
    final stations = <Station>[];
    for (var i = 0; i < valid.length; i += _maxIds) {
      final chunk = valid.skip(i).take(_maxIds);
      final json = await _api.get(
        '/v1/stations',
        query: {'ids': chunk.join(',')},
      );
      stations.addAll(_list(json!['stations']).map(_stationWithPrices));
    }
    return stations;
  }

  @override
  Future<List<PricePoint>> nationalTrend({
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async {
    final json = await _api.get(
      '/v1/trends/national',
      query: {..._fuel(fuel, mode), ..._days(days)},
    );
    return _points(json!);
  }

  @override
  Future<List<PricePoint>> areaTrend({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async {
    final json = await _api.get(
      '/v1/trends/area',
      query: {..._area(center, radiusKm), ..._fuel(fuel, mode), ..._days(days)},
    );
    return _points(json!);
  }

  @override
  Future<List<PricePoint>> stationTrend({
    required String stationId,
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async {
    if (!_isId(stationId)) return const [];
    final json = await _api.get(
      '/v1/stations/$stationId/trend',
      query: {..._fuel(fuel, mode), ..._days(days)},
      nullOn404: true,
    );
    return json == null ? const [] : _points(json);
  }

  @override
  Future<GoogleRating?> googleRating(String stationId) async {
    if (!_isId(stationId)) return null;
    final Map<String, dynamic>? json;
    try {
      json = await _api.get(
        '/v1/stations/$stationId/google-rating',
        nullOn404: true,
      );
    } on ApiException catch (e) {
      // 503: recensioni non attive sul server; 502: Google non risponde.
      // Le recensioni sono un di più: la schermata resta utilizzabile.
      if (e.status == 502 || e.status == 503) return null;
      rethrow;
    }
    final rating = json?['rating'];
    if (json == null || rating == null) return null;
    return GoogleRating(
      rating: _num(rating),
      count: json['rating_count'] as int,
      reviews: [
        for (final r in _list(json['reviews']))
          Review(
            author: r['author'] as String,
            authorUrl: _uri(r['author_uri']),
            rating: r['rating'] as int,
            relativeTime: r['relative_time'] as String,
            text: r['text'] as String,
          ),
      ],
      mapsUrl: _uri(json['maps_url']),
      attribution: json['attribution'] as String,
    );
  }

  @override
  Future<List<TrendAlert>> trendAlerts({int days = 30}) async {
    final json = await _api.get(
      '/v1/trends/alerts',
      query: {'days': '${days.clamp(1, 366)}'},
    );
    return [
      for (final a in _list(json!['alerts']))
        if (FuelType.values.asNameMap()[a['fuel']] case final fuel?)
          TrendAlert(
            fuel: fuel,
            mode: a['mode'] as String,
            day: DateTime.parse(a['day'] as String),
            rising: a['direction'] == 'up',
            title: a['title'] as String,
            body: a['body'] as String,
            topic: a['topic'] as String,
            sentAt: a['sent_at'] == null ? null : _dateTime(a['sent_at']),
          ),
    ];
  }

  @override
  Future<String?> serverVersion() async {
    final json = await _api.get('/health');
    final version = json?['version'];
    if (version is! String) return null;
    final commit = json!['commit'];
    return '$version (${commit is String ? commit : 'sviluppo'})';
  }

  // --- Parametri -------------------------------------------------------------

  static Map<String, String> _area(LatLng center, double radiusKm) => {
    'lat': center.latitude.toStringAsFixed(6),
    'lng': center.longitude.toStringAsFixed(6),
    'radius_km': '${radiusKm.clamp(0.1, 50)}',
  };

  /// GPL e metano non distinguono self e servito: il backend usa `any`.
  static Map<String, String> _fuel(FuelType fuel, ServiceMode mode) => {
    'fuel': fuel.name,
    'mode': fuel.hasServiceModes ? mode.name : 'any',
  };

  static Map<String, String> _days(int days) => {
    'days': '${days.clamp(2, 366)}',
  };

  static bool _isId(String id) => RegExp(r'^\d+$').hasMatch(id);

  // --- Risposte --------------------------------------------------------------

  static Station _stationWithPrices(Map<String, dynamic> json) {
    final prices = <FuelPrice>[];
    DateTime? updatedAt;
    for (final p in _list(json['prices'])) {
      final fuel = FuelType.values.asNameMap()[p['fuel']];
      if (fuel == null) continue;
      final price = _num(p['price']);
      final reported = _dateTime(p['reported_at']);
      if (updatedAt == null || reported.isAfter(updatedAt)) {
        updatedAt = reported;
      }
      if (fuel.hasServiceModes) {
        prices.add(
          FuelPrice(
            fuel,
            ServiceMode.values.byName(p['mode'] as String),
            price,
          ),
        );
        continue;
      }
      // GPL e metano: un solo prezzo, il più basso tra self e servito.
      final i = prices.indexWhere((e) => e.fuel == fuel);
      if (i < 0) {
        prices.add(FuelPrice(fuel, ServiceMode.self, price));
      } else if (price < prices[i].price) {
        prices[i] = FuelPrice(fuel, ServiceMode.self, price);
      }
    }
    final details = _details(json['details']);
    return _station(
      json,
      prices: prices,
      updatedAt: updatedAt,
      details: details,
    );
  }

  /// Nei risultati della ricerca ci sono solo i servizi (se già noti).
  static StationDetails? _servicesOnly(Object? value) {
    final services = [
      for (final s in (value is List ? value : const []))
        if (s is String) s,
    ];
    return services.isEmpty ? null : StationDetails(services: services);
  }

  static StationDetails? _details(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    return StationDetails(
      phone: text(value['phone']),
      email: text(value['email']),
      website: text(value['website']),
      services: [
        for (final s in (value['services'] as List? ?? const []))
          if (s is String) s,
      ],
      openingHours: [
        for (final h in (value['opening_hours'] as List? ?? const []))
          if (h is Map && h['day'] is int && h['hours'] is String)
            OpeningHours(h['day'] as int, h['hours'] as String),
      ],
    );
  }

  static Station _station(
    Map<String, dynamic> json, {
    required List<FuelPrice> prices,
    DateTime? updatedAt,
    StationDetails? details,
  }) {
    final brand = (json['brand'] as String).trim();
    return Station(
      id: '${json['id']}',
      brand: brand.isEmpty ? (json['name'] as String).trim() : brand,
      address: (json['address'] as String).trim(),
      city: _capitalize(json['city'] as String),
      position: LatLng(_num(json['lat']), _num(json['lng'])),
      prices: prices,
      updatedAt: updatedAt ?? DateTime.now(),
      openingHours: details?.hoursOn(DateTime.now()),
      details: details,
    );
  }

  static List<PricePoint> _points(Map<String, dynamic> json) => [
    for (final p in _list(json['points']))
      PricePoint(DateTime.parse(p['day'] as String), _num(p['price'])),
  ];

  static Iterable<Map<String, dynamic>> _list(Object? value) =>
      (value as List).cast<Map<String, dynamic>>();

  static double _num(Object? value) => (value as num).toDouble();

  static DateTime _dateTime(Object? value) =>
      DateTime.parse(value as String).toLocal();

  static Uri? _uri(Object? value) =>
      value is String && value.isNotEmpty ? Uri.tryParse(value) : null;

  /// I comuni nell'anagrafica MIMIT sono in maiuscolo: "SAN DONATO MILANESE"
  /// diventa "San Donato Milanese".
  static String _capitalize(String value) => value
      .trim()
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
