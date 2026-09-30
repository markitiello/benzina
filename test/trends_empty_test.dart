import 'package:benzina/app/app.dart';
import 'package:benzina/app/router.dart';
import 'package:benzina/data/location_service.dart';
import 'package:benzina/data/mock_fuel_repository.dart';
import 'package:benzina/data/models.dart';
import 'package:benzina/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'app_test.dart' show passSplash;

/// Metano: nessun distributore in zona. GPL: nessun dato nemmeno nazionale.
class SparseRepository extends MockFuelRepository {
  SparseRepository() : super(latency: Duration.zero);

  @override
  Future<List<PricePoint>> areaTrend({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async => fuel == FuelType.benzina || fuel == FuelType.diesel
      ? super.areaTrend(
          center: center,
          radiusKm: radiusKm,
          fuel: fuel,
          mode: mode,
          days: days,
        )
      : const [];

  @override
  Future<List<PricePoint>> nationalTrend({
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  }) async => fuel == FuelType.gpl
      ? const []
      : super.nationalTrend(fuel: fuel, mode: mode, days: days);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app([AppSettings settings = const AppSettings()]) => ProviderScope(
    retry: noRetry,
    overrides: [
      fuelRepositoryProvider.overrideWithValue(SparseRepository()),
      locationServiceProvider.overrideWithValue(const FixedLocationService()),
      settingsProvider.overrideWith(() => SettingsNotifier(settings)),
    ],
    child: BenzinaApp(
      router: buildRouter(splashDuration: const Duration(milliseconds: 10)),
    ),
  );

  testWidgets('Andamento: metano senza media della zona, GPL senza dati', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await passSplash(tester);
    await tester.tap(find.text('Andamento').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metano'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('€/kg'), findsOneWidget);
    expect(
      find.textContaining('Nessun distributore di metano'),
      findsOneWidget,
    );
    expect(find.textContaining('Minimo'), findsOneWidget);

    await tester.tap(find.text('GPL'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ancora nessun dato per gpl'), findsOneWidget);
  });

  testWidgets('Home: media nazionale non ancora disponibile', (tester) async {
    await tester.pumpWidget(app(const AppSettings(fuel: FuelType.gpl)));
    await passSplash(tester);
    expect(tester.takeException(), isNull);
    expect(
      find.text('Media nazionale non ancora disponibile.'),
      findsOneWidget,
    );
  });
}
