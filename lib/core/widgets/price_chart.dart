import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../format.dart';
import '../theme/app_colors.dart';

class ChartSeries {
  const ChartSeries({
    required this.points,
    required this.color,
    this.dashed = false,
    this.area = false,
  });

  final List<PricePoint> points;
  final Color color;
  final bool dashed;
  final bool area;
}

/// Grafico a linee dei prezzi: asse x in giorni, asse y in €/l.
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.series,
    this.height = 190,
    this.showAxes = true,
  });

  final List<ChartSeries> series;
  final double height;
  final bool showAxes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = [for (final s in series) ...s.points];
    if (all.isEmpty) return SizedBox(height: height);

    var minY = all.map((p) => p.price).reduce(math.min);
    var maxY = all.map((p) => p.price).reduce(math.max);
    final pad = math.max((maxY - minY) * 0.15, 0.005);
    minY -= pad;
    maxY += pad;
    final first = series.first.points;
    final lastX = (first.length - 1).toDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: lastX,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: showAxes,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => c.ink,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    s.spotIndex < first.length && s.barIndex == 0
                        ? '${formatShortDate(first[s.spotIndex].day)}\n${formatPrice(s.y)}'
                        : formatPrice(s.y),
                    TextStyle(
                      color: c.ground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          gridData: FlGridData(
            show: showAxes,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: c.lineSoft, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: showAxes,
            topTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) => v == meta.max || v == meta.min
                    ? const SizedBox.shrink()
                    : Text(
                        formatPrice(v).substring(0, 4),
                        style: TextStyle(fontSize: 10, color: c.muted),
                      ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: math.max(1, lastX / 2),
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= first.length) {
                    return const SizedBox.shrink();
                  }
                  final label = i == first.length - 1
                      ? 'oggi'
                      : formatShortDate(first[i].day);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 10, color: c.muted),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final s in series)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < s.points.length; i++)
                    FlSpot(i.toDouble(), s.points[i].price),
                ],
                color: s.color,
                barWidth: s.dashed ? 1.5 : 2.5,
                dashArray: s.dashed ? [4, 4] : null,
                isCurved: false,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, bar) =>
                      !s.dashed && spot.x == bar.spots.last.x,
                  getDotPainter: (a, b, c_, d) => FlDotCirclePainter(
                    radius: 4,
                    color: s.color,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: s.area,
                  color: s.color.withValues(alpha: 0.06),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  final List<(String, Color, bool dashed)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (label, color, dashed) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: dashed ? 2 : 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
            ],
          ),
      ],
    );
  }
}
