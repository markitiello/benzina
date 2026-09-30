import 'dart:convert';

import 'package:benzina/data/api/benzina_api.dart';
import 'package:benzina/data/api/response_cache.dart';
import 'package:benzina/data/api_fuel_repository.dart';
import 'package:benzina/data/models.dart';
import 'package:benzina/state/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

/// Risposte nel formato di docs/openapi.yaml del backend.
Map<String, dynamic> stationSummary(int id) => {
  'id': id,
  'brand': 'Agip Eni',
  'name': 'ENI $id',
  'address': 'VIALE ARGONNE 12',
  'city': 'SAN DONATO MILANESE',
  'province': 'MI',
  'lat': 45.47,
  'lng': 9.22,
};

Map<String, dynamic> stationDetail(int id) => {
  ...stationSummary(id),
  'operator': 'ROSSI SRL',
  'kind': 'Stradale',
  'prices': [
    {
      'fuel': 'benzina',
      'mode': 'self',
      'price': 1.749,
      'reported_at': '2026-09-25T07:00:00+02:00',
    },
    {
      'fuel': 'benzina',
      'mode': 'servito',
      'price': 1.899,
      'reported_at': '2026-09-24T07:00:00+02:00',
    },
    {
      'fuel': 'gpl',
      'mode': 'servito',
      'price': 0.719,
      'reported_at': '2026-09-26T08:30:00+02:00',
    },
    {
      'fuel': 'gpl',
      'mode': 'self',
      'price': 0.709,
      'reported_at': '2026-09-20T08:30:00+02:00',
    },
  ],
};

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {
    'content-type': status == 200
        ? 'application/json'
        : 'application/problem+json',
  },
);

