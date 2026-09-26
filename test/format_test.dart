import 'package:benzina/core/format.dart';
import 'package:benzina/data/models.dart';
import 'package:benzina/features/trends/trends_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i prezzi usano la virgola e tre decimali', () {
    expect(formatPrice(1.739), '1,739');
    expect(formatPrice(0.7), '0,700');
  });

  test('le differenze hanno il segno', () {
    expect(formatPriceDelta(-0.08), '−0,080');
    expect(formatPriceDelta(0.02), '+0,020');
    expect(formatPercentDelta(0.006), '+0,6%');
  });

  test('data di aggiornamento relativa', () {
    final now = DateTime(2026, 9, 26, 10);
    expect(formatUpdated(DateTime(2026, 9, 26, 8), now: now), 'oggi 08:00');
    expect(formatUpdated(DateTime(2026, 9, 25, 8), now: now), 'ieri 08:00');
    expect(formatUpdated(DateTime(2026, 8, 26, 8), now: now), '26 ago');
  });

  test('conta i giorni consecutivi di calo o aumento', () {
    List<PricePoint> series(List<double> prices) => [
      for (var i = 0; i < prices.length; i++)
        PricePoint(DateTime(2026, 9, i + 1), prices[i]),
    ];
    expect(streakDays(series([1.9, 1.8, 1.85, 1.84, 1.83])), 2);
    expect(streakDays(series([1.8, 1.81, 1.82])), -2);
    expect(streakDays(series([1.8, 1.8])), 0);
  });
}
