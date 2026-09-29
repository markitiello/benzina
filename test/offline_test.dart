import 'package:benzina/app/app.dart';
import 'package:benzina/app/router.dart';
import 'package:benzina/data/api/benzina_api.dart';
import 'package:benzina/data/location_service.dart';
import 'package:benzina/data/mock_fuel_repository.dart';
import 'package:benzina/data/models.dart';
import 'package:benzina/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'app_test.dart' show buildApp, passSplash;

/// Backend irraggiungibile e nessun dato salvato.
class OfflineRepository extends MockFuelRepository {
  OfflineRepository() : super(latency: Duration.zero);

  @override
  Future<List<StationOffer>> offersNear({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
  }) async => throw const ApiException(0, 'Connessione non riuscita');
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('senza server né dati salvati: pagina dedicata', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          fuelRepositoryProvider.overrideWithValue(OfflineRepository()),
          locationServiceProvider.overrideWithValue(
            const FixedLocationService(),
          ),
        ],
        child: BenzinaApp(
          router: buildRouter(splashDuration: const Duration(milliseconds: 10)),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.text('Impossibile raggiungere il server'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Riprova'), findsOneWidget);
  });

  testWidgets('dati salvati: banner rosso in alto con Riprova', (tester) async {
    await tester.pumpWidget(buildApp());
    await passSplash(tester);
    expect(find.textContaining('Impossibile aggiornare i dati'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BenzinaApp)),
    );
    final now = DateTime.now();
    container
        .read(staleDataProvider.notifier)
        .set(DateTime(now.year, now.month, now.day, 8, 5));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Impossibile aggiornare i dati. Visualizzi quelli di oggi 08:05.',
      ),
      findsOneWidget,
    );
    // I dati restano visibili sotto il banner.
    expect(find.text('Q8 Easy'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Riprova'));
    await tester.pumpAndSettle();
    container.read(staleDataProvider.notifier).set(null);
    await tester.pumpAndSettle();
    expect(find.textContaining('Impossibile aggiornare i dati'), findsNothing);
  });
}
