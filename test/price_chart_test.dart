import 'package:benzina/core/theme/app_theme.dart';
import 'package:benzina/core/widgets/price_chart.dart';
import 'package:benzina/data/models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<LineChartData> chart(
    WidgetTester tester,
    List<List<PricePoint>> series,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: PriceChart(
            series: [
              for (final points in series)
                ChartSeries(points: points, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
    return tester.widget<LineChart>(find.byType(LineChart)).data;
  }

  PricePoint p(int month, int day, double price) =>
      PricePoint(DateTime(2026, month, day), price);

  testWidgets('un periodo senza dati interrompe la linea', (tester) async {
    final data = await chart(tester, [
      [p(6, 29, 1.80), p(6, 30, 1.81), p(9, 26, 1.75), p(9, 27, 1.76)],
    ]);
    final spots = data.lineBarsData.single.spots;
    expect(spots.map((s) => s.isNull() ? null : s.x), [0, 1, null, 89, 90]);
    expect(data.maxX, 90);
  });

  testWidgets('le serie si allineano per data, non per posizione', (
    tester,
  ) async {
    final data = await chart(tester, [
      [p(9, 25, 1.80), p(9, 26, 1.81), p(9, 27, 1.82)],
      // La zona non ha il 25.
      [p(9, 26, 1.70), p(9, 27, 1.71)],
    ]);
    expect(data.lineBarsData[1].spots.map((s) => s.x), [1, 2]);
  });
}
