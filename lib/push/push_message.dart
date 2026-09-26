import '../data/models.dart';

/// Una notifica push ricevuta, indipendente da Firebase.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    this.id,
  });

  final String? id;
  final String title;
  final String body;

  /// Il campo `data` inviato dal backend, es.
  /// `{type: trend, fuel: benzina, mode: self, direction: down, day: 2026-09-23}`.
  final Map<String, String> data;
  final DateTime receivedAt;

  bool get isTrend => data['type'] == 'trend';

  /// Schermata da aprire toccando la notifica.
  String get route => isTrend ? '/andamento' : '/notifiche';

  AppNotification toNotification({bool read = false}) {
    final kind = isTrend
        ? (data['direction'] == 'up'
              ? NotificationKind.trendUp
              : NotificationKind.trendDown)
        : NotificationKind.appUpdate;
    // Un id stabile evita doppioni se la stessa notifica arriva sia come
    // messaggio in primo piano sia come tocco sulla notifica di sistema.
    final stableId = isTrend
        ? 'trend-${data['fuel']}-${data['mode']}-${data['day']}'
        : id ?? 'push-${receivedAt.millisecondsSinceEpoch}';
    return AppNotification(
      id: stableId,
      kind: kind,
      title: title,
      body: body,
      time: receivedAt,
      read: read,
    );
  }
}
