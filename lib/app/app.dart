import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/stale_banner.dart';
import '../push/push_message.dart';
import '../push/push_providers.dart';
import '../push/push_status.dart';
import '../push/push_topics.dart';
import '../push/topic_sync.dart';
import '../state/providers.dart';
import 'router.dart';

class BenzinaApp extends ConsumerStatefulWidget {
  const BenzinaApp({super.key, this.router});

  /// Per i test: un router con un'altra pagina iniziale.
  final GoRouter? router;

  @override
  ConsumerState<BenzinaApp> createState() => _BenzinaAppState();
}

class _BenzinaAppState extends ConsumerState<BenzinaApp> {
  late final GoRouter _router = widget.router ?? buildRouter();
  final _subscriptions = <StreamSubscription<PushMessage>>[];

  @override
  void initState() {
    super.initState();
    // Server irraggiungibile e dati salvati in uso: banner in alto.
    ref.read(apiClientProvider)?.onFreshness = (since) {
      if (mounted) ref.read(staleDataProvider.notifier).set(since);
    };

    final push = ref.read(pushGatewayProvider);
    final notifications = ref.read(notificationsProvider.notifier);

    // Notifiche push: finiscono nella lista Notifiche; toccarle apre la
    // schermata giusta (Andamento per le tendenze).
    _subscriptions
      ..add(push.received.listen((m) => notifications.add(m.toNotification())))
      ..add(push.opened.listen(_open));
    push.launchMessage().then((m) {
      if (m != null) _open(m);
    });

    // Iscrizione al topic del carburante scelto, aggiornata quando cambiano
    // carburante, modalità o l'interruttore nelle impostazioni.
    // (La chiave è una stringa: due Set uguali non sono "==" e il listener
    // scatterebbe a ogni modifica delle impostazioni, anche del tema.)
    ref.listenManual<String>(
      settingsProvider.select((s) => desiredTopics(s).join(',')),
      (_, key) => _syncTopics(key.isEmpty ? const {} : key.split(',').toSet()),
      fireImmediately: true,
    );
  }

  Future<void> _syncTopics(Set<String> topics) async {
    final status = ref.read(pushStatusProvider.notifier);
    try {
      final allowed = await syncTrendTopics(
        ref.read(pushGatewayProvider),
        topics,
      );
      if (mounted) status.synced(topics, permitted: allowed);
    } catch (e) {
      debugPrint('Iscrizione alle notifiche non riuscita: $e');
      if (mounted) status.failed(e);
    }
  }

  void _open(PushMessage message) {
    ref
        .read(notificationsProvider.notifier)
        .add(message.toNotification(read: true));
    _router.go(message.route);
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'Benzina',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
      builder: (context, child) => StaleDataFrame(child: child!),
    );
  }
}
