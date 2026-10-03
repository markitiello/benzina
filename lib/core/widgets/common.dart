import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/benzina_api.dart';
import '../app_check_status.dart';
import '../theme/app_colors.dart';

/// Scheda bianca (o grigio scuro) con bordo sottile.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Intestazione di sezione in maiuscoletto ("OGGI", "PREFERENZE").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: context.colors.muted,
        ),
      ),
    );
  }
}

/// Pulsante rotondo da 44 px con icona, con un contatore opzionale.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = Material(
      color: c.surface,
      shape: CircleBorder(side: BorderSide(color: c.line)),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 22, color: c.ink),
        onPressed: onPressed,
      ),
    );
    if (badge == 0) return button;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Badge(
      label: Text('$badge'),
      backgroundColor: isDark ? c.amber : c.priceyFill,
      textColor: isDark ? c.onAmber : Colors.white,
      offset: const Offset(-2, 2),
      child: button,
    );
  }
}

/// Etichetta "−0,080 vs media" colorata in base al segno.
class DeltaChip extends StatelessWidget {
  const DeltaChip({super.key, required this.text, required this.cheaper});

  final String text;
  final bool cheaper;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cheaper ? c.cheapChipBg : c.priceyFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cheaper ? c.cheapChipFg : Colors.white,
        ),
      ),
    );
  }
}

/// Selettore a segmenti come nel mockup (Benzina / Diesel / GPL / Metano).
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? c.surface : c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                selected: v == selected,
                button: true,
                child: Material(
                  color: v == selected
                      ? (isDark ? c.line : c.surface)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(v),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          labelOf(v),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: v == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: v == selected ? c.ink : c.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mostra caricamento, errore (con "Riprova") o il contenuto di un
/// [AsyncValue].
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loadingHeight = 120,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => SizedBox(
        height: loadingHeight,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => error is ApiException && error.isUnavailable
          ? OfflineView(onRetry: onRetry)
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Text('Impossibile caricare i dati.'),
                  // Il motivo (es. "Errore 401: token App Check non valido")
                  // aiuta a capire se è un problema di configurazione.
                  if (error is ApiException)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Errore ${error.status}: ${error.title}'
                        '${error.detail == null ? '' : ' — ${error.detail}'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  if (error is ApiException &&
                      error.status == 401 &&
                      AppCheckStatus.summary != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'App Check: ${AppCheckStatus.summary}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Riprova'),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Server irraggiungibile e nessun dato salvato da mostrare.
class OfflineView extends StatelessWidget {
  const OfflineView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: c.muted),
          const SizedBox(height: 16),
          const Text(
            'Impossibile raggiungere il server',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Controlla la connessione a internet. Se il problema continua, '
            'il servizio potrebbe essere temporaneamente non disponibile.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Riprova'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stelle piene/vuote per un voto da 1 a 5.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i - 0.25
                ? Icons.star_rounded
                : rating >= i - 0.75
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: c.star,
          ),
      ],
    );
  }
}