http.Response problem(int status, String title) =>
    json({'type': 'about:blank', 'title': title, 'status': status}, status);

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) handler;
  late List<bool> tokenRefreshes;

  ApiFuelRepository repository({String base = 'https://api.test'}) {
    final api = BenzinaApi(
      baseUrl: Uri.parse(base),
      client: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
      appCheckToken: ({bool forceRefresh = false}) async {
        tokenRefreshes.add(forceRefresh);
        return forceRefresh ? 'token-nuovo' : 'token';
      },
    );
    return ApiFuelRepository(api);
  }

  setUp(() {
    requests = [];
    tokenRefreshes = [];
    handler = (_) => problem(500, 'Non previsto');
  });

  test('distributori vicini: parametri, token App Check e risposta', () async {
    handler = (_) => json({
      'fuel': 'benzina',
      'mode': 'self',
      'data_date': '2026-09-26',
      'national_average': 1.812,
      'offers': [
        {
          'station': stationSummary(3464),
          'price': 1.739,
          'mode': 'self',
          'reported_at': '2026-09-25T19:00:00+02:00',
          'distance_km': 1.24,
        },
      ],
    });

    final offers = await repository().offersNear(
      center: const LatLng(45.4781, 9.227),
      radiusKm: 5,
      fuel: FuelType.benzina,
      mode: ServiceMode.self,
    );

    final request = requests.single;
    expect(request.url.path, '/v1/stations/nearby');
    expect(request.url.queryParameters, {
      'lat': '45.478100',
      'lng': '9.227000',
      'radius_km': '5.0',
      'fuel': 'benzina',
      'mode': 'self',
      'limit': '100',
    });
    expect(request.headers['X-Firebase-AppCheck'], 'token');
    expect(request.headers.containsKey('X-API-Key'), isFalse);

    final offer = offers.single;
    expect(offer.price, 1.739);
    expect(offer.distanceKm, 1.24);
    expect(offer.station.id, '3464');
    expect(offer.station.brand, 'Agip Eni');
    expect(offer.station.city, 'San Donato Milanese');
    expect(offer.station.priceFor(FuelType.benzina, ServiceMode.self), 1.739);
    expect(offer.station.updatedAt, DateTime.utc(2026, 9, 25, 17).toLocal());
  });

  test('risultati con i servizi (se già noti)', () async {
    Map<String, dynamic> offer(int id, List<String> services) => {
      'station': stationSummary(id),
      'price': 1.7,
      'mode': 'self',
      'reported_at': '2026-09-29T08:00:00+02:00',
      'distance_km': 1,
      'services': services,
    };
    handler = (_) => json({
      'fuel': 'benzina',
      'mode': 'self',
      'data_date': '2026-09-29',
      'national_average': 1.8,
      'offers': [
        offer(1, ['Bancomat', 'Food&Beverage']),
        offer(2, []),
      ],
    });

    final offers = await repository().offersNear(
      center: const LatLng(45, 9),
      radiusKm: 5,
      fuel: FuelType.benzina,
      mode: ServiceMode.self,
    );

    expect(offers.first.station.details!.services, [
      'Bancomat',
      'Food&Beverage',
    ]);
    expect(offers.last.station.details, isNull);
  });

  test('GPL e metano si chiedono con mode=any', () async {
    handler = (_) => json({
      'fuel': 'gpl',
      'mode': 'any',
      'data_date': null,
      'national_average': null,
      'offers': [
        {
          'station': stationSummary(1),
          'price': 0.709,
          'mode': 'servito',
          'reported_at': '2026-09-25T19:00:00+02:00',
          'distance_km': 2,
        },
      ],
    });

    final offers = await repository().offersNear(
      center: const LatLng(45, 9),
      radiusKm: 10,
      fuel: FuelType.gpl,
      mode: ServiceMode.servito,
    );

    expect(requests.single.url.queryParameters['mode'], 'any');
    // Nell'app GPL e metano sono sempre "self".
    expect(
      offers.single.station.priceFor(FuelType.gpl, ServiceMode.self),
      0.709,
    );
  });

  test(
    'dettaglio: prezzi, GPL al prezzo più basso, ultimo aggiornamento',
    () async {
      handler = (_) => json(stationDetail(3464));

      final station = (await repository().station('3464'))!;

      expect(requests.single.url.path, '/v1/stations/3464');
      expect(station.priceFor(FuelType.benzina, ServiceMode.self), 1.749);
      expect(station.priceFor(FuelType.benzina, ServiceMode.servito), 1.899);
      expect(station.priceFor(FuelType.gpl, ServiceMode.self), 0.709);
      expect(station.prices.where((p) => p.fuel == FuelType.gpl), hasLength(1));
      expect(station.updatedAt, DateTime.utc(2026, 9, 26, 6, 30).toLocal());
    },
  );

  test('dettaglio: orari, servizi e contatti', () async {
    handler = (_) => json({
      ...stationDetail(3464),
      'details': {
        'phone': '366 6286969',
        'email': null,
        'website': null,
        'services': ['Bancomat', 'Food&Beverage'],
        'opening_hours': [
          {'day': 1, 'hours': '07:00–18:30'},
          {'day': 7, 'hours': 'Chiuso'},
        ],
      },
    });

    final station = (await repository().station('3464'))!;

    final d = station.details!;
    expect(d.phone, '366 6286969');
    expect(d.email, isNull);
    expect(d.hasContacts, isTrue);
    expect(d.services, ['Bancomat', 'Food&Beverage']);
    expect(d.hoursOn(DateTime(2026, 9, 28)), '07:00–18:30'); // lunedì
    expect(d.hoursOn(DateTime(2026, 9, 27)), 'Chiuso'); // domenica
    expect(d.hoursOn(DateTime(2026, 9, 29)), isNull);
    expect(d.openingHours.last.dayName, 'Domenica');
  });

  test('senza dettagli (Osservaprezzi non attivo): null', () async {
    handler = (_) => json({...stationDetail(3464), 'details': null});
    expect((await repository().station('3464'))!.details, isNull);
  });

  test('distributore inesistente o id non valido: null', () async {
    handler = (_) => problem(404, 'Non trovato');
    final repo = repository();

    expect(await repo.station('999'), isNull);
    expect(await repo.station('mock-1'), isNull);
    expect(requests, hasLength(1), reason: 'niente richiesta per mock-1');
  });

  test('preferiti: al massimo 50 id per richiesta', () async {
    handler = (request) => json({
      'stations': [
        for (final id in request.url.queryParameters['ids']!.split(','))
          stationDetail(int.parse(id)),
      ],
    });

    final ids = [for (var i = 1; i <= 60; i++) '$i', 'mock-1'];
    final stations = await repository().stationsById(ids);

    expect(requests, hasLength(2));
    expect(
      requests.first.url.queryParameters['ids']!.split(','),
      hasLength(50),
    );
    expect(stations, hasLength(60));
    expect(await repository().stationsById(const []), isEmpty);
    expect(requests, hasLength(2));
  });

  test('andamento nazionale, della zona e del distributore', () async {
    handler = (_) => json({
      'fuel': 'diesel',
      'mode': 'servito',
      'points': [
        {'day': '2026-09-25', 'price': 1.8},
        {'day': '2026-09-26', 'price': 1.79},
      ],
    });
    final repo = repository();

    final national = await repo.nationalTrend(
      fuel: FuelType.diesel,
      mode: ServiceMode.servito,
      days: 7,
    );
    await repo.areaTrend(
      center: const LatLng(45, 9),
      radiusKm: 2,
      fuel: FuelType.diesel,
      mode: ServiceMode.servito,
      days: 30,
    );
    await repo.stationTrend(
      stationId: '42',
      fuel: FuelType.diesel,
      mode: ServiceMode.servito,
      days: 30,
    );

    expect(national.map((p) => p.price), [1.8, 1.79]);
    expect(national.last.day, DateTime(2026, 9, 26));
    expect(requests.map((r) => r.url.path), [
      '/v1/trends/national',
      '/v1/trends/area',
      '/v1/stations/42/trend',
    ]);
    expect(requests.first.url.queryParameters, {
      'fuel': 'diesel',
      'mode': 'servito',
      'days': '7',
    });
    expect(requests[1].url.queryParameters['radius_km'], '2.0');
  });

  test('recensioni Google', () async {
    handler = (_) => json({
      'place_id': 'abc',
      'rating': 4.3,
      'rating_count': 212,
      'maps_url': 'https://maps.google.com/?cid=1',
      'reviews': [
        {
          'author': 'Mario',
          'author_uri': 'https://www.google.com/maps/contrib/1',
          'rating': 5,
          'relative_time': '2 settimane fa',
          'text': 'Ottimo',
        },
      ],
      'attribution': 'Valutazioni e recensioni fornite da Google',
    });

    final rating = (await repository().googleRating('3464'))!;

    expect(requests.single.url.path, '/v1/stations/3464/google-rating');
    expect(rating.rating, 4.3);
    expect(rating.count, 212);
    expect(rating.mapsUrl, Uri.parse('https://maps.google.com/?cid=1'));
    expect(rating.reviews.single.authorUrl?.host, 'www.google.com');
    expect(rating.attribution, 'Valutazioni e recensioni fornite da Google');
  });

  test('recensioni non disponibili: null, senza errore', () async {
    for (final status in [404, 502, 503]) {
      handler = (_) => problem(status, 'Non disponibile');
      expect(await repository().googleRating('3464'), isNull);
    }
  });

  test('401: riprova una volta con un token App Check nuovo', () async {
    handler = (request) => request.headers['X-Firebase-AppCheck'] == 'token'
        ? problem(401, 'Non autorizzato')
        : json(stationDetail(1));

    final station = await repository().station('1');

    expect(station, isNotNull);
    expect(tokenRefreshes, [false, true]);
    expect(requests.last.headers['X-Firebase-AppCheck'], 'token-nuovo');
  });

  test(
    '401 anche con il token nuovo: errore con il titolo del backend',
    () async {
      handler = (_) => problem(401, 'Non autorizzato');

      await expectLater(
        repository().station('1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 401)
              .having((e) => e.title, 'title', 'Non autorizzato'),
        ),
      );
      expect(requests, hasLength(2));
    },
  );

  test('chiave di sviluppo e backend in una sottocartella', () async {
    handler = (_) => json(stationDetail(1));
    final api = BenzinaApi(
      baseUrl: Uri.parse('https://example.it/benzina/'),
      client: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
      apiKey: 'dev-key',
    );

    await ApiFuelRepository(api).station('1');

    expect(
      requests.single.url.toString(),
      'https://example.it/benzina/v1/stations/1',
    );
    expect(requests.single.headers['X-API-Key'], 'dev-key');
    expect(requests.single.headers.containsKey('X-Firebase-AppCheck'), isFalse);
  });

  test('tendenze segnalate', () async {
    handler = (_) => json({
      'alerts': [
        {
          'fuel': 'gpl',
          'mode': 'any',
          'day': '2026-09-26',
          'direction': 'up',
          'days': 3,
          'change': 0.012,
          'price': 0.72,
          'title': 'GPL in aumento',
          'body': 'Media nazionale 0,720 €/l: +1,2% in 3 giorni.',
          'topic': 'trend_gpl',
          'sent_at': '2026-09-26T09:15:04+02:00',
        },
        {
          'fuel': 'benzina',
          'mode': 'self',
          'day': '2026-09-20',
          'direction': 'down',
          'days': 3,
          'change': -0.01,
          'price': 1.8,
          'title': 'Benzina self in calo',
          'body': '...',
          'topic': 'trend_benzina_self',
          'sent_at': null,
        },
      ],
    });

    final alerts = await repository().trendAlerts(days: 30);

    expect(requests.single.url.path, '/v1/trends/alerts');
    expect(requests.single.url.queryParameters, {'days': '30'});
    expect(alerts, hasLength(2));
    final gpl = alerts.first.toNotification();
    expect(gpl.id, 'trend-gpl-any-2026-09-26');
    expect(gpl.kind, NotificationKind.trendUp);
    expect(gpl.time, DateTime.utc(2026, 9, 26, 7, 15, 4).toLocal());
    // Non ancora inviata: vale il giorno della tendenza.
    expect(alerts.last.toNotification().time, DateTime(2026, 9, 20));
  });

  group('server irraggiungibile', () {
    late MemoryStore store;
    late List<DateTime?> freshness;
    late int now;

    BenzinaApi cachedApi() {
      final api = BenzinaApi(
        baseUrl: Uri.parse('https://api.test'),
        client: MockClient((request) async {
          requests.add(request);
          return handler(request);
        }),
        cache: ResponseCache(store),
        clock: () => DateTime(2026, 9, 29, 10, now),
      );
      api.onFreshness = freshness.add;
      return api;
    }

    setUp(() {
      store = MemoryStore();
      freshness = [];
      now = 0;
    });

    test('usa l\'ultima risposta salvata e lo segnala', () async {
      handler = (_) => json(stationDetail(1));
      final repo = ApiFuelRepository(cachedApi());
      await repo.station('1');
      expect(freshness, [null]);

      now = 30;
      handler = (_) => throw http.ClientException('offline');
      final station = await repo.station('1');
      expect(station!.id, '1');
      expect(freshness.last, DateTime(2026, 9, 29, 10, 0));

      // Anche con un errore del server (5xx).
      handler = (_) => problem(503, 'Servizio non disponibile');
      expect(await repo.station('1'), isNotNull);

      // Tornato raggiungibile: dati aggiornati, niente più avviso.
      handler = (_) => json(stationDetail(1));
      await repo.station('1');
      expect(freshness.last, isNull);
    });

    test('la posizione non conta: si mostra l\'ultima lista', () async {
      final nearby = {
        'fuel': 'benzina',
        'mode': 'self',
        'data_date': '2026-09-29',
        'national_average': 1.8,
        'offers': <Object>[],
      };
      handler = (_) => json(nearby);
      final repo = ApiFuelRepository(cachedApi());
      Future<void> search(double lat) => repo.offersNear(
        center: LatLng(lat, 9),
        radiusKm: 5,
        fuel: FuelType.benzina,
        mode: ServiceMode.self,
      );
      await search(45.0);

      handler = (_) => throw http.ClientException('offline');
      await search(45.01);
      expect(freshness.last, isNotNull);
      // Carburante diverso: niente dati salvati, errore.
      await expectLater(
        repo.offersNear(
          center: const LatLng(45, 9),
          radiusKm: 5,
          fuel: FuelType.diesel,
          mode: ServiceMode.self,
        ),
        throwsA(
          isA<ApiException>().having((e) => e.isUnavailable, 'offline', isTrue),
        ),
      );
    });

    test('gli errori veri non usano i dati salvati', () async {
      handler = (_) => json(stationDetail(1));
      final api = cachedApi();
      await ApiFuelRepository(api).station('1');
      handler = (_) => problem(401, 'Non autorizzato');
      await expectLater(
        ApiFuelRepository(api).station('1'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });
  });

  test('versione del server da /health', () async {
    handler = (_) => json({
      'status': 'ok',
      'data_date': '2026-09-29',
      'version': '1.0.57',
      'commit': 'e21dfd2',
    });
    expect(await repository().serverVersion(), '1.0.57 (e21dfd2)');
    expect(requests.single.url.path, '/health');

    handler = (_) => json({
      'status': 'ok',
      'data_date': null,
      'version': '1.0',
      'commit': null,
    });
    expect(await repository().serverVersion(), '1.0 (sviluppo)');
  });

  test('errore di rete: ApiException con status 0', () async {
    final api = BenzinaApi(
      baseUrl: Uri.parse('https://api.test'),
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      ApiFuelRepository(api).station('1'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)),
    );
  });
}
