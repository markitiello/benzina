import 'package:benzina/data/mock_fuel_repository.dart';
import 'package:benzina/data/models.dart';
import 'package:benzina/state/local_store.dart';
import 'package:benzina/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Un "avvio" dell'app con i dati salvati in [store].
  ProviderContainer launch(LocalStore store) {
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        fuelRepositoryProvider.overrideWithValue(
          MockFuelRepository(
            clock: () => DateTime(2026, 9, 26, 10),
            latency: Duration.zero,
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('le impostazioni restano dopo il riavvio', () {
    final store = MemoryStore();
    launch(store)
        .read(settingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            fuel: FuelType.diesel,
            mode: ServiceMode.servito,
            radiusKm: 10,
            themeMode: ThemeMode.dark,
            trendAlerts: false,
          ),
        );

    final s = launch(store).read(settingsProvider);
    expect(s.fuel, FuelType.diesel);
    expect(s.mode, ServiceMode.servito);
    expect(s.radiusKm, 10);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.trendAlerts, isFalse);
  });

  test('impostazioni salvate non valide: valori predefiniti', () {
    final store = MemoryStore({
      StoreKeys.settings: '{"fuel":"kerosene","radiusKm":999,"themeMode":1}',
    });
    final s = launch(store).read(settingsProvider);
    expect(s.fuel, FuelType.benzina);
    expect(s.radiusKm, 5);
    expect(s.themeMode, ThemeMode.system);
    expect(
      launch(MemoryStore({StoreKeys.settings: 'non è json'}))
          .read(settingsProvider)
          .fuel,
      FuelType.benzina,
    );
  });

  test('i preferiti restano dopo il riavvio', () {
    final store = MemoryStore();
    final first = launch(store).read(favoritesProvider.notifier)
      ..toggle('3464')
      ..toggle('1001')
      ..toggle('3464');
    expect(first.state, {'1001'});
    expect(launch(store).read(favoritesProvider), {'1001'});
  });

  test('le notifiche lette restano lette dopo il riavvio', () async {
    final store = MemoryStore();

    Future<List<AppNotification>> notifications(ProviderContainer c) async {
      c.listen(notificationsProvider, (_, _) {});
      await c.read(trendAlertsProvider.future);
      await Future<void>.delayed(Duration.zero);
      return c.read(notificationsProvider);
    }

    final c1 = launch(store);
    final list = await notifications(c1);
    expect(list.where((n) => !n.read), hasLength(2));
    c1.read(notificationsProvider.notifier).markRead(list.first.id);

    final after = await notifications(launch(store));
    expect(after.first.read, isTrue);
    expect(after.last.read, isFalse);

    final c3 = launch(store);
    await notifications(c3);
    c3.read(notificationsProvider.notifier).markAllRead();
    expect((await notifications(launch(store))).every((n) => n.read), isTrue);
  });
}
