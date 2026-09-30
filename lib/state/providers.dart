import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/api/benzina_api.dart';
import '../data/fuel_repository.dart';
import '../data/location_service.dart';
import '../data/mock_fuel_repository.dart';
import '../data/models.dart';
import '../push/push_topics.dart';
import 'local_store.dart';

// --- Servizi (sostituibili nei test con `overrides`) -----------------------

final fuelRepositoryProvider = Provider<FuelRepository>(
  (ref) => MockFuelRepository(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

/// Sostituito in main.dart con DeviceStore (dati salvati sul telefono).
final localStoreProvider = Provider<LocalStore>((ref) => MemoryStore());

/// Client del backend, se configurato (in main.dart); `null` con i dati di prova.
final apiClientProvider = Provider<BenzinaApi?>((ref) => null);

/// Data dei dati mostrati quando il server non è raggiungibile e si usano
/// quelli salvati; `null` se i dati sono aggiornati.
class StaleDataNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? since) {
    if (state != since) state = since;
  }
}

final staleDataProvider = NotifierProvider<StaleDataNotifier, DateTime?>(
  StaleDataNotifier.new,
);

/// Nessun nuovo tentativo automatico quando un provider fallisce (Riverpod
/// ripete con attese crescenti: senza rete la splash resterebbe ferma per
/// secondi). Si riprova con il pulsante "Riprova".
Duration? noRetry(int retryCount, Object error) => null;

/// Richiede di nuovo al server tutti i dati mostrati (pulsante "Riprova").
void refreshAllData(WidgetRef ref) {
  ref
    ..invalidate(nearbyOffersProvider)
    ..invalidate(nationalTrendProvider)
    ..invalidate(areaTrendProvider)
    ..invalidate(stationProvider)
    ..invalidate(stationTrendProvider)
    ..invalidate(favoriteStationsProvider)
    ..invalidate(googleRatingProvider)
    ..invalidate(trendAlertsProvider);
}

// --- Impostazioni -----------------------------------------------------------

class AppSettings {
  const AppSettings({
    this.fuel = FuelType.benzina,
    this.mode = ServiceMode.self,
    this.radiusKm = 5,
    this.themeMode = ThemeMode.system,
    this.trendAlerts = true,
  });

  final FuelType fuel;
  final ServiceMode mode;
  final double radiusKm;
  final ThemeMode themeMode;

  /// Notifica push quando la media nazionale del carburante scelto inizia a
  /// salire o a scendere (vedi lib/push/).
  final bool trendAlerts;

  /// Modalità effettiva: GPL e metano sono solo self.
  ServiceMode get effectiveMode =>
      fuel.hasServiceModes ? mode : ServiceMode.self;

  AppSettings copyWith({
    FuelType? fuel,
    ServiceMode? mode,
    double? radiusKm,
    ThemeMode? themeMode,
    bool? trendAlerts,
  }) {
    return AppSettings(
      fuel: fuel ?? this.fuel,
      mode: mode ?? this.mode,
      radiusKm: radiusKm ?? this.radiusKm,
      themeMode: themeMode ?? this.themeMode,
      trendAlerts: trendAlerts ?? this.trendAlerts,
    );
  }

  Map<String, Object> toJson() => {
    'fuel': fuel.name,
    'mode': mode.name,
    'radiusKm': radiusKm,
    'themeMode': themeMode.name,
    'trendAlerts': trendAlerts,
  };

  /// Valori mancanti o non validi (es. da una versione precedente) tornano
  /// a quelli predefiniti.
  factory AppSettings.fromJson(Map<String, Object?> json) {
    const d = AppSettings();
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.asNameMap()[name] ?? fallback;
    final radius = json['radiusKm'];
    return AppSettings(
      fuel: pick(FuelType.values, json['fuel'], d.fuel),
      mode: pick(ServiceMode.values, json['mode'], d.mode),
      radiusKm: radius is num && radiusOptions.contains(radius.toDouble())
          ? radius.toDouble()
          : d.radiusKm,
      themeMode: pick(ThemeMode.values, json['themeMode'], d.themeMode),
      trendAlerts: json['trendAlerts'] is bool
          ? json['trendAlerts'] as bool
          : d.trendAlerts,
    );
  }
}

