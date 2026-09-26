import 'package:latlong2/latlong.dart';

enum FuelType {
  benzina('Benzina'),
  diesel('Diesel'),
  gpl('GPL'),
  metano('Metano');

  const FuelType(this.label);
  final String label;

  /// GPL e metano non hanno la distinzione self/servito.
  bool get hasServiceModes => this == benzina || this == diesel;
}

enum ServiceMode {
  self('Self'),
  servito('Servito');

  const ServiceMode(this.label);
  final String label;
}

class FuelPrice {
  const FuelPrice(this.fuel, this.mode, this.price);

  final FuelType fuel;
  final ServiceMode mode;

  /// €/l (€/kg per il metano).
  final double price;
}

/// Un distributore dell'anagrafica MIMIT.
class Station {
  const Station({
    required this.id,
    required this.brand,
    required this.address,
    required this.city,
    required this.position,
    required this.prices,
    required this.updatedAt,
    this.openingHours,
  });

  final String id;
  final String brand;
  final String address;
  final String city;
  final LatLng position;
  final List<FuelPrice> prices;
  final DateTime updatedAt;
  final String? openingHours;

  String get name => '$brand · $address';

  /// Sigla mostrata nel riquadro accanto al nome.
  String get initials {
    final letters = brand.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return letters
        .substring(0, letters.length < 3 ? letters.length : 3)
        .toUpperCase();
  }

  double? priceFor(FuelType fuel, ServiceMode mode) {
    final mode_ = fuel.hasServiceModes ? mode : ServiceMode.self;
    for (final p in prices) {
      if (p.fuel == fuel && p.mode == mode_) return p.price;
    }
    return null;
  }
}

/// Un distributore nel raggio di ricerca con il prezzo del carburante scelto.
class StationOffer {
  const StationOffer({
    required this.station,
    required this.price,
    required this.distanceKm,
  });

  final Station station;
  final double price;
  final double distanceKm;
}

class PricePoint {
  const PricePoint(this.day, this.price);

  final DateTime day;
  final double price;
}

class Review {
  const Review({
    required this.author,
    required this.rating,
    required this.relativeTime,
    required this.text,
    this.authorUrl,
  });

  final String author;

  /// Profilo Google dell'autore: Google chiede di mostrarlo con il nome.
  final Uri? authorUrl;
  final int rating;
  final String relativeTime;
  final String text;
}

/// Valutazione e recensioni da Google Places. Non va salvata in modo
/// permanente (termini d'uso di Google): si chiede ogni volta al backend.
class GoogleRating {
  const GoogleRating({
    required this.rating,
    required this.count,
    required this.reviews,
    required this.mapsUrl,
    this.attribution = 'Valutazioni e recensioni fornite da Google',
  });

  final double rating;
  final int count;

  /// Al massimo 5, scelte da Google.
  final List<Review> reviews;
  final Uri? mapsUrl;

  /// Testo di attribuzione da mostrare (termini d'uso di Google).
  final String attribution;
}

enum NotificationKind {
  priceBelowThreshold,
  favoriteDrop,
  // Media nazionale in aumento / in calo (notifiche push dal backend).
  trendUp,
  trendDown,
  weeklySummary,
  appUpdate,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.stationId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final String? stationId;

  bool get isPriceAlert =>
      kind == NotificationKind.priceBelowThreshold ||
      kind == NotificationKind.favoriteDrop ||
      kind == NotificationKind.trendUp ||
      kind == NotificationKind.trendDown;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    time: time,
    read: read ?? this.read,
    stationId: stationId,
  );
}
