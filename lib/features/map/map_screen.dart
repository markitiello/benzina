import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/directions.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/data_source.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../nearby/filter_bar.dart';

/// Sotto questa differenza dalla media un prezzo è "in media".
const _neutralBand = 0.010;

// TODO: se sulla mappa si mostrano dati Google (es. le stelle), i termini di
// Google richiedono Google Maps: passare a google_maps_flutter.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  String? _selectedId;

  /// Distributore richiesto prima che la mappa fosse aperta la prima volta:
  /// la mappa parte già centrata lì.
  LatLng? _initialFocus;

  @override
  void initState() {
    super.initState();
    _initialFocus = _takeFocus(ref.read(mapFocusProvider), move: false);
  }

  /// Seleziona il distributore [id] (se è tra i risultati) e ne restituisce
  /// la posizione; con [move] sposta subito la mappa.
  LatLng? _takeFocus(String? id, {required bool move}) {
    if (id == null) return null;
    final offers = ref.read(nearbyOffersProvider).value ?? const [];
    final offer = offers.where((o) => o.station.id == id).firstOrNull;
    Future.microtask(() => ref.read(mapFocusProvider.notifier).clear());
    if (offer == null) return null;
    _selectedId = id;
    final position = offer.station.position;
    if (move) _map.move(position, 15);
    return position;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = ref.watch(locationProvider).value;
    final offers =
        ref.watch(nearbyOffersProvider).value ?? const <StationOffer>[];
    final average = ref.watch(nationalAverageProvider).value;
    final radiusKm = ref.watch(settingsProvider.select((s) => s.radiusKm));
    ref.listen(mapFocusProvider, (_, id) {
      if (id != null) setState(() => _takeFocus(id, move: true));
    });

    StationOffer? selected;
    for (final o in offers) {
      if (o.station.id == _selectedId) selected = o;
    }
    selected ??= offers.isEmpty ? null : offers.first;

    return Scaffold(
      body: Stack(
        children: [
          if (location != null)
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _initialFocus ?? location.position,
                initialZoom: _initialFocus != null
                    ? 15
                    : (radiusKm <= 2 ? 14 : 13),
                backgroundColor: c.ground,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'it.markitiello.benzina',
                  tileBuilder: isDark ? darkModeTileBuilder : null,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: location.position,
                      radius: radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: c.cheapFill.withValues(alpha: 0.07),
                      borderColor: c.cheapFill,
                      borderStrokeWidth: 1.5,
                    ),
                    CircleMarker(
                      point: location.position,
                      radius: 8,
                      color: c.cheapFill,
                      borderColor: c.ground,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (final o in offers.reversed)
                      Marker(
                        point: o.station.position,
                        width: 72,
                        height: 34,
                        child: _PricePin(
                          offer: o,
                          average: average,
                          isCheapest: o == offers.first,
                          isSelected: o == selected,
                          onTap: () =>
                              setState(() => _selectedId = o.station.id),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                    TextSourceAttribution(
                      'Prezzi: MIMIT (mimit.gov.it)',
                      onTap: () => openExternal(context, mimitDatasetUrl),
                    ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FilterBar(elevated: true),
                  const SizedBox(height: 10),
                  _Legend(),
                ],
              ),
            ),
          ),
          if (location != null)
            Positioned(
              right: 16,
              bottom: (selected != null ? 170 : 16),
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                tooltip: 'Centra sulla mia posizione',
                backgroundColor: c.surface,
                foregroundColor: c.cheap,
                onPressed: () => _map.move(location.position, 13),
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          if (selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _SelectedStationSheet(offer: selected, average: average),
            ),
        ],
      ),
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({
    required this.offer,
    required this.average,
    required this.isCheapest,
    required this.isSelected,
    required this.onTap,
  });

  final StationOffer offer;
  final double? average;
  final bool isCheapest;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg = Colors.white;
    Border? border;
    if (isCheapest) {
      bg = isDark ? c.amber : c.ink;
      fg = isDark ? c.onAmber : Colors.white;
      if (!isDark) border = Border.all(color: c.amber, width: 3);
    } else if (average == null ||
        (offer.price - average!).abs() < _neutralBand) {
      bg = c.neutralPinBg;
      fg = c.neutralPinFg;
      border = Border.all(color: c.line);
    } else if (offer.price < average!) {
      bg = c.cheapFill;
    } else {
      bg = c.priceyFill;
    }
    return Semantics(
      button: true,
      label: '${offer.station.name}, ${formatPrice(offer.price)} euro al litro',
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.12 : 1,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: border,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                formatPrice(offer.price),
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget dot(Color color, String label, {bool outlined = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: outlined ? Border.all(color: c.muted) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c.ink)),
      ],
    );
    return Material(
      color: c.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(c.cheapFill, 'Sotto media'),
            const SizedBox(width: 10),
            dot(c.neutralPinBg, 'In media', outlined: true),
            const SizedBox(width: 10),
            dot(c.priceyFill, 'Sopra'),
          ],
        ),
      ),
    );
  }
}

class _SelectedStationSheet extends ConsumerWidget {
  const _SelectedStationSheet({required this.offer, required this.average});

  final StationOffer offer;
  final double? average;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = offer.station;
    return Material(
      color: c.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: displayStyle(fontSize: 20, color: c.ink)),
            Text(
              [formatKm(offer.distanceKm), ?s.openingHours].join(' · '),
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Su schermi stretti (o con testo grande) il prezzo si riduce
                // invece di spingere fuori i pulsanti.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          formatPrice(offer.price),
                          style: displayStyle(fontSize: 32, color: c.ink),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          priceUnit(ref.watch(settingsProvider).fuel),
                          style: TextStyle(fontSize: 14, color: c.muted),
                        ),
                        const SizedBox(width: 10),
                        if (average != null)
                          DeltaChip(
                            text: formatPriceDelta(offer.price - average!),
                            cheaper: offer.price <= average!,
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Naviga',
                  onPressed: () => openDirections(context, s.position),
                  icon: Icon(Icons.navigation_rounded, color: c.ink),
                ),
                FilledButton(
                  onPressed: () => context.push('/distributore/${s.id}'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: const Text('Dettagli'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
