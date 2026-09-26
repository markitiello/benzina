import 'package:intl/intl.dart';

final _price = NumberFormat('0.000', 'it_IT');
final _km = NumberFormat('0.0', 'it_IT');
final _rating = NumberFormat('0.0', 'it_IT');
final _percent = NumberFormat('0.0', 'it_IT');

/// 1.739 → "1,739"
String formatPrice(double value) => _price.format(value);

/// -0.08 → "−0,080", 0.02 → "+0,020"
String formatPriceDelta(double delta) {
  final sign = delta < 0 ? '−' : '+';
  return '$sign${_price.format(delta.abs())}';
}

/// 0.006 → "+0,6%"
String formatPercentDelta(double ratio) {
  final sign = ratio < 0 ? '−' : '+';
  return '$sign${_percent.format(ratio.abs() * 100)}%';
}

String formatKm(double km) => '${_km.format(km)} km';

String formatRating(double rating) => _rating.format(rating);

const _months = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

/// "26 ago"
String formatShortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

String formatTime(DateTime d) =>
    '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';

/// "oggi 08:00", "ieri 08:00" oppure "26 ago".
String formatUpdated(DateTime d, {DateTime? now}) {
  now ??= DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'oggi ${formatTime(d)}';
  if (diff == 1) return 'ieri ${formatTime(d)}';
  return formatShortDate(d);
}

const _weekdays = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];

/// Orario per le notifiche: "08:05" se di oggi, il giorno della settimana
/// se degli ultimi 7 giorni, altrimenti la data.
String formatNotificationTime(DateTime d, {DateTime? now}) {
  now ??= DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return formatTime(d);
  if (diff < 7) return _weekdays[d.weekday - 1];
  return formatShortDate(d);
}
