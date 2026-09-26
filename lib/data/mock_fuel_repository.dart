import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'fuel_repository.dart';
import 'models.dart';

/// Dati di prova, generati in modo deterministico attorno alla posizione
/// richiesta: l'app funziona ovunque anche senza backend.
///
/// Prezzi, distributori e recensioni sono inventati.
class MockFuelRepository implements FuelRepository {
  MockFuelRepository({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 300),
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Duration latency;
  final _distance = const Distance();

  /// Ultimi distributori generati, per risolverli dall'id.
  final Map<String, (_Template, Station)> _generated = {};

  static const defaultCenter = LatLng(45.4781, 9.2270); // Milano, Città Studi

  static const _templates = [
    _Template(
      'Q8 Easy',
      'Via Pacini 12',
      0.0060,
      0.0040,
      -0.080,
      4.3,
      212,
      '24 ore su 24',
    ),
    _Template(
      'Eni',
      'Viale Argonne 45',
      -0.0120,
      0.0180,
      -0.060,
      4.0,
      87,
      '06:00–22:00',
    ),
    _Template(
      'IP',
      'Via Porpora 110',
      0.0040,
      -0.0060,
      -0.047,
      3.7,
      54,
      '07:00–21:00',
    ),
    _Template(
      'Tamoil',
      'Via Ampère 30',
      0.0110,
      -0.0100,
      -0.031,
      4.1,
      132,
      '24 ore su 24',
    ),
    _Template(
      'Esso',
      'Via Padova 88',
      -0.0200,
      -0.0150,
      -0.004,
      3.9,
      76,
      '06:30–21:30',
    ),
    _Template(
      'Api',
      'Viale Romagna 7',
      0.0180,
      0.0120,
      0.050,
      3.5,
      41,
      '07:00–20:00',
    ),
    _Template(
      'Q8',
      'Viale Monza 150',
      -0.0300,
      0.0200,
      0.070,
      4.2,
      198,
      '24 ore su 24',
    ),
    _Template(
      'Eni',
      'Via Palmanova 60',
      0.0400,
      0.0300,
      0.020,
      4.4,
      305,
      '24 ore su 24',
    ),
    _Template(
      'Tamoil',
      'Viale Lombardia 3',
      -0.0450,
      -0.0400,
      -0.090,
      3.8,
      66,
      '07:00–21:00',
    ),
  ];

  static const _nationalToday = {
    (FuelType.benzina, ServiceMode.self): 1.819,
    (FuelType.benzina, ServiceMode.servito): 1.979,
    (FuelType.diesel, ServiceMode.self): 1.749,
    (FuelType.diesel, ServiceMode.servito): 1.909,
    (FuelType.gpl, ServiceMode.self): 0.719,
    (FuelType.metano, ServiceMode.self): 1.459,
  };

  DateTime get _today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  static ServiceMode _modeFor(FuelType fuel, ServiceMode mode) =>
      fuel.hasServiceModes ? mode : ServiceMode.self;

  /// Media nazionale di [daysAgo] giorni fa: in lieve calo nell'ultimo anno.
  double _national(FuelType fuel, ServiceMode mode, int daysAgo) {
    final base = _nationalToday[(fuel, _modeFor(fuel, mode))]!;
    return base + 0.012 * math.sin(daysAgo / 4.0) + 0.0002 * daysAgo;
  }

  static double _round3(double v) => (v * 1000).roundToDouble() / 1000;

  Station _buildStation(int index, _Template t, LatLng center) {
    final prices = <FuelPrice>[];
    for (final fuel in FuelType.values) {
      if (fuel == FuelType.gpl && index % 3 != 0) continue;
      if (fuel == FuelType.metano && index % 4 != 1) continue;
      final modes = fuel.hasServiceModes
          ? ServiceMode.values
          : [ServiceMode.self];
      for (final mode in modes) {
        final scale = fuel == FuelType.gpl ? 0.3 : 1.0;
        prices.add(
          FuelPrice(
            fuel,
            mode,
            _round3(_national(fuel, mode, 0) + t.priceDelta * scale),
          ),
        );
      }
    }
    return Station(
      id: 'mock-$index',
      brand: t.brand,
      address: t.address,
      city: 'Milano',
      position: LatLng(center.latitude + t.dLat, center.longitude + t.dLng),
      prices: prices,
      updatedAt: _today.add(const Duration(hours: 8)),
      openingHours: t.openingHours,
    );
  }

  List<Station> _stationsAround(LatLng center) {
    return [
      for (var i = 0; i < _templates.length; i++)
        () {
          final s = _buildStation(i, _templates[i], center);
          _generated[s.id] = (_templates[i], s);
          return s;
        }(),
    ];
  }

  @override
  Future<List<StationOffer>> offersNear({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
  }) async {
    await Future<void>.delayed(latency);
    final offers = <StationOffer>[];
    for (final s in _stationsAround(center)) {
      final price = s.priceFor(fuel, mode);
      if (price == null) continue;
      final km = _distance.as(LengthUnit.Meter, center, s.position) / 1000;
      if (km > radiusKm) continue;
      offers.add(StationOffer(station: s, price: price, distanceKm: km));
    }
    offers.sort((a, b) => a.price.compareTo(b.price));
    return offers;
  }

  @override
  Future<Station?> station(String id) async {
    await Future<void>.delayed(latency);
    return _lookup(id);
  }

  Station? _lookup(String id) {
    // Un id non ancora visto (es. un preferito di una sessione precedente):
    // rigenera i distributori attorno al centro di default.
    if (!_generated.containsKey(id)) _stationsAround(defaultCenter);
    return _generated[id]?.$2;
  }

  @override
  Future<List<Station>> stationsById(Iterable<String> ids) async {
    await Future<void>.delayed(latency);
    return [for (final id in ids) ?_lookup(id)];
  }

  List<PricePoint> _series(int days, double Function(int daysAgo) valueAt) {
    final today = _today;
    return [
      for (var daysAgo = days - 1; daysAgo >= 0; daysAgo--)
        PricePoint(
          today.subtract(Duration(days: daysAgo)),
          _round3(valueAt(daysAgo)),
        ),
    ];
  }

  @override
  Future<List<PricePoint>> nationalTrend({
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async {
    await Future<void>.delayed(latency);
    return _series(days, (d) => _national(fuel, mode, d));
  }

  @override
  Future<List<PricePoint>> areaTrend({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async {
    await Future<void>.delayed(latency);
    final scale = fuel == FuelType.gpl ? 0.3 : 1.0;
    return _series(
      days,
      (d) =>
          _national(fuel, mode, d) - 0.034 * scale + 0.004 * math.sin(d / 3.0),
    );
  }

  @override
  Future<List<PricePoint>> stationTrend({
    required String stationId,
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async {
    await Future<void>.delayed(latency);
    final today =
        _lookup(stationId)?.priceFor(fuel, mode) ?? _national(fuel, mode, 0);
    // Il prezzo di un distributore cambia a scalini, non ogni giorno.
    return _series(days, (d) => today + 0.008 * ((d ~/ 5) % 4) + 0.0002 * d);
  }

  @override
  Future<GoogleRating?> googleRating(String stationId) async {
    await Future<void>.delayed(latency);
    final station = _lookup(stationId);
    if (station == null) return null;
    final t = _generated[stationId]!.$1;
    return GoogleRating(
      rating: t.rating,
      count: t.reviewCount,
      reviews: const [
        Review(
          author: 'Utente di prova',
          rating: 5,
          relativeTime: '2 settimane fa',
          text:
              'Recensione di esempio. Qui comparirà il testo restituito da '
              'Google Places, troncato a 3 righe.',
        ),
        Review(
          author: 'Altro utente di prova',
          rating: 4,
          relativeTime: '1 mese fa',
          text: 'Seconda recensione di esempio.',
        ),
      ],
      mapsUrl: Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${station.position.latitude},${station.position.longitude}',
      }),
    );
  }
}

class _Template {
  const _Template(
    this.brand,
    this.address,
    this.dLat,
    this.dLng,
    this.priceDelta,
    this.rating,
    this.reviewCount,
    this.openingHours,
  );

  final String brand;
  final String address;
  final double dLat;
  final double dLng;
  final double priceDelta;
  final double rating;
  final int reviewCount;
  final String openingHours;
}