/// Impostazioni, salvate sul dispositivo a ogni modifica.
class SettingsNotifier extends Notifier<AppSettings> {
  /// Con [initial] (nei test) non si leggono quelle salvate.
  SettingsNotifier([this._initial]);

  final AppSettings? _initial;

  @override
  AppSettings build() {
    if (_initial case final initial?) return initial;
    final saved = ref.read(localStoreProvider).getString(StoreKeys.settings);
    if (saved == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(saved) as Map<String, Object?>);
    } catch (_) {
      return const AppSettings();
    }
  }

  void update(AppSettings Function(AppSettings s) change) {
    state = change(state);
    ref
        .read(localStoreProvider)
        .setString(StoreKeys.settings, jsonEncode(state.toJson()));
  }
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

/// Ultima media nazionale per il carburante delle impostazioni; `null` se il
/// backend non ha ancora dati.
final nationalAverageProvider = FutureProvider<double?>((ref) async {
  final s = ref.watch(settingsProvider);
  final trend = await ref.watch(
    nationalTrendProvider((fuel: s.fuel, mode: s.effectiveMode, days: 7))
        .future,
  );
  return trend.lastOrNull?.price;
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

/// Id dei distributori preferiti, salvati sul dispositivo.
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {
    ...?ref.read(localStoreProvider).getStringList(StoreKeys.favorites),
  };

  void toggle(String id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    ref
        .read(localStoreProvider)
        .setStringList(StoreKeys.favorites, state.toList());
  }
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

/// Tendenze della media nazionale per il carburante delle impostazioni
/// (le stesse inviate come notifiche push), dal backend.
final trendAlertsProvider = FutureProvider<List<TrendAlert>>((ref) async {
  final s = ref.watch(settingsProvider);
  final topic = trendTopic(s.fuel, s.effectiveMode);
  final alerts = await ref.watch(fuelRepositoryProvider).trendAlerts();
  return alerts.where((a) => a.topic == topic).toList();
});

/// Notifiche della schermata Notifiche: le tendenze del backend più le
/// notifiche push ricevute mentre l'app è aperta.
/// Quali notifiche sono state lette si salva sul dispositivo.
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    ref.listen(trendAlertsProvider, (_, next) {
      final alerts = next.value;
      if (alerts != null) _merge(alerts.map((a) => a.toNotification()));
    });
    return const [];
  }

  /// Id delle ultime notifiche lette da ricordare.
  static const _maxRead = 300;

  Set<String> get _readIds => {
    ...?ref.read(localStoreProvider).getStringList(StoreKeys.readNotifications),
  };

  void _saveRead(Iterable<String> ids) {
    final all = [..._readIds.where((id) => !ids.contains(id)), ...ids];
    ref
        .read(localStoreProvider)
        .setStringList(
          StoreKeys.readNotifications,
          all.skip(all.length > _maxRead ? all.length - _maxRead : 0).toList(),
        );
  }

  AppNotification _withSavedRead(AppNotification n, Set<String> readIds) =>
      !n.read && readIds.contains(n.id) ? n.copyWith(read: true) : n;

  /// Aggiunge le notifiche nuove e ordina dalla più recente.
  void _merge(Iterable<AppNotification> incoming) {
    final known = {for (final n in state) n.id};
    final readIds = _readIds;
    final added = incoming
        .where((n) => !known.contains(n.id))
        .map((n) => _withSavedRead(n, readIds))
        .toList();
    if (added.isEmpty) return;
    state = [...state, ...added]..sort((a, b) => b.time.compareTo(a.time));
  }

  /// Aggiunge in cima una notifica ricevuta (es. push). Ignora i doppioni.
  void add(AppNotification notification) {
    if (state.any((n) => n.id == notification.id)) return;
    state = [_withSavedRead(notification, _readIds), ...state];
    if (notification.read) _saveRead([notification.id]);
  }

  void markRead(String id) {
    state = [for (final n in state) n.id == id ? n.copyWith(read: true) : n];
    _saveRead([id]);
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(read: true)];
    _saveRead(state.map((n) => n.id));
  }
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

/// Versione del backend (Impostazioni → Server); `null` con i dati di prova.
final serverVersionProvider = FutureProvider<String?>(
  (ref) => ref.watch(fuelRepositoryProvider).serverVersion(),
);
