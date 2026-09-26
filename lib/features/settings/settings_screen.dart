import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/directions.dart';
import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/benzina_logo.dart';
import '../../core/widgets/common.dart';
import '../../data/models.dart';
import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final info = ref.watch(packageInfoProvider).value;
    final version = info == null
        ? '…'
        : '${info.version} (build ${info.buildNumber})';
    final updated = ref
        .watch(nearbyOffersProvider)
        .value
        ?.firstOrNull
        ?.station
        .updatedAt;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(
            'Impostazioni',
            style: displayStyle(
              fontSize: 30,
              letterSpacing: -0.5,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 8),
          const SectionLabel('Preferenze'),
          _Group(
            children: [
              _Row(
                title: 'Carburante predefinito',
                value: s.fuel.hasServiceModes
                    ? '${s.fuel.label} · ${s.mode.label}'
                    : s.fuel.label,
                onTap: () async {
                  final choice = await _pick<(FuelType, ServiceMode)>(
                    context,
                    'Carburante predefinito',
                    [
                      for (final f in FuelType.values)
                        if (f.hasServiceModes)
                          for (final m in ServiceMode.values)
                            ((f, m), '${f.label} · ${m.label}')
                        else
                          ((f, ServiceMode.self), f.label),
                    ],
                  );
                  if (choice != null) {
                    notifier.update(
                      (s) => s.copyWith(fuel: choice.$1, mode: choice.$2),
                    );
                  }
                },
              ),
              _Row(
                title: 'Raggio di ricerca',
                value: formatKm(s.radiusKm).replaceAll(',0', ''),
                onTap: () async {
                  final r = await _pick<double>(context, 'Raggio di ricerca', [
                    for (final r in radiusOptions)
                      (r, formatKm(r).replaceAll(',0', '')),
                  ]);
                  if (r != null) {
                    notifier.update((s) => s.copyWith(radiusKm: r));
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Tema', style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        selectedBackgroundColor: c.amber,
                        selectedForegroundColor: c.onAmber,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Chiaro'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Scuro'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Auto'),
                        ),
                      ],
                      selected: {s.themeMode},
                      onSelectionChanged: (v) => notifier.update(
                        (s) => s.copyWith(themeMode: v.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SectionLabel('Notifiche'),
          _Group(
            children: [
              _SwitchRow(
                title: 'Avviso prezzo sotto soglia',
                subtitle:
                    '${s.fuel.label} ${s.fuel.hasServiceModes ? '${s.mode.label.toLowerCase()} ' : ''}'
                    'sotto ${formatPrice(s.threshold)} €/l',
                value: s.thresholdAlert,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(thresholdAlert: v)),
              ),
              _SwitchRow(
                title: 'Variazioni dei preferiti',
                subtitle: 'Quando un preferito cambia prezzo',
                value: s.favoriteAlerts,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(favoriteAlerts: v)),
              ),
              _SwitchRow(
                title: 'Riepilogo settimanale',
                subtitle: 'Ogni lunedì mattina',
                value: s.weeklySummary,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(weeklySummary: v)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SectionLabel('Informazioni'),
          _Group(
            children: [
              _Row(title: 'Versione', value: version, bold: true),
              // TODO: schermata "Novità" con il changelog.
              _Row(
                title: 'Dati aggiornati',
                value: updated == null ? '—' : formatUpdated(updated),
              ),
              _Row(
                title: 'Fonti dei dati',
                value: 'MIMIT, Google',
                onTap: () => openExternal(
                  context,
                  Uri.https(
                    'www.mimit.gov.it',
                    '/it/open-data/elenco-dataset/carburanti-prezzi-praticati-e-anagrafica-degli-impianti',
                  ),
                ),
              ),
              _Row(
                title: 'Licenze open source',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Benzina',
                  applicationVersion: version,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: BenzinaLogo(
                      size: 48,
                      background: c.amber,
                      foreground: c.onAmber,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              BenzinaLogo(size: 48, background: c.amber, foreground: c.onAmber),
              const SizedBox(height: 6),
              Text('Benzina', style: displayStyle(fontSize: 17, color: c.ink)),
              Text(
                'Versione ${info?.version ?? '…'} · © ${DateTime.now().year}',
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<T?> _pick<T>(
    BuildContext context,
    String title,
    List<(T, String)> options,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final (value, label) in options)
              ListTile(
                title: Text(label),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.value, this.onTap, this.bold = false});

  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold ? c.ink : c.muted,
                ),
              ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: context.colors.muted),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
