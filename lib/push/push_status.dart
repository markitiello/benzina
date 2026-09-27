import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_providers.dart';

/// Stato delle notifiche push, mostrato nelle impostazioni per capire perché
/// una notifica non arriva.
class PushStatus {
  const PushStatus({
    required this.available,
    this.permitted,
    this.topics = const {},
    this.error,
  });

  /// Firebase configurato in questa build.
  final bool available;

  /// `null` finché non si è chiesto il permesso.
  final bool? permitted;

  /// Topic a cui il dispositivo risulta iscritto.
  final Set<String> topics;

  /// Ultimo errore di iscrizione.
  final String? error;

  String get summary {
    if (!available) return 'Non configurate';
    if (error != null) return 'Errore';
    if (permitted == false) return 'Permesso negato';
    if (permitted == null) return 'In attivazione…';
    if (topics.isEmpty) return 'Disattivate';
    return 'Attive';
  }
}

class PushStatusNotifier extends Notifier<PushStatus> {
  @override
  PushStatus build() =>
      PushStatus(available: ref.watch(pushGatewayProvider).isAvailable);

  void synced(Set<String> topics, {required bool permitted}) =>
      state = PushStatus(
        available: state.available,
        permitted: permitted,
        topics: topics,
      );

  void failed(Object error) => state = PushStatus(
    available: state.available,
    permitted: state.permitted,
    topics: const {},
    error: '$error',
  );
}

final pushStatusProvider = NotifierProvider<PushStatusNotifier, PushStatus>(
  PushStatusNotifier.new,
);
