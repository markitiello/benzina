import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models.dart';
import '../../state/providers.dart';

/// Filtri carburante / self-servito / raggio, condivisi da lista e mappa.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key, this.elevated = false});

  /// Sulla mappa i filtri hanno un'ombra per staccarsi dallo sfondo.
  final bool elevated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MenuChip<FuelType>(
            label: s.fuel.label,
            selected: true,
            elevated: elevated,
            values: FuelType.values,
            labelOf: (f) => f.label,
            onSelected: (f) => notifier.update((s) => s.copyWith(fuel: f)),
          ),
          const SizedBox(width: 8),
          if (s.fuel.hasServiceModes) ...[
            _MenuChip<ServiceMode>(
              label: s.mode.label,
              elevated: elevated,
              values: ServiceMode.values,
              labelOf: (m) => m.label,
              onSelected: (m) => notifier.update((s) => s.copyWith(mode: m)),
            ),
            const SizedBox(width: 8),
          ],
          _MenuChip<double>(
            label: 'Entro ${formatKm(s.radiusKm).replaceAll(',0', '')}',
            elevated: elevated,
            values: radiusOptions,
            labelOf: (r) => formatKm(r).replaceAll(',0', ''),
            onSelected: (r) => notifier.update((s) => s.copyWith(radiusKm: r)),
          ),
        ],
      ),
    );
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.values,
    required this.labelOf,
    required this.onSelected,
    this.selected = false,
    this.elevated = false,
  });

  final String label;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool selected;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.selectedChipFg : c.ink;
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final v in values)
          PopupMenuItem(value: v, child: Text(labelOf(v))),
      ],
      child: Material(
        color: selected ? c.selectedChipBg : c.surface,
        elevation: elevated ? 2 : 0,
        shape: StadiumBorder(
          side: selected || elevated
              ? BorderSide.none
              : BorderSide(color: c.line),
        ),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 18, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
