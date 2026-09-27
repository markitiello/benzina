import 'package:benzina/data/mock_fuel_repository.dart';
import 'package:benzina/data/models.dart';
import 'package:benzina/push/push_message.dart';
import 'package:benzina/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clock = DateTime(2026, 9, 26, 10);

  ProviderContainer container([AppSettings settings = const AppSettings()]) {
    final c = ProviderContainer(
      overrides: [
        fuelRepositoryProvider.overrideWithValue(
          MockFuelRepository(clock: () => clock, latency: Duration.zero),
        ),
        settingsProvider.overrideWith(() => SettingsNotifier(settings)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Legge le notifiche dopo che le tendenze sono arrivate.
  Future<List<AppNotification>> loaded(ProviderContainer c) async {
    c.listen(notificationsProvider, (_, _) {});
    await c.read(trendAlertsProvider.future);
    await Future<void>.delayed(Duration.zero);
    return c.read(notificationsProvider);
  }

  test('solo tendenze del carburante scelto, dalla più recente', () async {
    final list = await loaded(container());
    expect(list.map((n) => n.id), [
      'trend-benzina-self-2026-09-26',
      'trend-benzina-self-2026-09-14',
    ]);
    expect(list.every((n) => n.isPriceAlert && !n.read), isTrue);
  });

  test('cambiando carburante compaiono le sue tendenze', () async {
    final list = await loaded(
      container(const AppSettings(fuel: FuelType.diesel)),
    );
    expect(list.map((n) => n.id), ['trend-diesel-self-2026-09-24']);
  });

  test('la push della stessa tendenza non crea un doppione', () async {
    final c = container();
    final before = await loaded(c);
    final push = PushMessage(
      title: 'Benzina self in calo',
      body: 'Arrivata come push',
      data: const {
        'type': 'trend',
        'fuel': 'benzina',
        'mode': 'self',
        'direction': 'down',
        'day': '2026-09-26',
      },
      receivedAt: clock,
    );
    c.read(notificationsProvider.notifier).add(push.toNotification());
    expect(c.read(notificationsProvider), hasLength(before.length));
  });
}
