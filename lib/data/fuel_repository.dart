import 'package:latlong2/latlong.dart';

import 'models.dart';

/// Accesso ai dati su prezzi e distributori. Due implementazioni: i dati
/// di prova ([MockFuelRepository]) e il backend ([ApiFuelRepository]).
abstract interface class FuelRepository {
  /// Distributori entro [radiusKm] da [center] che vendono [fuel],
  /// ordinati dal più economico.
  Future<List<StationOffer>> offersNear({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
  });

  Future<Station?> station(String id);

  Future<List<Station>> stationsById(Iterable<String> ids);

  /// Media nazionale giornaliera degli ultimi [days] giorni, oggi incluso.
  Future<List<PricePoint>> nationalTrend({
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  });

  /// Media giornaliera dei distributori nel raggio di ricerca.
  Future<List<PricePoint>> areaTrend({
    required LatLng center,
    required double radiusKm,
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  });

  Future<List<PricePoint>> stationTrend({
    required String stationId,
    required FuelType fuel,
    required ServiceMode mode,
    required int days,
  });

  /// Valutazione Google del distributore, `null` se non abbinato.
  Future<GoogleRating?> googleRating(String stationId);

  /// Tendenze della media nazionale degli ultimi [days] giorni, dalla più
  /// recente (tutti i carburanti).
  Future<List<TrendAlert>> trendAlerts({int days = 30});

  /// Versione del backend e giorno dell'ultimo import.
  Future<ServerInfo> serverInfo();
}
