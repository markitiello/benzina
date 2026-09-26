import 'package:benzina/data/mock_fuel_repository.dart';
import 'package:benzina/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = MockFuelRepository(
    clock: () => DateTime(2026, 9, 26, 10),
    latency: Duration.zero,
  );

  test('i distributori sono nel raggio e ordinati dal più economico', () async {
    final offers = await repo.offersNear(
      center: MockFuelRepository.defaultCenter,
      radiusKm: 5,
      fuel: FuelType.benzina,
      mode: ServiceMode.self,
    );
    expect(offers, isNotEmpty);
    expect(offers.every((o) => o.distanceKm <= 5), isTrue);
    for (var i = 1; i < offers.length; i++) {
      expect(offers[i].price, greaterThanOrEqualTo(offers[i - 1].price));
    }
  });

  test('il GPL non è venduto ovunque', () async {
    Future<int> count(FuelType fuel) async => (await repo.offersNear(
      center: MockFuelRepository.defaultCenter,
      radiusKm: 20,
      fuel: fuel,
      mode: ServiceMode.self,
    )).length;
    expect(await count(FuelType.gpl), lessThan(await count(FuelType.benzina)));
  });

  test('le serie storiche finiscono oggi', () async {
    final trend = await repo.nationalTrend(
      fuel: FuelType.diesel,
      mode: ServiceMode.self,
      days: 30,
    );
    expect(trend, hasLength(30));
    expect(trend.last.day, DateTime(2026, 9, 26));
  });

  test('un preferito si ritrova anche senza una ricerca precedente', () async {
    final fresh = MockFuelRepository(latency: Duration.zero);
    expect(await fresh.station('mock-1'), isNotNull);
    expect(await fresh.googleRating('mock-1'), isNotNull);
  });
}
