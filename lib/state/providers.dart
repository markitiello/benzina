import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/fuel_repository.dart';
import '../data/location_service.dart';
import '../data/mock_fuel_repository.dart';
import '../data/models.dart';

// --- Servizi (sostituibili nei test con `overrides`) -----------------------

final fuelRepositoryProvider = Provider<FuelRepository>(
  (ref) => MockFuelRepository(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

// --- Impostazioni -----------------------------------------------------------

class AppSettings {
  const AppSettings({
    this.fuel = FuelType.benzina,
    this.mode = ServiceMode.self,
    this.radiusKm = 5,
    this.themeMode = ThemeMode.system,
    this.thresholdAlert = true,
    this.threshold = 1.750,
    this.favoriteAlerts = true,
    this.weeklySummary = false,
  });

  final FuelType fuel;
  final ServiceMode mode;
  final double radiusKm;
  final ThemeMode themeMode;
  final bool thresholdAlert;
  final double threshold;
  final bool favoriteAlerts;
  final bool weeklySummary;

  /// Modalità effettiva: GPL e metano sono solo self.
  ServiceMode get effectiveMode =>
      fuel.hasServiceModes ? mode : ServiceMode.self;

  AppSettings copyWith({
    FuelType? fuel,
    ServiceMode? mode,
    double? radiusKm,
    ThemeMode? themeMode,
    bool? thresholdAlert,
    double? threshold,
    bool? favoriteAlerts,
    bool? weeklySummary,
  }) {
    return AppSettings(
      fuel: fuel ?? this.fuel,
      mode: mode ?? this.mode,
      radiusKm: radiusKm ?? this.radiusKm,
      themeMode: themeMode ?? this.themeMode,
      thresholdAlert: thresholdAlert ?? this.thresholdAlert,
      threshold: threshold ?? this.threshold,
      favoriteAlerts: favoriteAlerts ?? this.favoriteAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }
}

// TODO: salvare le impostazioni sul dispositivo (shared_preferences).
class SettingsNotifier extends Notifier<AppSettings> {
  SettingsNotifier([this._initial = const AppSettings()]);

  final AppSettings _initial;

  @override
  AppSettings build() => _initial;

  void update(AppSettings Function(AppSettings s) change) =>
      state = change(state);
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

const radiusOptions = [2.0, 5.0, 10.0, 20.0];

// --- Posizione e dati ------------------------------------------------------

final locationProvider = FutureProvider<UserLocation>(
  (ref) => ref.watch(locationServiceProvider).current(),
);

/// Distributori nel raggio per il carburante scelto, dal più economico.
final nearbyOffersProvider = FutureProvider<List<StationOffer>>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final s = ref.watch(settingsProvider);
  return ref
      .watch(fuelRepositoryProvider)
      .offersNear(
        center: location.position,
        radiusKm: s.radiusKm,
        fuel: s.fuel,
        mode: s.effectiveMode,
      );
});

typedef TrendKey = ({FuelType fuel, ServiceMode mode, int days});

final nationalTrendProvider = FutureProvider.family<List<PricePoint>, TrendKey>(
  (ref, key) => ref
      .watch(fuelRepositoryProvider)
      .nationalTrend(
        fuel: key.fuel,
        mode: key.fuel.hasServiceModes ? key.mode : ServiceMode.self,
        days: key.days,
      ),
);

final areaTrendProvider = FutureProvider.family<List<PricePoint>, TrendKey>((
  ref,
  key,
) async {
  final location = await ref.watch(locationProvider.future);
  final radius = ref.watch(settingsProvider.select((s) => s.radiusKm));
  return ref
      .watch(fuelRepositoryProvider)
      .areaTrend(
        center: location.position,
        radiusKm: radius,
        fuel: key.fuel,
        mode: key.fuel.hasServiceModes ? key.mode : ServiceMode.self,
        days: key.days,
      );
});

/// Media nazionale di oggi per il carburante delle impostazioni.
final nationalAverageProvider = FutureProvider<double>((ref) async {
  final s = ref.watch(settingsProvider);
  final trend = await ref.watch(
    nationalTrendProvider((fuel: s.fuel, mode: s.effectiveMode, days: 7))
        .future,
  );
  return trend.last.price;
});

final stationProvider = FutureProvider.family<Station?, String>(
  (ref, id) => ref.watch(fuelRepositoryProvider).station(id),
);

final stationTrendProvider =
    FutureProvider.family<
      List<PricePoint>,
      ({String id, FuelType fuel, ServiceMode mode})
    >(
      (ref, key) => ref
          .watch(fuelRepositoryProvider)
          .stationTrend(
            stationId: key.id,
            fuel: key.fuel,
            mode: key.mode,
            days: 30,
          ),
    );

final googleRatingProvider = FutureProvider.family<GoogleRating?, String>(
  (ref, id) => ref.watch(fuelRepositoryProvider).googleRating(id),
);

// --- Preferiti ---------------------------------------------------------------

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {'mock-1'};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

final favoriteStationsProvider = FutureProvider<List<Station>>(
  (ref) => ref
      .watch(fuelRepositoryProvider)
      .stationsById(ref.watch(favoritesProvider)),
);

// --- Notifiche ---------------------------------------------------------------

// TODO: ricevere le notifiche push (Firebase Cloud Messaging) e salvarle.
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      AppNotification(
        id: 'n1',
        kind: NotificationKind.priceBelowThreshold,
        title: 'Prezzo sotto la tua soglia',
        body: 'Q8 Easy · Via Pacini: benzina self a 1,739 €/l (soglia 1,750).',
        time: today.add(const Duration(hours: 8, minutes: 5)),
        stationId: 'mock-0',
      ),
      AppNotification(
        id: 'n2',
        kind: NotificationKind.favoriteDrop,
        title: 'Un preferito ha abbassato il prezzo',
        body: 'Eni · Viale Argonne: benzina self −0,020 €/l rispetto a ieri.',
        time: today.add(const Duration(hours: 8, minutes: 1)),
        stationId: 'mock-1',
      ),
      AppNotification(
        id: 'n3',
        kind: NotificationKind.weeklySummary,
        title: 'Riepilogo settimanale',
        body: 'Media nazionale benzina 1,819 €/l, −0,6% sulla settimana.',
        time: today.subtract(const Duration(days: 2, hours: -9)),
        read: true,
      ),
      AppNotification(
        id: 'n4',
        kind: NotificationKind.appUpdate,
        title: 'Aggiornamento disponibile',
        body: 'È disponibile una nuova versione dell\'app. Scopri le novità.',
        time: today.subtract(const Duration(days: 3, hours: -10)),
        read: true,
      ),
    ];
  }

  void markRead(String id) =>
      state = [for (final n in state) n.id == id ? n.copyWith(read: true) : n];

  void markAllRead() => state = [for (final n in state) n.copyWith(read: true)];
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).where((n) => !n.read).length,
);

// --- App ---------------------------------------------------------------------

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);
