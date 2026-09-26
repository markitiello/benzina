import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../state/providers.dart';
import '../nearby/nearby_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stations = ref.watch(favoriteStationsProvider);
    final s = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Preferiti',
              style: displayStyle(
                fontSize: 30,
                letterSpacing: -0.5,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 16),
            AsyncBody(
              value: stations,
              onRetry: () => ref.invalidate(favoriteStationsProvider),
              builder: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 48,
                            color: c.muted,
                          ),
                          const SizedBox(height: 12),
                          const Text('Nessun preferito.'),
                          Text(
                            'Tocca il cuore nel dettaglio di un distributore per salvarlo qui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.muted),
                          ),
                        ],
                      ),
                    )
                  : AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < list.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            StationTile(
                              station: list[i],
                              subtitle:
                                  'Agg. ${formatUpdated(list[i].updatedAt)}',
                              price: list[i].priceFor(s.fuel, s.effectiveMode),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
