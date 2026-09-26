import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/directions.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/price_chart.dart';
import '../../data/models.dart';
import '../../state/providers.dart';

class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(stationProvider(stationId));
    final isFavorite = ref.watch(favoritesProvider).contains(stationId);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: isFavorite
                ? 'Rimuovi dai preferiti'
                : 'Aggiungi ai preferiti',
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(stationId),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncBody(
        value: station,
        onRetry: () => ref.invalidate(stationProvider(stationId)),
        builder: (s) => s == null
            ? const Center(child: Text('Distributore non trovato.'))
            : _Body(station: s),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text(
          station.brand,
          style: displayStyle(fontSize: 28, letterSpacing: -0.4, color: c.ink),
        ),
        Text(
          '${station.address}, ${station.city}',
          style: TextStyle(fontSize: 15, color: c.muted),
        ),
        if (station.openingHours != null)
          Text(
            'Aperto ${station.openingHours}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.cheap,
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => openDirections(context, station.position),
          icon: const Icon(Icons.navigation_rounded, size: 20),
          label: const Text('Naviga'),
        ),
        const SizedBox(height: 16),
        _PriceTable(station: station),
        const SizedBox(height: 16),
        _StationTrend(station: station),
        const SizedBox(height: 16),
        _Reviews(stationId: station.id),
      ],
    );
  }
}

class _PriceTable extends ConsumerWidget {
  const _PriceTable({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final fuels = FuelType.values.where(
      (f) => station.priceFor(f, ServiceMode.self) != null,
    );

    TextStyle cell({bool bold = false, Color? color}) => TextStyle(
      fontSize: 15,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Carburante',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Self',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Servito',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ),
              ],
            ),
          ),
          for (final f in fuels) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      f.label,
                      style: cell().copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatPrice(station.priceFor(f, ServiceMode.self)!),
                      textAlign: TextAlign.end,
                      style: cell(
                        bold: true,
                        color: f == s.fuel ? c.cheap : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.hasServiceModes
                          ? formatPrice(
                              station.priceFor(f, ServiceMode.servito) ?? 0,
                            )
                          : '—',
                      textAlign: TextAlign.end,
                      style: cell(color: f.hasServiceModes ? null : c.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fonte: MIMIT · Osservaprezzi Carburanti · agg. ${formatUpdated(station.updatedAt)}',
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationTrend extends ConsumerWidget {
  const _StationTrend({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final fuel = station.priceFor(s.fuel, s.effectiveMode) != null
        ? s.fuel
        : FuelType.benzina;
    final mode = fuel.hasServiceModes ? s.mode : ServiceMode.self;
    final trend = ref.watch(
      stationTrendProvider((id: station.id, fuel: fuel, mode: mode)),
    );
    final national = ref.watch(
      nationalTrendProvider((fuel: fuel, mode: mode, days: 30)),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prezzo ${fuel.label.toLowerCase()} qui',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'ultimi 30 giorni',
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AsyncBody(
            value: trend,
            builder: (points) => PriceChart(
              height: 120,
              series: [
                ChartSeries(points: points, color: c.cheap),
                if (national.value case final n?)
                  ChartSeries(points: n, color: c.muted, dashed: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ChartLegend(
            items: [
              ('Questo distributore', c.cheap, false),
              ('Media nazionale', c.muted, true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final rating = ref.watch(googleRatingProvider(stationId));

    return AppCard(
      child: AsyncBody(
        value: rating,
        builder: (r) {
          if (r == null) {
            return const Text(
              'Nessuna recensione disponibile per questo distributore.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recensioni',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'da Google Maps',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    formatRating(r.rating),
                    style: displayStyle(fontSize: 44, height: 1, color: c.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarRow(rating: r.rating),
                        const SizedBox(height: 4),
                        Text(
                          '${r.count} recensioni',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              for (final review in r.reviews) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _ReviewTile(review: review),
              ],
              if (r.mapsUrl case final url?) ...[
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => openExternal(context, url),
                  child: const Text('Leggi tutte su Google Maps'),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                r.attribution,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: c.cheapChipBg,
              foregroundColor: c.cheapChipFg,
              child: Text(
                review.author.characters.first,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: review.authorUrl == null
                        ? null
                        : () => openExternal(context, review.authorUrl!),
                    child: Text(
                      review.author,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      StarRow(rating: review.rating.toDouble(), size: 13),
                      Text(
                        ' · ${review.relativeTime}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          review.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 1.45),
        ),
      ],
    );
  }
}
