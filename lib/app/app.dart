import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
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
    );
  }
}
