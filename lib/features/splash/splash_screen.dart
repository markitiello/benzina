import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/benzina_logo.dart';
import '../../state/providers.dart';

/// Schermata di caricamento: segue la splash nativa (solo logo) e resta
/// visibile finché posizione e prezzi non sono pronti.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.minimumDuration = const Duration(milliseconds: 1200),
  });

  final Duration minimumDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        ref.read(nearbyOffersProvider.future),
        Future<void>.delayed(widget.minimumDuration),
      ]);
    } catch (_) {
      // La home mostra l'errore con "Riprova".
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? c.ground : c.amber;
    final fg = isDark ? c.ink : c.onAmber;
    final secondary = isDark ? c.muted : const Color(0xFF3B2E08);
    final locating = ref.watch(locationProvider).isLoading;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BenzinaLogo(
                      size: 112,
                      background: isDark ? c.amber : c.onAmber,
                      foreground: isDark ? c.onAmber : c.amber,
                      shadow: [
                        BoxShadow(
                          color: isDark
                              ? c.amber.withValues(alpha: 0.25)
                              : const Color(0x4016181D),
                          blurRadius: isDark ? 60 : 30,
                          offset: isDark ? Offset.zero : const Offset(0, 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Benzina',
                      style: displayStyle(
                        fontSize: 44,
                        letterSpacing: -1,
                        color: fg,
                      ),
                    ),
                    Text(
                      'Il pieno al prezzo giusto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: isDark ? c.amber : c.onAmber,
                    backgroundColor: isDark ? c.line : const Color(0x2E16181D),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                locating
                    ? 'Cerco la tua posizione…'
                    : 'Cerco i distributori vicino a te…',
                style: TextStyle(fontSize: 14, color: secondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Dati prezzi: MIMIT · Osservaprezzi Carburanti',
                style: TextStyle(fontSize: 12, color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
