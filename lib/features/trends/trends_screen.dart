import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/price_chart.dart';
import '../../data/models.dart';
import '../../state/providers.dart';

const _periods = [(7, '7 g'), (30, '30 g'), (182, '6 mesi'), (365, '1 anno')];

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  late FuelType _fuel = ref.read(settingsProvider).fuel;
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mode = ref.watch(settingsProvider.select((s) => s.mode));
    final radius = ref.watch(settingsProvider.select((s) => s.radiusKm));
    final key = (fuel: _fuel, mode: mode, days: _days);
    final national = ref.watch(nationalTrendProvider(key));
    final area = ref.watch(areaTrendProvider(key));
    // Per "un anno fa" serve sempre la serie annuale.
    final yearly = ref.watch(
      nationalTrendProvider((fuel: _fuel, mode: mode, days: 365)),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Andamento prezzi',
              style: displayStyle(
                fontSize: 30,
                letterSpacing: -0.5,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedTabs<FuelType>(
              values: FuelType.values,
              selected: _fuel,
              labelOf: (f) => f.label,
              onChanged: (f) => setState(() => _fuel = f),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: AsyncBody(
                value: national,
                loadingHeight: 300,
                builder: (points) {
                  if (points.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Ancora nessun dato per ${_fuel.label.toLowerCase()} in questo periodo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.muted),
                      ),
                    );
                  }
                  final areaPoints = area.value ?? const <PricePoint>[];
                  final today = points.last.price;
                  final change = today / points.first.price - 1;
                  final label = _periods.firstWhere((p) => p.$1 == _days).$2;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Media nazionale${_fuel.hasServiceModes ? ' ${mode.label.toLowerCase()}' : ''} · oggi',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                      Text(
                        '${formatPrice(today)} ${priceUnit(_fuel)}',
                        style: displayStyle(
                          fontSize: 36,
                          height: 1.1,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        '${change <= 0 ? '▼' : '▲'} ${formatPercentDelta(change)} in $label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: change <= 0 ? c.cheap : c.pricey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ChartLegend(
                        items: [
                          ('Italia', c.ink, false),
                          // Con pochi distributori vicini (es. metano) la
                          // media della zona può mancare.
                          if (areaPoints.isNotEmpty)
                            (
                              'Entro ${formatKm(radius).replaceAll(',0', '')} da te',
                              c.cheap,
                              false,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PriceChart(
                        series: [
                          ChartSeries(points: points, color: c.ink, area: true),
                          if (areaPoints.isNotEmpty)
                            ChartSeries(points: areaPoints, color: c.cheap),
                        ],
                      ),
                      if (area.hasValue && areaPoints.isEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Nessun distributore di ${_fuel.label.toLowerCase()} entro '
                          '${formatKm(radius).replaceAll(',0', '')} da te per la media della zona.',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final (days, text) in _periods) ...[
                            if (days != _periods.first.$1)
                              const SizedBox(width: 6),
                            Expanded(
                              child: _PeriodChip(
                                text: text,
                                selected: days == _days,
                                onTap: () => setState(() => _days = days),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (national.value case final points? when points.isNotEmpty) ...[
              if (area.value case final a? when a.isNotEmpty) ...[
                _InsightCard(national: points, area: a),
                const SizedBox(height: 16),
              ],
              _Stats(
                points: points,
                yearAgo: yearly.value?.firstOrNull?.price,
                periodLabel: _periods.firstWhere((p) => p.$1 == _days).$2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.selectedChipBg : c.surface,
      shape: StadiumBorder(
        side: selected ? BorderSide.none : BorderSide(color: c.line),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.selectedChipFg : c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Numero di giorni consecutivi, fino a oggi, in cui il prezzo è sceso
/// (valore positivo) o salito (valore negativo).
int streakDays(List<PricePoint> points) {
  if (points.length < 2) return 0;
  final falling = points.last.price < points[points.length - 2].price;
  var days = 0;
  for (var i = points.length - 1; i > 0; i--) {
    final down = points[i].price < points[i - 1].price;
    final up = points[i].price > points[i - 1].price;
    if ((falling && down) || (!falling && up)) {
      days++;
    } else {
      break;
    }
  }
  return falling ? days : -days;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.national, required this.area});

  final List<PricePoint> national;
  final List<PricePoint> area;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = streakDays(national);
    final gap = area.last.price - national.last.price;
    final falling = streak > 0;
    final title = streak == 0
        ? 'Prezzi stabili'
        : falling
        ? 'Prezzi in calo da ${streak == 1 ? '1 giorno' : '$streak giorni'}'
        : 'Prezzi in aumento da ${-streak == 1 ? '1 giorno' : '${-streak} giorni'}';
    final body = gap <= 0
        ? 'Nella tua zona paghi in media ${formatPrice(gap.abs())} €/l meno della media nazionale.'
        : 'Nella tua zona paghi in media ${formatPrice(gap)} €/l più della media nazionale.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cheapChipBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF2A3A66)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: c.cheapFill,
            foregroundColor: Colors.white,
            child: Icon(
              falling ? Icons.south_rounded : Icons.north_rounded,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.cheapChipFg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, color: c.cheapChipFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.points,
    required this.yearAgo,
    required this.periodLabel,
  });

  final List<PricePoint> points;
  final double? yearAgo;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final prices = points.map((p) => p.price);
    Widget tile(String label, String value) => Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.colors.muted),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile('Minimo $periodLabel', formatPrice(prices.reduce(math.min))),
        const SizedBox(width: 8),
        tile('Massimo $periodLabel', formatPrice(prices.reduce(math.max))),
        const SizedBox(width: 8),
        tile('Un anno fa', yearAgo == null ? '—' : formatPrice(yearAgo!)),
      ],
    );
  }
}
