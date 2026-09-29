import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../format.dart';

/// Banner rosso in alto su tutte le schermate quando il server non è
/// raggiungibile e si mostrano i dati salvati in precedenza.
class StaleDataFrame extends ConsumerWidget {
  const StaleDataFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final since = ref.watch(staleDataProvider);
    if (since == null) return child;
    return Column(
      children: [
        StaleBanner(since: since, onRetry: () => refreshAllData(ref)),
        // Il banner occupa già la barra di stato.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.since, required this.onRetry});

  final DateTime since;
  final VoidCallback onRetry;

  static const background = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Impossibile aggiornare i dati. '
                  'Visualizzi quelli di ${formatUpdated(since.toLocal())}.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
