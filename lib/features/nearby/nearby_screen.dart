import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/directions.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/service_icons.dart';
import '../../core/widgets/price_chart.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import 'filter_bar.dart';

class NearbyScreen extends ConsumerWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final location = ref.watch(locationProvider);
    final offers = ref.watch(nearbyOffersProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(locationProvider);
            await ref.read(nearbyOffersProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 15,
                              color: c.muted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location.value?.label ??
                                    'Cerco la tua posizione…',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: c.muted),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Vicino a te',
                          style: displayStyle(
                            fontSize: 30,
                            letterSpacing: -0.5,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: unread > 0
                        ? 'Notifiche, $unread non lette'
                        : 'Notifiche',
                    badge: unread,
                    onPressed: () => context.push('/notifiche'),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Impostazioni',
                    onPressed: () => context.push('/impostazioni'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const FilterBar(),
              const SizedBox(height: 16),
              AsyncBody(
                value: offers,
                loadingHeight: 300,
                onRetry: () => ref.invalidate(nearbyOffersProvider),
                builder: (list) => list.isEmpty
                    ? const _EmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CheapestCard(offer: list.first),
                          const SizedBox(height: 16),
                          const _NationalAverageCard(),
                          const SizedBox(height: 20),
                          if (list.length > 1)
                            _OtherStations(offers: list.skip(1).toList()),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheapestCard extends ConsumerWidget {
  const _CheapestCard({required this.offer});

  final StationOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final average = ref.watch(nationalAverageProvider).value;
    final rating = ref.watch(googleRatingProvider(offer.station.id)).value;
    final minutes = (offer.distanceKm / 18 * 60).ceil(); // ~18 km/h in città

    return Material(
      color: c.heroBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: c.heroBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/distributore/${offer.station.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'IL PIÙ ECONOMICO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: c.amber,
                      ),
                    ),
                  ),
                  if (rating != null) ...[
                    Icon(Icons.star_rounded, size: 16, color: c.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${formatRating(rating.rating)} · ${rating.count} su Google',
                      style: TextStyle(fontSize: 13, color: c.heroMuted),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                offer.station.brand,
                style: displayStyle(fontSize: 22, color: c.heroFg),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${offer.station.address} · ${formatKm(offer.distanceKm)} · $minutes min',
                      style: TextStyle(fontSize: 14, color: c.heroMuted),
                    ),
                  ),
                  ServiceIcons(
                    services: offer.station.details?.services ?? const [],
                    color: c.heroMuted,
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Con testo grande (accessibilità) il prezzo si riduce
                  // invece di uscire dalla scheda.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatPrice(offer.price),
                            style: displayStyle(
                              fontSize: 52,
                              height: 1,
                              letterSpacing: -1,
                              color: c.heroFg,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '€/l',
                              style: TextStyle(
                                fontSize: 16,
                                color: c.heroMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (average != null)
                    DeltaChip(
                      text:
                          '${formatPriceDelta(offer.price - average)} vs media',
                      cheaper: offer.price <= average,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          openDirections(context, offer.station.position),
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: const Text('Naviga'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Agg. ${formatUpdated(offer.station.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: c.heroMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NationalAverageCard extends ConsumerWidget {
  const _NationalAverageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final trend = ref.watch(
      nationalTrendProvider((fuel: s.fuel, mode: s.effectiveMode, days: 7)),
    );

    return AppCard(
      onTap: () => StatefulNavigationShell.maybeOf(context)?.goBranch(2),
      child: AsyncBody(
        value: trend,
        loadingHeight: 70,
        builder: (points) {
          final today = points.last.price;
          final change = today / points.first.price - 1;
          final color = change <= 0 ? c.cheap : c.pricey;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media nazionale · ${s.fuel.label.toLowerCase()}'
                      '${s.fuel.hasServiceModes ? ' ${s.mode.label.toLowerCase()}' : ''}',
                      style: TextStyle(fontSize: 13, color: c.muted),
                    ),
                    Text(
                      '${formatPrice(today)} €/l',
                      style: displayStyle(fontSize: 24, color: c.ink),
                    ),
                    Text(
                      '${change <= 0 ? '▼' : '▲'} ${formatPercentDelta(change)} negli ultimi 7 giorni',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                child: PriceChart(
                  height: 44,
                  showAxes: false,
                  series: [ChartSeries(points: points, color: color)],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OtherStations extends StatelessWidget {
  const _OtherStations({required this.offers});

  final List<StationOffer> offers;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Altri distributori',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Ordinati per prezzo',
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
            ],
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < offers.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                StationTile(
                  station: offers[i].station,
                  subtitle: formatKm(offers[i].distanceKm),
                  price: offers[i].price,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Riga di un distributore: sigla, nome, sottotitolo e prezzo.
class StationTile extends StatelessWidget {
  const StationTile({
    super.key,
    required this.station,
    required this.subtitle,
    this.price,
    this.priceCaption,
  });

  final Station station;
  final String subtitle;
  final double? price;

  /// Sotto il prezzo, es. "€/l · Benzina self". Se c'è, al posto di un
  /// prezzo mancante compare "—".
  final String? priceCaption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => context.push('/distributore/${station.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? c.surfaceMuted
                    : c.ground,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                station.initials,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          style: TextStyle(fontSize: 13, color: c.muted),
                        ),
                      ),
                      ServiceIcons(
                        services: station.details?.services ?? const [],
                        color: c.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (price != null || priceCaption != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price == null ? '—' : formatPrice(price!),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (priceCaption != null)
                    Text(
                      priceCaption!,
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.local_gas_station_outlined,
            size: 48,
            color: context.colors.muted,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nessun distributore in questo raggio.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Prova ad aumentare la distanza o a cambiare carburante.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}
