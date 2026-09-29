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

/// Orario di un giorno: [day] da 1 (lunedì) a 7 (domenica), 8 i festivi.
class OpeningHours {
  const OpeningHours(this.day, this.hours);

  final int day;

  /// "07:00–18:30", "08:00–12:30, 15:00–19:00", "24 ore" o "Chiuso".
  final String hours;

  static const dayNames = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
    'Festivi',
  ];

  String get dayName => day >= 1 && day <= 8 ? dayNames[day - 1] : '';
}

/// Orari, servizi e contatti comunicati dal gestore (da Osservaprezzi).
class StationDetails {
  const StationDetails({
    this.phone,
    this.email,
    this.website,
    this.services = const [],
    this.openingHours = const [],
  });

  final String? phone;
  final String? email;
  final String? website;

  /// Come li indica il gestore, es. "Bancomat", "Food&Beverage", "Wi-Fi".
  final List<String> services;
  final List<OpeningHours> openingHours;

  bool get hasContacts => phone != null || email != null || website != null;

  /// Orario del giorno [date] (i festivi non si riconoscono: vale il giorno
  /// della settimana).
  String? hoursOn(DateTime date) {
    for (final h in openingHours) {
      if (h.day == date.weekday) return h.hours;
    }
    return null;
  }
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
    this.details,
  });

  final String id;
  final String brand;
  final String address;
  final String city;
  final LatLng position;
  final List<FuelPrice> prices;
  final DateTime updatedAt;

  /// Orario di oggi, es. "07:00–18:30" o "Chiuso".
  final String? openingHours;
  final StationDetails? details;

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
    this.attribution = 'Valutazioni fornite da Google',
  });

  final double rating;
  final int count;

  /// Per ora sempre vuota: il backend chiede a Google solo le stelle (le
  /// recensioni costano di più). Il testo si legge su Google Maps.
  final List<Review> reviews;
  final Uri? mapsUrl;

  /// Testo di attribuzione da mostrare (termini d'uso di Google).
  final String attribution;
}

/// Tendenza della media nazionale rilevata dal backend: la stessa inviata
/// come notifica push al topic [topic].
class TrendAlert {
  const TrendAlert({
    required this.fuel,
    required this.mode,
    required this.day,
    required this.rising,
    required this.title,
    required this.body,
    required this.topic,
    this.sentAt,
  });

  final FuelType fuel;

  /// `self`, `servito` o `any` (GPL e metano), come nel backend.
  final String mode;
  final DateTime day;
  final bool rising;
  final String title;
  final String body;
  final String topic;

  /// Quando è partita la notifica push; `null` se non ancora inviata.
  final DateTime? sentAt;

  /// Stesso id della notifica push corrispondente (vedi PushMessage), così
  /// la stessa tendenza non compare due volte.
  String get notificationId =>
      'trend-${fuel.name}-$mode-${day.year}-${_two(day.month)}-${_two(day.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  AppNotification toNotification() => AppNotification(
    id: notificationId,
    kind: rising ? NotificationKind.trendUp : NotificationKind.trendDown,
    title: title,
    body: body,
    time: sentAt ?? day,
  );
}

enum NotificationKind {
  // Media nazionale in aumento / in calo (notifiche push dal backend).
  trendUp,
  trendDown,
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
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  bool get isPriceAlert =>
      kind == NotificationKind.trendUp || kind == NotificationKind.trendDown;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    time: time,
    read: read ?? this.read,
  );
}
